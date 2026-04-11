import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Photo collection step of the listing creation wizard.
///
/// Displays the photo grid, add-photo button, and next button.
/// Handles image picker results including permission errors.
class PhotoStepView extends ConsumerWidget {
  const PhotoStepView({super.key});

  static const _maxPhotos = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(listingCreationNotifierProvider);
    final notifier = ref.read(listingCreationNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'sell.photosCount'.tr(
                args: ['${state.imageFiles.length}', '$_maxPhotos'],
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: Spacing.s3),
        Expanded(
          child: PhotoGrid(
            imageFiles: state.imageFiles,
            onRemove: notifier.removePhoto,
            onRetry: notifier.retryUpload,
            onReorder: notifier.reorderPhotos,
          ),
        ),
        if (state.imageFiles.length < _maxPhotos)
          Padding(
            padding: const EdgeInsets.all(Spacing.s4),
            child: DeelButton(
              label: 'sell.addPhotos'.tr(),
              variant: DeelButtonVariant.outline,
              onPressed: () => _showPickerSheet(context, ref),
              leadingIcon: PhosphorIconsRegular.camera,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(Spacing.s4),
          child: DeelButton(
            label: 'sell.next'.tr(),
            onPressed:
                state.allImagesUploaded ? () => notifier.nextStep() : null,
          ),
        ),
      ],
    );
  }

  Future<void> _showPickerSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'sell.takePhoto'.tr(),
                  child: ListTile(
                    leading: const Icon(PhosphorIconsRegular.camera),
                    title: Text('sell.takePhoto'.tr()),
                    onTap: () => Navigator.pop(context, 'camera'),
                  ),
                ),
                Semantics(
                  label: 'sell.chooseFromGallery'.tr(),
                  child: ListTile(
                    leading: const Icon(PhosphorIconsRegular.images),
                    title: Text('sell.chooseFromGallery'.tr()),
                    onTap: () => Navigator.pop(context, 'gallery'),
                  ),
                ),
              ],
            ),
          ),
    );

    if (choice == null || !context.mounted) return;

    final notifier = ref.read(listingCreationNotifierProvider.notifier);

    if (choice == 'camera') {
      await notifier.addFromCamera();
    } else {
      await notifier.addFromGallery();
    }

    if (!context.mounted) return;

    final state = ref.read(listingCreationNotifierProvider);
    if (state.errorKey != null) {
      _handlePickerError(context, state.errorKey!);
    }
  }

  void _handlePickerError(BuildContext context, String errorKey) {
    if (errorKey == 'sell.errorPermissionPermanent') {
      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('sell.cameraPermissionDenied'.tr()),
              content: Text('sell.openSettingsHint'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('action.cancel'.tr()),
                ),
              ],
            ),
      );
      return;
    }

    final message = switch (errorKey) {
      'sell.errorPermissionDenied' => 'sell.cameraPermissionDenied'.tr(),
      'sell.errorFileTooLarge' => 'sell.errorFileTooLarge'.tr(),
      'sell.errorUnsupportedFormat' => 'sell.unsupportedImageFormat'.tr(),
      _ => 'sell.galleryPermissionDenied'.tr(),
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
