/// Extracted sub-widgets for [SuspensionGateScreen].
///
/// Reference: docs/screens/01-auth/06-suspension-gate.md
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

class SuspensionGateSanctionBody extends StatelessWidget {
  const SuspensionGateSanctionBody({
    required this.sanction,
    required this.onContactSupport,
    super.key,
  });

  final SanctionEntity sanction;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.s5),
        SuspensionGateHeader(sanction: sanction),
        const SizedBox(height: Spacing.s4),
        SuspensionGateReasonCard(reason: sanction.reason),
        const SizedBox(height: Spacing.s4),
        if (sanction.expiresAt != null)
          SuspensionGateCountdownChip(expiresAt: sanction.expiresAt!)
        else
          const SuspensionGatePermanentChip(),
        const SizedBox(height: Spacing.s4),
        if (sanction.isAppealPending)
          SuspensionGateReceiptBanner(sanction: sanction),
        if (sanction.appealDecision == AppealDecision.upheld)
          const SuspensionGateUpheldBody(),
        const SizedBox(height: Spacing.s4),
        SuspensionGateCtaRow(
          sanction: sanction,
          onContactSupport: onContactSupport,
        ),
        const SizedBox(height: Spacing.s8),
      ],
    );
  }
}

class SuspensionGateHeader extends StatelessWidget {
  const SuspensionGateHeader({required this.sanction, super.key});

  final SanctionEntity sanction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? DeelmarktColors.darkError : DeelmarktColors.error;
    final infoColor = isDark ? DeelmarktColors.darkInfo : DeelmarktColors.info;

    final IconData icon;
    final Color color;
    final String title;

    if (sanction.isAppealPending) {
      icon = PhosphorIcons.clock();
      color = infoColor;
      title = 'sanction.screen.appeal_pending_title'.tr();
    } else if (sanction.appealDecision == AppealDecision.upheld) {
      icon = PhosphorIcons.prohibit();
      color = iconColor;
      title = 'sanction.screen.appeal_upheld_title'.tr();
    } else {
      icon = PhosphorIcons.prohibit();
      color = iconColor;
      title = 'sanction.screen.title'.tr();
    }

    return Column(
      children: [
        Semantics(
          label: 'sanction.a11y.sanction_icon'.tr(),
          excludeSemantics: true,
          child: Icon(icon, size: 64, color: color),
        ),
        const SizedBox(height: Spacing.s3),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s3,
            vertical: Spacing.s1,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          ),
          child: Text(
            'sanction.type.${sanction.type.name}'.tr(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
        const SizedBox(height: Spacing.s3),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class SuspensionGateReasonCard extends StatelessWidget {
  const SuspensionGateReasonCard({required this.reason, super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Spacing.s3),
      decoration: BoxDecoration(
        color:
            isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral100,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'sanction.screen.reason_label'.tr(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
            ),
          ),
          const SizedBox(height: Spacing.s2),
          Text(reason, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class SuspensionGateCountdownChip extends StatelessWidget {
  const SuspensionGateCountdownChip({required this.expiresAt, super.key});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysLeft = expiresAt.difference(DateTime.now()).inDays.clamp(0, 9999);
    final label = 'sanction.screen.countdown_days'.tr(
      namedArgs: {'count': daysLeft.toString()},
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s3,
          vertical: Spacing.s2,
        ),
        decoration: BoxDecoration(
          color:
              isDark
                  ? DeelmarktColors.darkSurfaceElevated
                  : DeelmarktColors.warningSurface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.timer(),
              size: 16,
              color:
                  isDark
                      ? DeelmarktColors.darkWarning
                      : DeelmarktColors.warning,
            ),
            const SizedBox(width: Spacing.s1),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkWarning
                        : DeelmarktColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuspensionGatePermanentChip extends StatelessWidget {
  const SuspensionGatePermanentChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = 'sanction.screen.permanent'.tr();

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s3,
          vertical: Spacing.s2,
        ),
        decoration: BoxDecoration(
          color:
              isDark
                  ? DeelmarktColors.darkErrorSurface
                  : DeelmarktColors.errorSurface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.prohibit(),
              size: 16,
              color: isDark ? DeelmarktColors.darkError : DeelmarktColors.error,
            ),
            const SizedBox(width: Spacing.s1),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isDark ? DeelmarktColors.darkError : DeelmarktColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuspensionGateReceiptBanner extends StatelessWidget {
  const SuspensionGateReceiptBanner({required this.sanction, super.key});

  final SanctionEntity sanction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat.yMd().add_Hm().format(sanction.appealedAt!);

    return Container(
      padding: const EdgeInsets.all(Spacing.s3),
      decoration: BoxDecoration(
        color:
            isDark
                ? DeelmarktColors.darkInfoSurface
                : DeelmarktColors.infoSurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        border: Border.all(
          color: isDark ? DeelmarktColors.darkInfo : DeelmarktColors.info,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'sanction.screen.receipt'.tr(
              namedArgs: {'time': time, 'id': sanction.id},
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.s2),
          Text(
            'sanction.screen.sla_72h'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

class SuspensionGateUpheldBody extends StatelessWidget {
  const SuspensionGateUpheldBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Text(
        'sanction.screen.appeal_upheld_body'.tr(),
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SuspensionGateCtaRow extends ConsumerWidget {
  const SuspensionGateCtaRow({
    required this.sanction,
    required this.onContactSupport,
    super.key,
  });

  final SanctionEntity sanction;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAppealCta =
        sanction.canAppeal &&
        !sanction.isAppealPending &&
        sanction.appealDecision == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAppealCta) ...[
          DeelButton(
            label: 'sanction.screen.appeal_title'.tr(),
            onPressed:
                () => context.push(AppRoutes.suspendedAppeal, extra: sanction),
          ),
          const SizedBox(height: Spacing.s3),
        ],
        DeelButton(
          label: 'sanction.screen.contact_support'.tr(),
          onPressed: onContactSupport,
          variant: DeelButtonVariant.ghost,
        ),
      ],
    );
  }
}
