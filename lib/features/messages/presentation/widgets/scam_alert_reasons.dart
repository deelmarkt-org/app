import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_reason.dart';

/// Expandable reason list for the P-37 scam alert (high-confidence variant).
///
/// Uses [ValueNotifier] + [ValueListenableBuilder] for local expand/collapse
/// state (no setState per CLAUDE.md §1.3).
///
/// Respects [MediaQuery.disableAnimations] for the expand animation.
///
/// Reference: docs/screens/06-chat/03-scam-alert.md §Expanded variant
class ScamAlertReasons extends StatelessWidget {
  ScamAlertReasons({
    required this.reasons,
    required this.accentColor,
    super.key,
  });

  final List<ScamReason> reasons;
  final Color accentColor;

  final ValueNotifier<bool> _expanded = ValueNotifier<bool>(false);

  static const _minTapTarget = 44.0;

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
              child: Semantics(
                button: true,
                label:
                    isExpanded
                        ? 'scamAlert.collapseAction'.tr()
                        : 'scamAlert.expandAction'.tr(),
                child: GestureDetector(
                  onTap: () => _expanded.value = !_expanded.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'scamAlert.whyTitle'.tr(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: Spacing.s1),
                      Icon(
                        isExpanded
                            ? PhosphorIcons.caretUp()
                            : PhosphorIcons.caretDown(),
                        size: 16,
                        color: accentColor,
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
                            reasons.map((reason) {
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
                                        color: accentColor,
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
