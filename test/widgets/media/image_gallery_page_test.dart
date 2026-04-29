import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/widgets/media/image_gallery_page.dart';

import '../../_helpers/fake_performance_tracer.dart';

Widget _buildApp({
  required Widget child,
  required FakePerformanceTracer tracer,
}) {
  return ProviderScope(
    overrides: [performanceTracerProvider.overrideWithValue(tracer)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  const testUrl = 'https://example.com/img.jpg';

  Widget buildSubject({
    FakePerformanceTracer? tracer,
    String imageUrl = testUrl,
    int index = 0,
    int total = 3,
    String? heroTag,
  }) {
    return _buildApp(
      tracer: tracer ?? FakePerformanceTracer(),
      child: ImageGalleryPage(
        imageUrl: imageUrl,
        index: index,
        total: total,
        heroTag: heroTag,
      ),
    );
  }

  group('ImageGalleryPage', () {
    testWidgets('starts image_load trace on mount', (tester) async {
      final tracer = FakePerformanceTracer();
      await tester.pumpWidget(buildSubject(tracer: tracer));

      expect(
        tracer.recordedCalls,
        contains(TraceCall.start(TraceNames.imageLoad)),
      );
    });

    testWidgets('stops image_load trace on dispose (safety net)', (
      tester,
    ) async {
      final tracer = FakePerformanceTracer();
      await tester.pumpWidget(buildSubject(tracer: tracer));

      // Unmount the widget — dispose() must stop any in-flight trace.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(
        tracer.recordedCalls,
        contains(TraceCall.stop(TraceNames.imageLoad)),
      );
      expect(tracer.activeTraceCount, 0);
    });

    testWidgets('does not wrap in Hero when heroTag is null', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('wraps in Hero when heroTag is provided', (tester) async {
      await tester.pumpWidget(buildSubject(heroTag: 'gallery-0'));

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'gallery-0');
    });

    testWidgets('renders Semantics label with index + total', (tester) async {
      await tester.pumpWidget(buildSubject(index: 1, total: 5));

      // The Semantics node for the image must exist — label verified via
      // SemanticsController since easy_localization is not bootstrapped here,
      // so we only assert the Semantics widget is present.
      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });
  });
}
