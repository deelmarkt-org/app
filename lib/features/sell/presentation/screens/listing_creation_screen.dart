import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/details_step/details_step_view.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/listing_creation_success_view.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/live_preview_panel.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_step_view.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_step_view.dart';

/// Multi-step listing creation wizard.
///
/// Reference: docs/screens/03-listings/02-listing-creation.md
///
/// Single `/sell` route with internal step management via
/// [ListingCreationNotifier]. Steps: photos -> details -> quality -> success.
///
/// On expanded screens, shows a 2-column layout with live preview.
/// Protects against accidental navigation with an unsaved changes dialog.
///
/// Reference: docs/screens/03-listings/02-listing-creation.md
class ListingCreationScreen extends ConsumerStatefulWidget {
  const ListingCreationScreen({super.key});

  @override
  ConsumerState<ListingCreationScreen> createState() =>
      _ListingCreationScreenState();
}

class _ListingCreationScreenState extends ConsumerState<ListingCreationScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingCreationNotifierProvider);

    // Navigate to listing detail on success.
    ref.listen<ListingCreationState>(listingCreationNotifierProvider, (
      prev,
      next,
    ) {
      if (prev?.step != ListingCreationStep.success &&
          next.step == ListingCreationStep.success &&
          next.createdListingId != null) {
        context.go('/listings/${next.createdListingId}');
      }

      // Show all errors except photo picker errors (handled locally
      // in PhotoStepView). Excludelist is safe by default — new errors
      // are shown unless explicitly excluded here.
      const locallyHandledErrors = {
        'sell.errorPermissionDenied',
        'sell.errorPermissionPermanent',
        'sell.errorFileTooLarge',
        'sell.errorUnsupportedFormat',
        'sell.errorImagePicker',
      };
      if (next.errorKey != null &&
          prev?.errorKey != next.errorKey &&
          !locallyHandledErrors.contains(next.errorKey)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorKey!.tr())));
      }
    });

    return PopScope(
      canPop:
          !state.hasUnsavedData || state.step == ListingCreationStep.success,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _buildLeading(state),
          title: Semantics(
            liveRegion: true,
            child: Text(_titleForStep(state.step)),
          ),
        ),
        body: SafeArea(child: _buildBody(context, state)),
      ),
    );
  }

  Widget? _buildLeading(ListingCreationState state) {
    if (state.step == ListingCreationStep.success) return null;

    if (state.step == ListingCreationStep.photos) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          if (state.hasUnsavedData) {
            final shouldDiscard = await _showDiscardDialog();
            if (shouldDiscard && mounted) context.pop();
          } else {
            context.pop();
          }
        },
        tooltip: 'nav.close'.tr(),
      );
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed:
          () =>
              ref.read(listingCreationNotifierProvider.notifier).previousStep(),
      tooltip: 'nav.back'.tr(),
    );
  }

  Widget _buildBody(BuildContext context, ListingCreationState state) {
    if (Breakpoints.isExpanded(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: LivePreviewPanel(state: state)),
          Expanded(child: _buildStepView(state)),
        ],
      );
    }
    return _buildStepView(state);
  }

  Widget _buildStepView(ListingCreationState state) {
    // Step indicator for accessibility.
    final stepNumber = switch (state.step) {
      ListingCreationStep.photos => 1,
      ListingCreationStep.details => 2,
      ListingCreationStep.quality => 3,
      ListingCreationStep.publishing => 3,
      ListingCreationStep.success => 3,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s4,
            vertical: Spacing.s2,
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'sell.stepIndicator'.tr(args: ['$stepNumber', '3']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: switch (state.step) {
            ListingCreationStep.photos => const PhotoStepView(),
            ListingCreationStep.details => const DetailsStepView(),
            ListingCreationStep.quality => const QualityStepView(),
            ListingCreationStep.publishing => const Center(
              child: CircularProgressIndicator(),
            ),
            ListingCreationStep.success => ListingCreationSuccessView(
              listingId: state.createdListingId!,
            ),
          },
        ),
      ],
    );
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('sell.discardTitle'.tr()),
            content: Text('sell.discardMessage'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('sell.keepEditing'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('sell.discard'.tr()),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  String _titleForStep(ListingCreationStep step) => switch (step) {
    ListingCreationStep.photos => 'sell.stepPhotos'.tr(),
    ListingCreationStep.details => 'sell.stepDetails'.tr(),
    ListingCreationStep.quality => 'sell.stepQuality'.tr(),
    ListingCreationStep.publishing => 'sell.stepPublishing'.tr(),
    ListingCreationStep.success => 'sell.stepSuccess'.tr(),
  };
}
