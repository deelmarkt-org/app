import 'dart:io';
import 'dart:math' as math;

// Hide gotrue's AuthException so we can surface our domain [AuthException]
// from core/exceptions without a prefix collision.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_error_mapper.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

/// Thin HTTP client for the R-27 `image-upload-process` pipeline.
///
/// Two-step flow: upload bytes to `listings-images/<user_id>/<filename>`,
/// then invoke the `image-upload-process` Edge Function which runs
/// Cloudmersive virus scan + Cloudinary upload and returns the delivery URL.
///
/// All failures are mapped to [AppException] subtypes via
/// [ImageUploadErrorMapper] so callers receive typed errors with stable l10n
/// keys (see mapper for the full HTTP→exception table).
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

  /// Direct upload to Supabase Storage.
  Future<void> _uploadToStorage(String storagePath, File localFile) async {
    try {
      await _client.storage.from(_bucket).upload(storagePath, localFile);
    } on StorageException catch (err) {
      throw NetworkException(
        debugMessage: 'Storage upload failed: ${err.message}',
      );
    } catch (err) {
      throw NetworkException(
        debugMessage: 'Storage upload unexpected error: $err',
      );
    }
  }

  /// Invokes the `image-upload-process` EF and parses the response.
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
      // Route non-2xx EF responses through the shared mapper for the
      // right typed exception + l10n key.
      throw ImageUploadErrorMapper.map(err.status, err.details);
    } on FormatException catch (err) {
      throw NetworkException(
        messageKey: 'error.image.upload_failed',
        debugMessage:
            'image-upload-process payload parse failed: ${err.message}',
      );
    } on AppException {
      // Don't re-wrap our own typed exceptions.
      rethrow;
    } catch (err) {
      // Fallback for SocketException / ClientException / timeouts —
      // every failure path must hand callers an AppException subclass.
      throw NetworkException(
        debugMessage: 'image-upload-process unexpected error: $err',
      );
    }
  }

  /// Best-effort deletion of a previously uploaded Storage object.
  ///
  /// Called when the user removes an already-uploaded photo so we don't
  /// leave orphaned objects in the `listings-images` bucket. Failures are
  /// logged as warnings but never propagated — the caller continues
  /// regardless (see plan §3.8 — "non-blocking cleanup").
  Future<void> deleteStorageObject(String storagePath) async {
    try {
      await _client.storage.from(_bucket).remove([storagePath]);
    } on Object catch (err) {
      // Swallow — best-effort only. Log so infra can detect patterns.
      AppLogger.warning(
        'deleteStorageObject failed for $storagePath: $err',
        tag: 'image_upload',
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

  /// Generates a collision-resistant filename using timestamp + 8-char random suffix.
  static String _generateFilename(String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = math.Random.secure();
    final tail =
        List.generate(8, (_) => rand.nextInt(36).toRadixString(36)).join();
    return '$ts-$tail.$ext';
  }
}
