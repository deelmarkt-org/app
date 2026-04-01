import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Fetches listings near the user's location for the home screen.
///
/// Default location: Amsterdam Centraal — replaced by device location
/// when LocationService is implemented (E05).
class GetNearbyListingsUseCase {
  const GetNearbyListingsUseCase(this._repo);

  final ListingRepository _repo;

  /// Default latitude (Amsterdam Centraal).
  static const defaultLatitude = 52.3676;

  /// Default longitude (Amsterdam Centraal).
  static const defaultLongitude = 4.9041;

  /// Returns nearby listings, defaulting to Amsterdam coords.
  Future<List<ListingEntity>> call({
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
    int limit = 10,
  }) => _repo.getNearby(latitude: latitude, longitude: longitude, limit: limit);
}
