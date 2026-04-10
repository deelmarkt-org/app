import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Admin-specific empty state shown when no moderation actions are pending.
///
/// Displays a centred illustration, reassuring title/subtitle, and
/// refresh / view-logs actions.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({required this.onRefresh, this.onViewLogs, super.key});

  /// Called when the user taps the primary refresh button.
  final VoidCallback onRefresh;

  /// Called when the user taps the secondary "View Logs" link.
  final VoidCallback? onViewLogs;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'admin.empty.a11y'.tr(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIllustration(),
              const SizedBox(height: Spacing.s6),
              _buildTitle(),
              const SizedBox(height: Spacing.s2),
              _buildSubtitle(),
              const SizedBox(height: Spacing.s8),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: DeelmarktColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        PhosphorIconsRegular.package,
        size: 36,
        color: DeelmarktColors.primary,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'admin.empty.title'.tr(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DeelmarktColors.neutral900,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'admin.empty.subtitle'.tr(),
      style: const TextStyle(fontSize: 14, color: DeelmarktColors.neutral500),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        DeelButton(
          label: 'admin.empty.refresh'.tr(),
          onPressed: onRefresh,
          size: DeelButtonSize.medium,
          leadingIcon: PhosphorIconsRegular.arrowClockwise,
        ),
        if (onViewLogs != null) ...[
          const SizedBox(height: Spacing.s3),
          Semantics(
            label: 'admin.empty.view_logs'.tr(),
            button: true,
            child: TextButton(
              onPressed: onViewLogs,
              style: TextButton.styleFrom(
                foregroundColor: DeelmarktColors.neutral500,
                textStyle: const TextStyle(fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
                ),
              ),
              child: Text('admin.empty.view_logs'.tr()),
            ),
          ),
        ],
      ],
    );
  }
}
