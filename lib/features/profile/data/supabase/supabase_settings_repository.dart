import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Supabase implementation of [SettingsRepository].
///
/// Tables: `notification_preferences`, `user_addresses`.
/// Edge Functions: `export-user-data`, `delete-account`.
///
/// Reference: CLAUDE.md §9 (RLS on all tables), issue #47.
class SupabaseSettingsRepository implements SettingsRepository {
  const SupabaseSettingsRepository(this._client);

  final SupabaseClient _client;

  static const _formatError = 'Unexpected data format from server';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Not authenticated');
    return id;
  }

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
      return _prefsFromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch notification preferences: ${e.message}');
    } on TypeError {
      throw Exception(_formatError);
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

      return _prefsFromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to update notification preferences: ${e.message}',
      );
    } on TypeError {
      throw Exception(_formatError);
    }
  }

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
    } on TypeError {
      throw Exception(_formatError);
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
    } on TypeError {
      throw Exception(_formatError);
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

  @override
  Future<String> exportUserData() async {
    try {
      final response = await _client.functions.invoke('export-user-data');
      final url = (response.data as Map<String, dynamic>?)?['url'];
      if (url is! String || url.isEmpty) {
        throw Exception('Export function returned no URL');
      }

      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          !AppConstants.trustedHosts.any(
            (h) => uri.host == h || uri.host.endsWith('.$h'),
          )) {
        throw Exception('Export returned untrusted URL');
      }

      return url;
    } on FunctionException catch (e) {
      throw Exception('Failed to export user data: ${e.reasonPhrase}');
    }
  }

  /// The `delete-account` Edge Function MUST:
  /// 1. Verify password via `supabase.auth.signInWithPassword`
  /// 2. Soft-delete the user (set `deleted_at` timestamp)
  /// 3. Trigger 30-day PII cleanup (see issue #49)
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

  static NotificationPreferences _prefsFromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      messages: json['messages'] as bool? ?? true,
      offers: json['offers'] as bool? ?? true,
      shippingUpdates: json['shipping_updates'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
    );
  }

  static DutchAddress _addressFromJson(Map<String, dynamic> json) {
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
