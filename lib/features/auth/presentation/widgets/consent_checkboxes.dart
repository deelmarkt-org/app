import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/colors.dart';

/// GDPR Art. 7 compliant consent checkboxes for Terms and Privacy.
///
/// Extracted from RegistrationForm to keep file under 200 lines.
class ConsentCheckboxes extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConsentRow(
          value: termsAccepted,
          onChanged: enabled ? (v) => onTermsChanged(v ?? false) : null,
          prefixKey: 'auth.terms_agree_prefix',
          linkKey: 'auth.terms_link',
          linkUrl: AppConstants.termsUrl,
        ),
        _ConsentRow(
          value: privacyAccepted,
          onChanged: enabled ? (v) => onPrivacyChanged(v ?? false) : null,
          prefixKey: 'auth.privacy_agree_prefix',
          linkKey: 'auth.privacy_link',
          linkUrl: AppConstants.privacyUrl,
        ),
      ],
    );
  }
}

/// Single consent checkbox row with an accessible link in the title.
///
/// Uses [Semantics(link: true)] around the tappable URL text instead of
/// [TapGestureRecognizer] inside a [TextSpan] — the recogniser approach
/// does not expose the [link] semantic flag to TalkBack/VoiceOver, causing
/// screen readers to announce it as plain text rather than a navigable link
/// (WCAG 2.4.4 Link Purpose, Level AA).
///
/// The link [InkWell] uses [LaunchMode.externalApplication] to open the URL
/// in the device browser rather than an in-app WebView, preventing phishing
/// via a spoofed WebView (OWASP M1 — Improper Platform Usage).
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.prefixKey,
    required this.linkKey,
    required this.linkUrl,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String prefixKey;
  final String linkKey;
  final String linkUrl;

  Future<void> _openUrl(BuildContext context) async {
    final launched = await launchUrl(
      Uri.parse(linkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('error.url_open_failed'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: DeelmarktColors.secondary,
      decoration: TextDecoration.underline,
    );

    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Wrap(
        children: [
          Text(prefixKey.tr(), style: theme.textTheme.bodyMedium),
          Semantics(
            link: true,
            child: InkWell(
              onTap: () => _openUrl(context),
              // Vertical padding ensures the tap target meets the 44 dp minimum
              // required by WCAG 2.5.8 (Target Size, Level AA) and the EAA.
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(linkKey.tr(), style: linkStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
