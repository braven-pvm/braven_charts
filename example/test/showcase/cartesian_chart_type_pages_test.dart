// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await tester.pump(const Duration(milliseconds: 300));
  }

  final subjects = <String, Widget>{
    'line': const LineChartsPage(),
    'area': const AreaChartsPage(),
    'scatter': const ScatterChartsPage(),
  };

  for (final entry in subjects.entries) {
    testWidgets('${entry.key} guide exposes generated source centrally', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: entry.value)));
      await tester.pumpAndSettle();

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      expect(switcher, findsOneWidget);
      expect(
        find.descendant(of: switcher, matching: find.text('Source')),
        findsOneWidget,
      );

      final sourceMode = find.descendant(
        of: switcher,
        matching: find.text('Source'),
      );
      await tester.ensureVisible(sourceMode);
      await tester.pump();
      await tester.tap(sourceMode);
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      expect(
        workbench.workbenchController!.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains('final ${entry.key}Chart = BravenChartPlus('),
      );
      expect(find.byType(ChartSourceView), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chart-source-dark-window')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Line Source follows preset changes without a stale prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LineChartsPage())),
    );
    await tester.pumpAndSettle();

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();

    var workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    final firstSource = workbench.workbenchController!.generatedSource;
    expect(firstSource?.source, contains("id: 'observed'"));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Motion'),
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
    workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(workbench.workbenchController!.sourceIsStale, isFalse);
    expect(
      workbench.workbenchController!.generatedSource,
      isNot(same(firstSource)),
    );
    expect(
      workbench.workbenchController!.generatedSource!.source,
      allOf(
        contains("id: 'motion-observed'"),
        isNot(contains("id: 'interpolation-linear'")),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'line guide covers workhorse, interpolation, axes, motion, and compositions',
    (tester) async {
      await pumpPage(tester, const LineChartsPage());

      expect(find.text('Line Charts'), findsOneWidget);
      expect(find.text('Workhorse'), findsWidgets);
      expect(find.text('Interpolation'), findsWidgets);
      expect(find.text('Multi-axis'), findsWidgets);
      expect(find.text('Motion'), findsWidgets);
      expect(find.text('Comparison'), findsWidgets);
      expect(find.text('Envelope'), findsWidgets);
      expect(find.text('Spotlight'), findsWidgets);
      expect(find.text('Forecast'), findsWidgets);
      expect(find.byType(BravenChartWorkbench), findsOneWidget);
      expect(find.byType(BravenChartPlus), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('line-preset-picker')),
          matching: find.text('Multi-axis'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      expect(chart.series, hasLength(3));
      expect(chart.normalizationMode, NormalizationMode.perSeries);
    },
  );

  testWidgets(
    'area guide exposes baseline, forecast, and gradient compositions',
    (tester) async {
      await pumpPage(tester, const AreaChartsPage());

      expect(find.text('Area Charts'), findsOneWidget);
      expect(find.text('Layered'), findsWidgets);
      expect(find.text('Baseline'), findsWidgets);
      expect(find.text('Forecast'), findsWidgets);
      expect(find.text('Motion'), findsWidgets);
      expect(find.text('Gradient'), findsWidgets);
      expect(find.text('Composition'), findsWidgets);
      expect(find.text('Pulse'), findsWidgets);
      expect(find.byType(BravenChartWorkbench), findsOneWidget);

      await tester.tap(find.text('Baseline'));
      await tester.pump(const Duration(milliseconds: 200));

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      final series = chart.series.first as AreaChartSeries;
      expect(series.aboveBaselineFillColor, isNotNull);
      expect(series.belowBaselineFillColor, isNotNull);
    },
  );

  testWidgets('line presets add comparison and mixed envelope examples', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());
    final picker = find.byKey(const ValueKey('line-preset-picker'));

    final comparison = find.descendant(
      of: picker,
      matching: find.text('Comparison'),
    );
    await tester.ensureVisible(comparison);
    await tester.pumpAndSettle();
    await tester.tap(comparison);
    await tester.pumpAndSettle();
    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series.whereType<LineChartSeries>(), hasLength(3));
    expect(chart.series.map((series) => series.name), [
      'Current',
      'Previous',
      'Target',
    ]);

    final envelope = find.descendant(
      of: picker,
      matching: find.text('Envelope'),
    );
    await tester.ensureVisible(envelope);
    await tester.pumpAndSettle();
    await tester.tap(envelope);
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series, hasLength(2));
    expect(chart.series.first, isA<AreaChartSeries>());
    expect((chart.series.first as AreaChartSeries).fillGradient, isNotNull);
    expect(chart.series.last, isA<LineChartSeries>());
  });

  testWidgets('area presets add gradient and mixed composition examples', (
    tester,
  ) async {
    await pumpPage(tester, const AreaChartsPage());
    final picker = find.byKey(const ValueKey('area-preset-picker'));

    await tester.tap(
      find.descendant(of: picker, matching: find.text('Gradient')),
    );
    await tester.pumpAndSettle();
    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series, hasLength(1));
    expect((chart.series.single as AreaChartSeries).fillGradient, isNotNull);

    final gradientToggle = find.byKey(const ValueKey('area-gradient-fill'));
    expect(gradientToggle, findsOneWidget);
    await tester.tap(gradientToggle);
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect((chart.series.single as AreaChartSeries).fillGradient, isNull);

    final composition = find.descendant(
      of: picker,
      matching: find.text('Composition'),
    );
    await tester.ensureVisible(composition);
    await tester.pumpAndSettle();
    await tester.tap(composition);
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.series.whereType<AreaChartSeries>(), hasLength(2));
    expect(chart.series.whereType<LineChartSeries>(), hasLength(1));
  });

  testWidgets(
    'Line Forecast joins solid history to dotted prognosis at current time',
    (tester) async {
      await pumpPage(tester, const LineChartsPage());
      final forecast = find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Forecast'),
      );
      await tester.ensureVisible(forecast);
      await tester.pumpAndSettle();
      await tester.tap(forecast);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      final path = chart.series.whereType<LineChartSeries>().single;
      expect(path.id, 'forecast-continuous');
      expect(path.name, 'Observed + forecast');
      expect(path.points, hasLength(11));
      expect(
        path.points.map((point) => point.x),
        orderedEquals(List.generate(11, (index) => index)),
      );
      expect(path.dashPattern, isEmpty);
      expect(path.inlineLabel?.text, 'Forecast');
      expect(path.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
      expect(
        path.points.take(4),
        everyElement(
          isA<ChartDataPoint>().having(
            (point) => point.segmentStyle,
            'observed style',
            isNull,
          ),
        ),
      );
      expect(
        path.points.skip(4).take(6),
        everyElement(
          isA<ChartDataPoint>().having(
            (point) => point.segmentStyle?.dashPattern,
            'forecast pattern',
            const [2, 6],
          ),
        ),
      );
      expect(path.points.last.segmentStyle, isNull);
      final boundary = chart.annotations
          .whereType<ThresholdAnnotation>()
          .single;
      expect(boundary.axis, AnnotationAxis.x);
      expect(boundary.value, 4);
      expect(boundary.label, 'Current time');
      expect(chart.showLegend, isFalse);
      expect(find.text('Show Legend'), findsNothing);
      expect(find.text('Show second series'), findsNothing);
    },
  );

  testWidgets(
    'Line Spotlight stays focused while showcasing luminous identity',
    (tester) async {
      await pumpPage(tester, const LineChartsPage());
      final spotlight = find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Spotlight'),
      );
      await tester.ensureVisible(spotlight);
      await tester.pumpAndSettle();
      await tester.tap(spotlight);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      final focus = chart.series.whereType<LineChartSeries>().single;
      final context = chart.series.whereType<AreaChartSeries>().single;
      expect(focus.name, 'Live signal');
      expect(focus.lineGlow, 8);
      expect(focus.inlineLabel?.text, 'Live signal');
      expect(context.fillGradient, isNotNull);
      expect(chart.annotations.whereType<ThresholdAnnotation>(), hasLength(1));
      expect(chart.theme?.backgroundColor, ChartTheme.dark.backgroundColor);
      expect(chart.showLegend, isFalse);
      expect(find.text('Theme'), findsNothing);
    },
  );

  testWidgets(
    'Area Pulse combines gradient, target window, and peak emphasis',
    (tester) async {
      await pumpPage(tester, const AreaChartsPage());
      final pulse = find.descendant(
        of: find.byKey(const ValueKey('area-preset-picker')),
        matching: find.text('Pulse'),
      );
      await tester.ensureVisible(pulse);
      await tester.pumpAndSettle();
      await tester.tap(pulse);
      await tester.pumpAndSettle();

      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      final area = chart.series.whereType<AreaChartSeries>().single;
      expect(area.name, 'Live load');
      expect(area.fillGradient, isNotNull);
      expect(area.lineGlow, 3);
      expect(area.inlineLabel?.text, 'Live load');
      final target = chart.series.whereType<LineChartSeries>().single;
      expect(target.inlineLabel?.text, 'Target');
      expect(chart.showLegend, isFalse);
      expect(chart.annotations.whereType<RangeAnnotation>(), hasLength(1));
      expect(chart.annotations.whereType<PointAnnotation>(), hasLength(1));
    },
  );

  testWidgets('scatter guide demonstrates a trend annotation', (tester) async {
    await pumpPage(tester, const ScatterChartsPage());

    expect(find.text('Scatter Charts'), findsOneWidget);
    expect(find.text('Cohorts'), findsWidgets);

    await tester.tap(find.text('Correlation'));
    await tester.pump(const Duration(milliseconds: 200));

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.annotations.whereType<TrendAnnotation>(), hasLength(1));
  });

  testWidgets('line workbench supports Data, Split, and live resizing', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Data')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    final handle = find.byKey(const ValueKey('chart-workbench-split-handle'));
    expect(handle, findsOneWidget);
    final before = tester.getCenter(handle).dx;
    await tester.drag(handle, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(handle).dx, greaterThan(before));
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('line preset changes keep the workbench controller attached', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );

    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Split')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Multi-axis'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Power (W)'), findsOneWidget);
    expect(find.text('Heart rate (bpm)'), findsOneWidget);
    expect(
      find.textContaining('not attached to a mounted chart'),
      findsNothing,
    );
    expect(find.text('Retry refresh'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Line Motion preset replays and interpolates real values', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Motion'),
      ),
    );
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final motionSeries = chart.series.whereType<LineChartSeries>().toList();
    expect(motionSeries.map((series) => series.id), [
      'motion-observed',
      'motion-plan',
      'motion-capacity',
    ]);
    expect(
      motionSeries.every(
        (series) =>
            series.pathAnimation.entranceMode ==
                PathEntranceAnimationMode.reveal &&
            series.pathAnimation.dataUpdateMode ==
                PathDataUpdateAnimationMode.interpolate,
      ),
      isTrue,
    );
    expect(
      motionSeries.map((series) => series.pathAnimation.entranceTiming.delay),
      const [
        Duration.zero,
        Duration(milliseconds: 80),
        Duration(milliseconds: 160),
      ],
    );
    expect(
      motionSeries.map((series) => series.pathAnimation.dataUpdateTiming.delay),
      const [
        Duration.zero,
        Duration(milliseconds: 80),
        Duration(milliseconds: 160),
      ],
    );

    final delayControl = find.byKey(const ValueKey('line-series-delay'));
    final delaySlider = tester.widget<Slider>(
      find.descendant(of: delayControl, matching: find.byType(Slider)),
    );
    delaySlider.onChanged!(120);
    await tester.pump();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.whereType<LineChartSeries>().map(
        (series) => series.pathAnimation.entranceTiming.delay,
      ),
      const [
        Duration.zero,
        Duration(milliseconds: 120),
        Duration(milliseconds: 240),
      ],
    );
    final timingOnlyRenderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    expect(
      timingOnlyRenderBox.debugElements.whereType<SeriesElement>().map(
        (element) => element.revealProgress,
      ),
      everyElement(1),
    );
    await tester.pumpAndSettle();

    final update = find.byKey(const ValueKey('line-update-values'));
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final observed =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-observed')
                .series
            as LineChartSeries;
    expect(observed.points.first.y, closeTo(33, 0.2));
    await tester.pumpAndSettle();

    final addPoint = find.byKey(const ValueKey('line-add-point'));
    await tester.ensureVisible(addPoint);
    await tester.tap(addPoint);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    var topologySeries =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-observed')
                .series
            as LineChartSeries;
    expect(topologySeries.points, hasLength(9));
    expect(topologySeries.points.last.x, closeTo(7.5, 0.05));
    await tester.pumpAndSettle();

    final removePoint = find.byKey(const ValueKey('line-remove-point'));
    await tester.ensureVisible(removePoint);
    await tester.tap(removePoint);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    topologySeries =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-observed')
                .series
            as LineChartSeries;
    expect(topologySeries.points, hasLength(9));
    expect(topologySeries.points.last.x, closeTo(7.5, 0.05));
    await tester.pumpAndSettle();

    final backfill = find.byKey(const ValueKey('line-backfill-point'));
    await tester.ensureVisible(backfill);
    expect(find.text('Add backfill'), findsOneWidget);
    await tester.tap(backfill);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    topologySeries =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-observed')
                .series
            as LineChartSeries;
    expect(topologySeries.points, hasLength(9));
    expect(
      topologySeries.points.singleWhere((point) => point.label == 'Backfill').x,
      closeTo(3.5, 0.05),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove backfill'), findsOneWidget);

    await tester.tap(backfill);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));
    topologySeries =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-observed')
                .series
            as LineChartSeries;
    expect(topologySeries.points, hasLength(9));
    expect(
      topologySeries.points.where((point) => point.label == 'Backfill'),
      hasLength(1),
    );
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      (chart.series.first as LineChartSeries).points.where(
        (point) => point.label == 'Backfill',
      ),
      isEmpty,
    );
    expect(find.text('Add backfill'), findsOneWidget);

    final rollWindow = find.byKey(const ValueKey('line-roll-window'));
    final workbench = tester.widget<BravenChartWorkbench>(
      find.byKey(const ValueKey('line-workbench')),
    );
    final controller = workbench.chartController!;
    controller.selectPoint(
      const ChartPointRef(seriesId: 'motion-observed', pointIndex: 1),
      revision: controller.effectiveDocumentRevision.value!,
    );
    await tester.pump();
    await tester.ensureVisible(rollWindow);
    await tester.tap(rollWindow);
    await tester.pump();
    await tester.pump();
    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'motion-observed', pointIndex: 0),
    });
    await tester.pump(const Duration(milliseconds: 325));
    final topologyElement = renderBox.debugElements
        .whereType<SeriesElement>()
        .firstWhere((element) => element.series.id == 'motion-observed');
    topologySeries = topologyElement.series as LineChartSeries;
    expect(topologySeries.points, hasLength(9));
    expect(topologySeries.points.first.x, closeTo(0.5, 0.05));
    expect(topologySeries.points.last.x, closeTo(7.5, 0.05));
    expect(topologyElement.dataHitForPointIndex(0)!.isSelected, isTrue);
    await tester.pumpAndSettle();

    final replay = find.byKey(const ValueKey('line-replay-entrance'));
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Area Motion exposes and runs boundary topology actions', (
    tester,
  ) async {
    await pumpPage(tester, const AreaChartsPage());
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('area-preset-picker')),
        matching: find.text('Motion'),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final motionSeries = chart.series.whereType<AreaChartSeries>().toList();
    expect(motionSeries.map((series) => series.id), [
      'motion-volume',
      'motion-plan',
    ]);
    expect(
      motionSeries.map((series) => series.pathAnimation.entranceTiming.delay),
      const [Duration.zero, Duration(milliseconds: 120)],
    );
    expect(motionSeries.map((series) => series.fillOpacity), [
      0.24,
      closeTo(0.132, 0.001),
    ]);

    expect(find.byKey(const ValueKey('area-add-point')), findsOneWidget);
    expect(find.byKey(const ValueKey('area-remove-point')), findsOneWidget);
    final backfill = find.byKey(const ValueKey('area-backfill-point'));
    expect(backfill, findsOneWidget);
    tester.widget<OutlinedButton>(backfill).onPressed!();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    var area =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-volume')
                .series
            as AreaChartSeries;
    expect(area.points, hasLength(9));
    expect(
      area.points.singleWhere((point) => point.label == 'Backfill').x,
      closeTo(3.5, 0.05),
    );
    await tester.pumpAndSettle();

    tester.widget<OutlinedButton>(backfill).onPressed!();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    area = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<AreaChartSeries>()
        .first;
    expect(area.points, hasLength(8));
    expect(area.points.where((point) => point.label == 'Backfill'), isEmpty);

    final rollWindow = find.byKey(const ValueKey('area-roll-window'));
    tester.widget<OutlinedButton>(rollWindow).onPressed!();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 325));

    area =
        renderBox.debugElements
                .whereType<SeriesElement>()
                .firstWhere((element) => element.series.id == 'motion-volume')
                .series
            as AreaChartSeries;
    expect(area.points, hasLength(9));
    expect(area.points.first.x, closeTo(0.5, 0.05));
    expect(area.points.last.x, closeTo(7.5, 0.05));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Line and Area remain usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final page in const <Widget>[LineChartsPage(), AreaChartsPage()]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(find.byType(BravenChartWorkbench), findsOneWidget);
      final finalPreset = find.descendant(
        of: find.byKey(
          ValueKey(
            page is LineChartsPage
                ? 'line-preset-picker'
                : 'area-preset-picker',
          ),
        ),
        matching: find.text(page is LineChartsPage ? 'Spotlight' : 'Pulse'),
      );
      await tester.ensureVisible(finalPreset);
      await tester.pumpAndSettle();
      await tester.tap(finalPreset);
      await tester.pumpAndSettle();
      expect(find.byType(BravenChartPlus), findsOneWidget);
      final viewportWidth = tester.view.physicalSize.width;
      for (final surface in [
        find.text('Reset example'),
        find.byKey(const ValueKey('chart-page-options-button')),
        find.byType(BravenChartWorkbench),
      ]) {
        final rect = tester.getRect(surface);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(viewportWidth));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact Line and Area Motion sheets run backfill updates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final entry in const <(String, Widget)>[
      ('line', LineChartsPage()),
      ('area', AreaChartsPage()),
    ]) {
      final (family, page) = entry;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
      await tester.pump(const Duration(milliseconds: 300));
      final motion = find.descendant(
        of: find.byKey(ValueKey('$family-preset-picker')),
        matching: find.text('Motion'),
      );
      await tester.ensureVisible(motion);
      await tester.pumpAndSettle();
      await tester.tap(motion);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chart-page-options-button')));
      await tester.pumpAndSettle();

      final backfill = find.byKey(ValueKey('$family-backfill-point'));
      await tester.ensureVisible(backfill);
      await tester.pumpAndSettle();
      final rect = tester.getRect(backfill);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));

      await tester.tap(backfill);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      final chart = tester.widget<BravenChartPlus>(
        find.byType(BravenChartPlus),
      );
      expect(
        chart.series.first.points.where((point) => point.label == 'Backfill'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });
}
