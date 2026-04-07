import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// A single cell in the photo grid.
///
/// Shows an image with a remove button when [imagePath] is provided,
/// or a dashed-border placeholder when empty.
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.index,
    this.imagePath,
    this.onRemove,
    this.onMenuAction,
    super.key,
  });

  /// Path to the local image file, or null for the empty placeholder.
  final String? imagePath;

  /// Position in the grid (used for reorder context menu).
  final int index;

  /// Called when the user taps the remove button.
  final VoidCallback? onRemove;

  /// Called with a menu action key: 'moveToFront', 'moveUp', 'moveDown'.
  final void Function(String)? onMenuAction;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) return _buildEmptyTile();
    return _buildFilledTile();
  }

  Widget _buildFilledTile() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath!),
            cacheWidth: 300,
            cacheHeight: 300,
            fit: BoxFit.cover,
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
