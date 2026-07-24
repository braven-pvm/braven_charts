import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSelectionLab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SelectionShowcasePage())),
    );
    await tester.pumpAndSettle();
  }

  List<Widget> inspectorEntries(WidgetTester tester) {
    final panel = tester.widget<OptionsPanel>(find.byType(OptionsPanel));
    final entries = <Widget>[];

    void visit(Widget widget) {
      entries.add(widget);
      if (widget is OptionSection) {
        for (final child in widget.children) {
          visit(child);
        }
      }
    }

    for (final child in panel.children) {
      visit(child);
    }
    return entries;
  }

  T inspectorEntry<T extends Widget>(WidgetTester tester, Key key) =>
      inspectorEntries(
        tester,
      ).whereType<T>().singleWhere((widget) => widget.key == key);

  StandardChartOptions standardOptions(WidgetTester tester) =>
      inspectorEntries(tester).whereType<StandardChartOptions>().single;

  testWidgets(
    'selection lab exposes every chart family in one wrapped picker',
    (tester) async {
      await pumpSelectionLab(tester);

      expect(find.text('Selection lab'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('selection-family-grid')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('selection-family-grid')))
            .height,
        lessThanOrEqualTo(120),
        reason: 'The family selector must not collapse the chart viewport',
      );
      for (final family in const [
        'line',
        'area',
        'rangeArea',
        'bar',
        'scatter',
        'candlestick',
        'pie',
        'donut',
        'concentricDonut',
        'polarColumn',
      ]) {
        expect(
          find.byKey(ValueKey('selection-family-$family')),
          findsOneWidget,
        );
      }
      expect(find.byType(BravenChartWorkbench), findsOneWidget);
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(
        tester
            .widget<BravenChartPlus>(
              find.byKey(const ValueKey('selection-chart-line')),
            )
            .interactionConfig
            ?.showFocusBorder,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('chart-selection-action-strip')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-selection-summary')))
            .data,
        'Nothing selected',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'each family mounts its intended selection acquisition contract',
    (tester) async {
      await pumpSelectionLab(tester);

      final cases =
          <
            ({
              String family,
              ChartSelectionAcquisitionMode acquisition,
              ChartSelectionScope scope,
              int seriesCount,
            })
          >[
            (
              family: 'line',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.markOrWholeSeries,
              seriesCount: 2,
            ),
            (
              family: 'area',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.markOrWholeSeries,
              seriesCount: 2,
            ),
            (
              family: 'rangeArea',
              acquisition: ChartSelectionAcquisitionMode.rectangle,
              scope: ChartSelectionScope.mark,
              seriesCount: 3,
            ),
            (
              family: 'bar',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.wholeSeries,
              seriesCount: 4,
            ),
            (
              family: 'scatter',
              acquisition: ChartSelectionAcquisitionMode.lasso,
              scope: ChartSelectionScope.mark,
              seriesCount: 2,
            ),
            (
              family: 'candlestick',
              acquisition: ChartSelectionAcquisitionMode.xInterval,
              scope: ChartSelectionScope.mark,
              seriesCount: 1,
            ),
            (
              family: 'pie',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.mark,
              seriesCount: 1,
            ),
            (
              family: 'donut',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.mark,
              seriesCount: 1,
            ),
            (
              family: 'concentricDonut',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.category,
              seriesCount: 3,
            ),
            (
              family: 'polarColumn',
              acquisition: ChartSelectionAcquisitionMode.point,
              scope: ChartSelectionScope.category,
              seriesCount: 2,
            ),
          ];

      for (final testCase in cases) {
        await tester.tap(
          find.byKey(ValueKey('selection-family-${testCase.family}')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final chart = tester.widget<BravenChartPlus>(
          find.byKey(ValueKey('selection-chart-${testCase.family}')),
        );
        expect(chart.series, hasLength(testCase.seriesCount));
        expect(
          chart.interactionConfig?.selection.acquisitionMode,
          testCase.acquisition,
          reason: '${testCase.family} acquisition mode',
        );
        expect(
          chart.interactionConfig?.selection.scope,
          testCase.scope,
          reason: '${testCase.family} semantic scope',
        );
        expect(
          chart.interactionConfig?.tooltip.enabled,
          isFalse,
          reason: '${testCase.family} point popup default',
        );
        expect(tester.takeException(), isNull, reason: testCase.family);
      }
    },
  );

  testWidgets('tool and target controls reconfigure the mounted chart', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('selection-lab-tool-point')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('selection-lab-mode-replace')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(
              const ValueKey('selection-lab-target-markOrWholeSeries'),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('selection-lab-tool-xInterval')),
    );
    await tester.tap(
      find.byKey(const ValueKey('selection-lab-target-category')),
    );
    await tester.tap(find.byKey(const ValueKey('selection-lab-mode-add')));
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-line')),
    );
    expect(
      chart.interactionConfig?.selection.acquisitionMode,
      ChartSelectionAcquisitionMode.xInterval,
    );
    expect(
      chart.interactionConfig?.selection.scope,
      ChartSelectionScope.category,
    );
    expect(
      chart.interactionConfig?.selection.operation,
      ChartSelectionOperation.add,
    );

    await tester.tap(find.byKey(const ValueKey('selection-family-bar')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('selection-lab-target-categoryStack')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('selection-family-pie')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('selection-lab-tool-point')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('selection-lab-tool-xInterval')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection controls wrap without overflowing a compact page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(820, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SelectionShowcasePage()));
    await tester.pumpAndSettle();

    expect(find.text('Selection tool'), findsOneWidget);
    expect(find.text('Selection target'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selection-lab-target-markOrWholeSeries')),
      findsOneWidget,
    );
    for (final mode in const ['replace', 'add', 'subtract', 'toggle']) {
      expect(find.byKey(ValueKey('selection-lab-mode-$mode')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact RTL lab remains stable with dark theme and reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(820, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(1.25),
              ),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: SelectionShowcasePage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('selection-family-area')),
      );
      await tester.tap(find.byKey(const ValueKey('selection-family-area')));
      await tester.pumpAndSettle();

      final chartFinder = find.byKey(const ValueKey('selection-chart-area'));
      final chart = tester.widget<BravenChartPlus>(chartFinder);
      expect(Directionality.of(tester.element(chartFinder)), TextDirection.rtl);
      expect(Theme.of(tester.element(chartFinder)).brightness, Brightness.dark);
      expect(chart.theme, isNotNull);
      expect(MediaQuery.disableAnimationsOf(tester.element(chartFinder)), true);
      expect(
        find.byKey(const ValueKey('chart-selection-action-strip')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('selection-family-grid')))
            .height,
        lessThanOrEqualTo(180),
        reason: 'Larger RTL text may add one row but must remain compact',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'touch selection modes remain reachable with 2x text at compact width',
    (tester) async {
      tester.view.physicalSize = const Size(820, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: const SelectionShowcasePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final mode in const ['replace', 'add', 'subtract', 'toggle']) {
        final finder = find.byKey(ValueKey('selection-lab-mode-$mode'));
        expect(finder, findsOneWidget);
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(44),
          reason: '$mode must remain a usable touch target',
        );
      }

      await tester.ensureVisible(
        find.byKey(const ValueKey('selection-lab-mode-subtract')),
      );
      await tester.tap(
        find.byKey(const ValueKey('selection-lab-mode-subtract')),
      );
      await tester.pump();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('selection-chart-line')),
      );
      expect(
        chart.interactionConfig?.selection.operation,
        ChartSelectionOperation.subtract,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('standard chart options reconfigure the active selection chart', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    final standard = standardOptions(tester);
    expect(standard.showGridOption, isTrue);
    expect(standard.showMarkerOption, isTrue);
    expect(standard.showCrosshairOption, isTrue);
    expect(standard.showDataPointPopupOption, isTrue);
    expect(standard.controller.showDataPointPopup, isFalse);

    final initialChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-line')),
    );
    expect(initialChart.interactionConfig?.tooltip.enabled, isFalse);

    standard.controller
      ..showGrid = false
      ..showAxisLines = false
      ..showDataMarkers = false
      ..showLegend = false
      ..showCrosshair = false
      ..showDataPointPopup = false
      ..enableZoom = true
      ..enablePan = true;
    await tester.pump();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-line')),
    );
    expect(chart.grid?.horizontal, isFalse);
    expect(chart.grid?.vertical, isFalse);
    expect(chart.xAxisConfig?.showAxisLine, isFalse);
    expect(chart.yAxis?.showAxisLine, isFalse);
    expect(chart.showLegend, isFalse);
    expect(chart.interactionConfig?.crosshair.enabled, isFalse);
    expect(chart.interactionConfig?.tooltip.enabled, isFalse);
    expect(chart.interactionConfig?.enableZoom, isTrue);
    expect(chart.interactionConfig?.enablePan, isTrue);
    expect(
      chart.series.whereType<LineChartSeries>().every(
        (series) => !series.showDataPointMarkers,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Area honors path feedback and standard chart options like Line',
    (tester) async {
      await pumpSelectionLab(tester);

      await tester.tap(find.byKey(const ValueKey('selection-family-area')));
      await tester.pump();

      final standard = standardOptions(tester);
      standard.controller
        ..showGrid = false
        ..showAxisLines = false
        ..showDataMarkers = false
        ..showLegend = false
        ..showCrosshair = false
        ..enableZoom = true
        ..enablePan = true;
      await tester.pump();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('selection-chart-area')),
      );
      final selection = chart.interactionConfig!.selection;
      expect(selection.acquisitionMode, ChartSelectionAcquisitionMode.point);
      expect(selection.scope, ChartSelectionScope.markOrWholeSeries);
      expect(selection.dataPointHitRadius, 20);
      expect(selection.completeSeriesHitRadius, 22);
      expect(selection.dataPointHoverScale, 1.5);
      expect(selection.dataPointSelectionScale, 2.67);
      expect(selection.completeSeriesHoverStrokeScale, 1.75);
      expect(selection.completeSeriesSelectionStrokeScale, 1.5);
      expect(chart.grid?.horizontal, isFalse);
      expect(chart.grid?.vertical, isFalse);
      expect(chart.xAxisConfig?.showAxisLine, isFalse);
      expect(chart.yAxis?.showAxisLine, isFalse);
      expect(chart.showLegend, isFalse);
      expect(chart.interactionConfig?.crosshair.enabled, isFalse);
      expect(chart.interactionConfig?.enableZoom, isTrue);
      expect(chart.interactionConfig?.enablePan, isTrue);
      expect(
        chart.series.whereType<AreaChartSeries>().every(
          (series) => !series.showDataPointMarkers,
        ),
        isTrue,
      );
      expect(
        chart.series.whereType<LineChartSeries>().every(
          (series) => !series.showDataPointMarkers,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selection feedback controls follow chart-family capabilities', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    expect(
      find.byKey(
        const ValueKey('selection-lab-point-hover-scale'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('selection-lab-series-selection-scale'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('selection-family-bar')));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('selection-lab-bar-dimmed-opacity'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('selection-family-scatter')));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('selection-lab-scatter-selection-scale'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('selection-family-pie')));
    await tester.pump();
    final radialOptions = standardOptions(tester);
    expect(radialOptions.showGridOption, isFalse);
    expect(radialOptions.showAxisOption, isFalse);
    expect(radialOptions.showMarkerOption, isFalse);
    expect(radialOptions.showScrollbarOptions, isFalse);
    expect(radialOptions.showCrosshairOption, isFalse);
    expect(radialOptions.showDataPointPopupOption, isTrue);
    expect(radialOptions.showInteractionOptions, isFalse);
    expect(radialOptions.controller.showDataPointPopup, isFalse);
    var radialChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-pie')),
    );
    expect(radialChart.interactionConfig?.tooltip.enabled, isFalse);

    radialOptions.controller.showDataPointPopup = true;
    await tester.pump();
    radialChart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-pie')),
    );
    expect(radialChart.interactionConfig?.tooltip.enabled, isTrue);
    expect(
      find.byKey(
        const ValueKey('selection-lab-radial-effect'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'interval tools expose a configurable persistent brush and controller state',
    (tester) async {
      await pumpSelectionLab(tester);

      await tester.tap(
        find.byKey(const ValueKey('selection-lab-tool-xInterval')),
      );
      await tester.pumpAndSettle();

      final enabled = inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-brush-enabled'),
      );
      expect(enabled.value, isFalse);
      enabled.onChanged(true);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('selection-chart-line')),
      );
      expect(chart.interactionConfig?.selection.brush.enabled, isTrue);
      expect(chart.interactionConfig?.selection.brush.keyboardEnabled, isFalse);
      expect(chart.interactionConfig?.selection.brush.initialVisible, isTrue);
      expect(chart.interactionConfig?.selection.brush.initialRange, isNotNull);
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-range'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-fill-color'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      final keyboard = inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-brush-keyboard-enabled'),
      );
      expect(keyboard.value, isFalse);
      keyboard.onChanged(true);
      await tester.pumpAndSettle();
      final keyboardChart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('selection-chart-line')),
      );
      expect(
        keyboardChart.interactionConfig?.selection.brush.keyboardEnabled,
        isTrue,
      );
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-keyboard-focus-color'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('selection-workbench')),
      );
      expect(workbench.chartController!.selectionBrushState?.visible, isTrue);

      final visible = inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-brush-visible'),
      );
      visible.onChanged(false);
      await tester.pumpAndSettle();
      expect(workbench.chartController!.selectionBrushState?.visible, isFalse);
      expect(workbench.chartController!.selectedPointRefs, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'box mode exposes two-axis persistence and visual grid controls',
    (tester) async {
      await pumpSelectionLab(tester);

      await tester.tap(
        find.byKey(const ValueKey('selection-lab-tool-rectangle')),
      );
      await tester.pumpAndSettle();
      inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-brush-enabled'),
      ).onChanged(true);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-x-range'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-y-range'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      inspectorEntry<EnumOption<ChartSelectionBrushGridDirection>>(
        tester,
        const ValueKey('selection-lab-brush-grid-direction'),
      ).onChanged(ChartSelectionBrushGridDirection.both);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-grid-rows'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-grid-columns'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('selection-lab-brush-grid-pattern'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      final chart = tester.widget<BravenChartPlus>(
        find.byKey(const ValueKey('selection-chart-line')),
      );
      final brush = chart.interactionConfig!.selection.brush;
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('selection-workbench')),
      );
      expect(brush.initialBox, isNotNull);
      expect(brush.initialRange, isNull);
      expect(brush.style.grid.direction, ChartSelectionBrushGridDirection.both);
      expect(workbench.chartController!.selectionBrushState?.visible, isTrue);
      expect(workbench.chartController!.selectionBrushState?.box, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'box selection automatically rebases the visible Workbench table',
    (tester) async {
      await pumpSelectionLab(tester);

      await tester.tap(
        find.byKey(const ValueKey('selection-lab-tool-rectangle')),
      );
      await tester.pumpAndSettle();
      inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-brush-enabled'),
      ).onChanged(true);
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('selection-workbench')),
      );
      final workbenchController = workbench.workbenchController!;
      final chartController = workbench.chartController!;
      workbenchController.setDisplayMode(ChartDisplayMode.split);
      await tester.pumpAndSettle();
      final initialSnapshot = workbenchController.tableSnapshot;
      expect(initialSnapshot, isNotNull);

      expect(
        chartController.setSelectionBrushBox(
          minimumX: 2,
          maximumX: 4,
          minimumY: 38,
          maximumY: 61,
          referenceSeriesId: 'observed',
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(chartController.selectionBrushState?.box, isNotNull);
      expect(chartController.selectedPointRefs, isNotEmpty);
      expect(workbenchController.tableIsStale, isFalse);
      expect(workbenchController.tableSnapshot, isNot(same(initialSnapshot)));
      expect(
        workbenchController.tableSnapshot?.revision,
        chartController.effectiveDocumentRevision.value,
      );
      expect(
        workbenchController
            .tableSnapshot
            ?.viewState
            ?.selectionExpression
            ?.isNotEmpty,
        isTrue,
      );
      expect(
        workbenchController.tableSnapshot?.viewState?.selectionBrush?.box,
        chartController.selectionBrushState?.box,
      );
      expect(
        find.textContaining(
          '${chartController.selectedPointRefs.length} selected ·',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'The point reference belongs to an older chart document revision.',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selection action policies are wired into the Workbench', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    expect(
      inspectorEntry<BoolOption>(
        tester,
        const ValueKey('selection-lab-projection-annotations'),
      ).value,
      isFalse,
    );

    final seriesProjection =
        inspectorEntry<EnumOption<ChartSelectionSeriesProjection>>(
          tester,
          const ValueKey('selection-lab-series-projection'),
        );
    final annotationProjection =
        inspectorEntry<EnumOption<ChartSelectionAnnotationProjection>>(
          tester,
          const ValueKey('selection-lab-annotation-projection'),
        );
    final boundaryProjection =
        inspectorEntry<EnumOption<ChartSelectionIntervalBoundaryProjection>>(
          tester,
          const ValueKey('selection-lab-boundary-projection'),
        );
    final zoomPadding = inspectorEntry<SliderOption>(
      tester,
      const ValueKey('selection-lab-zoom-padding'),
    );

    seriesProjection.onChanged(
      ChartSelectionSeriesProjection.completeParticipatingSeries,
    );
    annotationProjection.onChanged(
      ChartSelectionAnnotationProjection.retainContained,
    );
    expect(
      boundaryProjection.value,
      ChartSelectionIntervalBoundaryProjection.sourcePointsOnly,
    );
    boundaryProjection.onChanged(
      ChartSelectionIntervalBoundaryProjection.interpolateContinuousSeries,
    );
    zoomPadding.onChanged(0.2);
    await tester.pump();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('selection-workbench')),
    );
    expect(
      workbench.selectionProjection.seriesProjection,
      ChartSelectionSeriesProjection.completeParticipatingSeries,
    );
    expect(
      workbench.selectionProjection.annotationProjection,
      ChartSelectionAnnotationProjection.retainContained,
    );
    expect(
      workbench.selectionProjection.intervalBoundaryProjection,
      ChartSelectionIntervalBoundaryProjection.interpolateContinuousSeries,
    );
    expect(workbench.selectionZoomPaddingFraction, 0.2);
    expect(workbench.onSelectionArtifactCreated, isNotNull);
    expect(workbench.selectionCsvFileName, 'line-selection.csv');
  });

  testWidgets('Create chart opens a hydrated selection-only chart', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('selection-workbench')),
    );
    final controller = workbench.chartController!;
    controller.selectPoint(
      const ChartPointRef(seriesId: 'observed', pointIndex: 1),
      revision: controller.effectiveDocumentRevision.value!,
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('chart-selection-create-chart')),
    );
    await tester.tap(
      find.byKey(const ValueKey('chart-selection-create-chart')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selection-created-chart-dialog')),
      findsOneWidget,
    );
    expect(find.text('Chart created from selection'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('selection-lab-open-created-chart')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Line X-range chart creation matches the four selected source marks by default',
    (tester) async {
      await pumpSelectionLab(tester);

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byKey(const ValueKey('selection-workbench')),
      );
      final controller = workbench.chartController!;
      expect(
        controller.selectExpression(
          ChartSelectionExpression(
            clauses: [
              ChartSelectionXIntervalClause(
                minimumXInclusive: 0.75,
                maximumXInclusive: 2.4,
                seriesIds: const {'observed', 'capacity'},
              ),
            ],
          ),
          revision: controller.effectiveDocumentRevision.value!,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      expect(controller.selectionSnapshot?.statistics.pointCount, 4);
      await tester.tap(
        find.byKey(const ValueKey('chart-selection-create-chart')),
      );
      await tester.pumpAndSettle();

      final created = tester.widget<HydratedBravenChart>(
        find.byType(HydratedBravenChart),
      );
      expect(created.configuration.series, hasLength(2));
      for (final series in created.configuration.series) {
        expect(series.points.map((point) => point.x), [1, 2]);
      }
      expect(find.textContaining('2 series · 4 points'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('linked peer synchronizes stable-key selection', (tester) async {
    await pumpSelectionLab(tester);

    final linkedToggle = inspectorEntry<BoolOption>(
      tester,
      const ValueKey('selection-lab-linked-peer-toggle'),
    );
    linkedToggle.onChanged(true);
    await tester.pumpAndSettle();

    expect(find.byType(BravenChartPlus), findsNWidgets(2));
    final main = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-line')),
    );
    final peer = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-linked-chart-line')),
    );
    expect(main.interactionGroupController, isNotNull);
    expect(
      peer.interactionGroupController,
      same(main.interactionGroupController),
    );
    expect(main.interactionGroupOptions.synchronizeSelection, isTrue);
    expect(peer.interactionGroupOptions.synchronizeSelection, isTrue);

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('selection-workbench')),
    );
    workbench.chartController!.selectPoint(
      const ChartPointRef(seriesId: 'observed', pointIndex: 2),
      revision: workbench.chartController!.effectiveDocumentRevision.value!,
    );
    await tester.pump();
    await tester.pump();

    expect(peer.bravenChartController!.selectedPointRefs, {
      const ChartPointRef(seriesId: 'observed', pointIndex: 2),
    });
    expect(tester.takeException(), isNull);
  });
}
