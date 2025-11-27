// Copyright (c) 2025 braven_charts. All rights reserved.
// Golden tests for 4-axis chart rendering (US1: Multi-Scale Data Visualization)

import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:braven_charts/src_plus/models/chart_type.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/widgets/braven_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for 4-axis chart rendering.
///
/// These tests verify visual correctness of:
/// - All four Y-axis positions (leftOuter, left, right, rightOuter)
/// - Maximum axis configuration (4 axes)
/// - Complex multi-series visualization with 4 different ranges
/// - Color coordination across 4 axes/series pairs
///
/// To update goldens: flutter test --update-goldens test/golden/multi_axis/four_axis_chart_test.dart
void main() {
  group('Four-Axis Chart Golden Tests', () {
    testWidgets('all four axis positions', (tester) async {
      // Core 4-axis test: cycling data with power, heart rate, cadence, and speed
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 500,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'power',
                        position: YAxisPosition.leftOuter,
                        label: 'Power',
                        unit: 'W',
                        color: Colors.blue,
                      ),
                      YAxisConfig(
                        id: 'heartRate',
                        position: YAxisPosition.left,
                        label: 'HR',
                        unit: 'bpm',
                        color: Colors.red,
                      ),
                      YAxisConfig(
                        id: 'cadence',
                        position: YAxisPosition.right,
                        label: 'Cadence',
                        unit: 'rpm',
                        color: Colors.green,
                      ),
                      YAxisConfig(
                        id: 'speed',
                        position: YAxisPosition.rightOuter,
                        label: 'Speed',
                        unit: 'km/h',
                        color: Colors.orange,
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
                      LineChartSeries(
                        id: 'speed-series',
                        yAxisId: 'speed',
                        unit: 'km/h',
                        points: _generateSpeedData(),
                        color: Colors.orange,
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
        matchesGoldenFile('goldens/four_axis_all_positions.png'),
      );
    });

    testWidgets('scientific data with 4 vastly different ranges', (tester) async {
      // Scientific use case: temperature, pressure, humidity, light intensity
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 500,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'temp',
                        position: YAxisPosition.leftOuter,
                        label: 'Temp',
                        unit: '°C',
                        color: Colors.deepOrange,
                      ),
                      YAxisConfig(
                        id: 'pressure',
                        position: YAxisPosition.left,
                        label: 'Pressure',
                        unit: 'hPa',
                        color: Colors.indigo,
                      ),
                      YAxisConfig(
                        id: 'humidity',
                        position: YAxisPosition.right,
                        label: 'Humidity',
                        unit: '%',
                        color: Colors.teal,
                      ),
                      YAxisConfig(
                        id: 'light',
                        position: YAxisPosition.rightOuter,
                        label: 'Light',
                        unit: 'lux',
                        color: Colors.amber,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      // Temperature: 15-35°C (small range)
                      LineChartSeries(
                        id: 'temp-series',
                        yAxisId: 'temp',
                        unit: '°C',
                        points: _generateTempData(),
                        color: Colors.deepOrange,
                      ),
                      // Pressure: 980-1030 hPa (medium range)
                      LineChartSeries(
                        id: 'pressure-series',
                        yAxisId: 'pressure',
                        unit: 'hPa',
                        points: _generatePressureData(),
                        color: Colors.indigo,
                      ),
                      // Humidity: 30-90% (medium range)
                      LineChartSeries(
                        id: 'humidity-series',
                        yAxisId: 'humidity',
                        unit: '%',
                        points: _generateHumidityData(),
                        color: Colors.teal,
                      ),
                      // Light: 0-100000 lux (very large range)
                      LineChartSeries(
                        id: 'light-series',
                        yAxisId: 'light',
                        unit: 'lux',
                        points: _generateLightData(),
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
        matchesGoldenFile('goldens/four_axis_scientific.png'),
      );
    });

    testWidgets('financial data with 4 metrics', (tester) async {
      // Financial use case: price, volume, RSI, MACD
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 500,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'price',
                        position: YAxisPosition.leftOuter,
                        label: 'Price',
                        unit: '\$',
                        color: Colors.blue,
                      ),
                      YAxisConfig(
                        id: 'volume',
                        position: YAxisPosition.left,
                        label: 'Volume',
                        unit: 'M',
                        color: Colors.grey,
                      ),
                      YAxisConfig(
                        id: 'rsi',
                        position: YAxisPosition.right,
                        label: 'RSI',
                        unit: '',
                        color: Colors.purple,
                      ),
                      YAxisConfig(
                        id: 'macd',
                        position: YAxisPosition.rightOuter,
                        label: 'MACD',
                        unit: '',
                        color: Colors.cyan,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      // Price: 100-200
                      LineChartSeries(
                        id: 'price-series',
                        yAxisId: 'price',
                        unit: '\$',
                        points: _generatePriceData(),
                        color: Colors.blue,
                      ),
                      // Volume: 1M-50M
                      LineChartSeries(
                        id: 'volume-series',
                        yAxisId: 'volume',
                        unit: 'M',
                        points: _generateVolumeData(),
                        color: Colors.grey,
                      ),
                      // RSI: 0-100
                      LineChartSeries(
                        id: 'rsi-series',
                        yAxisId: 'rsi',
                        points: _generateRsiData(),
                        color: Colors.purple,
                      ),
                      // MACD: -5 to +5
                      LineChartSeries(
                        id: 'macd-series',
                        yAxisId: 'macd',
                        points: _generateMacdData(),
                        color: Colors.cyan,
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
        matchesGoldenFile('goldens/four_axis_financial.png'),
      );
    });

    testWidgets('IoT sensor dashboard with 4 sensors', (tester) async {
      // IoT use case: 4 different sensors
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 500,
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    showLegend: false,
                    yAxes: const [
                      YAxisConfig(
                        id: 'voltage',
                        position: YAxisPosition.leftOuter,
                        label: 'Voltage',
                        unit: 'V',
                        color: Colors.purple,
                      ),
                      YAxisConfig(
                        id: 'current',
                        position: YAxisPosition.left,
                        label: 'Current',
                        unit: 'A',
                        color: Colors.lime,
                      ),
                      YAxisConfig(
                        id: 'vibration',
                        position: YAxisPosition.right,
                        label: 'Vibration',
                        unit: 'mm/s',
                        color: Colors.pink,
                      ),
                      YAxisConfig(
                        id: 'rpm',
                        position: YAxisPosition.rightOuter,
                        label: 'RPM',
                        unit: '',
                        color: Colors.brown,
                      ),
                    ],
                    normalizationMode: NormalizationMode.perSeries,
                    series: [
                      // Voltage: 3.0-4.2V
                      LineChartSeries(
                        id: 'voltage-series',
                        yAxisId: 'voltage',
                        unit: 'V',
                        points: _generateVoltageData(),
                        color: Colors.purple,
                      ),
                      // Current: 0-10A
                      LineChartSeries(
                        id: 'current-series',
                        yAxisId: 'current',
                        unit: 'A',
                        points: _generateCurrentData(),
                        color: Colors.lime,
                      ),
                      // Vibration: 0-50 mm/s
                      LineChartSeries(
                        id: 'vibration-series',
                        yAxisId: 'vibration',
                        unit: 'mm/s',
                        points: _generateVibrationData(),
                        color: Colors.pink,
                      ),
                      // RPM: 0-3000
                      LineChartSeries(
                        id: 'rpm-series',
                        yAxisId: 'rpm',
                        points: _generateRpmData(),
                        color: Colors.brown,
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
        matchesGoldenFile('goldens/four_axis_iot.png'),
      );
    });
  });
}

// =============================================================================
// Sample Data Generators - Cycling
// =============================================================================

/// Power data: 100-350W cycling power
List<ChartDataPoint> _generatePowerData() {
  return const [
    ChartDataPoint(x: 0, y: 150),
    ChartDataPoint(x: 5, y: 180),
    ChartDataPoint(x: 10, y: 220),
    ChartDataPoint(x: 15, y: 280),
    ChartDataPoint(x: 20, y: 320),
    ChartDataPoint(x: 25, y: 280),
    ChartDataPoint(x: 30, y: 220),
    ChartDataPoint(x: 35, y: 180),
    ChartDataPoint(x: 40, y: 200),
    ChartDataPoint(x: 45, y: 260),
    ChartDataPoint(x: 50, y: 300),
    ChartDataPoint(x: 55, y: 350),
    ChartDataPoint(x: 60, y: 280),
  ];
}

/// Heart rate data: 120-180 bpm
List<ChartDataPoint> _generateHeartRateData() {
  return const [
    ChartDataPoint(x: 0, y: 125),
    ChartDataPoint(x: 5, y: 130),
    ChartDataPoint(x: 10, y: 140),
    ChartDataPoint(x: 15, y: 155),
    ChartDataPoint(x: 20, y: 168),
    ChartDataPoint(x: 25, y: 160),
    ChartDataPoint(x: 30, y: 148),
    ChartDataPoint(x: 35, y: 138),
    ChartDataPoint(x: 40, y: 145),
    ChartDataPoint(x: 45, y: 158),
    ChartDataPoint(x: 50, y: 170),
    ChartDataPoint(x: 55, y: 178),
    ChartDataPoint(x: 60, y: 165),
  ];
}

/// Cadence data: 70-100 rpm
List<ChartDataPoint> _generateCadenceData() {
  return const [
    ChartDataPoint(x: 0, y: 75),
    ChartDataPoint(x: 5, y: 78),
    ChartDataPoint(x: 10, y: 82),
    ChartDataPoint(x: 15, y: 88),
    ChartDataPoint(x: 20, y: 92),
    ChartDataPoint(x: 25, y: 88),
    ChartDataPoint(x: 30, y: 82),
    ChartDataPoint(x: 35, y: 78),
    ChartDataPoint(x: 40, y: 80),
    ChartDataPoint(x: 45, y: 86),
    ChartDataPoint(x: 50, y: 94),
    ChartDataPoint(x: 55, y: 98),
    ChartDataPoint(x: 60, y: 90),
  ];
}

/// Speed data: 20-45 km/h
List<ChartDataPoint> _generateSpeedData() {
  return const [
    ChartDataPoint(x: 0, y: 22),
    ChartDataPoint(x: 5, y: 26),
    ChartDataPoint(x: 10, y: 32),
    ChartDataPoint(x: 15, y: 38),
    ChartDataPoint(x: 20, y: 42),
    ChartDataPoint(x: 25, y: 38),
    ChartDataPoint(x: 30, y: 32),
    ChartDataPoint(x: 35, y: 28),
    ChartDataPoint(x: 40, y: 30),
    ChartDataPoint(x: 45, y: 36),
    ChartDataPoint(x: 50, y: 40),
    ChartDataPoint(x: 55, y: 44),
    ChartDataPoint(x: 60, y: 38),
  ];
}

// =============================================================================
// Sample Data Generators - Scientific
// =============================================================================

/// Temperature data: 15-35°C
List<ChartDataPoint> _generateTempData() {
  return const [
    ChartDataPoint(x: 0, y: 18),
    ChartDataPoint(x: 4, y: 16),
    ChartDataPoint(x: 8, y: 17),
    ChartDataPoint(x: 12, y: 22),
    ChartDataPoint(x: 16, y: 28),
    ChartDataPoint(x: 20, y: 32),
    ChartDataPoint(x: 24, y: 28),
  ];
}

/// Pressure data: 980-1030 hPa
List<ChartDataPoint> _generatePressureData() {
  return const [
    ChartDataPoint(x: 0, y: 1013),
    ChartDataPoint(x: 4, y: 1008),
    ChartDataPoint(x: 8, y: 1000),
    ChartDataPoint(x: 12, y: 995),
    ChartDataPoint(x: 16, y: 988),
    ChartDataPoint(x: 20, y: 985),
    ChartDataPoint(x: 24, y: 992),
  ];
}

/// Humidity data: 30-90%
List<ChartDataPoint> _generateHumidityData() {
  return const [
    ChartDataPoint(x: 0, y: 72),
    ChartDataPoint(x: 4, y: 85),
    ChartDataPoint(x: 8, y: 78),
    ChartDataPoint(x: 12, y: 55),
    ChartDataPoint(x: 16, y: 42),
    ChartDataPoint(x: 20, y: 38),
    ChartDataPoint(x: 24, y: 58),
  ];
}

/// Light data: 0-100000 lux
List<ChartDataPoint> _generateLightData() {
  return const [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 4, y: 100),
    ChartDataPoint(x: 8, y: 10000),
    ChartDataPoint(x: 12, y: 80000),
    ChartDataPoint(x: 16, y: 95000),
    ChartDataPoint(x: 20, y: 50000),
    ChartDataPoint(x: 24, y: 5000),
  ];
}

// =============================================================================
// Sample Data Generators - Financial
// =============================================================================

/// Price data: 100-200
List<ChartDataPoint> _generatePriceData() {
  return const [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 5, y: 125),
    ChartDataPoint(x: 10, y: 130),
    ChartDataPoint(x: 15, y: 145),
    ChartDataPoint(x: 20, y: 155),
    ChartDataPoint(x: 25, y: 148),
    ChartDataPoint(x: 30, y: 162),
    ChartDataPoint(x: 35, y: 175),
    ChartDataPoint(x: 40, y: 168),
    ChartDataPoint(x: 45, y: 180),
    ChartDataPoint(x: 50, y: 195),
  ];
}

/// Volume data: 1M-50M
List<ChartDataPoint> _generateVolumeData() {
  return const [
    ChartDataPoint(x: 0, y: 15),
    ChartDataPoint(x: 5, y: 12),
    ChartDataPoint(x: 10, y: 18),
    ChartDataPoint(x: 15, y: 35),
    ChartDataPoint(x: 20, y: 42),
    ChartDataPoint(x: 25, y: 28),
    ChartDataPoint(x: 30, y: 22),
    ChartDataPoint(x: 35, y: 38),
    ChartDataPoint(x: 40, y: 25),
    ChartDataPoint(x: 45, y: 32),
    ChartDataPoint(x: 50, y: 45),
  ];
}

/// RSI data: 0-100
List<ChartDataPoint> _generateRsiData() {
  return const [
    ChartDataPoint(x: 0, y: 45),
    ChartDataPoint(x: 5, y: 52),
    ChartDataPoint(x: 10, y: 58),
    ChartDataPoint(x: 15, y: 68),
    ChartDataPoint(x: 20, y: 72),
    ChartDataPoint(x: 25, y: 65),
    ChartDataPoint(x: 30, y: 70),
    ChartDataPoint(x: 35, y: 75),
    ChartDataPoint(x: 40, y: 68),
    ChartDataPoint(x: 45, y: 72),
    ChartDataPoint(x: 50, y: 78),
  ];
}

/// MACD data: -5 to +5
List<ChartDataPoint> _generateMacdData() {
  return const [
    ChartDataPoint(x: 0, y: -1.2),
    ChartDataPoint(x: 5, y: 0.5),
    ChartDataPoint(x: 10, y: 1.8),
    ChartDataPoint(x: 15, y: 2.5),
    ChartDataPoint(x: 20, y: 1.2),
    ChartDataPoint(x: 25, y: -0.5),
    ChartDataPoint(x: 30, y: 1.5),
    ChartDataPoint(x: 35, y: 3.2),
    ChartDataPoint(x: 40, y: 2.0),
    ChartDataPoint(x: 45, y: 2.8),
    ChartDataPoint(x: 50, y: 4.0),
  ];
}

// =============================================================================
// Sample Data Generators - IoT
// =============================================================================

/// Voltage data: 3.0-4.2V
List<ChartDataPoint> _generateVoltageData() {
  return const [
    ChartDataPoint(x: 0, y: 4.2),
    ChartDataPoint(x: 10, y: 4.1),
    ChartDataPoint(x: 20, y: 3.95),
    ChartDataPoint(x: 30, y: 3.8),
    ChartDataPoint(x: 40, y: 3.65),
    ChartDataPoint(x: 50, y: 3.5),
    ChartDataPoint(x: 60, y: 3.35),
    ChartDataPoint(x: 70, y: 3.2),
    ChartDataPoint(x: 80, y: 3.1),
    ChartDataPoint(x: 90, y: 3.05),
    ChartDataPoint(x: 100, y: 3.0),
  ];
}

/// Current data: 0-10A
List<ChartDataPoint> _generateCurrentData() {
  return const [
    ChartDataPoint(x: 0, y: 0.5),
    ChartDataPoint(x: 10, y: 2.0),
    ChartDataPoint(x: 20, y: 4.5),
    ChartDataPoint(x: 30, y: 6.8),
    ChartDataPoint(x: 40, y: 8.2),
    ChartDataPoint(x: 50, y: 7.5),
    ChartDataPoint(x: 60, y: 5.8),
    ChartDataPoint(x: 70, y: 4.0),
    ChartDataPoint(x: 80, y: 2.5),
    ChartDataPoint(x: 90, y: 1.2),
    ChartDataPoint(x: 100, y: 0.8),
  ];
}

/// Vibration data: 0-50 mm/s
List<ChartDataPoint> _generateVibrationData() {
  return const [
    ChartDataPoint(x: 0, y: 2),
    ChartDataPoint(x: 10, y: 5),
    ChartDataPoint(x: 20, y: 12),
    ChartDataPoint(x: 30, y: 28),
    ChartDataPoint(x: 40, y: 42),
    ChartDataPoint(x: 50, y: 38),
    ChartDataPoint(x: 60, y: 25),
    ChartDataPoint(x: 70, y: 15),
    ChartDataPoint(x: 80, y: 8),
    ChartDataPoint(x: 90, y: 4),
    ChartDataPoint(x: 100, y: 3),
  ];
}

/// RPM data: 0-3000
List<ChartDataPoint> _generateRpmData() {
  return const [
    ChartDataPoint(x: 0, y: 200),
    ChartDataPoint(x: 10, y: 600),
    ChartDataPoint(x: 20, y: 1200),
    ChartDataPoint(x: 30, y: 2000),
    ChartDataPoint(x: 40, y: 2600),
    ChartDataPoint(x: 50, y: 2800),
    ChartDataPoint(x: 60, y: 2400),
    ChartDataPoint(x: 70, y: 1800),
    ChartDataPoint(x: 80, y: 1000),
    ChartDataPoint(x: 90, y: 500),
    ChartDataPoint(x: 100, y: 250),
  ];
}
