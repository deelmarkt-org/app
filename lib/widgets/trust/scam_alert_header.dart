part of 'scam_alert.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.isHigh,
    required this.accent,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onDismiss,
  });

  final bool isHigh;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          PhosphorIcons.warning(PhosphorIconsStyle.fill),
          color: accent,
          size: 24,
        ),
        const SizedBox(width: Spacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (isHigh ? 'scam_alert.titleHigh' : 'scam_alert.titleLow').tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (!isHigh) ...[
                const SizedBox(height: 2),
                Text(
                  'scam_alert.subtitleLow'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: Spacing.s2),
        _ExpandToggle(expanded: expanded, onTap: onToggleExpanded),
        if (onDismiss != null) ...[
          const SizedBox(width: Spacing.s1),
          _DismissButton(onTap: onDismiss!),
        ],
      ],
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          (expanded ? 'scam_alert.whyWarningHide' : 'scam_alert.whyWarning')
              .tr(),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              expanded ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'scam_alert.dismiss'.tr(),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              PhosphorIcons.x(),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonList extends StatelessWidget {
  const _ReasonList({required this.reasons});
  final List<ScamAlertReason> reasons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'scam_alert.whyWarning'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Spacing.s1),
        for (final reason in reasons) _ReasonRow(reason: reason),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.reason});
  final ScamAlertReason reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              PhosphorIcons.dotOutline(PhosphorIconsStyle.bold),
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacing.s1),
          Expanded(
            child: Text(
              '${'scam_alert.aiDetectedPrefix'.tr()} ${reason.l10nKey.tr()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
