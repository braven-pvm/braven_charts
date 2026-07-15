import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactShowcasePage());

  testWidgets('presents the complete artifact workflow on one page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    expect(find.text('Chart Artifacts'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('Generate random chart'), findsOneWidget);
    expect(find.text('Capture current chart'), findsOneWidget);
    expect(find.text('Captured charts'), findsOneWidget);
    expect(find.text('No captured charts yet'), findsOneWidget);
    expect(find.text('3. Restore or inspect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures, inspects, and restores a portable chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);

    expect(find.byKey(const ValueKey('artifact-thumbnail-1')), findsOneWidget);
    expect(find.text('1 saved in this demo session'), findsOneWidget);

    await tester.tap(find.text('View data'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('captured-data-showcase-capture-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Restore chart'));
    await tester.pump();

    expect(find.text('RESTORED FROM CAPTURE 1'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);

    await tester.tap(find.text('Raw JSON'));
    await tester.pump();
    expect(
      find.textContaining('"artifactType": "braven.chartArtifact"'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats live and captured series values to two decimals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    final liveTable = tester.widget<ChartDataTable>(
      find.byType(ChartDataTable).first,
    );
    _expectTwoDecimalSeriesValues(liveTable.model!);

    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);
    final capturedTable = tester.widget<ChartDataTable>(
      find.byKey(const ValueKey('captured-data-showcase-capture-1')),
    );
    _expectTwoDecimalSeriesValues(capturedTable.model!);
    expect(tester.takeException(), isNull);
  });

  testWidgets('regenerates a different live chart', (tester) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    final chartFinder = find.byKey(const ValueKey('live-generated-chart'));
    final firstChart = tester.widget<BravenChartPlus>(chartFinder);

    await tester.tap(find.text('Generate random chart'));
    await tester.pump();
    final secondChart = tester.widget<BravenChartPlus>(chartFinder);
    expect(secondChart.title, isNot(firstChart.title));
    expect(chartFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains ready to capture after repeated regeneration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    for (var generation = 0; generation < 3; generation++) {
      await tester.tap(find.text('Generate random chart'));
      await tester.pump();
      await tester.tap(find.text('Capture current chart'));
      await _settleCapture(tester);
    }

    expect(find.textContaining('chart_not_attached'), findsNothing);
    expect(find.text('3 saved in this demo session'), findsOneWidget);
    expect(find.text('Preparing data table'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains ready when switching between restored captures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);
    await tester.tap(find.text('Generate random chart'));
    await tester.pump();
    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);

    await tester.tap(find.text('Restore chart'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('artifact-library-showcase-capture-1')),
    );
    await tester.pump();
    await tester.tap(find.text('Restore chart'));
    await tester.pump();
    await tester.tap(find.text('Capture current chart'));
    await _settleCapture(tester);

    expect(find.textContaining('chart_not_attached'), findsNothing);
    expect(find.text('3 saved in this demo session'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the single page usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Generate random chart'), findsOneWidget);
    expect(find.byTooltip('Capture current chart'), findsOneWidget);
    expect(find.text('Chart Artifacts'), findsOneWidget);
    expect(find.text('1. Generate'), findsOneWidget);
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

void _expectTwoDecimalSeriesValues(ChartTableModel model) {
  final firstRow = model.wideRows.first;
  for (final cell in firstRow.cells.values) {
    expect(cell.yDisplay, cell.yRaw.toStringAsFixed(2));
  }
}
