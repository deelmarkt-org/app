import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/async_page.dart';

import 'package:deelmarkt/features/shipping/presentation/screens/parcel_shop_selector_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

/// Route-facing page for `/shipping/:id/parcel-shops`.
///
/// Fetches the shipping label to get the destination postal code,
/// then loads nearby parcel shops and renders [ParcelShopSelectorScreen].
class ParcelShopSelectorPage extends ConsumerWidget {
  const ParcelShopSelectorPage({required this.shippingId, super.key});

  final String shippingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = 'shipping.selectParcelShop'.tr();
    final labelState = ref.watch(shippingDetailProvider(shippingId));

    return labelState.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, _) => AsyncPage<void>(
            title: title,
            state: labelState,
            onRetry: () => ref.invalidate(shippingDetailProvider(shippingId)),
            builder: (_) => const SizedBox.shrink(),
          ),
      data: (data) {
        final postalCode = data.label.destinationPostalCode;
        return AsyncPage(
          title: title,
          state: ref.watch(parcelShopsProvider(postalCode)),
          onRetry: () => ref.invalidate(parcelShopsProvider(postalCode)),
          builder: (shops) => ParcelShopSelectorScreen(shops: shops),
        );
      },
    );
  }
}
