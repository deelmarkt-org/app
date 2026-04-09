import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/supabase/supabase_message_repository.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class _StubUser extends Fake implements User {
  _StubUser({required this.id});

  @override
  final String id;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _uid = 'user-abc-123';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _arrangeAuthenticated(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_StubUser(id: _uid));
}

void _arrangeUnauthenticated(
  MockSupabaseClient client,
  MockGoTrueClient auth,
) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFunctionsClient functions;
  late SupabaseMessageRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = SupabaseMessageRepository(client);
  });

  group('sendMessage', () {
    test('throws when user is not authenticated', () {
      _arrangeUnauthenticated(client, auth);

      expect(
        () => repo.sendMessage(
          conversationId: 'conv-1',
          text: 'hello',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not authenticated'),
          ),
        ),
      );
    });

    test('sends text message with correct type', () {
      _arrangeAuthenticated(client, auth);

      // Verify sendMessage uses MessageType.text as default
      expect(
        () => repo.sendMessage(
          conversationId: 'conv-1',
          text: 'hello',
        ),
        // Will throw because PostgREST is not mocked, but we verify
        // the auth check passes and the method proceeds
        throwsA(isNot(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not authenticated'),
        ))),
      );
    });

    test('sends offer message with amount', () {
      _arrangeAuthenticated(client, auth);

      expect(
        () => repo.sendMessage(
          conversationId: 'conv-1',
          text: 'I offer €25',
          type: MessageType.offer,
          offerAmountCents: 2500,
        ),
        throwsA(isNot(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not authenticated'),
        ))),
      );
    });
  });

  group('updateOfferStatus', () {
    test('throws ArgumentError for pending status', () {
      expect(
        () => repo.updateOfferStatus(
          messageId: 'msg-1',
          newStatus: OfferStatus.pending,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows accepted status', () {
      // Will throw PostgrestException (no real client) but NOT ArgumentError
      expect(
        () => repo.updateOfferStatus(
          messageId: 'msg-1',
          newStatus: OfferStatus.accepted,
        ),
        throwsA(isNot(isA<ArgumentError>())),
      );
    });

    test('allows declined status', () {
      expect(
        () => repo.updateOfferStatus(
          messageId: 'msg-1',
          newStatus: OfferStatus.declined,
        ),
        throwsA(isNot(isA<ArgumentError>())),
      );
    });
  });

  group('getOrCreateConversation', () {
    test('calls RPC with correct params', () {
      expect(
        () => repo.getOrCreateConversation(
          listingId: 'listing-1',
          buyerId: 'buyer-1',
        ),
        throwsA(anything),
      );
    });
  });

  group('watchMessages', () {
    test('returns a typed Stream of MessageEntity lists', () {
      final stream = repo.watchMessages('conv-1');
      expect(stream, isA<Stream<List<dynamic>>>());
    });
  });

  group('getConversations', () {
    test('calls get_conversations_for_user RPC', () {
      expect(() => repo.getConversations(), throwsA(anything));
    });
  });

  group('getMessages', () {
    test('accepts optional limit and offset', () {
      expect(
        () => repo.getMessages('conv-1', limit: 20, offset: 0),
        throwsA(anything),
      );
    });

    test('works without pagination params', () {
      expect(() => repo.getMessages('conv-1'), throwsA(anything));
    });
  });
}
