import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';
import 'package:deelmarkt/features/sell/domain/repositories/image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

/// R-27 client wiring: Storage upload → `image-upload-process` Edge Function.
///
/// Two-step pipeline:
/// 1. PUT bytes to `listings-images/<user_id>/<uuid>.<ext>`
/// 2. invoke('image-upload-process', body: { storage_path }) → delivery URL
///
/// All failures surface as typed [ImageUploadException]s so the queue can
/// distinguish retryable infra errors from terminal user errors. Cancellation
/// is checked at every await checkpoint (CP-1..CP-5).
class SupabaseImageUploadRepository implements ImageUploadRepository {
  SupabaseImageUploadRepository(this._client, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  static const String _bucket = 'listings-images';
  static const String _functionName = 'image-upload-process';
  // 15 MB client-side cap — aligns with the documented R-27 limit and prevents
  // OOM on oversized files before Storage rejects them.
  static const int _maxFileSizeBytes = 15 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
  };

  @override
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  }) async {
    token?.throwIfCancelled(); // CP-1
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const ImageUploadAuthException();
    final ext = _extensionOf(localPath);
    if (ext == null || !_allowedExtensions.contains(ext)) {
      throw const ImageUploadInvalidException();
    }
    final storagePath = '$userId/${_uuid.v4()}.$ext';
    final bytes = await _readBytes(localPath); // CP-2
    token?.throwIfCancelled();
    await _putToStorage(storagePath, bytes, ext); // Step 1
    token?.throwIfCancelled(); // CP-3
    final response = await _invokeEdgeFunction(storagePath); // Step 2
    token?.throwIfCancelled(); // CP-4
    if (response.status != 200) {
      throw _mapStatusCode(response.status, response.data);
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ImageUploadInvalidException();
    }
    token?.throwIfCancelled(); // CP-5
    return _parseResponse(data);
  }

  Future<Uint8List> _readBytes(String localPath) async {
    final file = File(localPath);
    try {
      if (await file.length() > _maxFileSizeBytes) {
        throw const ImageUploadTooLargeException();
      }
      return await file.readAsBytes();
    } on ImageUploadTooLargeException {
      rethrow;
    } on FileSystemException {
      throw const ImageUploadInvalidException();
    }
  }

  Future<void> _putToStorage(String path, Uint8List bytes, String ext) async {
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _mimeFor(ext)),
          );
    } on StorageException catch (e) {
      throw _mapStorageException(e);
    } catch (e) {
      throw ImageUploadNetworkException(cause: e);
    }
  }

  Future<FunctionResponse> _invokeEdgeFunction(String storagePath) async {
    try {
      return await _client.functions.invoke(
        _functionName,
        body: {'storage_path': storagePath},
      );
    } on FunctionException catch (e) {
      throw _mapFunctionException(e);
    } catch (e) {
      throw ImageUploadNetworkException(cause: e);
    }
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    try {
      await _client.storage.from(_bucket).remove([storagePath]);
    } on Object catch (_) {
      // Best-effort cleanup; never block UX on deletion failure.
    }
  }

  // ── helpers ──

  static String? _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;
    return path.substring(dot + 1).toLowerCase();
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  static UploadedImage _parseResponse(Map<String, dynamic> data) {
    try {
      return UploadedImage(
        storagePath: data['storage_path'] as String,
        deliveryUrl: data['delivery_url'] as String,
        publicId: data['public_id'] as String,
        width: (data['width'] as num).toInt(),
        height: (data['height'] as num).toInt(),
        bytes: (data['bytes'] as num).toInt(),
        format: data['format'] as String,
      );
    } on TypeError {
      throw const ImageUploadInvalidException();
    }
  }

  static ImageUploadException _mapStorageException(StorageException e) {
    final code = int.tryParse(e.statusCode ?? '') ?? 0;
    if (code == 401 || code == 403) return const ImageUploadAuthException();
    if (code == 413) return const ImageUploadTooLargeException();
    if (code >= 500 || code == 429) {
      return ImageUploadServerException(statusCode: code, details: e.message);
    }
    return const ImageUploadInvalidException();
  }

  static ImageUploadException _mapFunctionException(FunctionException e) {
    return _mapStatusCode(e.status, e.details);
  }

  static ImageUploadException _mapStatusCode(int status, Object? details) {
    if (status == 401 || status == 403) {
      return ImageUploadAuthException(statusCode: status);
    }
    if (status == 413) return const ImageUploadTooLargeException();
    if (status == 422) return const ImageUploadBlockedException();
    if (status == 429 || status == 502 || status == 503 || status >= 500) {
      return ImageUploadServerException(statusCode: status, details: details);
    }
    // Any other 4xx is a terminal client error — not retryable.
    if (status >= 400 && status < 500) {
      return const ImageUploadInvalidException();
    }
    return ImageUploadServerException(statusCode: status, details: details);
  }
}
