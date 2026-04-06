import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_reason.dart';

/// Expandable reason list for the P-37 scam alert (high-confidence variant).
///
/// Uses [ValueNotifier] + [ValueListenableBuilder] for local expand/collapse
/// state — avoids raw setState while properly disposing the notifier.
///
/// Respects [MediaQuery.disableAnimations] for the expand animation.
///
/// Reference: docs/screens/06-chat/03-scam-alert.md §Expanded variant
class ScamAlertReasons extends StatefulWidget {
  const ScamAlertReasons({
    required this.reasons,
    required this.accentColor,
    super.key,
  });

  final List<ScamReason> reasons;
  final Color accentColor;

  @override
  State<ScamAlertReasons> createState() => _ScamAlertReasonsState();
}

class _ScamAlertReasonsState extends State<ScamAlertReasons> {
  late final ValueNotifier<bool> _expanded;

  static const _minTapTarget = 44.0;

  @override
  void initState() {
    super.initState();
    _expanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, isExpanded, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _minTapTarget,
              width: double.infinity,
              child: Semantics(
                button: true,
                label:
                    isExpanded
                        ? 'scamAlert.collapseAction'.tr()
                        : 'scamAlert.expandAction'.tr(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _expanded.value = !_expanded.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded
                            ? 'scamAlert.collapseAction'.tr()
                            : 'scamAlert.expandAction'.tr(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: Spacing.s1),
                      Icon(
                        isExpanded
                            ? PhosphorIcons.caretUp()
                            : PhosphorIcons.caretDown(),
                        size: 16,
                        color: widget.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration:
                  reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child:
                  isExpanded
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            widget.reasons.map((reason) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.s2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        right: Spacing.s2,
                                      ),
                                      child: Icon(
                                        PhosphorIcons.dotOutline(
                                          PhosphorIconsStyle.fill,
                                        ),
                                        size: 8,
                                        color: widget.accentColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        reason.localizationKey.tr(),
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
