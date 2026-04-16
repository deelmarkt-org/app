import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/data/services/sell_services_providers.dart';
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

/// Fake [ImageUploadService] for tests — never hits the network.
///
/// By default returns a deterministic [ImageUploadResponse] for every call.
/// Set [shouldFail] to true to simulate upload failures.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class FakeImageUploadService extends ImageUploadService {
  FakeImageUploadService() : super(_MockSupabaseClient());

  bool shouldFail = false;
  final List<String> deletedPaths = [];

  @override
  Future<String> reserveAndUpload(File localFile) async {
    if (shouldFail) throw Exception('upload failed');
    final name = localFile.path.split(RegExp(r'[/\\]')).last;
    return 'fake/$name';
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    return ImageUploadResponse(
      storagePath: storagePath,
      deliveryUrl: 'https://cdn.test/${storagePath.split('/').last}',
      publicId: storagePath,
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
  FakeImageUploadService uploadService,
})
buildContainer(
  SharedPreferences prefs, {
  MockImagePickerService? picker,
  MockListingCreationRepository? repo,
  FakeImageUploadService? uploadService,
}) {
  final mockPicker = picker ?? MockImagePickerService();
  final mockRepo = repo ?? MockListingCreationRepository();
  final fakeService = uploadService ?? FakeImageUploadService();

  final container = ProviderContainer(
    overrides: [
      imagePickerServiceProvider.overrideWithValue(mockPicker),
      listingCreationRepositoryProvider.overrideWithValue(mockRepo),
      imageUploadServiceProvider.overrideWithValue(fakeService),
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
    uploadService: fakeService,
  );
}
