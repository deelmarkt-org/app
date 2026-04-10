import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

/// Two-step image upload pipeline for listing creation:
///
/// 1. Upload bytes to Supabase Storage under `<user_id>/<uuid>.<ext>`
/// 2. Invoke the `image-upload-process` Edge Function which:
///    - downloads from Storage
///    - virus-scans via Cloudmersive
///    - uploads to Cloudinary (EXIF strip, fetch_format=auto)
///    - returns the final delivery URL
///
/// Implementations MUST throw a typed [ImageUploadException] on failure so
/// the presentation layer can distinguish retryable from terminal errors.
///
/// [token] is polled at every await checkpoint. If the user removes the
/// photo or navigates away, cancel the token and the in-flight call will
/// surface an [ImageUploadCancelledException] which the queue drops silently.
abstract interface class ImageUploadRepository {
  /// Uploads [localPath] and returns the final [UploadedImage].
  ///
  /// [id] is the stable [SellImage.id] — used for logging correlation only;
  /// the server-side storage path uses a fresh UUID.
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  });

  /// Best-effort deletion of a previously uploaded Storage object. Called
  /// when the user removes an already-uploaded photo. Failures are swallowed
  /// by the caller (see plan §3.8 — "non-blocking cleanup").
  Future<void> deleteStorageObject(String storagePath);
}
