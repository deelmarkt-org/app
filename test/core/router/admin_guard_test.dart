import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/router/admin_guard.dart';

User _makeUser({Map<String, dynamic> appMetadata = const {}}) {
  return User(
    id: 'user-123',
    appMetadata: appMetadata,
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  group('isAdmin', () {
    test('returns false for null user', () {
      expect(isAdmin(null), isFalse);
    });

    test('returns false when appMetadata has no role', () {
      expect(isAdmin(_makeUser()), isFalse);
    });

    test('returns false when role is not admin', () {
      expect(isAdmin(_makeUser(appMetadata: {'role': 'user'})), isFalse);
    });

    test('returns true when role is admin', () {
      expect(isAdmin(_makeUser(appMetadata: {'role': 'admin'})), isTrue);
    });
  });
}
