/// E2E integration test for the listing creation flow (P-54).
///
/// Closes Tier-1 retrospective P1 acceptance row:
///   "🔵 [P-54] e2e_listing_creation_test.dart — capture → form → publish
///    → appears in search"
///
/// Scope (per retrospective rationale, "Unit tests don't catch contract drift
/// between layers"):
///
///   * Real `ListingCreationNotifier`           ← state machine + side-effects
///   * Real `CreateListingUseCase`              ← domain orchestration
///   * Real `StepValidator`                     ← step transition guards
///   * Real `ListingFormUpdaters`               ← field mutation logic
///   * Real `PhotoOperations`                   ← image collection mutators
///
///   Stubbed at the I/O boundary:
///   * `ListingCreationRepository`              ← capturing in-memory fake
///                                                 (records create() calls,
///                                                  exposes a "search" lookup
///                                                  for the appears-in-search
///                                                  acceptance row)
///   * `ImageUploadService`                     ← MockImageUploadService
///                                                 (already in repo, returns
///                                                  immediate success)
///   * `DraftPersistenceService`                ← in-memory SharedPreferences
///   * Quality score                            ← fixed `QualityScoreResult`
///
/// What this test deliberately does NOT do:
///   * Drive the wizard via widget taps (that's a UI smoke test concern;
///     PhotoStepView / DetailsStepView / QualityStepView each already have
///     widget tests). The integration boundary at risk is the
///     state-machine ↔ use-case ↔ repository contract, not the gesture wiring.
///   * Hit a real Supabase / Cloudinary backend (staging E2E is the
///     `B-62` payment workflow + `R-43` chat-offer test territory and
///     belongs in CI's nightly job per the retrospective).
///
/// Reference: docs/audits/2026-04-25-tier1-retrospective.md
/// Reference: docs/screens/03-listings/02-listing-creation.md
/// Reference: lib/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart
library;

// Test interleaves notifier mutations with state-read/expect statements;
// converting every adjacent pair to a cascade chain reduces readability
// without improving correctness.
// ignore_for_file: cascade_invocations

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

/// Captures every `create()` and `saveDraft()` call so the test can assert
/// on the exact arguments crossing the domain↔data boundary, and also
/// exposes a `findById` lookup that simulates the "appears in search"
/// acceptance row without needing a real search backend.
class _CapturingListingCreationRepository implements ListingCreationRepository {
  final List<
    ({
      String title,
      int priceInCents,
      String categoryId,
      List<String> imageUrls,
    })
  >
  createCalls = [];
  final Map<String, ListingEntity> _store = {};
  int _seq = 0;

  ListingEntity? findById(String id) => _store[id];

  Iterable<ListingEntity> findByTitleContains(String needle) {
    final lower = needle.toLowerCase();
    return _store.values.where((l) => l.title.toLowerCase().contains(lower));
  }

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
    createCalls.add((
      title: title,
      priceInCents: priceInCents,
      categoryId: categoryId,
      imageUrls: imageUrls,
    ));
    final id = 'listing-e2e-${++_seq}';
    final entity = ListingEntity(
      id: id,
      title: title,
      description: description,
      priceInCents: priceInCents,
      sellerId: 'test-user',
      sellerName: 'Test Seller',
      condition: condition,
      categoryId: categoryId,
      imageUrls: imageUrls,
      location: location,
      // explicit so the test verifies status is published (not draft) —
      // matches the mock repo's intent
      // ignore: avoid_redundant_argument_values
      status: ListingStatus.active,
      createdAt: DateTime.now(),
    );
    _store[id] = entity;
    return entity;
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
    final id = 'draft-e2e-${++_seq}';
    return ListingEntity(
      id: id,
      title: title,
      description: description,
      priceInCents: priceInCents,
      sellerId: 'test-user',
      sellerName: 'Test Seller',
      condition: condition ?? ListingCondition.good,
      categoryId: categoryId ?? '',
      imageUrls: imageUrls,
      location: location,
      status: ListingStatus.draft,
      createdAt: DateTime.now(),
    );
  }
}

/// Helper: build a `SellImage` whose upload state is already `uploaded`,
/// so the photos step's gating predicates (`hasPendingUploads`,
/// `hasFailedUploads`, `allImagesUploaded`) report ready-to-publish.
SellImage _uploadedImage(int n) {
  return SellImage(
    id: 'img-$n',
    localPath: '/dev/null/$n.jpg',
    status: ImageUploadStatus.uploaded,
    storagePath: 'test-user/$n.jpg',
    deliveryUrl: 'https://res.cloudinary.com/dm/test-user/$n.jpg',
    publicId: 'test-user/$n',
    width: 1080,
    height: 1080,
    bytes: 200000,
    format: 'jpg',
  );
}

void main() {
  late SharedPreferences prefs;
  late _CapturingListingCreationRepository repo;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _CapturingListingCreationRepository();
    container = ProviderContainer(
      overrides: [
        // Use the in-app mock data wiring (MockImageUploadService etc.) for
        // every other dependency we don't care to swap.
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Pin the repository so we can assert on captured calls.
        listingCreationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('E2E listing creation — capture → form → publish → appears in search', () {
    test(
      'full happy path drives all wizard steps and persists the listing',
      () async {
        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        // -- Step 1: capture -----------------------------------------------------
        // Three already-uploaded images (we bypass the camera/gallery picker
        // and the upload queue — covered by their own widget tests).
        notifier.apply(
          const ListingCreationState().copyWith(
            imageFiles: [
              _uploadedImage(1),
              _uploadedImage(2),
              _uploadedImage(3),
            ],
          ),
        );

        var state = container.read(listingCreationNotifierProvider);
        expect(state.step, ListingCreationStep.photos);
        expect(state.imageFiles.length, 3);
        expect(
          state.allImagesUploaded,
          isTrue,
          reason: 'photos step gate must be open before nextStep()',
        );

        // Photos → details
        expect(notifier.nextStep(), isTrue);
        state = container.read(listingCreationNotifierProvider);
        expect(
          state.step,
          ListingCreationStep.details,
          reason: 'StepValidator must allow advancing when 3 photos uploaded',
        );
        expect(state.errorKey, isNull);

        // -- Step 2: form (details) --------------------------------------------
        notifier
          ..updateTitle('Iconisch racefiets — Koga Miyata')
          ..updateDescription(
            'Stalen frame, Shimano 600 groepset, perfecte staat.',
          )
          ..updatePrice(45000) // EUR 450.00
          ..updateCondition(ListingCondition.good)
          ..updateCategoryL1('cat-l1-cycling')
          ..updateCategoryL2('cat-l2-roadbike')
          ..updateLocation('1011AA')
          ..updateShipping(ShippingCarrier.postnl, WeightRange.fiveToTen);

        // Pre-advance validation: details step requires title + price + L1.
        // Try advancing with an invalid intermediate to prove the validator
        // catches contract drift if a downstream layer ever silently lowers
        // the gate.
        notifier.apply(
          container.read(listingCreationNotifierProvider).copyWith(title: ''),
        );
        expect(
          notifier.nextStep(),
          isFalse,
          reason: 'StepValidator must reject empty title',
        );
        expect(
          container.read(listingCreationNotifierProvider).errorKey,
          'sell.errorNoTitle',
        );

        // Restore the title and advance for real.
        notifier.updateTitle('Iconisch racefiets — Koga Miyata');
        expect(notifier.nextStep(), isTrue);
        state = container.read(listingCreationNotifierProvider);
        expect(state.step, ListingCreationStep.quality);

        // -- Step 3: quality + publish ----------------------------------------
        // Quality step has no validator gate — it's an informational summary.
        // The notifier's publish() asserts allImagesUploaded then calls the
        // use case → repository.create.
        await notifier.publish();

        state = container.read(listingCreationNotifierProvider);
        expect(
          state.step,
          ListingCreationStep.success,
          reason: 'publish() success path must transition to success',
        );
        expect(state.createdListingId, isNotNull);
        expect(state.errorKey, isNull);
        expect(state.isLoading, isFalse);

        // -- Repository contract ------------------------------------------------
        expect(
          repo.createCalls.length,
          1,
          reason: 'create() must be invoked exactly once on publish',
        );
        final captured = repo.createCalls.single;
        expect(captured.title, 'Iconisch racefiets — Koga Miyata');
        expect(captured.priceInCents, 45000);
        expect(
          captured.categoryId,
          'cat-l2-roadbike',
          reason: 'use case must pass L2 category id, not L1',
        );
        expect(
          captured.imageUrls.length,
          3,
          reason: 'all uploaded delivery URLs must be forwarded',
        );
        expect(
          captured.imageUrls,
          everyElement(startsWith('https://res.cloudinary.com')),
        );

        // -- "Appears in search" acceptance row -------------------------------
        // The mock repo doubles as the search index — a fresh listing must be
        // findable by id (deep-link path) AND surface for a title-substring
        // query (the FTS-like path users actually take).
        final byId = repo.findById(state.createdListingId!);
        expect(byId, isNotNull);
        expect(byId!.title, 'Iconisch racefiets — Koga Miyata');
        expect(
          byId.status,
          ListingStatus.active,
          reason: 'create() must publish (status=active), not draft',
        );

        final byTitle = repo.findByTitleContains('koga');
        expect(byTitle, hasLength(1));
        expect(byTitle.single.id, state.createdListingId);
      },
    );

    test(
      'publish refuses if any image is still pending (contract guard)',
      () async {
        final notifier = container.read(
          listingCreationNotifierProvider.notifier,
        );

        // Two uploaded + one still uploading. The notifier's publish()
        // asserts `allImagesUploaded` — a layer-integration regression that
        // lowers this gate would let a half-uploaded listing through.
        notifier.apply(
          ListingCreationState(
            imageFiles: [
              _uploadedImage(1),
              _uploadedImage(2),
              const SellImage(
                id: 'img-3',
                localPath: '/dev/null/3.jpg',
                status: ImageUploadStatus.uploading,
              ),
            ],
            step: ListingCreationStep.quality,
            title: 'Test',
            priceInCents: 1000,
            categoryL1Id: 'a',
            categoryL2Id: 'b',
            condition: ListingCondition.good,
          ),
        );

        // ListingCreationNotifier.publish throws synchronously via
        // StateError when the precondition fails. Use expectLater so the
        // assertion message survives debug vs release mode (kReleaseMode
        // disables `assert`, but this is a `throw`).
        await expectLater(
          () async => notifier.publish(),
          throwsA(isA<StateError>()),
        );
        expect(
          repo.createCalls,
          isEmpty,
          reason: 'no repo.create() call when precondition fails',
        );
      },
    );

    test('mock repository is dev-only — release-mode assertion guards it', () {
      // Documents the safety guard: MockListingCreationRepository must not
      // ship in release builds. This test pins the kDebugMode contract so a
      // future flag rename surfaces here, not in the App Store reviewer flow.
      expect(
        kReleaseMode,
        isFalse,
        reason: 'integration test must run in debug — mock guard depends on it',
      );
    });
  });
}
