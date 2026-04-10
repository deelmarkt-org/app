import 'package:equatable/equatable.dart';

/// Successful upload result from the R-27 Edge Function.
///
/// Mirrors the `image-upload-process` response payload:
/// `{ storage_path, delivery_url, public_id, width, height, bytes, format }`.
class UploadedImage extends Equatable {
  const UploadedImage({
    required this.storagePath,
    required this.deliveryUrl,
    required this.publicId,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
  });

  /// `<user_id>/<uuid>.<ext>` within `listings-images` bucket.
  final String storagePath;

  /// Final Cloudinary delivery URL, served via CDN.
  final String deliveryUrl;

  /// Cloudinary public_id, needed for later deletion.
  final String publicId;

  final int width;
  final int height;
  final int bytes;
  final String format;

  @override
  List<Object?> get props => [
    storagePath,
    deliveryUrl,
    publicId,
    width,
    height,
    bytes,
    format,
  ];
}
