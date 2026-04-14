/// Avatar upload service interface — domain layer.
///
/// Reference: docs/screens/07-profile/01-own-profile.md
abstract class AvatarUploadService {
  /// Uploads an avatar image and returns the public URL.
  ///
  /// Throws on validation failure (wrong format, too large) or upload error.
  Future<String> upload({required String userId, required String filePath});
}
