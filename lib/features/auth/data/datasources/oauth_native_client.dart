import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native OAuth orchestrator for Google + Apple — isolates the platform
/// package APIs from [AuthRemoteDatasource] so that layer stays small.
///
/// On web, falls back to Supabase's [signInWithOAuth] redirect flow; the
/// repository then awaits the signed-in event via `onAuthStateChange`.
class OAuthNativeClient {
  OAuthNativeClient(
    this._client, {
    GoogleSignIn? googleSignIn,
    Future<AuthorizationCredentialAppleID> Function({
      List<AppleIDAuthorizationScopes> scopes,
      String nonce,
    })?
    appleRequester,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
       _appleRequester = appleRequester ?? _defaultAppleRequester;

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final Future<AuthorizationCredentialAppleID> Function({
    List<AppleIDAuthorizationScopes> scopes,
    String nonce,
  })
  _appleRequester;

  static Future<AuthorizationCredentialAppleID> _defaultAppleRequester({
    List<AppleIDAuthorizationScopes> scopes = const [],
    String nonce = '',
  }) => SignInWithApple.getAppleIDCredential(scopes: scopes, nonce: nonce);

  /// Google — native sheet on mobile, redirect on web.
  Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      return null;
    }
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if (idToken == null || accessToken == null) return null;
      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on PlatformException {
      return null;
    }
  }

  /// Apple — native ASAuthorizationController on mobile with SHA-256 nonce
  /// (replay-attack protection required by Apple).
  Future<AuthResponse?> signInWithApple() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.apple);
      return null;
    }
    try {
      final rawNonce = _generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await _appleRequester(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) return null;
      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } on PlatformException {
      return null;
    }
  }

  /// 32 random bytes → base64url. Hashed (SHA-256) before Apple; raw is sent
  /// to Supabase so Supabase can verify Apple signed the hash.
  static String _generateRawNonce() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
