import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/models/quality_score_response.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Thin HTTP client for the R-26 `listing-quality-score` Edge Function.
///
/// The client-side `CalculateQualityScoreUseCase` runs on every
/// keystroke for real-time UI feedback. This service is the
/// authoritative publish gate — call it once before attempting to
/// create a listing, and honour [QualityScoreResponse.canPublish].
///
/// The weights on both sides are kept in sync at commit time by
/// `scripts/check_quality_score_parity.sh`, so the server score should
/// agree with the client score under normal conditions. A divergence
/// indicates the parity check failed to run or the EF is stale.
class ListingQualityScoreService {
  const ListingQualityScoreService(this._client);

  final SupabaseClient _client;

  static const _functionName = 'listing-quality-score';

  /// Invokes the Edge Function with the current creation state and
  /// returns the authoritative server score.
  ///
  /// Throws:
  ///  - [ValidationException] (`error.quality_score.invalid_request`)
  ///    if the server rejects the payload as malformed (HTTP 400).
  ///    Indicates a client/server contract drift — should never happen
  ///    in practice.
  ///  - [NetworkException] for any transport failure, 5xx, or malformed
  ///    response. Callers should fall back to the client-side score
  ///    for UX (the app stays usable) and retry at publish time.
  ///
  /// `supabase_flutter`'s `FunctionsClient.invoke()` throws
  /// [FunctionException] on any non-2xx status, so the happy path only
  /// has to parse the body. The catch block routes off the exception's
  /// `status` field.
  Future<QualityScoreResponse> calculate(ListingCreationState state) async {
    final body = _buildRequestBody(state);
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: body,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const NetworkException(
          debugMessage: 'listing-quality-score EF returned non-map payload',
        );
      }
      return QualityScoreResponse.fromJson(data);
    } on FunctionException catch (err) {
      if (err.status == 400) {
        throw ValidationException(
          'error.quality_score.invalid_request',
          debugMessage: 'listing-quality-score EF returned 400: ${err.details}',
        );
      }
      throw NetworkException(
        debugMessage:
            'listing-quality-score EF returned HTTP ${err.status}: ${err.reasonPhrase}',
      );
    } on FormatException catch (err) {
      throw NetworkException(
        debugMessage:
            'listing-quality-score payload parse failed: ${err.message}',
      );
    } on AppException {
      // Don't re-wrap our own typed exceptions (e.g. the non-map
      // payload NetworkException thrown a few lines above).
      rethrow;
    } catch (err) {
      // Fallback: SocketException / ClientException / TimeoutException
      // etc. must surface as a typed AppException so the sell flow
      // can fall back to the client-side score without crashing.
      // Matches the image-upload-service contract: every failure path
      // hands the caller an AppException subclass.
      throw NetworkException(
        debugMessage: 'listing-quality-score unexpected error: $err',
      );
    }
  }

  /// Converts the wizard state into the EF's `DraftSchema` body.
  ///
  /// Extracted so unit tests can verify the client/server contract
  /// without running the HTTP round-trip.
  static Map<String, dynamic> _buildRequestBody(ListingCreationState state) {
    return {
      'photo_count': state.imageFiles.length,
      'title': state.title,
      'description': state.description,
      'price_cents': state.priceInCents,
      'category_l2_id': state.categoryL2Id,
      'condition': state.condition?.toDb(),
    };
  }
}
