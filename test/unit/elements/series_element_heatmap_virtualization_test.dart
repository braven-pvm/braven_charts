import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapChartSeries denseSeries({double gapFraction = 0}) =>
      HeatmapChartSeries(
        id: 'dense',
        points: [
          for (var y = 0; y < 100; y++)
            for (var x = 0; x < 100; x++)
              HeatmapDataPoint(
                x: x.toDouble(),
                y: y.toDouble(),
                value: (x + y).toDouble(),
              ),
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
        ),
        gapFraction: gapFraction,
      );

  const initialTransform = ChartTransform(
    dataXMin: 10,
    dataXMax: 20,
    dataYMin: 30,
    dataYMax: 40,
    plotWidth: 200,
    plotHeight: 100,
  );

  test('SeriesElement materializes only Heatmap viewport cells', () {
    final element = SeriesElement(
      series: denseSeries(),
      transform: initialTransform,
    );

    expect(element.visibleHeatmapPointIndices, hasLength(169));
    expect(element.heatmapVisitedCellCount, 169);
    expect(element.heatmapVisitedRowCount, 13);
    expect(element.pointCount, 10000);
  });

  test('indexed Heatmap hit preserves source identity and visual gaps', () {
    final element = SeriesElement(
      series: denseSeries(gapFraction: 0.2),
      transform: initialTransform,
    );
    final center = initialTransform.dataToPlot(15, 35);

    final hit = element.dataHitAt(center);

    expect(hit, isNotNull);
    expect(hit!.pointIndex, 3515);
    expect(hit.point, isA<HeatmapDataPoint>());

    final cellEdge = initialTransform.dataToPlot(15.5, 35);
    expect(element.dataHitAt(cellEdge), isNull);
  });

  test('Heatmap viewport cache follows transform changes', () {
    final element = SeriesElement(
      series: denseSeries(),
      transform: initialTransform,
    );
    expect(element.visibleHeatmapPointIndices, contains(3515));

    const nextTransform = ChartTransform(
      dataXMin: 70,
      dataXMax: 80,
      dataYMin: 80,
      dataYMax: 90,
      plotWidth: 200,
      plotHeight: 100,
    );
    element.updateTransform(nextTransform);

    expect(element.visibleHeatmapPointIndices, isNot(contains(3515)));
    expect(element.visibleHeatmapPointIndices, contains(8575));
    expect(element.heatmapVisitedCellCount, 169);
  });

  test('Heatmap series updates rebuild the source index', () {
    final element = SeriesElement(
      series: denseSeries(),
      transform: initialTransform,
    );
    expect(element.dataHitAt(initialTransform.dataToPlot(15, 35)), isNotNull);

    element.updateSeries(
      HeatmapChartSeries(
        id: 'replacement',
        points: [HeatmapDataPoint(x: 15, y: 35, value: 900)],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.red],
        ),
      ),
    );

    expect(element.visibleHeatmapPointIndices, [0]);
    expect(
      element.dataHitAt(initialTransform.dataToPlot(15, 35))!.pointIndex,
      0,
    );
  });

  test('dense Heatmap semantics stay bounded and prioritize selection', () {
    const fullTransform = ChartTransform(
      dataXMin: -0.5,
      dataXMax: 99.5,
      dataYMin: -0.5,
      dataYMax: 99.5,
      plotWidth: 500,
      plotHeight: 500,
    );
    final element = SeriesElement(
      series: denseSeries(),
      transform: fullTransform,
      selectedPointIndices: const {9999},
    );

    final hits = element.semanticDataHits.toList();

    expect(hits, hasLength(200));
    expect(hits.first.pointIndex, 9999);
    expect(hits.map((hit) => hit.pointIndex), contains(9999));
  });
}
