import 'package:braven_charts/src/artifacts/chart_view_state.dart';
import 'package:braven_charts/src/braven_chart_plus.dart';
import 'package:braven_charts/src/interaction/core/data_hit.dart';
import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/models/braven_chart_controller.dart';
import 'package:braven_charts/src/models/candlestick_chart_series.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
import 'package:braven_charts/src/models/chart_context_action.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/interaction_callbacks.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/range_area_chart_series.dart';
import 'package:braven_charts/src/models/range_area_data_point.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final families = <String, List<ChartSeries> Function()>{
    'Line': () => [
      LineChartSeries(
        id: 'line',
        showDataPointMarkers: true,
        points: _cartesianPoints,
      ),
    ],
    'Area': () => [
      AreaChartSeries(
        id: 'area',
        showDataPointMarkers: true,
        points: _cartesianPoints,
      ),
    ],
    'Range Area': () => [
      RangeAreaChartSeries(
        id: 'range-area',
        showBoundaryMarkers: true,
        points: _rangePoints,
      ),
    ],
    'Bar (horizontal)': () => [
      BarChartSeries(
        id: 'bar',
        points: _cartesianPoints,
        barWidthPercent: 0.65,
        orientation: BarOrientation.horizontal,
      ),
    ],
    'Scatter': () => [
      ScatterChartSeries(
        id: 'scatter',
        points: _cartesianPoints,
        markerRadius: 7,
      ),
    ],
    'Candlestick': () => [
      CandlestickChartSeries(id: 'candlestick', points: _candlestickPoints),
    ],
  };

  for (final family in families.entries) {
    testWidgets(
      '${family.key} supports touch zoom, pan, selection, and one final rebuild',
      (tester) async {
        final scrollController = ScrollController();
        final chartController = BravenChartController();
        final chartSeries = family.value();
        final tappedPoints = <ChartDataPoint>[];
        addTearDown(scrollController.dispose);
        addTearDown(chartController.dispose);
        await tester.pumpWidget(
          _TouchReleaseHarness(
            scrollController: scrollController,
            chartController: chartController,
            series: chartSeries,
            touch: const TouchInteractionConfig(
              profile: TouchInteractionProfile.explore,
            ),
            onDataPointTap: (point, position) => tappedPoints.add(point),
          ),
        );
        await tester.pumpAndSettle();

        final renderBox = _renderBox(tester);
        final initialHit = renderBox.dataHitForPointIndex(
          chartSeries.first.id,
          2,
        );
        expect(initialHit, isNotNull);
        final initialTap = await tester.createGesture(
          pointer: 100,
          kind: PointerDeviceKind.touch,
        );
        final initialWidgetPosition = _resolvableWidgetPosition(
          renderBox,
          initialHit!,
        );
        await initialTap.down(renderBox.localToGlobal(initialWidgetPosition));
        await tester.pump();
        await initialTap.up();
        await tester.pumpAndSettle();
        expect(
          chartController.selectedPointRefs,
          contains(
            ChartPointRef(
              seriesId: initialHit.seriesId,
              pointIndex: initialHit.pointIndex,
            ),
          ),
        );
        expect(tappedPoints, isNotEmpty);
        chartController.clearSelection();

        final initialSpan = _xSpan(renderBox);
        final rebuildsBeforePinch = renderBox.debugElementRebuildCount;
        final chartCenter = tester.getCenter(find.byType(BravenChartPlus));
        final first = await tester.createGesture(
          pointer: 101,
          kind: PointerDeviceKind.touch,
        );
        final second = await tester.createGesture(
          pointer: 102,
          kind: PointerDeviceKind.touch,
        );
        await first.down(chartCenter - const Offset(32, 0));
        await second.down(chartCenter + const Offset(32, 0));
        await tester.pump();
        await first.moveTo(chartCenter - const Offset(88, 0));
        await second.moveTo(chartCenter + const Offset(88, 0));
        await tester.pump();

        expect(
          renderBox.debugElementRebuildCount,
          rebuildsBeforePinch,
          reason: 'continuous touch updates must remain paint-only',
        );

        await first.up();
        await second.up();
        await tester.pump();

        expect(_xSpan(renderBox), lessThan(initialSpan));
        expect(
          renderBox.debugElementRebuildCount,
          rebuildsBeforePinch + 1,
          reason: 'geometry and the hit index rebuild once when pinch settles',
        );
        expect(scrollController.offset, 0);

        final boundsBeforePan = _viewportBounds(renderBox);
        final pan = await tester.createGesture(
          pointer: 103,
          kind: PointerDeviceKind.touch,
        );
        await pan.down(chartCenter);
        await tester.pump();
        await pan.moveBy(const Offset(-24, 0));
        await tester.pump();
        await pan.moveBy(const Offset(-48, 0));
        await tester.pump();
        await pan.up();
        await tester.pumpAndSettle();

        expect(_viewportBounds(renderBox), isNot(boundsBeforePan));
        expect(scrollController.offset, 0);
        expect(renderBox.coordinator.currentMode, InteractionMode.idle);
        expect(renderBox.debugIsSuppressingTouchSequence, isFalse);
      },
    );
  }

  testWidgets(
    'pinch preserves the data value under an off-center focal point',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        _TouchReleaseHarness(
          scrollController: scrollController,
          series: _lineSeries(),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = _renderBox(tester);
      final focalWidget = renderBox.plotToWidget(
        renderBox.transform!.dataToPlot(3.8, 6.2),
      );
      final focalPlot = renderBox.widgetToPlot(focalWidget);
      final dataBefore = renderBox.transform!.plotToData(
        focalPlot.dx,
        focalPlot.dy,
      );
      final focalGlobal = renderBox.localToGlobal(focalWidget);

      await _pinch(
        tester,
        focalPoint: focalGlobal,
        startRadius: 28,
        endRadius: 92,
        pointerBase: 120,
      );

      final dataAfter = renderBox.transform!.plotToData(
        focalPlot.dx,
        focalPlot.dy,
      );
      expect(dataAfter.dx, closeTo(dataBefore.dx, 0.0001));
      expect(dataAfter.dy, closeTo(dataBefore.dy, 0.0001));
    },
  );

  testWidgets('browse two-finger translation pans without scrolling the page', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final chartController = BravenChartController();
    addTearDown(scrollController.dispose);
    addTearDown(chartController.dispose);
    await tester.pumpWidget(
      _TouchReleaseHarness(
        scrollController: scrollController,
        chartController: chartController,
        series: _lineSeries(),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    expect(chartController.zoomViewport(2), isTrue);
    await tester.pumpAndSettle();
    final minBefore = renderBox.transform!.dataXMin;
    final center = tester.getCenter(find.byType(BravenChartPlus));
    final first = await tester.createGesture(
      pointer: 131,
      kind: PointerDeviceKind.touch,
    );
    final second = await tester.createGesture(
      pointer: 132,
      kind: PointerDeviceKind.touch,
    );
    await first.down(center - const Offset(30, 0));
    await second.down(center + const Offset(30, 0));
    await tester.pump();
    await first.moveBy(const Offset(-70, 0));
    await second.moveBy(const Offset(-70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(renderBox.transform!.dataXMin, isNot(minBefore));
    expect(scrollController.offset, 0);
  });

  testWidgets(
    'opt-in touch inertia coasts, settles, and cancels on new touch',
    (tester) async {
      final scrollController = ScrollController();
      final chartController = BravenChartController();
      addTearDown(scrollController.dispose);
      addTearDown(chartController.dispose);
      await tester.pumpWidget(
        _TouchReleaseHarness(
          scrollController: scrollController,
          chartController: chartController,
          series: _lineSeries(),
          touch: const TouchInteractionConfig(
            profile: TouchInteractionProfile.explore,
            enablePanInertia: true,
            panInertiaDeceleration: 4,
            maximumPanInertiaVelocity: 2400,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = _renderBox(tester);
      expect(chartController.zoomViewport(2), isTrue);
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.byType(BravenChartPlus));
      final pan = await tester.createGesture(
        pointer: 133,
        kind: PointerDeviceKind.touch,
      );
      await pan.down(center);
      await tester.pump(const Duration(milliseconds: 16));
      await pan.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await pan.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final minAtRelease = renderBox.transform!.dataXMin;
      await pan.up();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        renderBox.transform!.dataXMin,
        isNot(minAtRelease),
        reason: 'release velocity should continue moving the viewport',
      );

      final cancel = await tester.createGesture(
        pointer: 134,
        kind: PointerDeviceKind.touch,
      );
      await cancel.down(center);
      await tester.pump();
      final minAtCancel = renderBox.transform!.dataXMin;
      await tester.pump(const Duration(milliseconds: 300));
    expect(renderBox.transform!.dataXMin, closeTo(minAtCancel, 0.001));
      await cancel.up();
      await tester.pumpAndSettle();

      expect(renderBox.coordinator.currentMode, InteractionMode.idle);
      expect(scrollController.offset, 0);
    },
  );

  testWidgets('touch and global zoom gates both block pinch scaling', (
    tester,
  ) async {
    for (final config in [
      (
        touch: const TouchInteractionConfig(
          enablePinchZoom: false,
          enablePan: false,
        ),
        enableZoom: true,
      ),
      (
        touch: const TouchInteractionConfig(enablePan: false),
        enableZoom: false,
      ),
    ]) {
      final scrollController = ScrollController();
      await tester.pumpWidget(
        _TouchReleaseHarness(
          key: ValueKey(config),
          scrollController: scrollController,
          series: _lineSeries(),
          touch: config.touch,
          enableZoom: config.enableZoom,
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = _renderBox(tester);
      final spanBefore = _xSpan(renderBox);
      final rebuildsBefore = renderBox.debugElementRebuildCount;
      await _pinch(
        tester,
        focalPoint: tester.getCenter(find.byType(BravenChartPlus)),
        startRadius: 30,
        endRadius: 90,
        pointerBase: config.enableZoom ? 140 : 150,
      );

      expect(_xSpan(renderBox), closeTo(spanBefore, 0.0001));
      expect(renderBox.debugElementRebuildCount, rebuildsBefore);
      scrollController.dispose();
    }
  });

  testWidgets('disabled pan returns one-finger Explore dragging to the page', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      _TouchReleaseHarness(
        scrollController: scrollController,
        series: _lineSeries(),
        touch: const TouchInteractionConfig(
          profile: TouchInteractionProfile.explore,
          enablePan: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    final transformBefore = renderBox.transform;
    final drag = await tester.createGesture(
      pointer: 160,
      kind: PointerDeviceKind.touch,
    );
    await drag.down(tester.getCenter(find.byType(BravenChartPlus)));
    await tester.pump();
    await drag.moveBy(const Offset(0, -45));
    await tester.pump();
    await drag.moveBy(const Offset(0, -100));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(renderBox.transform!.dataXMin, transformBefore!.dataXMin);
    expect(renderBox.transform!.dataXMax, transformBefore.dataXMax);
    expect(scrollController.offset, greaterThan(0));
  });

  testWidgets(
    'viewport gestures suppress tap selection and tracking callbacks',
    (tester) async {
      final scrollController = ScrollController();
      final chartController = BravenChartController();
      var dataPointTaps = 0;
      final crosshairUpdates = <double?>[];
      addTearDown(scrollController.dispose);
      addTearDown(chartController.dispose);
      await tester.pumpWidget(
        _TouchReleaseHarness(
          scrollController: scrollController,
          chartController: chartController,
          series: _lineSeries(),
          onDataPointTap: (point, position) => dataPointTaps++,
          onCrosshairChanged: (position, points) {
            crosshairUpdates.add(
              position == null || points.isEmpty ? null : points.first.x,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await _pinch(
        tester,
        focalPoint: tester.getCenter(find.byType(BravenChartPlus)),
        startRadius: 30,
        endRadius: 90,
        pointerBase: 170,
      );

      expect(dataPointTaps, 0);
      expect(crosshairUpdates, isNotEmpty);
      expect(crosshairUpdates.last, isNull);
      expect(chartController.selectedPointRefs, isEmpty);
      expect(_renderBox(tester).coordinator.currentMode, InteractionMode.idle);
    },
  );

  testWidgets('context-menu long press retains priority over tracking scrub', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final trackingUpdates = <double?>[];
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      _TouchReleaseHarness(
        scrollController: scrollController,
        series: _lineSeries(),
        gesture: const GestureConfig(
          longPressTimeout: Duration(milliseconds: 80),
        ),
        contextMenuConfig: const ChartContextMenuConfig(
          enableLongPress: true,
          longPressDuration: Duration(milliseconds: 80),
        ),
        onCrosshairChanged: (position, points) {
          trackingUpdates.add(
            position == null || points.isEmpty ? null : points.first.x,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final hold = await tester.createGesture(
      pointer: 180,
      kind: PointerDeviceKind.touch,
    );
    await hold.down(tester.getCenter(find.byType(BravenChartPlus)));
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      _renderBox(tester).coordinator.currentMode,
      isNot(InteractionMode.trackingScrub),
    );
    expect(
      trackingUpdates.whereType<double>(),
      hasLength(1),
      reason: 'raw touch-down may inspect once, but scrub must not activate',
    );

    await hold.up();
    await tester.pumpAndSettle();
  });

  testWidgets('tablet relayout preserves touch and mouse viewport input', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 820);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final scrollController = ScrollController();
    final chartController = BravenChartController();
    addTearDown(scrollController.dispose);
    addTearDown(chartController.dispose);
    await tester.pumpWidget(
      _TouchReleaseHarness(
        scrollController: scrollController,
        chartController: chartController,
        series: _lineSeries(),
        touch: const TouchInteractionConfig(
          profile: TouchInteractionProfile.explore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    var renderBox = _renderBox(tester);
    expect(chartController.zoomViewport(2), isTrue);
    await tester.pumpAndSettle();
    final minBeforeMouse = renderBox.transform!.dataXMin;
    final mouse = await tester.createGesture(
      pointer: 190,
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await mouse.down(tester.getCenter(find.byType(BravenChartPlus)));
    await tester.pump();
    await mouse.moveBy(const Offset(-80, 0));
    await tester.pump();
    await mouse.up();
    await tester.pump();
    expect(renderBox.transform!.dataXMin, isNot(minBeforeMouse));

    tester.view.physicalSize = const Size(760, 1080);
    await tester.pumpAndSettle();
    renderBox = _renderBox(tester);
    final spanBeforeTouch = _xSpan(renderBox);
    await _pinch(
      tester,
      focalPoint: tester.getCenter(find.byType(BravenChartPlus)),
      startRadius: 26,
      endRadius: 74,
      pointerBase: 200,
    );
    expect(_xSpan(renderBox), lessThan(spanBeforeTouch));
  });
}

const _cartesianPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 3),
  ChartDataPoint(x: 1, y: 7),
  ChartDataPoint(x: 2, y: 5),
  ChartDataPoint(x: 3, y: 9),
  ChartDataPoint(x: 4, y: 6),
  ChartDataPoint(x: 5, y: 11),
];

final _rangePoints = <RangeAreaDataPoint>[
  RangeAreaDataPoint(x: 0, low: 1, high: 5),
  RangeAreaDataPoint(x: 1, low: 4, high: 9),
  RangeAreaDataPoint(x: 2, low: 2, high: 8),
  RangeAreaDataPoint(x: 3, low: 6, high: 12),
  RangeAreaDataPoint(x: 4, low: 3, high: 10),
  RangeAreaDataPoint(x: 5, low: 8, high: 14),
];

final _candlestickPoints = <CandlestickDataPoint>[
  CandlestickDataPoint(x: 0, open: 4, high: 7, low: 2, close: 5),
  CandlestickDataPoint(x: 1, open: 5, high: 9, low: 4, close: 8),
  CandlestickDataPoint(x: 2, open: 8, high: 10, low: 5, close: 6),
  CandlestickDataPoint(x: 3, open: 6, high: 11, low: 5, close: 10),
  CandlestickDataPoint(x: 4, open: 10, high: 12, low: 7, close: 8),
  CandlestickDataPoint(x: 5, open: 8, high: 14, low: 7, close: 13),
];

List<ChartSeries> _lineSeries() => [
  LineChartSeries(
    id: 'line',
    showDataPointMarkers: true,
    points: _cartesianPoints,
  ),
];

class _TouchReleaseHarness extends StatelessWidget {
  const _TouchReleaseHarness({
    super.key,
    required this.scrollController,
    required this.series,
    this.chartController,
    this.touch = const TouchInteractionConfig(),
    this.gesture = const GestureConfig(),
    this.contextMenuConfig = const ChartContextMenuConfig(),
    this.enableZoom = true,
    this.enablePan = true,
    this.onDataPointTap,
    this.onCrosshairChanged,
  });

  final ScrollController scrollController;
  final List<ChartSeries> series;
  final BravenChartController? chartController;
  final TouchInteractionConfig touch;
  final GestureConfig gesture;
  final ChartContextMenuConfig contextMenuConfig;
  final bool enableZoom;
  final bool enablePan;
  final DataPointCallback? onDataPointTap;
  final CrosshairChangeCallback? onCrosshairChanged;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: scrollController,
          children: [
            const SizedBox(height: 180),
            SizedBox(
              height: 360,
              child: BravenChartPlus(
                bravenChartController: chartController,
                showLegend: false,
                contextMenuConfig: contextMenuConfig,
                interactionConfig: InteractionConfig(
                  touch: touch,
                  gesture: gesture,
                  enableZoom: enableZoom,
                  enablePan: enablePan,
                  tooltip: const TooltipConfig(
                    triggerMode: TooltipTriggerMode.tap,
                  ),
                  onDataPointTap: onDataPointTap,
                  onCrosshairChanged: onCrosshairChanged,
                ),
                series: series,
              ),
            ),
            const SizedBox(height: 900),
          ],
        ),
      ),
    );
  }
}

ChartRenderBox _renderBox(WidgetTester tester) =>
    tester.renderObject<ChartRenderBox>(_chartRenderFinder());

double _xSpan(ChartRenderBox renderBox) =>
    renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;

(double, double, double, double) _viewportBounds(ChartRenderBox renderBox) {
  final transform = renderBox.transform!;
  return (
    transform.dataXMin,
    transform.dataXMax,
    transform.dataYMin,
    transform.dataYMax,
  );
}

Offset _resolvableWidgetPosition(
  ChartRenderBox renderBox,
  ChartDataHit expected,
) {
  final anchor = renderBox.plotToWidget(expected.plotPosition);
  const offsets = <Offset>[
    Offset.zero,
    Offset(-4, 0),
    Offset(4, 0),
    Offset(-8, 0),
    Offset(8, 0),
    Offset(0, -4),
    Offset(0, 4),
    Offset(0, -8),
    Offset(0, 8),
  ];
  for (final offset in offsets) {
    final candidate = anchor + offset;
    final resolved = renderBox.dataHitAtWidgetPosition(candidate);
    if (resolved?.seriesId == expected.seriesId &&
        resolved?.pointIndex == expected.pointIndex) {
      return candidate;
    }
  }
  fail(
    'the family test tap must resolve ${expected.seriesId}[${expected.pointIndex}]',
  );
}

Future<void> _pinch(
  WidgetTester tester, {
  required Offset focalPoint,
  required double startRadius,
  required double endRadius,
  required int pointerBase,
}) async {
  final first = await tester.createGesture(
    pointer: pointerBase,
    kind: PointerDeviceKind.touch,
  );
  final second = await tester.createGesture(
    pointer: pointerBase + 1,
    kind: PointerDeviceKind.touch,
  );
  await first.down(focalPoint - Offset(startRadius, 0));
  await second.down(focalPoint + Offset(startRadius, 0));
  await tester.pump();
  await first.moveTo(focalPoint - Offset(endRadius, 0));
  await second.moveTo(focalPoint + Offset(endRadius, 0));
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pump();
}

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
