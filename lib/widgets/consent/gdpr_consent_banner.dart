import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

/// GDPR consent banner — shown on first launch or when privacy policy
/// version changes. Non-dismissible overlay that blocks interaction
/// until the user makes a choice.
///
/// Uses [ModalBarrier] + [PopScope] to prevent bypass via back gesture
/// or tap-outside. GDPR Article 7: consent must be unambiguous.
///
/// Reference: docs/epics/E07-infrastructure.md §Consent & Accessibility
class GdprConsentBanner extends StatelessWidget {
  const GdprConsentBanner({
    required this.onAcceptAll,
    required this.onNecessaryOnly,
    super.key,
  });

  /// Called when user taps "Accept all".
  final VoidCallback onAcceptAll;

  /// Called when user taps "Necessary only".
  final VoidCallback onNecessaryOnly;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Semantics(
        label: 'a11y.consent_banner'.tr(),
        liveRegion: true,
        child: Stack(
          children: [
            ModalBarrier(
              dismissible: false,
              color: DeelmarktColors.neutral900.withValues(alpha: 0.54),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: isDark ? DeelmarktColors.darkSurface : DeelmarktColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DeelmarktRadius.xl),
            topRight: Radius.circular(DeelmarktRadius.xl),
          ),
          boxShadow: [
            BoxShadow(
              color: DeelmarktColors.neutral900.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: Spacing.s2),
            _buildBody(context),
            const SizedBox(height: Spacing.s1),
            _buildPrivacyLink(context),
            const SizedBox(height: Spacing.s4),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          size: 24,
          color: isDark ? DeelmarktColors.darkSuccess : DeelmarktColors.success,
        ),
        const SizedBox(width: Spacing.s2),
        Expanded(
          child: Text(
            'consent.title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'consent.body'.tr(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color:
            isDark
                ? DeelmarktColors.darkOnSurfaceSecondary
                : DeelmarktColors.neutral700,
      ),
    );
  }

  Widget _buildPrivacyLink(BuildContext context) {
    return Semantics(
      button: true,
      label: 'consent.privacy_policy'.tr(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: TextButton(
          onPressed: () {
            // Phase 2: open privacy policy in-app or external URL.
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'consent.privacy_policy'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DeelmarktColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: DeelmarktColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: DeelButton(
            label: 'consent.accept_all'.tr(),
            size: DeelButtonSize.medium,
            onPressed: onAcceptAll,
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: DeelButton(
            label: 'consent.necessary_only'.tr(),
            variant: DeelButtonVariant.outline,
            size: DeelButtonSize.medium,
            onPressed: onNecessaryOnly,
          ),
        ),
      ],
    );
  }
}
