import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/services/supabase_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseAvatarUploadService', () {
    test('implements AvatarUploadService interface', () {
      final client = MockSupabaseClient();
      final AvatarUploadService service = SupabaseAvatarUploadService(client);

      expect(service, isA<AvatarUploadService>());
    });

    test('rejects unsupported file extensions', () {
      final client = MockSupabaseClient();
      final service = SupabaseAvatarUploadService(client);

      // _validateFile is called via upload — we can test via a non-existent
      // path with a bad extension; File(path).lengthSync() will throw before
      // the extension check in a real run, but _validateFile is called first.
      // Use a fake path with an unsupported extension.
      expect(
        () => service.upload(userId: 'user-1', filePath: '/tmp/avatar.bmp'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
