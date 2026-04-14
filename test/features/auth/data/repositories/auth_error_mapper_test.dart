import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_error_mapper.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

// Minimal concrete class to exercise the mixin.
class _TestMapper with AuthErrorMapper {}

void main() {
  late _TestMapper mapper;

  setUp(() => mapper = _TestMapper());

  sb.AuthException makeAuthEx(String message, {String? statusCode}) =>
      sb.AuthException(message, statusCode: statusCode);

  group('AuthErrorMapper.mapOAuthAuthError', () {
    test(
      'returns OAuthUnavailable when message contains provider + disabled',
      () {
        final e = makeAuthEx('OAuth provider is disabled');
        expect(mapper.mapOAuthAuthError(e), isA<AuthFailureOAuthUnavailable>());
      },
    );

    test('returns OAuthUnavailable case-insensitively', () {
      final e = makeAuthEx('PROVIDER is DISABLED for this project');
      expect(mapper.mapOAuthAuthError(e), isA<AuthFailureOAuthUnavailable>());
    });

    test('delegates to mapLoginAuthError for 429 rate limit', () {
      final e = makeAuthEx('rate limited', statusCode: '429');
      expect(mapper.mapOAuthAuthError(e), isA<AuthFailureRateLimited>());
    });

    test('delegates to mapLoginAuthError for 400 invalid credentials', () {
      final e = makeAuthEx('invalid login credentials', statusCode: '400');
      expect(mapper.mapOAuthAuthError(e), isA<AuthFailureInvalidCredentials>());
    });

    test('returns AuthFailureUnknown for unrecognised error', () {
      final e = makeAuthEx('something went wrong', statusCode: '500');
      expect(mapper.mapOAuthAuthError(e), isA<AuthFailureUnknown>());
    });
  });

  group('AuthErrorMapper.mapLoginAuthError', () {
    test('returns RateLimited on 429 status code', () {
      final e = makeAuthEx('too many requests', statusCode: '429');
      final result = mapper.mapLoginAuthError(e);
      expect(result, isA<AuthFailureRateLimited>());
    });

    test('returns InvalidCredentials on 400 status code', () {
      final e = makeAuthEx('invalid login credentials', statusCode: '400');
      expect(mapper.mapLoginAuthError(e), isA<AuthFailureInvalidCredentials>());
    });

    test('returns InvalidCredentials when message contains invalid login', () {
      final e = makeAuthEx('invalid login');
      expect(mapper.mapLoginAuthError(e), isA<AuthFailureInvalidCredentials>());
    });

    test('returns RateLimited when message contains rate', () {
      final e = makeAuthEx('rate limit exceeded');
      expect(mapper.mapLoginAuthError(e), isA<AuthFailureRateLimited>());
    });
  });

  group('AuthErrorMapper.mapLoginGenericError', () {
    test('returns NetworkError for SocketException-like errors', () {
      final e = Exception('SocketException: connection refused');
      final result = mapper.mapLoginGenericError(e);
      expect(result, isA<AuthFailureNetworkError>());
    });

    test('returns AuthFailureUnknown for unrelated errors', () {
      final e = Exception('something else');
      expect(mapper.mapLoginGenericError(e), isA<AuthFailureUnknown>());
    });
  });

  group('AuthErrorMapper.mapAuthError', () {
    test('returns rate_limited on 429', () {
      final e = makeAuthEx('rate limited', statusCode: '429');
      final result = mapper.mapAuthError(e);
      expect(result, isA<AuthException>());
      expect((result as AuthException).messageKey, 'error.rate_limited');
    });

    test('returns otp_expired on 422 with expired message', () {
      final e = makeAuthEx('token has expired', statusCode: '422');
      final result = mapper.mapAuthError(e);
      expect(result, isA<AuthException>());
      expect((result as AuthException).messageKey, 'error.otp_expired');
    });

    test('returns email_taken on already registered message', () {
      final e = makeAuthEx('User already registered');
      final result = mapper.mapAuthError(e);
      expect(result, isA<AuthException>());
      expect((result as AuthException).messageKey, 'error.email_taken');
    });
  });
}
