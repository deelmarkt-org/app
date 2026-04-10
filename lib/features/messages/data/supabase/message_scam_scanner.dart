import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Invokes the R-35 scam-detection Edge Function for a sent message.
///
/// Fire-and-forget — the call is non-blocking. The Edge Function updates
/// the message's `scam_confidence`, `scam_reasons`, and `scam_flagged_at`
/// fields in-place via the `flag_message_scam` RPC. The Realtime
/// subscription on the `messages` table ([watchMessages]) picks up these
/// updates automatically and re-emits the message list.
///
/// Failures are logged via [AppLogger] but never propagated to the caller.
///
/// Reference: docs/epics/E06-trust-moderation.md §Scam Detection
class MessageScamScanner {
  const MessageScamScanner(this._client);

  final SupabaseClient _client;

  /// Scans [message] asynchronously. Returns immediately.
  void scan(MessageEntity message) {
    _client.functions
        .invoke(
          'scam-detection',
          body: {
            'message_id': message.id,
            'conversation_id': message.conversationId,
            'text': message.text,
          },
        )
        .then((_) {})
        .catchError((Object error, StackTrace stackTrace) {
          AppLogger.warning(
            'scam-detection invocation failed: $error',
            tag: 'MessageScamScanner',
          );
        });
  }
}
