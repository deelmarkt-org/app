import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockFunctionsClient mockFunctions;
  late AuthRemoteDatasource datasource;

  final tAuthResponse = AuthResponse();

  setUpAll(() {
    registerFallbackValue(OtpType.signup);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.functions).thenReturn(mockFunctions);
    datasource = AuthRemoteDatasource(mockClient);
  });

  // ---------------------------------------------------------------------------
  // signUpWithEmail
  // ---------------------------------------------------------------------------
  group('signUpWithEmail', () {
    test('delegates to client.auth.signUp with correct params', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => tAuthResponse);

      final result = await datasource.signUpWithEmail(
        email: 'test@test.com',
        password: 'pass123', // pragma: allowlist secret
        metadata: {'terms_accepted_at': '2026-01-01'},
      );

      expect(result, tAuthResponse);
      verify(
        () => mockAuth.signUp(
          email: 'test@test.com',
          password: 'pass123', // pragma: allowlist secret
          data: {'terms_accepted_at': '2026-01-01'},
        ),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // resendEmailOtp
  // ---------------------------------------------------------------------------
  group('resendEmailOtp', () {
    test('delegates to client.auth.resend with signup type', () async {
      when(
        () => mockAuth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => ResendResponse());

      await datasource.resendEmailOtp(email: 'test@test.com');

      verify(
        () => mockAuth.resend(type: OtpType.signup, email: 'test@test.com'),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // verifyEmailOtp
  // ---------------------------------------------------------------------------
  group('verifyEmailOtp', () {
    test('delegates to client.auth.verifyOTP with email type', () async {
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tAuthResponse);

      final result = await datasource.verifyEmailOtp(
        email: 'test@test.com',
        token: '123456',
      );

      expect(result, tAuthResponse);
      verify(
        () => mockAuth.verifyOTP(
          type: OtpType.email,
          email: 'test@test.com',
          token: '123456',
        ),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // sendPhoneOtp
  // ---------------------------------------------------------------------------
  group('sendPhoneOtp', () {
    test('delegates to client.auth.signInWithOtp with phone', () async {
      when(
        () => mockAuth.signInWithOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async => tAuthResponse);

      await datasource.sendPhoneOtp(phone: '+31612345678');

      verify(() => mockAuth.signInWithOtp(phone: '+31612345678')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // verifyPhoneOtp
  // ---------------------------------------------------------------------------
  group('verifyPhoneOtp', () {
    test('delegates to client.auth.verifyOTP with sms type', () async {
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tAuthResponse);

      final result = await datasource.verifyPhoneOtp(
        phone: '+31612345678',
        token: '654321',
      );

      expect(result, tAuthResponse);
      verify(
        () => mockAuth.verifyOTP(
          type: OtpType.sms,
          phone: '+31612345678',
          token: '654321',
        ),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // signInWithPassword (P-16)
  // ---------------------------------------------------------------------------
  group('signInWithPassword', () {
    test('delegates to client.auth.signInWithPassword', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tAuthResponse);

      final result = await datasource.signInWithPassword(
        email: 'test@test.com',
        password: 'SecureP@ss1', // pragma: allowlist secret
      );

      expect(result, tAuthResponse);
      verify(
        () => mockAuth.signInWithPassword(
          email: 'test@test.com',
          password: 'SecureP@ss1', // pragma: allowlist secret
        ),
      ).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // refreshSession (P-16)
  // ---------------------------------------------------------------------------
  group('refreshSession', () {
    test('delegates to client.auth.refreshSession', () async {
      when(
        () => mockAuth.refreshSession(),
      ).thenAnswer((_) async => tAuthResponse);

      final result = await datasource.refreshSession();

      expect(result, tAuthResponse);
      verify(() => mockAuth.refreshSession()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // currentSession (P-16)
  // ---------------------------------------------------------------------------
  group('currentSession', () {
    test('returns session from client.auth', () {
      final tUser = User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final tSession = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: tUser,
      );
      when(() => mockAuth.currentSession).thenReturn(tSession);

      expect(datasource.currentSession, tSession);
    });

    test('returns null when no session', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(datasource.currentSession, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // initiateIdin
  // ---------------------------------------------------------------------------
  group('initiateIdin', () {
    test('delegates to client.functions.invoke with initiate-idin', () async {
      final tResponse = FunctionResponse(
        status: 200,
        data: const {
          'redirect_url': 'https://auth.deelmarkt.nl/idin/mock-complete',
        },
      );
      when(
        () => mockFunctions.invoke('initiate-idin'),
      ).thenAnswer((_) async => tResponse);

      final result = await datasource.initiateIdin();

      expect(result, tResponse);
      verify(() => mockFunctions.invoke('initiate-idin')).called(1);
    });
  });
}
