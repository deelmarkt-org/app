import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/repositories/image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/create_listing_usecase.dart';
import 'package:deelmarkt/features/sell/domain/usecases/save_draft_usecase.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
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
    required List<String> imageUrls,
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
      imageUrls: imageUrls,
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
    List<String> imageUrls = const [],
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
      imageUrls: imageUrls,
      createdAt: DateTime(2025),
    );
  }
}

/// Fake [ImageUploadRepository] for tests — never hits the network.
/// By default returns a deterministic success for every call; override
/// [shouldFail] to simulate failures.
class FakeImageUploadRepository implements ImageUploadRepository {
  bool shouldFail = false;
  final List<String> deletedPaths = [];

  @override
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  }) async {
    if (shouldFail) {
      throw Exception('upload failed');
    }
    return UploadedImage(
      storagePath: 'fake/$id.jpg',
      deliveryUrl: 'https://cdn.test/$id.jpg',
      publicId: 'fake_$id',
      width: 1024,
      height: 1024,
      bytes: 1000,
      format: 'jpg',
    );
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    deletedPaths.add(storagePath);
  }
}

/// Flushes the event loop until every picked image has finished uploading
/// (or a short safety deadline elapses). Used by navigation/publish tests
/// that need the upload queue outcomes to be applied before asserting on
/// step transitions that check `allImagesUploaded`.
Future<void> pumpUntilUploaded(ProviderContainer container) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    final s = container.read(listingCreationNotifierProvider);
    if (s.imageFiles.isEmpty || s.imageFiles.every((i) => i.isUploaded)) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
}

/// Helper to build a container with a real SharedPreferences instance.
({
  ProviderContainer container,
  MockImagePickerService picker,
  MockListingCreationRepository repo,
  FakeImageUploadRepository uploadRepo,
})
buildContainer(
  SharedPreferences prefs, {
  MockImagePickerService? picker,
  MockListingCreationRepository? repo,
  FakeImageUploadRepository? uploadRepo,
}) {
  final mockPicker = picker ?? MockImagePickerService();
  final mockRepo = repo ?? MockListingCreationRepository();
  final fakeUploadRepo = uploadRepo ?? FakeImageUploadRepository();

  final container = ProviderContainer(
    overrides: [
      imagePickerServiceProvider.overrideWithValue(mockPicker),
      listingCreationRepositoryProvider.overrideWithValue(mockRepo),
      imageUploadRepositoryProvider.overrideWithValue(fakeUploadRepo),
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

  return (
    container: container,
    picker: mockPicker,
    repo: mockRepo,
    uploadRepo: fakeUploadRepo,
  );
}
