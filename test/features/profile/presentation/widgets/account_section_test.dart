import 'package:deelmarkt/features/profile/presentation/widgets/account_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AccountSection', () {
    testWidgets('renders email', (tester) async {
      await pumpTestWidget(
        tester,
        const AccountSection(email: 'jan@deelmarkt.nl', phone: '+31612345678'),
      );

      expect(find.text('jan@deelmarkt.nl'), findsOneWidget);
    });

    testWidgets('renders masked phone number', (tester) async {
      await pumpTestWidget(
        tester,
        const AccountSection(email: 'jan@deelmarkt.nl', phone: '+31612345678'),
      );

      expect(find.text('+31 6 \u2022\u2022\u2022\u2022 5678'), findsOneWidget);
    });

    testWidgets('renders section header', (tester) async {
      await pumpTestWidget(
        tester,
        const AccountSection(email: 'jan@deelmarkt.nl', phone: '+31612345678'),
      );

      expect(find.text('settings.account'), findsOneWidget);
    });
  });

  group('AccountSection.maskPhone', () {
    test('masks Dutch phone number', () {
      expect(
        AccountSection.maskPhone('+31612345678'),
        '+31 6 \u2022\u2022\u2022\u2022 5678',
      );
    });

    test('masks formatted phone number', () {
      expect(
        AccountSection.maskPhone('+31 6 1234 5678'),
        '+31 6 \u2022\u2022\u2022\u2022 5678',
      );
    });

    test('returns original for short numbers', () {
      expect(AccountSection.maskPhone('123'), '123');
    });

    test('shows last four digits', () {
      final result = AccountSection.maskPhone('+31698765432');
      expect(result, contains('5432'));
    });
  });
}
