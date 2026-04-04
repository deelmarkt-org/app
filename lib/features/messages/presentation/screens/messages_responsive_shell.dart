import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/messages/presentation/screens/chat_thread_screen.dart';
import 'package:deelmarkt/features/messages/presentation/screens/conversation_list_screen.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/no_thread_selected.dart';

/// Single entry point for `/messages` and `/messages/:conversationId`.
///
/// Uses a [LayoutBuilder] to switch between compact (push navigation)
/// and expanded (master-detail) layouts at [Breakpoints.medium].
///
/// In compact mode: either the list OR the thread is visible (push nav).
/// In expanded mode: list is a fixed 360-px left pane, thread fills the rest.
class MessagesResponsiveShell extends ConsumerWidget {
  const MessagesResponsiveShell({this.conversationId, super.key});

  final String? conversationId;

  static const double _listPaneWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ChatThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isExpanded = constraints.maxWidth >= Breakpoints.medium;
            if (isExpanded) {
              return _ExpandedLayout(
                conversationId: conversationId,
                listPaneWidth: _listPaneWidth,
              );
            }
            return _CompactLayout(conversationId: conversationId);
          },
        ),
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    if (conversationId == null) {
      return ConversationListScreen(
        onConversationTap: (id) => context.go(AppRoutes.chatThreadFor(id)),
      );
    }
    return ChatThreadScreen(
      conversationId: conversationId!,
      key: ValueKey(conversationId),
    );
  }
}

class _ExpandedLayout extends StatelessWidget {
  const _ExpandedLayout({
    required this.conversationId,
    required this.listPaneWidth,
  });

  final String? conversationId;
  final double listPaneWidth;

  @override
  Widget build(BuildContext context) {
    final colors = ChatThemeColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listPaneWidth,
          child: ConversationListScreen(
            selectedConversationId: conversationId,
            onConversationTap: (id) => context.go(AppRoutes.chatThreadFor(id)),
          ),
        ),
        Container(width: 1, color: colors.border),
        Expanded(
          child:
              conversationId == null
                  ? const NoThreadSelected()
                  : ChatThreadScreen(
                    conversationId: conversationId!,
                    showBackButton: false,
                    key: ValueKey(conversationId),
                  ),
        ),
      ],
    );
  }
}
