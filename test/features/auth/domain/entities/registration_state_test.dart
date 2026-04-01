import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';

void main() {
  group('RegistrationState', () {
    test('initial() creates emailForm step with defaults', () {
      final state = RegistrationState.initial();
      expect(state.step, RegistrationStep.emailForm);
      expect(state.email, isNull);
      expect(state.phone, isNull);
      expect(state.isLoading, false);
      expect(state.errorKey, isNull);
      expect(state.termsAccepted, false);
      expect(state.privacyAccepted, false);
    });

    test('copyWith creates new instance with changed fields', () {
      final state = RegistrationState.initial();
      final updated = state.copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
        isLoading: true,
      );

      expect(updated.step, RegistrationStep.emailVerification);
      expect(updated.email, 'test@example.com');
      expect(updated.isLoading, true);
      // Unchanged fields preserved
      expect(updated.phone, isNull);
      expect(updated.termsAccepted, false);
    });

    test('copyWith with errorKey factory clears error', () {
      final state = RegistrationState.initial().copyWith(
        errorKey: () => 'error.generic',
      );
      expect(state.errorKey, 'error.generic');

      final cleared = state.copyWith(errorKey: () => null);
      expect(cleared.errorKey, isNull);
    });

    test('equality works via Equatable', () {
      final a = RegistrationState.initial();
      final b = RegistrationState.initial();
      expect(a, equals(b));

      final c = a.copyWith(email: 'x@x.com');
      expect(a, isNot(equals(c)));
    });
  });

  group('RegistrationStep', () {
    test('has all expected steps', () {
      expect(RegistrationStep.values, hasLength(5));
      expect(RegistrationStep.values, contains(RegistrationStep.emailForm));
      expect(RegistrationStep.values, contains(RegistrationStep.complete));
    });
  });
}
