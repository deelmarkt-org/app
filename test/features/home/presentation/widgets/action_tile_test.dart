import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/action_tile.dart';

const _shipAction = ActionItemEntity(
  id: 'ship-tx-1234',
  type: ActionItemType.shipOrder,
  referenceId: 'tx-1234',
);

const _replyAction = ActionItemEntity(
  id: 'reply-conv-1',
  type: ActionItemType.replyMessage,
  referenceId: 'conv-1',
  otherUserName: 'Koper',
  unreadCount: 2,
);

Widget buildTile({
  required ActionItemEntity action,
  VoidCallback? onTap,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? DeelmarktTheme.light,
    home: Scaffold(body: ActionTile(action: action, onTap: onTap ?? () {})),
  );
}

void main() {
  group('ActionTile', () {
    testWidgets('renders InkWell for ship action', (tester) async {
      await tester.pumpWidget(buildTile(action: _shipAction));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders InkWell for reply action', (tester) async {
      await tester.pumpWidget(buildTile(action: _replyAction));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTile(action: _shipAction, onTap: () => tapped = true),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(
        buildTile(action: _replyAction, theme: DeelmarktTheme.dark),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('ship tile contains ClipRRect accent border', (tester) async {
      await tester.pumpWidget(buildTile(action: _shipAction));
      await tester.pump();

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('reply tile has no ClipRRect accent border', (tester) async {
      await tester.pumpWidget(buildTile(action: _replyAction));
      await tester.pump();

      expect(find.byType(ClipRRect), findsNothing);
    });
  });
}
