import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_result_count_text.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget host(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('exposes a Semantics liveRegion so screen readers re-announce', (
    tester,
  ) async {
    const data = SearchState(filter: SearchFilter(query: 'bike'), total: 12);
    await tester.pumpWidget(host(const SearchResultCountText(data: data)));
    await tester.pumpAndSettle();
    final semantics = tester.widget<Semantics>(
      find
          .ancestor(of: find.byType(Text), matching: find.byType(Semantics))
          .first,
    );
    expect(semantics.properties.liveRegion, isTrue);
  });
}
