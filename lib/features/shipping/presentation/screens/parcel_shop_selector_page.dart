import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/error_state.dart';

import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

/// Route-facing page for `/shipping/:id/parcel-shops`.
///
/// Fetches the shipping label to determine the postal code,
/// then loads nearby parcel shops and renders [ParcelShopSelectorScreen].
class ParcelShopSelectorPage extends ConsumerWidget {
  const ParcelShopSelectorPage({required this.shippingId, super.key});

  final String shippingId;

  static String get _title => 'shipping.selectParcelShop'.tr();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(shippingDetailProvider(shippingId));

    return labelState.when(
      loading: () => _loadingScaffold(),
      error:
          (_, _) => _errorScaffold(
            () => ref.invalidate(shippingDetailProvider(shippingId)),
          ),
      data: (data) {
        final postalCode = data.label.qrData.split('|').last;
        final shopState = ref.watch(parcelShopsProvider(postalCode));

        return shopState.when(
          loading: () => _loadingScaffold(),
          error:
              (_, _) => _errorScaffold(
                () => ref.invalidate(parcelShopsProvider(postalCode)),
              ),
          data: (shops) => ParcelShopSelectorScreen(shops: shops),
        );
      },
    );
  }

  Widget _loadingScaffold() => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _errorScaffold(VoidCallback onRetry) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: ErrorState(onRetry: onRetry),
  );
}
