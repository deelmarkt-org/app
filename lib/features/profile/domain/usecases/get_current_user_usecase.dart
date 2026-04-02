import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';

/// Retrieves the current authenticated user's profile.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);
  final UserRepository _repository;

  Future<UserEntity?> call() {
    return _repository.getCurrentUser();
  }
}
