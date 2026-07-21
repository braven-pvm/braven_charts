import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/performance_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('performance lab presents scoped session measurements', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PerformancePage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Performance Lab'), findsOneWidget);
    expect(find.text('Dataset Stress Test'), findsOneWidget);
    expect(find.text('Live session measurements'), findsOneWidget);
    expect(find.textContaining('do not treat these values'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    expect(find.text('Data generation'), findsOneWidget);
    expect(find.text('Visual update'), findsOneWidget);
    expect(find.text('p95 build'), findsOneWidget);
    expect(find.text('p95 raster'), findsOneWidget);
    expect(find.text('Slow frames'), findsOneWidget);

    expect(find.text('Excellent'), findsNothing);
    expect(find.text('Good'), findsNothing);
    expect(find.text('Moderate'), findsNothing);
    expect(find.text('Intensive'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('10K action updates the stress dataset', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PerformancePage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('Run 10K stress case'),
      300,
      scrollable: find.descendant(
        of: find.byType(OptionsPanel),
        matching: find.byType(Scrollable),
      ),
    );
    tester
        .widget<ActionButton>(
          find.widgetWithText(ActionButton, 'Run 10K stress case'),
        )
        .onPressed();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('10000 total points'), findsOneWidget);
    expect(find.text('10000'), findsOneWidget);

    tester
        .widget<ActionButton>(
          find.widgetWithText(ActionButton, 'Reset session metrics'),
        )
        .onPressed();
    await tester.pump();
    expect(find.text('0 / 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
