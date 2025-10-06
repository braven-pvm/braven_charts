/// Unit tests for BarPositioner
///
/// Tests the bar chart positioning algorithms for grouped (side-by-side)
/// and stacked (cumulative) modes with proper spacing and negative value handling.
library;

import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/charts/bar/bar_positioner.dart';
import 'package:braven_charts/src/charts/base/chart_config.dart';

void main() {
  group('BarPositioner', () {
    group('Grouped Bar Positioning (Side-by-Side)', () {
      test('positions two series side-by-side with spacing', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 5.0,
        );

        final series1Values = [10.0, 20.0];
        final series2Values = [15.0, 25.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1Values, series2Values],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        // Should have 2 categories × 2 series = 4 bars
        expect(layout.length, equals(4));

        // First category should have two bars side-by-side
        final cat0Series0 = layout[0];
        final cat0Series1 = layout[1];

        // Bars should not overlap
        expect(cat0Series0.bounds.right, lessThanOrEqualTo(cat0Series1.bounds.left));

        // Spacing between bars
        expect(cat0Series1.bounds.left - cat0Series0.bounds.right, closeTo(2.0, 0.1));
      });

      test('calculates bar width correctly based on ratio', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.5, // Half the available width
          barSpacing: 0.0,
          groupSpacing: 0.0,
        );

        final seriesData = [[10.0]]; // Single series, single value

        final layout = positioner.calculateLayout(
          seriesData: seriesData,
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(1));
        
        // Bar width should be approximately categoryWidth * barWidthRatio
        final barWidth = layout[0].bounds.width;
        expect(barWidth, closeTo(50.0, 5.0)); // 100 * 0.5
      });

      test('handles three series grouped together', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 1.0,
          groupSpacing: 5.0,
        );

        final series1 = [10.0];
        final series2 = [15.0];
        final series3 = [20.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2, series3],
          categoryWidth: 120.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(3));

        // All three bars should be in sequence
        expect(layout[0].bounds.right, lessThanOrEqualTo(layout[1].bounds.left));
        expect(layout[1].bounds.right, lessThanOrEqualTo(layout[2].bounds.left));
      });

      test('applies group spacing between categories', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 10.0,
        );

        final series1 = [10.0, 20.0]; // Two categories
        final series2 = [15.0, 25.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        // 2 categories × 2 series = 4 bars
        expect(layout.length, equals(4));

        // Second category should start after first category + group spacing
        // layout[0], layout[1] are category 0
        // layout[2], layout[3] are category 1
        final category0End = layout[1].bounds.right;
        final category1Start = layout[2].bounds.left;

        expect(category1Start - category0End, greaterThan(5.0)); // Has spacing
      });

      test('handles horizontal orientation', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.horizontal,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 5.0,
        );

        final series1 = [10.0];
        final series2 = [15.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 0.0,
        );

        expect(layout.length, equals(2));

        // In horizontal orientation, bars extend horizontally from baseline
        expect(layout[0].bounds.left, equals(0.0)); // Starts at baseline
        expect(layout[0].bounds.width, equals(10.0)); // Extends by value
      });
    });

    group('Stacked Bar Positioning (Cumulative)', () {
      test('stacks two series vertically', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 5.0,
        );

        final series1 = [10.0]; // First series
        final series2 = [5.0];  // Second series stacks on top

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(2));

        // First bar: from baseline up by 10
        expect(layout[0].bounds.bottom, equals(100.0));
        expect(layout[0].bounds.height, equals(10.0));

        // Second bar: stacks on top of first (from 90 up by 5)
        expect(layout[1].bounds.bottom, equals(90.0)); // baseline - series1
        expect(layout[1].bounds.height, equals(5.0));
        expect(layout[1].bounds.top, equals(85.0)); // 90 - 5
      });

      test('stacks three series cumulatively', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 0.0,
        );

        final series1 = [10.0];
        final series2 = [5.0];
        final series3 = [3.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2, series3],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(3));

        // Cumulative stacking:
        // series1: baseline - 10 = 90 (top)
        // series2: 90 - 5 = 85 (top)
        // series3: 85 - 3 = 82 (top)
        expect(layout[0].bounds.top, equals(90.0));
        expect(layout[1].bounds.top, equals(85.0));
        expect(layout[2].bounds.top, equals(82.0));
      });

      test('handles multiple categories in stacked mode', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 5.0,
        );

        final series1 = [10.0, 20.0]; // Two categories
        final series2 = [5.0, 10.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        // 2 categories × 2 series = 4 bars
        expect(layout.length, equals(4));

        // First category: 2 stacked bars
        expect(layout[0].categoryIndex, equals(0));
        expect(layout[1].categoryIndex, equals(0));

        // Second category: 2 stacked bars
        expect(layout[2].categoryIndex, equals(1));
        expect(layout[3].categoryIndex, equals(1));
      });
    });

    group('Negative Value Handling', () {
      test('positions negative values below baseline in grouped mode', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 5.0,
        );

        final series1 = [10.0, -5.0]; // Positive then negative

        final layout = positioner.calculateLayout(
          seriesData: [series1],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(2));

        // Positive bar extends upward from baseline
        expect(layout[0].bounds.bottom, equals(100.0));
        expect(layout[0].bounds.top, equals(90.0)); // 100 - 10
        expect(layout[0].isNegative, isFalse);

        // Negative bar extends downward from baseline
        expect(layout[1].bounds.top, equals(100.0));
        expect(layout[1].bounds.bottom, equals(105.0)); // 100 + 5
        expect(layout[1].isNegative, isTrue);
      });

      test('stacks negative values separately in stacked mode', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 0.0,
        );

        final series1 = [10.0, -10.0];
        final series2 = [5.0, -5.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(4));

        // Category 0: Positive stacking upward
        expect(layout[0].bounds.bottom, equals(100.0)); // series1: baseline - 10
        expect(layout[1].bounds.bottom, equals(90.0));  // series2: stacks on series1

        // Category 1: Negative stacking downward
        expect(layout[2].bounds.top, equals(100.0));    // series1: baseline
        expect(layout[2].isNegative, isTrue);
        expect(layout[3].bounds.top, equals(110.0));    // series2: stacks below series1
        expect(layout[3].isNegative, isTrue);
      });

      test('handles mixed positive and negative values across series', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 0.0,
        );

        final series1 = [10.0];   // Positive
        final series2 = [-5.0];   // Negative
        final series3 = [3.0];    // Positive

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2, series3],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(3));

        // Positive values stack upward
        expect(layout[0].isNegative, isFalse);
        expect(layout[0].bounds.bottom, equals(100.0));

        // Negative value extends downward
        expect(layout[1].isNegative, isTrue);
        expect(layout[1].bounds.top, equals(100.0));

        // Another positive stacks on top of first positive
        expect(layout[2].isNegative, isFalse);
        expect(layout[2].bounds.bottom, equals(90.0)); // Stacks on series1
      });
    });

    group('Edge Cases', () {
      test('handles empty series data', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 5.0,
        );

        final layout = positioner.calculateLayout(
          seriesData: [],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.isEmpty, isTrue);
      });

      test('handles single value in single series', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.8,
          barSpacing: 2.0,
          groupSpacing: 5.0,
        );

        final layout = positioner.calculateLayout(
          seriesData: [[10.0]],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(1));
        expect(layout[0].value, equals(10.0));
      });

      test('handles zero values', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.stacked,
          barWidthRatio: 0.8,
          barSpacing: 0.0,
          groupSpacing: 0.0,
        );

        final series1 = [0.0, 10.0];
        final series2 = [5.0, 0.0];

        final layout = positioner.calculateLayout(
          seriesData: [series1, series2],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(4));

        // Zero height bars should still be created
        expect(layout[0].bounds.height, equals(0.0));
        expect(layout[3].bounds.height, equals(0.0));
      });

      test('handles very small bar width ratio', () {
        final positioner = BarPositioner(
          orientation: BarOrientation.vertical,
          groupingMode: BarGroupingMode.grouped,
          barWidthRatio: 0.1, // Very thin bars
          barSpacing: 1.0,
          groupSpacing: 5.0,
        );

        final layout = positioner.calculateLayout(
          seriesData: [[10.0]],
          categoryWidth: 100.0,
          chartHeight: 200.0,
          baseline: 100.0,
        );

        expect(layout.length, equals(1));
        expect(layout[0].bounds.width, closeTo(10.0, 2.0)); // 100 * 0.1
      });
    });
  });
}
