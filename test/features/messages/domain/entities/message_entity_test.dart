import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_reason.dart';

void main() {
  final now = DateTime(2026, 3, 25, 14);

  group('MessageEntity', () {
    test('creates with required fields', () {
      final msg = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );

      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.senderId, 'user-1');
      expect(msg.text, 'Hello');
      expect(msg.type, MessageType.text);
      expect(msg.isRead, false);
      expect(msg.createdAt, now);
    });

    test('equality based on all props', () {
      final a = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );
      final b = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );
      final c = MessageEntity(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('different type makes unequal', () {
      final a = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'offer',
        type: MessageType.offer,
        createdAt: now,
      );
      final b = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'offer',
        createdAt: now,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('MessageType', () {
    test('has all expected values', () {
      expect(
        MessageType.values,
        containsAll([
          MessageType.text,
          MessageType.offer,
          MessageType.systemAlert,
          MessageType.scamWarning,
        ]),
      );
    });
  });

  group('MessageEntity scam metadata', () {
    test('defaults scamConfidence to none and reasons to null', () {
      final msg = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );

      expect(msg.scamConfidence, ScamConfidence.none);
      expect(msg.scamReasons, isNull);
      expect(msg.scamFlaggedAt, isNull);
    });

    test('retains provided scam metadata', () {
      final flaggedAt = DateTime(2026, 4, 1, 10);
      final msg = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Click bit.ly/pay-now',
        createdAt: now,
        scamConfidence: ScamConfidence.high,
        scamReasons: const [
          ScamReason.externalPaymentLink,
          ScamReason.urgencyPressure,
        ],
        scamFlaggedAt: flaggedAt,
      );

      expect(msg.scamConfidence, ScamConfidence.high);
      expect(msg.scamReasons, hasLength(2));
      expect(msg.scamReasons!.first, ScamReason.externalPaymentLink);
      expect(msg.scamFlaggedAt, flaggedAt);
    });

    test('copyWith preserves unchanged scam metadata', () {
      final original = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'x',
        createdAt: now,
        scamConfidence: ScamConfidence.low,
        scamReasons: const [ScamReason.phoneNumberRequest],
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.scamConfidence, ScamConfidence.low);
      expect(updated.scamReasons, const [ScamReason.phoneNumberRequest]);
      expect(updated.isRead, true);
    });

    test('copyWith overrides scam fields when provided', () {
      final original = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'x',
        createdAt: now,
      );

      final flagged = original.copyWith(
        scamConfidence: ScamConfidence.high,
        scamReasons: const [ScamReason.suspiciousPricing],
        scamFlaggedAt: DateTime(2026, 4, 5),
      );

      expect(flagged.scamConfidence, ScamConfidence.high);
      expect(flagged.scamReasons, const [ScamReason.suspiciousPricing]);
      expect(flagged.scamFlaggedAt, DateTime(2026, 4, 5));
    });

    test('equality distinguishes on scamConfidence', () {
      final base = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'x',
        createdAt: now,
      );
      final flagged = base.copyWith(scamConfidence: ScamConfidence.high);

      expect(base, isNot(equals(flagged)));
    });
  });

  group('ScamReason', () {
    test('has all expected values', () {
      expect(ScamReason.values, hasLength(6));
      expect(
        ScamReason.values,
        containsAll([
          ScamReason.externalPaymentLink,
          ScamReason.offSiteContact,
          ScamReason.phoneNumberRequest,
          ScamReason.suspiciousPricing,
          ScamReason.urgencyPressure,
          ScamReason.other,
        ]),
      );
    });

    test(
      'each value has a unique localizationKey under scam_alert.reason.*',
      () {
        final keys = ScamReason.values.map((r) => r.localizationKey).toSet();

        expect(keys, hasLength(ScamReason.values.length));
        for (final key in keys) {
          expect(key, startsWith('scam_alert.reason.'));
        }
      },
    );

    test('ScamConfidence has exactly none/low/high', () {
      expect(ScamConfidence.values, hasLength(3));
      expect(
        ScamConfidence.values,
        containsAll([
          ScamConfidence.none,
          ScamConfidence.low,
          ScamConfidence.high,
        ]),
      );
    });
  });
}
