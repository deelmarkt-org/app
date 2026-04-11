import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Upload-state derived getters for [ListingCreationState].
///
/// Lives in a companion extension file so the main state file stays under
/// the 100-line entity limit (CLAUDE.md §2.1).
extension ListingCreationStateUpload on ListingCreationState {
  int get uploadedCount =>
      imageFiles.where((i) => i.status == ImageUploadStatus.uploaded).length;

  bool get hasPendingUploads => imageFiles.any((i) => i.isPending);

  bool get hasFailedUploads => imageFiles.any((i) => i.isFailed);

  /// True when at least one image is present and every image has finished
  /// uploading successfully. Used to gate the publish CTA.
  bool get allImagesUploaded =>
      imageFiles.isNotEmpty && imageFiles.every((i) => i.isUploaded);

  /// Cloudinary delivery URLs of successfully uploaded images, in display
  /// order. Non-uploaded images are dropped (see plan §3.5).
  ///
  /// Uses [whereType] to safely skip any uploaded image whose [deliveryUrl]
  /// is unexpectedly null (defensive; should not occur in normal flow).
  List<String> get uploadedDeliveryUrls => imageFiles
      .where((i) => i.isUploaded)
      .map((i) => i.deliveryUrl)
      .whereType<String>()
      .toList(growable: false);
}
