import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/core/domain/entities/dutch_address.dart';

/// Save (add or update) a user address.
class SaveAddressUseCase {
  const SaveAddressUseCase({required this.repository});

  final SettingsRepository repository;

  Future<DutchAddress> call(DutchAddress address) {
    return repository.saveAddress(address);
  }
}
