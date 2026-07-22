import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSelectionLab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SelectionShowcasePage()));
    await tester.pumpAndSettle();
  }

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
              seriesCount: 1,
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

  testWidgets('standard chart options reconfigure the active selection chart', (
    tester,
  ) async {
    await pumpSelectionLab(tester);

    final standard = tester.widget<StandardChartOptions>(
      find.byType(StandardChartOptions),
    );
    expect(standard.showGridOption, isTrue);
    expect(standard.showMarkerOption, isTrue);
    expect(standard.showCrosshairOption, isTrue);

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
      find.byKey(const ValueKey('selection-chart-line')),
    );
    expect(chart.grid?.horizontal, isFalse);
    expect(chart.grid?.vertical, isFalse);
    expect(chart.xAxisConfig?.showAxisLine, isFalse);
    expect(chart.yAxis?.showAxisLine, isFalse);
    expect(chart.showLegend, isFalse);
    expect(chart.interactionConfig?.crosshair.enabled, isFalse);
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

      final standard = tester.widget<StandardChartOptions>(
        find.byType(StandardChartOptions),
      );
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
    final radialOptions = tester.widget<StandardChartOptions>(
      find.byType(StandardChartOptions),
    );
    expect(radialOptions.showGridOption, isFalse);
    expect(radialOptions.showAxisOption, isFalse);
    expect(radialOptions.showMarkerOption, isFalse);
    expect(radialOptions.showScrollbarOptions, isFalse);
    expect(radialOptions.showCrosshairOption, isFalse);
    expect(radialOptions.showInteractionOptions, isFalse);
    expect(
      find.byKey(
        const ValueKey('selection-lab-radial-effect'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
