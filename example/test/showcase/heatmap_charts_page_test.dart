// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/heatmap_raster_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/heatmap_charts_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, {String? initialPreset}) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final workbenchGroup = ChartWorkbenchGroupController();
    addTearDown(workbenchGroup.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ChartWorkbenchScope(
          controller: workbenchGroup,
          child: Scaffold(
            body: HeatmapChartsPage(initialPreset: initialPreset),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (:slug, :title) in const [
    (slug: 'density-contours', title: 'Customer density contours'),
    (slug: 'clustered-matrix', title: 'Clustered product signals'),
    (slug: 'massive-matrix', title: 'Viewport-backed massive matrix'),
  ]) {
    testWidgets('Heatmap direct route resolves $slug', (tester) async {
      await pumpPage(tester, initialPreset: slug);

      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Heatmap guide exposes chart, matrix data, split, and source', (
    tester,
  ) async {
    await pumpPage(tester);

    final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
    expect(workbenchFinder, findsOneWidget);
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(switcher, findsOneWidget);
    for (final mode in const ['Chart', 'Data', 'Split', 'Source']) {
      expect(
        find.descendant(of: switcher, matching: find.text(mode)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();

    var workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    final table = workbench.workbenchController!.tableModel!;
    expect(table.series, hasLength(12));
    expect(table.wideRows, hasLength(7));
    expect(table.xColumnLabel, 'Y \\ X');
    expect(table.wideRows.first.xDisplay, 'Mon');

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();

    workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    final generated = workbench.workbenchController!.generatedSource!;
    expect(generated.source, contains('final heatmapChart = BravenChartPlus('));
    expect(generated.source, contains('HeatmapChartSeries('));
    expect(
      generated.source,
      contains('colorScale: HeatmapColorScale.sequential('),
    );
    expect(find.byType(ChartSourceView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Heatmap guide exposes isolated session performance diagnostics',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(
        find.byKey(const ValueKey('options-panel-search-toggle')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('options-panel-search')),
        'Performance audit',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('heatmap-performance-audit-options')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-performance-probe')),
        findsOneWidget,
      );
      expect(find.text('Frame p95'), findsOneWidget);
      expect(find.text('Frame gap p95'), findsOneWidget);
      expect(find.text('Jank >16.7ms'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('run-heatmap-performance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('reset-heatmap-performance')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Heatmap preset changes refresh the mounted source', (
    tester,
  ) async {
    await pumpPage(tester);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service health'));
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('heatmap-workbench')),
    );
    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('colorScale: HeatmapColorScale.threshold('),
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains("bandLabels: ['Degraded', 'Watch', 'Healthy'],"),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Heatmap guide covers calendar and correlation matrices', (
    tester,
  ) async {
    await pumpPage(tester);

    for (final label in const [
      'Activity matrix',
      'Matrix selection',
      'Irregular cells',
      'Temperature',
      'Service health',
      'Calendar month',
      'Contribution calendar',
      'Correlation',
      '2D histogram',
      'Density raster',
      'Density contours',
      'Clustered matrix',
      'Colour axes',
      'Small multiples',
      'Dense viewport',
      'Massive matrix',
      'Raster tiles',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Calendar month'));
    await tester.pumpAndSettle();
    expect(find.text('Daily temperature in July'), findsOneWidget);

    final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();
    var workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains('HeatmapDataPoint.missing('),
    );

    await tester.tap(find.text('Correlation'));
    await tester.pumpAndSettle();
    expect(find.text('Product metric correlation'), findsOneWidget);

    workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource!.source,
      contains("label: 'Correlation'"),
    );

    expect(find.text('Palette'), findsOneWidget);
    expect(find.text('Reverse palette'), findsOneWidget);
    expect(find.text('Clamp to domain'), findsOneWidget);
    expect(find.text('Domain padding'), findsOneWidget);
    expect(find.text('Midpoint offset'), findsOneWidget);
    expect(find.text('Missing cell'), findsOneWidget);
    expect(find.text('Show colour legend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Raster tile preset paints a controller-owned Cartesian background',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Raster tiles'));
      await tester.pumpAndSettle();

      expect(find.text('Deep signal spectrogram'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('heatmap-raster-source-status')),
        findsOneWidget,
      );
      expect(find.text('512M samples'), findsOneWidget);
      expect(find.text('12/12'), findsOneWidget);

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('heatmap-chart-rasterTiles')),
      );
      expect(chart.series, isEmpty);
      expect(chart.heatmapRasterViewportController, isNotNull);
      expect(chart.interactionGroupController, isNotNull);
      expect(chart.resetViewportBounds?.xMin, 983039.5);
      expect(chart.resetViewportBounds?.xMax, 999999.5);
      expect(
        chart.heatmapRasterViewportController!.snapshot.mountedTiles,
        hasLength(12),
      );
      expect(
        chart.heatmapRasterViewportController!.snapshot.semanticCells,
        hasLength(1536),
      );
      expect(
        chart.heatmapRasterViewportController!.snapshot.semanticSeries!.id,
        'raster-spectrogram-resident',
      );
      expect(
        chart.heatmapRasterViewportController!.snapshot.semanticSeries!.points,
        hasLength(1536),
      );
      expect(chart.xAxisConfig?.min, -0.5);
      expect(chart.xAxisConfig?.max, 999999.5);
      expect(chart.yAxis?.min, -0.5);
      expect(chart.yAxis?.max, 511.5);

      final renderBox =
          find
                  .descendant(
                    of: find.byKey(const ValueKey('heatmap-chart-rasterTiles')),
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget.runtimeType.toString() == '_ChartRenderWidget',
                    ),
                  )
                  .evaluate()
                  .single
                  .renderObject!
              as ChartRenderBox;
      renderBox.zoomChart(1.5, animate: false);
      renderBox.panChart(36, 12);
      await tester.pump(const Duration(milliseconds: 120));
      expect(renderBox.transform!.dataXMax, lessThan(999999.5));
      expect(
        chart
            .heatmapRasterViewportController!
            .snapshot
            .requestedViewport!
            .maximumX,
        lessThan(999999.5),
      );
      expect(
        chart.heatmapRasterViewportController!.snapshot.mountedTiles.length,
        lessThanOrEqualTo(24),
      );

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      var workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      expect(
        workbench.workbenchController!.tableState.error,
        isNull,
        reason: workbench.workbenchController!.tableState.error == null
            ? null
            : '${workbench.workbenchController!.tableState.error!.code}: '
                  '${workbench.workbenchController!.tableState.error!.message}',
      );
      expect(workbench.workbenchController!.tableModel!.series, hasLength(1));
      expect(
        workbench.workbenchController!.tableModel!.longRows,
        hasLength(
          chart.heatmapRasterViewportController!.snapshot.semanticCells.length,
        ),
      );
      expect(
        workbench.workbenchController!.tableModel!.rowCount,
        greaterThan(0),
      );
      final rasterProvider =
          HeatmapRasterViewportProviderDescriptor.fromDocument(
            workbench
                    .workbenchController!
                    .tableSnapshot!
                    .document
                    .configuration
                    .values['heatmapRasterViewportProvider']
                as JsonObjectValue,
          );
      expect(
        workbench
            .workbenchController!
            .tableSnapshot!
            .document
            .requiredCapabilities,
        contains(HeatmapRasterViewportProviderDescriptor.capabilityId),
      );
      expect(
        workbench
            .workbenchController!
            .tableSnapshot!
            .document
            .interaction
            .requiredBindings,
        isEmpty,
      );
      expect(rasterProvider.providerId, 'showcase.deep-signal-spectrogram.v1');
      expect(rasterProvider.fallback, HeatmapRasterProviderFallback.cell);
      expect(rasterProvider.arguments['matrixColumns']?.toJson(), 1000000);
      expect(rasterProvider.arguments['matrixRows']?.toJson(), 512);
      expect(rasterProvider.arguments['semanticColumnsPerTile']?.toJson(), 16);

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final generated = workbench.workbenchController!.generatedSource!;
      expect(generated.source, contains("id: 'raster-spectrogram-resident'"));
      expect(generated.source, contains("'aggregation': 'sampled-mean'"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Raster lifecycle keeps the previous viewport through loading and failure',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Raster tiles'));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);

      HeatmapRasterElement rasterElement() {
        final renderBox = tester.allRenderObjects
            .whereType<ChartRenderBox>()
            .singleWhere(
              (box) => box.debugElements
                  .whereType<HeatmapRasterElement>()
                  .isNotEmpty,
            );
        final element = renderBox.debugElements
            .whereType<HeatmapRasterElement>()
            .single;
        expect(
          element.bounds.overlaps(
            Rect.fromLTWH(0, 0, renderBox.plotWidth, renderBox.plotHeight),
          ),
          isTrue,
          reason: 'the retained raster must remain inside the visible plot',
        );
        return element;
      }

      final initialElement = rasterElement();

      await tester.tap(find.text('Review retained loading'));
      await tester.pump();
      expect(find.text('Loading · previous viewport retained'), findsOneWidget);
      expect(find.text('12/12'), findsOneWidget);
      expect(
        rasterElement().snapshot.mountedViewport,
        initialElement.snapshot.mountedViewport,
      );
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);

      final readyElement = rasterElement();

      await tester.tap(find.text('Review retained failure'));
      await tester.pump();
      expect(find.text('Loading · previous viewport retained'), findsOneWidget);
      expect(
        rasterElement().snapshot.mountedViewport,
        readyElement.snapshot.mountedViewport,
      );
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();
      expect(find.text('Retained fallback'), findsOneWidget);
      expect(
        find.textContaining('upstream spectrogram tile was unavailable'),
        findsOneWidget,
      );
      expect(find.text('12/12'), findsOneWidget);
      expect(
        rasterElement().snapshot.mountedViewport,
        readyElement.snapshot.mountedViewport,
      );

      await tester.tap(find.text('Retry requested window'));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Massive matrix keeps the renderer and Workbench on a bounded snapshot',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Massive matrix'));
      await tester.pumpAndSettle();

      expect(find.text('Viewport-backed massive matrix'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('heatmap-viewport-source-status')),
        findsOneWidget,
      );
      expect(find.text('24M cells'), findsOneWidget);
      expect(find.text('Portable provider'), findsOneWidget);
      expect(find.text('procedural-matrix.v1'), findsOneWidget);
      expect(find.text('Return to latest window'), findsOneWidget);

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('heatmap-chart-viewportSource')),
      );
      final series = chart.series.single as HeatmapChartSeries;
      expect(series.points.length, greaterThan(0));
      expect(series.points.length, lessThanOrEqualTo(12288));
      expect(chart.interactionGroupController, isNotNull);
      expect(chart.xAxisConfig?.min, -0.5);
      expect(chart.xAxisConfig?.max, 999999.5);

      expect(find.text('Start live cell stream'), findsOneWidget);
      await tester.tap(find.text('Start live cell stream'));
      await tester.pump(const Duration(milliseconds: 25));
      expect(find.text('Stop live cell stream'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('24 cells / 1 frames'), findsOneWidget);
      await tester.tap(find.text('Stop live cell stream'));
      await tester.pump();
      expect(find.text('Start live cell stream'), findsOneWidget);

      final renderBox =
          find
                  .descendant(
                    of: find.byKey(
                      const ValueKey('heatmap-chart-viewportSource'),
                    ),
                    matching: find.byWidgetPredicate(
                      (widget) =>
                          widget.runtimeType.toString() == '_ChartRenderWidget',
                    ),
                  )
                  .evaluate()
                  .single
                  .renderObject!
              as ChartRenderBox;
      expect(renderBox.transform!.dataXMin, closeTo(999699.5, 1e-9));
      expect(renderBox.transform!.dataXMax, closeTo(999999.5, 1e-9));

      renderBox.zoomChart(1.5, animate: false);
      renderBox.panChart(-80, 0);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('exceeding the configured limit'),
        findsNothing,
      );
      expect(find.textContaining('Bad state:'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('heatmap-chart-viewportSource')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      expect(renderBox.transform!.dataXMin, closeTo(999699.5, 1e-9));
      expect(renderBox.transform!.dataXMax, closeTo(999999.5, 1e-9));
      expect(renderBox.transform!.dataYMin, closeTo(-0.5, 1e-9));
      expect(renderBox.transform!.dataYMax, closeTo(23.5, 1e-9));
      expect(
        find.textContaining('exceeding the configured limit'),
        findsNothing,
      );
      expect(find.textContaining('Bad state:'), findsNothing);

      final updatedChart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('heatmap-chart-viewportSource')),
      );
      final updatedSeries = updatedChart.series.single as HeatmapChartSeries;
      expect(updatedSeries.points, isNotEmpty);

      final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
      final workbenchController = workbench.workbenchController!;
      final tableError = workbenchController.tableState.error;
      expect(
        workbenchController.tableState.phase,
        ChartWorkbenchTablePhase.ready,
        reason: tableError == null
            ? null
            : '${tableError.code}: ${tableError.message} (${tableError.path})',
      );
      final table = workbenchController.tableModel!;
      expect(table.wideRows, hasLength(24));
      expect(
        table.wideRows.fold<int>(0, (count, row) => count + row.cells.length),
        updatedSeries.points.length,
      );
      final document = workbenchController.tableSnapshot!.document;
      expect(
        document.requiredCapabilities,
        contains(HeatmapViewportProviderDescriptor.capabilityId),
      );
      final configuration =
          document.configuration.toJson() as Map<String, Object?>;
      final providerDocuments =
          configuration['heatmapViewportProviders']! as List<Object?>;
      expect(providerDocuments, hasLength(1));
      expect(
        providerDocuments.single,
        isA<Map<String, Object?>>()
            .having(
              (value) => value['providerId'],
              'providerId',
              'showcase.heatmap.procedural-matrix.v1',
            )
            .having(
              (value) => value['seriesId'],
              'seriesId',
              'heatmap-viewport-source',
            ),
      );
      expect(
        configuration['interactionBindings'],
        isNull,
        reason: 'The provider descriptor owns viewport restoration.',
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final sourceWorkbench = tester.widget<BravenChartWorkbench>(
        workbenchFinder,
      );
      expect(sourceWorkbench.workbenchController!.sourceIsStale, isFalse);
      expect(
        sourceWorkbench.workbenchController!.generatedSource!.source,
        contains('${updatedSeries.points.length} points omitted'),
      );
      expect(
        sourceWorkbench.workbenchController!.generatedSource!.source,
        contains("'snapshotSemantics': 'resident-cells-only'"),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Irregular cells preserve unequal geometry through data and source views',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Irregular cells'));
      await tester.pumpAndSettle();

      expect(find.text('Pipeline intervals'), findsOneWidget);
      final workbenchFinder = find.byKey(const ValueKey('heatmap-workbench'));
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: workbenchFinder,
          matching: find.byType(BravenChartPlus),
        ),
      );
      final series = chart.series.single as HeatmapChartSeries;
      expect(series.points, hasLength(12));
      expect(series.cells.every((point) => point.bounds != null), isTrue);
      expect(series.cells.first.bounds?.xMinimum, 0);
      expect(series.cells.first.bounds?.xMaximum, 2.4);
      expect(series.cells[3].bounds?.yMinimum, 0.52);
      expect(series.cells[3].bounds?.yMaximum, 1.48);

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();

      var workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
      final table = workbench.workbenchController!.tableModel!;
      expect(table.projectionKind, ChartTableProjectionKind.cartesianLong);
      expect(table.wideRows, isEmpty);
      expect(table.longRows, hasLength(12));
      expect(
        table.series.single.auxiliaryFields,
        contains(ChartTableAuxiliaryField.heatmapXMinimum),
      );
      expect(
        table
            .longRows
            .first
            .auxiliaryValues[ChartTableAuxiliaryField.heatmapXMaximum]
            ?.raw,
        2.4,
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      workbench = tester.widget<BravenChartWorkbench>(workbenchFinder);
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains('bounds: HeatmapCellBounds('));
      expect(source, contains('xMaximum: 2.4'));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Matrix selection preset exposes rectangle brush and Heatmap expansion',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Matrix selection'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('heatmap-selection-status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-selection-options')),
        findsOneWidget,
      );

      BravenChartPlus mountedChart() => tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );

      var selection = mountedChart().interactionConfig!.selection;
      expect(mountedChart().interactionConfig!.enableSelection, isTrue);
      expect(
        selection.acquisitionMode,
        ChartSelectionAcquisitionMode.rectangle,
      );
      expect(selection.scope, ChartSelectionScope.mark);
      expect(selection.heatmapExpansion, HeatmapSelectionExpansion.cell);
      expect(selection.brush.enabled, isTrue);
      expect(selection.brush.initialBox, isNotNull);
      expect(mountedChart().showXScrollbar, isFalse);
      final brushBefore = tester
          .widget<BravenChartWorkbench>(
            find.byKey(const ValueKey('heatmap-workbench')),
          )
          .chartController!
          .selectionBrushState;
      final selectedCountBefore = tester
          .widget<BravenChartWorkbench>(
            find.byKey(const ValueKey('heatmap-workbench')),
          )
          .chartController!
          .selectedPointRefs
          .length;
      expect(brushBefore?.visible, isTrue);
      expect(selectedCountBefore, greaterThan(0));

      tester
          .widget<EnumOption<HeatmapSelectionExpansion>>(
            find.byKey(const ValueKey('heatmap-selection-expansion')),
          )
          .onChanged(HeatmapSelectionExpansion.row);
      await tester.pumpAndSettle();

      selection = mountedChart().interactionConfig!.selection;
      expect(selection.heatmapExpansion, HeatmapSelectionExpansion.row);
      final controller = tester
          .widget<BravenChartWorkbench>(
            find.byKey(const ValueKey('heatmap-workbench')),
          )
          .chartController!;
      expect(controller.selectionBrushState, brushBefore);
      expect(
        controller.selectedPointRefs.length,
        greaterThan(selectedCountBefore),
        reason:
            'Changing expansion policy must re-resolve the existing brush '
            'instead of clearing it.',
      );

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains('heatmapExpansion: HeatmapSelectionExpansion.row'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small multiples share one connected colour domain and legend', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Small multiples'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('heatmap-small-multiples-composition')),
      findsOneWidget,
    );
    expect(find.text('Service latency by time window'), findsOneWidget);
    expect(find.text('Share colour domain'), findsOneWidget);
    expect(find.text('Shared padding'), findsOneWidget);
    expect(find.text('Filtered cells'), findsOneWidget);
    expect(find.text('Excluded opacity'), findsOneWidget);
    expect(find.text('Domain padding'), findsNothing);
    expect(
      find.byKey(const ValueKey('heatmap-shared-domain-legend')),
      findsOneWidget,
    );

    expect(find.byType(BravenChartWorkbench), findsNothing);
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('heatmap-small-multiple-latency-checkout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('heatmap-small-multiple-latency-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('heatmap-small-multiple-latency-reporting')),
      findsOneWidget,
    );

    List<HeatmapChartSeries> mountedSeries() => tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .map((chart) => chart.series.single as HeatmapChartSeries)
        .toList(growable: false);

    var series = mountedSeries();
    expect(series, hasLength(3));
    expect(
      series.map((value) => value.colorScale.minimumValue).toSet(),
      hasLength(1),
    );
    expect(
      series.map((value) => value.colorScale.maximumValue).toSet(),
      hasLength(1),
    );

    final filterSlider = tester.widget<RangeSlider>(
      find.descendant(
        of: find.byKey(const ValueKey('heatmap-shared-domain-legend')),
        matching: find.byType(RangeSlider),
      ),
    );
    filterSlider.onChanged!(const RangeValues(20, 80));
    await tester.pump();

    series = mountedSeries();
    expect(series.every((value) => value.valueFilter != null), isTrue);
    expect(series.map((value) => value.valueFilter).toSet(), hasLength(1));
    expect(series.first.valueFilter?.minimumValue, 20);
    expect(series.first.valueFilter?.maximumValue, 80);
    expect(
      find.byKey(const ValueKey('heatmap-clear-value-filter')),
      findsOneWidget,
    );

    await tester.tap(find.text('Share colour domain'));
    await tester.pumpAndSettle();

    series = mountedSeries();
    expect(
      series.every((value) => value.colorScale.minimumValue == null),
      isTrue,
    );
    expect(
      series.every((value) => value.colorScale.maximumValue == null),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('heatmap-shared-domain-legend')),
      findsNothing,
    );
    expect(find.text('Shared padding'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Contribution calendar styles zero separately from missing cells',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Contribution calendar'));
      await tester.pumpAndSettle();

      expect(find.text('Contribution activity'), findsOneWidget);
      expect(find.text('Empty values'), findsOneWidget);
      expect(find.text('Style zero activity'), findsOneWidget);
      expect(find.text('Zero activity fill'), findsOneWidget);
      expect(find.text('Show zero labels'), findsOneWidget);

      BravenChartPlus mountedChart() => tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );

      var series = mountedChart().series.single as HeatmapChartSeries;
      expect(series.points, hasLength(24 * 7));
      expect(series.cells.any((point) => point.value == 0), isTrue);
      expect(series.cells.any((point) => point.isMissing), isFalse);
      expect(
        series.emptyValueStyle,
        const HeatmapEmptyValueStyle(
          fillColor: Color(0xFFE5E7EB),
          borderColor: Color(0xFFD1D5DB),
          borderWidth: 0.8,
          showInLegend: true,
          legendLabel: 'No contributions',
        ),
      );

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains('emptyValueStyle: HeatmapEmptyValueStyle('),
      );
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains("legendLabel: 'No contributions',"),
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Chart')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Style zero activity'));
      await tester.pumpAndSettle();
      series = mountedChart().series.single as HeatmapChartSeries;
      expect(series.emptyValueStyle, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '2D histogram exposes canonical bins through chart data and source',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('2D histogram'));
      await tester.pumpAndSettle();

      expect(find.text('Review score density'), findsOneWidget);
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      final series = chart.series.single as HeatmapChartSeries;
      expect(series.points, hasLength(90));
      expect(series.points.first.pointKey, 'histogram-0-0');
      expect(
        series.points.any(
          (point) =>
              point.metadata?['histogramSourcePointKeys'] is List &&
              (point.metadata!['histogramSourcePointKeys'] as List).isNotEmpty,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull, reason: 'histogram chart mode');

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      var workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      expect(workbench.workbenchController!.tableModel!.series, hasLength(9));
      expect(
        workbench.workbenchController!.tableModel!.wideRows,
        hasLength(10),
      );
      expect(tester.takeException(), isNull, reason: 'histogram data mode');

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains("pointKey: 'histogram-0-0'"));
      expect(source, contains("'histogramXLowerBound':"));
      expect(source, contains("'histogramSourcePointKeys':"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull, reason: 'histogram source mode');
    },
  );

  testWidgets(
    'Density raster exposes live kernel controls and canonical provenance',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Density raster'));
      await tester.pumpAndSettle();

      expect(find.text('Customer behaviour density'), findsOneWidget);
      expect(find.text('Density estimation'), findsOneWidget);
      expect(find.text('Kernel'), findsOneWidget);
      expect(find.text('Engagement bandwidth'), findsOneWidget);
      expect(find.text('Value bandwidth'), findsOneWidget);

      HeatmapChartSeries mountedSeries() {
        final chart = tester.widget<BravenChartPlus>(
          find.descendant(
            of: find.byKey(const ValueKey('heatmap-workbench')),
            matching: find.byType(BravenChartPlus),
          ),
        );
        return chart.series.single as HeatmapChartSeries;
      }

      var series = mountedSeries();
      expect(series.points, hasLength(224));
      expect(series.points.first.pointKey, 'density-0-0');
      expect(series.showCellLabels, isFalse);
      expect(series.points.first.metadata?['densityKernel'], 'gaussian');
      expect(
        series.points.any(
          (point) =>
              point.metadata?['densitySourcePointKeys'] is List &&
              (point.metadata!['densitySourcePointKeys'] as List).isNotEmpty,
        ),
        isTrue,
      );
      final originalValues = series.cells.map((point) => point.value).toList();

      final xBandwidth = tester
          .widgetList<Slider>(find.byType(Slider))
          .singleWhere((slider) => slider.max == 1.6);
      xBandwidth.onChanged!(1.4);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points.first.metadata?['densityBandwidthX'], 1.4);
      expect(
        series.cells.map((point) => point.value).toList(),
        isNot(equals(originalValues)),
      );

      final kernel = tester
          .widget<DropdownButtonFormField<HeatmapDensityKernel>>(
            find.byType(DropdownButtonFormField<HeatmapDensityKernel>),
          );
      kernel.onChanged!(HeatmapDensityKernel.epanechnikov);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points.first.metadata?['densityKernel'], 'epanechnikov');

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      var workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      expect(workbench.workbenchController!.tableModel!.series, hasLength(16));
      expect(
        workbench.workbenchController!.tableModel!.wideRows,
        hasLength(14),
      );

      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains("pointKey: 'density-0-0'"));
      expect(source, contains("'densityKernel': 'epanechnikov'"));
      expect(source, contains("'densitySourcePointKeys':"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Density contours compose portable line overlays with live controls',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Density contours'));
      await tester.pumpAndSettle();

      expect(find.text('Customer density contours'), findsOneWidget);
      final optionsPanel = tester.widget<OptionsPanel>(
        find.byType(OptionsPanel),
      );
      expect(
        optionsPanel.children
            .whereType<OptionSection>()
            .take(2)
            .map((section) => section.title),
        ['Contour overlay', 'Density estimation'],
      );
      expect(find.text('Show contours'), findsOneWidget);
      expect(find.text('Contour levels'), findsOneWidget);
      expect(find.text('Kernel'), findsOneWidget);
      OptionSection contourSection() => tester
          .widget<OptionsPanel>(find.byType(OptionsPanel))
          .children
          .whereType<OptionSection>()
          .singleWhere((section) => section.title == 'Contour overlay');
      expect(
        contourSection().children.whereType<BoolOption>().single.label,
        'Show contours',
      );
      expect(
        contourSection().children.whereType<EnumOption>().map(
          (option) => option.label,
        ),
        ['Contour levels', 'Line geometry'],
      );

      BravenChartPlus mountedChart() => tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );

      var chart = mountedChart();
      expect(chart.series.first, isA<HeatmapChartSeries>());
      expect(chart.series.whereType<LineChartSeries>(), isNotEmpty);
      expect(
        chart.series.whereType<LineChartSeries>().every(
          (series) => series.interpolation == LineInterpolation.linear,
        ),
        isTrue,
      );
      expect(
        chart.series.whereType<LineChartSeries>().every(
          (series) =>
              series.points.first.metadata?['densityContourPathId'] != null,
        ),
        isTrue,
      );

      await tester.tap(find.text('Coarse · 3 levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detailed · 5 levels').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('5 contour levels'), findsOneWidget);

      await tester.tap(find.text('Gaussian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Epanechnikov').last);
      await tester.pumpAndSettle();
      chart = mountedChart();
      expect(
        (chart.series.first as HeatmapChartSeries)
            .points
            .first
            .metadata?['densityKernel'],
        'epanechnikov',
      );

      await tester.tap(find.text('Exact · linear'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Smooth · Bézier').last);
      await tester.pumpAndSettle();
      final tension = tester.widget<Slider>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-contour-tension')),
          matching: find.byType(Slider),
        ),
      );
      expect(tension.max, 0.5);
      tension.onChanged!(0.4);
      await tester.pumpAndSettle();
      chart = mountedChart();
      expect(
        chart.series.whereType<LineChartSeries>().every(
          (series) =>
              series.interpolation == LineInterpolation.bezier &&
              series.tension == 0.4,
        ),
        isTrue,
      );

      final stroke = tester.widget<Slider>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-contour-stroke-width')),
          matching: find.byType(Slider),
        ),
      );
      expect(stroke.max, 5);
      stroke.onChanged!(4);
      await tester.pumpAndSettle();
      chart = mountedChart();
      expect(
        chart.series.whereType<LineChartSeries>().every(
          (series) => series.strokeWidth == 4,
        ),
        isTrue,
      );

      contourSection().children.whereType<BoolOption>().single.onChanged(false);
      await tester.pumpAndSettle();
      expect(mountedChart().series, hasLength(1));
      contourSection().children.whereType<BoolOption>().single.onChanged(true);
      await tester.pumpAndSettle();

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains('HeatmapChartSeries('));
      expect(source, contains('LineChartSeries('));
      expect(source, contains('interpolation: LineInterpolation.bezier,'));
      expect(source, contains('tension: 0.4,'));
      expect(source, contains("'densityContourPathId':"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Clustered matrix exposes deterministic ordering controls and provenance',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Clustered matrix'));
      await tester.pumpAndSettle();

      expect(find.text('Clustered product signals'), findsOneWidget);
      expect(find.text('Matrix clustering'), findsOneWidget);
      expect(find.text('Apply clustered order'), findsOneWidget);
      expect(find.text('Initial focus'), findsOneWidget);
      expect(find.text('Cluster axes'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Linkage'), findsOneWidget);
      expect(find.text('Missing values'), findsOneWidget);
      expect(find.text('Collapsed-cell reducer'), findsOneWidget);
      expect(find.text('Show row dendrogram'), findsOneWidget);
      expect(find.text('Show column dendrogram'), findsOneWidget);
      expect(find.text('Hierarchy interaction'), findsOneWidget);
      expect(find.text('Branch spacing'), findsOneWidget);
      expect(find.text('Branch extent'), findsOneWidget);
      expect(find.text('Branch stroke'), findsOneWidget);
      expect(find.text('Branch colour'), findsOneWidget);
      expect(find.text('Branch caps'), findsOneWidget);
      expect(find.text('Branch joins'), findsOneWidget);
      expect(find.text('Elbow radius'), findsOneWidget);
      expect(find.text('Show leaf baseline'), findsOneWidget);
      expect(find.text('Baseline colour'), findsOneWidget);
      expect(find.text('Baseline stroke'), findsOneWidget);
      expect(find.text('Show leaf ticks'), findsOneWidget);
      expect(find.text('Tick colour'), findsOneWidget);
      expect(find.text('Tick stroke'), findsOneWidget);
      expect(find.text('Tick length'), findsOneWidget);
      expect(find.text('Show leaf markers'), findsOneWidget);
      expect(find.text('Leaf fill colour'), findsOneWidget);
      expect(find.text('Leaf marker shape'), findsOneWidget);
      expect(find.text('Leaf marker fill'), findsOneWidget);
      expect(find.text('Leaf border colour'), findsOneWidget);
      expect(find.text('Leaf border stroke'), findsOneWidget);
      expect(find.text('Leaf marker radius'), findsOneWidget);
      expect(find.text('Show merge markers'), findsOneWidget);
      expect(find.text('Merge fill colour'), findsOneWidget);
      expect(find.text('Merge marker shape'), findsOneWidget);
      expect(find.text('Merge marker fill'), findsOneWidget);
      expect(find.text('Merge border colour'), findsOneWidget);
      expect(find.text('Merge border stroke'), findsOneWidget);
      expect(find.text('Merge marker radius'), findsOneWidget);
      expect(find.text('Show leaf labels'), findsOneWidget);
      expect(find.text('Show merge distances'), findsOneWidget);
      expect(find.text('Label density'), findsOneWidget);
      expect(find.text('Label placement'), findsOneWidget);
      expect(find.text('Label text colour'), findsOneWidget);
      expect(find.text('Label background'), findsOneWidget);
      expect(find.text('Label font size'), findsOneWidget);
      expect(find.text('Label characters'), findsOneWidget);
      expect(find.text('Distance decimals'), findsOneWidget);
      expect(find.text('Automatic level of detail'), findsOneWidget);
      expect(find.text('Minimum branch length'), findsOneWidget);
      expect(find.text('Leaf guide spacing'), findsOneWidget);
      expect(find.text('Leaf marker spacing'), findsOneWidget);
      expect(find.text('Merge marker spacing'), findsOneWidget);
      expect(find.text('Label spacing'), findsOneWidget);
      expect(
        find.text('Readable spacing · similar near matrix'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-row-dendrogram')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-column-dendrogram')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-cluster-row-labels')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-cluster-column-labels')),
        findsOneWidget,
      );

      BravenChartPlus mountedChart() => tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );

      var chart = mountedChart();
      expect(chart.xAxisConfig!.visible, isFalse);
      expect(chart.yAxis!.visible, isFalse);
      expect(chart.yAxis!.position, YAxisPosition.hidden);
      expect(chart.interactionConfig!.enableZoom, isFalse);
      expect(chart.interactionConfig!.enablePan, isFalse);
      expect(chart.showXScrollbar, isFalse);
      expect(chart.axislessPlotInsets, const EdgeInsets.all(10));
      expect(
        find.text(
          'Hierarchy view keeps the full hierarchy fixed so the matrix, '
          'labels, and both trees remain aligned. Hover or tap an enabled '
          'hierarchy to inspect its stable node or branch identity. Tab into '
          'a hierarchy, use the arrow keys to move between visible nodes, '
          'Enter or Space to select, and Escape to clear. Selection only '
          'inspects; use the explicit collapse or expand action to change the '
          'visible matrix. Collapsed cells use the selected reducer and '
          'retain all original row, column, and point identities. Initial '
          'focus prunes accepted subtrees before layout; it does not '
          'recluster values. Hide both dendrograms to restore zoom, pan, and '
          'the X scrollbar.',
        ),
        findsOneWidget,
      );

      final rowDendrogramOption = tester.widget<BoolOption>(
        find.byKey(const ValueKey('heatmap-cluster-show-row-dendrogram')),
      );
      final columnDendrogramOption = tester.widget<BoolOption>(
        find.byKey(const ValueKey('heatmap-cluster-show-column-dendrogram')),
      );
      rowDendrogramOption.onChanged(false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('heatmap-row-dendrogram')),
        findsNothing,
      );
      columnDendrogramOption.onChanged(false);
      await tester.pumpAndSettle();

      chart = mountedChart();
      expect(
        find.byKey(const ValueKey('heatmap-clustered-composition')),
        findsNothing,
      );
      expect(chart.xAxisConfig!.visible, isTrue);
      expect(chart.yAxis!.visible, isTrue);
      expect(chart.yAxis!.position, YAxisPosition.left);
      expect(chart.interactionConfig!.enableZoom, isTrue);
      expect(chart.interactionConfig!.enablePan, isTrue);
      expect(chart.showXScrollbar, isTrue);

      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-show-row-dendrogram')),
          )
          .onChanged(true);
      tester
          .widget<BoolOption>(
            find.byKey(
              const ValueKey('heatmap-cluster-show-column-dendrogram'),
            ),
          )
          .onChanged(true);
      await tester.pumpAndSettle();

      HeatmapChartSeries mountedSeries() {
        return mountedChart().series.single as HeatmapChartSeries;
      }

      var series = mountedSeries();
      expect(series.points, hasLength(64));
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('axisMode', 'both'),
      );
      expect(series.metadata, contains('heatmapDendrogramRow'));
      expect(series.metadata, contains('heatmapDendrogramColumn'));
      expect(series.metadata, containsPair('heatmapHierarchyReducer', 'mean'));
      expect(
        series.metadata?['heatmapDendrogramRow'],
        containsPair('distanceScale', 'structural'),
      );
      expect(
        series.metadata?['heatmapDendrogramRowStyle'],
        containsPair('elbowRadius', 6.0),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('branchJoin', 'round'),
      );
      expect(
        tester
            .widgetList<HeatmapDendrogram>(find.byType(HeatmapDendrogram))
            .first
            .style,
        const HeatmapDendrogramStyle(
          branchColor: Color(0xFF5B5AA6),
          branchWidth: 1.5,
          branchCap: StrokeCap.round,
          branchJoin: StrokeJoin.round,
          baselineColor: Color(0xFFB8B7D9),
          baselineWidth: 1,
          tickColor: Color(0xFF7473A8),
          tickWidth: 1,
          tickLength: 5,
          elbowRadius: 6,
          showLeafMarkers: true,
          leafMarkerColor: Color(0xFF3B82F6),
          leafMarkerShape: HeatmapDendrogramMarkerShape.circle,
          leafMarkerFill: HeatmapDendrogramMarkerFill.hollow,
          leafMarkerBorderColor: Color(0xFF3B82F6),
          leafMarkerBorderWidth: 1.5,
          showMergeMarkers: true,
          mergeMarkerColor: Color(0xFFF97316),
          mergeMarkerShape: HeatmapDendrogramMarkerShape.diamond,
          mergeMarkerBorderColor: Color(0xFF9A3412),
          showMergeDistanceLabels: true,
          labelColor: Color(0xFF2E2D4F),
          labelBackgroundColor: Color(0xFFF4F3FF),
          labelFontSize: 9,
          maxLabelCharacters: 12,
        ),
      );
      expect(
        tester
            .widgetList<HeatmapDendrogram>(find.byType(HeatmapDendrogram))
            .every((widget) => widget.onInteractionStateChanged != null),
        isTrue,
      );

      final columnDendrogram = tester
          .widgetList<HeatmapDendrogram>(find.byType(HeatmapDendrogram))
          .first;
      columnDendrogram.onInteractionStateChanged!(
        HeatmapDendrogramInteractionState(
          selectedTarget: HeatmapDendrogramTargetIdentity(
            kind: HeatmapDendrogramHitKind.node,
            axis: HeatmapDendrogramAxis.columns,
            nodeId: columnDendrogram.data.rootId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('heatmap-collapse-selected-hierarchy')),
        findsOneWidget,
      );
      tester
          .widget<ActionButton>(
            find.byKey(const ValueKey('heatmap-collapse-selected-hierarchy')),
          )
          .onPressed();
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points, hasLength(8));
      expect(
        series.metadata?['heatmapHierarchyColumnCollapseState'],
        containsPair('collapsedNodeIds', [columnDendrogram.data.rootId]),
      );
      expect(
        series.points.every(
          (point) =>
              point.metadata?['heatmapHierarchySourceColumnIndices'] is List &&
              (point.metadata!['heatmapHierarchySourceColumnIndices'] as List)
                      .length ==
                  8,
        ),
        isTrue,
      );

      tester
          .widget<EnumOption<HeatmapHierarchyReducer>>(
            find.byKey(const ValueKey('heatmap-cluster-hierarchy-reducer')),
          )
          .onChanged(HeatmapHierarchyReducer.sum);
      await tester.pumpAndSettle();
      expect(
        mountedSeries().metadata,
        containsPair('heatmapHierarchyReducer', 'sum'),
      );

      tester
          .widget<ActionButton>(
            find.byKey(const ValueKey('heatmap-expand-all-hierarchy')),
          )
          .onPressed();
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points, hasLength(64));

      final hierarchyInteractionOption = tester.widget<BoolOption>(
        find.byKey(const ValueKey('heatmap-cluster-dendrogram-interaction')),
      );
      hierarchyInteractionOption.onChanged(false);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<HeatmapDendrogram>(find.byType(HeatmapDendrogram))
            .every((widget) => widget.onInteractionStateChanged == null),
        isTrue,
      );
      hierarchyInteractionOption.onChanged(true);
      await tester.pumpAndSettle();
      expect(
        series.points.first.metadata?['heatmapClusterSourceRowLabel'],
        isNotNull,
      );
      expect(series.cells.any((point) => point.isMissing), isTrue);

      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-lod')),
          )
          .onChanged(false);
      final minimumBranchSlider = tester.widget<Slider>(
        find.descendant(
          of: find.byKey(
            const ValueKey('heatmap-cluster-dendrogram-min-branch'),
          ),
          matching: find.byType(Slider),
        ),
      );
      minimumBranchSlider.onChanged!(2);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('levelOfDetailMode', 'disabled'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('minimumBranchLength', 2.0),
      );

      await tester.tap(find.text('Full hierarchy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Primary cluster').last);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points.length, lessThan(64));
      expect(series.points, isNotEmpty);
      expect(series.metadata, contains('heatmapClusterFocusRowRootId'));
      expect(series.metadata, contains('heatmapClusterFocusColumnRootId'));
      expect(
        series.points.every(
          (point) =>
              point.metadata?['heatmapClusterFocusRowIndex'] is int &&
              point.metadata?['heatmapClusterFocusColumnIndex'] is int,
        ),
        isTrue,
      );
      expect(find.textContaining('primary cluster'), findsWidgets);

      await tester.tap(find.text('Primary cluster').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full hierarchy').last);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series.points, hasLength(64));

      tester
          .widget<EnumOption<HeatmapDendrogramDistanceScale>>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-distance-scale'),
            ),
          )
          .onChanged(HeatmapDendrogramDistanceScale.proportional);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapDendrogramColumn'],
        containsPair('distanceScale', 'proportional'),
      );
      expect(
        find.text('Proportional distance · similar near matrix'),
        findsOneWidget,
      );

      tester
          .widget<EnumOption<StrokeCap>>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-cap')),
          )
          .onChanged(StrokeCap.square);
      tester
          .widget<EnumOption<StrokeJoin>>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-join')),
          )
          .onChanged(StrokeJoin.bevel);
      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-baseline')),
          )
          .onChanged(false);
      tester
          .widget<EnumOption<HeatmapDendrogramMarkerShape>>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-leaf-shape')),
          )
          .onChanged(HeatmapDendrogramMarkerShape.triangle);
      tester
          .widget<EnumOption<HeatmapDendrogramMarkerFill>>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-leaf-fill')),
          )
          .onChanged(HeatmapDendrogramMarkerFill.solid);
      tester
          .widget<EnumOption<HeatmapDendrogramMarkerShape>>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-merge-shape'),
            ),
          )
          .onChanged(HeatmapDendrogramMarkerShape.square);
      tester
          .widget<EnumOption<HeatmapDendrogramMarkerFill>>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-merge-fill')),
          )
          .onChanged(HeatmapDendrogramMarkerFill.hollow);
      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-dendrogram-ticks')),
          )
          .onChanged(false);
      final elbowSlider = tester.widget<Slider>(
        find.descendant(
          of: find.byKey(
            const ValueKey('heatmap-cluster-dendrogram-elbow-radius'),
          ),
          matching: find.byType(Slider),
        ),
      );
      elbowSlider.onChanged!(12);
      tester
          .widget<BoolOption>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-leaf-markers'),
            ),
          )
          .onChanged(false);
      tester
          .widget<BoolOption>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-leaf-labels'),
            ),
          )
          .onChanged(true);
      tester
          .widget<EnumOption<HeatmapDendrogramLabelDensity>>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-label-density'),
            ),
          )
          .onChanged(HeatmapDendrogramLabelDensity.sparse);
      tester
          .widget<EnumOption<HeatmapDendrogramLabelPlacement>>(
            find.byKey(
              const ValueKey('heatmap-cluster-dendrogram-label-placement'),
            ),
          )
          .onChanged(HeatmapDendrogramLabelPlacement.after);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('branchCap', 'square'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('branchJoin', 'bevel'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('showLeafBaseline', false),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('showLeafTicks', false),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('elbowRadius', 12.0),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('showLeafMarkers', false),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('leafMarkerShape', 'triangle'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('leafMarkerFill', 'solid'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('mergeMarkerShape', 'square'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('mergeMarkerFill', 'hollow'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('showLeafLabels', true),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('labelDensity', 'sparse'),
      );
      expect(
        series.metadata?['heatmapDendrogramColumnStyle'],
        containsPair('labelPlacement', 'after'),
      );

      final axisOption = tester.widget<EnumOption<HeatmapClusterAxisMode>>(
        find.byKey(const ValueKey('heatmap-cluster-axis-mode')),
      );
      axisOption.onChanged(HeatmapClusterAxisMode.rows);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('axisMode', 'rows'),
      );
      expect(
        series.metadata?['heatmapClusterColumnOrder'],
        List<int>.generate(8, (index) => index),
      );
      expect(series.metadata, contains('heatmapDendrogramRow'));
      expect(series.metadata, isNot(contains('heatmapDendrogramColumn')));
      expect(
        find.byKey(const ValueKey('heatmap-row-dendrogram')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-column-dendrogram')),
        findsNothing,
      );

      tester
          .widget<EnumOption<HeatmapClusterDistance>>(
            find.byKey(const ValueKey('heatmap-cluster-distance')),
          )
          .onChanged(HeatmapClusterDistance.euclidean);
      tester
          .widget<EnumOption<HeatmapClusterLinkage>>(
            find.byKey(const ValueKey('heatmap-cluster-linkage')),
          )
          .onChanged(HeatmapClusterLinkage.complete);
      tester
          .widget<EnumOption<HeatmapClusterMissingValueMode>>(
            find.byKey(const ValueKey('heatmap-cluster-missing-values')),
          )
          .onChanged(HeatmapClusterMissingValueMode.zero);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('distance', 'euclidean'),
      );
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('linkage', 'complete'),
      );
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('missingValueMode', 'zero'),
      );

      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-apply-order')),
          )
          .onChanged(false);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(
        series.metadata?['heatmapClusterConfig'],
        containsPair('axisMode', 'none'),
      );
      expect(
        series.metadata?['heatmapClusterRowOrder'],
        List<int>.generate(8, (index) => index),
      );
      expect(series.metadata, isNot(contains('heatmapDendrogramRow')));
      expect(series.metadata, isNot(contains('heatmapDendrogramColumn')));
      expect(
        find.byKey(const ValueKey('heatmap-row-dendrogram')),
        findsNothing,
      );

      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-cluster-apply-order')),
          )
          .onChanged(true);
      tester
          .widget<EnumOption<HeatmapClusterAxisMode>>(
            find.byKey(const ValueKey('heatmap-cluster-axis-mode')),
          )
          .onChanged(HeatmapClusterAxisMode.both);
      await tester.pumpAndSettle();

      final currentColumnDendrogram = tester
          .widgetList<HeatmapDendrogram>(find.byType(HeatmapDendrogram))
          .first;
      currentColumnDendrogram.onInteractionStateChanged!(
        HeatmapDendrogramInteractionState(
          selectedTarget: HeatmapDendrogramTargetIdentity(
            kind: HeatmapDendrogramHitKind.node,
            axis: HeatmapDendrogramAxis.columns,
            nodeId: currentColumnDendrogram.data.rootId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<ActionButton>(
            find.byKey(const ValueKey('heatmap-collapse-selected-hierarchy')),
          )
          .onPressed();
      await tester.pumpAndSettle();

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains("'heatmapClusterConfig':"));
      expect(source, contains("'heatmapClusterRowOrder':"));
      expect(source, contains("'heatmapClusterFocusRowOrder':"));
      expect(source, contains("'heatmapHierarchyReducer': 'sum'"));
      expect(source, contains("'heatmapHierarchyColumnCollapseState':"));
      expect(source, contains("'collapsedNodeIds':"));
      expect(source, contains(currentColumnDendrogram.data.rootId));
      expect(source, contains("'heatmapHierarchySourceColumnIndices':"));
      expect(source, contains("'heatmapHierarchySourceColumnLabels':"));
      expect(source, contains("'heatmapHierarchySourcePointKeys':"));
      expect(source, contains("'heatmapDendrogramRowStyle':"));
      expect(source, contains("'branchCap': 'square'"));
      expect(source, contains("'elbowRadius': 12.0"));
      expect(source, contains("'nodes':"));
      expect(source, contains("'showLeafLabels': true"));
      expect(source, contains("'labelDensity': 'sparse'"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Heatmap inspector updates the mounted chart configuration', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Calendar month'));
    await tester.pumpAndSettle();

    HeatmapChartSeries mountedSeries() {
      final chart = tester.widget<BravenChartPlus>(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-workbench')),
          matching: find.byType(BravenChartPlus),
        ),
      );
      return chart.series.single as HeatmapChartSeries;
    }

    expect(mountedSeries().colorScale.reverse, isFalse);
    final reverse = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Reverse palette'),
    );
    reverse.onChanged!(true);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.reverse, isTrue);

    final clamp = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Clamp to domain'),
    );
    clamp.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.clamp, isFalse);

    final domainSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 0 && slider.max == 10);
    domainSlider.onChanged!(4);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.minimumValue, 11);
    expect(mountedSeries().colorScale.maximumValue, 32);

    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunset').last);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.colors, const [
      Color(0xFFFFF7ED),
      Color(0xFFFDBA74),
      Color(0xFFEA580C),
      Color(0xFF7C2D12),
    ]);

    final legend = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show colour legend'),
    );
    legend.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.showLegend, isFalse);

    final labels = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Show cell values'),
    );
    labels.onChanged!(false);
    await tester.pumpAndSettle();
    expect(mountedSeries().showCellLabels, isFalse);

    final gapSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 0.06);
    gapSlider.onChanged!(0.2);
    await tester.pumpAndSettle();
    expect(mountedSeries().gapFraction, 0.2);

    final radiusSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.value == 3);
    radiusSlider.onChanged!(8);
    await tester.pumpAndSettle();
    expect(mountedSeries().cornerRadius, 8);

    await tester.tap(
      find.byKey(ValueKey('heatmap-missing-color-${Colors.red.toARGB32()}')),
    );
    await tester.pumpAndSettle();
    expect(mountedSeries().colorScale.missingColor, Colors.red);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Colour axes keep two Heatmap scales, filters, data, and source independent',
    (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Colour axes'));
      await tester.pumpAndSettle();

      List<HeatmapChartSeries> mountedSeries() {
        final chart = tester.widget<BravenChartPlus>(
          find.descendant(
            of: find.byKey(const ValueKey('heatmap-workbench')),
            matching: find.byType(BravenChartPlus),
          ),
        );
        return chart.series.whereType<HeatmapChartSeries>().toList();
      }

      var series = mountedSeries();
      expect(series, hasLength(2));
      expect(series[0].id, 'latency-axis');
      expect(series[0].unit, 'ms');
      expect(series[0].colorScale.maximumValue, 100);
      expect(series[1].id, 'error-rate-axis');
      expect(series[1].unit, '%');
      expect(series[1].colorScale.maximumValue, 3);
      expect(
        find.byKey(const ValueKey('heatmap-colour-axis-group')),
        findsOneWidget,
      );

      final legendGroup = tester.widget<HeatmapColorLegendGroup>(
        find.byKey(const ValueKey('heatmap-colour-axis-group')),
      );
      legendGroup.onValueFilterChanged!(
        'error-rate-axis',
        const HeatmapValueFilter(minimumValue: 0.5, maximumValue: 2),
      );
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series[0].valueFilter, isNull);
      expect(series[1].valueFilter?.minimumValue, 0.5);
      expect(series[1].valueFilter?.maximumValue, 2);

      tester
          .widget<BoolOption>(
            find.byKey(const ValueKey('heatmap-latency-axis-toggle')),
          )
          .onChanged(false);
      await tester.pumpAndSettle();
      series = mountedSeries();
      expect(series[0].colorScale.showLegend, isFalse);
      expect(series[1].colorScale.showLegend, isTrue);

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('heatmap-workbench')),
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains("id: 'latency-axis'"));
      expect(source, contains("unit: 'ms'"));
      expect(source, contains("id: 'error-rate-axis'"));
      expect(source, contains("unit: '%'"));
      expect(workbench.workbenchController!.sourceIsStale, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
