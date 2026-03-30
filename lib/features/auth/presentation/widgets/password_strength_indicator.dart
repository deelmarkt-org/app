import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/validators.dart';

/// Visual password strength bar — 4 segments with colour and label.
///
/// Uses design tokens exclusively. Respects reduced motion.
/// Announces strength changes to screen readers via [Semantics.liveRegion].
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    required this.strength,
    required this.labels,
    super.key,
  });

  final PasswordStrength strength;

  /// L10n labels indexed by [PasswordStrength] ordinal.
  /// e.g. `['Zwak', 'Redelijk', 'Sterk', 'Zeer sterk']`
  final List<String> labels;

  int get _filledSegments => strength.index + 1;

  Color get _color => switch (strength) {
    PasswordStrength.weak => DeelmarktColors.error,
    PasswordStrength.fair => DeelmarktColors.warning,
    PasswordStrength.strong => DeelmarktColors.success,
    PasswordStrength.veryStrong => DeelmarktColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return Semantics(
      liveRegion: true,
      label: labels[strength.index],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = i < _filledSegments;
              return Expanded(
                child: AnimatedContainer(
                  duration: duration,
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? Spacing.s1 : 0),
                  decoration: BoxDecoration(
                    color: filled ? _color : DeelmarktColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: Spacing.s1),
          Text(
            labels[strength.index],
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
