import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/data/dto/transaction_dto.dart';
import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';
import 'package:deelmarkt/features/transaction/domain/repositories/transaction_repository.dart';

/// Supabase implementation of [TransactionRepository].
///
/// Queries the `transactions` table. Status updates are restricted
/// to `service_role` in RLS, so `updateStatus`, `setMolliePaymentId`,
/// and `setEscrowDeadline` require the client to have service-role
/// permissions (Edge Functions call these, not the Flutter app directly).
///
/// Reference: migration 20260321232641_create_transactions_and_ledger.sql
class SupabaseTransactionRepository implements TransactionRepository {
  const SupabaseTransactionRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'transactions';

  @override
  Future<TransactionEntity> createTransaction({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required int itemAmountCents,
    required int shippingCostCents,
  }) async {
    try {
      final response =
          await _client
              .from(_table)
              .insert(
                TransactionDto.toInsertJson(
                  listingId: listingId,
                  buyerId: buyerId,
                  sellerId: sellerId,
                  itemAmountCents: itemAmountCents,
                  shippingCostCents: shippingCostCents,
                ),
              )
              .select()
              .single();

      return TransactionDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create transaction: ${e.message}');
    }
  }

  @override
  Future<TransactionEntity?> getTransaction(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return TransactionDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch transaction $id: ${e.message}');
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactionsForUser(String userId) async {
    try {
      // RLS already filters to buyer/seller — but we query both sides
      // to get all transactions for this user.
      final response = await _client
          .from(_table)
          .select()
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('created_at', ascending: false);

      return TransactionDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch transactions for user: ${e.message}');
    }
  }

  @override
  Future<TransactionEntity> updateStatus({
    required String transactionId,
    required TransactionStatus newStatus,
  }) async {
    try {
      final response =
          await _client
              .from(_table)
              .update({'status': newStatus.toDb()})
              .eq('id', transactionId)
              .select()
              .single();

      return TransactionDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update transaction status: ${e.message}');
    }
  }

  @override
  Future<TransactionEntity> setMolliePaymentId({
    required String transactionId,
    required String molliePaymentId,
  }) async {
    try {
      final response =
          await _client
              .from(_table)
              .update({'mollie_payment_id': molliePaymentId})
              .eq('id', transactionId)
              .select()
              .single();

      return TransactionDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to set Mollie payment ID: ${e.message}');
    }
  }

  @override
  Future<TransactionEntity> setEscrowDeadline({
    required String transactionId,
    required DateTime deadline,
  }) async {
    try {
      final response =
          await _client
              .from(_table)
              .update({'escrow_deadline': deadline.toUtc().toIso8601String()})
              .eq('id', transactionId)
              .select()
              .single();

      return TransactionDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to set escrow deadline: ${e.message}');
    }
  }
}
