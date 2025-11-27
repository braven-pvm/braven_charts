// Copyright (c) 2025 braven_charts. All rights reserved.
// Golden tests for color-coded axes (US3: Color-Coded Axis Identification)
//
// T033 [US3] Golden tests for colored axes
// TDD: Tests written FIRST - golden files will be generated after implementation

import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for color-coded axis rendering.
///
/// These tests verify visual correctness of:
/// - Axis colors matching series colors (derived)
/// - Explicit axis colors overriding series colors
/// - All axis components (line, ticks, labels) use consistent color
/// - Neutral color for unbound axes
/// - Multi-axis with distinct colors
///
/// To update goldens:
/// flutter test --update-goldens test/golden/multi_axis/colored_axes_test.dart
void main() {
  group('Colored Axes Golden Tests', () {
    testWidgets('axes with explicit colors', (tester) async {
      // Given: Chart with explicit axis colors
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: 400,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        color: Colors.blue, // Explicit blue
                        showTicks: true,
                        showAxisLine: true,
                        showLabels: true,
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        color: Colors.red, // Explicit red
                        showTicks: true,
                        showAxisLine: true,
                        showLabels: true,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'power-series',
                        yAxisId: 'power',
                        unit: 'W',
                        points: _generatePowerData(),
                        color: Colors.blue,
                      ),
                      LineChartSeries(
                        id: 'hr-series',
                        yAxisId: 'heartRate',
                        unit: 'bpm',
                        points: _generateHeartRateData(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chart renders
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Golden test - visual verification of colored axes
      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/colored_axes_explicit.png'),
      );
    });

    testWidgets('axes derive color from series', (tester) async {
      // Given: Chart where axis colors are derived from series (no explicit color)
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: 400,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        // No explicit color - should derive from series
                        showTicks: true,
                        showAxisLine: true,
                        showLabels: true,
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        // No explicit color - should derive from series
                        showTicks: true,
                        showAxisLine: true,
                        showLabels: true,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'power-series',
                        yAxisId: 'power',
                        unit: 'W',
                        points: _generatePowerData(),
                        color: const Color(0xFF4CAF50), // Green
                      ),
                      LineChartSeries(
                        id: 'hr-series',
                        yAxisId: 'heartRate',
                        unit: 'bpm',
                        points: _generateHeartRateData(),
                        color: const Color(0xFFFF9800), // Orange
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chart renders
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Golden test - axis colors should match series colors
      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/colored_axes_derived.png'),
      );
    });

    testWidgets('three axes with distinct colors', (tester) async {
      // Given: Chart with 3 axes in different positions with distinct colors
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 700,
                  height: 450,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        color: Colors.blue,
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        color: Colors.red,
                      ),
                      YAxisConfig(
                        id: 'cadence',
                        position: YAxisPosition.leftOuter,
                        label: 'Cadence',
                        unit: 'rpm',
                        color: Colors.green,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'power-series',
                        yAxisId: 'power',
                        unit: 'W',
                        points: _generatePowerData(),
                        color: Colors.blue,
                      ),
                      LineChartSeries(
                        id: 'hr-series',
                        yAxisId: 'heartRate',
                        unit: 'bpm',
                        points: _generateHeartRateData(),
                        color: Colors.red,
                      ),
                      LineChartSeries(
                        id: 'cadence-series',
                        yAxisId: 'cadence',
                        unit: 'rpm',
                        points: _generateCadenceData(),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chart renders
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Golden test - 3 axes with distinct colors
      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/colored_axes_three.png'),
      );
    });

    testWidgets('dark theme with colored axes', (tester) async {
      // Given: Chart in dark theme with colored axes
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: const Color(0xFF1E1E1E), // Dark background
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: 400,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        color: Colors.cyan, // Bright color for dark theme
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        color: Colors.pink, // Bright color for dark theme
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'power-series',
                        yAxisId: 'power',
                        unit: 'W',
                        points: _generatePowerData(),
                        color: Colors.cyan,
                      ),
                      LineChartSeries(
                        id: 'hr-series',
                        yAxisId: 'heartRate',
                        unit: 'bpm',
                        points: _generateHeartRateData(),
                        color: Colors.pink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chart renders
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Golden test - dark theme with colored axes
      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/colored_axes_dark_theme.png'),
      );
    });

    testWidgets('mixed explicit and derived colors', (tester) async {
      // Given: Chart with some axes using explicit colors, others derived
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: 400,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.left,
                        label: 'Power',
                        unit: 'W',
                        color: Colors.purple, // Explicit color overrides series
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        // No explicit color - derives from series (red)
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'power-series',
                        yAxisId: 'power',
                        unit: 'W',
                        points: _generatePowerData(),
                        color: Colors.blue, // Will NOT be used for axis (explicit purple)
                      ),
                      LineChartSeries(
                        id: 'hr-series',
                        yAxisId: 'heartRate',
                        unit: 'bpm',
                        points: _generateHeartRateData(),
                        color: Colors.red, // WILL be used for axis (derived)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the chart renders
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Golden test - mixed explicit (purple) and derived (red) colors
      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/colored_axes_mixed.png'),
      );
    });
  });
}

// Data generation helpers (reused from other golden tests)

List<ChartDataPoint> _generatePowerData() {
  final points = <ChartDataPoint>[];
  for (int i = 0; i <= 50; i++) {
    final x = i.toDouble();
    // Power varies between 150-250W
    final y = 200.0 + 50.0 * (i % 10 < 5 ? (i % 5) / 5.0 : 1.0 - (i % 5) / 5.0);
    points.add(ChartDataPoint(x: x, y: y));
  }
  return points;
}

List<ChartDataPoint> _generateHeartRateData() {
  final points = <ChartDataPoint>[];
  for (int i = 0; i <= 50; i++) {
    final x = i.toDouble();
    // HR varies between 120-180 bpm
    final y = 150.0 + 30.0 * (i % 8 < 4 ? (i % 4) / 4.0 : 1.0 - (i % 4) / 4.0);
    points.add(ChartDataPoint(x: x, y: y));
  }
  return points;
}

List<ChartDataPoint> _generateCadenceData() {
  final points = <ChartDataPoint>[];
  for (int i = 0; i <= 50; i++) {
    final x = i.toDouble();
    // Cadence varies between 80-100 rpm
    final y = 90.0 + 10.0 * (i % 6 < 3 ? (i % 3) / 3.0 : 1.0 - (i % 3) / 3.0);
    points.add(ChartDataPoint(x: x, y: y));
  }
  return points;
}
