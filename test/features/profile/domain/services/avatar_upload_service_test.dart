import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';

void main() {
  group('AvatarUploadService interface', () {
    test('MockAvatarUploadService implements AvatarUploadService', () {
      // Verify the interface contract: any implementation must provide upload().
      final AvatarUploadService service = MockAvatarUploadService();
      expect(service, isA<AvatarUploadService>());
    });
  });
}
