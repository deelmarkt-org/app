import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/domain/usecases/create_listing_usecase.dart';
import 'package:deelmarkt/features/sell/domain/usecases/save_draft_usecase.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

// ── Mock implementations ──

class _MockImagePickerService extends ImagePickerService {
  _MockImagePickerService() : super(picker: null);

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

class _MockListingCreationRepository implements ListingCreationRepository {
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

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Helper to build a container with a real SharedPreferences instance.
  ({
    ProviderContainer container,
    _MockImagePickerService picker,
    _MockListingCreationRepository repo,
  })
  buildContainer({
    _MockImagePickerService? picker,
    _MockListingCreationRepository? repo,
  }) {
    final mockPicker = picker ?? _MockImagePickerService();
    final mockRepo = repo ?? _MockListingCreationRepository();

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

  group('ListingCreationNotifier — initial state', () {
    test('starts at photos step with empty fields', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
      expect(state.imageFiles, isEmpty);
      expect(state.title, isEmpty);
      expect(state.description, isEmpty);
      expect(state.priceInCents, equals(0));
      expect(state.condition, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorKey, isNull);
    });
  });

  group('ListingCreationNotifier — photo operations', () {
    test('addFromCamera() adds a photo', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(1));
      expect(state.imageFiles.first, equals('/mock/photo.jpg'));
    });

    test('addFromGallery() adds photos', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(2));
    });

    test('removePhoto(index) removes the photo at that index', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      // Add two photos first.
      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      container.read(listingCreationNotifierProvider.notifier).removePhoto(0);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(1));
      expect(state.imageFiles.first, equals('/mock/gallery2.jpg'));
    });

    test('reorderPhotos() changes photo order', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      container
          .read(listingCreationNotifierProvider.notifier)
          .reorderPhotos(0, 2);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles.first, equals('/mock/gallery2.jpg'));
      expect(state.imageFiles.last, equals('/mock/gallery1.jpg'));
    });

    test('max 12 photos enforced — addFromCamera() no-ops at limit', () async {
      final mockPicker = _MockImagePickerService();
      final (:container, picker: _, :repo) = buildContainer(picker: mockPicker);
      addTearDown(container.dispose);

      // Set up a single-path result so we can add one at a time.
      mockPicker.cameraResult = const ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: ['/mock/cam.jpg'],
      );

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      // Add 12 photos.
      for (var i = 0; i < 12; i++) {
        await notifier.addFromCamera();
      }

      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(12),
      );

      // 13th should be a no-op.
      await notifier.addFromCamera();
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(12),
      );
    });

    test('addFromCamera() sets error on permission denied', () async {
      final mockPicker =
          _MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.permissionDenied,
            );

      final (:container, picker: _, :repo) = buildContainer(picker: mockPicker);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.errorPermissionDenied'));
      expect(state.imageFiles, isEmpty);
    });
  });

  group('ListingCreationNotifier — step navigation', () {
    test('nextStep() from photos with 0 images stays and sets error', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final result =
          container.read(listingCreationNotifierProvider.notifier).nextStep();

      expect(result, isFalse);
      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
      expect(state.errorKey, equals('sell.errorNoPhotos'));
    });

    test('nextStep() from photos with 1+ image advances to details', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final result =
          container.read(listingCreationNotifierProvider.notifier).nextStep();

      expect(result, isTrue);
      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.details));
    });

    test(
      'nextStep() from details without title stays and sets error',
      () async {
        final (:container, :picker, :repo) = buildContainer();
        addTearDown(container.dispose);

        // Get to details step.
        await container
            .read(listingCreationNotifierProvider.notifier)
            .addFromCamera();
        container.read(listingCreationNotifierProvider.notifier).nextStep();

        // Set price but not title.
        container
            .read(listingCreationNotifierProvider.notifier)
            .updatePrice(500);

        final result =
            container.read(listingCreationNotifierProvider.notifier).nextStep();

        expect(result, isFalse);
        final state = container.read(listingCreationNotifierProvider);
        expect(state.step, equals(ListingCreationStep.details));
        expect(state.errorKey, equals('sell.errorNoTitle'));
      },
    );

    test(
      'nextStep() from details with valid data advances to quality',
      () async {
        final (:container, :picker, :repo) = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        await notifier.addFromCamera();
        notifier
          ..nextStep() // photos → details
          ..updateTitle('Test Listing Title')
          ..updatePrice(2500);

        final result = notifier.nextStep(); // details → quality

        expect(result, isTrue);
        final state = container.read(listingCreationNotifierProvider);
        expect(state.step, equals(ListingCreationStep.quality));
      },
    );

    test('previousStep() from details goes to photos', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep() // → details
        ..previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
    });

    test('previousStep() from quality goes to details', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep() // → details
        ..updateTitle('Title for test')
        ..updatePrice(1000)
        ..nextStep() // → quality
        ..previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.details));
    });

    test('previousStep() from photos is a no-op', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container.read(listingCreationNotifierProvider.notifier).previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
    });
  });

  group('ListingCreationNotifier — form updates', () {
    test('updateTitle changes title', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateTitle('My Item');

      expect(
        container.read(listingCreationNotifierProvider).title,
        equals('My Item'),
      );
    });

    test('updateDescription changes description', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateDescription('A nice item');

      expect(
        container.read(listingCreationNotifierProvider).description,
        equals('A nice item'),
      );
    });

    test('updatePrice changes priceInCents', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updatePrice(4500);

      expect(
        container.read(listingCreationNotifierProvider).priceInCents,
        equals(4500),
      );
    });

    test('updateCondition changes condition', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateCondition(ListingCondition.likeNew);

      expect(
        container.read(listingCreationNotifierProvider).condition,
        equals(ListingCondition.likeNew),
      );
    });
  });

  group('ListingCreationNotifier — publish', () {
    test('publish() sets step to success with createdListingId', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      // Fill required fields for CreateListingUseCase.
      await notifier.addFromCamera();
      notifier
        ..updateTitle('Test Listing')
        ..updateDescription('A description')
        ..updatePrice(1000)
        ..updateCondition(ListingCondition.good)
        ..updateCategoryL2('cat-sub-1');

      await notifier.publish();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.success));
      expect(state.createdListingId, equals('listing-001'));
      expect(state.isLoading, isFalse);
    });

    test('publish() sets error on failure', () async {
      final mockRepo = _MockListingCreationRepository()..shouldFail = true;
      final (:container, :picker, repo: _) = buildContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      await notifier.addFromCamera();
      notifier
        ..updateTitle('Test')
        ..updateDescription('desc')
        ..updatePrice(1000)
        ..updateCondition(ListingCondition.good)
        ..updateCategoryL2('cat-sub-1');

      await notifier.publish();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.publishError'));
      expect(state.isLoading, isFalse);
    });
  });

  group('ListingCreationNotifier — draft save', () {
    test('saveDraft() sets step to success on completion', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier)
        ..updateTitle('Draft Title');

      await notifier.saveDraft();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.success));
      expect(state.isLoading, isFalse);
    });

    test('saveDraft() sets error on failure', () async {
      final mockRepo = _MockListingCreationRepository()..shouldFail = true;
      final (:container, :picker, repo: _) = buildContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .saveDraft();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.draftError'));
      expect(state.isLoading, isFalse);
    });
  });

  group('ListingCreationNotifier — additional photo error handling', () {
    test('addFromGallery() sets error on permission denied', () async {
      final mockPicker =
          _MockImagePickerService()
            ..galleryResult = const ImagePickerResult(
              type: ImagePickerResultType.permissionDenied,
            );

      final (:container, picker: _, :repo) = buildContainer(picker: mockPicker);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.errorPermissionDenied'));
      expect(state.imageFiles, isEmpty);
    });

    test(
      'addFromCamera() sets errorPermissionPermanent on permanent denial',
      () async {
        final mockPicker =
            _MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.permissionPermanentlyDenied,
              );

        final (:container, picker: _, :repo) = buildContainer(
          picker: mockPicker,
        );
        addTearDown(container.dispose);

        await container
            .read(listingCreationNotifierProvider.notifier)
            .addFromCamera();

        final state = container.read(listingCreationNotifierProvider);
        expect(state.errorKey, equals('sell.errorPermissionPermanent'));
      },
    );

    test('addFromCamera() sets errorFileTooLarge on file too large', () async {
      final mockPicker =
          _MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.fileTooLarge,
            );

      final (:container, picker: _, :repo) = buildContainer(picker: mockPicker);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.errorFileTooLarge'));
    });

    test(
      'addFromCamera() sets errorUnsupportedFormat on unsupported format',
      () async {
        final mockPicker =
            _MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.unsupportedFormat,
              );

        final (:container, picker: _, :repo) = buildContainer(
          picker: mockPicker,
        );
        addTearDown(container.dispose);

        await container
            .read(listingCreationNotifierProvider.notifier)
            .addFromCamera();

        final state = container.read(listingCreationNotifierProvider);
        expect(state.errorKey, equals('sell.errorUnsupportedFormat'));
      },
    );

    test('addFromCamera() no-ops when cancelled', () async {
      final mockPicker =
          _MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.cancelled,
            );

      final (:container, picker: _, :repo) = buildContainer(picker: mockPicker);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.errorImagePicker'));
      expect(state.imageFiles, isEmpty);
    });

    test(
      'addFromGallery() respects remaining slots and no-ops at max',
      () async {
        final mockPicker =
            _MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.success,
                paths: ['/mock/cam.jpg'],
              );

        final (:container, picker: _, :repo) = buildContainer(
          picker: mockPicker,
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        // Fill to 12 via camera.
        for (var i = 0; i < 12; i++) {
          await notifier.addFromCamera();
        }

        // Gallery should be a no-op at max.
        await notifier.addFromGallery();
        expect(
          container.read(listingCreationNotifierProvider).imageFiles,
          hasLength(12),
        );
      },
    );
  });

  group('ListingCreationNotifier — form updates (extended)', () {
    test('updateCategoryL1 changes categoryL1Id', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateCategoryL1('cat-1');

      expect(
        container.read(listingCreationNotifierProvider).categoryL1Id,
        equals('cat-1'),
      );
    });

    test('updateCategoryL2 changes categoryL2Id', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateCategoryL2('sub-1');

      expect(
        container.read(listingCreationNotifierProvider).categoryL2Id,
        equals('sub-1'),
      );
    });

    test('updateShipping changes carrier and weight range', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateShipping(ShippingCarrier.postnl, WeightRange.twoToFive);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.shippingCarrier, equals(ShippingCarrier.postnl));
      expect(state.weightRange, equals(WeightRange.twoToFive));
    });

    test('updateLocation changes location', () {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateLocation('1234AB');

      expect(
        container.read(listingCreationNotifierProvider).location,
        equals('1234AB'),
      );
    });
  });

  group('ListingCreationNotifier — step validation (extended)', () {
    test(
      'nextStep() from details without price stays and sets error',
      () async {
        final (:container, :picker, :repo) = buildContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );
        await notifier.addFromCamera();
        notifier
          ..nextStep() // photos -> details
          ..updateTitle('Has title');

        final result = notifier.nextStep();

        expect(result, isFalse);
        final state = container.read(listingCreationNotifierProvider);
        expect(state.errorKey, equals('sell.errorNoPrice'));
      },
    );

    test('nextStep() from quality is a no-op', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep() // photos -> details
        ..updateTitle('Title')
        ..updatePrice(1000)
        ..nextStep(); // details -> quality

      final result = notifier.nextStep(); // quality -> should be no-op

      expect(result, isFalse);
      expect(
        container.read(listingCreationNotifierProvider).step,
        equals(ListingCreationStep.quality),
      );
    });

    test('removePhoto with invalid index is a no-op', () async {
      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      // Remove at invalid index.
      container.read(listingCreationNotifierProvider.notifier).removePhoto(-1);
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(1),
      );

      container.read(listingCreationNotifierProvider.notifier).removePhoto(5);
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(1),
      );
    });
  });

  group('ListingCreationNotifier — draft persistence integration', () {
    test('build restores state from draft persistence', () async {
      // Pre-populate a draft in SharedPreferences.
      SharedPreferences.setMockInitialValues({
        'listing_creation_draft':
            '{"imageFiles":["/saved/photo.jpg"],"title":"Saved Draft","description":"desc","priceInCents":5000}',
      });
      prefs = await SharedPreferences.getInstance();

      final (:container, :picker, :repo) = buildContainer();
      addTearDown(container.dispose);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.title, equals('Saved Draft'));
      expect(state.imageFiles, contains('/saved/photo.jpg'));
      expect(state.priceInCents, equals(5000));
      // Always restarts from photos step.
      expect(state.step, equals(ListingCreationStep.photos));
    });
  });
}
