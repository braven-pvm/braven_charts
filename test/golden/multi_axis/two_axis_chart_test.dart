// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Golden tests for 2-axis chart configurations.
///
/// These tests verify visual regression for charts with left and right Y-axes,
/// ensuring both series use full vertical height despite different data ranges.
///
/// Run: flutter test test/golden/multi_axis/two_axis_chart_test.dart
/// Update: flutter test --update-goldens test/golden/multi_axis/two_axis_chart_test.dart
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Two-Axis Chart Golden Tests', () {
    /// Test data: Power (0-300W range) for left axis
    List<ChartDataPoint> generatePowerData() {
      return List.generate(50, (i) {
        final wave = (i % 10 < 5) ? i % 10 / 5.0 : (10 - i % 10) / 5.0;
        return ChartDataPoint(x: i.toDouble(), y: 100 + 200 * wave);
      });
    }

    /// Test data: Heart Rate (60-180bpm range) for right axis
    List<ChartDataPoint> generateHRData() {
      return List.generate(50, (i) {
        final wave = (i % 10 < 5) ? i % 10 / 5.0 : (10 - i % 10) / 5.0;
        return ChartDataPoint(x: i.toDouble(), y: 80 + 100 * wave);
      });
    }

    testWidgets('two axis chart with power and heart rate', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'power',
                    name: 'Power',
                    points: generatePowerData(),
                    color: Colors.blue,
                    yAxisId: 'power-axis',
                    unit: 'W',
                  ),
                  LineChartSeries(
                    id: 'hr',
                    name: 'Heart Rate',
                    points: generateHRData(),
                    color: Colors.red,
                    yAxisId: 'hr-axis',
                    unit: 'bpm',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                    label: 'Power',
                    unit: 'W',
                    color: Colors.blue,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                    label: 'Heart Rate',
                    unit: 'bpm',
                    color: Colors.red,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_power_hr.png'),
      );
    });

    testWidgets('two axis chart with vastly different scales', (tester) async {
      // Temperature (0-100°C) vs Pressure (0-10000 Pa) - 100x difference
      final tempData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 20 + 60 * (i / 30));
      });

      final pressureData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 1000 + 8000 * (i / 30));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'temp',
                    name: 'Temperature',
                    points: tempData,
                    color: Colors.orange,
                    yAxisId: 'temp-axis',
                    unit: '°C',
                  ),
                  LineChartSeries(
                    id: 'pressure',
                    name: 'Pressure',
                    points: pressureData,
                    color: Colors.purple,
                    yAxisId: 'pressure-axis',
                    unit: 'Pa',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'temp-axis',
                    position: YAxisPosition.left,
                    label: 'Temperature',
                    unit: '°C',
                    color: Colors.orange,
                  ),
                  YAxisConfig(
                    id: 'pressure-axis',
                    position: YAxisPosition.right,
                    label: 'Pressure',
                    unit: 'Pa',
                    color: Colors.purple,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_different_scales.png'),
      );
    });

    testWidgets('two axis chart with explicit axis bounds', (tester) async {
      final speedData = List.generate(40, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 25 + 15 * (i % 8 / 8));
      });

      final cadenceData = List.generate(40, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 70 + 30 * (i % 8 / 8));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'speed',
                    name: 'Speed',
                    points: speedData,
                    color: Colors.green,
                    yAxisId: 'speed-axis',
                    unit: 'km/h',
                  ),
                  LineChartSeries(
                    id: 'cadence',
                    name: 'Cadence',
                    points: cadenceData,
                    color: Colors.amber,
                    yAxisId: 'cadence-axis',
                    unit: 'rpm',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'speed-axis',
                    position: YAxisPosition.left,
                    label: 'Speed',
                    unit: 'km/h',
                    color: Colors.green,
                    min: 0,
                    max: 50,
                  ),
                  YAxisConfig(
                    id: 'cadence-axis',
                    position: YAxisPosition.right,
                    label: 'Cadence',
                    unit: 'rpm',
                    color: Colors.amber,
                    min: 0,
                    max: 120,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_explicit_bounds.png'),
      );
    });

    testWidgets('two axis chart with area chart type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                series: [
                  AreaChartSeries(
                    id: 'power',
                    name: 'Power',
                    points: generatePowerData(),
                    color: Colors.blue,
                    yAxisId: 'power-axis',
                    unit: 'W',
                    fillOpacity: 0.3,
                  ),
                  AreaChartSeries(
                    id: 'hr',
                    name: 'Heart Rate',
                    points: generateHRData(),
                    color: Colors.red,
                    yAxisId: 'hr-axis',
                    unit: 'bpm',
                    fillOpacity: 0.3,
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                    label: 'Power',
                    unit: 'W',
                    color: Colors.blue,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                    label: 'Heart Rate',
                    unit: 'bpm',
                    color: Colors.red,
                  ),
                ],
                normalizationMode: NormalizationMode.perSeries,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_area_chart.png'),
      );
    });
  });
}
