import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Supabase implementation of [SettingsRepository].
///
/// Tables:
///   - `notification_preferences` — one row per user (upsert pattern)
///   - `user_addresses` — multiple per user, unique on
///     (user_id, postcode, house_number, addition)
///
/// Edge Functions:
///   - `export-user-data` — returns signed URL for GDPR export ZIP.
///     URL validated against [_exportAllowedHosts] before returning.
///   - `delete-account` — re-authenticates via `signInWithPassword`
///     server-side (OWASP ASVS L2 §4.2.1), then soft-deletes user
///     with 30-day PII cleanup. See issue #49.
///
/// Reference: CLAUDE.md §9 (RLS on all tables), issue #47
class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository(this._client);

  final SupabaseClient _client;

  static const _exportAllowedHosts = {'deelmarkt.nl', 'api.deelmarkt.nl'};

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
      final response =
          await _client
              .from('notification_preferences')
              .upsert({
                'user_id': _userId,
                'messages': prefs.messages,
                'offers': prefs.offers,
                'shipping_updates': prefs.shippingUpdates,
                'marketing': prefs.marketing,
              })
              .select()
              .single();

      return NotificationPreferences(
        messages: response['messages'] as bool? ?? true,
        offers: response['offers'] as bool? ?? true,
        shippingUpdates: response['shipping_updates'] as bool? ?? true,
        marketing: response['marketing'] as bool? ?? false,
      );
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
      final response =
          await _client
              .from('user_addresses')
              .upsert({
                'user_id': _userId,
                'postcode': address.postcode,
                'house_number': address.houseNumber,
                'addition': address.addition,
                'street': address.street,
                'city': address.city,
                'latitude': address.latitude,
                'longitude': address.longitude,
              }, onConflict: 'user_id,postcode,house_number,addition')
              .select()
              .single();

      return _addressFromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save address: ${e.message}');
    }
  }

  @override
  Future<void> deleteAddress(DutchAddress address) async {
    try {
      var query = _client
          .from('user_addresses')
          .delete()
          .eq('user_id', _userId)
          .eq('postcode', address.postcode)
          .eq('house_number', address.houseNumber);

      if (address.addition != null) {
        query = query.eq('addition', address.addition!);
      } else {
        query = query.isFilter('addition', null);
      }

      await query;
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

      // Validate URL against allowlist (defense-in-depth, HIGH-1 audit fix)
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          !_exportAllowedHosts.any(
            (h) => uri.host == h || uri.host.endsWith('.$h'),
          )) {
        throw Exception('Export returned untrusted URL');
      }

      return url;
    } on FunctionException catch (e) {
      throw Exception('Failed to export user data: ${e.reasonPhrase}');
    }
  }

  /// Permanently delete user account.
  ///
  /// The `delete-account` Edge Function MUST:
  /// 1. Verify the password via `supabase.auth.signInWithPassword`
  /// 2. Soft-delete the user (set `deleted_at` timestamp)
  /// 3. Trigger 30-day PII cleanup (see issue #49)
  ///
  /// The password is sent over HTTPS (Supabase Edge Functions enforce TLS).
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
