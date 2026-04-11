import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/data/biometric_service.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockBiometricService extends Mock implements BiometricService {}

// ---------------------------------------------------------------------------
// Stub FunctionResponse — FunctionResponse is a final class so we fake it.
// ---------------------------------------------------------------------------

class _FakeResponse extends Fake implements sb.FunctionResponse {
  _FakeResponse({required this.data});

  @override
  final dynamic data;
}

void main() {
  late MockAuthRemoteDatasource mockDatasource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockAuthRemoteDatasource();
    repository = AuthRepositoryImpl(
      mockDatasource,
      biometricService: MockBiometricService(),
    );
  });

  group('AuthRepositoryImpl.initiateIdinVerification', () {
    test('returns redirect_url from EF on success', () async {
      when(() => mockDatasource.initiateIdin()).thenAnswer(
        (_) async => _FakeResponse(
          data: const {
            'redirect_url': 'https://auth.deelmarkt.nl/idin/mock-complete',
            'session_token': 'abc123',
            'mock': true,
          },
        ),
      );

      final url = await repository.initiateIdinVerification();

      expect(url, 'https://auth.deelmarkt.nl/idin/mock-complete');
    });

    test('throws on missing redirect_url in response', () async {
      when(() => mockDatasource.initiateIdin()).thenAnswer(
        (_) async => _FakeResponse(data: const {'session_token': 'abc123'}),
      );

      await expectLater(
        repository.initiateIdinVerification(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws on null data in response', () async {
      when(
        () => mockDatasource.initiateIdin(),
      ).thenAnswer((_) async => _FakeResponse(data: null));

      await expectLater(
        repository.initiateIdinVerification(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws on empty redirect_url', () async {
      when(() => mockDatasource.initiateIdin()).thenAnswer(
        (_) async => _FakeResponse(data: const {'redirect_url': ''}),
      );

      await expectLater(
        repository.initiateIdinVerification(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps FunctionException 409 to AuthException', () async {
      when(() => mockDatasource.initiateIdin()).thenThrow(
        const sb.FunctionException(
          status: 409,
          details: 'User already has a pending iDIN session',
        ),
      );

      await expectLater(
        repository.initiateIdinVerification(),
        throwsA(isA<sb.AuthException>()),
      );
    });

    test('maps generic exception to NetworkException', () async {
      when(
        () => mockDatasource.initiateIdin(),
      ).thenThrow(Exception('SocketException: Connection refused'));

      await expectLater(
        repository.initiateIdinVerification(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
