import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/sell/data/mock/mock_image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/listing_quality_score_service.dart';

part 'sell_services_providers.g.dart';

/// Authoritative server-side quality score client (R-26).
///
/// Kept in a separate provider file from `sell_providers.dart` so the
/// upcoming Split B part 2 wiring (SupabaseListingCreationRepository)
/// can import it without churning the existing mock providers file.
@riverpod
ListingQualityScoreService listingQualityScoreService(Ref ref) {
  return ListingQualityScoreService(ref.watch(supabaseClientProvider));
}

/// Storage upload + Cloudmersive scan + Cloudinary pipeline client (R-27).
///
/// Returns [MockImageUploadService] when [useMockDataProvider] is true so
/// the sell wizard works in development without a live Supabase project.
@riverpod
ImageUploadService imageUploadService(Ref ref) {
  if (ref.watch(useMockDataProvider)) return MockImageUploadService();
  return ImageUploadService(ref.watch(supabaseClientProvider));
}
