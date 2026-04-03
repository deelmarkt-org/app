import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Initiates iDIN bank verification and returns the validated redirect URL.
///
/// Enforces URL allowlist validation to prevent open redirect attacks.
/// The URL must be HTTPS and from an approved iDIN/DeelMarkt domain.
class InitiateIdinVerificationUseCase {
  const InitiateIdinVerificationUseCase(this._repository);
  final AuthRepository _repository;

  /// Allowed hosts for iDIN redirect URLs.
  static const _allowedHosts = {
    'www.idin.nl',
    'idin.nl',
    'auth.deelmarkt.nl',
    'api.deelmarkt.nl',
  };

  Future<String> call() async {
    final url = await _repository.initiateIdinVerification();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !_allowedHosts.any(
          (host) => uri.host == host || uri.host.endsWith('.$host'),
        )) {
      throw StateError('iDIN redirect URL failed allowlist validation');
    }
    return url;
  }
}
