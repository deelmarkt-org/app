import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
/// * failed (terminal) → error tint + warning icon + optional error text
/// * uploaded → plain image
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.index,
    this.image,
    this.onRemove,
    this.onRetry,
    this.onMenuAction,
    this.isRetrying = false,
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

  /// True while this photo is currently in retry backoff (429 rate-limit,
  /// transient network error). Drives the live-region Semantics announcement
  /// so screen-reader users know the upload isn't stalled — EAA §10.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final img = image;
    if (img == null) return _buildEmptyTile();
    return _buildFilledTile(context, img);
  }

  Widget _buildFilledTile(BuildContext context, SellImage img) {
    // Prefer the Cloudinary delivery URL once uploaded — avoids loading
    // from a potentially stale or missing local file path (M7).
    // On web, dart:io File is not available; kIsWeb guards prevent runtime
    // errors — the null branch renders a neutral placeholder instead.
    // ResizeImage caps memory cache at 300×300 logical pixels for both
    // network and file sources (cacheWidth/Height not available on Image()).
    final ImageProvider? rawProvider =
        img.isUploaded && img.deliveryUrl != null
            ? NetworkImage(img.deliveryUrl!)
            : kIsWeb
            ? null // no local File on web — show placeholder
            : FileImage(File(img.localPath));

    final Widget imageWidget =
        rawProvider != null
            ? Image(
              image: ResizeImage(rawProvider, width: 300, height: 300),
              fit: BoxFit.cover,
            )
            : const ColoredBox(
              color: DeelmarktColors.neutral200,
              child: Center(
                child: Icon(
                  PhosphorIconsRegular.image,
                  color: DeelmarktColors.neutral500,
                ),
              ),
            );

    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(opacity: img.isUploaded ? 1.0 : 0.6, child: imageWidget),
          if (img.isPending) _UploadingOverlay(isRetrying: isRetrying),
          if (img.isFailed)
            _FailedOverlay(
              canRetry: img.canRetry,
              onRetry: onRetry,
              errorKey: img.errorKey,
            ),
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
  const _UploadingOverlay({this.isRetrying = false});

  /// When true, the Semantics label announces the retry state so screen
  /// readers can tell the user the client is actively waiting for a
  /// server-advised retry window (not stalled).
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: (isRetrying ? 'sell.uploadRetrying' : 'sell.uploadingImage').tr(),
      // Fix #126: liveRegion announces upload progress to screen readers (EAA §10)
      liveRegion: true,
      child: Container(
        // Fix #125: use design token instead of hardcoded Colors.black26
        color: DeelmarktColors.neutral900.withValues(alpha: 0.50),
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
/// Shows a localised error message when [errorKey] is provided.
class _FailedOverlay extends StatelessWidget {
  const _FailedOverlay({
    required this.canRetry,
    required this.onRetry,
    this.errorKey,
  });

  final bool canRetry;
  final VoidCallback? onRetry;
  final String? errorKey;

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
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsRegular.warning,
                    color: DeelmarktColors.white,
                    size: 28,
                  ),
                  if (errorKey != null) ...[
                    const SizedBox(height: Spacing.s1),
                    Text(
                      errorKey!.tr(),
                      style: const TextStyle(
                        color: DeelmarktColors.white,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
