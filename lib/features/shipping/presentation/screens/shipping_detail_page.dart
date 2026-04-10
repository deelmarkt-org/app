import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/async_page.dart';

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
    return AsyncPage(
      title: 'shipping.details'.tr(),
      state: ref.watch(shippingDetailProvider(shippingId)),
      onRetry: () => ref.invalidate(shippingDetailProvider(shippingId)),
      builder:
          (data) =>
              ShippingDetailScreen(label: data.label, events: data.events),
    );
  }
}
