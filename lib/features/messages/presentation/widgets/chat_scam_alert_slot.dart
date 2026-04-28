import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_notifier.dart'
    show ChatThreadState;
import 'package:deelmarkt/widgets/trust/scam_alert.dart';

/// Riverpod provider tracking whether the scam alert has been dismissed.
///
/// Defined here (co-located with the sole consumer) per CLAUDE.md §3.2.
final scamAlertDismissedProvider = StateProvider<bool>((_) => false);

/// Renders the [ScamAlert] banner when the latest message in the thread
/// has been flagged, or an invisible [SizedBox.shrink] otherwise.
///
/// Declared as [ConsumerWidget] because it needs [scamAlertDismissedProvider]
/// for read + write (D2 exception — direct notifier write avoids a 4-param
/// callback chain back to the screen).
///
/// Reference: docs/screens/06-chat/03-scam-alert.md
class ChatScamAlertSlot extends ConsumerWidget {
  const ChatScamAlertSlot({required this.state, super.key});

  final ChatThreadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(scamAlertDismissedProvider);
    if (dismissed || state.messages.isEmpty) return const SizedBox.shrink();

    final latest = state.messages.last;
    if (latest.scamConfidence == ScamConfidence.none) {
      return const SizedBox.shrink();
    }

    return ScamAlert(
      confidence: latest.scamConfidence,
      reasons: latest.scamReasons ?? const [ScamReason.other],
      onReport:
          latest.scamConfidence == ScamConfidence.high
              ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('scam_alert.report_submitted'.tr())),
                );
              }
              : null,
      onDismiss:
          latest.scamConfidence == ScamConfidence.low
              ? () => ref.read(scamAlertDismissedProvider.notifier).state = true
              : null,
    );
  }
}
