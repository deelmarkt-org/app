import '../entities/user_entity.dart';

/// User repository interface — domain layer.
abstract class UserRepository {
  /// Get a user profile by ID.
  Future<UserEntity?> getById(String id);

  /// Get the current authenticated user's profile.
  Future<UserEntity?> getCurrentUser();

  /// Update user profile fields.
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  });
}
