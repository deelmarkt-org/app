/// Response DTO for the `image-upload-process` Edge Function (R-27).
///
/// Mirrors the JSON payload returned by
/// `supabase/functions/image-upload-process/index.ts` on success.
library;

/// Successful result of a full image upload pipeline:
/// Supabase Storage → Cloudmersive scan → Cloudinary transform.
///
/// [deliveryUrl] is the only value the caller must persist — it's the
/// CDN URL safe to store in `listings.image_urls[]`. Variants
/// (200/800/1600) are produced at render time via Cloudinary delivery
/// transforms on this URL, so we do not track multiple URLs per image.
class ImageUploadResponse {
  const ImageUploadResponse({
    required this.storagePath,
    required this.deliveryUrl,
    required this.publicId,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
  });

  /// Path inside the `listings-images` bucket that the client originally
  /// uploaded. Returned by the EF so the client can reconcile with its
  /// local upload record.
  final String storagePath;

  /// Cloudinary `secure_url` — the canonical delivery URL to persist
  /// in the database and render with.
  final String deliveryUrl;

  /// Cloudinary public id (includes folder prefix). Used for targeted
  /// deletes/transforms if we ever need them.
  final String publicId;

  /// Image width in pixels (Cloudinary reports post-upload dimensions).
  final int width;

  /// Image height in pixels.
  final int height;

  /// Byte size of the stored image (after Cloudinary processing).
  final int bytes;

  /// File format Cloudinary settled on (e.g. `jpg`, `webp`). Note that
  /// delivery format is `f_auto` at render time — this is only the
  /// storage format.
  final String format;

  /// Parses the JSON payload returned by `functions.invoke`.
  ///
  /// Throws [FormatException] on missing or wrong-typed fields. The
  /// service catches this and maps it to a stable error key.
  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    final storagePath = json['storage_path'];
    final deliveryUrl = json['delivery_url'];
    final publicId = json['public_id'];
    final width = json['width'];
    final height = json['height'];
    final bytes = json['bytes'];
    final format = json['format'];
    if (storagePath is! String ||
        deliveryUrl is! String ||
        publicId is! String ||
        width is! int ||
        height is! int ||
        bytes is! int ||
        format is! String) {
      throw const FormatException(
        'ImageUploadResponse: missing or wrong-typed required fields',
      );
    }
    return ImageUploadResponse(
      storagePath: storagePath,
      deliveryUrl: deliveryUrl,
      publicId: publicId,
      width: width,
      height: height,
      bytes: bytes,
      format: format,
    );
  }
}
