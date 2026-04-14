/// CTA row widget for [SuspensionGateScreen].
///
/// Reference: docs/screens/01-auth/06-suspension-gate.md
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

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
