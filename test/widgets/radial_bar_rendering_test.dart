import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radial_bar_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/widgets/pie_chart_legend.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
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
                showLegend: false,
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
                  tooltip: TooltipConfig(
                    triggerMode: TooltipTriggerMode.both,
                    style: TooltipStyle(
                      backgroundColor: Color(0xFF172554),
                      borderColor: Color(0xFF38BDF8),
                      borderWidth: 1.5,
                      borderRadius: 9,
                      shadowColor: Color(0x660F172A),
                      shadowBlurRadius: 10,
                      padding: 12,
                      textColor: Color(0xFFEFF6FF),
                      fontSize: 13,
                    ),
                  ),
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
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump();

    expect(selection, hasLength(1));
    expect(selection.single.label, 'Discovery');
    expect(renderBox.debugSelectedTooltipMarker?.markerIndex, 0);
    expect(renderBox.debugTooltipOpacity, greaterThan(0.99));
    expect(renderBox.debugTooltipRect, isNotNull);
    expect(renderBox.debugTooltipRect!.isEmpty, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hover tooltip resolves across the complete Radial Bar arc', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                showLegend: false,
                series: [
                  RadialBarChartSeries.fromMap(
                    id: 'progress',
                    unit: '%',
                    values: const {'Discovery': 92, 'Build': 54, 'Launch': 31},
                  ),
                ],
                radialBarChartConfig: const RadialBarChartConfig(
                  showScaleLabels: false,
                ),
                interactionConfig: const InteractionConfig(
                  tooltip: TooltipConfig(
                    triggerMode: TooltipTriggerMode.hover,
                    showDelay: Duration.zero,
                  ),
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
    final mark = element.geometry.marks.first;
    final localTarget = renderBox.plotToWidget(
      mark.mark.pointAt(angularFraction: 0.25),
    );
    expect(
      (mark.tooltipAnchor - mark.mark.pointAt(angularFraction: 0.25)).distance,
      greaterThan(20),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getTopLeft(chartFinder));
    await mouse.moveTo(tester.getTopLeft(chartFinder) + localTarget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(renderBox.debugTooltipOpacity, greaterThan(0.99));
    expect(renderBox.debugTooltipRect, isNotNull);
    expect(renderBox.debugTooltipRect!.isEmpty, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native Radial Bar legend selects its owning category track', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 520,
            child: BravenChartPlus(
              bravenChartController: controller,
              series: [
                RadialBarChartSeries.fromMap(
                  id: 'progress',
                  unit: '%',
                  values: const {'Discovery': 72, 'Build': 54, 'Launch': 31},
                ),
              ],
              showLegend: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadialBarLegend), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('radial-bar-legend-item-progress-1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('radial-bar-legend-item-progress-1')),
    );
    await tester.pumpAndSettle();

    expect(
      controller.selectedPointRefs,
      equals(<ChartPointRef>{
        const ChartPointRef(seriesId: 'progress', pointIndex: 1),
      }),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Radial Bar legend reflects the rendered gradient palette', (
    tester,
  ) async {
    final legendColors = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 520,
            child: BravenChartPlus(
              series: [
                RadialBarChartSeries.fromMap(
                  id: 'gradient-legend',
                  unit: '%',
                  values: const {'Discovery': 72, 'Build': 54},
                  radialBarStyle: const RadialBarStyle(
                    gradient: RadialBarGradientStyle(
                      startColor: Color(0xFF22D3EE),
                      endColor: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
              showLegend: true,
              radialLegendItemBuilder: (context, data) {
                legendColors.add(data.color);
                return Text(data.category);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expected = Color.lerp(
      const Color(0xFF22D3EE),
      const Color(0xFF4F46E5),
      0.5,
    );
    expect(legendColors, isNotEmpty);
    expect(legendColors.toSet(), equals(<Color>{expected!}));
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
      radialBarStyle: const RadialBarStyle(
        trackOpacity: 0.2,
        gradient: RadialBarGradientStyle(
          type: RadialBarGradientType.radial,
          startLightnessShift: 0.2,
          endLightnessShift: -0.18,
        ),
        dataLabels: RadialBarDataLabelConfig(
          position: RadialBarDataLabelPosition.outsideCallout,
          content: RadialBarDataLabelContent.categoryAndValue,
          colorMode: RadialBarDataLabelColorMode.fixed,
          textStyle: PolarLabelStyle(
            color: Color(0xFF112233),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          offset: 8,
          connectorLength: 18,
          connectorWidth: 1.5,
          connectorColor: Color(0xFF445566),
        ),
      ),
    );
    const config = RadialBarChartConfig(
      trackGap: 10,
      trackOrder: RadialBarTrackOrder.innerToOuter,
      categoryLabels: RadialBarCategoryLabelConfig(
        position: RadialBarCategoryLabelPosition.startGap,
        orientation: RadialBarCategoryLabelOrientation.horizontal,
        offset: 9,
        textStyle: PolarLabelStyle(
          color: Color(0xFF223344),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        showPanel: true,
        panelStyle: LabelStyle(
          textStyle: TextStyle(),
          backgroundColor: Color(0xFFF7F8FA),
          borderColor: Color(0xFF667788),
          borderWidth: 1.25,
          borderRadius: 5,
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        ),
        connectorLength: 16,
        connectorWidth: 1.25,
        connectorColor: Color(0xFF556677),
      ),
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
    expect(
      generated,
      contains('categoryLabels: RadialBarCategoryLabelConfig('),
    );
    expect(
      generated,
      contains('orientation: RadialBarCategoryLabelOrientation.horizontal'),
    );
    expect(generated, contains('showPanel: true'));
    expect(generated, contains('panelStyle: LabelStyle('));
    expect(generated, contains('dataLabels: RadialBarDataLabelConfig('));
    expect(generated, contains('gradient: RadialBarGradientStyle('));
    expect(generated, contains('type: RadialBarGradientType.radial'));
    expect(
      generated,
      contains('position: RadialBarDataLabelPosition.outsideCallout'),
    );
    expect(
      generated,
      contains('content: RadialBarDataLabelContent.categoryAndValue'),
    );
    expect(generated, contains('colorMode: RadialBarDataLabelColorMode.fixed'));
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

  testWidgets(
    'baseline-valued categories remain available to assistive traversal',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 360,
              child: BravenChartPlus(
                showLegend: false,
                series: [
                  RadialBarChartSeries.fromMap(
                    id: 'progress',
                    unit: '%',
                    values: const {
                      'No progress': 0,
                      'In progress': 54,
                      'Complete': 100,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
        ),
      );
      final element = renderBox.debugElements
          .whereType<RadialBarSeriesElement>()
          .single;
      final hits = element.semanticDataHits.toList();

      expect(hits, hasLength(3));
      expect(hits.first.category, 'No progress');
      expect(hits.first.semanticBounds.isEmpty, isFalse);
      expect(
        find.semantics.byLabel('Radial Bar chart with 3 categories'),
        findsOneWidget,
      );
      expect(find.semantics.byLabel(hits.first.semanticLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
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
