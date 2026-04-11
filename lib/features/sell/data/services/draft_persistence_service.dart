import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Persists listing creation drafts to SharedPreferences.
///
/// Schema version 2 (P-24): persists only successfully uploaded images so
/// drafts survive across sessions without dangling local file paths. Pending
/// and failed uploads are dropped on save — the user must re-pick.
///
/// Uses **strict equality** on the version field: a missing or differing
/// `v` returns null (drops the draft) rather than risking partial parses.
/// This handles both backward (v1 legacy) and forward (future v3) cases.
class DraftPersistenceService {
  DraftPersistenceService(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'listing_creation_draft';
  static const int _schemaVersion = 2;

  /// Saves the current creation state as a JSON draft.
  ///
  /// Only persists user-entered fields and **uploaded** images — UI state
  /// and in-flight uploads are excluded.
  Future<void> save(ListingCreationState state) async {
    final uploadedImages = state.imageFiles
        .where((i) => i.isUploaded)
        .map(_serializeImage)
        .toList(growable: false);

    final data = <String, Object?>{
      'v': _schemaVersion,
      'imageFiles': uploadedImages,
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

  /// Restores a previously saved draft, or null if none exists or the
  /// schema version doesn't match.
  ///
  /// Always restores to [ListingCreationStep.photos]. Defensive parsing
  /// returns null on any structural error rather than crashing.
  ListingCreationState? restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      // Strict version check — drop incompatible drafts.
      if (data['v'] != _schemaVersion) return null;

      return ListingCreationState(
        // ignore: avoid_redundant_argument_values
        step: ListingCreationStep.photos, // always restart from step 1
        imageFiles: _parseImages(data['imageFiles']),
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

  static Map<String, Object?> _serializeImage(SellImage image) =>
      image.toJson();

  List<SellImage> _parseImages(Object? value) {
    if (value is! List) return const [];
    final result = <SellImage>[];
    for (final item in value) {
      if (item is! Map) continue;
      final id = item['id'];
      final localPath = item['localPath'];
      final deliveryUrl = item['deliveryUrl'];
      if (id is! String || localPath is! String || deliveryUrl is! String) {
        continue;
      }
      try {
        result.add(SellImage.fromJson(Map<String, dynamic>.from(item)));
      } on Object {
        continue; // defensive: drop malformed entries
      }
    }
    return result;
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
