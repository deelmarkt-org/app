import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/error_state.dart';

import 'package:deelmarkt/features/shipping/presentation/screens/shipping_detail_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

/// Route-facing page for `/shipping/:id`.
///
/// Fetches shipping label + tracking events by ID,
/// handles loading/error states, and renders [ShippingDetailScreen].
class ShippingDetailPage extends ConsumerWidget {
  const ShippingDetailPage({required this.shippingId, super.key});

  final String shippingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shippingDetailProvider(shippingId));

    return state.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: Text('shipping.details'.tr())),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, _) => Scaffold(
            appBar: AppBar(title: Text('shipping.details'.tr())),
            body: ErrorState(
              onRetry: () => ref.invalidate(shippingDetailProvider(shippingId)),
            ),
          ),
      data:
          (data) =>
              ShippingDetailScreen(label: data.label, events: data.events),
    );
  }
}
