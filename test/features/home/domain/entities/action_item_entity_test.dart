import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';

void main() {
  group('ActionItemEntity', () {
    const entity = ActionItemEntity(
      id: 'ship-abc',
      type: ActionItemType.shipOrder,
      title: 'Verzend bestelling #abc',
      subtitle: 'Bestelling betaald',
      referenceId: 'abc',
    );

    test('props includes all fields', () {
      expect(entity.props, [
        'ship-abc',
        ActionItemType.shipOrder,
        'Verzend bestelling #abc',
        'Bestelling betaald',
        'abc',
      ]);
    });

    test('equality with same values', () {
      const other = ActionItemEntity(
        id: 'ship-abc',
        type: ActionItemType.shipOrder,
        title: 'Verzend bestelling #abc',
        subtitle: 'Bestelling betaald',
        referenceId: 'abc',
      );
      expect(entity, equals(other));
    });

    test('inequality with different id', () {
      const other = ActionItemEntity(
        id: 'ship-xyz',
        type: ActionItemType.shipOrder,
        title: 'Verzend bestelling #abc',
        subtitle: 'Bestelling betaald',
        referenceId: 'abc',
      );
      expect(entity, isNot(equals(other)));
    });

    test('inequality with different type', () {
      const other = ActionItemEntity(
        id: 'ship-abc',
        type: ActionItemType.replyMessage,
        title: 'Verzend bestelling #abc',
        subtitle: 'Bestelling betaald',
        referenceId: 'abc',
      );
      expect(entity, isNot(equals(other)));
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
