import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

import '../../viewmodels/viewmodel_test_helpers.dart';

/// Stub notifier that returns a fixed [ListingCreationState] and records
/// interactions so tests can assert side-effects of the PhotoStepView.
class StubListingCreationNotifier extends ListingCreationNotifier {
  StubListingCreationNotifier(this._initial, {this.afterPickErrorKey});

  final ListingCreationState _initial;

  /// When non-null, `addFromCamera`/`addFromGallery` patch the state with
  /// this `errorKey` so the view's `_handlePickerError` branch runs.
  final String? afterPickErrorKey;

  int cameraCalls = 0;
  int galleryCalls = 0;
  int nextStepCalls = 0;

  @override
  ListingCreationState build() => _initial;

  @override
  Future<void> addFromCamera() async {
    cameraCalls++;
    if (afterPickErrorKey != null) {
      state = ListingCreationState(
        imageFiles: state.imageFiles,
        errorKey: afterPickErrorKey,
      );
    }
  }

  @override
  Future<void> addFromGallery() async {
    galleryCalls++;
    if (afterPickErrorKey != null) {
      state = ListingCreationState(
        imageFiles: state.imageFiles,
        errorKey: afterPickErrorKey,
      );
    }
  }

  @override
  bool nextStep() {
    nextStepCalls++;
    return true;
  }
}

List<Override> buildPhotoStepOverrides(
  SharedPreferences prefs,
  ListingCreationState state, {
  StubListingCreationNotifier? stub,
}) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  listingCreationNotifierProvider.overrideWith(
    () => stub ?? StubListingCreationNotifier(state),
  ),
  imagePickerServiceProvider.overrideWithValue(MockImagePickerService()),
  imageUploadRepositoryProvider.overrideWithValue(FakeImageUploadRepository()),
  listingCreationRepositoryProvider.overrideWithValue(
    MockListingCreationRepository(),
  ),
];
