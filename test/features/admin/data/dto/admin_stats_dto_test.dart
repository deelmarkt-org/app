import 'package:deelmarkt/features/admin/data/dto/admin_stats_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminStatsDto', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = <String, dynamic>{
          'open_disputes': 12,
          'dsa_notices_within_24h': 3,
          'active_listings': 156,
          'escrow_amount_cents': 1245000,
          'flagged_listings': 8,
          'reported_users': 4,
          'approved_count': 142,
        };

        final result = AdminStatsDto.fromJson(json);

        expect(result.openDisputes, 12);
        expect(result.dsaNoticesWithin24h, 3);
        expect(result.activeListings, 156);
        expect(result.escrowAmountCents, 1245000);
        expect(result.flaggedListings, 8);
        expect(result.reportedUsers, 4);
        expect(result.approvedCount, 142);
      });

      test('missing fields default to 0', () {
        final json = <String, dynamic>{
          'open_disputes': 5,
          'active_listings': 100,
        };

        final result = AdminStatsDto.fromJson(json);

        expect(result.openDisputes, 5);
        expect(result.dsaNoticesWithin24h, 0);
        expect(result.activeListings, 100);
        expect(result.escrowAmountCents, 0);
        expect(result.flaggedListings, 0);
        expect(result.reportedUsers, 0);
        expect(result.approvedCount, 0);
      });

      test('empty map returns all zeros', () {
        final result = AdminStatsDto.fromJson(<String, dynamic>{});

        expect(result.openDisputes, 0);
        expect(result.dsaNoticesWithin24h, 0);
        expect(result.activeListings, 0);
        expect(result.escrowAmountCents, 0);
        expect(result.flaggedListings, 0);
        expect(result.reportedUsers, 0);
        expect(result.approvedCount, 0);
      });

      test('numeric values as doubles are converted to int', () {
        final json = <String, dynamic>{
          'open_disputes': 12.0,
          'dsa_notices_within_24h': 3.5,
          'active_listings': 156.9,
          'escrow_amount_cents': 1245000.0,
          'flagged_listings': 8.1,
          'reported_users': 4.7,
          'approved_count': 142.0,
        };

        final result = AdminStatsDto.fromJson(json);

        expect(result.openDisputes, 12);
        expect(result.dsaNoticesWithin24h, 3);
        expect(result.activeListings, 156);
        expect(result.escrowAmountCents, 1245000);
        expect(result.flaggedListings, 8);
        expect(result.reportedUsers, 4);
        expect(result.approvedCount, 142);
      });
    });
  });
}
