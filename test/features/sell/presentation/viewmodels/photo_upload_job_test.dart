import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoUploadJob', () {
    test('constructs with required fields and default flags false', () {
      final token = CancellationToken();
      final job = PhotoUploadJob(
        id: 'photo-1',
        localPath: '/tmp/a.jpg',
        token: token,
      );
      expect(job.id, 'photo-1');
      expect(job.localPath, '/tmp/a.jpg');
      expect(identical(job.token, token), isTrue);
      expect(job.storagePath, isNull);
      expect(job.uploadCompleted, isFalse);
      expect(job.processingCompleted, isFalse);
    });

    test('mutable fields track upload/processing state transitions', () {
      final job =
          PhotoUploadJob(
              id: 'photo-2',
              localPath: '/tmp/b.jpg',
              token: CancellationToken(),
            )
            ..storagePath = 'uploads/photo-2'
            ..uploadCompleted = true;
      expect(job.storagePath, 'uploads/photo-2');
      expect(job.uploadCompleted, isTrue);
      expect(job.processingCompleted, isFalse);

      job.processingCompleted = true;
      expect(job.processingCompleted, isTrue);
    });

    test('storagePath can be nulled out on retry', () {
      final job =
          PhotoUploadJob(
              id: 'photo-3',
              localPath: '/tmp/c.jpg',
              token: CancellationToken(),
            )
            ..storagePath = 'uploads/photo-3'
            ..uploadCompleted = true
            ..storagePath = null
            ..uploadCompleted = false;
      expect(job.storagePath, isNull);
      expect(job.uploadCompleted, isFalse);
    });
  });
}
