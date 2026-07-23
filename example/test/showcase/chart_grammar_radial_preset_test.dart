import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the radial preset renders every family without exception', (
    tester,
  ) async {
    // Showcase pages lay out for a desktop workbench: the default 800x600 test
    // surface collapses the chart pane (Cartesian axes assert pixelMax >
    // pixelMin) and pushes the wrapped preset chips off-screen. Every other
    // showcase page test sizes the view to 1440x1000 for the same reason.
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartGrammarPage())),
    );
    await tester.pumpAndSettle();

    // Select the radial preset.
    await tester.tap(find.byKey(const ValueKey('chart-grammar-preset-radial')));
    await tester.pumpAndSettle();

    for (final family in const ['Pie', 'Donut', 'Concentric', 'Polar']) {
      await tester.tap(find.text(family).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);
    }
  });
}
