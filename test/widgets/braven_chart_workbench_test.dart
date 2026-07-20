import 'dart:async';
import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps one mounted chart while changing presentation modes', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    var initializations = 0;
    var disposals = 0;
    var chartBuilds = 0;

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        chartBuilder: (context, controller) {
          chartBuilds++;
          return _LifecycleProbe(
            onInit: () => initializations++,
            onDispose: () => disposals++,
            child: _chart(controller),
          );
        },
      ),
    );
    await tester.pump();

    expect(initializations, 1);
    expect(chartBuilds, 1);
    expect(workbenchController.tableSnapshot, isNull);
    expect(
      chartController.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );

    workbenchController.setDisplayMode(ChartDisplayMode.data);
    await tester.pumpAndSettle();

    expect(initializations, 1);
    expect(disposals, 0);
    expect(chartBuilds, 1);
    expect(workbenchController.tableSnapshot, isNotNull);
    expect(workbenchController.tableModel?.rowCount, 3);
    expect(
      chartController.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );

    workbenchController.setDisplayMode(ChartDisplayMode.chart);
    await tester.pumpAndSettle();

    expect(initializations, 1);
    expect(disposals, 0);
    expect(chartBuilds, 1);
  });

  testWidgets('keeps Source opt-in and rejects it when unavailable', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(_host(workbenchController: workbenchController));
    await tester.pumpAndSettle();

    expect(find.text('Source'), findsNothing);
    final result = workbenchController.setDisplayMode(ChartDisplayMode.source);
    expect(result, isA<ChartArtifactFailure<ChartDisplayMode>>());
    expect(workbenchController.effectiveMode, ChartDisplayMode.chart);
    expect(
      workbenchController.sourceState.phase,
      ChartWorkbenchSourcePhase.uninitialized,
    );
  });

  testWidgets(
    'generates Source without rebuilding the chart or requesting a table',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);
      var initializations = 0;
      var disposals = 0;
      var chartBuilds = 0;

      await tester.pumpWidget(
        _host(
          chartController: chartController,
          workbenchController: workbenchController,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          chartBuilder: (context, controller) {
            chartBuilds++;
            return _LifecycleProbe(
              onInit: () => initializations++,
              onDispose: () => disposals++,
              child: _chart(controller),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Source'));
      await tester.pumpAndSettle();

      expect(workbenchController.effectiveMode, ChartDisplayMode.source);
      expect(
        workbenchController.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      expect(
        workbenchController.generatedSource?.source,
        contains('final chart'),
      );
      expect(
        workbenchController.generatedSource?.source,
        contains('LineChartSeries('),
      );
      expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
      expect(
        workbenchController.tableState.phase,
        ChartWorkbenchTablePhase.uninitialized,
      );
      expect(initializations, 1);
      expect(disposals, 0);
      expect(chartBuilds, 1);
      expect(
        chartController.extractDocument(),
        isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
      );
    },
  );

  testWidgets('source placeholders preserve fail-closed artifact extraction', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.source,
        },
        chartBuilder: (context, controller) {
          final runtimeSeries = LineChartSeries(
            id: 'runtime',
            points: const [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 12),
            ],
            dataPointLabels: DataPointLabelConfig(
              show: true,
              formatter: (point) => '${point.y} runtime',
            ),
          );
          return BravenChartPlus(
            bravenChartController: controller,
            showLegend: false,
            xAxisConfig: XAxisConfig(
              label: 'Elapsed',
              labelFormatter: (value) => '${value.toStringAsFixed(1)} h',
            ),
            interactionConfig: InteractionConfig(
              onDataPointTap: (point, position) {},
              tooltip: TooltipConfig(
                customBuilder: (context, dataPoint) => const Text('Custom'),
              ),
            ),
            series: [runtimeSeries],
            annotations: [
              LegendAnnotation(
                id: 'runtime-legend',
                series: [runtimeSeries],
                onSeriesToggle: (seriesId) {},
              ),
            ],
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final portable = chartController.extractDocument();
    expect(portable, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    expect(
      (portable as ChartArtifactFailure<ChartDocumentSnapshot>).error.code,
      ChartArtifactDiagnosticCodes.runtimeBindingRequired,
    );

    workbenchController.setDisplayMode(ChartDisplayMode.source);
    await tester.pumpAndSettle();

    expect(
      workbenchController.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    expect(
      workbenchController.sourceState.warnings,
      contains(
        isA<ChartArtifactWarning>().having(
          (warning) => warning.path,
          'path',
          r'$.series.runtime.dataPointLabels.formatter',
        ),
      ),
    );
    expect(
      workbenchController.sourceState.warnings,
      contains(
        isA<ChartArtifactWarning>().having(
          (warning) => warning.path,
          'path',
          r'$.annotations.legend.onSeriesToggle',
        ),
      ),
    );
    expect(
      workbenchController.generatedSource?.source,
      contains('dataPointLabels: DataPointLabelConfig('),
    );
    expect(
      workbenchController.generatedSource?.source,
      contains('Runtime interaction bindings omitted:'),
    );
    expect(
      workbenchController.generatedSource?.source,
      contains('LegendAnnotation('),
    );
    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
  });

  testWidgets('retains usable source through a failed refresh and retry', (
    tester,
  ) async {
    final chartController = _ControlledExtractionController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.source,
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.source,
        },
      ),
    );
    await tester.pumpAndSettle();
    final usableSource = workbenchController.generatedSource;
    expect(usableSource, isNotNull);

    chartController.failNextSource = true;
    workbenchController.refreshSource();
    expect(
      workbenchController.sourceState.phase,
      ChartWorkbenchSourcePhase.refreshing,
    );
    await tester.pumpAndSettle();

    expect(
      workbenchController.sourceState.phase,
      ChartWorkbenchSourcePhase.failed,
    );
    expect(workbenchController.generatedSource, same(usableSource));
    expect(workbenchController.sourceIsStale, isTrue);
    expect(find.text('Retry refresh'), findsOneWidget);
    expect(
      find.textContaining('previous source is still shown'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry refresh'));
    await tester.pumpAndSettle();
    expect(
      workbenchController.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    expect(workbenchController.sourceIsStale, isFalse);
  });

  testWidgets('marks manual source stale until explicitly refreshed', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.source,
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.source,
        },
        sourceRefreshPolicy: ChartSourceRefreshPolicy.manual,
        chartValue: 11,
      ),
    );
    await tester.pumpAndSettle();
    final firstSource = workbenchController.generatedSource!;

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.source,
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.source,
        },
        sourceRefreshPolicy: ChartSourceRefreshPolicy.manual,
        chartValue: 42,
      ),
    );
    await tester.pump();

    expect(workbenchController.sourceIsStale, isTrue);
    expect(workbenchController.generatedSource, same(firstSource));
    expect(
      find.text('The chart changed after this source was generated.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Refresh source').first);
    await tester.pumpAndSettle();
    expect(workbenchController.sourceIsStale, isFalse);
    expect(workbenchController.generatedSource, isNot(same(firstSource)));
    expect(workbenchController.generatedSource?.source, contains('y: 42.0'));
  });

  testWidgets(
    'keeps visible Source synchronized with effective chart changes by default',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      final defaults = BravenChartWorkbench(
        chartBuilder: (context, controller) => _chart(controller),
      );
      expect(
        defaults.sourceRefreshPolicy,
        ChartSourceRefreshPolicy.onDocumentRevision,
      );

      await tester.pumpWidget(
        _host(
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          chartValue: 11,
          chartTitle: 'Initial chart options',
        ),
      );
      await tester.pumpAndSettle();
      final firstSource = workbenchController.generatedSource;
      expect(firstSource?.source, contains('y: 11.0'));
      expect(firstSource?.source, contains("title: 'Initial chart options'"));

      await tester.pumpWidget(
        _host(
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          chartValue: 42,
          chartTitle: 'Updated chart options',
        ),
      );
      await tester.pump();

      expect(
        find.text('The chart changed after this source was generated.'),
        findsNothing,
      );
      expect(find.text('Chart changed'), findsNothing);
      expect(find.text('Refresh source'), findsNothing);

      await tester.pumpAndSettle();
      expect(workbenchController.sourceIsStale, isFalse);
      expect(workbenchController.generatedSource, isNot(same(firstSource)));
      expect(workbenchController.generatedSource?.source, contains('y: 42.0'));
      expect(
        workbenchController.generatedSource?.source,
        contains("title: 'Updated chart options'"),
      );
    },
  );

  testWidgets(
    'keeps generated source current across layout-only parent rebuilds',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        _host(
          width: 720,
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          sourceRefreshPolicy: ChartSourceRefreshPolicy.manual,
          chartValue: 11,
        ),
      );
      await tester.pumpAndSettle();
      final generated = workbenchController.generatedSource;
      expect(generated, isNotNull);
      expect(workbenchController.sourceIsStale, isFalse);

      await tester.pumpWidget(
        _host(
          width: 840,
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          sourceRefreshPolicy: ChartSourceRefreshPolicy.manual,
          chartValue: 11,
        ),
      );
      await tester.pumpAndSettle();

      expect(workbenchController.generatedSource, same(generated));
      expect(workbenchController.sourceIsStale, isFalse);
      expect(
        find.text('The chart changed after this source was generated.'),
        findsNothing,
      );
    },
  );

  testWidgets('exposes Source as a 48px keyboard-operable presentation', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        width: 720,
        workbenchController: workbenchController,
        availableDisplayModes: const {
          ChartDisplayMode.chart,
          ChartDisplayMode.data,
          ChartDisplayMode.source,
        },
      ),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    expect(tester.getSize(switcher).height, greaterThanOrEqualTo(48));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Chart presentation',
      ),
      findsOneWidget,
    );

    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      if (workbenchController.requestedMode == ChartDisplayMode.source) break;
    }

    expect(workbenchController.requestedMode, ChartDisplayMode.source);
    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
  });

  testWidgets('captures the same chart preview from Chart, Data, and Split', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(_host(workbenchController: workbenchController));
    await tester.pumpAndSettle();

    final hashes = <String>[];
    for (final mode in ChartDisplayMode.values) {
      workbenchController.setDisplayMode(mode);
      await tester.pumpAndSettle();
      final result = await _capture(
        tester,
        workbenchController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'workbench-${mode.name}-mode',
            createdAt: DateTime.utc(2026, 7, 15, 12),
            includePreview: true,
            previewOptions: const ChartPreviewOptions(pixelRatio: 1),
          ),
        ),
      );

      final success = result as ChartArtifactSuccess<ChartArtifact>;
      final preview = success.value.preview!;
      expect(preview.bytes, isNotEmpty, reason: '${mode.name} preview');
      expect(
        preview.documentHash,
        ChartArtifactCanonicalizer.documentHash(success.value.document),
      );
      expect(success.warnings, isEmpty);
      hashes.add(preview.documentHash);
    }

    expect(hashes.toSet(), hasLength(1));
  });

  testWidgets('preserves effective chart state across every display mode', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    final annotationController = AnnotationController(
      initialAnnotations: [
        ThresholdAnnotation(
          id: 'target',
          axis: AnnotationAxis.y,
          value: 12,
          label: 'Target',
        ),
      ],
    );
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);
    addTearDown(annotationController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          annotationController: annotationController,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'signal',
              points: [
                ChartDataPoint(x: 0, y: 10),
                ChartDataPoint(x: 1, y: 12),
                ChartDataPoint(x: 2, y: 11),
              ],
            ),
            LineChartSeries(
              id: 'comparison',
              points: [
                ChartDataPoint(x: 0, y: 8),
                ChartDataPoint(x: 1, y: 9),
                ChartDataPoint(x: 2, y: 10),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    chartController.restoreViewState(
      ChartViewState(
        visibleBounds: const ChartBoundsDocument(
          xMin: 0.5,
          xMax: 1.5,
          yMin: 8,
          yMax: 13,
        ),
        hiddenSeriesIds: const {'comparison'},
        selectedSeriesId: 'signal',
        selectedPointRefs: const [
          ChartPointRef(seriesId: 'signal', pointIndex: 1),
        ],
        selectedAnnotationId: 'target',
      ),
    );
    await tester.pumpAndSettle();

    for (final mode in [
      ChartDisplayMode.data,
      ChartDisplayMode.split,
      ChartDisplayMode.chart,
    ]) {
      workbenchController.setDisplayMode(mode);
      await tester.pumpAndSettle();
    }

    final extracted =
        chartController.extractDocument()
            as ChartArtifactSuccess<ChartDocumentSnapshot>;
    final state = extracted.value.viewState!;
    expect(state.hiddenSeriesIds, {'comparison'});
    expect(state.selectedSeriesId, 'signal');
    expect(state.selectedPointRefs, const [
      ChartPointRef(seriesId: 'signal', pointIndex: 1),
    ]);
    expect(state.selectedAnnotationId, 'target');
    expect(state.visibleBounds?.xMin, closeTo(0.5, 0.001));
    expect(state.visibleBounds?.xMax, closeTo(1.5, 0.001));
    expect(extracted.value.document.annotations.single.id, 'target');
    expect(annotationController.annotations.single.id, 'target');
  });

  testWidgets('preserves requested Split while compact layout uses one pane', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        width: 480,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.split,
        splitBreakpoint: 600,
      ),
    );
    await tester.pumpAndSettle();

    expect(workbenchController.requestedMode, ChartDisplayMode.split);
    expect(workbenchController.effectiveMode, ChartDisplayMode.chart);
    expect(find.text('Split resumes when more space is available'), findsOne);

    await tester.pumpWidget(
      _host(
        width: 700,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.split,
        splitBreakpoint: 600,
      ),
    );
    await tester.pumpAndSettle();

    expect(workbenchController.requestedMode, ChartDisplayMode.split);
    expect(workbenchController.effectiveMode, ChartDisplayMode.split);
  });

  testWidgets('auto-fits and resizes the Split data pane without remounting', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        width: 1200,
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.split,
        splitBreakpoint: 600,
        autoFitTablePane: true,
      ),
    );
    await tester.pumpAndSettle();

    final chartFinder = find.byKey(const ValueKey('chart-workbench-chart'));
    final tableFinder = find.byType(ChartDataTable);
    final handleFinder = find.byKey(
      const ValueKey('chart-workbench-split-handle'),
    );
    final initialChartWidth = tester.getSize(chartFinder).width;
    final initialTableWidth = tester.getSize(tableFinder).width;
    final preferredTableWidth = ChartDataTable.preferredWidthFor(
      model: workbenchController.tableModel!,
    );

    expect(handleFinder, findsOneWidget);
    expect(tester.getSize(handleFinder).width, 12);
    expect(initialTableWidth, closeTo(math.max(360, preferredTableWidth), 0.1));
    expect(initialChartWidth, greaterThan(initialTableWidth));

    await tester.drag(handleFinder, const Offset(-120, 0));
    await tester.pumpAndSettle();
    final draggedChartWidth = tester.getSize(chartFinder).width;
    expect(draggedChartWidth, lessThan(initialChartWidth - 80));
    expect(tester.getSize(tableFinder).width, greaterThan(initialTableWidth));

    await tester.tap(handleFinder);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, greaterThan(draggedChartWidth));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.getSize(chartFinder).width, closeTo(initialChartWidth, 0.1));
    expect(
      chartController.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports large text, high contrast, and keyboard-only modes', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        width: 620,
        height: 720,
        workbenchController: workbenchController,
        textScaler: const TextScaler.linear(2),
        highContrast: true,
      ),
    );
    await tester.pumpAndSettle();

    final presentation = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Chart presentation',
      ),
    );
    expect(presentation.properties.label, 'Chart presentation');

    for (var attempt = 0; attempt < 6; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      if (workbenchController.requestedMode == ChartDisplayMode.data) break;
    }

    expect(workbenchController.requestedMode, ChartDisplayMode.data);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps caller-owned controllers alive after unmount', (
    tester,
  ) async {
    final chartController = _TrackingChartController();
    final workbenchController = _TrackingWorkbenchController();

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(chartController.wasDisposed, isFalse);
    expect(workbenchController.wasDisposed, isFalse);

    chartController.dispose();
    workbenchController.dispose();
  });

  testWidgets('detaches a package-owned chart controller after unmount', (
    tester,
  ) async {
    BravenChartController? ownedController;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 560,
          child: BravenChartWorkbench(
            chartBuilder: (context, controller) => _chart(controller),
            actionsBuilder: (context, handle) {
              ownedController = handle.chartController;
              return const [];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      ownedController!.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    final detached = ownedController!.extractDocument();
    expect(detached, isA<ChartArtifactFailure<ChartDocumentSnapshot>>());
    expect(
      (detached as ChartArtifactFailure<ChartDocumentSnapshot>).error.code,
      ChartArtifactDiagnosticCodes.chartNotAttached,
    );
  });

  testWidgets('keeps two mounted workbenches completely independent', (
    tester,
  ) async {
    final leftChart = BravenChartController();
    final rightChart = BravenChartController();
    final leftWorkbench = ChartWorkbenchController();
    final rightWorkbench = ChartWorkbenchController();
    addTearDown(leftChart.dispose);
    addTearDown(rightChart.dispose);
    addTearDown(leftWorkbench.dispose);
    addTearDown(rightWorkbench.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 560,
            child: Row(
              children: [
                Expanded(
                  child: BravenChartWorkbench(
                    chartController: leftChart,
                    workbenchController: leftWorkbench,
                    chartBuilder: (context, controller) => _chart(controller),
                  ),
                ),
                Expanded(
                  child: BravenChartWorkbench(
                    chartController: rightChart,
                    workbenchController: rightWorkbench,
                    chartBuilder: (context, controller) => _chart(controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    leftChart.setSeriesVisible('signal', false);
    leftWorkbench.setDisplayMode(ChartDisplayMode.data);
    await tester.pumpAndSettle();

    expect(leftChart.hiddenSeriesIds, {'signal'});
    expect(rightChart.hiddenSeriesIds, isEmpty);
    expect(leftWorkbench.tableSnapshot?.viewState?.hiddenSeriesIds, {'signal'});
    expect(rightWorkbench.tableSnapshot, isNull);
    expect(
      rightChart.extractDocument(),
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    );
  });

  testWidgets('gives custom actions one stable imperative handle', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);
    ChartWorkbenchHandle? firstHandle;
    var builds = 0;

    await tester.pumpWidget(
      _host(
        workbenchController: workbenchController,
        actionsBuilder: (context, handle) {
          firstHandle ??= handle;
          expect(identical(handle, firstHandle), isTrue);
          builds++;
          return const [
            IconButton(
              key: ValueKey('host-action'),
              tooltip: 'Save chart',
              onPressed: null,
              icon: Icon(Icons.bookmark_add_outlined),
            ),
          ];
        },
      ),
    );
    await tester.pump();

    expect(firstHandle, same(workbenchController));
    expect(find.byKey(const ValueKey('host-action')), findsOneWidget);

    workbenchController.setDisplayMode(ChartDisplayMode.data);
    await tester.pumpAndSettle();

    expect(builds, greaterThan(1));
    expect(firstHandle, same(workbenchController));
  });

  testWidgets(
    'gives visible and context actions the same stable Workbench handle',
    (tester) async {
      final workbenchController = ChartWorkbenchController();
      addTearDown(workbenchController.dispose);
      ChartWorkbenchHandle? visibleHandle;
      ChartWorkbenchHandle? contextHandle;
      ChartWorkbenchHandle? overlayHandle;
      ChartContextInvocation? invocation;
      ChartArtifactResult<ChartArtifact>? artifactResult;

      await tester.pumpWidget(
        _host(
          workbenchController: workbenchController,
          actionsBuilder: (context, handle) {
            visibleHandle = handle;
            return const [];
          },
          contextActionsBuilder: (context, handle, value) {
            contextHandle = handle;
            invocation = value;
            return [
              ChartContextAction(
                id: 'host.addToCollection',
                label: 'Add to collection',
                icon: Icons.collections_bookmark_outlined,
                onSelected: () async {
                  artifactResult = await handle.extractArtifact(
                    const ChartArtifactExtractOptions(
                      artifactId: 'context-action-artifact',
                      includePreview: false,
                    ),
                  );
                },
              ),
            ];
          },
          chartActionButtonBuilder: (context, handle) {
            overlayHandle = handle;
            return ChartOverlayAction(
              id: 'host.addToCollection',
              tooltip: 'Add chart to collection',
              icon: Icons.collections_bookmark_outlined,
              onPressed: () {},
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      final position = renderBox.localToGlobal(
        renderBox.plotToWidget(
          Offset(renderBox.plotWidth / 2, renderBox.plotHeight / 2),
        ),
      );
      final gesture = await tester.startGesture(
        position,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(visibleHandle, same(workbenchController));
      expect(contextHandle, same(workbenchController));
      expect(contextHandle, same(visibleHandle));
      expect(overlayHandle, same(workbenchController));
      expect(
        find.byKey(
          const ValueKey('chart-overlay-action-button-host.addToCollection'),
        ),
        findsOneWidget,
      );
      expect(invocation?.source, ChartContextInvocationSource.secondaryClick);
      expect(find.text('Add to collection'), findsOneWidget);

      await tester.tap(find.text('Add to collection'));
      await tester.pumpAndSettle();

      expect(artifactResult, isA<ChartArtifactSuccess<ChartArtifact>>());
    },
  );

  testWidgets('rejects duplicate artifact extraction without changing table', (
    tester,
  ) async {
    final chartController = _DelayedArtifactController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
      ),
    );
    await tester.pumpAndSettle();
    final tableSnapshot = workbenchController.tableSnapshot;

    final first = workbenchController.extractArtifact(
      const ChartArtifactExtractOptions(
        artifactId: 'first-capture',
        includePreview: false,
      ),
    );
    await tester.pump();
    expect(
      workbenchController.artifactState.phase,
      ChartWorkbenchArtifactPhase.extracting,
    );

    final duplicate = await workbenchController.extractArtifact(
      const ChartArtifactExtractOptions(
        artifactId: 'duplicate-capture',
        includePreview: false,
      ),
    );
    expect(duplicate, isA<ChartArtifactFailure<ChartArtifact>>());
    expect(
      (duplicate as ChartArtifactFailure<ChartArtifact>).error.code,
      ChartArtifactDiagnosticCodes.captureInProgress,
    );

    chartController.release();
    final completed = await first;
    expect(completed, isA<ChartArtifactSuccess<ChartArtifact>>());
    expect(
      workbenchController.artifactState.phase,
      ChartWorkbenchArtifactPhase.succeeded,
    );
    expect(workbenchController.tableSnapshot, same(tableSnapshot));
    expect(workbenchController.tableState.error, isNull);
  });

  testWidgets('returns a structured failure for a host-disabled mode', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        workbenchController: workbenchController,
        availableDisplayModes: const {ChartDisplayMode.chart},
      ),
    );
    await tester.pump();

    final result = workbenchController.setDisplayMode(ChartDisplayMode.data);

    expect(result, isA<ChartArtifactFailure<ChartDisplayMode>>());
    expect(
      (result as ChartArtifactFailure<ChartDisplayMode>).error.code,
      ChartArtifactDiagnosticCodes.requestedDisplayModeUnavailable,
    );
    expect(workbenchController.requestedMode, ChartDisplayMode.chart);
  });

  testWidgets(
    'manual policy captures on first use without mode-entry refresh',
    (tester) async {
      final workbenchController = ChartWorkbenchController();
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        _host(
          workbenchController: workbenchController,
          tableRefreshPolicy: ChartTableRefreshPolicy.manual,
        ),
      );
      await tester.pump();

      workbenchController.setDisplayMode(ChartDisplayMode.data);
      await tester.pumpAndSettle();
      final firstSnapshot = workbenchController.tableSnapshot;
      expect(firstSnapshot, isNotNull);

      workbenchController.setDisplayMode(ChartDisplayMode.chart);
      await tester.pumpAndSettle();
      workbenchController.setDisplayMode(ChartDisplayMode.data);
      await tester.pumpAndSettle();

      expect(workbenchController.tableSnapshot, same(firstSnapshot));
    },
  );

  testWidgets('table snapshot equals direct extraction at the same revision', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    const documentOptions = ChartDocumentExtractOptions(
      documentId: 'workbench-contract',
      includeViewState: true,
    );
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        documentOptions: documentOptions,
      ),
    );
    await tester.pumpAndSettle();

    final tableSnapshot = workbenchController.tableSnapshot!;
    final direct =
        chartController.extractDocument(documentOptions)
            as ChartArtifactSuccess<ChartDocumentSnapshot>;
    expect(tableSnapshot.revision, direct.value.revision);
    expect(
      ChartArtifactCanonicalizer.documentHash(tableSnapshot.document),
      ChartArtifactCanonicalizer.documentHash(direct.value.document),
    );
    expect(
      ChartArtifactCanonicalizer.viewHash(
        tableSnapshot.document,
        tableSnapshot.viewState,
      ),
      ChartArtifactCanonicalizer.viewHash(
        direct.value.document,
        direct.value.viewState,
      ),
    );
  });

  testWidgets('uses explicit runtime formatter descriptors inside workbench', (
    tester,
  ) async {
    final workbenchController = ChartWorkbenchController();
    final formatter = ChartFormatterDescriptor(
      id: 'braven.number.fixed',
      arguments: {'decimals': JsonNumberValue(2)},
    ).toDocument();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'formatter-contract',
          yAxisFormatterDescriptors: {'y': formatter},
        ),
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Signal',
            labelFormatter: (value) => value.toStringAsFixed(2),
          ),
          series: const [
            LineChartSeries(
              id: 'signal',
              points: [ChartDataPoint(x: 0, y: 10)],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(workbenchController.tableModel?.longRows.single.yDisplay, '10.00');
    expect(workbenchController.tableState.warnings, isEmpty);
  });

  testWidgets('coalesces concurrent table refresh requests', (tester) async {
    final workbenchController = ChartWorkbenchController();
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(_host(workbenchController: workbenchController));
    await tester.pump();

    final first = workbenchController.refreshTable();
    final second = workbenchController.refreshTable();
    expect(second, same(first));

    await tester.pumpAndSettle();
    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.ready,
    );
    expect(workbenchController.tableSnapshot, isNotNull);
  });

  testWidgets('links one wide table row to every chart point it represents', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'power',
              points: [
                ChartDataPoint(x: 0, y: 220),
                ChartDataPoint(x: 1, y: 240),
              ],
            ),
            LineChartSeries(
              id: 'heart-rate',
              points: [
                ChartDataPoint(x: 0, y: 130),
                ChartDataPoint(x: 1, y: 135),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final model = workbenchController.tableModel!;
    final firstRow = find.byKey(ValueKey(model.wideRows.first.rowId));
    final detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: firstRow,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();

    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });
    final selectedSurface = tester.widget<Container>(
      find.descendant(of: firstRow, matching: find.byType(Container)).first,
    );
    final selectionBorder =
        (selectedSurface.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(selectionBorder.left.width, 4);
    final semantics = tester.widget<Semantics>(
      find.descendant(of: firstRow, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.selected, isTrue);
    final captured =
        chartController.extractDocument()
            as ChartArtifactSuccess<ChartDocumentSnapshot>;
    expect(captured.value.viewState?.selectedPointRefs.toSet(), {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });

    detector.focusNode?.unfocus();
    await tester.pump();
    expect(chartController.focusedPointRefs, isEmpty);
  });

  testWidgets('Ctrl activation additively toggles complete wide rows', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'power',
              points: [
                ChartDataPoint(x: 0, y: 220),
                ChartDataPoint(x: 1, y: 240),
              ],
            ),
            LineChartSeries(
              id: 'heart-rate',
              points: [
                ChartDataPoint(x: 0, y: 130),
                ChartDataPoint(x: 1, y: 135),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder rowAt(int index) => find.byKey(
      ValueKey(workbenchController.tableModel!.wideRows[index].rowId),
    );

    await tester.tap(rowAt(0));
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(rowAt(1));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
      const ChartPointRef(seriesId: 'power', pointIndex: 1),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 1),
    });

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(rowAt(0));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 1),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 1),
    });
    expect(find.textContaining('2 selected'), findsOneWidget);

    await tester.tap(find.text('Clear selection'));
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, isEmpty);
    expect(find.textContaining('selected'), findsNothing);
    expect(workbenchController.tableIsStale, isFalse);

    await tester.tap(rowAt(0));
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });
  });

  testWidgets('Ctrl+A selects the displayed dataset and Escape clears it', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'power',
              points: [
                ChartDataPoint(x: 0, y: 220),
                ChartDataPoint(x: 1, y: 240),
              ],
            ),
            LineChartSeries(
              id: 'heart-rate',
              points: [
                ChartDataPoint(x: 0, y: 130),
                ChartDataPoint(x: 1, y: 135),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstRow = find.byKey(
      ValueKey(workbenchController.tableModel!.wideRows.first.rowId),
    );
    final detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: firstRow,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
      const ChartPointRef(seriesId: 'power', pointIndex: 1),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 1),
    });
    expect(find.textContaining('4 selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, isEmpty);
    expect(workbenchController.tableIsStale, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    });
  });

  testWidgets('Shift activation selects a range across snapshot refreshes', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'power',
              points: [
                ChartDataPoint(x: 0, y: 220),
                ChartDataPoint(x: 1, y: 230),
                ChartDataPoint(x: 2, y: 240),
                ChartDataPoint(x: 3, y: 250),
              ],
            ),
            LineChartSeries(
              id: 'heart-rate',
              points: [
                ChartDataPoint(x: 0, y: 130),
                ChartDataPoint(x: 1, y: 135),
                ChartDataPoint(x: 2, y: 140),
                ChartDataPoint(x: 3, y: 145),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder rowAt(int index) => find.byKey(
      ValueKey(workbenchController.tableModel!.wideRows[index].rowId),
    );

    await tester.tap(rowAt(0));
    await tester.pumpAndSettle();
    final targetDetector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: rowAt(2),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    targetDetector.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(chartController.selectedPointRefs, {
      for (final seriesId in const ['power', 'heart-rate'])
        for (var pointIndex = 0; pointIndex <= 2; pointIndex++)
          ChartPointRef(seriesId: seriesId, pointIndex: pointIndex),
    });
    expect(find.textContaining('6 selected'), findsOneWidget);
    expect(workbenchController.tableIsStale, isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(rowAt(3));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(chartController.selectedPointRefs, hasLength(8));
    expect(find.textContaining('8 selected'), findsOneWidget);
  });

  testWidgets('boundary keys navigate linked virtualized chart points', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        height: 360,
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: [
            LineChartSeries(
              id: 'signal',
              points: [
                for (var index = 0; index < 100; index++)
                  ChartDataPoint(x: index.toDouble(), y: index.toDouble()),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final model = workbenchController.tableModel!;
    Finder rowAt(int index) =>
        find.byKey(ValueKey(model.wideRows[index].rowId));
    FocusableActionDetector detectorAt(int index) =>
        tester.widget<FocusableActionDetector>(
          find.descendant(
            of: rowAt(index),
            matching: find.byType(FocusableActionDetector),
          ),
        );

    detectorAt(0).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(rowAt(99), findsOneWidget);
    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 99),
    });

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(rowAt(0), findsOneWidget);
    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });
  });

  testWidgets('row hover temporarily overrides and restores keyboard focus', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
      ),
    );
    await tester.pumpAndSettle();

    final model = workbenchController.tableModel!;
    final firstRow = find.byKey(ValueKey(model.wideRows.first.rowId));
    final secondRow = find.byKey(ValueKey(model.wideRows[1].rowId));
    final firstDetector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: firstRow,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    firstDetector.focusNode!.requestFocus();
    await tester.pump();
    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(secondRow));
    await tester.pump();
    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 1),
    });

    await mouse.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      ),
    );
    await tester.pump();
    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });

    firstDetector.focusNode!.unfocus();
    await tester.pump();
    expect(chartController.focusedPointRefs, isEmpty);
  });

  testWidgets(
    'reveals a point selected directly through the chart controller',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        _host(
          height: 360,
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.data,
          chartBuilder: (context, controller) => BravenChartPlus(
            bravenChartController: controller,
            showLegend: false,
            series: [
              LineChartSeries(
                id: 'signal',
                points: [
                  for (var index = 0; index < 100; index++)
                    ChartDataPoint(x: index.toDouble(), y: index.toDouble()),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final model = workbenchController.tableModel!;
      final targetRow = find.byKey(ValueKey(model.wideRows[90].rowId));
      expect(targetRow, findsNothing);
      final result = chartController.selectPoint(
        const ChartPointRef(seriesId: 'signal', pointIndex: 90),
        revision: workbenchController.tableSnapshot!.revision,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
      expect(table.selectedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 90),
      });
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.controller!.offset, greaterThan(3000));
      expect(targetRow, findsOneWidget);
      expect(chartController.selectedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 90),
      });
    },
  );

  testWidgets(
    'reveals transient chart focus in the table without selecting the row',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        _host(
          height: 360,
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.data,
          chartBuilder: (context, controller) => BravenChartPlus(
            bravenChartController: controller,
            showLegend: false,
            series: [
              LineChartSeries(
                id: 'signal',
                points: [
                  for (var index = 0; index < 100; index++)
                    ChartDataPoint(x: index.toDouble(), y: index.toDouble()),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final model = workbenchController.tableModel!;
      final targetRow = find.byKey(ValueKey(model.wideRows[80].rowId));
      expect(targetRow, findsNothing);
      final result = chartController.focusPoint(
        const ChartPointRef(seriesId: 'signal', pointIndex: 80),
        revision: workbenchController.tableSnapshot!.revision,
      );
      expect(result, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();

      final table = tester.widget<ChartDataTable>(find.byType(ChartDataTable));
      expect(table.focusedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 80),
      });
      expect(table.selectedPointRefs, isEmpty);
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.controller!.offset, greaterThan(2500));
      expect(targetRow, findsOneWidget);
      expect(chartController.selectedPointRefs, isEmpty);
      final semantics = tester.widget<Semantics>(
        find.descendant(of: targetRow, matching: find.byType(Semantics)).first,
      );
      expect(semantics.properties.focused, isFalse);
      expect(semantics.properties.selected, isFalse);
    },
  );

  testWidgets('links one long table row to exactly one chart point', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableOptions: const ChartTableOptions(
          rowLayout: ChartTableRowLayout.long,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final model = workbenchController.tableModel!;
    final firstRow = find.byKey(ValueKey(model.longRows.first.rowId));
    final detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: firstRow,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();

    expect(chartController.focusedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });
  });

  testWidgets('keeps manual table links current across repeated selections', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableRefreshPolicy: ChartTableRefreshPolicy.manual,
      ),
    );
    await tester.pumpAndSettle();

    Future<void> activateRow(int index) async {
      final model = workbenchController.tableModel!;
      final row = find.byKey(ValueKey(model.wideRows[index].rowId));
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: row,
          matching: find.byType(FocusableActionDetector),
        ),
      );
      detector.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await activateRow(0);
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 0),
    });
    expect(workbenchController.tableIsStale, isFalse);
    expect(
      find.text(
        'The point reference belongs to an older chart document revision.',
      ),
      findsNothing,
    );

    await activateRow(1);
    expect(chartController.selectedPointRefs, {
      const ChartPointRef(seriesId: 'signal', pointIndex: 1),
    });
    expect(workbenchController.tableIsStale, isFalse);
    expect(
      find.text(
        'The point reference belongs to an older chart document revision.',
      ),
      findsNothing,
    );
  });

  testWidgets('shows an initial extraction failure and recovers on retry', (
    tester,
  ) async {
    final chartController = _ControlledExtractionController()
      ..failNextDocument = true;
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.failed,
    );
    expect(workbenchController.tableModel, isNull);
    expect(find.text('Retry table'), findsOneWidget);
    expect(find.textContaining('Demo table refresh failed'), findsWidgets);

    await tester.tap(find.text('Retry table'));
    await tester.pumpAndSettle();

    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.ready,
    );
    expect(workbenchController.tableModel?.rowCount, 3);
    expect(find.text('Retry table'), findsNothing);
  });

  testWidgets('retains a usable table through warning and failed refresh', (
    tester,
  ) async {
    final chartController = _ControlledExtractionController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
      ),
    );
    await tester.pumpAndSettle();
    chartController.warnNextDocument = true;
    workbenchController.refreshTable();
    await tester.pumpAndSettle();
    expect(workbenchController.tableState.warnings, hasLength(1));
    expect(find.textContaining('Demo values were rounded'), findsOneWidget);
    final usableModel = workbenchController.tableModel;

    chartController.failNextDocument = true;
    workbenchController.refreshTable();
    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.refreshing,
    );
    await tester.pumpAndSettle();

    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.failed,
    );
    expect(workbenchController.tableModel, same(usableModel));
    expect(workbenchController.tableIsStale, isTrue);
    expect(find.text('Retry refresh'), findsOneWidget);
    expect(
      find.textContaining('previous table is still shown'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry refresh'));
    await tester.pumpAndSettle();
    expect(
      workbenchController.tableState.phase,
      ChartWorkbenchTablePhase.ready,
    );
    expect(workbenchController.tableIsStale, isFalse);
  });

  testWidgets('marks a manual table stale until the host refreshes it', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableRefreshPolicy: ChartTableRefreshPolicy.manual,
        chartValue: 11,
      ),
    );
    await tester.pumpAndSettle();
    final firstSnapshot = workbenchController.tableSnapshot!;
    expect(
      firstSnapshot.revision,
      chartController.effectiveDocumentRevision.value,
    );

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableRefreshPolicy: ChartTableRefreshPolicy.manual,
        chartValue: 42,
      ),
    );
    await tester.pump();

    expect(workbenchController.tableIsStale, isTrue);
    expect(workbenchController.tableSnapshot, same(firstSnapshot));
    expect(
      find.text('The chart changed after this table snapshot was captured.'),
      findsOneWidget,
    );

    final staleModel = workbenchController.tableModel!;
    tester
        .widget<FocusableActionDetector>(
          find.descendant(
            of: find.byKey(ValueKey(staleModel.wideRows.first.rowId)),
            matching: find.byType(FocusableActionDetector),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    expect(chartController.focusedPointRefs, isEmpty);
    expect(
      find.text(
        'The point reference belongs to an older chart document revision.',
      ),
      findsOneWidget,
    );

    workbenchController.refreshTable();
    await tester.pumpAndSettle();

    expect(workbenchController.tableIsStale, isFalse);
    expect(workbenchController.tableSnapshot, isNot(same(firstSnapshot)));
    expect(
      workbenchController.tableSnapshot?.revision,
      chartController.effectiveDocumentRevision.value,
    );
  });

  testWidgets('coalesces revision-driven refresh onto a bounded cadence', (
    tester,
  ) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
        chartValue: 10,
      ),
    );
    await tester.pumpAndSettle();
    final firstSnapshot = workbenchController.tableSnapshot!;

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        initialDisplayMode: ChartDisplayMode.data,
        tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
        chartValue: 30,
      ),
    );
    await tester.pump();
    expect(workbenchController.tableIsStale, isTrue);
    expect(workbenchController.tableSnapshot, same(firstSnapshot));
    expect(
      find.text('The chart changed after this table snapshot was captured.'),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(workbenchController.tableSnapshot, same(firstSnapshot));

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(workbenchController.tableIsStale, isFalse);
    expect(workbenchController.tableSnapshot, isNot(same(firstSnapshot)));
  });
}

Widget _host({
  double width = 1000,
  double height = 560,
  BravenChartController? chartController,
  required ChartWorkbenchController workbenchController,
  ChartDisplayMode initialDisplayMode = ChartDisplayMode.chart,
  BravenChartBuilder? chartBuilder,
  ChartWorkbenchActionsBuilder? actionsBuilder,
  ChartWorkbenchContextActionsBuilder? contextActionsBuilder,
  ChartWorkbenchOverlayActionBuilder? chartActionButtonBuilder,
  double splitBreakpoint = 900,
  Set<ChartDisplayMode> availableDisplayModes = const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
  },
  ChartTableRefreshPolicy tableRefreshPolicy =
      ChartTableRefreshPolicy.onModeEntry,
  ChartSourceRefreshPolicy sourceRefreshPolicy =
      ChartSourceRefreshPolicy.onDocumentRevision,
  ChartDartSourceOptions sourceOptions = const ChartDartSourceOptions(),
  ChartTableOptions tableOptions = const ChartTableOptions(),
  ChartDocumentExtractOptions documentOptions =
      const ChartDocumentExtractOptions(includeViewState: true),
  double chartValue = 10,
  String? chartTitle,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
  bool autoFitTablePane = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: textScaler, highContrast: highContrast),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: BravenChartWorkbench(
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: initialDisplayMode,
          chartBuilder:
              chartBuilder ??
              (context, controller) =>
                  _chart(controller, y: chartValue, title: chartTitle),
          actionsBuilder: actionsBuilder,
          contextActionsBuilder: contextActionsBuilder,
          chartActionButtonBuilder: chartActionButtonBuilder,
          splitBreakpoint: splitBreakpoint,
          availableDisplayModes: availableDisplayModes,
          tableRefreshPolicy: tableRefreshPolicy,
          sourceRefreshPolicy: sourceRefreshPolicy,
          sourceOptions: sourceOptions,
          tableOptions: tableOptions,
          documentOptions: documentOptions,
          autoFitTablePane: autoFitTablePane,
        ),
      ),
    ),
  ),
);

Widget _chart(
  BravenChartController controller, {
  double y = 10,
  String? title,
}) => BravenChartPlus(
  bravenChartController: controller,
  title: title,
  showLegend: false,
  series: [
    LineChartSeries(
      id: 'signal',
      name: 'Signal',
      points: [
        ChartDataPoint(x: 0, y: y),
        ChartDataPoint(x: 1, y: y + 2),
        ChartDataPoint(x: 2, y: y + 1),
      ],
    ),
  ],
);

Future<ChartArtifactResult<ChartArtifact>> _capture(
  WidgetTester tester,
  Future<ChartArtifactResult<ChartArtifact>> future,
) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump();
  }
  return (await tester.runAsync(
    () => future.timeout(const Duration(seconds: 10)),
  ))!;
}

class _LifecycleProbe extends StatefulWidget {
  const _LifecycleProbe({
    required this.onInit,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onInit;
  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_LifecycleProbe> createState() => _LifecycleProbeState();
}

class _LifecycleProbeState extends State<_LifecycleProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TrackingChartController extends BravenChartController {
  bool wasDisposed = false;

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

class _TrackingWorkbenchController extends ChartWorkbenchController {
  bool wasDisposed = false;

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

class _ControlledExtractionController extends BravenChartController {
  bool failNextDocument = false;
  bool warnNextDocument = false;
  bool failNextSource = false;

  @override
  ChartArtifactResult<ChartDocumentSnapshot> extractDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    if (failNextDocument) {
      failNextDocument = false;
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.tableProjectionFailed,
          message: 'Demo table refresh failed. Retry to use current data.',
        ),
      );
    }
    final result = super.extractDocument(options);
    if (!warnNextDocument) return result;
    warnNextDocument = false;
    return switch (result) {
      ChartArtifactSuccess<ChartDocumentSnapshot>() => ChartArtifactSuccess(
        value: result.value,
        warnings: const [
          ChartArtifactWarning(
            code: 'demo_rounded_values',
            message: 'Demo values were rounded for display.',
          ),
        ],
      ),
      ChartArtifactFailure<ChartDocumentSnapshot>() => result,
    };
  }

  @override
  ChartArtifactResult<ChartDocumentSnapshot> extractSourceDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    if (failNextSource) {
      failNextSource = false;
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Demo source refresh failed. Retry to use current data.',
        ),
      );
    }
    return super.extractSourceDocument(options);
  }
}

class _DelayedArtifactController extends BravenChartController {
  final Completer<void> _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ChartArtifactResult<ChartArtifact>> extractArtifact([
    ChartArtifactExtractOptions options = const ChartArtifactExtractOptions(
      artifactId: 'chart-artifact',
    ),
  ]) async {
    await _gate.future;
    return super.extractArtifact(options);
  }
}
