import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_category_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/messages/data/mock/mock_message_repository.dart';
import 'package:deelmarkt/features/messages/data/supabase/supabase_message_repository.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_settings_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_review_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_settings_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_user_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';
import 'package:deelmarkt/features/transaction/data/mock/mock_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';

export 'package:deelmarkt/core/services/supabase_service.dart'
    show currentUserProvider;

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

/// Review repository — mock or Supabase based on [useMockDataProvider].
///
/// SupabaseReviewRepository implements blind review via DB-level RLS (R-36).
/// Resolves GitHub Issue #46.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockReviewRepository();
  return SupabaseReviewRepository(ref.watch(supabaseClientProvider));
});

/// Transaction repository — mock-only until [SupabaseTransactionRepository]
/// ships with the E03 backend tasks.
///
/// TODO(belengaz): add `useMockDataProvider` gate once real implementation
/// exists — same pattern as [listingRepositoryProvider]:
/// ```dart
/// final useMock = ref.watch(useMockDataProvider);
/// if (useMock) return MockTransactionRepository();
/// return SupabaseTransactionRepository(ref.watch(supabaseClientProvider));
/// ```
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return MockTransactionRepository();
});

/// Settings repository — mock or Supabase based on [useMockDataProvider].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockSettingsRepository();
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider));
});

/// Message repository — real Supabase implementation (B-53).
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockMessageRepository();
  return SupabaseMessageRepository(ref.watch(supabaseClientProvider));
});
