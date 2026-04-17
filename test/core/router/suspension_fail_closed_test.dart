/// Tests for [sanctionAsyncRedirect] — fail-CLOSED suspension gate behaviour.
///
/// Background: Gemini flagged a HIGH security issue on PR #171 (comment id
/// 3096148637) — the suspension gate previously read
/// `sanctionAsync.valueOrNull?.isActive ?? false`, which defaulted to `false`
/// when the provider was in an error state. A suspended/banned user could
/// bypass the gate by forcing the sanction lookup to fail (e.g. by dropping
/// the network during the request).
///
/// Reference: lib/core/router/app_router.dart
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/router/app_router.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

void main() {
  group('sanctionAsyncRedirect — fail-CLOSED on AsyncError', () {
    final error = AsyncValue<SanctionEntity?>.error(
      Exception('network down'),
      StackTrace.empty,
    );

    test(
      'logged-in user on /home → /suspended when sanction lookup errored',
      () {
        expect(
          sanctionAsyncRedirect(
            isLoggedIn: true,
            sanctionAsync: error,
            currentPath: AppRoutes.home,
          ),
          AppRoutes.suspended,
        );
      },
    );

    test('logged-in user on /sell → /suspended on error (no bypass)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: error,
          currentPath: AppRoutes.sell,
        ),
        AppRoutes.suspended,
      );
    });

    test('logged-in user on /messages → /suspended on error (no bypass)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: error,
          currentPath: AppRoutes.messages,
        ),
        AppRoutes.suspended,
      );
    });

    test('already on /suspended → no redirect (no loop)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: error,
          currentPath: AppRoutes.suspended,
        ),
        isNull,
      );
    });

    test('already on /suspended/appeal → no redirect (no loop)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: error,
          currentPath: AppRoutes.suspendedAppeal,
        ),
        isNull,
      );
    });

    test('not logged in → no redirect (gate only applies to authed users)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: false,
          sanctionAsync: error,
          currentPath: AppRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('sanctionAsyncRedirect — loading state', () {
    const loading = AsyncValue<SanctionEntity?>.loading();

    test('logged-in + loading + not on /splash → /splash', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: loading,
          currentPath: AppRoutes.home,
        ),
        AppRoutes.splash,
      );
    });

    test('logged-in + loading + already on /splash → no redirect', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: loading,
          currentPath: AppRoutes.splash,
        ),
        isNull,
      );
    });

    test('logged-out + loading → no redirect', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: false,
          sanctionAsync: loading,
          currentPath: AppRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('sanctionAsyncRedirect — data state delegates to authRedirect', () {
    test('AsyncData(null) → no redirect (no sanction)', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: const AsyncValue<SanctionEntity?>.data(null),
          currentPath: AppRoutes.home,
        ),
        isNull,
      );
    });

    test(
      'AsyncData(sanction) → no redirect here (handled by authRedirect)',
      () {
        final sanction = SanctionEntity(
          id: 's1',
          userId: 'u1',
          type: SanctionType.suspension,
          reason: 'test',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 6)),
        );
        expect(
          sanctionAsyncRedirect(
            isLoggedIn: true,
            sanctionAsync: AsyncValue<SanctionEntity?>.data(sanction),
            currentPath: AppRoutes.home,
          ),
          isNull,
        );
      },
    );
  });
}
