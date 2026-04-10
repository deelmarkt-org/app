import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';

import 'viewmodel_test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('ListingCreationNotifier -- initial state', () {
    test('starts at photos step with empty fields', () {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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

  group('ListingCreationNotifier -- form updates', () {
    test('updateTitle changes title', () {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateCondition(ListingCondition.likeNew);

      expect(
        container.read(listingCreationNotifierProvider).condition,
        equals(ListingCondition.likeNew),
      );
    });

    test('updateCategoryL1 changes categoryL1Id', () {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
      addTearDown(container.dispose);

      container
          .read(listingCreationNotifierProvider.notifier)
          .updateShipping(ShippingCarrier.postnl, WeightRange.twoToFive);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.shippingCarrier, equals(ShippingCarrier.postnl));
      expect(state.weightRange, equals(WeightRange.twoToFive));
    });

    test('updateLocation changes location', () {
      final (:container, :picker, :repo, uploadRepo: _) = buildContainer(prefs);
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
}
