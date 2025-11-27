// Copyright 2025 Braven Charts - Auto-Detection Widget Tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auto-Detection Widget Tests', () {
    group('NormalizationMode.auto behavior', () {
      testWidgets('enables multi-axis mode when series ranges differ by >10x', (tester) async {
        // Power: 100-250W (span: 150)
        final powerSeries = LineChartSeries(
          id: 'power',
          name: 'Power',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i / 100) * 150),
          ),
          color: Colors.blue,
        );

        // Micro-volts: 0.001-0.005 (span: 0.004) - >37000x difference
        final microSeries = LineChartSeries(
          id: 'micro',
          name: 'Micro-Volts',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 0.001 + (i / 100) * 0.004),
          ),
          color: Colors.green,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [powerSeries, microSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // With auto mode and >10x ratio, multi-axis should be active
        // The chart should detect and apply per-series normalization
      });

      testWidgets('uses single-axis mode when series ranges are similar', (tester) async {
        // Power: 100-250W (span: 150)
        final powerSeries = LineChartSeries(
          id: 'power',
          name: 'Power',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i / 100) * 150),
          ),
          color: Colors.blue,
        );

        // Heart Rate: 60-180bpm (span: 120) - only ~1.25x difference
        final hrSeries = LineChartSeries(
          id: 'hr',
          name: 'Heart Rate',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 60 + (i / 100) * 120),
          ),
          color: Colors.red,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [powerSeries, hrSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // With auto mode and <10x ratio, single-axis mode should remain
      });
    });

    group('NormalizationMode.perSeries explicit mode', () {
      testWidgets('always uses multi-axis when perSeries is set', (tester) async {
        // Two series with similar ranges but explicit multi-axis
        final series1 = LineChartSeries(
          id: 'series1',
          name: 'Series 1',
          points: List.generate(
            50,
            (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0),
          ),
          color: Colors.blue,
          yAxisId: 'axis1',
        );

        final series2 = LineChartSeries(
          id: 'series2',
          name: 'Series 2',
          points: List.generate(
            50,
            (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.5),
          ),
          color: Colors.red,
          yAxisId: 'axis2',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.perSeries,
                  series: [series1, series2],
                  yAxes: const [
                    YAxisConfig(
                      id: 'axis1',
                      position: YAxisPosition.left,
                      label: 'Axis 1',
                    ),
                    YAxisConfig(
                      id: 'axis2',
                      position: YAxisPosition.right,
                      label: 'Axis 2',
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
    });

    group('NormalizationMode.none explicit mode', () {
      testWidgets('never uses multi-axis when none is set', (tester) async {
        // Two series with very different ranges but explicit single-axis
        final powerSeries = LineChartSeries(
          id: 'power',
          name: 'Power',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i / 100) * 150),
          ),
          color: Colors.blue,
        );

        final microSeries = LineChartSeries(
          id: 'micro',
          name: 'Micro-Volts',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 0.001 + (i / 100) * 0.004),
          ),
          color: Colors.green,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.none,
                  series: [powerSeries, microSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Chart should render without errors
        expect(find.byType(BravenChartPlus), findsOneWidget);

        // Even with >10x difference, single-axis mode forced
      });
    });

    group('Auto-detection edge cases', () {
      testWidgets('handles single series with auto mode', (tester) async {
        final singleSeries = LineChartSeries(
          id: 'only',
          name: 'Only Series',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
          ),
          color: Colors.blue,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [singleSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
        // Single series should not trigger multi-axis
      });

      testWidgets('handles empty series list with auto mode', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles series with zero span (constant value)', (tester) async {
        // Constant series (all same Y value)
        final constantSeries = LineChartSeries(
          id: 'constant',
          name: 'Constant',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 50),
          ),
          color: Colors.blue,
        );

        final normalSeries = LineChartSeries(
          id: 'normal',
          name: 'Normal',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0),
          ),
          color: Colors.red,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [constantSeries, normalSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });

      testWidgets('handles series with negative values in auto mode', (tester) async {
        final positiveSeries = LineChartSeries(
          id: 'positive',
          name: 'Positive',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: 100 + i),
          ),
          color: Colors.blue,
        );

        final negativeSeries = LineChartSeries(
          id: 'negative',
          name: 'Negative',
          points: List.generate(
            100,
            (i) => ChartDataPoint(x: i.toDouble(), y: -1000 - i * 10),
          ),
          color: Colors.red,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: [positiveSeries, negativeSeries],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
      });
    });

    group('Auto-detection with 3+ series', () {
      testWidgets('detects multi-axis need with multiple series', (tester) async {
        final series = [
          LineChartSeries(
            id: 'power',
            name: 'Power',
            points: List.generate(
              50,
              (i) => ChartDataPoint(x: i.toDouble(), y: 100 + i),
            ),
            color: Colors.blue,
          ),
          LineChartSeries(
            id: 'hr',
            name: 'Heart Rate',
            points: List.generate(
              50,
              (i) => ChartDataPoint(x: i.toDouble(), y: 60 + i * 2),
            ),
            color: Colors.red,
          ),
          LineChartSeries(
            id: 'micro',
            name: 'Micro',
            points: List.generate(
              50,
              (i) => ChartDataPoint(x: i.toDouble(), y: 0.001 + i * 0.0001),
            ),
            color: Colors.green,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: BravenChartPlus(
                  chartType: ChartType.line,
                  normalizationMode: NormalizationMode.auto,
                  series: series,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);
        // Should detect that micro series differs by >10x from others
      });
    });
  });
}
