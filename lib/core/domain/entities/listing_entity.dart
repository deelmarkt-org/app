// Re-export ListingEntity and related types for cross-feature use.
// Per CLAUDE.md §1.2: "Never import from one feature into another —
// use shared core/". Features that own the entity import directly;
// other features import from this barrel.
export 'package:deelmarkt/features/home/domain/entities/listing_condition.dart';
export 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
export 'package:deelmarkt/features/home/domain/entities/listing_status.dart';
