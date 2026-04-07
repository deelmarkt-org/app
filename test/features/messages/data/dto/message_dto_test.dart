import 'package:deelmarkt/features/messages/data/dto/message_dto.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageDto.fromJson', () {
    final baseJson = {
      'id': 'msg-1',
      'conversation_id': 'conv-1',
      'sender_id': 'user-1',
      'text': 'Hoi!',
      'type': 'text',
      'is_read': false,
      'created_at': '2026-04-07T12:00:00.000Z',
      'scam_confidence': 'none',
      'scam_reasons': null,
      'scam_flagged_at': null,
    };

    test('parses a minimal text message', () {
      final entity = MessageDto.fromJson(baseJson);

      expect(entity.id, 'msg-1');
      expect(entity.conversationId, 'conv-1');
      expect(entity.senderId, 'user-1');
      expect(entity.text, 'Hoi!');
      expect(entity.type, MessageType.text);
      expect(entity.isRead, isFalse);
      expect(entity.scamConfidence, ScamConfidence.none);
      expect(entity.scamReasons, isNull);
      expect(entity.scamFlaggedAt, isNull);
    });

    test('parses an offer message with offerAmountCents', () {
      final json = {...baseJson, 'type': 'offer', 'offer_amount_cents': 4999};

      final entity = MessageDto.fromJson(json);

      expect(entity.type, MessageType.offer);
      expect(entity.offerAmountCents, 4999);
    });

    test('parses a flagged message with scam fields', () {
      final json = {
        ...baseJson,
        'scam_confidence': 'high',
        'scam_reasons': ['external_payment_link', 'urgency_pressure'],
        'scam_flagged_at': '2026-04-07T12:01:00.000Z',
      };

      final entity = MessageDto.fromJson(json);

      expect(entity.scamConfidence, ScamConfidence.high);
      expect(entity.scamReasons, [
        ScamReason.externalPaymentLink,
        ScamReason.urgencyPressure,
      ]);
      expect(entity.scamFlaggedAt, isNotNull);
    });

    test('unknown scam reason falls back to other', () {
      final json = {
        ...baseJson,
        'scam_confidence': 'low',
        'scam_reasons': ['totally_new_reason'],
        'scam_flagged_at': '2026-04-07T12:02:00.000Z',
      };

      final entity = MessageDto.fromJson(json);

      expect(entity.scamReasons, [ScamReason.other]);
    });

    test('throws FormatException on missing required fields', () {
      expect(
        () => MessageDto.fromJson({'id': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJsonList skips malformed entries', () {
      final list = [
        baseJson,
        {'bad': 'row'},
        {...baseJson, 'id': 'msg-2'},
      ];

      final result = MessageDto.fromJsonList(list);

      expect(result, hasLength(2));
      expect(result.map((e) => e.id).toList(), ['msg-1', 'msg-2']);
    });
  });

  group('MessageDto.toJson', () {
    test('serialises a text message without optional fields', () {
      final entity = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hoi!',
        createdAt: DateTime(2026, 4, 7, 12),
      );

      final json = MessageDto.toJson(entity);

      expect(json['conversation_id'], 'conv-1');
      expect(json['sender_id'], 'user-1');
      expect(json['text'], 'Hoi!');
      expect(json['type'], 'text');
      expect(json.containsKey('offer_amount_cents'), isFalse);
    });

    test('serialises an offer message including offerAmountCents', () {
      final entity = MessageEntity(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Bod: € 49,99',
        type: MessageType.offer,
        offerAmountCents: 4999,
        createdAt: DateTime(2026, 4, 7, 12),
      );

      final json = MessageDto.toJson(entity);

      expect(json['type'], 'offer');
      expect(json['offer_amount_cents'], 4999);
    });
  });

  group('MessageType.fromDb / toDb round-trip', () {
    for (final entry
        in {
          'text': MessageType.text,
          'offer': MessageType.offer,
          'system_alert': MessageType.systemAlert,
          'scam_warning': MessageType.scamWarning,
          'unknown_value': MessageType.text,
        }.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(MessageType.fromDb(entry.key), entry.value);
      });
    }

    test('toDb produces expected DB strings', () {
      expect(MessageType.text.toDb(), 'text');
      expect(MessageType.offer.toDb(), 'offer');
      expect(MessageType.systemAlert.toDb(), 'system_alert');
      expect(MessageType.scamWarning.toDb(), 'scam_warning');
    });
  });

  group('ScamReason.fromDb', () {
    test('maps all known DB values', () {
      expect(
        ScamReason.fromDb('external_payment_link'),
        ScamReason.externalPaymentLink,
      );
      expect(ScamReason.fromDb('off_site_contact'), ScamReason.offSiteContact);
      expect(
        ScamReason.fromDb('phone_number_request'),
        ScamReason.phoneNumberRequest,
      );
      expect(
        ScamReason.fromDb('suspicious_pricing'),
        ScamReason.suspiciousPricing,
      );
      expect(ScamReason.fromDb('urgency_pressure'), ScamReason.urgencyPressure);
      expect(ScamReason.fromDb('other'), ScamReason.other);
    });

    test('unknown value falls back to other', () {
      expect(ScamReason.fromDb('new_future_reason'), ScamReason.other);
    });
  });

  group('ScamConfidence.fromDb', () {
    test('maps known values', () {
      expect(ScamConfidence.fromDb('low'), ScamConfidence.low);
      expect(ScamConfidence.fromDb('high'), ScamConfidence.high);
      expect(ScamConfidence.fromDb('none'), ScamConfidence.none);
      expect(ScamConfidence.fromDb(null), ScamConfidence.none);
      expect(ScamConfidence.fromDb('unexpected'), ScamConfidence.none);
    });
  });
}
