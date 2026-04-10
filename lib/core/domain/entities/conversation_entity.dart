// Barrel re-export for cross-feature access (CLAUDE.md §11).
//
// Features that need [ConversationEntity] import this file instead of
// reaching into `features/messages/` directly.
export 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
