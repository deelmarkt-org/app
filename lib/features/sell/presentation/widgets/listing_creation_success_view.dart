import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Success state after a listing is published.
///
/// Shows a check icon, "Gepubliceerd!" heading, and a button
/// to navigate to the listing detail screen.
/// Respects reduced motion for the scale animation.
class ListingCreationSuccessView extends StatelessWidget {
  const ListingCreationSuccessView({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: 1.0,
              duration:
                  reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              child: const Icon(
                PhosphorIconsFill.checkCircle,
                color: DeelmarktColors.success,
                size: 80,
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'sell.published'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s8),
            DeelButton(
              label: 'sell.viewListing'.tr(),
              onPressed: () => context.go('/listings/$listingId'),
            ),
          ],
        ),
      ),
    );
  }
}
