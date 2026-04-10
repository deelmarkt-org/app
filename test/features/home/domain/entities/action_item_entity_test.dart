import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';

void main() {
  group('ActionItemEntity', () {
    const shipEntity = ActionItemEntity(
      id: 'ship-abc',
      type: ActionItemType.shipOrder,
      referenceId: 'abc',
    );

    const replyEntity = ActionItemEntity(
      id: 'reply-conv-1',
      type: ActionItemType.replyMessage,
      referenceId: 'conv-1',
      otherUserName: 'Koper',
      unreadCount: 3,
    );

    test(
      'props includes id, type, referenceId, otherUserName, unreadCount',
      () {
        expect(shipEntity.props, [
          'ship-abc',
          ActionItemType.shipOrder,
          'abc',
          null,
          null,
        ]);
      },
    );

    test('props for replyMessage includes otherUserName and unreadCount', () {
      expect(replyEntity.props, [
        'reply-conv-1',
        ActionItemType.replyMessage,
        'conv-1',
        'Koper',
        3,
      ]);
    });

    test('equality with same values', () {
      const other = ActionItemEntity(
        id: 'ship-abc',
        type: ActionItemType.shipOrder,
        referenceId: 'abc',
      );
      expect(shipEntity, equals(other));
    });

    test('inequality with different id', () {
      const other = ActionItemEntity(
        id: 'ship-xyz',
        type: ActionItemType.shipOrder,
        referenceId: 'abc',
      );
      expect(shipEntity, isNot(equals(other)));
    });

    test('inequality with different type', () {
      const other = ActionItemEntity(
        id: 'ship-abc',
        type: ActionItemType.replyMessage,
        referenceId: 'abc',
      );
      expect(shipEntity, isNot(equals(other)));
    });

    test('shipOrder entity has null otherUserName and unreadCount', () {
      expect(shipEntity.otherUserName, isNull);
      expect(shipEntity.unreadCount, isNull);
    });

    test('replyMessage entity stores otherUserName and unreadCount', () {
      expect(replyEntity.otherUserName, 'Koper');
      expect(replyEntity.unreadCount, 3);
    });
  });

  group('ActionItemType', () {
    test('has expected values', () {
      expect(ActionItemType.values, contains(ActionItemType.shipOrder));
      expect(ActionItemType.values, contains(ActionItemType.replyMessage));
      expect(ActionItemType.values.length, 2);
    });
  });
}
