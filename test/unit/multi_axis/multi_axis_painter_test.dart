// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/painting.dart' hide TextStyle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisLayoutDelegate', () {
    const delegate = MultiAxisLayoutDelegate();
    const defaultStyle = painting.TextStyle(fontSize: 12);

    group('computeAxisWidths', () {
      test('returns empty map for empty axis list', () {
        final result = delegate.computeAxisWidths(
          axes: [],
          axisBounds: {},
          labelStyle: defaultStyle,
        );

        expect(result, isEmpty);
      });

      test('computes width based on label text measurement', () {
        final axes = [
          YAxisConfig(id: 'test', position: YAxisPosition.left),
        ];
        final bounds = {
          'test': const DataRange(min: 0.0, max: 100.0),
        };

        final result = delegate.computeAxisWidths(
          axes: axes,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        );

        expect(result['test'], isNotNull);
        expect(result['test']!, greaterThan(0));
      });

      test('respects YAxisConfig.minWidth', () {
        const minWidth = 60.0;
        final axes = [
          YAxisConfig(
            id: 'test',
            position: YAxisPosition.left,
            minWidth: minWidth,
          ),
        ];
        final bounds = {
          'test': const DataRange(min: 0.0, max: 10.0), // Small values
        };

        final result = delegate.computeAxisWidths(
          axes: axes,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        );

        expect(result['test'], greaterThanOrEqualTo(minWidth));
      });

      test('respects YAxisConfig.maxWidth', () {
        const maxWidth = 50.0;
        final axes = [
          YAxisConfig(
            id: 'test',
            position: YAxisPosition.left,
            maxWidth: maxWidth,
          ),
        ];
        final bounds = {
          'test': const DataRange(min: 0.0, max: 1000000.0), // Large values
        };

        final result = delegate.computeAxisWidths(
          axes: axes,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        );

        expect(result['test'], lessThanOrEqualTo(maxWidth));
      });

      test('includes space for unit suffix', () {
        final axesWithUnit = [
          YAxisConfig(
            id: 'withUnit',
            position: YAxisPosition.left,
            unit: 'W',
          ),
        ];
        final axesWithoutUnit = [
          YAxisConfig(
            id: 'withoutUnit',
            position: YAxisPosition.left,
          ),
        ];
        final bounds = {
          'withUnit': const DataRange(min: 0.0, max: 100.0),
          'withoutUnit': const DataRange(min: 0.0, max: 100.0),
        };

        final widthWithUnit = delegate.computeAxisWidths(
          axes: axesWithUnit,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        )['withUnit']!;

        final widthWithoutUnit = delegate.computeAxisWidths(
          axes: axesWithoutUnit,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        )['withoutUnit']!;

        // Width with unit should be greater or equal
        expect(widthWithUnit, greaterThanOrEqualTo(widthWithoutUnit));
      });

      test('accounts for tick marks width', () {
        final axes = [
          YAxisConfig(
            id: 'test',
            position: YAxisPosition.left,
            showTicks: true,
          ),
        ];
        final bounds = {
          'test': const DataRange(min: 0.0, max: 100.0),
        };

        final result = delegate.computeAxisWidths(
          axes: axes,
          axisBounds: bounds,
          labelStyle: defaultStyle,
        );

        // Should include tick mark padding
        expect(result['test']!, greaterThan(0));
      });
    });

    group('getTotalLeftWidth', () {
      test('returns 0 for no left axes', () {
        final axes = [
          YAxisConfig(id: 'r1', position: YAxisPosition.right),
          YAxisConfig(id: 'r2', position: YAxisPosition.rightOuter),
        ];
        final widths = {'r1': 50.0, 'r2': 50.0};

        final result = delegate.getTotalLeftWidth(axes, widths);

        expect(result, equals(0.0));
      });

      test('sums widths of left and leftOuter axes', () {
        final axes = [
          YAxisConfig(id: 'l1', position: YAxisPosition.left),
          YAxisConfig(id: 'l2', position: YAxisPosition.leftOuter),
        ];
        final widths = {'l1': 40.0, 'l2': 50.0};

        final result = delegate.getTotalLeftWidth(axes, widths);

        expect(result, equals(90.0));
      });
    });

    group('getTotalRightWidth', () {
      test('returns 0 for no right axes', () {
        final axes = [
          YAxisConfig(id: 'l1', position: YAxisPosition.left),
          YAxisConfig(id: 'l2', position: YAxisPosition.leftOuter),
        ];
        final widths = {'l1': 50.0, 'l2': 50.0};

        final result = delegate.getTotalRightWidth(axes, widths);

        expect(result, equals(0.0));
      });

      test('sums widths of right and rightOuter axes', () {
        final axes = [
          YAxisConfig(id: 'r1', position: YAxisPosition.right),
          YAxisConfig(id: 'r2', position: YAxisPosition.rightOuter),
        ];
        final widths = {'r1': 40.0, 'r2': 50.0};

        final result = delegate.getTotalRightWidth(axes, widths);

        expect(result, equals(90.0));
      });
    });
  });

  group('AxisLayoutManager', () {
    const manager = AxisLayoutManager();
    const chartArea = Rect.fromLTWH(0, 0, 800, 600);

    group('getAxisRect', () {
      test('positions leftOuter axis at far left', () {
        final axis = YAxisConfig(id: 'lo', position: YAxisPosition.leftOuter);
        final allAxes = [
          axis,
          YAxisConfig(id: 'l', position: YAxisPosition.left),
        ];
        final widths = {'lo': 50.0, 'l': 40.0};

        final rect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axis,
          axisWidths: widths,
          allAxes: allAxes,
        );

        expect(rect.left, equals(0.0));
        expect(rect.width, equals(50.0));
      });

      test('positions left axis inside leftOuter', () {
        final leftAxis = YAxisConfig(id: 'l', position: YAxisPosition.left);
        final allAxes = [
          YAxisConfig(id: 'lo', position: YAxisPosition.leftOuter),
          leftAxis,
        ];
        final widths = {'lo': 50.0, 'l': 40.0};

        final rect = manager.getAxisRect(
          chartArea: chartArea,
          axis: leftAxis,
          axisWidths: widths,
          allAxes: allAxes,
        );

        // Left axis should be after leftOuter
        expect(rect.left, equals(50.0));
        expect(rect.width, equals(40.0));
      });

      test('positions right axis at right edge of plot area', () {
        final axis = YAxisConfig(id: 'r', position: YAxisPosition.right);
        final allAxes = [
          YAxisConfig(id: 'l', position: YAxisPosition.left),
          axis,
          YAxisConfig(id: 'ro', position: YAxisPosition.rightOuter),
        ];
        final widths = {'l': 40.0, 'r': 50.0, 'ro': 60.0};

        final rect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axis,
          axisWidths: widths,
          allAxes: allAxes,
        );

        // right axis should be before rightOuter
        // Plot area ends at chartArea.right - rightOuter width
        expect(rect.right, equals(800.0 - 60.0));
        expect(rect.width, equals(50.0));
      });

      test('positions rightOuter axis outside right', () {
        final axis = YAxisConfig(id: 'ro', position: YAxisPosition.rightOuter);
        final allAxes = [
          YAxisConfig(id: 'r', position: YAxisPosition.right),
          axis,
        ];
        final widths = {'r': 50.0, 'ro': 60.0};

        final rect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axis,
          axisWidths: widths,
          allAxes: allAxes,
        );

        // rightOuter should be at the far right
        expect(rect.right, equals(800.0));
        expect(rect.width, equals(60.0));
      });

      test('handles single axis at each position', () {
        // Test single left axis
        final leftAxis = YAxisConfig(id: 'l', position: YAxisPosition.left);
        final widths = {'l': 50.0};

        final rect = manager.getAxisRect(
          chartArea: chartArea,
          axis: leftAxis,
          axisWidths: widths,
          allAxes: [leftAxis],
        );

        expect(rect.left, equals(0.0));
        expect(rect.width, equals(50.0));
        expect(rect.top, equals(chartArea.top));
        expect(rect.height, equals(chartArea.height));
      });

      test('handles all 4 axes simultaneously', () {
        final axes = [
          YAxisConfig(id: 'lo', position: YAxisPosition.leftOuter),
          YAxisConfig(id: 'l', position: YAxisPosition.left),
          YAxisConfig(id: 'r', position: YAxisPosition.right),
          YAxisConfig(id: 'ro', position: YAxisPosition.rightOuter),
        ];
        final widths = {'lo': 40.0, 'l': 50.0, 'r': 50.0, 'ro': 40.0};

        final loRect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axes[0],
          axisWidths: widths,
          allAxes: axes,
        );
        final lRect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axes[1],
          axisWidths: widths,
          allAxes: axes,
        );
        final rRect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axes[2],
          axisWidths: widths,
          allAxes: axes,
        );
        final roRect = manager.getAxisRect(
          chartArea: chartArea,
          axis: axes[3],
          axisWidths: widths,
          allAxes: axes,
        );

        // Verify ordering: leftOuter | left | plot | right | rightOuter
        expect(loRect.left, equals(0.0));
        expect(lRect.left, equals(loRect.right));
        expect(roRect.right, equals(chartArea.right));
        expect(rRect.right, equals(roRect.left));

        // No overlap between left-side and right-side
        expect(lRect.right, lessThan(rRect.left));
      });
    });

    group('computePlotArea', () {
      test('reduces chart area by axis widths', () {
        final axes = [
          YAxisConfig(id: 'lo', position: YAxisPosition.leftOuter),
          YAxisConfig(id: 'l', position: YAxisPosition.left),
          YAxisConfig(id: 'r', position: YAxisPosition.right),
          YAxisConfig(id: 'ro', position: YAxisPosition.rightOuter),
        ];
        final widths = {'lo': 40.0, 'l': 50.0, 'r': 50.0, 'ro': 40.0};

        final plotArea = manager.computePlotArea(
          chartArea: chartArea,
          axes: axes,
          axisWidths: widths,
        );

        // Left side: 40 + 50 = 90
        // Right side: 50 + 40 = 90
        expect(plotArea.left, equals(90.0));
        expect(plotArea.right, equals(800.0 - 90.0));
        expect(plotArea.width, equals(800.0 - 180.0));
        expect(plotArea.top, equals(chartArea.top));
        expect(plotArea.height, equals(chartArea.height));
      });

      test('preserves plot area when no axes', () {
        final plotArea = manager.computePlotArea(
          chartArea: chartArea,
          axes: [],
          axisWidths: {},
        );

        expect(plotArea, equals(chartArea));
      });
    });
  });

  group('MultiAxisPainter', () {
    group('tick value computation', () {
      test('generates appropriate tick count for axis height', () {
        final painter = MultiAxisPainter(
          axes: [YAxisConfig(id: 'test', position: YAxisPosition.left)],
          axisBounds: {'test': const DataRange(min: 0.0, max: 100.0)},
        );

        // Height 600 should generate reasonable tick count
        final ticks = painter.generateTicks(
          const DataRange(min: 0.0, max: 100.0),
          maxTicks: 10,
        );

        expect(ticks.length, greaterThanOrEqualTo(2));
        // Allow up to maxTicks + 1 because nice number algorithm can generate
        // one extra tick at the boundary
        expect(ticks.length, lessThanOrEqualTo(11));
      });

      test('uses nice numbers for tick values', () {
        final painter = MultiAxisPainter(
          axes: [YAxisConfig(id: 'test', position: YAxisPosition.left)],
          axisBounds: {'test': const DataRange(min: 0.0, max: 100.0)},
        );

        final ticks = painter.generateTicks(
          const DataRange(min: 0.0, max: 100.0),
          maxTicks: 10,
        );

        // Ticks should be "nice" round numbers
        for (final tick in ticks) {
          // Nice ticks are typically divisible by 1, 2, 5, or 10
          expect(tick % 1, equals(0.0), reason: 'Tick $tick should be a whole number');
        }
      });

      test('respects explicit min/max from YAxisConfig', () {
        final axis = YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          min: 10.0,
          max: 90.0,
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'test': const DataRange(min: 10.0, max: 90.0)},
        );

        final ticks = painter.generateTicks(
          const DataRange(min: 10.0, max: 90.0),
          maxTicks: 10,
        );

        // First tick should be >= min
        expect(ticks.first, greaterThanOrEqualTo(10.0));
        // Last tick should be <= max
        expect(ticks.last, lessThanOrEqualTo(90.0));
      });

      test('uses denormalized values from DataRange', () {
        // When we have bounds 0-1000, tick labels should show real values
        final painter = MultiAxisPainter(
          axes: [YAxisConfig(id: 'power', position: YAxisPosition.left)],
          axisBounds: {'power': const DataRange(min: 0.0, max: 1000.0)},
        );

        final ticks = painter.generateTicks(
          const DataRange(min: 0.0, max: 1000.0),
          maxTicks: 10,
        );

        // Ticks should span the actual data range
        expect(ticks.first, greaterThanOrEqualTo(0.0));
        expect(ticks.last, lessThanOrEqualTo(1000.0));
        expect(ticks.any((t) => t >= 100), isTrue, reason: 'Should have tick values in hundreds for 0-1000 range');
      });
    });

    group('formatTickLabel', () {
      test('formats tick value with unit suffix', () {
        final axis = YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          unit: 'W',
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'power': const DataRange(min: 0.0, max: 400.0)},
        );

        final label = painter.formatTickLabel(240.0, axis);

        expect(label, contains('240'));
        expect(label, contains('W'));
      });

      test('formats tick value without unit suffix when not provided', () {
        final axis = YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'power': const DataRange(min: 0.0, max: 400.0)},
        );

        final label = painter.formatTickLabel(240.0, axis);

        expect(label, equals('240'));
      });

      test('formats decimal values appropriately', () {
        final axis = YAxisConfig(
          id: 'percentage',
          position: YAxisPosition.left,
          unit: '%',
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'percentage': const DataRange(min: 0.0, max: 1.0)},
        );

        final label = painter.formatTickLabel(0.75, axis);

        expect(label, contains('0.75'));
        expect(label, contains('%'));
      });

      test('uses custom labelFormatter when provided', () {
        final axis = YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          labelFormatter: (value) => '${value.toInt()}★',
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'test': const DataRange(min: 0.0, max: 100.0)},
        );

        final label = painter.formatTickLabel(50.0, axis);

        expect(label, equals('50★'));
      });
    });

    group('paint behavior', () {
      test('handles empty axis configuration gracefully', () {
        final painter = MultiAxisPainter(
          axes: [],
          axisBounds: {},
        );

        // Should not throw
        expect(() => painter.axes, returnsNormally);
        expect(painter.axes, isEmpty);
      });

      test('uses axis color from YAxisConfig', () {
        const axisColor = Color(0xFF0000FF);
        final axis = YAxisConfig(
          id: 'test',
          position: YAxisPosition.left,
          color: axisColor,
        );
        final painter = MultiAxisPainter(
          axes: [axis],
          axisBounds: {'test': const DataRange(min: 0.0, max: 100.0)},
        );

        // Verify painter stores axis with color
        expect(painter.axes.first.color, equals(axisColor));
      });
    });
  });

  group('Acceptance Scenarios', () {
    test('renders 2 axes - one left, one right', () {
      final axes = [
        YAxisConfig(
          id: 'power',
          position: YAxisPosition.left,
          color: const Color(0xFF0000FF),
          unit: 'W',
        ),
        YAxisConfig(
          id: 'heartrate',
          position: YAxisPosition.right,
          color: const Color(0xFFFF0000),
          unit: 'bpm',
        ),
      ];

      final bounds = {
        'power': const DataRange(min: 0.0, max: 400.0),
        'heartrate': const DataRange(min: 60.0, max: 200.0),
      };

      final painter = MultiAxisPainter(axes: axes, axisBounds: bounds);

      expect(painter.axes.length, equals(2));
      expect(painter.axisBounds['power'], isNotNull);
      expect(painter.axisBounds['heartrate'], isNotNull);
    });

    test('renders 4 axes at all positions', () {
      final axes = [
        YAxisConfig(id: 'a1', position: YAxisPosition.leftOuter),
        YAxisConfig(id: 'a2', position: YAxisPosition.left),
        YAxisConfig(id: 'a3', position: YAxisPosition.right),
        YAxisConfig(id: 'a4', position: YAxisPosition.rightOuter),
      ];

      final bounds = {
        'a1': const DataRange(min: 0.0, max: 100.0),
        'a2': const DataRange(min: 0.0, max: 1000.0),
        'a3': const DataRange(min: 60.0, max: 200.0),
        'a4': const DataRange(min: 0.0, max: 50.0),
      };

      final painter = MultiAxisPainter(axes: axes, axisBounds: bounds);

      expect(painter.axes.length, equals(4));

      // Verify all positions are represented
      final positions = painter.axes.map((a) => a.position).toSet();
      expect(positions, contains(YAxisPosition.leftOuter));
      expect(positions, contains(YAxisPosition.left));
      expect(positions, contains(YAxisPosition.right));
      expect(positions, contains(YAxisPosition.rightOuter));
    });

    test('each axis shows original scale values', () {
      final powerAxis = YAxisConfig(
        id: 'power',
        position: YAxisPosition.left,
        unit: 'W',
      );
      final hrAxis = YAxisConfig(
        id: 'heartrate',
        position: YAxisPosition.right,
        unit: 'bpm',
      );

      final bounds = {
        'power': const DataRange(min: 0.0, max: 400.0),
        'heartrate': const DataRange(min: 60.0, max: 200.0),
      };

      final painter = MultiAxisPainter(
        axes: [powerAxis, hrAxis],
        axisBounds: bounds,
      );

      // Power axis ticks should be in 0-400 range (not normalized 0-1)
      final powerTicks = painter.generateTicks(bounds['power']!, maxTicks: 10);
      expect(powerTicks.every((t) => t >= 0 && t <= 400), isTrue);

      // HR axis ticks should be in 60-200 range
      final hrTicks = painter.generateTicks(bounds['heartrate']!, maxTicks: 10);
      expect(hrTicks.every((t) => t >= 60 && t <= 200), isTrue);

      // Labels should show original values with units
      final powerLabel = painter.formatTickLabel(240.0, powerAxis);
      expect(powerLabel, contains('W'));

      final hrLabel = painter.formatTickLabel(140.0, hrAxis);
      expect(hrLabel, contains('bpm'));
    });
  });

  group('Nice number algorithm', () {
    test('generates nice tick values for various ranges', () {
      final painter = MultiAxisPainter(
        axes: [YAxisConfig(id: 'test', position: YAxisPosition.left)],
        axisBounds: {},
      );

      // Test range 0-100
      var ticks = painter.generateTicks(
        const DataRange(min: 0.0, max: 100.0),
        maxTicks: 10,
      );
      expect(ticks, containsAll([0.0]));
      expect(ticks.last, lessThanOrEqualTo(100.0));

      // Test range 0-1000
      ticks = painter.generateTicks(
        const DataRange(min: 0.0, max: 1000.0),
        maxTicks: 10,
      );
      expect(ticks.first, greaterThanOrEqualTo(0.0));
      expect(ticks.last, lessThanOrEqualTo(1000.0));

      // Test range 60-200 (heart rate)
      ticks = painter.generateTicks(
        const DataRange(min: 60.0, max: 200.0),
        maxTicks: 8,
      );
      expect(ticks.first, greaterThanOrEqualTo(60.0));
      expect(ticks.last, lessThanOrEqualTo(200.0));
    });

    test('handles decimal ranges', () {
      final painter = MultiAxisPainter(
        axes: [YAxisConfig(id: 'test', position: YAxisPosition.left)],
        axisBounds: {},
      );

      // Test range 0-1
      final ticks = painter.generateTicks(
        const DataRange(min: 0.0, max: 1.0),
        maxTicks: 10,
      );

      expect(ticks.first, greaterThanOrEqualTo(0.0));
      expect(ticks.last, lessThanOrEqualTo(1.0));
      expect(ticks.length, greaterThanOrEqualTo(2));
    });

    test('handles negative ranges', () {
      final painter = MultiAxisPainter(
        axes: [YAxisConfig(id: 'test', position: YAxisPosition.left)],
        axisBounds: {},
      );

      final ticks = painter.generateTicks(
        const DataRange(min: -100.0, max: 100.0),
        maxTicks: 10,
      );

      expect(ticks.any((t) => t < 0), isTrue);
      expect(ticks.any((t) => t >= 0), isTrue);
    });
  });
}
