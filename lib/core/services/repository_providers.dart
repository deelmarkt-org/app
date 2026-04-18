import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/data/shared_prefs_home_mode_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_category_repository.dart';
import 'package:deelmarkt/features/home/data/supabase/supabase_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/home_mode_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/toggle_favourite_usecase.dart';
import 'package:deelmarkt/features/messages/data/mock/mock_message_repository.dart';
import 'package:deelmarkt/features/messages/data/supabase/supabase_message_repository.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';
import 'package:deelmarkt/features/admin/data/mock/mock_admin_repository.dart';
import 'package:deelmarkt/features/admin/data/supabase/supabase_admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_dsa_report_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_sanction_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_settings_repository.dart';
import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';
import 'package:deelmarkt/features/profile/data/services/supabase_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_dsa_report_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_review_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_sanction_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_settings_repository.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_user_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/dsa_report_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';
import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';
import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/data/supabase/supabase_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/domain/repositories/shipping_repository.dart';
import 'package:deelmarkt/features/transaction/data/mock/mock_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/data/supabase/supabase_transaction_repository.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
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

/// Home mode repository — persists buyer/seller toggle via SharedPreferences.
final homeModeRepositoryProvider = Provider<HomeModeRepository>((ref) {
  return SharedPrefsHomeModeRepository(ref.watch(sharedPreferencesProvider));
});

/// Listing repository — mock or Supabase based on [useMockDataProvider].
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockListingRepository();
  return SupabaseListingRepository(ref.watch(supabaseClientProvider));
});

/// ToggleFavouriteUseCase — shared across home, search, favourites, and
/// category-detail notifiers so feature modules don't import each other.
final toggleFavouriteUseCaseProvider = Provider<ToggleFavouriteUseCase>(
  (ref) => ToggleFavouriteUseCase(ref.watch(listingRepositoryProvider)),
);

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

/// Transaction repository — mock or Supabase based on [useMockDataProvider].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockTransactionRepository();
  return SupabaseTransactionRepository(ref.watch(supabaseClientProvider));
});

/// Settings repository — mock or Supabase based on [useMockDataProvider].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockSettingsRepository();
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider));
});

/// Shipping repository — mock or Supabase based on [useMockDataProvider].
final shippingRepositoryProvider = Provider<ShippingRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockShippingRepository();
  return SupabaseShippingRepository(ref.watch(supabaseClientProvider));
});

/// Message repository — real Supabase implementation (B-53).
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockMessageRepository();
  return SupabaseMessageRepository(ref.watch(supabaseClientProvider));
});

/// Admin repository — mock or Supabase based on [useMockDataProvider].
///
/// Provides moderation dashboard stats and recent activity.
/// Phase A: dashboard only. Phases B–D add flagged listings, disputes, etc.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockAdminRepository();
  return SupabaseAdminRepository(ref.watch(supabaseClientProvider));
});

/// Sanction repository — mock or Supabase based on [useMockDataProvider].
///
/// Provides read access to [account_sanctions] and the [submit_appeal] RPC.
/// All write operations (issuance, decisions) are service_role-only (R-37).
final sanctionRepositoryProvider = Provider<SanctionRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockSanctionRepository();
  return SupabaseSanctionRepository(ref.watch(supabaseClientProvider));
});

/// Avatar upload service — mock or Supabase based on [useMockDataProvider].
///
/// Uploads avatar images to `avatars/<user_id>/<timestamp>.<ext>` in Storage.
/// Mock mode returns a fake Cloudinary URL for development/testing.
final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockAvatarUploadService();
  return SupabaseAvatarUploadService(ref.watch(supabaseClientProvider));
});

/// DSA report repository — mock or Supabase based on [useMockDataProvider].
final dsaReportRepositoryProvider = Provider<DsaReportRepository>((ref) {
  final useMock = ref.watch(useMockDataProvider);
  if (useMock) return MockDsaReportRepository();
  return SupabaseDsaReportRepository(ref.watch(supabaseClientProvider));
});
