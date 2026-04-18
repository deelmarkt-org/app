/// Status chips, receipt banner, and upheld body for [SuspensionGateScreen].
///
/// Reference: docs/screens/01-auth/06-suspension-gate.md
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

class SuspensionGateCountdownChip extends StatelessWidget {
  const SuspensionGateCountdownChip({required this.expiresAt, super.key});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ceiling via inSeconds so even <1 h remaining shows "1 day left" not "0".
    final daysLeft = (expiresAt.difference(DateTime.now()).inSeconds / 86400)
        .ceil()
        .clamp(0, 9999);
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
              size: DeelmarktIconSize.xs,
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
              size: DeelmarktIconSize.xs,
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
