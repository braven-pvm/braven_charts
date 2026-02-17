// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Tests to verify Y-axis padding is applied correctly in perSeries mode.

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerSeries Y-Axis Padding', () {
    test('5% padding ensures data does not touch plot edges', () {
      final manager = MultiAxisManager();

      // Create series with known Y range
      final series = [
        ChartSeries(
          id: 'power',
          name: 'Power',
          points: [
            const ChartDataPoint(x: 0, y: 0), // Min
            const ChartDataPoint(x: 50, y: 100), // Mid
            const ChartDataPoint(x: 100, y: 200), // Max
          ],
          yAxisConfig: YAxisConfig.withId(
            id: 'power_axis',
            position: YAxisPosition.left,
          ),
        ),
      ];

      manager.setSeries(series);
      manager.setNormalizationMode(NormalizationMode.perSeries);

      // Get axis bounds (should include 5% padding)
      final axisBounds = manager.computeAxisBounds(
        transform: null,
        originalTransform: null,
        forPainting: true,
      );

      expect(axisBounds, contains('power_axis'));
      final powerBounds = axisBounds['power_axis']!;

      // Data range is 0-200, 5% padding = 10 on each side
      expect(
        powerBounds.min,
        closeTo(-10.0, 0.1),
        reason: 'Min should be -10 (5% below 0)',
      );
      expect(
        powerBounds.max,
        closeTo(210.0, 0.1),
        reason: 'Max should be 210 (5% above 200)',
      );

      // Create transform with these padded bounds
      const plotHeight = 400.0;
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: powerBounds.min,
        dataYMax: powerBounds.max,
        plotWidth: 600,
        plotHeight: plotHeight,
        invertY: true,
      );

      // Test Y=0 (data minimum) position
      final minPos = transform.dataToPlot(0, 0);
      expect(
        minPos.dy,
        greaterThan(plotHeight * 0.9),
        reason: 'Y=0 should be near bottom, but not AT bottom',
      );
      expect(
        minPos.dy,
        lessThan(plotHeight),
        reason: 'Y=0 should not be below plot area',
      );

      // Test Y=200 (data maximum) position
      final maxPos = transform.dataToPlot(0, 200);
      expect(
        maxPos.dy,
        greaterThan(0),
        reason: 'Y=200 should not be above plot area',
      );
      expect(
        maxPos.dy,
        lessThan(plotHeight * 0.1),
        reason: 'Y=200 should be near top, but not AT top',
      );

      // Calculate exact expected positions
      // Y=0 → relativeY = (0 - (-10)) / 220 = 10/220 ≈ 0.0455
      // With invertY: plotY = (1 - 0.0455) * 400 ≈ 381.8
      final expectedMinY = (1 - (10.0 / 220.0)) * plotHeight;
      expect(
        minPos.dy,
        closeTo(expectedMinY, 1.0),
        reason: 'Y=0 should map to $expectedMinY (4.5% from bottom)',
      );

      // Y=200 → relativeY = (200 - (-10)) / 220 = 210/220 ≈ 0.9545
      // With invertY: plotY = (1 - 0.9545) * 400 ≈ 18.2
      final expectedMaxY = (1 - (210.0 / 220.0)) * plotHeight;
      expect(
        maxPos.dy,
        closeTo(expectedMaxY, 1.0),
        reason: 'Y=200 should map to $expectedMaxY (4.5% from top)',
      );

      // Verify padding percentage
      final paddingPercent = 10.0 / 220.0 * 100;
      expect(
        paddingPercent,
        closeTo(4.55, 0.1),
        reason: 'Padding should be ~4.5% of plot height',
      );

      // Log for clarity
      // ignore: avoid_print
      print('Data range: 0-200');
      // ignore: avoid_print
      print('Padded bounds: ${powerBounds.min} to ${powerBounds.max}');
      // ignore: avoid_print
      print('Y=0 plot position: ${minPos.dy} (expected: $expectedMinY)');
      // ignore: avoid_print
      print('Y=200 plot position: ${maxPos.dy} (expected: $expectedMaxY)');
      // ignore: avoid_print
      print(
        'Padding from edges: ${plotHeight - minPos.dy}px at bottom, ${maxPos.dy}px at top',
      );
    });

    test('Contrast: non-normalized mode also has 5% padding', () {
      // In non-normalized mode, DataConverter.computeDataBounds adds 5% padding
      // This test confirms that both modes should have equivalent padding

      const dataMin = 0.0;
      const dataMax = 200.0;
      const plotHeight = 400.0;

      // Simulate DataConverter.computeDataBounds padding
      const range = dataMax - dataMin;
      const padding = range * 0.05;
      const paddedMin = dataMin - padding;
      const paddedMax = dataMax + padding;

      const transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: paddedMin,
        dataYMax: paddedMax,
        plotWidth: 600,
        plotHeight: plotHeight,
        invertY: true,
      );

      final minPos = transform.dataToPlot(0, dataMin);
      final maxPos = transform.dataToPlot(0, dataMax);

      // Should have ~4.5% padding on each side
      expect(minPos.dy, closeTo((1 - (10.0 / 220.0)) * plotHeight, 1.0));
      expect(maxPos.dy, closeTo((1 - (210.0 / 220.0)) * plotHeight, 1.0));

      // Log for comparison
      // ignore: avoid_print
      print('Non-normalized mode:');
      // ignore: avoid_print
      print('Padded bounds: $paddedMin to $paddedMax');
      // ignore: avoid_print
      print('Y=$dataMin plot position: ${minPos.dy}');
      // ignore: avoid_print
      print('Y=$dataMax plot position: ${maxPos.dy}');
    });
  });
}
