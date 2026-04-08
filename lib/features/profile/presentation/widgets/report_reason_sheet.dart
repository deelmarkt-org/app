import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';

/// Maps a camelCase enum name to its snake_case l10n key under
/// `review.report_reason.*`.
String _reasonL10nKey(ReportReason reason) {
  // Convert camelCase → snake_case (e.g. hateSpeech → hate_speech).
  final snake = reason.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );
  return 'review.report_reason.$snake';
}

/// Bottom sheet for selecting a report reason (DSA Art. 16).
///
/// Used by review cards and profile overflow menus.
class ReportReasonSheet extends StatelessWidget {
  const ReportReasonSheet({required this.onSubmit, super.key});

  final Future<void> Function(ReportReason reason) onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.s4),
            child: Semantics(
              header: true,
              child: Text(
                'report.title'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ...ReportReason.values.map(
            (reason) => Semantics(
              button: true,
              label: _reasonL10nKey(reason).tr(),
              child: ListTile(
                title: Text(_reasonL10nKey(reason).tr()),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await onSubmit(reason);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('report.submitted'.tr())),
                      );
                    }
                  } on Exception {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('error.generic'.tr())),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: Spacing.s2),
        ],
      ),
    );
  }
}
