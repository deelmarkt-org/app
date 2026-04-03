import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/create_listing_usecase.dart';
import 'package:deelmarkt/features/sell/domain/usecases/save_draft_usecase.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

// ── Mock implementations ──

class MockImagePickerService extends ImagePickerService {
  MockImagePickerService() : super(picker: null);

  ImagePickerResult? cameraResult;
  ImagePickerResult? galleryResult;

  @override
  Future<ImagePickerResult> pickFromCamera() async {
    return cameraResult ??
        const ImagePickerResult(
          type: ImagePickerResultType.success,
          paths: ['/mock/photo.jpg'],
        );
  }

  @override
  Future<ImagePickerResult> pickFromGallery({int maxCount = 12}) async {
    return galleryResult ??
        const ImagePickerResult(
          type: ImagePickerResultType.success,
          paths: ['/mock/gallery1.jpg', '/mock/gallery2.jpg'],
        );
  }
}

class MockListingCreationRepository implements ListingCreationRepository {
  bool shouldFail = false;

  @override
  Future<ListingEntity> create({
    required String title,
    required String description,
    required int priceInCents,
    required ListingCondition condition,
    required String categoryId,
    required List<String> imagePaths,
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    if (shouldFail) throw Exception('create failed');
    return ListingEntity(
      id: 'listing-001',
      title: title,
      description: description,
      priceInCents: priceInCents,
      sellerId: 'seller-001',
      sellerName: 'Test Seller',
      condition: condition,
      categoryId: categoryId,
      imageUrls: imagePaths,
      createdAt: DateTime(2025),
    );
  }

  @override
  Future<ListingEntity> saveDraft({
    required String title,
    String description = '',
    int priceInCents = 0,
    ListingCondition? condition,
    String? categoryId,
    List<String> imagePaths = const [],
    String? location,
    ShippingCarrier shippingCarrier = ShippingCarrier.none,
    WeightRange? weightRange,
  }) async {
    if (shouldFail) throw Exception('saveDraft failed');
    return ListingEntity(
      id: 'draft-001',
      title: title,
      description: description,
      priceInCents: priceInCents,
      sellerId: 'seller-001',
      sellerName: 'Test Seller',
      condition: condition ?? ListingCondition.good,
      categoryId: categoryId ?? 'cat-1',
      imageUrls: imagePaths,
      createdAt: DateTime(2025),
    );
  }
}

/// Helper to build a container with a real SharedPreferences instance.
({
  ProviderContainer container,
  MockImagePickerService picker,
  MockListingCreationRepository repo,
})
buildContainer(
  SharedPreferences prefs, {
  MockImagePickerService? picker,
  MockListingCreationRepository? repo,
}) {
  final mockPicker = picker ?? MockImagePickerService();
  final mockRepo = repo ?? MockListingCreationRepository();

  final container = ProviderContainer(
    overrides: [
      imagePickerServiceProvider.overrideWithValue(mockPicker),
      listingCreationRepositoryProvider.overrideWithValue(mockRepo),
      createListingUseCaseProvider.overrideWithValue(
        CreateListingUseCase(mockRepo),
      ),
      saveDraftUseCaseProvider.overrideWithValue(SaveDraftUseCase(mockRepo)),
      sharedPreferencesProvider.overrideWithValue(prefs),
      draftPersistenceServiceProvider.overrideWithValue(
        DraftPersistenceService(prefs),
      ),
    ],
  )..listen(listingCreationNotifierProvider, (_, _) {});

  return (container: container, picker: mockPicker, repo: mockRepo);
}
