import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/conversation_list_notifier.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_theme_colors.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_empty_state.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_skeleton.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/conversation_list_tile.dart';

/// P-35 — Conversation list screen.
///
/// Reference: `docs/screens/06-chat/01-conversation-list.md`.
/// Parent responsive shell owns the [Scaffold] so this widget focuses on
/// body composition and state handling.
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({
    this.selectedConversationId,
    this.onConversationTap,
    super.key,
  });

  /// In expanded layout the selected row is highlighted.
  final String? selectedConversationId;

  /// When provided, called instead of navigating. Used by the responsive
  /// shell to swap the right pane without changing routes.
  final void Function(String conversationId)? onConversationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationListNotifierProvider);
    final colors = ChatThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(colors: colors),
        Expanded(
          child: async.when(
            loading: () => const ConversationListSkeleton(),
            error:
                (err, _) => _ErrorView(
                  onRetry:
                      () =>
                          ref
                              .read(conversationListNotifierProvider.notifier)
                              .refresh(),
                ),
            data: (conversations) => _buildDataBody(ref, conversations),
          ),
        ),
      ],
    );
  }

  Widget _buildDataBody(WidgetRef ref, List<ConversationEntity> conversations) {
    if (conversations.isEmpty) {
      return const ConversationListEmptyState();
    }
    // Single `now` per frame so all row timestamps render consistently.
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh:
          () => ref.read(conversationListNotifierProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s4,
          vertical: Spacing.s3,
        ),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.s3),
        itemBuilder: (context, index) {
          final c = conversations[index];
          return ConversationListTile(
            conversation: c,
            selected: c.id == selectedConversationId,
            now: now,
            // Sonar S6582 — null-aware invocation instead of explicit null check.
            onTap: () => onConversationTap?.call(c.id),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});

  final ChatThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s5,
        Spacing.s6,
        Spacing.s5,
        Spacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'messages.title'.tr(),
            style: theme.textTheme.displayLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            'messages.subtitle'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  // Raw exception message is intentionally NOT exposed here — renders a
  // localised title only. Future developers: do not add an `err.toString()`
  // text widget in this view; it can leak Supabase table names, RLS policy
  // identifiers, or stack fragments to end users (security finding F-04).
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: DeelmarktColors.error,
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'messages.errorTitle'.tr(),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s4),
            FilledButton(
              onPressed: onRetry,
              child: Text('messages.errorRetry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
