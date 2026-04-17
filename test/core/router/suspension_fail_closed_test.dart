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
import 'package:deelmarkt/core/router/auth_guard.dart';
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

    // M1 fix: loading during retry from /suspended must NOT flash to /splash
    test(
      'logged-in + loading + on /suspended → no redirect (retry in-page)',
      () {
        expect(
          sanctionAsyncRedirect(
            isLoggedIn: true,
            sanctionAsync: loading,
            currentPath: AppRoutes.suspended,
          ),
          isNull,
        );
      },
    );

    test('logged-in + loading + on /suspended/appeal → no redirect', () {
      expect(
        sanctionAsyncRedirect(
          isLoggedIn: true,
          sanctionAsync: loading,
          currentPath: AppRoutes.suspendedAppeal,
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

  // Full-pipeline tests (M2 fix): verify that the router does NOT release
  // a user from /suspended when the provider is in error state — the bug
  // existed because sanctionAsyncRedirect returned null (loop prevention)
  // and then hasActiveSanction defaulted to false, causing authRedirect to
  // send the user back to /home. Fixed by H1: hasActiveSanction = hasError || ...
  group('full pipeline — /suspended user stays gated on error', () {
    final error = AsyncValue<SanctionEntity?>.error(
      Exception('network down'),
      StackTrace.empty,
    );

    // Simulates what app_router.dart does: sanctionAsyncRedirect first,
    // then authRedirect with hasActiveSanction derived from the same AsyncValue.
    String? fullPipelineRedirect({
      required AsyncValue<SanctionEntity?> sanctionAsync,
      required String currentPath,
    }) {
      final asyncRedirect = sanctionAsyncRedirect(
        isLoggedIn: true,
        sanctionAsync: sanctionAsync,
        currentPath: currentPath,
      );
      if (asyncRedirect != null) return asyncRedirect;
      final hasActiveSanction =
          sanctionAsync.hasError ||
          (sanctionAsync.valueOrNull?.isActive ?? false);
      return authRedirect(
        isLoading: false,
        isLoggedIn: true,
        currentPath: currentPath,
        hasActiveSanction: hasActiveSanction,
      );
    }

    test(
      'user on /suspended with error → stays on /suspended (no release)',
      () {
        expect(
          fullPipelineRedirect(
            sanctionAsync: error,
            currentPath: AppRoutes.suspended,
          ),
          isNull,
          reason: 'Must remain on /suspended while provider is in error state',
        );
      },
    );

    test('user on /suspended/appeal with error → stays (no release)', () {
      expect(
        fullPipelineRedirect(
          sanctionAsync: error,
          currentPath: AppRoutes.suspendedAppeal,
        ),
        isNull,
      );
    });

    test('user on /suspended with AsyncData(null) → released to /home', () {
      expect(
        fullPipelineRedirect(
          sanctionAsync: const AsyncValue<SanctionEntity?>.data(null),
          currentPath: AppRoutes.suspended,
        ),
        AppRoutes.home,
        reason: 'No error and no active sanction — user should be released',
      );
    });

    test('user on /home with error → redirected to /suspended', () {
      expect(
        fullPipelineRedirect(sanctionAsync: error, currentPath: AppRoutes.home),
        AppRoutes.suspended,
      );
    });
  });
}
