import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';

import 'viewmodel_test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ListingCreationNotifier -- photo operations', () {
    test('addFromCamera() adds a photo', () async {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(1));
      expect(state.imageFiles.first.localPath, equals('/mock/photo.jpg'));
    });

    test('addFromGallery() adds photos', () async {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(2));
    });

    test('removePhoto(id) removes the photo with that id', () async {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromGallery();

      final firstId =
          container.read(listingCreationNotifierProvider).imageFiles.first.id;
      notifier.removePhoto(firstId);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles, hasLength(1));
      expect(state.imageFiles.first.localPath, equals('/mock/gallery2.jpg'));
    });

    test('reorderPhotos() changes photo order', () async {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromGallery();

      container
          .read(listingCreationNotifierProvider.notifier)
          .reorderPhotos(0, 2);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.imageFiles.first.localPath, equals('/mock/gallery2.jpg'));
      expect(state.imageFiles.last.localPath, equals('/mock/gallery1.jpg'));
    });

    test('max 12 photos enforced -- addFromCamera() no-ops at limit', () async {
      final mockPicker = MockImagePickerService();
      final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
        prefs,
        picker: mockPicker,
      );
      addTearDown(container.dispose);

      mockPicker.cameraResult = const ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: ['/mock/cam.jpg'],
      );

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      for (var i = 0; i < 12; i++) {
        await notifier.addFromCamera();
      }

      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(12),
      );

      await notifier.addFromCamera();
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(12),
      );
    });

    test('addFromCamera() sets error on permission denied', () async {
      final mockPicker =
          MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.permissionDenied,
            );

      final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
        prefs,
        picker: mockPicker,
      );
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .addFromCamera();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.errorPermissionDenied'));
      expect(state.imageFiles, isEmpty);
    });

    test('addFromGallery() sets error on permission denied', () async {
      final mockPicker =
          MockImagePickerService()
            ..galleryResult = const ImagePickerResult(
              type: ImagePickerResultType.permissionDenied,
            );

      final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
        prefs,
        picker: mockPicker,
      );
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
            MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.permissionPermanentlyDenied,
              );

        final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
          prefs,
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
          MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.fileTooLarge,
            );

      final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
        prefs,
        picker: mockPicker,
      );
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
            MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.unsupportedFormat,
              );

        final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
          prefs,
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
          MockImagePickerService()
            ..cameraResult = const ImagePickerResult(
              type: ImagePickerResultType.cancelled,
            );

      final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
        prefs,
        picker: mockPicker,
      );
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
            MockImagePickerService()
              ..cameraResult = const ImagePickerResult(
                type: ImagePickerResultType.success,
                paths: ['/mock/cam.jpg'],
              );

        final (:container, picker: _, :repo, uploadRepo: _) = buildContainer(
          prefs,
          picker: mockPicker,
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        for (var i = 0; i < 12; i++) {
          await notifier.addFromCamera();
        }

        await notifier.addFromGallery();
        expect(
          container.read(listingCreationNotifierProvider).imageFiles,
          hasLength(12),
        );
      },
    );

    test('removePhoto with unknown id is a no-op', () async {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();

      notifier.removePhoto('does-not-exist');
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(1),
      );

      notifier.removePhoto('another-unknown');
      expect(
        container.read(listingCreationNotifierProvider).imageFiles,
        hasLength(1),
      );
    });
  });
}
