import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heatmap data bounds include explicit cell rectangles', () {
    final bounds = DataConverter.computeDataBounds([
      HeatmapChartSeries(
        id: 'irregular',
        points: [
          HeatmapDataPoint(
            x: 5,
            y: 12,
            value: 1,
            bounds: HeatmapCellBounds(
              xMinimum: -4,
              xMaximum: 10,
              yMinimum: 2,
              yMaximum: 20,
            ),
          ),
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.white, Colors.blue],
        ),
      ),
    ]);

    expect(bounds.xMin, lessThanOrEqualTo(-4));
    expect(bounds.xMax, greaterThanOrEqualTo(10));
    expect(bounds.yMin, lessThanOrEqualTo(2));
    expect(bounds.yMax, greaterThanOrEqualTo(20));
  });
}
