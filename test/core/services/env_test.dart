import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/env.dart';

void main() {
  group('Env', () {
    test('supabaseUrl derives URL from project ID', () {
      final url = Env.supabaseUrl;
      expect(url, startsWith('https://'));
      expect(url, endsWith('.supabase.co'));
      expect(url, contains(Env.supabaseProjectId));
    });

    test('supabaseProjectId is non-empty', () {
      expect(Env.supabaseProjectId, isNotEmpty);
    });

    test('supabaseAnonKey is non-empty', () {
      expect(Env.supabaseAnonKey, isNotEmpty);
    });
  });
}
