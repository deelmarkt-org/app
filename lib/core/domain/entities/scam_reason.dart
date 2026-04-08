// Re-export scam detection types from the canonical source.
//
// The canonical definitions live in
// `lib/features/messages/domain/entities/scam_detection.dart`.
// This barrel file exists so that `core/domain/entities/scam_reason.dart`
// imports used by the shared `ScamAlert` widget (lib/widgets/trust/) and
// the chat integration (P-37) resolve to the **same** Dart types as those
// used by `MessageEntity` and the data-layer DTOs.
export 'package:deelmarkt/features/messages/domain/entities/scam_detection.dart';
