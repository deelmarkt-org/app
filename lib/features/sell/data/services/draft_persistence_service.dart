import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Persists listing creation drafts to SharedPreferences.
///
/// Saves only user-entered data (not UI state like step, isLoading, errorKey).
/// On restore, always restarts from [ListingCreationStep.photos].
class DraftPersistenceService {
  DraftPersistenceService(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'listing_creation_draft';

  /// Saves the current creation state as a JSON draft.
  ///
  /// Only persists user-entered fields — UI state is excluded.
  Future<void> save(ListingCreationState state) async {
    final data = <String, Object?>{
      'imageFiles': state.imageFiles,
      'title': state.title,
      'description': state.description,
      'categoryL1Id': state.categoryL1Id,
      'categoryL2Id': state.categoryL2Id,
      'condition': state.condition?.name,
      'priceInCents': state.priceInCents,
      'shippingCarrier': state.shippingCarrier.name,
      'weightRange': state.weightRange?.name,
      'location': state.location,
    };

    await _prefs.setString(_key, jsonEncode(data));
  }

  /// Restores a previously saved draft, or null if none exists.
  ///
  /// Always restores to [ListingCreationStep.photos] so the user
  /// reviews their photos first. Uses defensive parsing — returns
  /// null for invalid JSON rather than crashing.
  ListingCreationState? restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      return ListingCreationState(
        // ignore: avoid_redundant_argument_values
        step: ListingCreationStep.photos, // always restart from step 1
        imageFiles: _parseStringList(data['imageFiles']),
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        categoryL1Id: data['categoryL1Id'] as String?,
        categoryL2Id: data['categoryL2Id'] as String?,
        condition: _parseCondition(data['condition'] as String?),
        priceInCents: data['priceInCents'] as int? ?? 0,
        shippingCarrier: _parseShippingCarrier(
          data['shippingCarrier'] as String?,
        ),
        weightRange: _parseWeightRange(data['weightRange'] as String?),
        location: data['location'] as String?,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Removes the saved draft.
  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  List<String> _parseStringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  ListingCondition? _parseCondition(String? value) {
    if (value == null) return null;
    try {
      return ListingCondition.values.byName(value);
    } on ArgumentError {
      return null;
    }
  }

  ShippingCarrier _parseShippingCarrier(String? value) {
    if (value == null) return ShippingCarrier.none;
    try {
      return ShippingCarrier.values.byName(value);
    } on ArgumentError {
      return ShippingCarrier.none;
    }
  }

  WeightRange? _parseWeightRange(String? value) {
    if (value == null) return null;
    try {
      return WeightRange.values.byName(value);
    } on ArgumentError {
      return null;
    }
  }
}
