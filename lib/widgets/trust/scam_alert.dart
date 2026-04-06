import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/trust/scam_alert_reason.dart';

part 'scam_alert_header.dart';
part 'scam_alert_actions.dart';

/// Left-border accent width for the alert card.
const double _kAlertBorderWidth = 4;

/// Minimum tappable area — WCAG 2.2 AA (44×44 px).
const double _kMinTapTarget = 44;

/// Bullet dot icon size in the reason list.
const double _kBulletIconSize = 14;

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
         confidence == ScamAlertConfidence.low || onReport != null,
         'Pass a non-null `onReport` callback for high-confidence '
         'alerts — the Report action is the only user-facing '
         'recovery path (non-dismissible banners with no action '
         'become dead UI).',
       ),
       assert(
         // ignore: prefer_is_empty
         reasons.length > 0,
         'ScamAlert requires at least one reason — use '
         'ScamAlertReason.other if the backend flag is opaque.',
       );

  final ScamAlertConfidence confidence;
  final List<ScamAlertReason> reasons;

  /// Fires when the user taps the Report action. **Required** for
  /// high confidence (asserted at construction), optional for low.
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
          border: Border(
            left: BorderSide(color: palette.accent, width: _kAlertBorderWidth),
          ),
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
                  // _Actions is only rendered when at least one button
                  // would be visible: high-confidence always shows Report,
                  // low-confidence only when onReport is non-null. When
                  // isHigh=false AND onReport=null the guard skips _Actions
                  // entirely — the Row would otherwise render empty.
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
