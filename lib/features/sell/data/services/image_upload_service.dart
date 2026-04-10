import 'dart:io';
import 'dart:math' as math;

// Hide gotrue's AuthException so we can surface our domain [AuthException]
// from core/exceptions without a prefix collision.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_error_mapper.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

/// Thin HTTP client for the R-27 `image-upload-process` pipeline.
///
/// Wraps the two-step upload flow in a single call:
///  1. Upload raw bytes to `listings-images/<user_id>/<uuid>.<ext>` in
///     Supabase Storage (direct-to-bucket, RLS enforces folder ownership).
///  2. Invoke the `image-upload-process` Edge Function with the path.
///     The EF runs Cloudmersive virus scan + Cloudinary signed upload
///     and returns the delivery URL.
///
/// Caller gets back an [ImageUploadResponse] with the Cloudinary URL
/// that is safe to persist in `listings.image_urls[]`. On any failure
/// the pipeline aborts; Storage objects that triggered a threat
/// detection are deleted server-side by the EF, so the client does
/// not need to clean up.
///
/// ## Error mapping
///
/// The sealed [AppException] hierarchy has only three subtypes today:
/// [AuthException], [ValidationException], [NetworkException]. We map
/// every failure into one of those with a stable l10n key so callers
/// can show the right message without matching on raw HTTP codes.
///
/// | HTTP | Exception           | l10n key                                |
/// | ---- | ------------------- | --------------------------------------- |
/// | 401  | AuthException       | `error.auth.unauthenticated`            |
/// | 403  | AuthException       | `error.image.ownership_mismatch`        |
/// | 404  | NetworkException    | (storage object vanished — transport)   |
/// | 413  | ValidationException | `error.image.too_large`                 |
/// | 422  | ValidationException | `error.image.blocked`                   |
/// | 429  | ValidationException | `error.image.rate_limited`              |
/// | 502  | NetworkException    | (Cloudinary outage)                     |
/// | 503  | NetworkException    | (Cloudmersive scan outage)              |
/// | 5xx  | NetworkException    | (generic transport)                     |
class ImageUploadService {
  const ImageUploadService(this._client);

  final SupabaseClient _client;

  static const _bucket = 'listings-images';
  static const _functionName = 'image-upload-process';

  /// Matches the 15 MiB ceiling enforced server-side by
  /// `image-upload-process` and the R-05 bucket policy. Checked
  /// client-side to avoid a wasted Storage upload + 413 round trip.
  static const int maxBytes = 15 * 1024 * 1024;

  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

  /// Uploads [localFile] and runs it through the R-27 pipeline.
  ///
  /// Throws [AuthException] when no user is signed in,
  /// [ValidationException] for client-side rejections (too large,
  /// wrong extension, server-blocked threat) or
  /// [NetworkException] for transport failures and server-side outages.
  Future<ImageUploadResponse> uploadAndProcess(File localFile) async {
    final userId = _requireUserId();
    final ext = await _validateLocalFile(localFile);
    final storagePath = '$userId/${_generateFilename(ext)}';
    await _uploadToStorage(storagePath, localFile);
    return _invokeProcessingFunction(storagePath);
  }

  /// Returns the signed-in user id, or throws [AuthException].
  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException(
        'error.auth.unauthenticated',
        debugMessage: 'ImageUploadService called with no signed-in user',
      );
    }
    return userId;
  }

  /// Pre-flight validation: enforces the 15 MiB ceiling and the
  /// extension allowlist before we touch Storage. Returns the
  /// lowercased extension on success.
  Future<String> _validateLocalFile(File localFile) async {
    final size = await localFile.length();
    if (size > maxBytes) {
      throw const ValidationException(
        'error.image.too_large',
        debugMessage: 'Local file exceeds 15 MiB before upload',
      );
    }
    final ext = _extensionOf(localFile.path);
    if (ext == null || !_allowedExtensions.contains(ext)) {
      throw ValidationException(
        'error.image.unsupported_format',
        debugMessage: 'Unsupported extension: $ext',
      );
    }
    return ext;
  }

  /// Direct upload to Supabase Storage. Path format must satisfy the
  /// EF regex
  /// `^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$`
  /// (strict UUIDv4 8-4-4-4-12 layout, tightened in PR #105 review).
  ///
  /// `upsert` defaults to false, which is what we want — the filename
  /// has a timestamp + random tail so collisions are effectively
  /// impossible, and RLS blocks cross-user writes.
  Future<void> _uploadToStorage(String storagePath, File localFile) async {
    try {
      await _client.storage.from(_bucket).upload(storagePath, localFile);
    } on StorageException catch (err) {
      throw NetworkException(
        debugMessage: 'Storage upload failed: ${err.message}',
      );
    }
  }

  /// Invokes the `image-upload-process` Edge Function and parses the
  /// response.
  ///
  /// `supabase_flutter`'s `FunctionsClient.invoke()` throws
  /// [FunctionException] on any non-2xx status, so the happy path only
  /// has to parse the body. Error mapping lives in
  /// [ImageUploadErrorMapper] and runs off the exception's `status` +
  /// `details` fields.
  Future<ImageUploadResponse> _invokeProcessingFunction(
    String storagePath,
  ) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: {'storage_path': storagePath},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const NetworkException(
          messageKey: 'error.image.upload_failed',
          debugMessage: 'image-upload-process returned non-map payload',
        );
      }
      return ImageUploadResponse.fromJson(data);
    } on FunctionException catch (err) {
      // Route real non-2xx responses through the shared mapper so the
      // right typed exception + l10n key reach the caller.
      throw ImageUploadErrorMapper.map(err.status, err.details);
    } on FormatException catch (err) {
      throw NetworkException(
        messageKey: 'error.image.upload_failed',
        debugMessage:
            'image-upload-process payload parse failed: ${err.message}',
      );
    }
  }

  /// Extracts the lowercase extension (no dot) from a file path.
  /// Returns `null` when there's no extension or the path ends in a dot.
  static String? _extensionOf(String path) {
    final slash = math.max(path.lastIndexOf('/'), path.lastIndexOf(r'\'));
    final dot = path.lastIndexOf('.');
    if (dot <= slash || dot == path.length - 1) return null;
    return path.substring(dot + 1).toLowerCase();
  }

  /// Generates a filename that satisfies the EF regex
  /// `[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}`. Uses `Random.secure` +
  /// timestamp for uniqueness — we don't need a real UUIDv4 because
  /// Storage `upsert: false` detects collisions and RLS prevents
  /// cross-user contamination.
  static String _generateFilename(String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = math.Random.secure();
    final tail =
        List.generate(8, (_) => rand.nextInt(36).toRadixString(36)).join();
    return '$ts-$tail.$ext';
  }
}
