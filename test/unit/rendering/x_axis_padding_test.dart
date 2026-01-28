// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Tests to verify X-axis padding is applied correctly in multi-axis mode.

import 'package:braven_charts/src/axis/axis.dart' as chart_axis;
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('X-Axis Padding', () {
    test('computeDataBounds adds 5% X padding to data bounds', () {
      // Create series with known X range: 0-60 (like typical time series)
      final series = [
        LineChartSeries(
          id: 'test',
          name: 'Test',
          points: List.generate(61, (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0)),
        ),
      ];

      final bounds = DataConverter.computeDataBounds(series);

      // Data range is 0-60
      // 5% padding = 3 on each side
      // Expected: xMin = -3, xMax = 63
      expect(bounds.xMin, closeTo(-3.0, 0.1), reason: 'xMin should be -3 (5% below 0)');
      expect(bounds.xMax, closeTo(63.0, 0.1), reason: 'xMax should be 63 (5% above 60)');
    });

    test('computeDataBounds adds 5% Y padding to data bounds', () {
      // Create series with known Y range: 0-120
      final series = [
        LineChartSeries(
          id: 'test',
          name: 'Test',
          points: List.generate(61, (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0)),
        ),
      ];

      final bounds = DataConverter.computeDataBounds(series);

      // Data Y range is 0-120
      // 5% padding = 6 on each side
      expect(bounds.yMin, closeTo(-6.0, 0.1), reason: 'yMin should be -6 (5% below 0)');
      expect(bounds.yMax, closeTo(126.0, 0.1), reason: 'yMax should be 126 (5% above 120)');
    });

    test('Multi-series bounds include 5% X padding', () {
      // Create multiple series like in athletic chart (power, HR, cadence)
      final series = [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: List.generate(200, (i) => ChartDataPoint(x: i.toDouble(), y: 150 + (i % 50).toDouble())),
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: List.generate(200, (i) => ChartDataPoint(x: i.toDouble(), y: 140 + (i % 30).toDouble())),
        ),
        LineChartSeries(
          id: 'cadence',
          name: 'Cadence',
          points: List.generate(200, (i) => ChartDataPoint(x: i.toDouble(), y: 85 + (i % 10).toDouble())),
        ),
      ];

      final bounds = DataConverter.computeDataBounds(series);

      // Data X range is 0-199
      // 5% padding = 9.95 on each side
      final xRange = 199.0 - 0.0;
      final expectedXPadding = xRange * 0.05;

      expect(bounds.xMin, lessThan(0), reason: 'xMin should be negative (padded below 0)');
      expect(bounds.xMax, greaterThan(199), reason: 'xMax should be greater than 199 (padded above)');
      expect(bounds.xMin, closeTo(-expectedXPadding, 0.5));
      expect(bounds.xMax, closeTo(199 + expectedXPadding, 0.5));
    });

    test('Multi-axis mode with perSeries normalization preserves X padding', () {
      // Simulate what happens in BravenChartPlus._buildChartState
      // for multi-axis charts with perSeries normalization

      // Create series like athletic chart with inline yAxisConfig
      final series = [
        LineChartSeries(
          id: 'power',
          name: 'Power',
          points: List.generate(60, (i) => ChartDataPoint(x: i.toDouble(), y: 150 + (i % 50).toDouble())),
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
          ),
        ),
        LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: List.generate(60, (i) => ChartDataPoint(x: i.toDouble(), y: 140 + (i % 30).toDouble())),
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.right,
            label: 'HR',
          ),
        ),
      ];

      // Step 1: Compute data bounds (as in _buildChartState)
      var dataBounds = DataConverter.computeDataBounds(series);

      // Verify initial X bounds have 5% padding
      // Data X range: 0-59, 5% = 2.95
      expect(dataBounds.xMin, lessThan(0), reason: 'Initial xMin should have negative padding');
      expect(dataBounds.xMax, greaterThan(59), reason: 'Initial xMax should exceed data max');

      // Step 2: Apply perSeries normalization modification (as in _buildChartState)
      // Check if multi-axis config is active
      final hasMultiAxisConfig = series.any((s) => s.yAxisConfig != null || (s.yAxisId != null && s.yAxisId!.isNotEmpty));
      expect(hasMultiAxisConfig, isTrue, reason: 'Series should have multi-axis config');

      // Simulate the dataBounds override for perSeries mode
      const normalizationMode = NormalizationMode.perSeries;
      if (normalizationMode == NormalizationMode.perSeries && hasMultiAxisConfig) {
        dataBounds = DataBounds(
          xMin: dataBounds.xMin, // Should preserve X padding!
          xMax: dataBounds.xMax, // Should preserve X padding!
          yMin: -0.05, // 5% buffer below normalized range
          yMax: 1.05, // 5% buffer above normalized range
        );
      }

      // X bounds should STILL have padding after the modification
      expect(dataBounds.xMin, lessThan(0), reason: 'xMin should preserve negative padding');
      expect(dataBounds.xMax, greaterThan(59), reason: 'xMax should preserve padding above data max');

      // Step 3: Create axis and transform (as in _buildChartState)
      const xAxisConfig = XAxisConfig();
      final xAxis = chart_axis.Axis.fromXAxisConfig(
        config: xAxisConfig,
        dataMin: xAxisConfig.min ?? dataBounds.xMin,
        dataMax: xAxisConfig.max ?? dataBounds.xMax,
      );

      expect(xAxis.dataMin, lessThan(0), reason: 'X-axis dataMin should have padding');
      expect(xAxis.dataMax, greaterThan(59), reason: 'X-axis dataMax should have padding');

      // Step 4: Create transform (as in chart_render_box)
      final transform = ChartTransform(
        dataXMin: xAxis.dataMin,
        dataXMax: xAxis.dataMax,
        dataYMin: dataBounds.yMin,
        dataYMax: dataBounds.yMax,
        plotWidth: 800,
        plotHeight: 400,
        invertY: true,
      );

      expect(transform.dataXMin, lessThan(0), reason: 'Transform dataXMin should have padding');
      expect(transform.dataXMax, greaterThan(59), reason: 'Transform dataXMax should have padding');

      // Step 5: Verify data points don't render at the edges
      // First data point at x=0 should map to a position INSIDE the plot area
      final firstPointPos = transform.dataToPlot(0, 0.5);
      final lastPointPos = transform.dataToPlot(59, 0.5);

      expect(firstPointPos.dx, greaterThan(0), reason: 'x=0 should NOT be at left edge');
      expect(lastPointPos.dx, lessThan(transform.plotWidth), reason: 'x=59 should NOT be at right edge');

      // Calculate expected padding in pixels
      final xRange = transform.dataXMax - transform.dataXMin;
      final paddingRatio = (-transform.dataXMin) / xRange; // How much of range is left padding
      final expectedLeftPadding = paddingRatio * transform.plotWidth;

      expect(firstPointPos.dx, closeTo(expectedLeftPadding, 1.0), reason: 'First point should be at ~5% from left edge');
    });
  });
}
