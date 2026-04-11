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

  group('ListingCreationNotifier -- publish', () {
    test('publish() sets step to success with createdListingId', () async {
      final (:container, :picker, :repo, uploadService: _) = buildContainer(
        prefs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      await notifier.addFromCamera();
      await pumpUntilUploaded(container);
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
      final mockRepo = MockListingCreationRepository()..shouldFail = true;
      final (:container, :picker, repo: _, uploadService: _) = buildContainer(
        prefs,
        repo: mockRepo,
      );
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier);

      await notifier.addFromCamera();
      await pumpUntilUploaded(container);
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

  group('ListingCreationNotifier -- draft save', () {
    test('saveDraft() sets step to success on completion', () async {
      final (:container, :picker, :repo, uploadService: _) = buildContainer(
        prefs,
      );
      addTearDown(container.dispose);

      final notifier = container.read(listingCreationNotifierProvider.notifier)
        ..updateTitle('Draft Title');

      await notifier.saveDraft();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.step, equals(ListingCreationStep.success));
      expect(state.isLoading, isFalse);
    });

    test('saveDraft() sets error on failure', () async {
      final mockRepo = MockListingCreationRepository()..shouldFail = true;
      final (:container, :picker, repo: _, uploadService: _) = buildContainer(
        prefs,
        repo: mockRepo,
      );
      addTearDown(container.dispose);

      await container
          .read(listingCreationNotifierProvider.notifier)
          .saveDraft();

      final state = container.read(listingCreationNotifierProvider);
      expect(state.errorKey, equals('sell.draftError'));
      expect(state.isLoading, isFalse);
    });
  });

  group('ListingCreationNotifier -- draft persistence integration', () {
    test('build restores state from draft persistence', () async {
      SharedPreferences.setMockInitialValues({
        'listing_creation_draft':
            '{"v":2,"imageFiles":[{"id":"saved-1","localPath":"/saved/photo.jpg","storagePath":"fake/saved-1.jpg","deliveryUrl":"https://cdn.test/saved-1.jpg"}],"title":"Saved Draft","description":"desc","priceInCents":5000}',
      });
      prefs = await SharedPreferences.getInstance();

      final (:container, :picker, :repo, uploadService: _) = buildContainer(
        prefs,
      );
      addTearDown(container.dispose);

      final state = container.read(listingCreationNotifierProvider);
      expect(state.title, equals('Saved Draft'));
      expect(state.imageFiles, hasLength(1));
      expect(state.imageFiles.first.id, equals('saved-1'));
      expect(state.imageFiles.first.localPath, equals('/saved/photo.jpg'));
      expect(
        state.imageFiles.first.deliveryUrl,
        equals('https://cdn.test/saved-1.jpg'),
      );
      expect(state.priceInCents, equals(5000));
      expect(state.step, equals(ListingCreationStep.photos));
    });
  });
}
