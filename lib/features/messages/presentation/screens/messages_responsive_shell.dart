import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:deelmarkt/features/messages/presentation/screens/conversation_list_screen.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/no_thread_selected.dart';
import 'package:deelmarkt/widgets/layout/responsive_detail_scaffold.dart';

/// Single entry point for `/messages` and `/messages/:conversationId`.
///
/// Composes the conversation list + chat thread via the shared
/// [ResponsiveDetailScaffold] primitive (#192 foundation):
/// - Below [Breakpoints.medium] (<840px): either the list OR the thread is
///   visible based on `conversationId` — selecting a conversation pushes
///   `/messages/:id` so back navigation returns to the list (unchanged
///   mobile drill-down UX).
/// - At or above [Breakpoints.medium] (≥840px): list pinned as a 360-px
///   master pane, thread fills the detail pane — selecting a conversation
///   updates only the detail without replacing the list.
///
/// Default scaffold params (`masterWidth = 360`, `breakpoint = medium`)
/// match this screen's previous hand-rolled layout, so the migration is
/// behaviour-preserving. Divider color uses the chat theme's `border`
/// token to keep parity with the rest of the messages surface (generic
/// `dividerTheme.color` would be a ~3% luminance shift in dark mode).
///
/// Reference: docs/screens/06-chat/01-conversation-list.md,
/// docs/screens/06-chat/02-chat-thread.md.
class MessagesResponsiveShell extends StatelessWidget {
  const MessagesResponsiveShell({this.conversationId, super.key});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    final colors = ChatThemeColors.of(context);
    final isExpanded = Breakpoints.isExpanded(context);

    final master = ConversationListScreen(
      selectedConversationId: isExpanded ? conversationId : null,
      onConversationTap: (id) => context.go(AppRoutes.chatThreadFor(id)),
    );

    // On compact we're on the thread route with its own back button;
    // on expanded the thread sits next to the list and back would be
    // incongruent with the master-detail pattern.
    final detail =
        conversationId == null
            ? null
            : ChatThreadScreen(
              conversationId: conversationId!,
              showBackButton: !isExpanded,
              key: ValueKey(conversationId),
            );

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        bottom: false,
        child: ResponsiveDetailScaffold(
          master: master,
          detail: detail,
          emptyDetail: const NoThreadSelected(),
          dividerColor: colors.border,
        ),
      ),
    );
  }
}
