import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

/// Combined shipping state: label + tracking events.
class ShippingDetailState extends Equatable {
  const ShippingDetailState({required this.label, required this.events});

  final ShippingLabel label;
  final List<TrackingEvent> events;

  @override
  List<Object?> get props => [label, events];
}

/// Provider family keyed by shipping ID — fetches label + tracking events.
final shippingDetailProvider =
    AutoDisposeFutureProvider.family<ShippingDetailState, String>((
      ref,
      id,
    ) async {
      final repo = ref.watch(shippingRepositoryProvider);
      final results = await Future.wait([
        repo.getLabel(id),
        repo.getTrackingEvents(id),
      ]);
      final label = results[0] as ShippingLabel?;
      if (label == null) throw Exception('Shipping label not found');
      final events = results[1] as List<TrackingEvent>;
      return ShippingDetailState(label: label, events: events);
    });

/// Provider family for parcel shops by postal code.
final parcelShopsProvider =
    AutoDisposeFutureProvider.family<List<ParcelShop>, String>((
      ref,
      postalCode,
    ) async {
      final repo = ref.watch(shippingRepositoryProvider);
      return repo.getParcelShops(postalCode);
    });
