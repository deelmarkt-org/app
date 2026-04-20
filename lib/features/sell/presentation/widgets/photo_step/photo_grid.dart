import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';
import 'package:deelmarkt/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart';

/// A grid of photos with drag-to-reorder and accessible menu alternatives.
///
/// Uses [LongPressDraggable] + [DragTarget] for reordering, with a
/// [PopupMenuButton] fallback for WCAG 2.5.7 non-drag accessibility.
///
/// [retryingIds] is injected by the parent (typically via
/// `ref.watch(retryingPhotoIdsProvider)`) — keeping this widget stateless
/// and free of Riverpod coupling simplifies testing.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    required this.imageFiles,
    required this.onRemove,
    required this.onRetry,
    required this.onReorder,
    this.retryingIds = const <String>{},
    super.key,
  });

  /// Picked images with per-item upload state.
  final List<SellImage> imageFiles;

  /// Called when the user removes a photo with [id].
  final void Function(String id) onRemove;

  /// Called when the user retries a failed upload for [id].
  final void Function(String id) onRetry;

  /// Called to reorder a photo from [oldIndex] to [newIndex].
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Photo IDs currently in retry backoff. The matching tile's overlay
  /// switches its Semantics label to `sell.uploadRetrying` for EAA §10.
  final Set<String> retryingIds;

  @override
  Widget build(BuildContext context) {
    final columns = Breakpoints.isCompact(context) ? 2 : 3;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: Spacing.s2,
        mainAxisSpacing: Spacing.s2,
      ),
      itemCount: imageFiles.length,
      itemBuilder:
          (context, index) => _buildDraggableCell(context, index, retryingIds),
    );
  }

  Widget _buildDraggableCell(
    BuildContext context,
    int index,
    Set<String> retryingIds,
  ) {
    final tile = _buildTileWithMenu(index, retryingIds);
    final img = imageFiles[index];
    final isRetrying = retryingIds.contains(img.id);

    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        child: SizedBox(
          width: 120,
          height: 120,
          child: PhotoGridTile(
            image: img,
            index: index,
            isRetrying: isRetrying,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) => onReorder(details.data, index),
        builder: (context, candidateData, rejectedData) {
          if (candidateData.isNotEmpty) {
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
              ),
              child: tile,
            );
          }
          return tile;
        },
      ),
    );
  }

  /// Builds a tile with a popup menu for WCAG 2.5.7 non-drag alternative.
  Widget _buildTileWithMenu(int index, Set<String> retryingIds) {
    final isFirst = index == 0;
    final isLast = index == imageFiles.length - 1;
    final img = imageFiles[index];

    return Stack(
      children: [
        PhotoGridTile(
          image: img,
          index: index,
          onRemove: () => onRemove(img.id),
          onRetry: () => onRetry(img.id),
          isRetrying: retryingIds.contains(img.id),
        ),
        if (!isFirst || !isLast)
          Positioned(
            bottom: Spacing.s1,
            right: Spacing.s1,
            child: _ReorderMenu(
              showMoveToFront: !isFirst,
              showMoveUp: !isFirst,
              showMoveDown: !isLast,
              onAction: (action) => _handleMenuAction(action, index),
            ),
          ),
      ],
    );
  }

  void _handleMenuAction(String action, int index) {
    switch (action) {
      case 'moveToFront':
        onReorder(index, 0);
      case 'moveUp':
        onReorder(index, index - 1);
      case 'moveDown':
        onReorder(index, index + 2);
    }
  }
}

/// Popup menu for non-drag reorder actions (WCAG 2.5.7).
class _ReorderMenu extends StatelessWidget {
  const _ReorderMenu({
    required this.showMoveToFront,
    required this.showMoveUp,
    required this.showMoveDown,
    required this.onAction,
  });

  final bool showMoveToFront;
  final bool showMoveUp;
  final bool showMoveDown;
  final void Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: PopupMenuButton<String>(
        onSelected: onAction,
        padding: EdgeInsets.zero,
        iconSize: 20,
        itemBuilder:
            (_) => [
              if (showMoveToFront)
                PopupMenuItem(
                  value: 'moveToFront',
                  child: Text('sell.moveToFront'.tr()),
                ),
              if (showMoveUp)
                PopupMenuItem(value: 'moveUp', child: Text('sell.moveUp'.tr())),
              if (showMoveDown)
                PopupMenuItem(
                  value: 'moveDown',
                  child: Text('sell.moveDown'.tr()),
                ),
            ],
      ),
    );
  }
}
