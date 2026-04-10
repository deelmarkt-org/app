import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/action_required_section.dart';

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

Widget buildSection({
  List<ActionItemEntity> actions = const [],
  ValueChanged<ActionItemEntity>? onActionTap,
}) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: Scaffold(
      body: ActionRequiredSection(
        actions: actions,
        onActionTap: onActionTap ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('ActionRequiredSection', () {
    testWidgets('renders nothing when actions list is empty', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('renders one tile for a single ship action', (tester) async {
      await tester.pumpWidget(buildSection(actions: const [_shipAction]));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders one tile for a reply action', (tester) async {
      await tester.pumpWidget(buildSection(actions: const [_replyAction]));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders multiple tiles for multiple actions', (tester) async {
      await tester.pumpWidget(
        buildSection(actions: const [_shipAction, _replyAction]),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('calls onActionTap with correct action when tapped', (
      tester,
    ) async {
      ActionItemEntity? tappedAction;
      await tester.pumpWidget(
        buildSection(
          actions: const [_shipAction],
          onActionTap: (a) => tappedAction = a,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(tappedAction, equals(_shipAction));
    });

    testWidgets('renders dark mode without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: Scaffold(
            body: ActionRequiredSection(
              actions: const [_shipAction],
              onActionTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
