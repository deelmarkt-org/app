import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../dto/user_dto.dart';

/// Supabase implementation of [UserRepository].
///
/// Queries the `user_profiles` table. Public read for all profiles,
/// write restricted to own profile via RLS.
///
/// Reference: CLAUDE.md §1.2, docs/epics/E02-user-auth-kyc.md
class SupabaseUserRepository implements UserRepository {
  const SupabaseUserRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserEntity?> getById(String id) async {
    final response =
        await _client.from('user_profiles').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return UserDto.fromJson(response);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getById(userId);
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (location != null) updates['location'] = location;

    if (updates.isEmpty) {
      final current = await getById(userId);
      if (current == null) throw Exception('Profile not found');
      return current;
    }

    final response =
        await _client
            .from('user_profiles')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();

    return UserDto.fromJson(response);
  }
}
