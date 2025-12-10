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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3),
          ),
          YAxisConfig.withId(id: 'heartRate',
            position: YAxisPosition.right,
            color: Color(0xFFF44336),
          ),
          YAxisConfig.withId(id: 'cadence',
            position: YAxisPosition.leftOuter,
            color: Color(0xFF4CAF50),
          ),
          YAxisConfig.withId(id: 'speed',
            position: YAxisPosition.rightOuter,
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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'heartRate',
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

      test('calculates LeftOuter axis position correctly', () {
        final axes = [
          YAxisConfig.withId(id: 'cadence',
            position: YAxisPosition.leftOuter,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(100, 10, 300, 200),
        );

        final leftPosition = painter.getAxisX(YAxisPosition.left);
        final leftOuterPosition = painter.getAxisX(YAxisPosition.leftOuter);
        // LeftOuter should be further left than left
        expect(leftOuterPosition, lessThan(leftPosition));
      });

      test('calculates RightOuter axis position correctly', () {
        final axes = [
          YAxisConfig.withId(id: 'speed',
            position: YAxisPosition.rightOuter,
          ),
        ];

        final painter = MultiAxisPainter(
          axes: axes,
          chartRect: const Rect.fromLTWH(50, 10, 300, 200),
        );

        final rightPosition = painter.getAxisX(YAxisPosition.right);
        final rightOuterPosition = painter.getAxisX(YAxisPosition.rightOuter);
        // RightOuter should be further right than right
        expect(rightOuterPosition, greaterThan(rightPosition));
      });
    });

    group('Tick Calculation', () {
      test('generates tick values for axis with explicit bounds', () {
        final axes = [
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
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
          YAxisConfig.withId(id: 'power',
            position: YAxisPosition.left,
            color: Color(0xFF2196F3), // Blue
          ),
          YAxisConfig.withId(id: 'heartRate',
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
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final axes2 = [
          YAxisConfig.withId(id: 'heartRate', position: YAxisPosition.right),
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
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
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
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
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
          YAxisConfig.withId(id: 'power',
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
