import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_error_mapper.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

/// Orchestrates the OAuth login flow across native (mobile) and web platforms.
///
/// - Mobile: datasource returns an [sb.AuthResponse] synchronously — we map
///   to [AuthSuccess] immediately.
/// - Web: datasource kicks off the redirect and returns null — we await the
///   next `signedIn` event via [AuthRemoteDatasource.authStateChanges], up to
///   [timeout].
///
/// Extracted from `AuthRepositoryImpl` to keep that file under the 200-line
/// cap per CLAUDE.md §2.1.
class OAuthLoginOrchestrator with AuthErrorMapper {
  OAuthLoginOrchestrator(this._datasource, {this.timeout = _defaultTimeout});

  static const Duration _defaultTimeout = Duration(seconds: 60);

  final AuthRemoteDatasource _datasource;
  final Duration timeout;

  Future<AuthResult> loginWithOAuth(OAuthProvider provider) async {
    // Subscribe BEFORE triggering the redirect to avoid racing the event.
    final webSignInFuture = kIsWeb ? _awaitSignedInEvent() : null;

    try {
      final response = await switch (provider) {
        OAuthProvider.google => _datasource.signInWithGoogle(),
        OAuthProvider.apple => _datasource.signInWithApple(),
      };

      if (response != null) {
        final userId = response.user?.id;
        if (userId == null) {
          return const AuthFailureUnknown(message: 'No user returned');
        }
        return AuthSuccess(userId: userId);
      }

      if (webSignInFuture != null) {
        final userId = await webSignInFuture;
        return userId != null
            ? AuthSuccess(userId: userId)
            : const AuthFailureOAuthCancelled();
      }
      return const AuthFailureOAuthCancelled();
    } on sb.AuthException catch (e) {
      return mapOAuthAuthError(e);
    } on Object catch (e) {
      return mapLoginGenericError(e);
    }
  }

  /// Completes with the user id on the next `signedIn` event, or null after
  /// [timeout]. Always cancels the subscription + timer on completion.
  Future<String?> _awaitSignedInEvent() {
    final completer = Completer<String?>();
    late final StreamSubscription<sb.AuthState> sub;
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    sub = _datasource.authStateChanges.listen((state) {
      if (state.event == sb.AuthChangeEvent.signedIn) {
        final userId = state.session?.user.id;
        if (!completer.isCompleted) completer.complete(userId);
      }
    });
    return completer.future.whenComplete(() {
      timer.cancel();
      sub.cancel();
    });
  }
}
