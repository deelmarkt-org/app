import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/data/mock/mock_category_repository.dart';
import '../../features/home/data/mock/mock_listing_repository.dart';
import '../../features/home/data/supabase/supabase_category_repository.dart';
import '../../features/home/data/supabase/supabase_listing_repository.dart';
import '../../features/home/domain/repositories/category_repository.dart';
import '../../features/home/domain/repositories/listing_repository.dart';
import '../../features/profile/data/mock/mock_user_repository.dart';
import '../../features/profile/data/supabase/supabase_user_repository.dart';
import '../../features/profile/domain/repositories/user_repository.dart';
import 'supabase_service.dart';

/// Whether to use real Supabase or mock repositories.
///
/// Override in tests: `ProviderScope(overrides: [useMockDataProvider.overrideWithValue(true)])`
/// In production: defaults to false (real Supabase).
/// Uses compile-time flag to avoid catching unrelated Supabase errors.
final useMockDataProvider = Provider<bool>((ref) {
  const useMock = bool.fromEnvironment('USE_MOCK_DATA');
  if (useMock) return true;
  try {
    Supabase.instance.client;
    return false;
  } on StateError {
    return true;
  } on AssertionError {
    // Supabase uses assert(_isInitialized) internally
    return true;
  }
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
