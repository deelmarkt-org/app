import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/kyc_prompt_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_faq_expandable.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_progress_bar.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/kyc_trust_footer.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Modal bottom sheet for Level 1 → Level 2 iDIN verification.
///
/// Shown when a user attempts a transaction >= €500 with KycLevel.level1.
/// State survives rotation via Riverpod (not local StatefulWidget state).
class KycBottomSheet extends ConsumerWidget {
  const KycBottomSheet({super.key});

  /// Show this sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const KycBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycPromptNotifierProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.s4,
        right: Spacing.s4,
        top: Spacing.s6,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: DeelmarktColors.neutral300,
                borderRadius: BorderRadius.circular(DeelmarktRadius.xxs),
              ),
            ),
          ),
          const SizedBox(height: Spacing.s6),

          if (state.isSuccess) ...[
            _buildSuccess(context, reduceMotion),
          ] else ...[
            _buildContent(context, ref, state),
          ],

          const SizedBox(height: Spacing.s4),
          const KycTrustFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    KycPromptState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'kyc.sheetTitle'.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.s2),
        Text(
          'kyc.sheetSubtitle'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.s6),

        const KycProgressBar(progress: 0.5),
        const SizedBox(height: Spacing.s6),

        const KycFaqExpandable(),
        const SizedBox(height: Spacing.s4),

        if (state.error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              'kyc.error'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.s3),
        ],

        DeelButton(
          label: 'kyc.verifyWithIdin'.tr(),
          onPressed:
              state.isLoading
                  ? null
                  : () =>
                      ref
                          .read(kycPromptNotifierProvider.notifier)
                          .initiateIdin(),
          isLoading: state.isLoading,
          variant: DeelButtonVariant.secondary,
        ),
        const SizedBox(height: Spacing.s2),
        DeelButton(
          label: 'kyc.later'.tr(),
          variant: DeelButtonVariant.ghost,
          onPressed: () {
            ref.read(kycPromptNotifierProvider.notifier).dismiss();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, bool reduceMotion) {
    final duration = DeelmarktAnimation.resolve(
      DeelmarktAnimation.emphasis,
      reduceMotion: reduceMotion,
    );

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            curve: DeelmarktAnimation.curveStandard,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Icon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: DeelmarktColors.trustVerified,
              size: DeelmarktIconSize.hero,
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            'kyc.success'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
