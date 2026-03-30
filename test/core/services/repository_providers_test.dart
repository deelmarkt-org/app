import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';

void main() {
  group('Repository Providers', () {
    test(
      'useMockDataProvider defaults to true when Supabase not initialized',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useMock = container.read(useMockDataProvider);
        expect(useMock, true);
      },
    );

    test(
      'listingRepositoryProvider returns MockListingRepository when mock=true',
      () {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);

        final repo = container.read(listingRepositoryProvider);
        expect(repo, isA<MockListingRepository>());
      },
    );

    test(
      'categoryRepositoryProvider returns MockCategoryRepository when mock=true',
      () {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);

        final repo = container.read(categoryRepositoryProvider);
        expect(repo, isA<MockCategoryRepository>());
      },
    );

    test(
      'userRepositoryProvider returns MockUserRepository when mock=true',
      () {
        final container = ProviderContainer(
          overrides: [useMockDataProvider.overrideWithValue(true)],
        );
        addTearDown(container.dispose);

        final repo = container.read(userRepositoryProvider);
        expect(repo, isA<MockUserRepository>());
      },
    );

    test('mock override can be toggled', () {
      final container = ProviderContainer(
        overrides: [useMockDataProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);

      expect(container.read(useMockDataProvider), true);
      expect(
        container.read(listingRepositoryProvider),
        isA<MockListingRepository>(),
      );
    });
  });
}
