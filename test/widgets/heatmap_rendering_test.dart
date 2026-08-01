import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapChartSeries series(List<HeatmapDataPoint> points) =>
      HeatmapChartSeries(
        id: 'matrix',
        points: points,
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
        ),
      );

  testWidgets('categorical axes own the complete Heatmap cell domain', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 320,
            child: BravenChartPlus(
              series: [
                series([
                  HeatmapDataPoint(x: 0, y: 0, value: 1),
                  HeatmapDataPoint(x: 1, y: 2, value: 2),
                ]),
              ],
              xAxisConfig: const XAxisConfig(
                categoryAxis: CategoryAxisConfig(categories: ['A', 'B']),
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                categoryAxis: const CategoryAxisConfig(
                  categories: ['North', 'Central', 'South'],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    expect(renderBox.transform!.dataXMin, -0.5);
    expect(renderBox.transform!.dataXMax, 1.5);
    expect(renderBox.transform!.dataYMin, -0.5);
    expect(renderBox.transform!.dataYMax, 2.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple Heatmap series share geometry but keep colour axes', (
    tester,
  ) async {
    final latencyScale = HeatmapColorScale.sequential(
      colors: const [Colors.white, Colors.blue],
      minimumValue: 35,
      maximumValue: 100,
      label: 'Latency',
      unit: 'ms',
    );
    final errorScale = HeatmapColorScale.sequential(
      colors: const [Colors.white, Colors.orange],
      minimumValue: 0,
      maximumValue: 3,
      label: 'Error rate',
      unit: '%',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 320,
            child: BravenChartPlus(
              series: [
                HeatmapChartSeries(
                  id: 'latency-axis',
                  unit: 'ms',
                  points: [HeatmapDataPoint(x: 0, y: 0, value: 42)],
                  colorScale: latencyScale,
                ),
                HeatmapChartSeries(
                  id: 'error-rate-axis',
                  unit: '%',
                  points: [HeatmapDataPoint(x: 0, y: 1, value: 1.8)],
                  colorScale: errorScale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mounted = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    final mountedHeatmaps = mounted.series.cast<HeatmapChartSeries>();
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;

    expect(mountedHeatmaps, hasLength(2));
    expect(mountedHeatmaps[0].colorScale, latencyScale);
    expect(mountedHeatmaps[1].colorScale, errorScale);
    expect(renderBox.transform!.dataYMin, -0.5);
    expect(renderBox.transform!.dataYMax, 1.5);
    expect(renderBox.debugSeriesCachePicture, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid Heatmap category coordinates fail visibly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 320,
            child: BravenChartPlus(
              series: [
                series([HeatmapDataPoint(x: 0, y: 1.5, value: 1)]),
              ],
              xAxisConfig: const XAxisConfig(
                categoryAxis: CategoryAxisConfig(categories: ['A']),
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.left,
                categoryAxis: const CategoryAxisConfig(
                  categories: ['North', 'South'],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('presentation-only updates replace the mounted Heatmap series', (
    tester,
  ) async {
    final key = GlobalKey();
    final points = [HeatmapDataPoint(x: 0, y: 0, value: 0)];

    Widget chart({
      required bool reverse,
      required bool showLabels,
      required double gap,
      required double radius,
      required HeatmapEmptyValueStyle? emptyValueStyle,
    }) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 500,
          height: 320,
          child: BravenChartPlus(
            key: key,
            series: [
              HeatmapChartSeries(
                id: 'matrix',
                points: points,
                colorScale: HeatmapColorScale.sequential(
                  colors: const [Colors.white, Colors.blue],
                  reverse: reverse,
                ),
                showCellLabels: showLabels,
                gapFraction: gap,
                cornerRadius: radius,
                emptyValueStyle: emptyValueStyle,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      chart(
        reverse: false,
        showLabels: false,
        gap: 0,
        radius: 0,
        emptyValueStyle: null,
      ),
    );
    await tester.pumpAndSettle();
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final initialPicture = renderBox.debugSeriesCachePicture;
    expect(initialPicture, isNotNull);

    await tester.pumpWidget(
      chart(
        reverse: true,
        showLabels: true,
        gap: 0.2,
        radius: 8,
        emptyValueStyle: const HeatmapEmptyValueStyle(
          fillColor: Color(0xFFE5E7EB),
          borderColor: Color(0xFF94A3B8),
          borderWidth: 1.5,
          showLabel: false,
          legendLabel: 'No activity',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mounted = tester.widget<BravenChartPlus>(
      find.byType(BravenChartPlus),
    );
    final updated = mounted.series.single as HeatmapChartSeries;
    expect(updated.colorScale.reverse, isTrue);
    expect(updated.showCellLabels, isTrue);
    expect(updated.gapFraction, 0.2);
    expect(updated.cornerRadius, 8);
    expect(
      updated.emptyValueStyle,
      const HeatmapEmptyValueStyle(
        fillColor: Color(0xFFE5E7EB),
        borderColor: Color(0xFF94A3B8),
        borderWidth: 1.5,
        showLabel: false,
        legendLabel: 'No activity',
      ),
    );
    expect(renderBox.debugSeriesCachePicture, isNot(same(initialPicture)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Heatmap point selection retains the cached base picture', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final points = [
      HeatmapDataPoint(x: 0, y: 0, value: 1),
      HeatmapDataPoint(x: 1, y: 0, value: 2),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 320,
            child: BravenChartPlus(
              bravenChartController: controller,
              series: [series(points)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final picture = renderBox.debugSeriesCachePicture;
    expect(picture, isNotNull);

    controller.selectPoint(
      const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
      revision: controller.effectiveDocumentRevision.value!,
    );
    await tester.pumpAndSettle();

    expect(renderBox.debugSeriesCachePicture, same(picture));
    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
    });
  });

  testWidgets('Heatmap hover feedback retains the cached base picture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 320,
            child: BravenChartPlus(
              series: [
                series([
                  HeatmapDataPoint(x: 0, y: 0, value: 1),
                  HeatmapDataPoint(x: 1, y: 0, value: 2),
                ]),
              ],
              interactionConfig: const InteractionConfig(
                tooltip: TooltipConfig(enabled: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final picture = renderBox.debugSeriesCachePicture;
    expect(picture, isNotNull);

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(pointer.removePointer);
    await pointer.addPointer(location: Offset.zero);
    final plotPosition = renderBox.transform!.dataToPlot(1, 0);
    await pointer.moveTo(
      renderBox.localToGlobal(renderBox.plotToWidget(plotPosition)),
    );
    await tester.pump();

    expect(renderBox.coordinator.hoveredMarker?.seriesId, 'matrix');
    expect(renderBox.coordinator.hoveredMarker?.markerIndex, 1);
    expect(renderBox.debugSeriesCachePicture, same(picture));
  });
}
