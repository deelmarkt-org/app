import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/screens/own_profile_screen.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_skeleton.dart';

import '../../../../helpers/pump_app.dart';

/// Suppress overflow errors during widget tests.
void _suppressOverflow(FlutterErrorDetails details) {
  if (details.exceptionAsString().contains('overflowed')) return;
  FlutterError.dumpErrorToConsole(details);
}

/// Stub [ProfileNotifier] that does not auto-load.
class _StubProfileNotifier extends ProfileNotifier {
  _StubProfileNotifier(this._initialState, {required super.ref});

  final ProfileState _initialState;

  @override
  Future<void> load() async {
    state = _initialState;
  }
}

void main() {
  final testUser = UserEntity(
    id: 'user-001',
    displayName: 'Jan de Vries',
    kycLevel: KycLevel.level1,
    location: 'Amsterdam',
    badges: const [BadgeType.emailVerified],
    averageRating: 4.7,
    reviewCount: 23,
    responseTimeMinutes: 15,
    createdAt: DateTime(2025, 6),
  );

  final loadedState = ProfileState(
    user: AsyncValue.data(testUser),
    listings: const AsyncValue.data([]),
    reviews: const AsyncValue.data([]),
  );

  group('OwnProfileScreen', () {
    final origOnError = FlutterError.onError;
    setUp(() => FlutterError.onError = _suppressOverflow);
    tearDown(() => FlutterError.onError = origOnError);

    testWidgets('shows ProfileSkeleton during loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              (ref) => _StubProfileNotifier(const ProfileState(), ref: ref),
            ),
          ],
          child: const MaterialApp(home: OwnProfileScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });

    testWidgets('shows error message on user load failure', (tester) async {
      final errorState = ProfileState(
        user: AsyncValue.error(Exception('fail'), StackTrace.current),
      );

      await pumpTestScreenWithProviders(
        tester,
        const OwnProfileScreen(),
        overrides: [
          profileProvider.overrideWith(
            (ref) => _StubProfileNotifier(errorState, ref: ref),
          ),
        ],
      );

      expect(find.text('error.generic'), findsOneWidget);
    });

    testWidgets('shows not-logged-in message when user is null', (
      tester,
    ) async {
      const nullUserState = ProfileState(user: AsyncValue.data(null));

      await pumpTestScreenWithProviders(
        tester,
        const OwnProfileScreen(),
        overrides: [
          profileProvider.overrideWith(
            (ref) => _StubProfileNotifier(nullUserState, ref: ref),
          ),
        ],
      );

      expect(find.text('profile.notLoggedIn'), findsOneWidget);
    });

    testWidgets('shows title and gear icon when loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              (ref) => _StubProfileNotifier(loadedState, ref: ref),
            ),
          ],
          child: const MaterialApp(home: OwnProfileScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Consume RenderFlex overflow from narrow test viewport.
      tester.takeException();

      expect(find.text('profile.title'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows display name and TabBarView when loaded', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              (ref) => _StubProfileNotifier(loadedState, ref: ref),
            ),
          ],
          child: const MaterialApp(home: OwnProfileScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();

      expect(find.text('Jan de Vries'), findsWidgets);
      expect(find.byType(TabBarView), findsOneWidget);
    });
  });
}
