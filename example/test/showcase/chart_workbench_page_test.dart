import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_workbench_page.dart';
import 'package:flutter/gestures.dart';
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
    expect(
      find.text('One chart, four linked views, one host-owned result'),
      findsOneWidget,
    );
    expect(find.text('Use BravenChartPlus directly'), findsOneWidget);
    expect(find.text('Add a Workbench'), findsOneWidget);
    expect(find.text('Your chart'), findsOneWidget);
    expect(find.text('Linked views'), findsOneWidget);
    expect(find.text('Host action'), findsOneWidget);
    expect(find.text('Your application'), findsOneWidget);
    expect(find.text('Explore one mounted chart in four ways'), findsOneWidget);
    expect(
      find.text('Send the current chart back to your app'),
      findsOneWidget,
    );
    expect(find.byType(BravenChartWorkbench), findsNWidgets(2));
    expect(find.byType(BravenChartPlus), findsNWidgets(5));
    expect(find.byType(ChartDataTable), findsNWidgets(2));
    expect(find.text('Compare portable chart documents'), findsOneWidget);
    expect(find.text('Three independently hydrated charts'), findsOneWidget);
    expect(
      find.text('Bounded stream, deliberate table snapshot'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNWidgets(2),
    );
    expect(find.text('Chart'), findsWidgets);
    expect(find.text('Data'), findsWidgets);
    expect(find.text('Split'), findsWidgets);
    expect(find.text('Source'), findsWidgets);
    expect(find.text('Shared presentation'), findsOneWidget);
    expect(find.text('Shared view'), findsOneWidget);
    expect(find.text('Show view selector'), findsOneWidget);
    expect(find.text('Add to report'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('chart-overlay-action-button-showcase.addToReport'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the standard copyable Dart code surface', (tester) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final codeReference = find.byKey(
      const ValueKey('workbench-code-reference'),
    );
    await tester.ensureVisible(codeReference);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workbench-usage-code-window')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('workbench-usage-code')), findsOneWidget);
    expect(find.byType(ChartCodeBlock), findsOneWidget);
    expect(find.text('Compose linked views'), findsWidgets);
    expect(find.text('Return an artifact'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-workbench-code')), findsOneWidget);

    await tester.tap(find.text('Return an artifact'));
    await tester.pumpAndSettle();

    final code = tester.widget<ChartCodeBlock>(find.byType(ChartCodeBlock));
    expect(code.code, contains('handle.extractArtifact(options)'));
    expect(code.code, contains('reportStore.add(result.value)'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs the primary host action from the chart button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final actionButton = find.byKey(
      const ValueKey('chart-overlay-action-button-showcase.addToReport'),
    );
    expect(actionButton, findsOneWidget);
    expect(tester.getSize(actionButton), const Size.square(48));

    await tester.tap(actionButton);
    await _settleWorkbench(tester, includeAsyncDelay: true);

    expect(find.text('Portable copy returned to the host'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runs the primary host action from the native chart menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final chart = find.byKey(const ValueKey('workbench-mounted-chart'));
    final renderSurface = find.descendant(
      of: chart,
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(renderSurface),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Add to report'), findsWidgets);
    await tester.tap(find.text('Add to report').last);
    await _settleWorkbench(tester, includeAsyncDelay: true);

    expect(find.text('Portable copy returned to the host'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('host menu remains available when annotations are absent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final streamWorkbench = find.byKey(
      const ValueKey('stream-chart-workbench'),
    );
    await tester.ensureVisible(streamWorkbench);
    await _settleWorkbench(tester);
    final streamChart = find.descendant(
      of: streamWorkbench,
      matching: find.byType(BravenChartPlus),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(streamChart),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Capture stream snapshot'), findsOneWidget);
    expect(find.text('Add Text Annotation'), findsNothing);
    await tester.tap(find.text('Capture stream snapshot'));
    await _settleWorkbench(tester, includeAsyncDelay: true);

    expect(
      find.byKey(const ValueKey('stream-context-capture-status')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows copyable effective Dart in the central Source view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final mainWorkbench = find.byKey(
      const ValueKey('showcase-chart-workbench'),
    );
    final sourceMode = find.descendant(
      of: mainWorkbench,
      matching: find.text('Source'),
    );
    await tester.ensureVisible(sourceMode);
    await tester.pump();
    await tester.tap(sourceMode);
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final modeSwitcher = tester.widget<SegmentedButton<ChartDisplayMode>>(
      find.descendant(
        of: mainWorkbench,
        matching: find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      ),
    );
    expect(modeSwitcher.selected, {ChartDisplayMode.source});
    final controller = tester
        .widget<BravenChartWorkbench>(mainWorkbench)
        .workbenchController!;
    final sourceState = controller.sourceState;
    expect(
      sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
      reason: sourceState.error == null
          ? null
          : '${sourceState.error!.code}: ${sourceState.error!.message}',
    );

    expect(
      find.descendant(
        of: mainWorkbench,
        matching: find.byType(ChartSourceView),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
    expect(
      find.descendant(of: mainWorkbench, matching: find.text('Copy code')),
      findsOneWidget,
    );
    expect(find.byType(BravenChartPlus), findsNWidgets(5));
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
    expect(find.text('Hide Observed'), findsNWidgets(3));
    expect(find.text('All 3 series are visible.'), findsNWidgets(3));

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
      hasLength(3),
    );

    final secondTileToggle = find.byKey(
      const ValueKey('comparison-tile-toggle-1'),
    );
    await tester.ensureVisible(secondTileToggle);
    await tester.pumpAndSettle();
    await tester.tap(secondTileToggle);
    await tester.pumpAndSettle();
    expect(find.text('Show Observed'), findsOneWidget);
    expect(find.text('Hide Observed'), findsNWidgets(2));
    expect(
      find.text('Observed is hidden in this restored chart only.'),
      findsOneWidget,
    );
    expect(find.text('All 3 series are visible.'), findsNWidgets(2));
    expect(planController.hiddenSeriesIds, contains(targetSeriesId));
    final after = planController.extractDocument(visibleSeriesOptions);
    expect(after, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
    expect(
      (after as ChartArtifactSuccess<ChartDocumentSnapshot>)
          .value
          .document
          .series,
      hasLength(2),
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

  testWidgets('prepares document comparison without an active data view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());

    final mainWorkbench = find.byKey(
      const ValueKey('showcase-chart-workbench'),
    );
    await tester.tap(
      find.descendant(of: mainWorkbench, matching: find.text('Chart')),
    );
    await _settleWorkbench(tester);

    final comparisonProof = find.byKey(
      const ValueKey('workbench-comparison-proof'),
    );
    expect(
      find.descendant(
        of: comparisonProof,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: comparisonProof,
        matching: find.text('Three independently hydrated charts'),
      ),
      findsOneWidget,
    );
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
    await tester.tap(find.text('Generate another chart').first);
    await _settleWorkbench(tester);

    final secondTileToggle = find.byKey(
      const ValueKey('comparison-tile-toggle-1'),
    );
    final sourceChart = tester.widget<BravenChartPlus>(
      find.descendant(
        of: find.byKey(const ValueKey('comparison-tile-1')),
        matching: find.byType(BravenChartPlus),
      ),
    );
    final seriesName = sourceChart.series.first.name!;
    expect(find.text('Hide $seriesName'), findsNWidgets(3));
    await tester.ensureVisible(secondTileToggle);
    await tester.pumpAndSettle();
    await tester.tap(secondTileToggle);
    await tester.pumpAndSettle();

    expect(find.text('Show $seriesName'), findsOneWidget);
    expect(
      find.text('$seriesName is hidden in this restored chart only.'),
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
    expect(find.text('3 selected'), findsOneWidget);
    final selectedTable = tester.widget<ChartDataTable>(mainTable);
    expect(selectedTable.selectedPointRefs.length, 3);
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
    expect(find.text('3 selected points'), findsOneWidget);
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
    expect(find.textContaining('Portable result ready below'), findsOneWidget);
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
    final workbench = find.byKey(const ValueKey('showcase-chart-workbench'));
    final beforeChart = tester.widget<BravenChartPlus>(
      find.descendant(of: workbench, matching: find.byType(BravenChartPlus)),
    );
    final beforeTable = tester.widget<ChartDataTable>(
      find.descendant(of: workbench, matching: find.byType(ChartDataTable)),
    );

    await tester.tap(find.text('Generate another chart').first);
    await _settleWorkbench(tester);

    final afterChart = tester.widget<BravenChartPlus>(
      find.descendant(of: workbench, matching: find.byType(BravenChartPlus)),
    );
    final table = tester.widget<ChartDataTable>(
      find.descendant(of: workbench, matching: find.byType(ChartDataTable)),
    );
    expect(afterChart.title, isNot(beforeChart.title));
    expect(table.model?.documentId, isNot(beforeTable.model?.documentId));
    expect(table.model?.documentId, startsWith('workbench-'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps varied generated chart families inside one Workbench', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleWorkbench(tester);

    final workbench = find.byKey(const ValueKey('showcase-chart-workbench'));
    final seriesTypes = <Type>{};
    final titles = <String>{};
    for (var generation = 0; generation < 8; generation++) {
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(of: workbench, matching: find.byType(BravenChartPlus)),
      );
      seriesTypes.add(chart.series.first.runtimeType);
      titles.add(chart.title!);
      final table = tester.widget<ChartDataTable>(
        find.descendant(of: workbench, matching: find.byType(ChartDataTable)),
      );
      expect(table.model?.rowCount, greaterThan(0));
      expect(find.text('3 documents'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Generate another chart').first);
      await _settleWorkbench(tester);
    }

    expect(titles, hasLength(8));
    expect(seriesTypes.length, greaterThanOrEqualTo(4));
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
