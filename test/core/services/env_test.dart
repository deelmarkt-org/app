import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/env.dart';

void main() {
  group('Env', () {
    test('supabaseUrl resolves to a non-empty URL', () {
      // Locally, SUPABASE_URL override points at http://127.0.0.1:54321.
      // In prod, projectId is set and the getter derives https://…supabase.co.
      // Either way, the string must not be empty.
      expect(Env.supabaseUrl, isNotEmpty);
      expect(
        Env.supabaseUrl,
        anyOf(startsWith('http://'), startsWith('https://')),
      );
    });

    test('supabaseProjectId is optional (defaults to empty)', () {
      // Field has defaultValue: '' so blank .env succeeds at build time.
      // Prod injects a real project id via Codemagic / CI env.
      expect(Env.supabaseProjectId, isNotNull);
    });

    test('supabaseAnonKey is non-empty', () {
      expect(Env.supabaseAnonKey, isNotEmpty);
    });
  });
}
