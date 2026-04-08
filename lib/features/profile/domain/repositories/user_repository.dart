import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// User repository interface — domain layer.
abstract class UserRepository {
  /// Get a user profile by ID.
  Future<UserEntity?> getById(String id);

  /// Get the current authenticated user's profile.
  Future<UserEntity?> getCurrentUser();

  /// Report a user for DSA Art. 16 compliance.
  Future<void> reportUser(String userId, ReportReason reason);

  /// Update user profile fields.
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  });
}
