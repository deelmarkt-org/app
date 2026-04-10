import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/async_page.dart';

import 'package:deelmarkt/features/shipping/presentation/screens/tracking_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

/// Route-facing page for `/shipping/:id/tracking`.
///
/// Fetches shipping label + tracking events and renders [TrackingScreen].
class TrackingPage extends ConsumerWidget {
  const TrackingPage({required this.shippingId, super.key});

  final String shippingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncPage(
      title: 'tracking.title'.tr(),
      state: ref.watch(shippingDetailProvider(shippingId)),
      onRetry: () => ref.invalidate(shippingDetailProvider(shippingId)),
      builder: (data) => TrackingScreen(label: data.label, events: data.events),
    );
  }
}
