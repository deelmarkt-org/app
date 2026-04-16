import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/oauth_login_orchestrator.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

class _MockDatasource extends Mock implements AuthRemoteDatasource {}

void main() {
  late _MockDatasource ds;
  late OAuthLoginOrchestrator orchestrator;

  setUp(() {
    ds = _MockDatasource();
    orchestrator = OAuthLoginOrchestrator(
      ds,
      timeout: const Duration(milliseconds: 100),
    );
    when(
      () => ds.authStateChanges,
    ).thenAnswer((_) => const Stream<sb.AuthState>.empty());
  });

  sb.AuthResponse responseWithUser(String id) => sb.AuthResponse(
    user: sb.User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime(2026).toIso8601String(),
    ),
  );

  group('OAuthLoginOrchestrator', () {
    test('native Google success returns AuthSuccess', () async {
      when(
        () => ds.signInWithGoogle(),
      ).thenAnswer((_) async => responseWithUser('uid-g'));

      final result = await orchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'uid-g');
    });

    test('native Apple success returns AuthSuccess', () async {
      when(
        () => ds.signInWithApple(),
      ).thenAnswer((_) async => responseWithUser('uid-a'));

      final result = await orchestrator.loginWithOAuth(OAuthProvider.apple);

      expect(result, isA<AuthSuccess>());
    });

    test('null datasource response returns OAuthCancelled', () async {
      when(() => ds.signInWithGoogle()).thenAnswer((_) async => null);

      final result = await orchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureOAuthCancelled>());
    });

    test('AuthException provider_disabled maps to OAuthUnavailable', () async {
      when(() => ds.signInWithApple()).thenThrow(
        const sb.AuthException('Provider is disabled', statusCode: '422'),
      );

      final result = await orchestrator.loginWithOAuth(OAuthProvider.apple);

      expect(result, isA<AuthFailureOAuthUnavailable>());
    });

    test('429 AuthException maps to RateLimited', () async {
      when(
        () => ds.signInWithGoogle(),
      ).thenThrow(const sb.AuthException('rate limited', statusCode: '429'));

      final result = await orchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureRateLimited>());
    });

    test('generic network error maps to NetworkError', () async {
      when(
        () => ds.signInWithGoogle(),
      ).thenThrow(Exception('SocketException: connection refused'));

      final result = await orchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureNetworkError>());
    });

    test('AuthResponse without user returns AuthFailureUnknown', () async {
      when(
        () => ds.signInWithGoogle(),
      ).thenAnswer((_) async => sb.AuthResponse());

      final result = await orchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureUnknown>());
    });
  });

  group('OAuthLoginOrchestrator (web redirect flow)', () {
    late _MockDatasource wds;
    late OAuthLoginOrchestrator webOrchestrator;
    late StreamController<sb.AuthState> authStream;

    setUp(() {
      wds = _MockDatasource();
      authStream = StreamController<sb.AuthState>.broadcast();
      when(() => wds.authStateChanges).thenAnswer((_) => authStream.stream);
      webOrchestrator = OAuthLoginOrchestrator(
        wds,
        timeout: const Duration(milliseconds: 200),
        awaitWebRedirect: true,
      );
    });

    tearDown(() => authStream.close());

    test('signedIn event with user resolves to AuthSuccess', () async {
      when(() => wds.signInWithGoogle()).thenAnswer((_) async => null);
      final user = sb.User(
        id: 'web-uid',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );
      final session = sb.Session(
        accessToken: 'a',
        tokenType: 'bearer',
        user: user,
        refreshToken: 'r',
      );

      final future = webOrchestrator.loginWithOAuth(OAuthProvider.google);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      authStream.add(sb.AuthState(sb.AuthChangeEvent.signedIn, session));

      final result = await future;
      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'web-uid');
    });

    test('timeout with no signedIn event returns OAuthCancelled', () async {
      when(() => wds.signInWithGoogle()).thenAnswer((_) async => null);

      final result = await webOrchestrator.loginWithOAuth(OAuthProvider.google);

      expect(result, isA<AuthFailureOAuthCancelled>());
    });

    test('non-signedIn events are ignored until timeout', () async {
      when(() => wds.signInWithApple()).thenAnswer((_) async => null);

      final future = webOrchestrator.loginWithOAuth(OAuthProvider.apple);
      authStream
        ..add(const sb.AuthState(sb.AuthChangeEvent.tokenRefreshed, null))
        ..add(const sb.AuthState(sb.AuthChangeEvent.signedOut, null));

      final result = await future;
      expect(result, isA<AuthFailureOAuthCancelled>());
    });
  });
}
