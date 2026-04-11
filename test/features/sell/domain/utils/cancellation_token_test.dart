import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('isCancelled starts false', () {
      expect(CancellationToken().isCancelled, isFalse);
    });

    test('cancel() sets isCancelled to true', () {
      final token = CancellationToken()..cancel();
      expect(token.isCancelled, isTrue);
    });

    test('throwIfCancelled() does not throw when not cancelled', () {
      expect(() => CancellationToken().throwIfCancelled(), returnsNormally);
    });

    test(
      'throwIfCancelled() throws UploadCancelledException when cancelled',
      () {
        final token = CancellationToken()..cancel();
        expect(
          () => token.throwIfCancelled(),
          throwsA(isA<UploadCancelledException>()),
        );
      },
    );

    test('cancel() can be called multiple times safely', () {
      final token =
          CancellationToken()
            ..cancel()
            ..cancel()
            ..cancel();
      expect(token.isCancelled, isTrue);
    });
  });
}
