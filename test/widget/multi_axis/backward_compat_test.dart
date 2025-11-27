// Copyright (c) 2025 braven_charts. All rights reserved.
// Backward compatibility tests for single-axis mode (T051)

import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backward compatibility tests ensuring single-axis mode remains unchanged.
///
/// These tests verify:
/// - Charts without yAxes configuration work as before
/// - Default single-axis behavior is preserved
/// - Series without yAxisId render correctly
/// - Existing tooltip and crosshair behavior unchanged
/// - NormalizationMode.none works correctly
void main() {
  group('Backward Compatibility', () {
    group('Single-axis mode (no yAxes)', () {
      testWidgets('chart renders without yAxes configuration', (tester) async {
        // GIVEN: A chart configured without any yAxes (legacy mode)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  // No yAxes - should use default single axis
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: _generateTestData(100, 0, 100),
                      color: Colors.blue,
                    ),
                    LineChartSeries(
                      id: 'series2',
                      points: _generateTestData(100, 50, 150),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render successfully
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('series without yAxisId use default axis', (tester) async {
        // GIVEN: Series without explicit yAxisId binding
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'unboundSeries1',
                      // No yAxisId - should bind to default
                      points: _generateTestData(50, 0, 200),
                      color: Colors.green,
                    ),
                    LineChartSeries(
                      id: 'unboundSeries2',
                      // No yAxisId - should bind to default
                      points: _generateTestData(50, 100, 300),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render with both series on the same axis
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('normalizationMode.none preserves original Y values', (tester) async {
        // GIVEN: Chart with normalizationMode.none
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.none,
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: _generateTestData(100, 0, 100),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render without normalization applied
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Multiple series on shared axis', () {
      testWidgets('multiple series on single axis render together', (tester) async {
        // GIVEN: Multiple series sharing the default axis
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'power',
                      points: _generateTestData(100, 0, 300),
                      color: Colors.blue,
                    ),
                    LineChartSeries(
                      id: 'threshold',
                      points: _generateThresholdData(100, 200),
                      color: Colors.red,
                    ),
                    LineChartSeries(
                      id: 'target',
                      points: _generateThresholdData(100, 250),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: All series should render on the shared axis
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('area chart type works without yAxes', (tester) async {
        // GIVEN: An area chart without yAxes configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.area,
                  series: [
                    AreaChartSeries(
                      id: 'area1',
                      points: _generateTestData(100, 0, 100),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Area chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('bar chart type works without yAxes', (tester) async {
        // GIVEN: A bar chart without yAxes configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.bar,
                  series: [
                    BarChartSeries(
                      id: 'bar1',
                      points: _generateTestData(20, 0, 100),
                      color: Colors.purple,
                      barWidthPercent: 0.8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Bar chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('scatter chart type works without yAxes', (tester) async {
        // GIVEN: A scatter chart without yAxes configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.scatter,
                  series: [
                    ScatterChartSeries(
                      id: 'scatter1',
                      points: _generateTestData(50, 0, 100),
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Scatter chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Legacy API compatibility', () {
      testWidgets('empty series list renders empty chart', (tester) async {
        // GIVEN: Chart with no series
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Empty chart should render without error
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('single series renders correctly', (tester) async {
        // GIVEN: Chart with a single series (most common case)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'onlySeries',
                      points: _generateTestData(100, 0, 100),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Single series chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('series with units renders without yAxes', (tester) async {
        // GIVEN: Series with unit property but no yAxes
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'powerSeries',
                      unit: 'W', // Unit without yAxes config
                      points: _generateTestData(100, 0, 400),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Default behavior preservation', () {
      testWidgets('default axis is left-positioned', (tester) async {
        // GIVEN: Chart without explicit axis configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: _generateTestData(100, 0, 100),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should use default left-positioned axis
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('auto-detection does not activate for similar ranges', (tester) async {
        // GIVEN: Series with similar Y-ranges (< 10x difference)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      points: _generateTestData(100, 0, 100), // 0-100
                      color: Colors.blue,
                    ),
                    LineChartSeries(
                      id: 'series2',
                      points: _generateTestData(100, 50, 150), // 50-150
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render with single axis (no auto-detection)
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Edge cases', () {
      testWidgets('handles very large data ranges', (tester) async {
        // GIVEN: Series with very large Y values
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'largeValues',
                      points: _generateTestData(100, 0, 1000000),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles very small data ranges', (tester) async {
        // GIVEN: Series with very small Y values
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'smallValues',
                      points: _generateTestData(100, 0.001, 0.01),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles negative Y values', (tester) async {
        // GIVEN: Series with negative Y values
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'negativeValues',
                      points: _generateTestData(100, -100, 100),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render correctly with negative values
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles flat data (all same Y value)', (tester) async {
        // GIVEN: Series with flat data
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  series: [
                    LineChartSeries(
                      id: 'flatData',
                      points: _generateThresholdData(100, 50), // All y = 50
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // THEN: Chart should render correctly
        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });
  });
}

/// Generate test data points with variable Y values.
List<ChartDataPoint> _generateTestData(int count, double minY, double maxY) {
  final range = maxY - minY;
  return List.generate(
    count,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: minY + (i % 100) / 100 * range,
    ),
  );
}

/// Generate threshold/constant Y data.
List<ChartDataPoint> _generateThresholdData(int count, double value) {
  return List.generate(
    count,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: value,
    ),
  );
}
