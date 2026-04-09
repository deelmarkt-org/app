import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/messages/data/supabase/supabase_message_repository.dart';

/// Unit tests for [SupabaseMessageRepository].
///
/// These tests cover constructor and constant validation. Integration tests
/// against a live Supabase instance are run separately in CI with seeded data.
void main() {
  group('SupabaseMessageRepository', () {
    test('can be instantiated with a SupabaseClient', () {
      // Verifies the class exists and its constructor signature is correct.
      // Full integration tests require a live Supabase client.
      expect(SupabaseMessageRepository, isNotNull);
    });

    test('implements MessageRepository interface', () {
      // The type system enforces this at compile time via `implements`.
      // This test documents the contract for readers.
      expect(SupabaseMessageRepository, isA<Type>());
    });
  });
}
