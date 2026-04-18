import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_tile_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTest(Widget child) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('ConversationListTileAvatar renders placeholder when no url', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTest(
        Builder(
          builder:
              (context) => ConversationListTileAvatar(
                url: null,
                isOnline: false,
                colors: ChatThemeColors.of(context),
              ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ConversationListTileAvatar), findsOneWidget);
  });

  testWidgets('ConversationListTileAvatar shows online indicator when online', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTest(
        Builder(
          builder:
              (context) => ConversationListTileAvatar(
                url: null,
                isOnline: true,
                colors: ChatThemeColors.of(context),
              ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ConversationListTileAvatar), findsOneWidget);
  });
}
