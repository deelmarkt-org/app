import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/services/analytics/sanction_analytics.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics analytics;
  late SanctionAnalytics sut;

  setUpAll(() {
    registerFallbackValue(<String, Object>{});
  });

  setUp(() {
    analytics = MockFirebaseAnalytics();
    sut = SanctionAnalytics(analytics: analytics);
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('SanctionAnalytics', () {
    test('suspensionGateShown logs event with sanction_id and type', () {
      sut.suspensionGateShown(
        sanctionId: 'san-001',
        type: SanctionType.suspension,
      );

      verify(
        () => analytics.logEvent(
          name: 'suspension_gate_shown',
          parameters: {'sanction_id': 'san-001', 'sanction_type': 'suspension'},
        ),
      ).called(1);
    });

    test('appealStarted logs event with sanction_id', () {
      sut.appealStarted(sanctionId: 'san-002');

      verify(
        () => analytics.logEvent(
          name: 'appeal_started',
          parameters: {'sanction_id': 'san-002'},
        ),
      ).called(1);
    });

    test('appealSubmitted logs event with body_length (no body content)', () {
      sut.appealSubmitted(sanctionId: 'san-003', bodyLength: 250);

      verify(
        () => analytics.logEvent(
          name: 'appeal_submitted',
          parameters: {'sanction_id': 'san-003', 'body_length': 250},
        ),
      ).called(1);
    });

    test('appealFailed logs event with sanction_id and error_code', () {
      sut.appealFailed(
        sanctionId: 'san-004',
        errorCode: 'APPEAL_WINDOW_EXPIRED',
      );

      verify(
        () => analytics.logEvent(
          name: 'appeal_failed',
          parameters: {
            'sanction_id': 'san-004',
            'error_code': 'APPEAL_WINDOW_EXPIRED',
          },
        ),
      ).called(1);
    });
  });
}
