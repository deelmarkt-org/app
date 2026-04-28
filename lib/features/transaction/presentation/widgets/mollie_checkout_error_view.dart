import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

/// Error view shown when the Mollie checkout WebView fails to load.
///
/// Provides a retry button (reloads the checkout URL) and a cancel button
/// (dismisses the flow and returns [MollieCheckoutResult.cancelled]).
///
/// Reference: docs/screens/04-payments/02-mollie-checkout.md §Error state
class MollieCheckoutErrorView extends StatelessWidget {
  const MollieCheckoutErrorView({
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'error.payment_failed'.tr(),
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warningCircle(),
              size: 48,
              color: isDark ? DeelmarktColors.darkError : DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'error.payment_failed'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s2),
            Text(
              'error.network'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurfaceSecondary
                        : DeelmarktColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s6),
            DeelButton(
              label: 'action.retry'.tr(),
              leadingIcon: PhosphorIcons.arrowClockwise(),
              variant: DeelButtonVariant.secondary,
              onPressed: onRetry,
            ),
            const SizedBox(height: Spacing.s3),
            DeelButton(
              label: 'action.cancel'.tr(),
              variant: DeelButtonVariant.ghost,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
