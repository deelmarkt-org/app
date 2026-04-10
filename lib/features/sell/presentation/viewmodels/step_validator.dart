import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';

/// Wizard step validation + navigation graph.
///
/// Extracted from [ListingCreationNotifier] so the ViewModel stays focused
/// on state mutation; keeping the validator pure makes it trivially testable
/// without a ProviderContainer.
class StepValidator {
  const StepValidator._();

  /// Returns the l10n error key if [state] fails the current step's rules,
  /// or null if it is ready to advance.
  static String? validate(ListingCreationState state) {
    switch (state.step) {
      case ListingCreationStep.photos:
        if (state.imageFiles.isEmpty) return 'sell.errorNoPhotos';
        if (state.hasFailedUploads) return 'sell.errorImagesFailed';
        if (state.hasPendingUploads) return 'sell.errorImagesUploading';
        return null;
      case ListingCreationStep.details:
        if (state.title.trim().isEmpty) return 'sell.errorNoTitle';
        if (state.priceInCents <= 0) return 'sell.errorNoPrice';
        if (state.categoryL1Id == null) return 'sell.errorNoCategory';
        return null;
      case ListingCreationStep.quality:
      case ListingCreationStep.publishing:
      case ListingCreationStep.success:
        return null;
    }
  }

  /// Next step in the wizard, or null if [current] has no forward edge.
  static ListingCreationStep? next(ListingCreationStep current) {
    return switch (current) {
      ListingCreationStep.photos => ListingCreationStep.details,
      ListingCreationStep.details => ListingCreationStep.quality,
      _ => null,
    };
  }

  /// Previous step in the wizard, or null if [current] has no back edge.
  static ListingCreationStep? previous(ListingCreationStep current) {
    return switch (current) {
      ListingCreationStep.details => ListingCreationStep.photos,
      ListingCreationStep.quality => ListingCreationStep.details,
      _ => null,
    };
  }
}
