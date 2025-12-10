import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test colors
  const blueColor = Color(0xFF0000FF);
  const redColor = Color(0xFFFF0000);
  const greenColor = Color(0xFF00FF00);
  const defaultGray = Color(0xFF333333);

  // Axis with explicit color
  final axisWithColor = YAxisConfig.withId(id: 'power',
    position: YAxisPosition.left,
    color: blueColor,
  );

  // Axis without color (should resolve from series)
  final axisWithoutColor = YAxisConfig.withId(id: 'heartrate',
    position: YAxisPosition.right,
    color: null,
  );

  // Axis with no bound series
  final unboundAxis = YAxisConfig.withId(id: 'unbound',
    position: YAxisPosition.left,
    color: null,
  );

  // Shared axis (for multiple series)
  final sharedAxis = YAxisConfig.withId(id: 'percentage',
    position: YAxisPosition.left,
    color: null,
  );

  // Bindings
  const powerBinding = SeriesAxisBinding(
    seriesId: 'power-series',
    yAxisId: 'power',
  );

  const hrBinding = SeriesAxisBinding(
    seriesId: 'hr-series',
    yAxisId: 'heartrate',
  );

  // Shared axis bindings (two series → one axis)
  const sharedBinding1 = SeriesAxisBinding(
    seriesId: 'cpu-series',
    yAxisId: 'percentage',
  );

  const sharedBinding2 = SeriesAxisBinding(
    seriesId: 'memory-series',
    yAxisId: 'percentage',
  );

  // Series with colors
  const powerSeries = ChartSeries(
    id: 'power-series',
    points: [],
    color: blueColor,
  );

  const hrSeries = ChartSeries(
    id: 'hr-series',
    points: [],
    color: redColor,
  );

  const cpuSeries = ChartSeries(
    id: 'cpu-series',
    points: [],
    color: greenColor, // First series → this color should win
  );

  const memorySeries = ChartSeries(
    id: 'memory-series',
    points: [],
    color: redColor, // Second series → should be ignored
  );

  // Series without color
  const noColorSeries = ChartSeries(
    id: 'no-color-series',
    points: [],
    color: null,
  );

  // Binding for no-color series
  const noColorBinding = SeriesAxisBinding(
    seriesId: 'no-color-series',
    yAxisId: 'heartrate',
  );

  group('AxisColorResolver', () {
    group('T034: Axis color resolver', () {
      test('returns axis.color when explicitly set', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithColor,
          [powerBinding],
          [powerSeries],
        );

        expect(result, equals(blueColor));
      });

      test('returns first bound series color when axis.color is null', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [hrBinding],
          [hrSeries],
        );

        expect(result, equals(redColor));
      });

      test('returns default color when no series bound', () {
        final result = AxisColorResolver.resolveAxisColor(
          unboundAxis,
          [], // No bindings for this axis
          [powerSeries, hrSeries],
        );

        expect(result, equals(defaultGray));
      });

      test('returns default color when bound series has null color', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [noColorBinding],
          [noColorSeries],
        );

        expect(result, equals(defaultGray));
      });
    });

    group('T038: Shared axis', () {
      test('uses first bound series color for shared axis', () {
        final result = AxisColorResolver.resolveAxisColor(
          sharedAxis,
          [sharedBinding1, sharedBinding2],
          [cpuSeries, memorySeries],
        );

        // First binding is cpu-series which has green color
        expect(result, equals(greenColor));
      });

      test('ignores subsequent series colors for shared axis', () {
        final result = AxisColorResolver.resolveAxisColor(
          sharedAxis,
          [sharedBinding1, sharedBinding2],
          [cpuSeries, memorySeries],
        );

        // Should NOT return red (memory series color)
        expect(result, isNot(equals(redColor)));
        expect(result, equals(greenColor));
      });
    });

    group('Edge cases', () {
      test('handles empty bindings list', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [], // Empty bindings
          [hrSeries],
        );

        expect(result, equals(defaultGray));
      });

      test('handles empty series list', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [hrBinding],
          [], // Empty series
        );

        expect(result, equals(defaultGray));
      });

      test('handles custom default color parameter', () {
        const customDefault = Color(0xFF123456);

        final result = AxisColorResolver.resolveAxisColor(
          unboundAxis,
          [],
          [],
          defaultColor: customDefault,
        );

        expect(result, equals(customDefault));
      });

      test('handles binding with non-existent series', () {
        const orphanBinding = SeriesAxisBinding(
          seriesId: 'non-existent',
          yAxisId: 'heartrate',
        );

        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [orphanBinding],
          [powerSeries], // power-series, not non-existent
        );

        expect(result, equals(defaultGray));
      });

      test('finds series even when binding is not first in list', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [powerBinding, hrBinding], // hrBinding is second
          [powerSeries, hrSeries],
        );

        expect(result, equals(redColor));
      });

      test('finds series even when series is not first in list', () {
        final result = AxisColorResolver.resolveAxisColor(
          axisWithoutColor,
          [hrBinding],
          [powerSeries, hrSeries], // hrSeries is second
        );

        expect(result, equals(redColor));
      });
    });

    group('defaultAxisColor constant', () {
      test('defaultAxisColor equals expected gray value', () {
        expect(AxisColorResolver.defaultAxisColor, equals(defaultGray));
      });
    });
  });
}
