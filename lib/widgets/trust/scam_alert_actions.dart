part of 'scam_alert.dart';

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isHigh,
    required this.onReport,
    required this.onDismiss,
  });
  final bool isHigh;
  final VoidCallback? onReport;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onReport != null)
          Expanded(child: _ReportButton(isHigh: isHigh, onTap: onReport!)),
        if (!isHigh && onReport != null && onDismiss != null)
          const SizedBox(width: Spacing.s2),
        if (!isHigh && onDismiss != null)
          Expanded(child: _InlineDismissButton(onTap: onDismiss!)),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.isHigh, required this.onTap});
  final bool isHigh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color:
            isHigh
                ? DeelmarktColors.trustWarning
                : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          child: Container(
            height: _kMinTapTarget,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s3),
            child: Text(
              'scam_alert.report'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: DeelmarktColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineDismissButton extends StatelessWidget {
  const _InlineDismissButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DeelmarktRadius.md),
          child: Container(
            height: _kMinTapTarget,
            alignment: Alignment.center,
            child: Text(
              'scam_alert.dismiss'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
