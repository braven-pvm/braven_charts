// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:braven_charts_example/showcase/widgets/chart_options.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
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

  testWidgets('Line surface preserves a generous chart reading height', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());

    final workhorseCard = tester.getRect(find.byType(ChartCard));
    expect(workhorseCard.height, greaterThanOrEqualTo(700));
    expect(find.byKey(const ValueKey('line-showcase-scroll')), findsOneWidget);

    final synchronized = find.descendant(
      of: find.byKey(const ValueKey('line-preset-picker')),
      matching: find.text('Synchronized'),
    );
    await tester.ensureVisible(synchronized);
    await tester.pumpAndSettle();
    await tester.tap(synchronized);
    await tester.pumpAndSettle();

    final synchronizedCard = tester.getRect(find.byType(ChartCard));
    final codeReference = tester.getRect(
      find.byKey(const ValueKey('synchronized-code-reference')),
    );
    expect(synchronizedCard.height, greaterThanOrEqualTo(700));
    expect(codeReference.top, greaterThan(synchronizedCard.bottom));
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
      expect(find.text('Synchronized'), findsWidgets);
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
    'Line Synchronized stacks three independent charts in one interaction group',
    (tester) async {
      await pumpPage(tester, const LineChartsPage());
      final synchronized = find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Synchronized'),
      );
      await tester.ensureVisible(synchronized);
      await tester.pumpAndSettle();
      await tester.tap(synchronized);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('synchronized-cartesian-stack')),
        findsOneWidget,
      );
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Elevation'), findsOneWidget);
      expect(find.text('Heart rate'), findsOneWidget);
      expect(find.text('9.3 km/h'), findsOneWidget);
      expect(find.text('329 m'), findsOneWidget);
      expect(find.text('138 bpm'), findsOneWidget);
      expect(find.byType(BravenChartWorkbench), findsNothing);
      expect(
        find.byKey(const ValueKey('synchronized-code-reference')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('synchronized-code-controller')),
        findsOneWidget,
      );
      expect(find.textContaining('ChartInteractionGroupController'), findsOne);

      final participantSnippet = find.descendant(
        of: find.byKey(const ValueKey('synchronized-code-selector')),
        matching: find.text('Chart participants'),
      );
      await tester.ensureVisible(participantSnippet);
      await tester.pumpAndSettle();
      await tester.tap(participantSnippet);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('synchronized-code-participants')),
        findsOneWidget,
      );
      expect(find.textContaining('interactionGroupOptions'), findsOne);

      final charts = tester
          .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
          .toList();
      expect(charts, hasLength(3));
      expect(charts[0].series.single, isA<LineChartSeries>());
      expect(charts[1].series.single, isA<AreaChartSeries>());
      expect(charts[2].series.single, isA<AreaChartSeries>());
      expect(
        charts.map((chart) => chart.interactionGroupController).toSet(),
        hasLength(1),
      );
      expect(charts.first.interactionGroupController, isNotNull);
      final renderElements = _chartRenderFinder().evaluate().toList();
      final renderBoxes = renderElements
          .map((render) => render.renderObject! as ChartRenderBox)
          .toList();
      for (final renderBox in renderBoxes) {
        expect(renderBox.size.height, greaterThanOrEqualTo(48));
      }
      final firstFinder = find.byElementPredicate(
        (element) => element == renderElements.first,
      );
      await tester.ensureVisible(firstFinder);
      await tester.pumpAndSettle();
      final first = renderBoxes.first;
      const dataX = 0.2;
      final local = first.plotToWidget(
        first.transform!.dataToPlot(
          dataX,
          (first.transform!.dataYMin + first.transform!.dataYMax) / 2,
        ),
      );
      final pointer = await tester.createGesture();
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getTopLeft(firstFinder) + local);
      await tester.pump();
      expect(
        renderBoxes.map((renderBox) => renderBox.debugSynchronizedCursorX),
        everyElement(closeTo(dataX, 0.0001)),
      );
      for (final renderBox in renderBoxes) {
        final tracked =
            renderBox.debugSynchronizedTrackingState!.seriesValues.single;
        expect(tracked.x, closeTo(dataX, 0.0001));
        expect(tracked.isInterpolated, isTrue);
        final cursor = renderBox.debugSynchronizedCursorPosition!;
        final expectedY = renderBox
            .plotToWidget(renderBox.transform!.dataToPlot(tracked.x, tracked.y))
            .dy;
        expect(
          cursor.dy,
          closeTo(expectedY, 0.01),
          reason: 'full tracking follows each chart\'s local rendered value',
        );
      }
      final cursorScreenXs = <double>[
        for (var index = 0; index < renderBoxes.length; index++)
          tester
                  .getTopLeft(
                    find.byElementPredicate(
                      (element) => element == renderElements[index],
                    ),
                  )
                  .dx +
              renderBoxes[index].debugSynchronizedCursorPosition!.dx,
      ];
      for (final cursorScreenX in cursorScreenXs.skip(1)) {
        expect(
          cursorScreenX,
          closeTo(cursorScreenXs.first, 0.01),
          reason: 'shared data X must align to one screen-space coordinate',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Synchronized composition supports membership, sizing, tracking, and metrics',
    (tester) async {
      await pumpPage(tester, const LineChartsPage());
      final synchronized = find.descendant(
        of: find.byKey(const ValueKey('line-preset-picker')),
        matching: find.text('Synchronized'),
      );
      await tester.ensureVisible(synchronized);
      await tester.tap(synchronized);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('synchronized-performance-panel')),
        findsOneWidget,
      );
      expect(find.byType(BravenChartPlus), findsNWidgets(3));
      for (final chart in tester.widgetList<BravenChartPlus>(
        find.byType(BravenChartPlus),
      )) {
        expect(chart.interactionConfig!.crosshair.enabled, isTrue);
        expect(chart.interactionConfig!.crosshair.mode, CrosshairMode.both);
        expect(chart.interactionConfig!.crosshair.showTrackingTooltip, isTrue);
        expect(chart.yAxis!.showCrosshairLabel, isTrue);
      }

      await tester.tap(find.text('Chart composition'));
      await tester.pumpAndSettle();
      final elevationToggle = find.descendant(
        of: find.byKey(
          const ValueKey('synchronized-elevation-visible'),
          skipOffstage: false,
        ),
        matching: find.byType(SwitchListTile, skipOffstage: false),
      );
      tester.widget<SwitchListTile>(elevationToggle).onChanged!(false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('synchronized-elevation')),
        findsNothing,
      );
      expect(find.byType(BravenChartPlus), findsNWidgets(2));

      final speedHeight = find.descendant(
        of: find.byKey(
          const ValueKey('synchronized-speed-height'),
          skipOffstage: false,
        ),
        matching: find.byType(Slider, skipOffstage: false),
      );
      tester.widget<Slider>(speedHeight).onChanged!(320);
      await tester.pump();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('synchronized-speed-slot')))
            .height,
        320,
      );

      await tester.tap(find.text('Chart composition'));
      await tester.pumpAndSettle();
      final trackingToggle = find.descendant(
        of: find.byKey(
          const ValueKey('synchronized-tracking'),
          skipOffstage: false,
        ),
        matching: find.byType(SwitchListTile, skipOffstage: false),
      );
      tester.widget<SwitchListTile>(trackingToggle).onChanged!(false);
      await tester.pump();
      for (final chart in tester.widgetList<BravenChartPlus>(
        find.byType(BravenChartPlus),
      )) {
        expect(chart.interactionConfig!.crosshair.enabled, isFalse);
        expect(chart.interactionConfig!.crosshair.showTrackingTooltip, isFalse);
        expect(chart.yAxis!.showCrosshairLabel, isFalse);
      }

      await tester.tap(find.text('Chart composition'));
      await tester.pumpAndSettle();
      for (final metric in const ['speed', 'heartRate']) {
        final toggle = find.descendant(
          of: find.byKey(
            ValueKey('synchronized-$metric-visible'),
            skipOffstage: false,
          ),
          matching: find.byType(SwitchListTile, skipOffstage: false),
        );
        tester.widget<SwitchListTile>(toggle).onChanged!(false);
        await tester.pump();
      }
      expect(find.byType(BravenChartPlus), findsNothing);
      expect(
        find.byKey(const ValueKey('synchronized-empty-state')),
        findsOneWidget,
      );

      final addSpeed = find.descendant(
        of: find.byKey(
          const ValueKey('synchronized-speed-visible'),
          skipOffstage: false,
        ),
        matching: find.byType(SwitchListTile, skipOffstage: false),
      );
      tester.widget<SwitchListTile>(addSpeed).onChanged!(true);
      await tester.pump();
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(
        tester.widget<BravenChartPlus>(find.byType(BravenChartPlus)).xAxisConfig
            ?.label,
        'Distance',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Line appearance and synchronization controls are live', (
    tester,
  ) async {
    await pumpPage(tester, const LineChartsPage());

    final markerStyle = find.descendant(
      of: find.byKey(const ValueKey('line-marker-style')),
      matching: find.byType(DropdownButtonFormField<DataPointMarkerStyle>),
    );
    tester
        .widget<DropdownButtonFormField<DataPointMarkerStyle>>(markerStyle)
        .onChanged!(DataPointMarkerStyle.hollow);
    final markerRadius = find.descendant(
      of: find.byKey(const ValueKey('line-marker-radius')),
      matching: find.byType(Slider),
    );
    tester.widget<Slider>(markerRadius).onChanged!(6);
    await tester.pump();

    var lineSeries = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<LineChartSeries>();
    expect(
      lineSeries,
      everyElement(
        isA<LineChartSeries>()
            .having(
              (series) => series.dataPointMarkerStyle,
              'marker style',
              DataPointMarkerStyle.hollow,
            )
            .having(
              (series) => series.dataPointMarkerRadius,
              'marker radius',
              6,
            ),
      ),
    );

    final synchronized = find.descendant(
      of: find.byKey(const ValueKey('line-preset-picker')),
      matching: find.text('Synchronized'),
    );
    await tester.ensureVisible(synchronized);
    await tester.pumpAndSettle();
    await tester.tap(synchronized);
    await tester.pumpAndSettle();

    expect(find.text('Show Legend'), findsNothing);
    expect(find.text('Show Y Scrollbar'), findsNothing);
    expect(find.text('Show X Scrollbar'), findsOneWidget);

    for (final optionKey in const [
      ValueKey('synchronize-cursor'),
      ValueKey('synchronize-viewport'),
      ValueKey('synchronized-intersections'),
    ]) {
      final option = find.descendant(
        of: find.byKey(optionKey, skipOffstage: false),
        matching: find.byType(SwitchListTile, skipOffstage: false),
      );
      final tile = tester.widget<SwitchListTile>(option);
      tile.onChanged!(!tile.value);
      await tester.pump();
    }
    tester
        .widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Show Data Markers'),
        )
        .onChanged!(false);
    tester
        .widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Show X Scrollbar'),
        )
        .onChanged!(true);
    await tester.pump();

    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList();
    expect(charts, hasLength(3));
    expect(
      charts.map((chart) => chart.interactionGroupOptions.synchronizeCursor),
      everyElement(isFalse),
    );
    expect(
      charts
          .expand((chart) => chart.series)
          .map(
            (series) => switch (series) {
              LineChartSeries() => series.showDataPointMarkers,
              AreaChartSeries() => series.showDataPointMarkers,
              _ => null,
            },
          ),
      everyElement(isFalse),
    );
    expect(charts.take(2).map((chart) => chart.showXScrollbar), [false, false]);
    expect(charts.last.showXScrollbar, isTrue);
    expect(
      charts.map((chart) => chart.interactionGroupOptions.synchronizeViewport),
      everyElement(isFalse),
    );
    expect(
      charts.map(
        (chart) => chart.interactionConfig!.crosshair.showIntersectionMarkers,
      ),
      everyElement(isFalse),
    );
    expect(
      charts
          .expand((chart) => chart.series)
          .map(
            (series) => switch (series) {
              LineChartSeries() => series.dataPointMarkerRadius,
              AreaChartSeries() => series.dataPointMarkerRadius,
              _ => null,
            },
          ),
      everyElement(6),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact synchronized stack removes repeated distance axes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LineChartsPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final synchronized = find.descendant(
      of: find.byKey(const ValueKey('line-preset-picker')),
      matching: find.text('Synchronized'),
    );
    await tester.ensureVisible(synchronized);
    await tester.pumpAndSettle();
    await tester.tap(synchronized);
    await tester.pumpAndSettle();

    final charts = tester
        .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
        .toList();
    expect(charts, hasLength(3));
    expect(
      charts.take(2).map((chart) => chart.xAxisConfig?.visible),
      everyElement(isFalse),
    );
    expect(charts.last.xAxisConfig?.visible, isTrue);
    for (final render in _chartRenderFinder().evaluate()) {
      expect(
        (render.renderObject! as ChartRenderBox).size.height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.takeException(), isNull);
  });

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
    expect(chart.xAxisConfig?.label, 'Weekly training load (TSS)');
    expect(chart.yAxis?.label, '20-minute power (W)');
    expect(chart.series.map((series) => series.name), [
      'Base block',
      'Build block',
    ]);
  });

  testWidgets('scatter Cohorts presents a representative athlete dataset', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(find.text('Olympic athlete profiles'), findsOneWidget);
    expect(chart.xAxisConfig?.label, 'Height (cm)');
    expect(chart.yAxis?.label, 'Body mass (kg)');
    expect(scatter.map((series) => series.name), [
      'Triathlon',
      'Volleyball',
      'Basketball',
    ]);
    expect(scatter.map((series) => series.markerShape), [
      SeriesMarkerShape.triangle,
      SeriesMarkerShape.square,
      SeriesMarkerShape.circle,
    ]);
    expect(scatter.expand((series) => series.points), hasLength(44));
  });

  testWidgets('scatter marker controls update the rendered series model', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());

    await tester.tap(find.text('Correlation'));
    await tester.pumpAndSettle();

    final radiusSlider = tester
        .widgetList<Slider>(find.byType(Slider))
        .singleWhere((slider) => slider.min == 2 && slider.max == 10);
    radiusSlider.onChanged?.call(9);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<SeriesMarkerShape>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Square').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(scatter.map((series) => series.markerRadius), [9, 8]);
    expect(
      scatter.every((series) => series.markerShape == SeriesMarkerShape.square),
      isTrue,
    );
  });

  testWidgets('scatter Shapes showcases every visible marker silhouette', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final shapesPreset = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Shapes'),
    );
    await tester.ensureVisible(shapesPreset);
    await tester.tap(shapesPreset);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(
      scatter,
      hasLength(
        SeriesMarkerShape.values
            .where((shape) => shape != SeriesMarkerShape.none)
            .length,
      ),
    );
    expect(
      scatter.map((series) => series.markerShape).toSet(),
      containsAll(
        SeriesMarkerShape.values.where(
          (shape) => shape != SeriesMarkerShape.none,
        ),
      ),
    );
    expect(find.textContaining('mixed shapes'), findsOneWidget);
  });

  testWidgets('scatter Styling exposes the advanced marker-style layer', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final stylingPreset = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Styling'),
    );
    await tester.ensureVisible(stylingPreset);
    await tester.tap(stylingPreset);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(scatter, hasLength(3));
    expect(scatter.every((series) => series.markerStyle != null), isTrue);
    expect(scatter.first.markerStyle?.width, 18);
    expect(scatter.first.markerStyle?.height, 10);
    expect(scatter.first.markerStyle?.strokeWidth, 2);
    expect(scatter.first.markerStyle?.opacity, 0.82);
    expect(
      scatter.first.points.where((point) => point.pointStyle != null),
      hasLength(1),
    );
    expect(
      scatter.first.points[6].pointStyle?.scatterMarkerShape,
      SeriesMarkerShape.star,
    );
    for (final label in const [
      'Fill tone',
      'Marker width',
      'Marker height',
      'Outline width',
      'Rotation',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('scatter-styling-opacity')),
      findsOneWidget,
    );
  });

  testWidgets('scatter Stress exposes configurable dense indexed cohorts', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final stress = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Stress'),
    );
    await tester.ensureVisible(stress);
    await tester.tap(stress);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(scatter, hasLength(3));
    expect(scatter.every((series) => series.points.length == 10000), isTrue);
    expect(scatter.every((series) => series.isXOrdered), isTrue);
    expect(find.text('Points per series'), findsOneWidget);
    expect(find.text('Series count'), findsOneWidget);
  });

  testWidgets('scatter Unsorted preserves deliberately unordered source data', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final unsorted = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Unsorted'),
    );
    await tester.ensureVisible(unsorted);
    await tester.tap(unsorted);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final series = chart.series.whereType<ScatterChartSeries>().first;
    expect(series.isXOrdered, isFalse);
    expect(series.points[1].x, greaterThan(series.points[2].x));
  });

  testWidgets('scatter States exercises selection and linked focus', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final states = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('States'),
    );
    await tester.ensureVisible(states);
    await tester.tap(states);
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(find.text('Interactive point states'), findsOneWidget);
    expect(scatter, hasLength(2));
    expect(scatter.map((series) => series.markerShape), [
      SeriesMarkerShape.circle,
      SeriesMarkerShape.diamond,
    ]);
    expect(scatter.first.interactionStyle.selectionScale, 1.45);
    expect(scatter.first.interactionStyle.dimmedOpacity, 0.22);
    expect(find.text('Selection scale'), findsOneWidget);
    expect(find.text('Unselected opacity'), findsOneWidget);
    expect(find.text('Focus ring gap'), findsOneWidget);

    final selectSample = find.byKey(const ValueKey('scatter-select-sample'));
    await tester.ensureVisible(selectSample);
    await tester.tap(selectSample);
    await tester.pumpAndSettle();
    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final controller = chart.bravenChartController!;
    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'scatter-state-current', pointIndex: 6),
    });

    final focusSample = find.byKey(const ValueKey('scatter-focus-sample'));
    await tester.ensureVisible(focusSample);
    await tester.tap(focusSample);
    await tester.pumpAndSettle();
    expect(controller.focusedPointRefs, {
      const ChartPointRef(seriesId: 'scatter-state-previous', pointIndex: 8),
    });

    final clear = find.byKey(const ValueKey('scatter-clear-states'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(controller.selectedPointRefs, isEmpty);
    expect(controller.focusedPointRefs, isEmpty);
  });

  testWidgets('scatter Bubble maps a third metric and exposes its scale', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final bubble = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Bubble'),
    );
    await tester.ensureVisible(bubble);
    await tester.tap(bubble);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(find.text('Market opportunity map'), findsOneWidget);
    expect(find.textContaining('X: revenue growth'), findsOneWidget);
    expect(scatter, hasLength(2));
    expect(scatter.every((series) => series.sizeEncoding != null), isTrue);
    expect(
      scatter.every((series) => series.sizeEncoding!.minimumValue == 95),
      isTrue,
    );
    expect(scatter.expand((series) => series.points), hasLength(10));
    expect(
      scatter
          .expand((series) => series.points)
          .every((point) => point.magnitude != null),
      isTrue,
    );
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legends = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .toList();
    expect(legends, hasLength(2));
    expect(
      legends
          .singleWhere((legend) => legend.annotation.sizeScale != null)
          .annotation
          .sizeScale
          ?.label,
      'Active accounts',
    );
    expect(scatter.first.points.first.label, 'North America');
    expect(find.text('Small bubble'), findsOneWidget);
    expect(find.text('Large bubble'), findsOneWidget);
  });

  testWidgets('scatter Color scale maps an independent continuous metric', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final colorScale = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Color scale'),
    );
    await tester.ensureVisible(colorScale);
    await tester.tap(colorScale);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(find.text('Athlete readiness map'), findsOneWidget);
    expect(
      find.textContaining('Marker color: recovery readiness'),
      findsOneWidget,
    );
    expect(scatter, hasLength(2));
    expect(scatter.every((series) => series.colorEncoding != null), isTrue);
    expect(
      scatter
          .expand((series) => series.points)
          .every((point) => point.colorValue != null),
      isTrue,
    );
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legends = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .toList();
    expect(legends, hasLength(2));
    expect(
      legends
          .singleWhere((legend) => legend.annotation.colorScale != null)
          .annotation
          .colorScale
          ?.label,
      'Recovery readiness',
    );
    expect(find.byKey(const ValueKey('scatter-color-ramp')), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<SeriesMarkerShape>),
      findsNothing,
    );
  });

  testWidgets('scatter Bands uses explicit piecewise risk thresholds', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final bands = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Bands'),
    );
    await tester.ensureVisible(bands);
    await tester.tap(bands);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().single;
    final encoding = scatter.colorEncoding!;
    expect(find.text('Equipment risk map'), findsOneWidget);
    expect(encoding.scaleType, ScatterColorScaleType.piecewise);
    expect(encoding.thresholds, const [35, 60, 80]);
    expect(encoding.bandLabels, const [
      'Normal',
      'Monitor',
      'Warning',
      'Critical',
    ]);
    expect(encoding.bandLabelFor(35), 'Monitor');
    expect(encoding.bandLabelFor(80), 'Critical');
    expect(find.byKey(const ValueKey('scatter-risk-palette')), findsOneWidget);

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final quantitative = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .singleWhere((legend) => legend.annotation.colorScale != null);
    expect(
      quantitative.annotation.colorScale?.type,
      LegendColorScaleType.piecewise,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scatter Opacity maps confidence and exposes a native scale', (
    tester,
  ) async {
    await pumpPage(tester, const ScatterChartsPage());
    final opacity = find.descendant(
      of: find.byKey(const ValueKey('scatter-preset-picker')),
      matching: find.text('Opacity'),
    );
    await tester.ensureVisible(opacity);
    await tester.tap(opacity);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final scatter = chart.series.whereType<ScatterChartSeries>().toList();
    expect(find.text('Demand forecast confidence'), findsOneWidget);
    expect(
      find.textContaining('Marker opacity: model confidence'),
      findsOneWidget,
    );
    expect(scatter, hasLength(2));
    expect(scatter.every((series) => series.opacityEncoding != null), isTrue);
    expect(
      scatter
          .expand((series) => series.points)
          .every((point) => point.opacityValue != null),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('scatter-minimum-opacity')),
      findsOneWidget,
    );
    expect(
      find.byType(DropdownButtonFormField<SeriesMarkerShape>),
      findsNothing,
    );

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final quantitative = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .singleWhere((legend) => legend.annotation.opacityScale != null);
    expect(quantitative.annotation.opacityScale?.label, 'Model confidence');

    final slider = find.descendant(
      of: find.byKey(const ValueKey('scatter-minimum-opacity')),
      matching: find.byType(Slider),
    );
    await tester.drag(slider, const Offset(90, 0));
    await tester.pumpAndSettle();
    final updated = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    expect(
      (updated.series.first as ScatterChartSeries)
          .opacityEncoding!
          .minimumOpacity,
      greaterThan(0.18),
    );
    expect(tester.takeException(), isNull);
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

  testWidgets(
    'every Line and Area preset completes the wide Workbench surface matrix',
    (tester) async {
      const lineSourceSeriesByPreset = <String, String>{
        'Workhorse': 'observed',
        'Interpolation': 'interpolation-linear',
        'Multi-axis': 'power',
        'Motion': 'motion-observed',
        'Comparison': 'comparison-current',
        'Envelope': 'capacity-envelope',
        'Spotlight': 'spotlight-signal',
        'Forecast': 'forecast-continuous',
      };
      const families = <({String name, Widget page, List<String> presets})>[
        (
          name: 'line',
          page: LineChartsPage(),
          presets: [
            'Workhorse',
            'Interpolation',
            'Multi-axis',
            'Motion',
            'Comparison',
            'Envelope',
            'Spotlight',
            'Forecast',
            'Synchronized',
          ],
        ),
        (
          name: 'area',
          page: AreaChartsPage(),
          presets: [
            'Layered',
            'Baseline',
            'Forecast',
            'Motion',
            'Gradient',
            'Composition',
            'Pulse',
          ],
        ),
      ];

      for (final family in families) {
        await pumpPage(tester, family.page);
        final picker = find.byKey(ValueKey('${family.name}-preset-picker'));

        for (final preset in family.presets) {
          final presetControl = find.descendant(
            of: picker,
            matching: find.text(preset),
          );
          await tester.ensureVisible(presetControl);
          await tester.pumpAndSettle();
          await tester.tap(presetControl);
          await tester.pumpAndSettle();

          final charts = find.byType(BravenChartPlus);
          if (preset == 'Synchronized') {
            expect(charts, findsNWidgets(3), reason: '$preset chart count');
            expect(find.byType(BravenChartWorkbench), findsNothing);
            expect(
              find.byKey(const ValueKey('synchronized-cartesian-stack')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull, reason: '$preset surface');
            continue;
          }

          expect(charts, findsOneWidget, reason: '$preset chart surface');
          expect(
            tester.widget<BravenChartPlus>(charts).series,
            isNotEmpty,
            reason: '$preset canonical series',
          );
          final switcher = find.byKey(
            const ValueKey('chart-workbench-mode-switcher'),
          );
          expect(switcher, findsOneWidget, reason: '$preset mode switcher');

          for (final mode in const <(String, ChartDisplayMode)>[
            ('Chart', ChartDisplayMode.chart),
            ('Data', ChartDisplayMode.data),
            ('Split', ChartDisplayMode.split),
            ('Source', ChartDisplayMode.source),
          ]) {
            final (label, displayMode) = mode;
            await tester.tap(
              find.descendant(of: switcher, matching: find.text(label)),
            );
            await tester.pumpAndSettle();

            final workbench = tester.widget<BravenChartWorkbench>(
              find.byType(BravenChartWorkbench),
            );
            final controller = workbench.workbenchController!;
            expect(
              controller.requestedMode,
              displayMode,
              reason: '$preset requested $label mode',
            );
            expect(
              controller.effectiveMode,
              displayMode,
              reason: '$preset effective $label mode',
            );

            switch (displayMode) {
              case ChartDisplayMode.chart:
                expect(find.byType(BravenChartPlus), findsOneWidget);
              case ChartDisplayMode.data:
                expect(find.byType(ChartDataTable), findsOneWidget);
                expect(
                  controller.tableState.phase,
                  ChartWorkbenchTablePhase.ready,
                );
              case ChartDisplayMode.split:
                expect(find.byType(BravenChartPlus), findsOneWidget);
                expect(find.byType(ChartDataTable), findsOneWidget);
                expect(
                  find.byKey(const ValueKey('chart-workbench-split-handle')),
                  findsOneWidget,
                );
              case ChartDisplayMode.source:
                expect(find.byType(ChartSourceView), findsOneWidget);
                expect(
                  controller.sourceState.phase,
                  ChartWorkbenchSourcePhase.ready,
                );
                expect(
                  controller.generatedSource!.source,
                  contains('final ${family.name}Chart = BravenChartPlus('),
                );
                if (family.name == 'line') {
                  expect(
                    controller.generatedSource!.source,
                    contains("id: '${lineSourceSeriesByPreset[preset]}'"),
                    reason: '$preset generated source matches its live series',
                  );
                }
            }
            expect(
              find.textContaining('not attached to a mounted chart'),
              findsNothing,
              reason: '$preset $label controller attachment',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$preset $label surface',
            );
          }
        }
      }
    },
  );

  testWidgets('every Line and Area preset renders inside a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const families = <({String name, Widget page, List<String> presets})>[
      (
        name: 'line',
        page: LineChartsPage(),
        presets: [
          'Workhorse',
          'Interpolation',
          'Multi-axis',
          'Motion',
          'Comparison',
          'Envelope',
          'Spotlight',
          'Forecast',
          'Synchronized',
        ],
      ),
      (
        name: 'area',
        page: AreaChartsPage(),
        presets: [
          'Layered',
          'Baseline',
          'Forecast',
          'Motion',
          'Gradient',
          'Composition',
          'Pulse',
        ],
      ),
    ];

    for (final family in families) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: family.page)));
      await tester.pump(const Duration(milliseconds: 300));
      final picker = find.byKey(ValueKey('${family.name}-preset-picker'));

      for (final preset in family.presets) {
        final presetControl = find.descendant(
          of: picker,
          matching: find.text(preset),
        );
        await tester.ensureVisible(presetControl);
        await tester.pumpAndSettle();
        await tester.tap(presetControl);
        await tester.pumpAndSettle();

        final activeLabel = tester.getRect(presetControl);
        expect(activeLabel.left, greaterThanOrEqualTo(0), reason: preset);
        expect(activeLabel.right, lessThanOrEqualTo(390), reason: preset);
        final charts = find.byType(BravenChartPlus);
        expect(
          charts,
          preset == 'Synchronized' ? findsNWidgets(3) : findsOneWidget,
          reason: '$preset compact chart count',
        );
        for (final render in _chartRenderFinder().evaluate()) {
          final size = (render.renderObject! as ChartRenderBox).size;
          expect(size.width, greaterThanOrEqualTo(48), reason: preset);
          expect(size.height, greaterThanOrEqualTo(48), reason: preset);
        }
        expect(tester.takeException(), isNull, reason: '$preset compact');
      }
    }
  });

  testWidgets(
    'Line synchronized and Area standard surfaces honor light and dark',
    (tester) async {
      for (final entry
          in const <({Widget page, String? preset, int chartCount})>[
            (page: LineChartsPage(), preset: 'Synchronized', chartCount: 3),
            (page: AreaChartsPage(), preset: null, chartCount: 1),
          ]) {
        await pumpPage(tester, entry.page);
        if (entry.preset case final preset?) {
          final presetControl = find.descendant(
            of: find.byKey(const ValueKey('line-preset-picker')),
            matching: find.text(preset),
          );
          await tester.ensureVisible(presetControl);
          await tester.pumpAndSettle();
          await tester.tap(presetControl);
          await tester.pumpAndSettle();
        }

        final themeControl = find.byType(DropdownButtonFormField<ThemePreset>);
        expect(themeControl, findsOneWidget);
        await tester.tap(themeControl);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle();
        var charts = tester
            .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
            .toList();
        expect(charts, hasLength(entry.chartCount));
        expect(
          charts.map((chart) => chart.theme?.backgroundColor),
          everyElement(ChartTheme.dark.backgroundColor),
        );

        await tester.tap(find.byType(DropdownButtonFormField<ThemePreset>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Light').last);
        await tester.pumpAndSettle();
        charts = tester
            .widgetList<BravenChartPlus>(find.byType(BravenChartPlus))
            .toList();
        expect(
          charts.map((chart) => chart.theme?.backgroundColor),
          everyElement(ChartTheme.light.backgroundColor),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

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

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
