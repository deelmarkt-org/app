import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/layout/responsive_detail_scaffold.dart';

Widget _buildApp({
  required double width,
  required Widget master,
  Widget? detail,
  Widget? emptyDetail,
  double masterWidth = 360,
}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: MaterialApp(
      home: Scaffold(
        body: ResponsiveDetailScaffold(
          master: master,
          detail: detail,
          emptyDetail: emptyDetail,
          masterWidth: masterWidth,
        ),
      ),
    ),
  );
}

void main() {
  const masterKey = Key('master');
  const detailKey = Key('detail');
  const emptyKey = Key('empty');

  group('ResponsiveDetailScaffold compact (<840px)', () {
    testWidgets('renders master when detail is null', (tester) async {
      await tester.pumpWidget(
        _buildApp(width: 500, master: const SizedBox(key: masterKey)),
      );
      expect(find.byKey(masterKey), findsOneWidget);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders detail instead of master when detail is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          width: 500,
          master: const SizedBox(key: masterKey),
          detail: const SizedBox(key: detailKey),
        ),
      );
      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.byKey(masterKey), findsNothing);
    });
  });

  group('ResponsiveDetailScaffold expanded (≥840px)', () {
    testWidgets('renders both master and detail side-by-side', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          width: 1000,
          master: const SizedBox(key: masterKey),
          detail: const SizedBox(key: detailKey),
        ),
      );
      expect(find.byKey(masterKey), findsOneWidget);
      expect(find.byKey(detailKey), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('master column honours masterWidth', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          width: 1200,
          master: const SizedBox(key: masterKey),
          detail: const SizedBox(key: detailKey),
          masterWidth: 320,
        ),
      );
      final sized = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byKey(masterKey),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sized.width, 320);
    });

    testWidgets(
      'VerticalDivider stretches full viewport height when detail is a ListView',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResponsiveDetailScaffold(
                master: const SizedBox(key: masterKey),
                detail: ListView(
                  children: [for (int i = 0; i < 20; i++) Text('item $i')],
                ),
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(VerticalDivider)).height, 600);
      },
    );

    testWidgets('renders emptyDetail when detail is null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          width: 1000,
          master: const SizedBox(key: masterKey),
          emptyDetail: const SizedBox(key: emptyKey),
        ),
      );
      expect(find.byKey(masterKey), findsOneWidget);
      expect(find.byKey(emptyKey), findsOneWidget);
    });
  });
}
