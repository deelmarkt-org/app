import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/usecases/save_address_usecase.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SaveAddressUseCase useCase;
  late MockSettingsRepository mockRepo;

  const testAddress = DutchAddress(
    postcode: '1012 AB',
    houseNumber: '42',
    street: 'Damstraat',
    city: 'Amsterdam',
  );

  setUp(() {
    mockRepo = MockSettingsRepository();
    useCase = SaveAddressUseCase(repository: mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(testAddress);
  });

  group('SaveAddressUseCase', () {
    test('delegates to repository.saveAddress', () async {
      when(
        () => mockRepo.saveAddress(any()),
      ).thenAnswer((_) async => testAddress);

      final result = await useCase.call(testAddress);

      expect(result, testAddress);
      verify(() => mockRepo.saveAddress(testAddress)).called(1);
    });

    test('saves address with addition', () async {
      const addressWithAddition = DutchAddress(
        postcode: '3011 HE',
        houseNumber: '15',
        addition: 'B',
        street: 'Coolsingel',
        city: 'Rotterdam',
      );

      when(
        () => mockRepo.saveAddress(any()),
      ).thenAnswer((_) async => addressWithAddition);

      final result = await useCase.call(addressWithAddition);

      expect(result.addition, 'B');
      verify(() => mockRepo.saveAddress(addressWithAddition)).called(1);
    });

    test('propagates repository exceptions', () async {
      when(
        () => mockRepo.saveAddress(any()),
      ).thenThrow(Exception('Save failed'));

      expect(() => useCase.call(testAddress), throwsA(isA<Exception>()));
    });
  });
}
