import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// DeelMarkt logo with brand name — centered at top of login screen.
///
/// Uses theme-aware colors for dark mode support.
/// Reference: docs/screens/01-auth/03-login.md
class LoginLogoSection extends StatelessWidget {
  const LoginLogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Semantics(
          image: true,
          label: 'DeelMarkt logo',
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
            ),
            child: Icon(
              PhosphorIconsFill.handshake,
              color: colorScheme.onPrimary,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: Spacing.s4),
        Text(
          'DeelMarkt',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
