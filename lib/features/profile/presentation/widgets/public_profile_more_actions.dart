import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/report_reason_sheet.dart';

/// AppBar overflow-menu actions for [PublicProfileScreen] — share + report.
///
/// Extracted from public_profile_screen.dart to keep the screen under the
/// §2.1 200-line cap (PR #269 review).
class PublicProfileMoreButton extends ConsumerWidget {
  const PublicProfileMoreButton({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(publicProfileNotifierProvider(userId).notifier);
    return PopupMenuButton<_MenuAction>(
      icon: Icon(PhosphorIcons.dotsThreeVertical()),
      tooltip: 'seller_profile.more_actions'.tr(),
      onSelected: (action) => _handle(context, notifier, action),
      itemBuilder:
          (_) => [
            PopupMenuItem(
              value: _MenuAction.share,
              child: Text('seller_profile.share_action'.tr()),
            ),
            PopupMenuItem(
              value: _MenuAction.report,
              child: Text('seller_profile.report_action'.tr()),
            ),
          ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    PublicProfileNotifier notifier,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.share:
        await notifier.shareProfile();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('seller_profile.share_copied'.tr())),
        );
      case _MenuAction.report:
        await showReportReasonSheet(
          context,
          (reason) => notifier.reportUser(reason),
        );
    }
  }
}

/// Opens the report-reason bottom sheet. Public so the reviews tab can
/// re-use it for per-review reports without duplicating the showModalBottomSheet
/// plumbing.
Future<void> showReportReasonSheet(
  BuildContext context,
  Future<void> Function(ReportReason) onSubmit,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => ReportReasonSheet(onSubmit: onSubmit),
  );
}

enum _MenuAction { share, report }
