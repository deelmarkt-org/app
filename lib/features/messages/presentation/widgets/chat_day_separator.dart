import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/chat_date_formatter.dart';

/// P-36 — Centred day separator between message groups in the thread.
///
/// Reference: `docs/screens/06-chat/02-chat-thread.md` §Message thread.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({required this.moment, required this.now, super.key});

  final DateTime moment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s3),
      child: Center(
        child: Text(
          ChatDateFormatter.daySeparator(moment, now: now),
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
