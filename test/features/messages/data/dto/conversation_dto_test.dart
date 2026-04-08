import 'package:deelmarkt/features/messages/data/dto/conversation_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationDto.fromJson', () {
    final baseJson = {
      'id': 'conv-1',
      'listing_id': 'listing-1',
      'listing_title': 'iPhone 15 Pro',
      'listing_image_url': 'https://example.com/img.jpg',
      'other_user_id': 'user-2',
      'other_user_name': 'Maria',
      'other_user_avatar_url': null,
      'last_message_text': 'Hoi!',
      'last_message_at': '2026-04-07T12:00:00.000Z',
      'unread_count': 2,
    };

    test('parses all fields correctly', () {
      final entity = ConversationDto.fromJson(baseJson);

      expect(entity.id, 'conv-1');
      expect(entity.listingId, 'listing-1');
      expect(entity.listingTitle, 'iPhone 15 Pro');
      expect(entity.listingImageUrl, 'https://example.com/img.jpg');
      expect(entity.otherUserId, 'user-2');
      expect(entity.otherUserName, 'Maria');
      expect(entity.otherUserAvatarUrl, isNull);
      expect(entity.lastMessageText, 'Hoi!');
      expect(entity.unreadCount, 2);
    });

    test('defaults unread_count to 0 when missing', () {
      final json = {...baseJson}..remove('unread_count');
      final entity = ConversationDto.fromJson(json);
      expect(entity.unreadCount, 0);
    });

    test('defaults lastMessageText to empty string when null', () {
      final json = {...baseJson, 'last_message_text': null};
      final entity = ConversationDto.fromJson(json);
      expect(entity.lastMessageText, '');
    });

    test('throws FormatException on missing required fields', () {
      expect(
        () => ConversationDto.fromJson({'id': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses seller_response_time_minutes when present', () {
      final json = {...baseJson, 'seller_response_time_minutes': 120};
      final entity = ConversationDto.fromJson(json);
      expect(entity.sellerResponseTimeMinutes, 120);
    });

    test('parses seller_response_time_minutes as null when missing', () {
      final entity = ConversationDto.fromJson(baseJson);
      expect(entity.sellerResponseTimeMinutes, isNull);
    });

    test('casts seller_response_time_minutes from num to int', () {
      final json = {...baseJson, 'seller_response_time_minutes': 45.0};
      final entity = ConversationDto.fromJson(json);
      expect(entity.sellerResponseTimeMinutes, 45);
    });

    test('fromJsonList skips malformed entries', () {
      final list = [
        baseJson,
        {'bad': 'row'},
        {...baseJson, 'id': 'conv-2'},
      ];

      final result = ConversationDto.fromJsonList(list);

      expect(result, hasLength(2));
      expect(result.map((e) => e.id).toList(), ['conv-1', 'conv-2']);
    });
  });
}
