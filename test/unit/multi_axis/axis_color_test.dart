// Copyright 2025 Braven Charts - TDD Tests for Axis Color Resolution
// SPDX-License-Identifier: MIT
//
// T031 [US3] Unit tests for axis color resolution
// TDD: These tests are written FIRST and should FAIL until T034 is implemented.

// Import will exist after T034 implementation
// ignore: unused_import
import 'package:braven_charts/src_plus/axis/axis_color_resolver.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AxisColorResolver', () {
    // Helper to create test series
    LineChartSeries createSeries({
      required String id,
      required Color color,
      String? yAxisId,
    }) {
      return LineChartSeries(
        id: id,
        name: id,
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 1, y: 1),
        ],
        color: color,
        yAxisId: yAxisId,
      );
    }

    group('resolveAxisColor', () {
      test('returns explicit color when axis has color defined', () {
        // Given: An axis with explicit color
        final axisConfig = const YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          color: Colors.blue,
        );
        final series = [
          createSeries(id: 'power', color: Colors.red, yAxisId: 'power'),
        ];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns the explicit axis color (not series color)
        expect(color, Colors.blue);
      });

      test('returns series color when axis has no explicit color', () {
        // Given: An axis without explicit color, but with a bound series
        final axisConfig = const YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          // No color specified
        );
        final series = [
          createSeries(id: 'power', color: Colors.orange, yAxisId: 'power'),
        ];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns the bound series color
        expect(color, Colors.orange);
      });

      test('returns first series color when multiple series bound to same axis', () {
        // Given: An axis with multiple bound series (no explicit color)
        final axisConfig = const YAxisConfig(
          id: 'shared',
          position: YAxisPosition.left,
        );
        final series = [
          createSeries(id: 'first', color: Colors.green, yAxisId: 'shared'),
          createSeries(id: 'second', color: Colors.purple, yAxisId: 'shared'),
          createSeries(id: 'third', color: Colors.teal, yAxisId: 'shared'),
        ];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns the first bound series color
        expect(color, Colors.green);
      });

      test('returns neutral color when no series bound to axis', () {
        // Given: An axis with no bound series
        final axisConfig = const YAxisConfig(
          id: 'orphan',
          position: YAxisPosition.left,
        );
        final series = [
          createSeries(id: 'other', color: Colors.red, yAxisId: 'different'),
        ];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns a neutral color (grey)
        expect(color, AxisColorResolver.neutralColor);
      });

      test('returns neutral color when series has null yAxisId and axis is not first', () {
        // Given: An axis that's NOT the first/default and series with null yAxisId
        const axisConfig = YAxisConfig(
          id: 'custom',
          position: YAxisPosition.right, // Not the first axis position
        );
        // First axis would be the default
        const firstAxis = YAxisConfig(
          id: 'first',
          position: YAxisPosition.left,
        );
        final series = [
          createSeries(id: 'unbound', color: Colors.pink, yAxisId: null),
        ];

        // When: Resolving axis color for non-default axis
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
          allAxes: [firstAxis, axisConfig], // Provides context
        );

        // Then: Returns neutral color (unbound goes to first/default)
        expect(color, AxisColorResolver.neutralColor);
      });

      test('binds series with null yAxisId to first axis', () {
        // Given: First axis in list (considered default) and series with null yAxisId
        const firstAxis = YAxisConfig(
          id: 'default',
          position: YAxisPosition.left,
        );
        const secondAxis = YAxisConfig(
          id: 'secondary',
          position: YAxisPosition.right,
        );
        final series = [
          createSeries(id: 'unbound', color: Colors.cyan, yAxisId: null),
        ];

        // When: Resolving axis color for first axis
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: firstAxis,
          series: series,
          allAxes: [firstAxis, secondAxis],
        );

        // Then: Returns the unbound series color (bound to first/default)
        expect(color, Colors.cyan);
      });
    });

    group('resolveAllAxisColors', () {
      test('resolves colors for all axes in configuration', () {
        // Given: Multiple axes with different color scenarios
        final axes = [
          const YAxisConfig(id: 'power', position: YAxisPosition.left, color: Colors.blue),
          const YAxisConfig(id: 'hr', position: YAxisPosition.right),
          const YAxisConfig(id: 'cadence', position: YAxisPosition.leftOuter),
        ];
        final series = [
          createSeries(id: 'power-series', color: Colors.red, yAxisId: 'power'),
          createSeries(id: 'hr-series', color: Colors.red.shade600, yAxisId: 'hr'),
          createSeries(id: 'cadence-series', color: Colors.green, yAxisId: 'cadence'),
        ];

        // When: Resolving all axis colors
        final colorMap = AxisColorResolver.resolveAllAxisColors(
          axes: axes,
          series: series,
        );

        // Then: Returns correct color for each axis
        expect(colorMap['power'], Colors.blue); // Explicit color
        expect(colorMap['hr'], Colors.red.shade600); // From series
        expect(colorMap['cadence'], Colors.green); // From series
      });

      test('returns empty map for empty axes list', () {
        // Given: No axes
        final axes = <YAxisConfig>[];
        final series = [
          createSeries(id: 'orphan', color: Colors.red, yAxisId: 'nonexistent'),
        ];

        // When: Resolving all axis colors
        final colorMap = AxisColorResolver.resolveAllAxisColors(
          axes: axes,
          series: series,
        );

        // Then: Returns empty map
        expect(colorMap, isEmpty);
      });
    });

    group('getBoundSeries', () {
      test('returns series explicitly bound to axis by yAxisId', () {
        // Given: Series with explicit axis binding
        final series = [
          createSeries(id: 'power', color: Colors.blue, yAxisId: 'power-axis'),
          createSeries(id: 'hr', color: Colors.red, yAxisId: 'hr-axis'),
          createSeries(id: 'cadence', color: Colors.green, yAxisId: 'power-axis'),
        ];

        // When: Getting bound series
        final bound = AxisColorResolver.getBoundSeries(
          axisId: 'power-axis',
          series: series,
          isFirstAxis: false,
        );

        // Then: Returns only series bound to that axis
        expect(bound.length, 2);
        expect(bound.map((s) => s.id), containsAll(['power', 'cadence']));
      });

      test('includes unbound series when axis is first in list', () {
        // Given: Mix of bound and unbound series
        final series = [
          createSeries(id: 'bound', color: Colors.blue, yAxisId: 'first'),
          createSeries(id: 'unbound', color: Colors.red, yAxisId: null),
        ];

        // When: Getting bound series for first axis
        final bound = AxisColorResolver.getBoundSeries(
          axisId: 'first',
          series: series,
          isFirstAxis: true, // First axis is the default
        );

        // Then: Returns both bound and unbound series
        expect(bound.length, 2);
        expect(bound.map((s) => s.id), containsAll(['bound', 'unbound']));
      });

      test('returns empty list when no series bound', () {
        // Given: Series bound to different axes
        final series = [
          createSeries(id: 'other', color: Colors.blue, yAxisId: 'other-axis'),
        ];

        // When: Getting bound series for unrelated axis
        final bound = AxisColorResolver.getBoundSeries(
          axisId: 'orphan-axis',
          series: series,
          isFirstAxis: false,
        );

        // Then: Returns empty list
        expect(bound, isEmpty);
      });
    });

    group('neutralColor', () {
      test('is a grey color suitable for neutral axes', () {
        // When: Accessing the neutral color
        final color = AxisColorResolver.neutralColor;

        // Then: It's a grey color
        expect(color.red, color.green);
        expect(color.green, color.blue);
        // Should be a medium grey, not too light or dark
        expect(color.red, greaterThan(80));
        expect(color.red, lessThan(180));
      });
    });

    group('edge cases', () {
      test('handles series with same color as axis gracefully', () {
        // Given: Axis and series with same color
        final axisConfig = const YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          color: Colors.blue,
        );
        final series = [
          createSeries(id: 'power', color: Colors.blue, yAxisId: 'power'),
        ];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns the color (no conflict)
        expect(color, Colors.blue);
      });

      test('handles empty series list', () {
        // Given: No series at all
        final axisConfig = const YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
        );
        final series = <ChartSeries>[];

        // When: Resolving axis color
        final color = AxisColorResolver.resolveAxisColor(
          axisConfig: axisConfig,
          series: series,
        );

        // Then: Returns neutral color
        expect(color, AxisColorResolver.neutralColor);
      });

      test('resolves color with mixed explicit and derived colors', () {
        // Given: Mix of axes with and without explicit colors
        final axes = [
          const YAxisConfig(id: 'explicit', position: YAxisPosition.left, color: Colors.purple),
          const YAxisConfig(id: 'derived', position: YAxisPosition.right),
          const YAxisConfig(id: 'neutral', position: YAxisPosition.leftOuter),
        ];
        final series = [
          createSeries(id: 's1', color: Colors.orange, yAxisId: 'derived'),
        ];

        // When: Resolving all colors
        final colorMap = AxisColorResolver.resolveAllAxisColors(
          axes: axes,
          series: series,
        );

        // Then: Each axis gets appropriate color
        expect(colorMap['explicit'], Colors.purple);
        expect(colorMap['derived'], Colors.orange);
        expect(colorMap['neutral'], AxisColorResolver.neutralColor);
      });
    });
  });
}
