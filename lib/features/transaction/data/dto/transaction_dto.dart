import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';

/// DTO for converting Supabase REST JSON to [TransactionEntity].
///
/// Column mapping follows migration `20260321232641_create_transactions_and_ledger.sql`.
class TransactionDto {
  const TransactionDto._();

  static TransactionEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final listingId = json['listing_id'];
    final buyerId = json['buyer_id'];
    final sellerId = json['seller_id'];
    final statusRaw = json['status'];
    final itemAmountCents = json['item_amount_cents'];
    final platformFeeCents = json['platform_fee_cents'];
    final shippingCostCents = json['shipping_cost_cents'];
    final createdAtRaw = json['created_at'];

    if (id is! String ||
        listingId is! String ||
        buyerId is! String ||
        sellerId is! String ||
        statusRaw is! String ||
        itemAmountCents is! int ||
        platformFeeCents is! int ||
        shippingCostCents is! int ||
        createdAtRaw is! String) {
      throw const FormatException(
        'TransactionDto.fromJson: missing or invalid required fields',
      );
    }

    return TransactionEntity(
      id: id,
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      status: TransactionStatus.fromDb(statusRaw),
      itemAmountCents: itemAmountCents,
      platformFeeCents: platformFeeCents,
      shippingCostCents: shippingCostCents,
      currency: (json['currency'] as String?) ?? 'EUR',
      molliePaymentId: json['mollie_payment_id'] as String?,
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      paidAt: _parseOptionalDate(json['paid_at']),
      shippedAt: _parseOptionalDate(json['shipped_at']),
      deliveredAt: _parseOptionalDate(json['delivered_at']),
      confirmedAt: _parseOptionalDate(json['confirmed_at']),
      releasedAt: _parseOptionalDate(json['released_at']),
      disputedAt: _parseOptionalDate(json['disputed_at']),
      escrowDeadline: _parseOptionalDate(json['escrow_deadline']),
    );
  }

  /// Build INSERT JSON. `platform_fee_cents` is omitted — it is computed
  /// server-side by the `trg_calculate_platform_fee` trigger (2.5% of
  /// item_amount_cents, ceil-rounded). See migration
  /// `20260414180000_b55_server_side_platform_fee.sql`.
  static Map<String, dynamic> toInsertJson({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  }) {
    return {
      'listing_id': listingId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'item_amount_cents': itemAmountCents,
      'shipping_cost_cents': shippingCostCents,
      'currency': 'EUR',
    };
  }

  static List<TransactionEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
