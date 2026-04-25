import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

/// WebView screen for completing Mollie payment (iDEAL checkout).
///
/// Note: Uses StatefulWidget + setState for WebView controller lifecycle.
/// This is an accepted deviation from §1.3 (Riverpod) because
/// WebViewController requires initState and the state is purely local UI.
///
/// Reference: docs/epics/E03-payments-escrow.md §WebView integration
class MollieCheckoutScreen extends StatefulWidget {
  const MollieCheckoutScreen({
    required this.checkoutUrl,
    required this.redirectUrl,
    super.key,
  });

  final String checkoutUrl;
  final String redirectUrl;

  @override
  State<MollieCheckoutScreen> createState() => _MollieCheckoutScreenState();
}

class _MollieCheckoutScreenState extends State<MollieCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  /// Allowed URL hosts for the payment WebView.
  /// Mollie + iDEAL bank domains — JavaScript is required
  /// for iDEAL bank selection and 3D-Secure flows.
  static const _trustedHosts = [
    'www.mollie.com',
    'mollie.com',
    // iDEAL bank redirect domains
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

  @override
  void initState() {
    super.initState();
    assert(
      _trustedHosts.any((h) => Uri.parse(widget.checkoutUrl).host.endsWith(h)),
      'Checkout URL must be a Mollie domain',
    );
    _controller =
        WebViewController()
          // JavaScript required for Mollie iDEAL bank selection + 3D-Secure.
          // URL is validated against _trustedHosts above.
          ..setJavaScriptMode(JavaScriptMode.unrestricted) // NOSONAR
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {
                if (mounted) setState(() => _isLoading = true);
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _isLoading = false);
              },
              onWebResourceError: (_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                }
              },
              onNavigationRequest: (request) {
                // Detect redirect back to our app (payment complete)
                if (request.url.startsWith(widget.redirectUrl)) {
                  if (mounted) context.pop(MollieCheckoutResult.completed);
                  return NavigationDecision.prevent;
                }
                // Only allow HTTPS to trusted hosts (Mollie + iDEAL banks).
                final host = Uri.parse(request.url).host;
                final isTrusted = _trustedHosts.any((h) => host.endsWith(h));
                if (request.url.startsWith('https://') && isTrusted) {
                  return NavigationDecision.navigate;
                }
                return NavigationDecision.prevent;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('payment.payWithIdeal'.tr()),
        leading: IconButton(
          icon: Icon(PhosphorIcons.x()),
          onPressed: () => context.pop(MollieCheckoutResult.cancelled),
          tooltip: 'action.cancel'.tr(),
        ),
      ),
      body: MollieCheckoutBodyFrame(
        child: _hasError ? _buildError(context) : _buildWebView(),
      ),
    );
  }

  Widget _buildWebView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Semantics(
            label: 'payment.processing'.tr(),
            liveRegion: true,
            child: Container(
              color:
                  isDark
                      ? DeelmarktColors.darkScaffold.withValues(alpha: 0.8)
                      : DeelmarktColors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: Spacing.s4),
                    Text(
                      'payment.processing'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Outer Center comes from [MollieCheckoutBodyFrame]; this inner Padding
    // sits directly inside the 500px cap, so no second Center is needed.
    return Semantics(
      label: 'error.payment_failed'.tr(),
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warningCircle(),
              size: 48,
              color: isDark ? DeelmarktColors.darkError : DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'error.payment_failed'.tr(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s2),
            Text(
              'error.network'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurfaceSecondary
                        : DeelmarktColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s6),
            DeelButton(
              label: 'action.retry'.tr(),
              leadingIcon: PhosphorIcons.arrowClockwise(),
              variant: DeelButtonVariant.secondary,
              onPressed: _retry,
            ),
            const SizedBox(height: Spacing.s3),
            DeelButton(
              label: 'action.cancel'.tr(),
              variant: DeelButtonVariant.ghost,
              onPressed: () => context.pop(MollieCheckoutResult.cancelled),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of the Mollie checkout WebView.
enum MollieCheckoutResult { completed, cancelled }

/// Layout frame for the Mollie checkout body — centers content and caps
/// its width at [Breakpoints.contentMaxWidth] (500px) so the hosted iframe
/// (~400px Mollie-controlled form) doesn't stretch on desktop. Extracted
/// so the layout cap can be unit-tested without the `WebViewController`
/// platform channel.
///
/// The cap is fixed (not a parameter): Mollie's form width is determined
/// by Mollie, not by our design tokens, so there's no design-system
/// variation to expose.
///
/// Reference: docs/screens/04-payments/02-mollie-checkout.md §Responsive.
class MollieCheckoutBodyFrame extends StatelessWidget {
  const MollieCheckoutBodyFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: Breakpoints.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
