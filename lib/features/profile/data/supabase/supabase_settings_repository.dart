import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Supabase implementation of [SettingsRepository].
///
/// Tables:
///   - `notification_preferences` — one row per user (upsert pattern)
///   - `user_addresses` — multiple per user, keyed by postcode + house_number
///
/// Edge Functions:
///   - `export-user-data` — returns signed URL for GDPR export ZIP
///   - `delete-account` — soft-deletes user, triggers 30-day PII cleanup
///
/// Reference: CLAUDE.md §9 (RLS on all tables), issue #47
class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Not authenticated');
    return id;
  }

  // ── Notification Preferences ─────────────────────────────────────────

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final response =
          await _client
              .from('notification_preferences')
              .select()
              .eq('user_id', _userId)
              .maybeSingle();

      if (response == null) return const NotificationPreferences();

      return NotificationPreferences(
        messages: response['messages'] as bool? ?? true,
        offers: response['offers'] as bool? ?? true,
        shippingUpdates: response['shipping_updates'] as bool? ?? true,
        marketing: response['marketing'] as bool? ?? false,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch notification preferences: ${e.message}');
    }
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      await _client.from('notification_preferences').upsert({
        'user_id': _userId,
        'messages': prefs.messages,
        'offers': prefs.offers,
        'shipping_updates': prefs.shippingUpdates,
        'marketing': prefs.marketing,
      });
      return prefs;
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to update notification preferences: ${e.message}',
      );
    }
  }

  // ── Addresses ────────────────────────────────────────────────────────

  @override
  Future<List<DutchAddress>> getAddresses() async {
    try {
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', _userId)
          .order('created_at');

      return response.map(_addressFromJson).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch addresses: ${e.message}');
    }
  }

  @override
  Future<DutchAddress> saveAddress(DutchAddress address) async {
    try {
      await _client.from('user_addresses').upsert({
        'user_id': _userId,
        'postcode': address.postcode,
        'house_number': address.houseNumber,
        'addition': address.addition,
        'street': address.street,
        'city': address.city,
        'latitude': address.latitude,
        'longitude': address.longitude,
      }, onConflict: 'user_id,postcode,house_number');
      return address;
    } on PostgrestException catch (e) {
      throw Exception('Failed to save address: ${e.message}');
    }
  }

  @override
  Future<void> deleteAddress(DutchAddress address) async {
    try {
      await _client
          .from('user_addresses')
          .delete()
          .eq('user_id', _userId)
          .eq('postcode', address.postcode)
          .eq('house_number', address.houseNumber);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete address: ${e.message}');
    }
  }

  // ── GDPR ─────────────────────────────────────────────────────────────

  @override
  Future<String> exportUserData() async {
    try {
      final response = await _client.functions.invoke('export-user-data');
      final url = (response.data as Map<String, dynamic>?)?['url'];
      if (url is! String || url.isEmpty) {
        throw Exception('Export function returned no URL');
      }
      return url;
    } on FunctionException catch (e) {
      throw Exception('Failed to export user data: ${e.reasonPhrase}');
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      await _client.functions.invoke(
        'delete-account',
        body: {'password': password},
      );
    } on FunctionException catch (e) {
      throw Exception('Failed to delete account: ${e.reasonPhrase}');
    }
  }

  DutchAddress _addressFromJson(Map<String, dynamic> json) {
    return DutchAddress(
      postcode: json['postcode'] as String,
      houseNumber: json['house_number'] as String,
      addition: json['addition'] as String?,
      street: json['street'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
