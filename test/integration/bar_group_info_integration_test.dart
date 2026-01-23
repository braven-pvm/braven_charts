// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';

void main() {
  group('BarGroupInfo integration', () {
    test('BarGroupInfo is exported from public API', () {
      // This test verifies that BarGroupInfo can be imported from the main package
      const info = BarGroupInfo(index: 0, count: 3);
      expect(info, isA<BarGroupInfo>());
    });

    test('SeriesElement accepts barGroupInfo parameter', () {
      // Create test data
      final series = BarChartSeries(
        id: 'test',
        points: [
          const ChartDataPoint(x: 1, y: 10),
          const ChartDataPoint(x: 2, y: 20),
        ],
        barWidthPercent: 0.8,
      );

      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
      );

      const barGroupInfo = BarGroupInfo(index: 1, count: 3, gap: 2.0);

      // Create SeriesElement with barGroupInfo
      final element = SeriesElement(
        series: series,
        transform: transform,
        barGroupInfo: barGroupInfo,
      );

      expect(element.barGroupInfo, equals(barGroupInfo));
      expect(element.barGroupInfo?.index, equals(1));
      expect(element.barGroupInfo?.count, equals(3));
      expect(element.barGroupInfo?.gap, equals(2.0));
    });

    test('SeriesElement barGroupInfo is optional (null by default)', () {
      final series = LineChartSeries(
        id: 'test',
        points: [
          const ChartDataPoint(x: 1, y: 10),
          const ChartDataPoint(x: 2, y: 20),
        ],
      );

      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
      );

      // Create SeriesElement without barGroupInfo
      final element = SeriesElement(
        series: series,
        transform: transform,
      );

      expect(element.barGroupInfo, isNull);
    });
  });
}
