// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for Task 15: Y-axis validation in BravenChartPlus.
///
/// These tests verify:
/// - Widget accepts up to 4 Y-axes
/// - Widget assertion fails with 5+ Y-axes
/// - Widget accepts axes at different positions
/// - Widget assertion fails with duplicate positions
void main() {
  group('BravenChartPlus Y-axis validation', () {
    // Sample series for all tests
    final testSeries = [
      const LineChartSeries(
        id: 'test',
        name: 'Test',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 200),
        ],
      ),
    ];

    group('axis count validation', () {
      testWidgets('accepts up to 4 Y-axes', (tester) async {
        // Valid configuration with exactly 4 axes
        final validAxes = [
          YAxisConfig(id: 'axis1', position: YAxisPosition.leftOuter),
          YAxisConfig(id: 'axis2', position: YAxisPosition.left),
          YAxisConfig(id: 'axis3', position: YAxisPosition.right),
          YAxisConfig(id: 'axis4', position: YAxisPosition.rightOuter),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: testSeries,
                  yAxes: validAxes,
                ),
              ),
            ),
          ),
        );

        // Should build without error
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('assertion fails with 5+ Y-axes', (tester) async {
        // Invalid configuration with 5 axes (exceeds max)
        final invalidAxes = [
          YAxisConfig(id: 'axis1', position: YAxisPosition.leftOuter),
          YAxisConfig(id: 'axis2', position: YAxisPosition.left),
          YAxisConfig(id: 'axis3', position: YAxisPosition.right),
          YAxisConfig(id: 'axis4', position: YAxisPosition.rightOuter),
          YAxisConfig(id: 'axis5', position: YAxisPosition.left), // 5th axis!
        ];

        // Expect assertion error when building widget
        expect(
          () => BravenChartPlus(
            chartType: ChartType.line,
            series: testSeries,
            yAxes: invalidAxes,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('position uniqueness validation', () {
      testWidgets('accepts axes at different positions', (tester) async {
        // Valid: all unique positions
        final validAxes = [
          YAxisConfig(id: 'axis1', position: YAxisPosition.left),
          YAxisConfig(id: 'axis2', position: YAxisPosition.right),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: testSeries,
                  yAxes: validAxes,
                ),
              ),
            ),
          ),
        );

        // Should build without error
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('assertion fails with duplicate positions', (tester) async {
        // Invalid: two axes at the same position
        final duplicateAxes = [
          YAxisConfig(id: 'axis1', position: YAxisPosition.left),
          YAxisConfig(id: 'axis2', position: YAxisPosition.left), // Duplicate!
        ];

        // Expect assertion error when building widget
        expect(
          () => BravenChartPlus(
            chartType: ChartType.line,
            series: testSeries,
            yAxes: duplicateAxes,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('edge cases', () {
      testWidgets('accepts null yAxes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: testSeries,
                  // yAxes not provided (null)
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('accepts empty yAxes list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: testSeries,
                  yAxes: const [], // Empty list
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('accepts single Y-axis', (tester) async {
        final singleAxis = [
          YAxisConfig(id: 'axis1', position: YAxisPosition.left),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: testSeries,
                  yAxes: singleAxis,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });
}
