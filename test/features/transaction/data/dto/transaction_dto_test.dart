import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/transaction/data/dto/transaction_dto.dart';

void main() {
  group('TransactionDto', () {
    group('fromJson', () {
      test('parses a complete JSON row', () {
        final json = _validJson();
        final entity = TransactionDto.fromJson(json);

        expect(entity.id, 'txn-001');
        expect(entity.listingId, 'listing-001');
        expect(entity.buyerId, 'buyer-001');
        expect(entity.sellerId, 'seller-001');
        expect(entity.status, TransactionStatus.paid);
        expect(entity.itemAmountCents, 5000);
        expect(entity.platformFeeCents, 125);
        expect(entity.shippingCostCents, 495);
        expect(entity.currency, 'EUR');
        expect(entity.molliePaymentId, 'tr_mock123');
        expect(entity.paidAt, isNotNull);
      });

      test('parses payment_pending status correctly', () {
        final json = _validJson(status: 'payment_pending');
        final entity = TransactionDto.fromJson(json);
        expect(entity.status, TransactionStatus.paymentPending);
      });

      test('defaults unknown status to created', () {
        final json = _validJson(status: 'unknown_future_status');
        final entity = TransactionDto.fromJson(json);
        expect(entity.status, TransactionStatus.created);
      });

      test('handles null optional dates', () {
        final json =
            _validJson()
              ..remove('paid_at')
              ..remove('mollie_payment_id');
        final entity = TransactionDto.fromJson(json);

        expect(entity.paidAt, isNull);
        expect(entity.molliePaymentId, isNull);
        expect(entity.shippedAt, isNull);
        expect(entity.deliveredAt, isNull);
        expect(entity.escrowDeadline, isNull);
      });

      test('throws FormatException on missing required fields', () {
        final json = _validJson()..remove('id');
        expect(
          () => TransactionDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException on wrong type for amount', () {
        final json = _validJson();
        json['item_amount_cents'] = '5000'; // String instead of int
        expect(
          () => TransactionDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('fromJsonList', () {
      test('parses a list of rows', () {
        final list = [_validJson(), _validJson(id: 'txn-002')];
        final entities = TransactionDto.fromJsonList(list);
        expect(entities, hasLength(2));
        expect(entities[1].id, 'txn-002');
      });

      test('skips non-map entries', () {
        final list = [_validJson(), 'garbage', null, 42];
        final entities = TransactionDto.fromJsonList(list);
        expect(entities, hasLength(1));
      });
    });

    group('toInsertJson', () {
      test('calculates platform fee at 2.5%', () {
        final json = TransactionDto.toInsertJson(
          listingId: 'listing-001',
          buyerId: 'buyer-001',
          sellerId: 'seller-001',
          itemAmountCents: 10000,
          shippingCostCents: 495,
        );

        expect(json['platform_fee_cents'], 250); // 2.5% of 10000
        expect(json['currency'], 'EUR');
      });

      test('rounds platform fee up', () {
        // 2.5% of 999 = 24.975 → ceil → 25
        final json = TransactionDto.toInsertJson(
          listingId: 'l',
          buyerId: 'b',
          sellerId: 's',
          itemAmountCents: 999,
          shippingCostCents: 0,
        );
        expect(json['platform_fee_cents'], 25);
      });
    });
  });
}

Map<String, dynamic> _validJson({
  String id = 'txn-001',
  String status = 'paid',
}) {
  return {
    'id': id,
    'listing_id': 'listing-001',
    'buyer_id': 'buyer-001',
    'seller_id': 'seller-001',
    'status': status,
    'item_amount_cents': 5000,
    'platform_fee_cents': 125,
    'shipping_cost_cents': 495,
    'currency': 'EUR',
    'mollie_payment_id': 'tr_mock123',
    'created_at': '2026-04-01T10:00:00Z',
    'paid_at': '2026-04-01T10:05:00Z',
  };
}
