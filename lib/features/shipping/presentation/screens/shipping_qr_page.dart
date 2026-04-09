import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/error_state.dart';

import 'package:deelmarkt/features/shipping/presentation/screens/shipping_qr_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

/// Route-facing page for `/shipping/:id/qr`.
///
/// Fetches the shipping label by ID and renders [ShippingQrScreen].
class ShippingQrPage extends ConsumerWidget {
  const ShippingQrPage({required this.shippingId, super.key});

  final String shippingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shippingDetailProvider(shippingId));

    return state.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: Text('shipping.sendPackage'.tr())),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, _) => Scaffold(
            appBar: AppBar(title: Text('shipping.sendPackage'.tr())),
            body: ErrorState(
              onRetry: () => ref.invalidate(shippingDetailProvider(shippingId)),
            ),
          ),
      data: (data) => ShippingQrScreen(label: data.label),
    );
  }
}
