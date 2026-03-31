import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/colors.dart';

/// GDPR Art. 7 compliant consent checkboxes for Terms and Privacy.
///
/// Extracted from RegistrationForm to keep file under 200 lines.
class ConsentCheckboxes extends StatefulWidget {
  const ConsentCheckboxes({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    this.enabled = true,
    super.key,
  });

  final bool termsAccepted;
  final bool privacyAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final bool enabled;

  @override
  State<ConsentCheckboxes> createState() => _ConsentCheckboxesState();
}

class _ConsentCheckboxesState extends State<ConsentCheckboxes> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer =
        TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(AppConstants.termsUrl));
    _privacyRecognizer =
        TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(AppConstants.privacyUrl));
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: DeelmarktColors.secondary,
      decoration: TextDecoration.underline,
    );

    return Column(
      children: [
        CheckboxListTile(
          value: widget.termsAccepted,
          onChanged:
              widget.enabled ? (v) => widget.onTermsChanged(v ?? false) : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text.rich(
            TextSpan(
              text: 'auth.terms_agree_prefix'.tr(),
              children: [
                TextSpan(
                  text: 'auth.terms_link'.tr(),
                  style: linkStyle,
                  recognizer: _termsRecognizer,
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        CheckboxListTile(
          value: widget.privacyAccepted,
          onChanged:
              widget.enabled
                  ? (v) => widget.onPrivacyChanged(v ?? false)
                  : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text.rich(
            TextSpan(
              text: 'auth.privacy_agree_prefix'.tr(),
              children: [
                TextSpan(
                  text: 'auth.privacy_link'.tr(),
                  style: linkStyle,
                  recognizer: _privacyRecognizer,
                ),
              ],
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
