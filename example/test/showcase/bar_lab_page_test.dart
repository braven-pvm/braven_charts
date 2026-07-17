import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/bar_lab_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: Scaffold(body: BarLabPage()));

  testWidgets('shows a live bar review surface and style controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Bar Lab'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('Progress against capacity'), findsOneWidget);
    expect(find.text('Series count'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Capacity tracks'), findsOneWidget);
    expect(find.text('Value labels'), findsOneWidget);
    expect(find.text('Edge offset'), findsOneWidget);
    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .whereType<BarChartSeries>()
          .every((series) => series.labelStyle.padding == 8),
      isTrue,
    );
  });

  testWidgets('changes the number of grouped bar series', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(
      tester.widget<BravenChartPlus>(find.byType(BravenChartPlus)).series,
      hasLength(2),
    );

    await tester.drag(find.byType(Slider).first, const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BravenChartPlus>(find.byType(BravenChartPlus)).series,
      hasLength(12),
    );
    expect(find.textContaining('12 series · vertical'), findsOneWidget);
  });

  testWidgets('changes the end-label edge offset', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final edgeOffsetOption = find.byWidgetPredicate(
      (widget) => widget is SliderOption && widget.label == 'Edge offset',
    );
    await tester.ensureVisible(edgeOffsetOption);
    await tester.pumpAndSettle();
    final edgeOffsetSlider = find.descendant(
      of: edgeOffsetOption,
      matching: find.byType(Slider),
    );
    await tester.drag(edgeOffsetSlider, const Offset(1000, 0));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BravenChartPlus>(find.byType(BravenChartPlus))
          .series
          .whereType<BarChartSeries>()
          .every((series) => series.labelStyle.padding == 20),
      isTrue,
    );
  });

  testWidgets('switches to normalized named stacks', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100% stacked').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) =>
            series.layoutMode == BarLayoutMode.normalizedStacked &&
            series.groupId != null &&
            series.labelStyle.valueMode == BarLabelValueMode.percentage,
      ),
      isTrue,
    );
    expect(find.text('Named stacks'), findsOneWidget);
    expect(find.textContaining('100% stacked · 1 stack'), findsOneWidget);
  });

  testWidgets('overlays series with deterministic layer widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overlaid').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final bars = chart.series.whereType<BarChartSeries>().toList();
    expect(bars, hasLength(2));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );
    expect(bars.first.groupId, bars.last.groupId);
    expect(bars.first.overlayWidthFactor, 1);
    expect(bars.last.overlayWidthFactor, closeTo(0.78, 0.001));
    expect(bars.every((series) => series.overlayOffsetFactor == 0), isTrue);
    expect(bars.first.labelStyle.show, isFalse);
    expect(bars.last.labelStyle.show, isTrue);
    expect(find.text('Overlay groups'), findsOneWidget);
    expect(find.text('Layer inset'), findsOneWidget);
    expect(find.text('Layer offset'), findsOneWidget);
    expect(find.textContaining('overlaid · 1 group'), findsOneWidget);
  });

  testWidgets('switches between reference-driven presets', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gradient').first);
    await tester.pumpAndSettle();

    expect(find.text('Value-axis gradients'), findsOneWidget);
    expect(
      find.text(
        'Gradients follow each bar from its baseline to its value end.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('transposes the live chart when orientation changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BarOrientation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(
      chart.series.whereType<BarChartSeries>().every(
        (series) => series.orientation == BarOrientation.horizontal,
      ),
      isTrue,
    );
    expect(chart.interactionConfig?.crosshair.mode, CrosshairMode.both);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal bars remain rendered after repeated pan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final axesPreset = find.byKey(const ValueKey('bar-lab-preset-axes'));
    await tester.ensureVisible(axesPreset);
    await tester.tap(axesPreset);
    await tester.pumpAndSettle();

    final renderBox = tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final fullTransform = renderBox.transform!;
    final categoryCenter =
        (fullTransform.dataXMin + fullTransform.dataXMax) / 2;
    final categoryHalfRange = fullTransform.dataXRange / 4;
    expect(
      renderBox.restoreVisibleDataBounds(
        xMin: categoryCenter - categoryHalfRange,
        xMax: categoryCenter + categoryHalfRange,
        yMin: fullTransform.dataYMin,
        yMax: fullTransform.dataYMax,
      ),
      isTrue,
    );

    for (var index = 0; index < 6; index++) {
      renderBox.panChart(-200, 0);
      await tester.pump();
    }

    final pannedTransform = renderBox.transform!;
    final maximumWhitespace = fullTransform.dataYRange * 0.1;

    expect(tester.takeException(), isNull);
    expect(pannedTransform.transposed, isTrue);
    expect(
      pannedTransform.dataYMin,
      greaterThanOrEqualTo(fullTransform.dataYMin - maximumWhitespace - 0.001),
    );
    expect(
      _hasVisibleSeriesHit(renderBox),
      isTrue,
      reason: 'Panning must not move every horizontal bar off-screen',
    );
  });

  testWidgets('range bounds update when more series are added', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final rangePreset = find.byKey(const ValueKey('bar-lab-preset-range'));
    await tester.ensureVisible(rangePreset);
    await tester.pumpAndSettle();
    await tester.tap(rangePreset);
    await tester.pumpAndSettle();

    var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect(chart.yAxis?.min, isNull);
    expect(chart.yAxis?.max, isNull);

    await tester.drag(find.byType(Slider).first, const Offset(1000, 0));
    await tester.pumpAndSettle();

    chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    final bars = chart.series.whereType<BarChartSeries>().toList();
    expect(bars, hasLength(12));
    expect(chart.yAxis?.min, isNull);
    expect(chart.yAxis?.max, isNull);
    expect(
      bars
          .expand((series) => series.points)
          .every((point) => point.y >= 22 && point.y <= 32),
      isTrue,
    );
    expect(
      bars
          .expand((series) => series.rangeStartValues)
          .whereType<double>()
          .every((value) => value >= 11 && value <= 24),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick-jumps to every shipped composition setup', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final presetSelector = find.byKey(const ValueKey('bar-lab-preset-wrap'));
    Future<void> tapPreset(String label) async {
      final target = find.descendant(
        of: presetSelector,
        matching: find.text(label),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    for (final label in [
      'Capacity',
      'Targets',
      'Rods',
      'Gradient',
      'Signed',
      'Overlay',
      'Offset',
      'Range',
      'Waterfall',
      'Horizontal',
      'Axes',
      'Motion',
      'States',
      'Stacked',
      '100%',
    ]) {
      expect(
        find.descendant(of: presetSelector, matching: find.text(label)),
        findsOneWidget,
      );
    }

    final firstPreset = find.byKey(const ValueKey('bar-lab-preset-capacity'));
    final lastPreset = find.byKey(const ValueKey('bar-lab-preset-normalized'));
    expect(
      tester.getTopLeft(lastPreset).dy,
      greaterThan(tester.getTopLeft(firstPreset).dy),
      reason: 'The full preset set should wrap instead of clipping offscreen.',
    );

    await tapPreset('Overlay');
    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Layered comparisons'), findsOneWidget);
    expect(bars, hasLength(4));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );
    expect(bars.map((series) => series.groupId).toSet(), hasLength(2));

    await tapPreset('Offset');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Offset comparisons'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(bars.first.name, 'Summer 2020');
    expect(bars.last.name, 'Current result');
    expect(bars.first.overlayWidthFactor, 1);
    expect(bars.last.overlayWidthFactor, 1);
    expect(bars.first.overlayOffsetFactor, closeTo(-0.15, 0.001));
    expect(bars.last.overlayOffsetFactor, closeTo(0.15, 0.001));
    expect(bars.first.points, hasLength(5));
    expect(
      bars.last.points.every((point) => point.pointStyle?.color != null),
      isTrue,
    );

    await tapPreset('Range');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Floating temperature ranges'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(bars.first.name, 'Observed');
    expect(bars.last.name, 'Forecast');
    expect(bars.first.rangeStartValues, const [14, 17, 15, 19, 16, 13, 14]);
    expect(bars.last.rangeStartValues, const [12, 16, 18, 17, 15, 14, 17]);
    expect(
      bars.every(
        (series) =>
            series.hasRangeValues &&
            series.labelStyle.valueMode == BarLabelValueMode.range &&
            series.labelStyle.position == BarLabelPosition.rangeEnds &&
            series.barStyle.cornerRadiusPolicy == BarCornerRadiusPolicy.all,
      ),
      isTrue,
    );
    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    expect(find.text('Overlaid'), findsOneWidget);
    expect(
      tester
          .widgetList<DropdownMenuItem<BarLayoutMode>>(
            find.byType(DropdownMenuItem<BarLayoutMode>),
          )
          .map((item) => item.value)
          .toSet(),
      {BarLayoutMode.grouped, BarLayoutMode.overlaid},
    );
    await tester.tap(find.text('Overlaid'));
    await tester.pumpAndSettle();
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.overlaid),
      isTrue,
    );

    await tapPreset('Waterfall');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Cash-flow bridge'), findsOneWidget);
    expect(find.text('Increase'), findsOneWidget);
    expect(find.text('Decrease'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Connectors'), findsOneWidget);
    expect(bars, hasLength(1));
    expect(bars.single.layoutMode, BarLayoutMode.waterfall);
    expect(bars.single.waterfallTotalIndices, const {6});
    expect(bars.single.waterfallDisplayValueFor(6), 91);
    expect(bars.single.labelStyle.valueMode, BarLabelValueMode.waterfall);
    expect(bars.single.waterfallStyle.connector.show, isTrue);
    await tester.tap(find.byType(DropdownButtonFormField<BarLayoutMode>));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DropdownMenuItem<BarLayoutMode>>(
            find.byType(DropdownMenuItem<BarLayoutMode>),
          )
          .map((item) => item.value)
          .toSet(),
      {BarLayoutMode.waterfall},
    );
    await tester.tap(find.text('Waterfall').last);
    await tester.pumpAndSettle();

    await tapPreset('Horizontal');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    final horizontalChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    expect(find.text('Revenue by channel'), findsOneWidget);
    expect(bars, hasLength(2));
    expect(
      bars.every(
        (series) =>
            series.orientation == BarOrientation.horizontal &&
            series.layoutMode == BarLayoutMode.grouped,
      ),
      isTrue,
    );
    expect(
      bars.first.points.map((point) => point.y),
      orderedEquals([96, 84, 73, 61, 49, 36]),
    );
    expect(horizontalChart.xAxisConfig?.label, 'Channel');
    expect(horizontalChart.yAxis?.label, 'Revenue (thousands)');
    expect(
      horizontalChart.interactionConfig?.crosshair.mode,
      CrosshairMode.both,
    );

    await tapPreset('Axes');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    final axesChart = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    expect(find.text('Independent channel metrics'), findsOneWidget);
    expect(bars, hasLength(4));
    expect(
      bars.every(
        (series) =>
            series.orientation == BarOrientation.horizontal &&
            series.yAxisConfig != null &&
            series.yAxisConfig!.showCrosshairLabel,
      ),
      isTrue,
    );
    expect(
      bars.map((series) => series.yAxisConfig!.position),
      orderedEquals([
        YAxisPosition.left,
        YAxisPosition.right,
        YAxisPosition.right,
        YAxisPosition.left,
      ]),
    );
    expect(axesChart.normalizationMode, NormalizationMode.perSeries);
    expect(axesChart.maxAxesPerSide, 3);
    expect(tester.takeException(), isNull);

    await tapPreset('States');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Interactive bar states'), findsOneWidget);
    expect(find.text('Inactive opacity', skipOffstage: false), findsOneWidget);
    expect(bars, hasLength(3));
    expect(
      bars.every((series) => series.barStyle.interaction.dimmedOpacity == 0.32),
      isTrue,
    );
    expect(
      bars.expand((series) => series.points).every((point) => point.hasLabel),
      isTrue,
    );

    await tapPreset('Stacked');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('Named stacked totals'), findsOneWidget);
    expect(bars, hasLength(6));
    expect(
      bars.every((series) => series.layoutMode == BarLayoutMode.stacked),
      isTrue,
    );
    expect(bars.map((series) => series.groupId).toSet(), hasLength(2));

    await tapPreset('100%');
    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(find.text('100% stacked composition'), findsOneWidget);
    expect(
      bars.every(
        (series) =>
            series.layoutMode == BarLayoutMode.normalizedStacked &&
            series.labelStyle.valueMode == BarLabelValueMode.percentage,
      ),
      isTrue,
    );
  });

  testWidgets('shows benchmark markers and transposes them with the chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-targets')));
    await tester.pumpAndSettle();

    expect(find.text('Actual against target'), findsOneWidget);
    expect(find.text('Target markers', skipOffstage: false), findsOneWidget);
    expect(find.text('Marker width', skipOffstage: false), findsOneWidget);
    expect(find.text('Marker span', skipOffstage: false), findsOneWidget);

    var bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars, hasLength(1));
    expect(bars.single.name, 'Actual');
    expect(bars.single.targetValues, const [72, 78, 85, 68, 84, 95, 76]);
    expect(bars.single.targetMarkerStyle.width, 2);

    var renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    var element = renderBox.debugElements.whereType<SeriesElement>().single;
    var geometry = element.barGeometryForPoint(0)!;
    expect(geometry.targetStart, isNotNull);
    expect(geometry.targetEnd, isNotNull);
    expect(geometry.targetStart!.dy, closeTo(geometry.targetEnd!.dy, 0.001));

    await tester.tap(find.byType(DropdownButtonFormField<BarOrientation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horizontal').last);
    await tester.pumpAndSettle();

    bars = tester
        .widget<BravenChartPlus>(find.byType(BravenChartPlus))
        .series
        .whereType<BarChartSeries>()
        .toList();
    expect(bars.single.orientation, BarOrientation.horizontal);
    renderBox = tester.allRenderObjects.whereType<ChartRenderBox>().single;
    element = renderBox.debugElements.whereType<SeriesElement>().single;
    geometry = element.barGeometryForPoint(0)!;
    expect(geometry.targetStart!.dx, closeTo(geometry.targetEnd!.dx, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays bar values from the Motion preset', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bar-lab-preset-motion')));
    await tester.pumpAndSettle();

    expect(find.text('Animated value updates'), findsOneWidget);
    expect(find.text('Duration', skipOffstage: false), findsOneWidget);
    expect(find.text('Animate bars', skipOffstage: false), findsOneWidget);

    final replay = find.byKey(
      const ValueKey('bar-lab-replay-motion'),
      skipOffstage: false,
    );
    await tester.ensureVisible(replay);
    await tester.pumpAndSettle();
    await tester.tap(replay);
    await tester.pump();
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 325));

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final animatedValue =
        (renderBox.debugElements.whereType<SeriesElement>().first.series
                as BarChartSeries)
            .points
            .first
            .y;
    expect(animatedValue, greaterThan(54));
    expect(animatedValue, lessThan(82));

    await tester.pumpAndSettle();
    final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
    expect((chart.series.first as BarChartSeries).points.first.y, 82);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps chart options reachable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

bool _hasVisibleSeriesHit(ChartRenderBox renderBox) {
  for (var x = 4.0; x < renderBox.plotWidth; x += 6) {
    for (var y = 4.0; y < renderBox.plotHeight; y += 6) {
      final hit = renderBox.hitTestElements(
        renderBox.plotToWidget(Offset(x, y)),
      );
      if (hit is SeriesElement) return true;
    }
  }
  return false;
}
