import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';

/// Subtle biometric icon + label — matches design mockup (not a full button).
///
/// Only rendered when biometric hardware is available AND a stored session
/// exists. Tapping triggers the OS biometric prompt.
///
/// Uses [DeelmarktColors.neutral700] in light mode for WCAG 2.2 AA
/// contrast compliance at [labelSmall] (11px) size.
/// Reference: docs/screens/01-auth/03-login.md
class BiometricSection extends ConsumerWidget {
  const BiometricSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    if (!state.biometricAvailable) return const SizedBox.shrink();

    final isFace = state.biometricMethod == BiometricMethod.face;
    final biometricLabel =
        isFace ? 'auth.useFaceId'.tr() : 'auth.useFingerprint'.tr();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: biometricLabel,
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              isFace
                  ? PhosphorIconsDuotone.scan
                  : PhosphorIconsDuotone.fingerprint,
              size: DeelmarktIconSize.lg,
              color: secondaryColor,
            ),
            onPressed:
                state.isLoading
                    ? null
                    : () => ref
                        .read(loginViewModelProvider.notifier)
                        .loginWithBiometric(
                          localizedReason: 'auth.biometricReason'.tr(),
                        ),
            tooltip: biometricLabel,
          ),
        ),
        Text(
          biometricLabel,
          style: theme.textTheme.labelSmall?.copyWith(color: secondaryColor),
        ),
      ],
    );
  }
}
