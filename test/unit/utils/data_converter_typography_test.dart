// Copyright 2025 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui' show TextDirection;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('series elements inherit the chart typography font family', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 1,
      dataYMin: 0,
      dataYMax: 1,
      plotWidth: 100,
      plotHeight: 100,
    );
    final theme = ChartTheme.light.copyWith(
      typographyTheme: ChartTheme.light.typographyTheme.copyWith(
        fontFamily: 'CaptureFont',
      ),
    );

    final elements = DataConverter.seriesToElements(
      series: const [
        LineChartSeries(
          id: 'series',
          points: [ChartDataPoint(x: 0, y: 0), ChartDataPoint(x: 1, y: 1)],
        ),
      ],
      transform: transform,
      theme: theme,
    );

    expect(elements.single.fontFamily, 'CaptureFont');
    expect(elements.single.copyWith().fontFamily, 'CaptureFont');
  });

  test(
    'series elements preserve the ambient text direction through copies',
    () {
      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 1,
        dataYMin: 0,
        dataYMax: 1,
        plotWidth: 100,
        plotHeight: 100,
      );

      final elements = DataConverter.seriesToElements(
        series: const [
          BarChartSeries(
            id: 'series',
            points: [ChartDataPoint(x: 0, y: 1)],
            barWidthPercent: 0.8,
          ),
        ],
        transform: transform,
        textDirection: TextDirection.rtl,
      );

      expect(elements.single.textDirection, TextDirection.rtl);
      expect(elements.single.copyWith().textDirection, TextDirection.rtl);
    },
  );
}
