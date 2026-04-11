import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

/// Repository interface for shipping operations.
///
/// Domain layer — implementation in data layer (Supabase / mock).
abstract class ShippingRepository {
  /// Get the shipping label for a transaction.
  Future<ShippingLabel?> getLabel(String shippingId);

  /// Get tracking events for a shipment, newest first.
  Future<List<TrackingEvent>> getTrackingEvents(String shippingId);

  /// Get nearby parcel shops for a postal code.
  Future<List<ParcelShop>> getParcelShops(String postalCode);
}
