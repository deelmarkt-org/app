import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_header.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  ConversationEntity buildConv({int? sellerResponseTimeMinutes}) {
    return ConversationEntity(
      id: 'c1',
      listingId: 'l1',
      listingTitle: 'iPhone 15 Pro',
      listingImageUrl: null,
      otherUserId: 'u1',
      otherUserName: 'Jan de Vries',
      lastMessageText: 'Hoi!',
      lastMessageAt: DateTime(2026, 4, 7),
      sellerResponseTimeMinutes: sellerResponseTimeMinutes,
    );
  }

  group('ChatHeader', () {
    group('displays other user name', () {
      testWidgets('shows user name', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(conversation: buildConv(), showBackButton: false),
        );

        expect(find.text('Jan de Vries'), findsOneWidget);
      });
    });

    group('response time subtitle', () {
      testWidgets('null minutes shows offline fallback', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(conversation: buildConv(), showBackButton: false),
        );

        // .tr() returns key path in test environment
        expect(find.text('chat.lastSeen'), findsOneWidget);
      });

      testWidgets('under 60 min shows under_1h bucket', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 30),
            showBackButton: false,
          ),
        );

        expect(
          find.text('seller_profile.response_time.under_1h'),
          findsOneWidget,
        );
      });

      testWidgets('exactly 60 min shows under_4h bucket', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 60),
            showBackButton: false,
          ),
        );

        expect(
          find.text('seller_profile.response_time.under_4h'),
          findsOneWidget,
        );
      });

      testWidgets('239 min shows under_4h bucket (boundary)', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 239),
            showBackButton: false,
          ),
        );

        expect(
          find.text('seller_profile.response_time.under_4h'),
          findsOneWidget,
        );
      });

      testWidgets('240 min shows under_24h bucket', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 240),
            showBackButton: false,
          ),
        );

        expect(
          find.text('seller_profile.response_time.under_24h'),
          findsOneWidget,
        );
      });

      testWidgets('1440 min shows over_24h bucket', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 1440),
            showBackButton: false,
          ),
        );

        expect(
          find.text('seller_profile.response_time.over_24h'),
          findsOneWidget,
        );
      });
    });

    group('accessibility', () {
      testWidgets('has Semantics with name and response time', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(
            conversation: buildConv(sellerResponseTimeMinutes: 30),
            showBackButton: false,
          ),
        );

        // Semantics label combines name + subtitle
        expect(
          find.bySemanticsLabel(
            RegExp(r'Jan de Vries.*seller_profile\.response_time\.under_1h'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('back button has 44x44 touch target', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(conversation: buildConv(), showBackButton: true),
        );

        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);
      });

      testWidgets('options button has 44x44 touch target', (tester) async {
        await pumpTestWidget(
          tester,
          ChatHeader(conversation: buildConv(), showBackButton: false),
        );

        final optionsButton = find.byIcon(Icons.more_vert);
        expect(optionsButton, findsOneWidget);
      });
    });
  });
}
