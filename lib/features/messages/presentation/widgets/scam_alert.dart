import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/scam_alert_reasons.dart';

/// Inline scam alert banner shown at the top of a chat thread when the E06
/// scam detector flags a message.
///
/// Two severity variants:
/// - [ScamAlert.highConfidence] — red surface, non-dismissible
/// - [ScamAlert.lowConfidence] — amber surface, dismissible via `X` button
///
/// Uses [DeelmarktTrustTheme] for dark-mode-aware colours (ADR-SCAM-ALERT-THEME).
///
/// Reference: docs/screens/06-chat/03-scam-alert.md
class ScamAlert extends StatelessWidget {
  /// High-confidence scam alert — non-dismissible red banner.
  const ScamAlert.highConfidence({
    required this.allReasons,
    required this.onReport,
    super.key,
  }) : _isHighConfidence = true,
       onDismiss = null;

  /// Low-confidence scam alert — dismissible amber banner.
  const ScamAlert.lowConfidence({
    required this.onReport,
    required VoidCallback this.onDismiss,
    super.key,
  }) : _isHighConfidence = false,
       allReasons = const [];

  final List<ScamReason> allReasons;
  final VoidCallback onReport;
  final VoidCallback? onDismiss;
  final bool _isHighConfidence;

  static const _borderWidth = 4.0;
  static const _iconSize = 24.0;
  static const _minTapTarget = 44.0;

  @override
  Widget build(BuildContext context) {
    final trustTheme =
        Theme.of(context).extension<DeelmarktTrustTheme>() ??
        DeelmarktTrustTheme.light();

    final surface =
        _isHighConfidence
            ? trustTheme.scamHighSurface
            : trustTheme.scamLowSurface;
    final accent =
        _isHighConfidence
            ? trustTheme.scamHighAccent
            : trustTheme.scamLowAccent;

    return RepaintBoundary(
      child: Semantics(
        container: true,
        liveRegion: true,
        label:
            _isHighConfidence
                ? 'scamAlert.a11y.highSeverity'.tr()
                : 'scamAlert.a11y.lowSeverity'.tr(),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            Spacing.s4,
            Spacing.s4,
            Spacing.s4,
            Spacing.s6,
          ),
          padding: const EdgeInsets.all(Spacing.s4),
          decoration: BoxDecoration(
            color: surface,
            border: Border(
              left: BorderSide(color: accent, width: _borderWidth),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(DeelmarktRadius.lg),
              bottomRight: Radius.circular(DeelmarktRadius.lg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, accent),
              if (_isHighConfidence && allReasons.isNotEmpty)
                ScamAlertReasons(reasons: allReasons, accentColor: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            color: accent,
            size: _iconSize,
          ),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isHighConfidence
                    ? 'scamAlert.highTitle'.tr()
                    : 'scamAlert.lowTitle'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.s1),
              SizedBox(
                height: _minTapTarget,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    button: true,
                    hint: 'scamAlert.a11y.reportHint'.tr(),
                    child: InkWell(
                      onTap: onReport,
                      child: Text(
                        'scamAlert.reportAction'.tr(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_isHighConfidence && onDismiss != null)
          SizedBox(
            width: _minTapTarget,
            height: _minTapTarget,
            child: Semantics(
              button: true,
              label: 'scamAlert.dismissAction'.tr(),
              child: IconButton(
                onPressed: onDismiss,
                icon: Icon(PhosphorIcons.x(), size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }
}
