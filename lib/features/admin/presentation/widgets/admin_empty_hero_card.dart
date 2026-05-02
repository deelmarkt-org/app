import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Hero "all clear" card shown inside [AdminEmptyState] when no moderation
/// actions are pending — package icon, headline, subtitle, and the
/// Refresh / View Logs CTAs.
///
/// Extracted from `admin_empty_state.dart` (P-55) — kept feature-local under
/// `admin/presentation/widgets/`.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminEmptyHeroCard extends StatelessWidget {
  const AdminEmptyHeroCard({
    required this.onRefresh,
    required this.onViewLogs,
    super.key,
  });

  final VoidCallback onRefresh;
  final VoidCallback? onViewLogs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: Spacing.s4),
          _buildTitle(context),
          const SizedBox(height: Spacing.s2),
          _buildSubtitle(context),
          const SizedBox(height: Spacing.s6),
          _buildRefreshButton(),
          if (onViewLogs != null) ...[
            const SizedBox(height: Spacing.s3),
            _buildViewLogsLink(),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
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

  Widget _buildTitle(BuildContext context) {
    return Text(
      'admin.empty.title'.tr(),
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: DeelmarktColors.neutral900),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'admin.empty.subtitle'.tr(),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral500),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRefreshButton() {
    return DeelButton(
      label: 'admin.empty.refresh'.tr(),
      onPressed: onRefresh,
      size: DeelButtonSize.medium,
      leadingIcon: PhosphorIconsRegular.arrowClockwise,
    );
  }

  Widget _buildViewLogsLink() {
    return Semantics(
      label: 'admin.empty.view_logs'.tr(),
      button: true,
      child: TextButton(
        onPressed: onViewLogs,
        style: TextButton.styleFrom(
          foregroundColor: DeelmarktColors.neutral500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
          ),
        ),
        child: Text('admin.empty.view_logs'.tr()),
      ),
    );
  }
}
