import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';

import 'viewmodel_test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ListingCreationNotifier -- step navigation', () {
    test('nextStep() from photos with 0 images stays and sets error', () {
      final (:container, :picker, :repo) = buildContainer(prefs);
      addTearDown(container.dispose);

      final result =
          container.read(listingCreationNotifierProvider.notifier).nextStep();

      expect(result, isFalse);
      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
      expect(state.errorKey, equals('sell.errorNoPhotos'));
    });

    test('nextStep() from photos with 1+ image advances to details', () async {
      final (:container, :picker, :repo) = buildContainer(prefs);
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
        final (:container, :picker, :repo) = buildContainer(prefs);
        addTearDown(container.dispose);

        await container
            .read(listingCreationNotifierProvider.notifier)
            .addFromCamera();
        container.read(listingCreationNotifierProvider.notifier).nextStep();

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
        final (:container, :picker, :repo) = buildContainer(prefs);
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        await notifier.addFromCamera();
        notifier
          ..nextStep()
          ..updateTitle('Test Listing Title')
          ..updatePrice(2500)
          ..updateCategoryL2('sub-cat-1');

        final result = notifier.nextStep();

        expect(result, isTrue);
        final state = container.read(listingCreationNotifierProvider);
        expect(state.step, equals(ListingCreationStep.quality));
      },
    );

    test('previousStep() from details goes to photos', () async {
      final (:container, :picker, :repo) = buildContainer(prefs);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep()
        ..previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
    });

    test('previousStep() from quality goes to details', () async {
      final (:container, :picker, :repo) = buildContainer(prefs);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep()
        ..updateTitle('Title for test')
        ..updatePrice(1000)
        ..updateCategoryL2('sub-cat-1')
        ..nextStep()
        ..previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.details));
    });

    test('previousStep() from photos is a no-op', () {
      final (:container, :picker, :repo) = buildContainer(prefs);
      addTearDown(container.dispose);

      container.read(listingCreationNotifierProvider.notifier).previousStep();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.photos));
    });

    test(
      'nextStep() from details without price stays and sets error',
      () async {
        final (:container, :picker, :repo) = buildContainer(prefs);
        addTearDown(container.dispose);

        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );
        await notifier.addFromCamera();
        notifier
          ..nextStep()
          ..updateTitle('Has title');

        final result = notifier.nextStep();

        expect(result, isFalse);
        final state = container.read(listingCreationNotifierProvider);
        expect(state.errorKey, equals('sell.errorNoPrice'));
      },
    );

    test('nextStep() from quality is a no-op', () async {
      final (:container, :picker, :repo) = buildContainer(prefs);
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);
      await notifier.addFromCamera();
      notifier
        ..nextStep()
        ..updateTitle('Title')
        ..updatePrice(1000)
        ..updateCategoryL2('sub-cat-1')
        ..nextStep();

      final result = notifier.nextStep();

      expect(result, isFalse);
      expect(
        container.read(listingCreationNotifierProvider).step,
        equals(ListingCreationStep.quality),
      );
    });
  });
}
