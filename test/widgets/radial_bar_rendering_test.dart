import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radial_bar_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and selects Radial Bar through BravenChartPlus', (
    tester,
  ) async {
    List<ChartDataPoint> selection = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                series: [
                  RadialBarChartSeries.fromMap(
                    id: 'progress',
                    unit: '%',
                    values: const {'Discovery': 72, 'Build': 54, 'Launch': 31},
                  ),
                ],
                radialBarChartConfig: const RadialBarChartConfig(
                  showScaleLabels: false,
                ),
                interactionConfig: InteractionConfig(
                  onSelectionChanged: (points) => selection = points,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartFinder = find.byType(BravenChartPlus);
    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<RadialBarSeriesElement>()
        .single;
    expect(element.geometry.marks, hasLength(3));

    final localTarget = renderBox.plotToWidget(
      element.geometry.marks.first.tooltipAnchor,
    );
    await tester.tapAt(tester.getTopLeft(chartFinder) + localTarget);
    await tester.pump();

    expect(selection, hasLength(1));
    expect(selection.single.label, 'Discovery');
    expect(tester.takeException(), isNull);
  });

  testWidgets('extracts, hydrates, and emits a complete Radial Bar chart', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final series = RadialBarChartSeries.fromMap(
      id: 'progress',
      name: 'Progress',
      unit: '%',
      values: const {'Discovery': 72, 'Build': 54},
      radialBarStyle: const RadialBarStyle(trackOpacity: 0.2),
    );
    const config = RadialBarChartConfig(
      trackGap: 10,
      trackOrder: RadialBarTrackOrder.innerToOuter,
      thresholds: [RadialBarThreshold(value: 60, label: 'Target')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 420,
          child: BravenChartPlus(
            bravenChartController: controller,
            series: [series],
            radialBarChartConfig: config,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snapshot = _success(controller.extractDocument()).value;
    expect(
      snapshot.document.requiredCapabilities,
      containsAll(<String>[
        'series.radial.bar.v1',
        'chart.radial.bar.config.v1',
      ]),
    );
    final hydrated = _success(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    ).value;
    expect(hydrated.series.single, series);
    expect(hydrated.radialBarChartConfig, config);

    final generated = _success(
      ChartDartSourceGenerator.generate(snapshot),
    ).value.source;
    expect(generated, contains('RadialBarChartSeries('));
    expect(generated, contains('radialBarChartConfig: RadialBarChartConfig('));
    expect(generated, contains('trackOrder: RadialBarTrackOrder.innerToOuter'));
    expect(generated, contains('RadialBarThreshold('));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard traversal selects one stable Radial Bar category', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              key: const ValueKey('radial-bar-keyboard'),
              bravenChartController: controller,
              series: [
                RadialBarChartSeries.fromMap(
                  id: 'progress',
                  values: const {'Discovery': 72, 'Build': 54, 'Launch': 31},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chart = find.byKey(const ValueKey('radial-bar-keyboard'));
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getTopLeft(chart));
    await mouse.moveTo(tester.getCenter(chart));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(controller.selectedPointRefs, hasLength(1));
    expect(controller.selectedPointRefs.single.seriesId, 'progress');
    expect(
      controller.selectedPointRefs.single.pointIndex,
      inInclusiveRange(0, 2),
    );
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });

  testWidgets('reduced motion resolves Radial Bar at final geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox.square(
            dimension: 320,
            child: BravenChartPlus(
              series: [
                RadialBarChartSeries.fromMap(
                  id: 'reduced-motion',
                  values: const {'Discovery': 72, 'Build': 54},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<RadialBarSeriesElement>()
        .single;
    expect(element.revealProgress, 1);
    expect(element.geometry.marks.map((mark) => mark.value), [72, 54]);
    expect(element.semanticDataHits, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  if (result case ChartArtifactFailure<T> failure) {
    fail(
      '${failure.error.code}: ${failure.error.message} '
      'at ${failure.error.path}',
    );
  }
  return result as ChartArtifactSuccess<T>;
}
