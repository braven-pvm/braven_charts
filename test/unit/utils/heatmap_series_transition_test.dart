import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/heatmap_series_transition.dart';
import 'package:flutter/material.dart';
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

  test('interpolates measured values by stable cell identity', () {
    final from = series([
      HeatmapDataPoint(x: 0, y: 0, value: 10, pointKey: 'a'),
      HeatmapDataPoint(x: 1, y: 0, value: 20, pointKey: 'b'),
    ]);
    final to = series([
      HeatmapDataPoint(x: 0, y: 0, value: 30, pointKey: 'a'),
      HeatmapDataPoint(x: 1, y: 0, value: 60, pointKey: 'b'),
    ]);

    final halfway = HeatmapSeriesTransition.interpolate(
      from: from,
      to: to,
      progress: 0.5,
    );

    expect(halfway.cells.map((cell) => cell.value), [20, 40]);
  });

  test('retains target ordering while joining cells by identity', () {
    final from = series([
      HeatmapDataPoint(x: 0, y: 0, value: 10, pointKey: 'a'),
      HeatmapDataPoint(x: 1, y: 0, value: 20, pointKey: 'b'),
    ]);
    final to = series([
      HeatmapDataPoint(x: 1, y: 0, value: 40, pointKey: 'b'),
      HeatmapDataPoint(x: 0, y: 0, value: 30, pointKey: 'a'),
    ]);

    final halfway = HeatmapSeriesTransition.interpolate(
      from: from,
      to: to,
      progress: 0.5,
    );

    expect(halfway.cells.map((cell) => cell.pointKey), ['b', 'a']);
    expect(halfway.cells.map((cell) => cell.value), [30, 20]);
  });

  test('treats a coordinate move as removal plus addition', () {
    final from = series([
      HeatmapDataPoint(x: 0, y: 0, value: 10, pointKey: 'stable'),
    ]);
    final to = series([
      HeatmapDataPoint(x: 1, y: 0, value: 20, pointKey: 'stable'),
    ]);

    expect(HeatmapSeriesTransition.isCompatible(from, to), isFalse);
    expect(
      HeatmapSeriesTransition.interpolate(from: from, to: to, progress: 0.25),
      same(to),
    );
  });

  test('never fabricates numeric values for missing-cell transitions', () {
    final from = series([
      HeatmapDataPoint.missing(x: 0, y: 0, pointKey: 'stable'),
    ]);
    final to = series([
      HeatmapDataPoint(x: 0, y: 0, value: 20, pointKey: 'stable'),
    ]);

    expect(
      HeatmapSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: 0.25,
      ).cells.single.isMissing,
      isTrue,
    );
    expect(
      HeatmapSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: 0.75,
      ).cells.single.value,
      20,
    );
  });
}
