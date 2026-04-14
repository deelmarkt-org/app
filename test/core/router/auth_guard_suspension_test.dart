/// Tests for [authRedirect] — suspension-gate truth table (P-53 Phase G).
///
/// Extends the existing auth_guard_test.dart with hasActiveSanction cases.
/// Reference: lib/core/router/auth_guard.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/router/auth_guard.dart';
import 'package:deelmarkt/core/router/routes.dart';

void main() {
  group('authRedirect — suspension gate (hasActiveSanction=true)', () {
    test(
      'redirects to /suspended when logged in, has active sanction, at /home',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.home,
            hasActiveSanction: true,
          ),
          AppRoutes.suspended,
        );
      },
    );

    test(
      'allows /suspended when logged in and has active sanction (no redirect)',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.suspended,
            hasActiveSanction: true,
          ),
          isNull,
        );
      },
    );

    test('allows /suspended/appeal when logged in and has active sanction', () {
      expect(
        authRedirect(
          isLoading: false,
          isLoggedIn: true,
          currentPath: AppRoutes.suspendedAppeal,
          hasActiveSanction: true,
        ),
        isNull,
      );
    });

    test(
      'redirects /profile to /suspended when logged in and has active sanction',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.profile,
            hasActiveSanction: true,
          ),
          AppRoutes.suspended,
        );
      },
    );

    test(
      'redirects /sell to /suspended when logged in and has active sanction',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.sell,
            hasActiveSanction: true,
          ),
          AppRoutes.suspended,
        );
      },
    );

    test(
      'redirects /messages to /suspended when logged in and has active sanction',
      () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.messages,
            hasActiveSanction: true,
          ),
          AppRoutes.suspended,
        );
      },
    );
  });

  group(
    'authRedirect — suspension lifted (hasActiveSanction=false on /suspended)',
    () {
      test('redirects /suspended to /home when sanction is cleared', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.suspended,
          ),
          AppRoutes.home,
        );
      });

      test('redirects /suspended/appeal to /home when sanction is cleared', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.suspendedAppeal,
          ),
          AppRoutes.home,
        );
      });
    },
  );

  group(
    'authRedirect — pre-existing branches unaffected by hasActiveSanction',
    () {
      test('returns /splash while loading regardless of sanction flag', () {
        expect(
          authRedirect(
            isLoading: true,
            isLoggedIn: true,
            currentPath: AppRoutes.home,
            hasActiveSanction: true,
          ),
          '/splash',
        );
      });

      test('redirects unauthenticated /home to null (not protected)', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('redirects unauthenticated /sell to /onboarding', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: AppRoutes.sell,
          ),
          '/onboarding',
        );
      });

      test(
        'redirects unauthenticated /sell to /login when onboarding complete',
        () {
          expect(
            authRedirect(
              isLoading: false,
              isLoggedIn: false,
              currentPath: AppRoutes.sell,
              isOnboardingComplete: true,
            ),
            '/login',
          );
        },
      );

      test('redirects /admin to /home when logged in but not admin', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.admin,
          ),
          AppRoutes.home,
        );
      });

      test('allows /admin when logged in and is admin', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.admin,
            isAdmin: true,
          ),
          isNull,
        );
      });

      test('redirects /login to /home when logged in (no sanction)', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: '/login',
          ),
          AppRoutes.home,
        );
      });

      test('allows /home when logged in with no sanction', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('/splash → /home when resolved and logged in (no sanction)', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: true,
            currentPath: '/splash',
          ),
          AppRoutes.home,
        );
      });

      test('allows /search for unauthenticated (no sanction)', () {
        expect(
          authRedirect(
            isLoading: false,
            isLoggedIn: false,
            currentPath: AppRoutes.search,
          ),
          isNull,
        );
      });
    },
  );
}
