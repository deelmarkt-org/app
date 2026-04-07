import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Live preview panel shown on expanded (tablet/desktop) layouts.
///
/// Displays the first photo, title, and price from the current
/// [ListingCreationState] as a card preview.
class LivePreviewPanel extends StatelessWidget {
  const LivePreviewPanel({required this.state, super.key});

  final ListingCreationState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sell.livePreview'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: Spacing.s3),
              // Preview image placeholder or first photo.
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: DeelmarktColors.neutral100,
                    borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
                  ),
                  child:
                      state.imageFiles.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DeelmarktRadius.sm,
                            ),
                            child: Image.file(
                              File(state.imageFiles.first),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, e, st) => const Center(
                                    child: Icon(Icons.image, size: 48),
                                  ),
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: DeelmarktColors.neutral500,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: Spacing.s3),
              // Preview title.
              Text(
                state.title.isNotEmpty
                    ? state.title
                    : 'sell.previewTitlePlaceholder'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.s1),
              // Preview price.
              Text(
                state.priceInCents > 0
                    ? '\u20AC ${(state.priceInCents / 100).toStringAsFixed(2)}'
                    : '\u20AC 0,00',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DeelmarktColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
