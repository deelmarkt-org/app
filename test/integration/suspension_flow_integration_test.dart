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

  // ---------------------------------------------------------------------------
  // Scenario E — fail-open: sanction error does NOT block the user
  // ---------------------------------------------------------------------------
  // POLICY DECISION (documented here intentionally):
  //   When activeSanctionProvider throws (e.g. network outage, Supabase down),
  //   `sanctionAsync.valueOrNull` returns null, so `hasActiveSanction` defaults
  //   to false. This is a deliberate fail-OPEN design: availability takes
  //   priority over strict enforcement during backend outages. The trade-off is
  //   that a suspended user on a poor connection may temporarily bypass the gate.
  //   Mitigation: RLS policies on the backend still enforce access at the DB level.
  // ---------------------------------------------------------------------------

  group('Scenario E — sanction provider error → fail-open', () {
    test(
      'authRedirect passes user through when hasActiveSanction=false (error case)',
      () {
        // Simulate: sanctionAsync.valueOrNull == null (from AsyncError or AsyncData(null))
        // hasActiveSanction computed as: null?.isActive ?? false = false
        final redirect = authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: '/',
          hasActiveSanction:
              false, // ignore: avoid_redundant_argument_values — error state → null → false (fail-open)
        );
        // EXPECTED: fail-open — user stays on /home, not redirected to /suspended.
        expect(
          redirect,
          isNull,
          reason: 'Fail-open: sanction error must not trap the user',
        );
      },
    );

    test(
      'authRedirect does NOT redirect to /suspended when hasActiveSanction=false',
      () {
        // failOpenValue: AsyncError → valueOrNull=null → isActive ?? false = false
        // ignore: avoid_redundant_argument_values
        const failOpenValue = false;
        for (final path in ['/', '/sell', '/messages', '/profile']) {
          final redirect = authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: path,
            hasActiveSanction:
                failOpenValue, // ignore: avoid_redundant_argument_values
          );
          expect(
            redirect,
            isNot(equals('/suspended')),
            reason: 'Path $path must not redirect to /suspended on error',
          );
        }
      },
    );
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
