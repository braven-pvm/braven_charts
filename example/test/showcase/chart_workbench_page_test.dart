import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_workbench_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ChartWorkbenchPage());

  testWidgets('shows the complete workbench workflow with one mounted chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    expect(find.text('Chart Workbench'), findsOneWidget);
    expect(find.text('Choose a view'), findsOneWidget);
    expect(find.text('Link rows to points'), findsOneWidget);
    expect(find.text('Try linked chart and table navigation'), findsOneWidget);
    expect(find.text('Run a host action'), findsOneWidget);
    expect(find.byType(BravenChartWorkbench), findsNWidgets(2));
    expect(find.byType(BravenChartPlus), findsNWidgets(5));
    expect(find.byType(ChartDataTable), findsNWidgets(2));
    expect(find.text('Compare portable chart documents'), findsOneWidget);
    expect(find.text('Three independently hydrated charts'), findsOneWidget);
    expect(
      find.text('Bounded stream, deliberate table snapshot'),
      findsOneWidget,
    );
    expect(find.text('Chart'), findsNWidgets(2));
    expect(find.text('Data'), findsNWidgets(2));
    expect(find.text('Split'), findsNWidgets(2));
    expect(find.text('Add to report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps restored comparison chart interactions independent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    expect(find.text('3 documents'), findsOneWidget);
    expect(find.textContaining('aligned rows'), findsOneWidget);
    expect(find.text('Hide Training load'), findsNWidgets(3));
    expect(find.text('All 2 series are visible.'), findsNWidgets(3));

    BravenChartPlus restoredChart(int index) => tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(ValueKey('comparison-tile-$index')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    final planChartBefore = restoredChart(1);
    final planController = planChartBefore.bravenChartController!;
    final targetSeriesId = planChartBefore.series.first.id;
    final formatterDescriptor = ChartFormatterDescriptor(
      id: 'braven.number.fixed',
      fallbackPattern: '{value}',
    ).toDocument();
    final visibleSeriesOptions = ChartDocumentExtractOptions(
      dataScope: ChartDataScope.visibleSeries,
      xAxisFormatterDescriptor: formatterDescriptor,
      yAxisFormatterDescriptors: {'y': formatterDescriptor},
    );
    final before = planController.extractDocument(visibleSeriesOptions);
    expect(
      before,
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
      reason: before is ChartArtifactFailure<ChartDocumentSnapshot>
          ? '${before.error.code}: ${before.error.message}'
          : null,
    );
    expect(
      (before as ChartArtifactSuccess<ChartDocumentSnapshot>)
          .value
          .document
          .series,
      hasLength(2),
    );

    final secondTileToggle = find.byKey(
      const ValueKey('comparison-tile-toggle-1'),
    );
    await tester.ensureVisible(secondTileToggle);
    await tester.pumpAndSettle();
    await tester.tap(secondTileToggle);
    await tester.pumpAndSettle();
    expect(find.text('Show Training load'), findsOneWidget);
    expect(find.text('Hide Training load'), findsNWidgets(2));
    expect(
      find.text('Training load is hidden in this restored chart only.'),
      findsOneWidget,
    );
    expect(find.text('All 2 series are visible.'), findsNWidgets(2));
    expect(planController.hiddenSeriesIds, contains(targetSeriesId));
    final after = planController.extractDocument(visibleSeriesOptions);
    expect(after, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
    expect(
      (after as ChartArtifactSuccess<ChartDocumentSnapshot>)
          .value
          .document
          .series,
      hasLength(1),
    );
    expect(restoredChart(0).bravenChartController!.hiddenSeriesIds, isEmpty);
    expect(restoredChart(2).bravenChartController!.hiddenSeriesIds, isEmpty);

    await tester.ensureVisible(find.text('Inspect CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspect CSV'));
    await tester.pumpAndSettle();
    expect(find.text('Source and derived comparison columns'), findsOneWidget);
    expect(find.textContaining('Absolute delta [derived]'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps restored controls attached after the source changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    await tester.tap(find.text('Generate another dataset'));
    await _settleWorkbench(tester);

    expect(find.text('Hide Observed'), findsNWidgets(3));
    final secondTileToggle = find.byKey(
      const ValueKey('comparison-tile-toggle-1'),
    );
    await tester.ensureVisible(secondTileToggle);
    await tester.pumpAndSettle();
    await tester.tap(secondTileToggle);
    await tester.pumpAndSettle();

    expect(find.text('Show Observed'), findsOneWidget);
    expect(
      find.text('Observed is hidden in this restored chart only.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects all exact-X points and carries them into a capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    final mainTable = find.descendant(
      of: find.byKey(const ValueKey('showcase-chart-workbench')),
      matching: find.byType(ChartDataTable),
    );
    final table = tester.widget<ChartDataTable>(mainTable);
    final rowId = table.model!.wideRows.first.rowId;

    final firstRow = find.descendant(
      of: mainTable,
      matching: find.byKey(ValueKey(rowId)),
    );
    await tester.ensureVisible(firstRow);
    await tester.pumpAndSettle();
    expect(
      find.text('Snapshot is stale'),
      findsNothing,
      reason: 'Scrolling the showcase must not invalidate the stream table.',
    );
    await tester.tap(firstRow);
    await _settleWorkbench(tester);
    expect(find.text('2 selected'), findsOneWidget);
    final selectedTable = tester.widget<ChartDataTable>(mainTable);
    expect(selectedTable.selectedPointRefs.length, 2);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('showcase-chart-workbench')),
        matching: find.text(
          'The chart changed after this table snapshot was captured.',
        ),
      ),
      findsNothing,
    );

    final addToReport = find.text('Add to report');
    await tester.ensureVisible(addToReport);
    await tester.pumpAndSettle();
    await tester.tap(addToReport);
    await _settleWorkbench(tester, includeAsyncDelay: true);
    expect(find.text('2 selected points'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures the effective chart and inline preview from Split', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    await tester.tap(find.text('Add to report'));
    await _settleWorkbench(tester, includeAsyncDelay: true);

    expect(find.text('Portable copy returned to the host'), findsOneWidget);
    expect(find.text('Portable copy ready'), findsOneWidget);
    expect(find.textContaining('workbench-capture-1'), findsOneWidget);
    expect(find.text('Preview attached'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes canonical JSON and revision-bound diagnostics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    await tester.tap(find.text('Add to report'));
    await _settleWorkbench(tester, includeAsyncDelay: true);

    final inspector = find.byKey(const ValueKey('inspect-artifact-button'));
    await tester.ensureVisible(inspector);
    await tester.pumpAndSettle();
    await tester.tap(inspector);
    await tester.pumpAndSettle();

    expect(find.text('Inspect portable artifact'), findsOneWidget);
    final rawJson = tester.widget<SelectableText>(
      find.byKey(const ValueKey('artifact-raw-json')),
    );
    expect(rawJson.data, contains('"artifactId":"workbench-capture-1"'));
    expect(rawJson.data, contains('"document"'));

    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Hash verified'), findsOneWidget);
    expect(find.text('No warnings'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('series ·'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close inspector'));
    await tester.pumpAndSettle();
  });

  testWidgets('demonstrates warning, failure recovery, and stale snapshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final warningAction = find.text('Show table warning');
    await tester.ensureVisible(warningAction);
    await tester.tap(warningAction);
    await _settleWorkbench(tester);
    expect(find.textContaining('safe display fallback'), findsOneWidget);

    final failureAction = find.text('Show recoverable failure');
    await tester.tap(failureAction);
    await _settleWorkbench(tester);
    expect(find.text('Retry refresh'), findsOneWidget);
    expect(
      find.textContaining('previous table is still shown'),
      findsOneWidget,
    );
    final retry = find.text('Retry refresh');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await _settleWorkbench(tester);
    expect(find.text('Retry refresh'), findsNothing);

    final staleAction = find.text('Show stale snapshot');
    await tester.tap(staleAction);
    await _settleWorkbench(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('showcase-chart-workbench')),
        matching: find.text(
          'The chart changed after this table snapshot was captured.',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Refresh table'), findsWidgets);
  });

  testWidgets('keeps a bounded stream table stable until explicit refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    expect(find.text('8 / 12 live samples'), findsOneWidget);
    expect(find.text('8 table rows'), findsOneWidget);
    expect(find.text('Snapshot is stale'), findsNothing);

    final streamTable = find.descendant(
      of: find.byKey(const ValueKey('stream-chart-workbench')),
      matching: find.byType(ChartDataTable),
    );
    final initialTable = tester.widget<ChartDataTable>(streamTable);
    final firstRow = find.descendant(
      of: streamTable,
      matching: find.byKey(ValueKey(initialTable.model!.wideRows.first.rowId)),
    );
    await tester.ensureVisible(firstRow);
    await tester.pumpAndSettle();
    await tester.tap(firstRow);
    await _settleWorkbench(tester);
    final streamWorkbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('stream-chart-workbench')),
    );
    final streamHandle = streamWorkbench.workbenchController!;
    expect(
      find.text('Snapshot is stale'),
      findsNothing,
      reason:
          'phase=${streamHandle.tableState.phase}, '
          'snapshotMatches=${streamHandle.tableSnapshot?.revision == streamHandle.chartController.effectiveDocumentRevision.value}, '
          'selected=${streamHandle.chartController.selectedPointRefs}',
    );
    expect(
      find.text(
        'The point reference belongs to an older chart document revision.',
      ),
      findsNothing,
    );

    final addSamples = find.byKey(const ValueKey('stream-add-samples'));
    await tester.ensureVisible(addSamples);
    await tester.pumpAndSettle();
    await tester.tap(addSamples);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('12 / 12 live samples'), findsOneWidget);
    expect(find.text('8 table rows'), findsOneWidget);
    expect(find.text('Snapshot is stale'), findsOneWidget);

    final refresh = find.byKey(const ValueKey('stream-refresh-table'));
    await tester.tap(refresh);
    await _settleWorkbench(tester);
    expect(find.text('12 table rows'), findsOneWidget);
    expect(find.text('Snapshot is stale'), findsNothing);
  });

  testWidgets('refreshes the table when the host changes its chart data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);
    expect(find.text('Recovery response'), findsWidgets);

    await tester.tap(find.text('Generate another dataset'));
    await _settleWorkbench(tester);

    expect(find.text('Interval comparison'), findsWidgets);
    final table = tester.widget<ChartDataTable>(
      find.descendant(
        of: find.byKey(const ValueKey('showcase-chart-workbench')),
        matching: find.byType(ChartDataTable),
      ),
    );
    expect(table.model?.documentId, 'workbench-intervals-2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the showcase usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Chart Workbench'), findsOneWidget);
    expect(find.byType(BravenChartWorkbench), findsNWidgets(2));
    expect(find.byKey(const ValueKey('workbench-host-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps mounted workbenches attached across layout breakpoints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final mainWorkbench = find.byKey(
      const ValueKey('showcase-chart-workbench'),
    );
    final mountedState = tester.state(mainWorkbench);

    tester.view.physicalSize = const Size(820, 900);
    await tester.pump();
    await _settleWorkbench(tester);

    expect(tester.state(mainWorkbench), same(mountedState));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();
    await _settleWorkbench(tester);

    expect(tester.state(mainWorkbench), same(mountedState));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleWorkbench(
  WidgetTester tester, {
  bool includeAsyncDelay = false,
}) async {
  if (includeAsyncDelay) {
    for (var index = 0; index < 8; index++) {
      await tester.pump();
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    for (var index = 0; index < 6; index++) {
      await tester.pump();
    }
    return;
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 20));
}
