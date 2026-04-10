import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/sell/data/mock/mock_listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/data/repositories/supabase_image_upload_repository.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';
import 'package:deelmarkt/features/sell/domain/repositories/image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/calculate_quality_score_usecase.dart';
import 'package:deelmarkt/features/sell/domain/usecases/create_listing_usecase.dart';
import 'package:deelmarkt/features/sell/domain/usecases/save_draft_usecase.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

part 'sell_providers.g.dart';

/// Listing creation repository — mock for Phase 1, swap for Supabase later.
@riverpod
ListingCreationRepository listingCreationRepository(Ref ref) {
  return MockListingCreationRepository();
}

/// Image picker service for camera/gallery operations.
@riverpod
ImagePickerService imagePickerService(Ref ref) {
  return ImagePickerService();
}

/// Image upload pipeline (Storage → Edge Function → Cloudinary).
@riverpod
ImageUploadRepository imageUploadRepository(Ref ref) {
  return SupabaseImageUploadRepository(ref.watch(supabaseClientProvider));
}

/// Bounded-concurrency upload queue. One instance per wizard session;
/// disposed via [Ref.onDispose] in the consumer.
@riverpod
PhotoUploadQueue photoUploadQueue(Ref ref) {
  final queue = PhotoUploadQueue(
    repository: ref.watch(imageUploadRepositoryProvider),
  );
  ref.onDispose(queue.dispose);
  return queue;
}

/// Draft persistence service — saves/restores creation state.
@riverpod
DraftPersistenceService draftPersistenceService(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DraftPersistenceService(prefs);
}

/// Quality score calculator — pure, no dependencies.
@riverpod
CalculateQualityScoreUseCase calculateQualityScoreUseCase(Ref ref) {
  return const CalculateQualityScoreUseCase();
}

/// Publishes a listing via the repository.
@riverpod
CreateListingUseCase createListingUseCase(Ref ref) {
  return CreateListingUseCase(ref.watch(listingCreationRepositoryProvider));
}

/// Saves a draft listing via the repository.
@riverpod
SaveDraftUseCase saveDraftUseCase(Ref ref) {
  return SaveDraftUseCase(ref.watch(listingCreationRepositoryProvider));
}

/// Derived quality score — auto-computes whenever creation state changes.
@riverpod
QualityScoreResult qualityScore(Ref ref) {
  final state = ref.watch(listingCreationNotifierProvider);
  final useCase = ref.watch(calculateQualityScoreUseCaseProvider);
  return useCase(state);
}

/// Top-level categories for the category picker.
@riverpod
Future<List<CategoryEntity>> topLevelCategories(Ref ref) async {
  return ref.read(categoryRepositoryProvider).getTopLevel();
}

/// Subcategories for a given parent L1 category.
@riverpod
Future<List<CategoryEntity>> subcategories(Ref ref, String parentId) async {
  return ref.read(categoryRepositoryProvider).getSubcategories(parentId);
}
