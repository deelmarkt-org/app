import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/supabase/message_scam_scanner.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MessageEntity _msg() => MessageEntity(
  id: 'msg_001',
  conversationId: 'conv_001',
  senderId: 'usr_buyer',
  text: 'test message',
  createdAt: DateTime(2026, 3, 19, 10),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late MessageScamScanner scanner;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.functions).thenReturn(mockFunctions);
    scanner = MessageScamScanner(mockClient);
  });

  group('MessageScamScanner', () {
    test(
      'scan() invokes scam-detection function with correct payload',
      () async {
        when(
          () =>
              mockFunctions.invoke('scam-detection', body: any(named: 'body')),
        ).thenAnswer((_) async => FunctionResponse(status: 200));

        scanner.scan(_msg());

        // Allow the async fire-and-forget to complete.
        await Future<void>.delayed(Duration.zero);

        verify(
          () => mockFunctions.invoke(
            'scam-detection',
            body: {
              'message_id': 'msg_001',
              'conversation_id': 'conv_001',
              'text': 'test message',
            },
          ),
        ).called(1);
      },
    );

    test('scan() does not throw when Edge Function fails', () async {
      when(
        () => mockFunctions.invoke('scam-detection', body: any(named: 'body')),
      ).thenAnswer((_) async => throw Exception('network error'));

      // scan() is fire-and-forget — must not propagate errors to caller.
      expect(() => scanner.scan(_msg()), returnsNormally);
      await Future<void>.delayed(Duration.zero);
    });
  });
}
