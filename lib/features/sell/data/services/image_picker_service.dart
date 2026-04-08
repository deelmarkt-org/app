import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result type for image picking operations.
enum ImagePickerResultType {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  cancelled,
  fileTooLarge,
  unsupportedFormat,
}

/// Immutable result of an image picking operation.
class ImagePickerResult {
  const ImagePickerResult({required this.type, this.paths = const []});

  final ImagePickerResultType type;
  final List<String> paths;

  bool get isSuccess => type == ImagePickerResultType.success;
}

/// Service for picking images from camera or gallery.
///
/// Wraps [ImagePicker] with validation and error handling.
/// Constructor accepts an optional [ImagePicker] for testing.
class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Maximum file size: 15 MB.
  static const maxFileSizeBytes = 15 * 1024 * 1024;

  /// Allowed image file extensions.
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

  /// Pick a single image from the camera.
  Future<ImagePickerResult> pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );

      if (photo == null) {
        return const ImagePickerResult(type: ImagePickerResultType.cancelled);
      }

      final validation = await _validateFile(photo);
      if (validation != null) return validation;

      return ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: [photo.path],
      );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Pick one or more images from the gallery.
  Future<ImagePickerResult> pickFromGallery({int maxCount = 12}) async {
    try {
      final photos = await _picker.pickMultiImage(
        requestFullMetadata: false,
        limit: maxCount,
      );

      if (photos.isEmpty) {
        return const ImagePickerResult(type: ImagePickerResultType.cancelled);
      }

      final validPaths = <String>[];
      for (final photo in photos) {
        final validation = await _validateFile(photo);
        if (validation != null) return validation;
        validPaths.add(photo.path);
      }

      return ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: List.unmodifiable(validPaths),
      );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  /// Validates file extension and size.
  ///
  /// Returns an error [ImagePickerResult] if validation fails,
  /// or null if the file is valid.
  Future<ImagePickerResult?> _validateFile(XFile file) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return const ImagePickerResult(
        type: ImagePickerResultType.unsupportedFormat,
      );
    }

    final size = await file.length();
    if (size > maxFileSizeBytes) {
      return const ImagePickerResult(type: ImagePickerResultType.fileTooLarge);
    }

    return null;
  }

  /// Maps platform-specific permission errors to result types.
  ImagePickerResult _handlePlatformException(PlatformException e) {
    if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
      return const ImagePickerResult(
        type: ImagePickerResultType.permissionDenied,
      );
    }

    if (e.code == 'camera_access_restricted') {
      return const ImagePickerResult(
        type: ImagePickerResultType.permissionPermanentlyDenied,
      );
    }

    return const ImagePickerResult(
      type: ImagePickerResultType.permissionDenied,
    );
  }
}
