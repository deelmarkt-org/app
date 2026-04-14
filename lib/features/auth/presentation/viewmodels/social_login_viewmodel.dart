import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

part 'social_login_viewmodel.g.dart';

/// State for the social login buttons.
///
/// [loadingProvider] is non-null while an OAuth sheet is open —
/// allows each button to show its own loading indicator independently.
class SocialLoginState {
  const SocialLoginState({this.loadingProvider, this.result});

  final OAuthProvider? loadingProvider;
  final AuthResult? result;

  bool get isLoading => loadingProvider != null;

  SocialLoginState copyWith({
    OAuthProvider? loadingProvider,
    AuthResult? result,
  }) {
    return SocialLoginState(loadingProvider: loadingProvider, result: result);
  }
}

/// ViewModel for Google + Apple sign-in buttons.
///
/// Reference: docs/screens/01-auth/05-social-login.md
@riverpod
class SocialLoginNotifier extends _$SocialLoginNotifier {
  @override
  SocialLoginState build() => const SocialLoginState();

  Future<AuthResult> signIn(OAuthProvider provider) async {
    state = SocialLoginState(loadingProvider: provider);
    final result = await ref
        .read(authRepositoryProvider)
        .loginWithOAuth(provider);
    state = SocialLoginState(result: result);
    return result;
  }
}
