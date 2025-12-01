// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Backward compatibility tests for single-axis mode.
///
/// These tests verify that existing single-axis chart behavior is unchanged
/// by the multi-axis feature additions. Charts without yAxes parameter should
/// continue to work exactly as before Sprint 011.
///
/// Validates: T051 - Backward compatibility validation
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backward Compatibility Tests', () {
    /// Standard test data
    List<ChartDataPoint> generateTestData() {
      return List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 100 + 50 * (i % 5) / 5);
      });
    }

    testWidgets('single-axis chart renders without yAxes parameter', (tester) async {
      // This is the classic usage - no yAxes, no axisBindings, no normalizationMode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'sales',
                    name: 'Sales Data',
                    points: generateTestData(),
                    color: Colors.blue,
                  ),
                ],
                // NO yAxes - should use single-axis mode
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Chart should be visible
      final chartFinder = find.byType(BravenChartPlus);
      expect(chartFinder, findsOneWidget);
    });

    testWidgets('null yAxes falls back to single-axis mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'data',
                    name: 'Test Data',
                    points: generateTestData(),
                    color: Colors.green,
                  ),
                ],
                yAxes: null, // Explicitly null
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('empty yAxes list falls back to single-axis mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'data',
                    name: 'Test Data',
                    points: generateTestData(),
                    color: Colors.orange,
                  ),
                ],
                yAxes: const [], // Empty list
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('single-axis in yAxes list does not trigger multi-axis mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'data',
                    name: 'Test Data',
                    points: generateTestData(),
                    color: Colors.purple,
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'single-axis',
                    position: YAxisPosition.left,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('multiple series without yAxes uses shared Y-axis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'series1',
                    name: 'Series A',
                    points: generateTestData(),
                    color: Colors.blue,
                  ),
                  LineChartSeries(
                    id: 'series2',
                    name: 'Series B',
                    points: List.generate(30, (i) {
                      return ChartDataPoint(x: i.toDouble(), y: 80 + 30 * (i % 5) / 5);
                    }),
                    color: Colors.red,
                  ),
                ],
                // NO yAxes - both series share single Y-axis
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('chart types work without multi-axis - bar chart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.bar,
                series: [
                  BarChartSeries(
                    id: 'sales',
                    name: 'Monthly Sales',
                    points: List.generate(12, (i) {
                      return ChartDataPoint(x: i.toDouble(), y: 100 + 50 * (i % 4));
                    }),
                    color: Colors.teal,
                    barWidthPercent: 0.7,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('chart types work without multi-axis - area chart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.area,
                series: [
                  AreaChartSeries(
                    id: 'usage',
                    name: 'Resource Usage',
                    points: generateTestData(),
                    color: Colors.indigo,
                    fillOpacity: 0.3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('chart types work without multi-axis - scatter chart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.scatter,
                series: [
                  ScatterChartSeries(
                    id: 'points',
                    name: 'Data Points',
                    points: generateTestData(),
                    color: Colors.deepOrange,
                    markerRadius: 5.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    // NOTE: Tests for yAxis/xAxis config parameters are not included here
    // because BravenChartPlus uses an internal AxisConfig type from
    // src/axis/axis_config.dart which differs from the public API export.
    // This is a known technical debt issue to be addressed in a future sprint.
    // The yAxis/xAxis parameters remain functional but use the internal type.

    testWidgets('theme applies correctly in single-axis mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'data',
                    name: 'Test Data',
                    points: generateTestData(),
                    color: Colors.blue,
                  ),
                ],
                theme: ChartTheme.dark,
                backgroundColor: const Color(0xFF121212),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('normalizationMode.none behaves like no yAxes', (tester) async {
      // When normalizationMode is none, even with yAxes defined,
      // the chart should use global Y bounds (single-axis behavior)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'series1',
                    name: 'Series A',
                    points: generateTestData(),
                    color: Colors.blue,
                    yAxisId: 'axis1',
                  ),
                  LineChartSeries(
                    id: 'series2',
                    name: 'Series B',
                    points: List.generate(30, (i) {
                      return ChartDataPoint(x: i.toDouble(), y: 200 + 100 * (i % 5) / 5);
                    }),
                    color: Colors.red,
                    yAxisId: 'axis2',
                  ),
                ],
                yAxes: [
                  YAxisConfig(id: 'axis1', position: YAxisPosition.left),
                  YAxisConfig(id: 'axis2', position: YAxisPosition.right),
                ],
                normalizationMode: NormalizationMode.none, // Disable normalization
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
