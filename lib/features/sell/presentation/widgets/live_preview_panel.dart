import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
              _ImagePreview(imageFiles: state.imageFiles),
              const SizedBox(height: Spacing.s3),
              _TitleText(title: state.title, context: context),
              const SizedBox(height: Spacing.s1),
              _PriceText(priceInCents: state.priceInCents, context: context),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageFiles});

  final List<SellImage> imageFiles;

  Widget _buildPreviewImage(List<SellImage> images) {
    if (images.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: DeelmarktColors.neutral500,
        ),
      );
    }

    final first = images.first;

    // Prefer Cloudinary delivery URL (available once uploaded).
    // On web, dart:io File is unavailable; kIsWeb guard prevents runtime error.
    if (first.isUploaded && first.deliveryUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        child: Image.network(
          first.deliveryUrl!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.image, size: 48)),
        ),
      );
    }

    if (!kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        child: Image.file(
          File(first.localPath),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.image, size: 48)),
        ),
      );
    }

    // Web + no delivery URL yet → neutral placeholder.
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: DeelmarktColors.neutral500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: DeelmarktColors.neutral100,
          borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        ),
        child: _buildPreviewImage(imageFiles),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title, required this.context});

  final String title;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Text(
      title.isNotEmpty ? title : 'sell.previewTitlePlaceholder'.tr(),
      style: Theme.of(context).textTheme.titleMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({required this.priceInCents, required this.context});

  final int priceInCents;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final label =
        priceInCents > 0
            ? '\u20AC ${(priceInCents / 100).toStringAsFixed(2)}'
            : '\u20AC 0,00';
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: DeelmarktColors.primary),
    );
  }
}
