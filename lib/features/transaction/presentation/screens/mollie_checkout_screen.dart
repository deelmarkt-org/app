import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/features/transaction/domain/mollie_url_validator.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/mollie_checkout_error_view.dart';
import 'package:deelmarkt/features/transaction/presentation/widgets/mollie_checkout_loading_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    assert(
      MollieUrlValidator.isAllowed(widget.checkoutUrl),
      'Checkout URL must be an HTTPS Mollie URL',
    );
    _controller =
        WebViewController()
          // JavaScript required for Mollie iDEAL bank selection + 3D-Secure.
          // URL is validated against MollieUrlValidator.isAllowed above.
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
                if (request.url.startsWith(widget.redirectUrl)) {
                  if (mounted) context.pop(MollieCheckoutResult.completed);
                  return NavigationDecision.prevent;
                }
                if (MollieUrlValidator.isAllowed(request.url)) {
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
        child:
            _hasError
                ? MollieCheckoutErrorView(
                  onRetry: _retry,
                  onCancel: () => context.pop(MollieCheckoutResult.cancelled),
                )
                : _buildWebView(),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const MollieCheckoutLoadingOverlay(),
      ],
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
