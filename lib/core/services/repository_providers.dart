import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_category_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_settings_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_user_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';

/// Whether to use real Supabase or mock repositories.
///
/// Compile-time constant: `--dart-define=USE_MOCK_DATA=true` for mock mode.
/// Override in tests: `ProviderScope(overrides: [useMockDataProvider.overrideWithValue(true)])`
/// In production: defaults to false (real Supabase).
/// Uses compile-time flag to avoid catching unrelated Supabase errors.
final useMockDataProvider = Provider<bool>((ref) {
  return const bool.fromEnvironment('USE_MOCK_DATA');
});

/// Listing repository — mock or Supabase based on [useMockDataProvider].
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockListingRepository();
  return SupabaseListingRepository(ref.watch(supabaseClientProvider));
});

/// Category repository — mock or Supabase based on [useMockDataProvider].
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockCategoryRepository();
  return SupabaseCategoryRepository(ref.watch(supabaseClientProvider));
});

/// User repository — mock or Supabase based on [useMockDataProvider].
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockUserRepository();
  return SupabaseUserRepository(ref.watch(supabaseClientProvider));
});

/// Review repository — mock or real.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  // Tracked: #46 — SupabaseReviewRepository blocked by R-36
  return MockReviewRepository();
});

/// Settings repository — mock or real.
/// WARNING: Both branches currently return mock. Real Supabase impl needed before production.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockSettingsRepository();
  // Tracked: #47 — P0 launch blocker: SupabaseSettingsRepository
  return MockSettingsRepository();
});
