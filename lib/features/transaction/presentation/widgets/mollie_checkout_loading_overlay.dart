import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Full-screen translucent loading overlay shown while the Mollie WebView
/// is loading or navigating between pages.
///
/// Announces itself as a live region so screen readers vocalise the
/// "processing" state as soon as it appears (EAA §10 requirement).
///
/// Reference: docs/screens/04-payments/02-mollie-checkout.md §Loading state
class MollieCheckoutLoadingOverlay extends StatelessWidget {
  const MollieCheckoutLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'payment.processing'.tr(),
      liveRegion: true,
      child: Container(
        color:
            isDark
                ? DeelmarktColors.darkScaffold.withValues(alpha: 0.8)
                : DeelmarktColors.white.withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: Spacing.s4),
              Text(
                'payment.processing'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
