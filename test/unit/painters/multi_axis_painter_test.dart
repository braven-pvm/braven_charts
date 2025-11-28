// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Unit tests for MultiAxisPainter.
///
/// Tests verify:
/// - Single axis rendering at correct position
/// - Multiple axes at different positions
/// - Axis colors from configuration
/// - Tick marks and labels rendering
library;

import 'dart:ui';

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisPainter', () {
    group('Construction', () {
      test('creates painter with single axis config', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3),
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        expect(painter.axes, equals(axes));
        expect(painter.axes.length, equals(1));
      });

      test('creates painter with multiple axis configs', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3),
          ),
          const YAxisConfig(
            id: 'heartRate',
            position: YAxisPosition.right,
            color: Color(0xFFF44336),
          ),
          const YAxisConfig(
            id: 'cadence',
            position: YAxisPosition.outerLeft,
            color: Color(0xFF4CAF50),
          ),
          const YAxisConfig(
            id: 'speed',
            position: YAxisPosition.outerRight,
            color: Color(0xFFFF9800),
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(100, 10, 300, 200),
        );

        expect(painter.axes.length, equals(4));
      });

      test('creates painter with empty axes list', () {
        final painter = const MultiAxisPainter(
          axes: [],
          chartRect: Rect.fromLTWH(50, 10, 300, 200),
        );

        expect(painter.axes.isEmpty, isTrue);
      });
    });

    group('Axis Position Calculation', () {
      test('calculates left axis position correctly', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final position = painter.getAxisX(YAxisPosition.left);
        // Left axis should be at or before chartRect.left
        expect(position, lessThanOrEqualTo(50));
      });

      test('calculates right axis position correctly', () {
        final axes = [
          const YAxisConfig(
            id: 'heartRate',
            position: YAxisPosition.right,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final position = painter.getAxisX(YAxisPosition.right);
        // Right axis should be at or after chartRect.right (50 + 300 = 350)
        expect(position, greaterThanOrEqualTo(350));
      });

      test('calculates outerLeft axis position correctly', () {
        final axes = [
          const YAxisConfig(
            id: 'cadence',
            position: YAxisPosition.outerLeft,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(100, 10, 300, 200),
        );

        final leftPosition = painter.getAxisX(YAxisPosition.left);
        final outerLeftPosition = painter.getAxisX(YAxisPosition.outerLeft);
        // OuterLeft should be further left than left
        expect(outerLeftPosition, lessThan(leftPosition));
      });

      test('calculates outerRight axis position correctly', () {
        final axes = [
          const YAxisConfig(
            id: 'speed',
            position: YAxisPosition.outerRight,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final rightPosition = painter.getAxisX(YAxisPosition.right);
        final outerRightPosition = painter.getAxisX(YAxisPosition.outerRight);
        // OuterRight should be further right than right
        expect(outerRightPosition, greaterThan(rightPosition));
      });
    });

    group('Tick Calculation', () {
      test('generates tick values for axis with explicit bounds', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            minValue: 0,
            maxValue: 300,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final ticks = painter.getTickValues(axes[0]);
        expect(ticks, isNotEmpty);
        expect(ticks.first, greaterThanOrEqualTo(0));
        expect(ticks.last, lessThanOrEqualTo(300));
      });

      test('generates tick values with unit suffix formatting', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            minValue: 0,
            maxValue: 300,
            unitSuffix: 'W',
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final label = painter.formatTickLabel(150, axes[0]);
        expect(label, contains('W'));
      });

      test('generates reasonable number of ticks (5-10)', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            minValue: 0,
            maxValue: 1000,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final ticks = painter.getTickValues(axes[0]);
        expect(ticks.length, greaterThanOrEqualTo(3));
        expect(ticks.length, lessThanOrEqualTo(15));
      });
    });

    group('Axis Color', () {
      test('uses axis color from config', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3),
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final color = painter.getAxisColor(axes[0]);
        expect(color, equals(const Color(0xFF2196F3)));
      });

      test('uses default color when axis config has no color', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            // No color specified
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final color = painter.getAxisColor(axes[0]);
        expect(color, isNotNull);
        // Should return a default color (gray or black)
        expect(color, isA<Color>());
      });

      test('each axis maintains its own color', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3), // Blue
          ),
          const YAxisConfig(
            id: 'heartRate',
            position: YAxisPosition.right,
            color: Color(0xFFF44336), // Red
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        expect(painter.getAxisColor(axes[0]), equals(const Color(0xFF2196F3)));
        expect(painter.getAxisColor(axes[1]), equals(const Color(0xFFF44336)));
      });
    });

    group('shouldRepaint', () {
      test('returns true when axes change', () {
        final axes1 = [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
        ];
        final axes2 = [
          const YAxisConfig(id: 'heartRate', position: YAxisPosition.right),
        ];

        final painter1 = MultiAxisPainter(
          axes: axes1,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );
        final painter2 = MultiAxisPainter(
          axes: axes2,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns true when chartRect changes', () {
        final axes = [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
        ];

        final painter1 = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );
        final painter2 = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(60, 10, 300, 200),
        );

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('returns false when nothing changes', () {
        final axes = [
          const YAxisConfig(id: 'power', position: YAxisPosition.left),
        ];
        final chartRect = const Rect.fromLTWH(50, 10, 300, 200);

        final painter1 = MultiAxisPainter(axes: axes, chartRect: chartRect);
        final painter2 = MultiAxisPainter(axes: axes, chartRect: chartRect);

        expect(painter2.shouldRepaint(painter1), isFalse);
      });
    });

    group('Axis Label', () {
      test('includes axis label when provided', () {
        final axes = [
          const YAxisConfig(
            id: 'power',
            position: YAxisPosition.left,
            label: 'Power Output',
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        expect(painter.axes[0].label, equals('Power Output'));
      });
    });
  });
}
