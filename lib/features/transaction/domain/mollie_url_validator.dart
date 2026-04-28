/// URL validation for the Mollie iDEAL checkout WebView.
///
/// Encapsulates the trusted-host allowlist so the same rules can be used
/// by the WebView navigation delegate, the payment listener, and future
/// Apple Pay / Bancontact flows without duplication.
///
/// Reference: docs/epics/E03-payments-escrow.md §WebView integration
class MollieUrlValidator {
  MollieUrlValidator._();

  /// Mollie + iDEAL bank redirect domains permitted inside the checkout WebView.
  static const trustedHosts = [
    'www.mollie.com',
    'mollie.com',
    'ideal.nl',
    'ideal.ing.nl',
    'ideal.rabobank.nl',
    'ideal.abnamro.nl',
    'ideal.triodos.nl',
    'ideal.bunq.com',
    'ideal.knab.nl',
    'ideal.asnbank.nl',
    'ideal.regiobank.nl',
    'ideal.snsbank.nl',
    'ideal.vanlanschot.com',
    'ideal.handelsbanken.nl',
  ];

  /// Returns `true` if the host of [url] is an exact match or a direct
  /// subdomain of a trusted domain.
  ///
  /// Uses `host == h || host.endsWith('.$h')` rather than a bare
  /// `endsWith(h)` to prevent suffix-spoofing attacks where a hostname like
  /// `attacker-mollie.com` would otherwise match the `mollie.com` entry.
  static bool isTrustedHost(String url) {
    final host = Uri.parse(url).host;
    return trustedHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  /// Returns `true` if [url] uses HTTPS **and** resolves to a trusted host.
  ///
  /// Use this in `NavigationDelegate.onNavigationRequest` to decide whether
  /// a navigation should proceed.
  static bool isAllowed(String url) =>
      url.startsWith('https://') && isTrustedHost(url);
}
