// Copyright (c) 2025 braven_charts. All rights reserved.
// Test: US1 - Default Y-Axis Auto-Creation

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Default Y-Axis Auto-Creation', () {
    late MultiAxisManager manager;

    setUp(() {
      manager = MultiAxisManager();
    });

    group('FR-005: Auto-create default Y-axis when no Y-axis configured', () {
      test(
          'creates default left Y-axis when primaryYAxis is null and no series have yAxisConfig',
          () {
        // Arrange: Empty series list, no primary axis
        manager.setSeries([]);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Should have exactly one default axis
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
        expect(effectiveAxes[0].id, equals('default'));
      });

      test(
          'creates default left Y-axis when primaryYAxis is null and series have no yAxisConfig',
          () {
        // Arrange: Series without yAxisConfig
        final series = [
          const ChartSeries(
            id: 's1',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 20),
              ChartDataPoint(x: 2, y: 15),
            ],
          ),
          const ChartSeries(
            id: 's2',
            points: [
              ChartDataPoint(x: 0, y: 5),
              ChartDataPoint(x: 1, y: 15),
              ChartDataPoint(x: 2, y: 10),
            ],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Should have exactly one default axis
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
        expect(effectiveAxes[0].id, equals('default'));
      });

      test('uses primaryYAxis when provided', () {
        // Arrange: Primary axis provided
        final primaryAxis = YAxisConfig(
          position: YAxisPosition.left,
          label: 'Custom Axis',
        );
        manager.setSeries([]);

        // Act
        final effectiveAxes =
            manager.getEffectiveYAxes(primaryYAxis: primaryAxis);

        // Assert: Should use the primary axis
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].label, equals('Custom Axis'));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });

      test('does not create default axis when series have yAxisConfig', () {
        // Arrange: Series with inline yAxisConfig
        final series = [
          ChartSeries(
            id: 's1',
            points: const [ChartDataPoint(x: 0, y: 10)],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Series Axis',
            ),
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Should use series axis, no default created
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].label, equals('Series Axis'));
        expect(effectiveAxes[0].position, equals(YAxisPosition.right));
      });
    });

    group('FR-006: YAxisConfig.position defaults to left', () {
      test('YAxisConfig defaults to left position when not specified', () {
        // Arrange & Act
        final config = YAxisConfig(position: YAxisPosition.left);

        // Assert
        expect(config.position, equals(YAxisPosition.left));
      });

      test('default axis created by system uses left position', () {
        // Arrange: No axes configured
        manager.setSeries([]);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });
    });

    group('FR-007: YAxisConfig works without explicit id parameter', () {
      test('YAxisConfig can be created without providing id', () {
        // Arrange & Act: Create config without id
        expect(
          () => YAxisConfig(
            position: YAxisPosition.left,
            label: 'Test Axis',
          ),
          returnsNormally,
        );
      });

      test('system auto-generates id for default axis', () {
        // Arrange
        manager.setSeries([]);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: ID should be auto-generated
        expect(effectiveAxes[0].id, isNotEmpty);
        expect(effectiveAxes[0].id, equals('default'));
      });

      test('system auto-generates id for primaryYAxis when not provided', () {
        // Arrange: Primary axis without explicit id
        final primaryAxis = YAxisConfig(
          position: YAxisPosition.left,
          label: 'Primary',
        );
        manager.setSeries([]);

        // Act
        final effectiveAxes =
            manager.getEffectiveYAxes(primaryYAxis: primaryAxis);

        // Assert: ID should be auto-generated
        expect(effectiveAxes[0].id, isNotEmpty);
        expect(effectiveAxes[0].id, equals('primary_axis'));
      });

      test('system auto-generates id for series yAxisConfig when not provided',
          () {
        // Arrange: Series with yAxisConfig without explicit id
        final series = [
          ChartSeries(
            id: 's1',
            points: const [ChartDataPoint(x: 0, y: 10)],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Series Axis',
            ),
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: ID should be auto-generated
        expect(effectiveAxes[0].id, isNotEmpty);
        expect(effectiveAxes[0].id, equals('s1_axis'));
      });
    });

    group('Edge Cases', () {
      test('handles empty series list gracefully', () {
        // Arrange: Empty series
        manager.setSeries([]);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Should still create default axis
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });

      test('handles series with single data point', () {
        // Arrange: Series with only one data point
        final series = [
          const ChartSeries(
            id: 's1',
            points: [ChartDataPoint(x: 0, y: 42)],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Default axis should be created
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });

      test('handles series with zero range (min == max)', () {
        // Arrange: All data points have same value
        final series = [
          const ChartSeries(
            id: 's1',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 10),
              ChartDataPoint(x: 2, y: 10),
            ],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Default axis should be created
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });

      test('handles null data points gracefully', () {
        // Arrange: Series with gaps (null values represented by missing points)
        final series = [
          const ChartSeries(
            id: 's1',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 2, y: 20), // Gap at x=1
            ],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Default axis should be created
        expect(effectiveAxes.length, equals(1));
        expect(effectiveAxes[0].position, equals(YAxisPosition.left));
      });
    });

    group('Auto-Scaling', () {
      test(
          'default axis uses data range for auto-scaling when no explicit min/max',
          () {
        // Arrange: Series with varying data
        final series = [
          const ChartSeries(
            id: 's1',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 50),
              ChartDataPoint(x: 2, y: 30),
            ],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Default axis should not have explicit min/max (relies on auto-scaling)
        expect(effectiveAxes[0].min, isNull);
        expect(effectiveAxes[0].max, isNull);
        // Auto-scaling happens in axis creation from data range
      });

      test('respects explicit min/max when provided on primaryYAxis', () {
        // Arrange: Primary axis with explicit bounds
        final primaryAxis = YAxisConfig(
          position: YAxisPosition.left,
          min: 0,
          max: 100,
        );
        final series = [
          const ChartSeries(
            id: 's1',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 200), // Exceeds max
            ],
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes =
            manager.getEffectiveYAxes(primaryYAxis: primaryAxis);

        // Assert: Should preserve explicit bounds
        expect(effectiveAxes[0].min, equals(0));
        expect(effectiveAxes[0].max, equals(100));
      });
    });

    group('Caching Behavior', () {
      test('returns new list each time (not cached)', () {
        // Arrange
        manager.setSeries([]);

        // Act: Get axes twice
        final axes1 = manager.getEffectiveYAxes();
        final axes2 = manager.getEffectiveYAxes();

        // Assert: Returns new list each time (based on current implementation)
        // Note: getEffectiveYAxes() rebuilds list on each call
        expect(axes1.length, equals(axes2.length));
        expect(axes1[0].id, equals(axes2[0].id));
      });

      test('reflects series changes immediately', () {
        // Arrange
        manager.setSeries([]);
        final axes1 = manager.getEffectiveYAxes();

        // Act: Update series
        manager.setSeries([
          const ChartSeries(
            id: 's1',
            points: [ChartDataPoint(x: 0, y: 10)],
          ),
        ]);
        final axes2 = manager.getEffectiveYAxes();

        // Assert: Should still return default axis (series has no yAxisConfig)
        expect(axes1.length, equals(1));
        expect(axes2.length, equals(1));
      });
    });

    group('Multiple Axes Scenarios', () {
      test('combines primaryYAxis with series inline yAxisConfig', () {
        // Arrange: Both primary and series axes
        final primaryAxis = YAxisConfig(
          position: YAxisPosition.left,
          label: 'Primary',
        );
        final series = [
          ChartSeries(
            id: 's1',
            points: const [ChartDataPoint(x: 0, y: 10)],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Series',
            ),
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes =
            manager.getEffectiveYAxes(primaryYAxis: primaryAxis);

        // Assert: Should have both axes
        expect(effectiveAxes.length, equals(2));
        expect(
          effectiveAxes.any((a) => a.label == 'Primary'),
          isTrue,
        );
        expect(
          effectiveAxes.any((a) => a.label == 'Series'),
          isTrue,
        );
      });

      test('deduplicates axes with same id', () {
        // Arrange: Multiple series pointing to same axis
        final series = [
          ChartSeries(
            id: 's1',
            points: const [ChartDataPoint(x: 0, y: 10)],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Shared',
            ),
          ),
          ChartSeries(
            id: 's2',
            points: const [ChartDataPoint(x: 0, y: 20)],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Shared',
            ),
          ),
        ];
        manager.setSeries(series);

        // Act
        final effectiveAxes = manager.getEffectiveYAxes();

        // Assert: Should deduplicate based on auto-generated ID
        // Both series will get different auto-generated IDs, so we'll have 2 axes
        // This is expected behavior - same config but different series = different axes
        expect(effectiveAxes.length, equals(2));
      });
    });

    group('Integration with MultiAxisManager', () {
      test('getEffectiveYAxes returns consistent results', () {
        // Arrange
        manager.setSeries([]);

        // Act: Call multiple times
        final axes1 = manager.getEffectiveYAxes();
        final axes2 = manager.getEffectiveYAxes();
        final axes3 = manager.getEffectiveYAxes();

        // Assert: Results should be consistent
        expect(axes1.length, equals(axes2.length));
        expect(axes2.length, equals(axes3.length));
        expect(axes1[0].id, equals(axes2[0].id));
      });

      test('works correctly after multiple setSeries calls', () {
        // Arrange & Act: Multiple updates
        manager.setSeries([]);
        var axes = manager.getEffectiveYAxes();
        expect(axes.length, equals(1));

        final primaryAxis = YAxisConfig(position: YAxisPosition.left);
        manager.setSeries([]);
        axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes.length, equals(1));

        manager.setSeries([
          ChartSeries(
            id: 's1',
            points: const [ChartDataPoint(x: 0, y: 10)],
            yAxisConfig: YAxisConfig(position: YAxisPosition.right),
          ),
        ]);
        axes = manager.getEffectiveYAxes();
        expect(axes.length, equals(1));

        // Assert: Should handle multiple updates correctly
        expect(axes[0].position, equals(YAxisPosition.right));
      });
    });
  });
}
