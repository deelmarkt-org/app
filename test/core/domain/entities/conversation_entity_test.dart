import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/conversation_entity.dart';

/// Barrel re-export verification — ensures the public API surface
/// of [ConversationEntity] is accessible via the core barrel.
void main() {
  test('ConversationEntity is accessible via core barrel', () {
    // Compile-time verification: if this test compiles, the barrel works.
    expect(ConversationEntity, isNotNull);
  });
}
