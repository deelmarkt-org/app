import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/trust/scam_alert_reason.dart';

/// Inline chat banner surfaced above a suspicious message.
///
/// Two confidence tiers:
/// - [ScamAlertConfidence.high]: red `errorSurface` background, non-
///   dismissible, Report button required.
/// - [ScamAlertConfidence.low]: amber `warningSurface` background,
///   dismissible, no Report button required.
///
/// The widget NEVER renders raw message content — only a localised
/// reason string from the closed [ScamAlertReason] enum and the
/// classifier confidence tier. Raw user input is a rendering /
/// injection risk and belongs in the message bubble, not here.
///
/// Reference:
/// - `docs/design-system/patterns.md` §Scam Alert (Inline)
/// - `docs/screens/06-chat/03-scam-alert.md`
/// - `docs/screens/06-chat/designs/scam_alert_*`
class ScamAlert extends StatefulWidget {
  // Non-const: the `reasons` list length can only be validated at runtime,
  // so the runtime assertion disqualifies a const constructor. Call sites
  // pass a fresh List literal anyway — no const-canonicalisation benefit
  // is lost.
  // ignore: prefer_const_constructors_in_immutables
  ScamAlert({
    required this.confidence,
    required this.reasons,
    this.onReport,
    this.onDismiss,
    this.initiallyExpanded = false,
    super.key,
  }) : assert(
         confidence == ScamAlertConfidence.low || onDismiss == null,
         'High-confidence scam alerts must NOT be dismissible '
         '(onDismiss must be null).',
       ),
       assert(
         // ignore: prefer_is_empty
         reasons.length > 0,
         'ScamAlert requires at least one reason — use '
         'ScamAlertReason.other if the backend flag is opaque.',
       );

  final ScamAlertConfidence confidence;
  final List<ScamAlertReason> reasons;

  /// Fires when the user taps the Report action. Required for high
  /// confidence, optional for low.
  final VoidCallback? onReport;

  /// Only honoured for [ScamAlertConfidence.low]. Asserted at
  /// construction time so a high-confidence alert cannot accept a
  /// dismiss handler.
  final VoidCallback? onDismiss;

  final bool initiallyExpanded;

  @override
  State<ScamAlert> createState() => _ScamAlertState();
}

class _ScamAlertState extends State<ScamAlert> {
  // ValueNotifier keeps the expand/collapse toggle local without
  // violating CLAUDE.md §1.3 (no imperative state rebuilds in the
  // presentation layer) — no Riverpod provider overhead for a purely
  // visual UI state.
  late final ValueNotifier<bool> _expanded = ValueNotifier<bool>(
    widget.initiallyExpanded,
  );

  bool get _isHigh => widget.confidence == ScamAlertConfidence.high;

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);
    return Semantics(
      label: (_isHigh ? 'scam_alert.a11yHigh' : 'scam_alert.a11yLow').tr(),
      liveRegion: true,
      container: true,
      explicitChildNodes: true,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.s4,
          vertical: Spacing.s2,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          border: Border(left: BorderSide(color: palette.accent, width: 4)),
        ),
        padding: const EdgeInsets.all(Spacing.s3),
        child: ValueListenableBuilder<bool>(
          valueListenable: _expanded,
          builder:
              (context, expanded, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    isHigh: _isHigh,
                    accent: palette.accent,
                    expanded: expanded,
                    onToggleExpanded: () => _expanded.value = !expanded,
                    onDismiss: _isHigh ? null : widget.onDismiss,
                  ),
                  if (expanded) ...[
                    const SizedBox(height: Spacing.s3),
                    _ReasonList(reasons: widget.reasons),
                  ],
                  if (_isHigh || widget.onReport != null) ...[
                    const SizedBox(height: Spacing.s3),
                    _Actions(
                      isHigh: _isHigh,
                      onReport: widget.onReport,
                      onDismiss: _isHigh ? null : widget.onDismiss,
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }

  _Palette _palette(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isHigh) {
      return _Palette(
        surface:
            isDark
                ? DeelmarktColors.darkErrorSurface
                : DeelmarktColors.errorSurface,
        accent:
            isDark
                ? DeelmarktColors.darkTrustWarning
                : DeelmarktColors.trustWarning,
      );
    }
    return _Palette(
      surface:
          isDark
              ? DeelmarktColors.darkWarningSurface
              : DeelmarktColors.warningSurface,
      accent:
          isDark
              ? DeelmarktColors.darkTrustPending
              : DeelmarktColors.trustPending,
    );
  }
}

class _Palette {
  const _Palette({required this.surface, required this.accent});
  final Color surface;
  final Color accent;
}

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
            height: 44,
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
            height: 44,
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
