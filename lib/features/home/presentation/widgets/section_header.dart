import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';

/// Section header with title and optional trailing action link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
                  child: Text(
                    actionLabel!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
