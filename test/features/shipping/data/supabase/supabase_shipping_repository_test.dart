import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/shipping/data/supabase/supabase_shipping_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient client;
  late MockFunctionsClient functions;
  late SupabaseShippingRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = SupabaseShippingRepository(client);
  });

  group('SupabaseShippingRepository', () {
    test('can be instantiated', () {
      expect(repo, isA<SupabaseShippingRepository>());
    });

    group('getLabel', () {
      test('queries shipping_labels table', () async {
        expect(() => repo.getLabel('ship-001'), throwsA(anything));
      });
    });

    group('getTrackingEvents', () {
      test('queries tracking_events table', () async {
        expect(() => repo.getTrackingEvents('ship-001'), throwsA(anything));
      });
    });

    group('getParcelShops', () {
      test('invokes get-parcel-shops Edge Function', () async {
        when(
          () => functions.invoke('get-parcel-shops', body: any(named: 'body')),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: [
              {
                'id': 'ps-001',
                'name': 'PostNL Punt AH',
                'address': 'Straat 1',
                'postal_code': '1012RR',
                'city': 'Amsterdam',
                'latitude': 52.37,
                'longitude': 4.89,
                'distance_km': 0.3,
                'carrier': 'postnl',
              },
            ],
          ),
        );

        final shops = await repo.getParcelShops('1012RR');

        expect(shops, hasLength(1));
        expect(shops.first.name, 'PostNL Punt AH');
        expect(shops.first.postalCode, '1012RR');

        verify(
          () => functions.invoke(
            'get-parcel-shops',
            body: {'postal_code': '1012RR'},
          ),
        ).called(1);
      });

      test('returns empty list when response data is not a list', () async {
        when(
          () => functions.invoke('get-parcel-shops', body: any(named: 'body')),
        ).thenAnswer((_) async => FunctionResponse(status: 200));

        final shops = await repo.getParcelShops('0000XX');
        expect(shops, isEmpty);
      });
    });
  });
}
