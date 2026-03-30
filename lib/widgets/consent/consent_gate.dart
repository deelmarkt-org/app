import 'package:flutter/material.dart';

import 'package:deelmarkt/core/services/consent/consent_record.dart';

import 'package:deelmarkt/widgets/consent/gdpr_consent_banner.dart';

/// Wraps app content and shows consent banner when:
/// - No consent recorded ([consentRecord] is null), or
/// - Consent version is outdated (privacy policy updated).
///
/// Place at the top of the widget tree, above navigation. The banner
/// blocks interaction via [ModalBarrier] until consent is given.
///
/// ```dart
/// ConsentGate(
///   consentRecord: consentState,
///   onAcceptAll: () => notifier.grant(ConsentLevel.allCookies, ...),
///   onNecessaryOnly: () => notifier.grant(ConsentLevel.necessaryOnly, ...),
///   child: MaterialApp(...),
/// )
/// ```
class ConsentGate extends StatelessWidget {
  const ConsentGate({
    required this.consentRecord,
    required this.onAcceptAll,
    required this.onNecessaryOnly,
    required this.child,
    super.key,
  });

  final ConsentRecord? consentRecord;
  final VoidCallback onAcceptAll;
  final VoidCallback onNecessaryOnly;
  final Widget child;

  bool get _needsConsent =>
      consentRecord == null || consentRecord!.isOutdated(kPrivacyPolicyVersion);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (_needsConsent)
          GdprConsentBanner(
            onAcceptAll: onAcceptAll,
            onNecessaryOnly: onNecessaryOnly,
          ),
      ],
    );
  }
}
