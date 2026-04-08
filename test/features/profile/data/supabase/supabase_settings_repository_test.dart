import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/features/profile/data/supabase/supabase_settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// Fake [User] with fixed [id] and optional [email].
/// Avoids stubbing non-nullable String getters through `when()` — doing so
/// triggers a mocktail capture-mode null-safety error that leaves `_whenCall`
/// dirty and poisons subsequent `when()` calls in the same test suite.
class _StubUser extends Fake implements User {
  _StubUser({required this.id, this.email});

  @override
  final String id;

  @override
  final String? email;
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

// _MaybeSingleResult is a thin Future wrapper for PostgrestTransformBuilder<T?>
// that avoids the complexity of mocking the full Postgrest chain.
// It resolves immediately to [value] when awaited.
class _MaybeSingleResult extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  _MaybeSingleResult(this._value);

  final Map<String, dynamic>? _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) => Future<Map<String, dynamic>?>.value(
    _value,
  ).then(onValue, onError: onError);

  @override
  Stream<Map<String, dynamic>?> asStream() =>
      Future<Map<String, dynamic>?>.value(_value).asStream();

  @override
  Future<Map<String, dynamic>?> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) => Future<Map<String, dynamic>?>.value(
    _value,
  ).catchError(onError, test: test);

  @override
  Future<Map<String, dynamic>?> timeout(
    Duration timeLimit, {
    FutureOr<Map<String, dynamic>?> Function()? onTimeout,
  }) => Future<Map<String, dynamic>?>.value(
    _value,
  ).timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<Map<String, dynamic>?> whenComplete(
    FutureOr<void> Function() action,
  ) => Future<Map<String, dynamic>?>.value(_value).whenComplete(action);
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _uid = 'user-abc-123';
const _tEmail = 'user@example.com';

const _tAddress = DutchAddress(
  postcode: '1012 AB',
  houseNumber: '10',
  street: 'Damrak',
  city: 'Amsterdam',
);

const _tPrefsJson = <String, dynamic>{
  'messages': true,
  'offers': false,
  'shipping_updates': true,
  'marketing': false,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _arrangeAuthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_StubUser(id: _uid, email: _tEmail));
}

void _arrangeUnauthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFunctionsClient functions;
  late SupabaseSettingsRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    functions = MockFunctionsClient();
    repo = SupabaseSettingsRepository(client);
  });

  // =========================================================================
  // _userId guard — all methods throw when user is not authenticated
  // =========================================================================

  group('_userId guard', () {
    setUp(() => _arrangeUnauthenticated(client, auth));

    test('getNotificationPreferences throws when unauthenticated', () async {
      await expectLater(
        repo.getNotificationPreferences(),
        throwsA(isA<Exception>()),
      );
    });

    test('updateNotificationPreferences throws Not authenticated', () async {
      await expectLater(
        repo.updateNotificationPreferences(const NotificationPreferences()),
        throwsA(isA<Exception>()),
      );
    });

    test('getAddresses throws Not authenticated', () async {
      await expectLater(repo.getAddresses(), throwsA(isA<Exception>()));
    });

    test('saveAddress throws Not authenticated', () async {
      await expectLater(repo.saveAddress(_tAddress), throwsA(isA<Exception>()));
    });

    test('deleteAddress throws Not authenticated', () async {
      await expectLater(
        repo.deleteAddress(_tAddress),
        throwsA(isA<Exception>()),
      );
    });
  });

  // =========================================================================
  // getNotificationPreferences
  // =========================================================================

  group('getNotificationPreferences', () {
    late MockSupabaseQueryBuilder qb;
    late MockFilterBuilder fb;

    setUp(() {
      _arrangeAuthenticated(client, auth);
      qb = MockSupabaseQueryBuilder();
      fb = MockFilterBuilder();
      // Use thenAnswer (not thenReturn) for Future-implementing Postgrest types
      // to avoid mocktail leaving _whenCall dirty on ArgumentError.
      when(() => client.from('notification_preferences')).thenAnswer((_) => qb);
      when(() => qb.select()).thenAnswer((_) => fb);
      when(() => fb.eq('user_id', _uid)).thenAnswer((_) => fb);
    });

    test('returns default NotificationPreferences when row is null', () async {
      when(() => fb.maybeSingle()).thenAnswer((_) => _MaybeSingleResult(null));

      final result = await repo.getNotificationPreferences();

      expect(result, equals(const NotificationPreferences()));
    });

    test('maps JSON row to NotificationPreferences', () async {
      when(
        () => fb.maybeSingle(),
      ).thenAnswer((_) => _MaybeSingleResult(_tPrefsJson));

      final result = await repo.getNotificationPreferences();

      expect(result.messages, isTrue);
      expect(result.offers, isFalse);
      expect(result.shippingUpdates, isTrue);
      expect(result.marketing, isFalse);
    });

    test('wraps PostgrestException in Exception', () async {
      when(
        () => fb.maybeSingle(),
      ).thenThrow(const PostgrestException(message: 'db error'));

      await expectLater(
        repo.getNotificationPreferences(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch notification preferences'),
          ),
        ),
      );
    });
  });

  // =========================================================================
  // exportUserData
  // =========================================================================

  group('exportUserData', () {
    setUp(() {
      _arrangeAuthenticated(client, auth);
      when(() => client.functions).thenReturn(functions);
    });

    test('returns trusted deelmarkt.nl URL on success', () async {
      when(() => functions.invoke('export-user-data')).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {'url': 'https://api.deelmarkt.nl/export/abc.zip'},
        ),
      );

      final url = await repo.exportUserData();

      expect(url, equals('https://api.deelmarkt.nl/export/abc.zip'));
    });

    test('throws on non-200 status code', () async {
      when(
        () => functions.invoke('export-user-data'),
      ).thenAnswer((_) async => FunctionResponse(status: 500));

      await expectLater(
        repo.exportUserData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Export failed with status 500'),
          ),
        ),
      );
    });

    test('throws on untrusted export URL (SSRF defence)', () async {
      when(() => functions.invoke('export-user-data')).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {'url': 'https://evil.com/steal-data'},
        ),
      );

      await expectLater(
        repo.exportUserData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('untrusted URL'),
          ),
        ),
      );
    });

    test('throws on FunctionException', () async {
      when(() => functions.invoke('export-user-data')).thenThrow(
        const FunctionException(
          status: 500,
          reasonPhrase: 'Internal Server Error',
        ),
      );

      await expectLater(
        repo.exportUserData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to export user data'),
          ),
        ),
      );
    });
  });

  // =========================================================================
  // deleteAccount
  // =========================================================================

  group('deleteAccount', () {
    const tPassword = 'Secret1!'; // pragma: allowlist secret

    setUp(() {
      _arrangeAuthenticated(client, auth);
      when(() => client.functions).thenReturn(functions);
    });

    test(
      're-authenticates then invokes delete-account Edge Function',
      () async {
        when(
          () => auth.signInWithPassword(email: _tEmail, password: tPassword),
        ).thenAnswer((_) async => AuthResponse());
        when(
          () => functions.invoke('delete-account'),
        ).thenAnswer((_) async => FunctionResponse(status: 200));
        when(() => auth.signOut()).thenAnswer((_) async {});

        await repo.deleteAccount(password: tPassword);

        verify(
          () => auth.signInWithPassword(email: _tEmail, password: tPassword),
        ).called(1);
        verify(() => functions.invoke('delete-account')).called(1);
      },
    );

    test('throws wrapped AuthException on wrong password', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid credentials'));

      await expectLater(
        repo.deleteAccount(password: tPassword),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Authentication failed'),
          ),
        ),
      );
      verifyNever(() => functions.invoke(any()));
    });

    test('throws wrapped FunctionException when Edge Function fails', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());
      when(() => functions.invoke('delete-account')).thenThrow(
        const FunctionException(status: 500, reasonPhrase: 'Not Found'),
      );

      await expectLater(
        repo.deleteAccount(password: tPassword),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete account'),
          ),
        ),
      );
    });

    test('throws Not authenticated when currentUser email is null', () async {
      when(() => auth.currentUser).thenReturn(_StubUser(id: _uid));

      await expectLater(
        repo.deleteAccount(password: tPassword),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Not authenticated'),
          ),
        ),
      );
      verifyNever(() => functions.invoke(any()));
    });
  });
}
