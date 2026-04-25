import 'package:deelmarkt/core/services/performance/trace_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TraceAttributes.allowlist', () {
    test('contains the documented safe keys', () {
      expect(TraceAttributes.allowlist, contains('locale'));
      expect(TraceAttributes.allowlist, contains('platform'));
      expect(TraceAttributes.allowlist, contains('cache_hit'));
      expect(TraceAttributes.allowlist, contains('result_count'));
      expect(TraceAttributes.allowlist, contains('payment_method'));
      expect(TraceAttributes.allowlist, contains('listing_category'));
      expect(TraceAttributes.allowlist, contains('listing_price_bucket'));
    });

    test('does not contain forbidden PII keys', () {
      expect(TraceAttributes.allowlist, isNot(contains('user_id')));
      expect(TraceAttributes.allowlist, isNot(contains('email')));
      expect(TraceAttributes.allowlist, isNot(contains('listing_id')));
      expect(TraceAttributes.allowlist, isNot(contains('search_term')));
      expect(TraceAttributes.allowlist, isNot(contains('coordinates')));
      expect(TraceAttributes.allowlist, isNot(contains('device_id')));
      expect(TraceAttributes.allowlist, isNot(contains('ip')));
    });
  });

  group('TraceAttributes.validateKey', () {
    test('returns true for allowlisted keys', () {
      expect(TraceAttributes.validateKey('locale'), isTrue);
      expect(TraceAttributes.validateKey('platform'), isTrue);
      expect(TraceAttributes.validateKey('listing_category'), isTrue);
    });

    test('throws ArgumentError in debug for forbidden keys', () {
      // kDebugMode is true under `flutter test`.
      expect(
        () => TraceAttributes.validateKey('user_id'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TraceAttributes.validateKey('email'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TraceAttributes.validateKey('listing_id'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TraceAttributes.validateKey('search_term'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TraceAttributes.bucketResultCount', () {
    test('zero result', () {
      expect(TraceAttributes.bucketResultCount(0), '0');
      expect(TraceAttributes.bucketResultCount(-5), '0');
    });

    test('small bucket (1-10)', () {
      expect(TraceAttributes.bucketResultCount(1), '1-10');
      expect(TraceAttributes.bucketResultCount(10), '1-10');
    });

    test('medium bucket (11-50)', () {
      expect(TraceAttributes.bucketResultCount(11), '11-50');
      expect(TraceAttributes.bucketResultCount(50), '11-50');
    });

    test('large bucket (50+)', () {
      expect(TraceAttributes.bucketResultCount(51), '50+');
      expect(TraceAttributes.bucketResultCount(99999), '50+');
    });
  });

  group('TraceAttributes.bucketImageSize', () {
    test('small (<200kb)', () {
      expect(TraceAttributes.bucketImageSize(1024), '<200kb');
      expect(TraceAttributes.bucketImageSize(199 * 1024), '<200kb');
    });

    test('medium (200kb-1mb)', () {
      expect(TraceAttributes.bucketImageSize(200 * 1024), '200kb-1mb');
      expect(TraceAttributes.bucketImageSize(1024 * 1024 - 1), '200kb-1mb');
    });

    test('large (>1mb)', () {
      expect(TraceAttributes.bucketImageSize(1024 * 1024), '>1mb');
      expect(TraceAttributes.bucketImageSize(50 * 1024 * 1024), '>1mb');
    });
  });

  group('TraceAttributes.bucketPriceCents', () {
    test('cheap (0-50 EUR)', () {
      expect(TraceAttributes.bucketPriceCents(0), '0-50');
      expect(TraceAttributes.bucketPriceCents(4999), '0-50');
    });

    test('mid-low (50-200 EUR)', () {
      expect(TraceAttributes.bucketPriceCents(5000), '50-200');
      expect(TraceAttributes.bucketPriceCents(19999), '50-200');
    });

    test('mid-high (200-1000 EUR)', () {
      expect(TraceAttributes.bucketPriceCents(20000), '200-1000');
      expect(TraceAttributes.bucketPriceCents(99999), '200-1000');
    });

    test('premium (1000+ EUR)', () {
      expect(TraceAttributes.bucketPriceCents(100000), '1000+');
      expect(TraceAttributes.bucketPriceCents(50000000), '1000+');
    });
  });
}
