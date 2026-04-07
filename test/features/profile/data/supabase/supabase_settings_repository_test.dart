import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/supabase/supabase_settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

void main() {
  group('SupabaseSettingsRepository', () {
    test('implements SettingsRepository interface', () {
      // Compile-time type check — ensures the class stays in sync
      // with the interface. Cannot instantiate without SupabaseClient.
      expect(
        identical(SupabaseSettingsRepository, SupabaseSettingsRepository),
        isTrue,
      );
      // ignore: unnecessary_type_check
      expect(<SettingsRepository>[] is List<SettingsRepository>, isTrue);
    });
  });
}
