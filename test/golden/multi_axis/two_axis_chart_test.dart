// Copyright (c) 2025 braven_charts. All rights reserved.
// Golden tests for 2-axis chart rendering (US1: Multi-Scale Data Visualization)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';

/// Golden tests for 2-axis chart rendering.
///
/// These tests verify visual correctness of:
/// - Left/right Y-axis positioning
/// - Color-coded axis labels matching series
/// - Proper axis label rendering with units
/// - Grid suppression in multi-axis mode (FR-009)
///
/// To update goldens: flutter test --update-goldens test/golden/multi_axis/two_axis_chart_test.dart
void main() {
  group('Two-Axis Chart Golden Tests', () {
    testWidgets('left-right axis layout', (tester) async {
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
                        color: Colors.blue,
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.right,
                        label: 'Heart Rate',
                        unit: 'bpm',
                        color: Colors.red,
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

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_left_right.png'),
      );
    });

    testWidgets('dual left axes layout', (tester) async {
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
                        id: 'temp',
                        position: YAxisPosition.leftOuter,
                        label: 'Temperature',
                        unit: '°C',
                        color: Colors.orange,
                      ),
                      YAxisConfig(
                        id: 'humidity',
                        position: YAxisPosition.left,
                        label: 'Humidity',
                        unit: '%',
                        color: Colors.teal,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'temp-series',
                        yAxisId: 'temp',
                        unit: '°C',
                        points: _generateTempData(),
                        color: Colors.orange,
                      ),
                      LineChartSeries(
                        id: 'humidity-series',
                        yAxisId: 'humidity',
                        unit: '%',
                        points: _generateHumidityData(),
                        color: Colors.teal,
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

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_dual_left.png'),
      );
    });

    testWidgets('dual right axes layout', (tester) async {
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
                        id: 'voltage',
                        position: YAxisPosition.right,
                        label: 'Voltage',
                        unit: 'V',
                        color: Colors.purple,
                      ),
                      YAxisConfig(
                        id: 'current',
                        position: YAxisPosition.rightOuter,
                        label: 'Current',
                        unit: 'A',
                        color: Colors.green,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'voltage-series',
                        yAxisId: 'voltage',
                        unit: 'V',
                        points: _generateVoltageData(),
                        color: Colors.purple,
                      ),
                      LineChartSeries(
                        id: 'current-series',
                        yAxisId: 'current',
                        unit: 'A',
                        points: _generateCurrentData(),
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

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_dual_right.png'),
      );
    });

    testWidgets('vastly different ranges normalized', (tester) async {
      // Core multi-axis use case: series with 100,000x range difference
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
                        id: 'small',
                        position: YAxisPosition.left,
                        label: 'Small Values',
                        unit: '',
                        color: Colors.blue,
                      ),
                      YAxisConfig(
                        id: 'large',
                        position: YAxisPosition.right,
                        label: 'Large Values',
                        unit: '',
                        color: Colors.red,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      // Small range: 0-10
                      LineChartSeries(
                        id: 'small-series',
                        yAxisId: 'small',
                        points: _generateSmallRangeData(),
                        color: Colors.blue,
                      ),
                      // Large range: 0-1,000,000
                      LineChartSeries(
                        id: 'large-series',
                        yAxisId: 'large',
                        points: _generateLargeRangeData(),
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

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_normalized_ranges.png'),
      );
    });

    testWidgets('color-coded axis labels', (tester) async {
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
                        id: 'speed',
                        position: YAxisPosition.left,
                        label: 'Speed',
                        unit: 'km/h',
                        color: Colors.indigo,
                      ),
                      YAxisConfig(
                        id: 'cadence',
                        position: YAxisPosition.right,
                        label: 'Cadence',
                        unit: 'rpm',
                        color: Colors.amber,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      LineChartSeries(
                        id: 'speed-series',
                        yAxisId: 'speed',
                        unit: 'km/h',
                        points: _generateSpeedData(),
                        color: Colors.indigo,
                      ),
                      LineChartSeries(
                        id: 'cadence-series',
                        yAxisId: 'cadence',
                        unit: 'rpm',
                        points: _generateCadenceData(),
                        color: Colors.amber,
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

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_color_coded.png'),
      );
    });
  });
}

// =============================================================================
// Sample Data Generators
// =============================================================================

/// Power data: 100-350W cycling power
List<ChartDataPoint> _generatePowerData() {
  return const [
    ChartDataPoint(x: 0, y: 150),
    ChartDataPoint(x: 10, y: 200),
    ChartDataPoint(x: 20, y: 280),
    ChartDataPoint(x: 30, y: 320),
    ChartDataPoint(x: 40, y: 250),
    ChartDataPoint(x: 50, y: 180),
    ChartDataPoint(x: 60, y: 220),
    ChartDataPoint(x: 70, y: 300),
    ChartDataPoint(x: 80, y: 350),
    ChartDataPoint(x: 90, y: 280),
    ChartDataPoint(x: 100, y: 200),
  ];
}

/// Heart rate data: 120-180 bpm
List<ChartDataPoint> _generateHeartRateData() {
  return const [
    ChartDataPoint(x: 0, y: 125),
    ChartDataPoint(x: 10, y: 135),
    ChartDataPoint(x: 20, y: 150),
    ChartDataPoint(x: 30, y: 165),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 140),
    ChartDataPoint(x: 60, y: 148),
    ChartDataPoint(x: 70, y: 168),
    ChartDataPoint(x: 80, y: 178),
    ChartDataPoint(x: 90, y: 165),
    ChartDataPoint(x: 100, y: 145),
  ];
}

/// Temperature data: 15-35°C
List<ChartDataPoint> _generateTempData() {
  return const [
    ChartDataPoint(x: 0, y: 18),
    ChartDataPoint(x: 6, y: 16),
    ChartDataPoint(x: 12, y: 22),
    ChartDataPoint(x: 18, y: 32),
    ChartDataPoint(x: 24, y: 28),
  ];
}

/// Humidity data: 40-80%
List<ChartDataPoint> _generateHumidityData() {
  return const [
    ChartDataPoint(x: 0, y: 65),
    ChartDataPoint(x: 6, y: 78),
    ChartDataPoint(x: 12, y: 55),
    ChartDataPoint(x: 18, y: 42),
    ChartDataPoint(x: 24, y: 58),
  ];
}

/// Voltage data: 3.0-4.2V
List<ChartDataPoint> _generateVoltageData() {
  return const [
    ChartDataPoint(x: 0, y: 4.2),
    ChartDataPoint(x: 20, y: 4.0),
    ChartDataPoint(x: 40, y: 3.8),
    ChartDataPoint(x: 60, y: 3.5),
    ChartDataPoint(x: 80, y: 3.2),
    ChartDataPoint(x: 100, y: 3.0),
  ];
}

/// Current data: 0-2.5A
List<ChartDataPoint> _generateCurrentData() {
  return const [
    ChartDataPoint(x: 0, y: 0.5),
    ChartDataPoint(x: 20, y: 1.2),
    ChartDataPoint(x: 40, y: 2.0),
    ChartDataPoint(x: 60, y: 2.3),
    ChartDataPoint(x: 80, y: 1.8),
    ChartDataPoint(x: 100, y: 0.8),
  ];
}

/// Small range data: 0-10
List<ChartDataPoint> _generateSmallRangeData() {
  return const [
    ChartDataPoint(x: 0, y: 1),
    ChartDataPoint(x: 20, y: 4),
    ChartDataPoint(x: 40, y: 8),
    ChartDataPoint(x: 60, y: 6),
    ChartDataPoint(x: 80, y: 9),
    ChartDataPoint(x: 100, y: 5),
  ];
}

/// Large range data: 0-1,000,000
List<ChartDataPoint> _generateLargeRangeData() {
  return const [
    ChartDataPoint(x: 0, y: 100000),
    ChartDataPoint(x: 20, y: 400000),
    ChartDataPoint(x: 40, y: 800000),
    ChartDataPoint(x: 60, y: 600000),
    ChartDataPoint(x: 80, y: 900000),
    ChartDataPoint(x: 100, y: 500000),
  ];
}

/// Speed data: 15-45 km/h
List<ChartDataPoint> _generateSpeedData() {
  return const [
    ChartDataPoint(x: 0, y: 20),
    ChartDataPoint(x: 10, y: 28),
    ChartDataPoint(x: 20, y: 35),
    ChartDataPoint(x: 30, y: 42),
    ChartDataPoint(x: 40, y: 38),
    ChartDataPoint(x: 50, y: 30),
  ];
}

/// Cadence data: 70-100 rpm
List<ChartDataPoint> _generateCadenceData() {
  return const [
    ChartDataPoint(x: 0, y: 75),
    ChartDataPoint(x: 10, y: 82),
    ChartDataPoint(x: 20, y: 88),
    ChartDataPoint(x: 30, y: 95),
    ChartDataPoint(x: 40, y: 90),
    ChartDataPoint(x: 50, y: 80),
  ];
}
