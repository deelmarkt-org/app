import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';

/// A single cell in the photo grid.
///
/// Renders a [SellImage] with per-status overlays:
/// * pending/uploading → dimmed + centered spinner
/// * failed (retryable) → error tint + retry button
/// * failed (terminal) → error tint + remove-only
/// * uploaded → plain image
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.index,
    this.image,
    this.onRemove,
    this.onRetry,
    this.onMenuAction,
    super.key,
  });

  /// The image model, or null for the empty placeholder.
  final SellImage? image;

  /// Position in the grid (used for reorder context menu).
  final int index;

  /// Called when the user taps the remove button.
  final VoidCallback? onRemove;

  /// Called when the user taps the retry affordance on a failed tile.
  final VoidCallback? onRetry;

  /// Called with a menu action key: 'moveToFront', 'moveUp', 'moveDown'.
  final void Function(String)? onMenuAction;

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) return _buildEmptyTile();
    return _buildFilledTile(context, img);
  }

  Widget _buildFilledTile(BuildContext context, SellImage img) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: img.isUploaded ? 1.0 : 0.6,
            child: Image.file(
              File(img.localPath),
              cacheWidth: 300,
              cacheHeight: 300,
              fit: BoxFit.cover,
            ),
          ),
          if (img.isPending) const _UploadingOverlay(),
          if (img.isFailed)
            _FailedOverlay(canRetry: img.canRetry, onRetry: onRetry),
          Positioned(
            top: Spacing.s1,
            right: Spacing.s1,
            child: _RemoveButton(onTap: onRemove),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTile() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DeelmarktColors.neutral300),
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      ),
      child: const Center(
        child: Icon(
          PhosphorIconsRegular.camera,
          color: DeelmarktColors.neutral500,
        ),
      ),
    );
  }
}

/// Centered spinner shown while a photo is pending/uploading.
class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'sell.uploadingImage'.tr(),
      child: Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(DeelmarktColors.white),
          ),
        ),
      ),
    );
  }
}

/// Error overlay shown when upload failed; includes retry when retryable.
class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({required this.canRetry, required this.onRetry});

  final bool canRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DeelmarktColors.error.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child:
          canRetry && onRetry != null
              ? Semantics(
                label: 'sell.retryUpload'.tr(),
                button: true,
                child: IconButton(
                  onPressed: onRetry,
                  icon: const Icon(
                    PhosphorIconsRegular.arrowClockwise,
                    color: DeelmarktColors.white,
                  ),
                ),
              )
              : const Icon(
                PhosphorIconsRegular.warning,
                color: DeelmarktColors.white,
                size: 28,
              ),
    );
  }
}

/// 44x44 remove button with circular background and X icon.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'action.delete'.tr(),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: DeelmarktColors.neutral900,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.x,
              color: DeelmarktColors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
