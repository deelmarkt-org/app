import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';

/// Mock avatar upload service for development and testing.
///
/// Returns a fake Cloudinary-style URL after a short delay.
class MockAvatarUploadService implements AvatarUploadService {
  @override
  Future<String> upload({
    required String userId,
    required String filePath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://res.cloudinary.com/demo/image/upload/avatars/$userId/$timestamp.webp';
  }
}
