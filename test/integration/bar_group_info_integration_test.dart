// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/utils/data_converter.dart';

void main() {
  group('BarGroupInfo integration', () {
    test('BarGroupInfo is exported from public API', () {
      // This test verifies that BarGroupInfo can be imported from the main package
      const info = BarGroupInfo(index: 0, count: 3);
      expect(info, isA<BarGroupInfo>());
    });

    test('SeriesElement accepts barGroupInfo parameter', () {
      // Create test data
      const series = BarChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 1, y: 10),
          ChartDataPoint(x: 2, y: 20),
        ],
        barWidthPercent: 0.8,
      );

      const transform = ChartTransform(
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
      const series = LineChartSeries(
        id: 'test',
        points: [
          ChartDataPoint(x: 1, y: 10),
          ChartDataPoint(x: 2, y: 20),
        ],
      );

      const transform = ChartTransform(
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

    test('DataConverter assigns BarGroupInfo for multiple bar series', () {
      // Create two bar series (like in fit_distribution_page)
      const barSeries1 = BarChartSeries(
        id: 'time_distribution',
        name: 'Time in band',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 200),
          ChartDataPoint(x: 2, y: 150),
        ],
        barWidthPercent: 0.7,
      );

      const barSeries2 = BarChartSeries(
        id: 'work_distribution',
        name: 'Work in band',
        points: [
          ChartDataPoint(x: 0, y: 50),
          ChartDataPoint(x: 1, y: 80),
          ChartDataPoint(x: 2, y: 60),
        ],
        barWidthPercent: 0.7,
      );

      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 3,
        dataYMin: 0,
        dataYMax: 200,
        plotWidth: 400,
        plotHeight: 300,
      );

      // Convert using DataConverter (this is what BravenChartPlus does)
      final elements = DataConverter.seriesToElements(
        series: [barSeries1, barSeries2],
        transform: transform,
      );

      // Verify both elements have BarGroupInfo
      expect(elements.length, equals(2));
      expect(elements[0].barGroupInfo, isNotNull);
      expect(elements[1].barGroupInfo, isNotNull);

      // Verify correct index and count
      expect(elements[0].barGroupInfo!.index, equals(0));
      expect(elements[0].barGroupInfo!.count, equals(2));
      expect(elements[1].barGroupInfo!.index, equals(1));
      expect(elements[1].barGroupInfo!.count, equals(2));

      // Verify offsets are different (bars should be side-by-side)
      const testBarWidth = 30.0;
      final offset0 = elements[0].barGroupInfo!.calculateOffset(testBarWidth);
      final offset1 = elements[1].barGroupInfo!.calculateOffset(testBarWidth);

      expect(offset0, isNot(equals(offset1)));
      // With gap=2, effectiveWidth=32, totalWidth=62
      // offset0 = -31 + 15 + 0*32 = -16
      // offset1 = -31 + 15 + 1*32 = 16
      expect(offset0, closeTo(-16.0, 0.1));
      expect(offset1, closeTo(16.0, 0.1));
    });
  });
}
