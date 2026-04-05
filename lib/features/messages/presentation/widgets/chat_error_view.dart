import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Shared error view for chat screens (P-35, P-36).
class ChatErrorView extends StatelessWidget {
  const ChatErrorView({required this.onRetry, super.key});

  // Raw exception message is intentionally NOT exposed here — renders a
  // localised title only. Future developers: do not add an `err.toString()`
  // text widget in this view; it can leak Supabase table names, RLS policy
  // identifiers, or stack fragments to end users (security finding F-04).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'messages.errorTitle'.tr(),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s4),
            FilledButton(
              onPressed: onRetry,
              child: Text('messages.errorRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
