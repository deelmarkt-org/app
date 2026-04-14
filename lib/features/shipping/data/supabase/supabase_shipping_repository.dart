import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/shipping/data/dto/parcel_shop_dto.dart';
import 'package:deelmarkt/features/shipping/data/dto/shipping_label_dto.dart';
import 'package:deelmarkt/features/shipping/data/dto/tracking_event_dto.dart';
import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/domain/repositories/shipping_repository.dart';

/// Supabase implementation of [ShippingRepository].
///
/// Labels and tracking events are read from DB tables.
/// Parcel shops are fetched via an Edge Function that calls carrier APIs.
///
/// Reference: migration 20260324223334_shipping_labels_and_tracking_events.sql
class SupabaseShippingRepository implements ShippingRepository {
  const SupabaseShippingRepository(this._client);

  final SupabaseClient _client;

  static const _parcelShopsFunction = 'get-parcel-shops';

  @override
  Future<ShippingLabel?> getLabel(String shippingId) async {
    try {
      final response =
          await _client
              .from('shipping_labels')
              .select()
              .eq('id', shippingId)
              .maybeSingle();

      if (response == null) return null;
      return ShippingLabelDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch shipping label: ${e.message}');
    }
  }

  @override
  Future<List<TrackingEvent>> getTrackingEvents(String shippingId) async {
    try {
      final response = await _client
          .from('tracking_events')
          .select()
          .eq('shipping_label_id', shippingId)
          .order('occurred_at', ascending: false);

      return TrackingEventDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch tracking events: ${e.message}');
    }
  }

  @override
  Future<List<ParcelShop>> getParcelShops(String postalCode) async {
    try {
      final response = await _client.functions.invoke(
        _parcelShopsFunction,
        body: {'postal_code': postalCode},
      );

      final data = response.data;
      if (data is! List) return [];
      return ParcelShopDto.fromJsonList(data);
    } on FunctionException catch (e) {
      throw Exception('Failed to fetch parcel shops: ${e.details}');
    }
  }
}
