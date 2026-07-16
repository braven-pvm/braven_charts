import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showcases live pie datasets and public usage guidance', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Pie Charts'), findsOneWidget);
    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-revenue')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-effort')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-dataset-support')), findsOneWidget);
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-legend-item-0')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-legend-item-0')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-legend-item-0')));
    await tester.pumpAndSettle();

    expect(find.text('Selected: Subscriptions'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pie-dataset-support')),
      -500,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('pie-showcase-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('pie-dataset-support')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Requests by topic'), findsOneWidget);
    expect(find.textContaining('8 categories'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    tester
        .widget<ElevatedButton>(
          find.byKey(const ValueKey('regenerate-pie-values')),
        )
        .onPressed!();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('tickets total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the pie showcase usable at a narrow viewport', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Options'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows native pie data and restores a captured artifact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PieChartsPage())),
    );
    await _settleCapture(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('pie-display-mode')),
        matching: find.text('Split'),
      ),
    );
    await _settleCapture(tester);
    final initialTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('pie-showcase-table')),
    );
    expect(initialTable.model?.projectionKind, ChartTableProjectionKind.pie);
    expect(initialTable.model?.pieRows.first.category, 'Subscriptions');
    expect(initialTable.model?.pieRows.first.shareDisplay, '42.00%');
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Value (USD)'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    final hardwareCell = find.descendant(
      of: find.byKey(const ValueKey('pie-showcase-table')),
      matching: find.text('Hardware'),
    );
    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Selected: Hardware'), findsOneWidget);
    final selectedTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('pie-showcase-table')),
    );
    expect(selectedTable.selectedPointRefs, {
      const ChartPointRef(seriesId: 'pie-showcase-revenue', pointIndex: 2),
    });
    expect(
      find.semantics.byLabel(
        'Hardware, 16.00 USD, 16.0 percent, slice 3 of 5, selected',
      ),
      findsOne,
    );

    await tester.tap(hardwareCell);
    await tester.pumpAndSettle();
    expect(find.text('Try slice interaction'), findsOneWidget);
    expect(
      tester
          .widget<ChartDataTable>(
            find.byKey(const ValueKey('pie-showcase-table')),
          )
          .selectedPointRefs,
      isEmpty,
    );
    semantics.dispose();

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('pie-showcase-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('capture-pie-artifact')),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const ValueKey('capture-pie-artifact')));
    await _settleCapture(tester);

    expect(find.text('series.pie'), findsOneWidget);
    expect(find.text('Schema 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Captured pie chart preview'), findsOneWidget);
    expect(find.text('Restore captured chart'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-pie-artifact')));
    await tester.pump();
    expect(find.byKey(const ValueKey('restored-pie-artifact')), findsOneWidget);
    expect(
      find.text('Restored from canonical JSON into a fresh chart runtime'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
