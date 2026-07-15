import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_types_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart type ribbon selects the configurable main chart', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose a chart type'), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-type-ribbon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-type-preview-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-area')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-type-preview-scatter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selected-chart-type-line')),
      findsOneWidget,
    );
    expect(find.text('Line chart playground'), findsOneWidget);
    expect(find.textContaining('2 series · 16 points each'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-bar')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-bar')),
      findsOneWidget,
    );
    expect(find.text('Bar chart playground'), findsOneWidget);
    expect(find.text('Bar Appearance'), findsOneWidget);
    expect(find.textContaining('64% bar width'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chart-type-preview-scatter')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-chart-type-scatter')),
      findsOneWidget,
    );
    expect(find.text('Scatter chart playground'), findsOneWidget);
    expect(find.text('Marker Appearance'), findsOneWidget);
  });

  testWidgets('chart-defining controls precede generic display controls', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartTypesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final chartTypeTop = tester.getTopLeft(find.text('Chart Type')).dy;
    final genericOptionsTop = tester.getTopLeft(find.text('Chart Options')).dy;

    expect(chartTypeTop, lessThan(genericOptionsTop));
    expect(find.text('Show Second Series'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Regenerate Dataset'),
      300,
      scrollable: find.descendant(
        of: find.byType(OptionsPanel),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Regenerate Dataset'), findsOneWidget);
  });
}
