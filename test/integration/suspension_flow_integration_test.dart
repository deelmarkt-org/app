/// Integration tests for the P-53 suspension gate flow.
///
/// Scenarios covered:
///   A: Logged-in user with active sanction → navigates to /suspended on start.
///   C: Logged-in user with no sanction → stays on /home (no /suspended flash).
///
/// Scenarios B (appeal submit → back with pending state) and D (auto-redirect
/// after sanction overturned) require a real GoRouter wired with all shell
/// branches, which pulls in Firebase and Supabase initialisation. They are
/// deferred to a follow-up integration test with the full app harness.
///
/// Reference: lib/core/router/auth_guard.dart
/// Reference: lib/features/profile/presentation/screens/suspension_gate_screen.dart
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/router/auth_guard.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Pure-logic integration tests — no app harness needed.
  // Full GoRouter integration requires Firebase init; deferred (see header).
  // ---------------------------------------------------------------------------

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Scenario A — active sanction blocks navigation', () {
    test('authRedirect sends user to /suspended from /home', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/',
        hasActiveSanction: true,
      );
      expect(redirect, '/suspended');
    });

    test('authRedirect sends user to /suspended from /sell', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/sell',
        hasActiveSanction: true,
      );
      expect(redirect, '/suspended');
    });

    test('authRedirect sends user to /suspended from /messages', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/messages',
        hasActiveSanction: true,
      );
      expect(redirect, '/suspended');
    });

    test('authRedirect sends user to /suspended from /profile', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/profile',
        hasActiveSanction: true,
      );
      expect(redirect, '/suspended');
    });

    test('/suspended itself is allowed (no loop)', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/suspended',
        hasActiveSanction: true,
      );
      expect(redirect, isNull);
    });

    test('/suspended/appeal is allowed during active sanction', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/suspended/appeal',
        hasActiveSanction: true,
      );
      expect(redirect, isNull);
    });
  });

  group(
    'Scenario C — no sanction: user stays on /home, never sees /suspended',
    () {
      test('authRedirect returns null for /home with no sanction', () {
        final redirect = authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/',
        );
        expect(redirect, isNull);
      });

      test('authRedirect returns null for /sell with no sanction', () {
        final redirect = authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/sell',
        );
        expect(redirect, isNull);
      });

      test(
        'if user somehow ends up at /suspended with no sanction, sent to /home',
        () {
          final redirect = authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: '/suspended',
          );
          expect(redirect, '/');
        },
      );

      test(
        'no /suspended flash: /splash → /home (not /suspended) on login without sanction',
        () {
          final redirect = authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: '/splash',
          );
          expect(redirect, '/'); // goes home, not suspended
        },
      );
    },
  );

  group('Scenario D — sanction overturned: gate clears automatically', () {
    test(
      'once hasActiveSanction flips to false at /suspended, redirects to /home',
      () {
        // Simulate: sanction just overturned — guard re-evaluates.
        final redirect = authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/suspended',
          // hasActiveSanction defaults to false — sanction cleared
        );
        expect(redirect, '/');
      },
    );

    test('/suspended/appeal also redirects to /home once sanction cleared', () {
      final redirect = authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: '/suspended/appeal',
      );
      expect(redirect, '/');
    });
  });

  group('GoRouterRefreshStream — sanity', () {
    test('notifies listeners on stream event', () async {
      final controller = StreamController<int>.broadcast();
      final stream = GoRouterRefreshStream(controller.stream);

      var count = 0;
      stream.addListener(() => count++);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      expect(count, 1);
      stream.dispose();
      await controller.close();
    });
  });
}
