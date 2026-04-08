import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Updates the lifecycle status of an offer message (seller-only).
///
/// Only [OfferStatus.accepted] and [OfferStatus.declined] are valid
/// transitions — the server RPC enforces this and also verifies that the
/// caller is the listing's seller. Re-calling on an already-resolved offer
/// is a no-op (idempotent).
class UpdateOfferStatusUseCase {
  const UpdateOfferStatusUseCase(this._repo);

  final MessageRepository _repo;

  Future<void> call({
    required String messageId,
    required OfferStatus newStatus,
  }) {
    if (messageId.trim().isEmpty) {
      throw ArgumentError.value(
        messageId,
        'messageId',
        'messageId must not be empty',
      );
    }
    if (newStatus != OfferStatus.accepted &&
        newStatus != OfferStatus.declined) {
      throw ArgumentError.value(
        newStatus,
        'newStatus',
        'Only accepted or declined are valid transitions',
      );
    }
    return _repo.updateOfferStatus(messageId: messageId, newStatus: newStatus);
  }
}
