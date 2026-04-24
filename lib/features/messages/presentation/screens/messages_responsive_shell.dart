import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// Delegates the compact/expanded split to [ResponsiveDetailScaffold] so the
/// 360-px master / `Breakpoints.medium` threshold stays aligned with the
/// design-system contract established in #192. On compact (<840) the shell
/// shows either the list OR the thread (push navigation); on expanded
/// (≥840) it shows the list as a fixed 360-px left pane with the thread
/// filling the rest.
///
/// The thread's back button only surfaces on compact — on expanded, the
/// master pane is always visible so navigating back is meaningless.
///
/// Reference: docs/screens/06-chat/01-conversation-list.md §Expanded
/// + docs/screens/06-chat/02-chat-thread.md §Responsive
class MessagesResponsiveShell extends ConsumerWidget {
  const MessagesResponsiveShell({this.conversationId, super.key});

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ChatThemeColors.of(context);
    final isExpanded = Breakpoints.isExpanded(context);
    final id = conversationId;

    final master = ConversationListScreen(
      selectedConversationId: id,
      onConversationTap:
          (tappedId) => context.go(AppRoutes.chatThreadFor(tappedId)),
    );

    final detail =
        id == null
            ? null
            : ChatThreadScreen(
              conversationId: id,
              showBackButton: !isExpanded,
              key: ValueKey(id),
            );

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        bottom: false,
        child: ResponsiveDetailScaffold(
          master: master,
          detail: detail,
          emptyDetail: const NoThreadSelected(),
        ),
      ),
    );
  }
}
