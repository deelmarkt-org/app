import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Google + Apple social login buttons (stub — P-44).
///
/// Reference: docs/screens/01-auth/03-login.md
class LoginSocialButtons extends StatelessWidget {
  const LoginSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DeelButton(
          label: 'auth.continueWithGoogle'.tr(),
          variant: DeelButtonVariant.outline,
          leadingIcon: PhosphorIconsDuotone.googleLogo,
          onPressed: null, // Stub — P-44 social login
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'auth.continueWithApple'.tr(),
          variant: DeelButtonVariant.outline,
          leadingIcon: PhosphorIconsDuotone.appleLogo,
          onPressed: null, // Stub — P-44 social login
        ),
      ],
    );
  }
}
