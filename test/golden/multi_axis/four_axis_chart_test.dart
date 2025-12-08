// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Golden tests for 4-axis chart configurations.
///
/// These tests verify visual regression for charts with all four Y-axis positions:
/// leftOuter, left, right, rightOuter. Verifies all axes render without overlap.
///
/// Run: flutter test test/golden/multi_axis/four_axis_chart_test.dart
/// Update: flutter test --update-goldens test/golden/multi_axis/four_axis_chart_test.dart
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Four-Axis Chart Golden Tests', () {
    /// Test data generators for four different metrics

    /// Power: 0-400W range
    List<ChartDataPoint> generatePowerData() {
      return List.generate(40, (i) {
        final wave = (i % 8 < 4) ? i % 8 / 4.0 : (8 - i % 8) / 4.0;
        return ChartDataPoint(x: i.toDouble(), y: 150 + 250 * wave);
      });
    }

    /// Heart Rate: 60-200bpm range
    List<ChartDataPoint> generateHRData() {
      return List.generate(40, (i) {
        final wave = (i % 8 < 4) ? i % 8 / 4.0 : (8 - i % 8) / 4.0;
        return ChartDataPoint(x: i.toDouble(), y: 80 + 120 * wave);
      });
    }

    /// Cadence: 50-110rpm range
    List<ChartDataPoint> generateCadenceData() {
      return List.generate(40, (i) {
        final wave = (i % 10 < 5) ? i % 10 / 5.0 : (10 - i % 10) / 5.0;
        return ChartDataPoint(x: i.toDouble(), y: 60 + 50 * wave);
      });
    }

    /// Speed: 20-50km/h range
    List<ChartDataPoint> generateSpeedData() {
      return List.generate(40, (i) {
        final wave = (i % 12 < 6) ? i % 12 / 6.0 : (12 - i % 12) / 6.0;
        return ChartDataPoint(x: i.toDouble(), y: 25 + 25 * wave);
      });
    }

    testWidgets('four axis chart with cycling metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
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
                  LineChartSeries(
                    id: 'cadence',
                    name: 'Cadence',
                    points: generateCadenceData(),
                    color: Colors.green,
                    yAxisId: 'cadence-axis',
                    unit: 'rpm',
                  ),
                  LineChartSeries(
                    id: 'speed',
                    name: 'Speed',
                    points: generateSpeedData(),
                    color: Colors.orange,
                    yAxisId: 'speed-axis',
                    unit: 'km/h',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.leftOuter,
                    label: 'Power',
                    unit: 'W',
                    color: Colors.blue,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.left,
                    label: 'Heart Rate',
                    unit: 'bpm',
                    color: Colors.red,
                  ),
                  YAxisConfig(
                    id: 'cadence-axis',
                    position: YAxisPosition.right,
                    label: 'Cadence',
                    unit: 'rpm',
                    color: Colors.green,
                  ),
                  YAxisConfig(
                    id: 'speed-axis',
                    position: YAxisPosition.rightOuter,
                    label: 'Speed',
                    unit: 'km/h',
                    color: Colors.orange,
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
        matchesGoldenFile('goldens/four_axis_cycling.png'),
      );
    });

    testWidgets('four axis chart with industrial sensors', (tester) async {
      // Simulates industrial monitoring with 4 different sensor types
      final tempData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 50 + 50 * (i / 30));
      });

      final pressureData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 2000 + 6000 * (i / 30));
      });

      final flowData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 10 + 15 * ((i % 10) / 10.0));
      });

      final levelData = List.generate(30, (i) {
        return ChartDataPoint(x: i.toDouble(), y: 30 + 60 * (1 - i / 30));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: BravenChartPlus(
                series: [
                  LineChartSeries(
                    id: 'temp',
                    name: 'Temperature',
                    points: tempData,
                    color: Colors.deepOrange,
                    yAxisId: 'temp-axis',
                    unit: '°C',
                  ),
                  LineChartSeries(
                    id: 'pressure',
                    name: 'Pressure',
                    points: pressureData,
                    color: Colors.indigo,
                    yAxisId: 'pressure-axis',
                    unit: 'Pa',
                  ),
                  LineChartSeries(
                    id: 'flow',
                    name: 'Flow Rate',
                    points: flowData,
                    color: Colors.teal,
                    yAxisId: 'flow-axis',
                    unit: 'L/s',
                  ),
                  LineChartSeries(
                    id: 'level',
                    name: 'Tank Level',
                    points: levelData,
                    color: Colors.cyan,
                    yAxisId: 'level-axis',
                    unit: '%',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'temp-axis',
                    position: YAxisPosition.leftOuter,
                    label: 'Temperature',
                    unit: '°C',
                    color: Colors.deepOrange,
                  ),
                  YAxisConfig(
                    id: 'pressure-axis',
                    position: YAxisPosition.left,
                    label: 'Pressure',
                    unit: 'Pa',
                    color: Colors.indigo,
                  ),
                  YAxisConfig(
                    id: 'flow-axis',
                    position: YAxisPosition.right,
                    label: 'Flow Rate',
                    unit: 'L/s',
                    color: Colors.teal,
                  ),
                  YAxisConfig(
                    id: 'level-axis',
                    position: YAxisPosition.rightOuter,
                    label: 'Tank Level',
                    unit: '%',
                    color: Colors.cyan,
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
        matchesGoldenFile('goldens/four_axis_industrial.png'),
      );
    });

    testWidgets('four axis chart with mixed visibility options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
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
                  LineChartSeries(
                    id: 'cadence',
                    name: 'Cadence',
                    points: generateCadenceData(),
                    color: Colors.green,
                    yAxisId: 'cadence-axis',
                    unit: 'rpm',
                  ),
                  LineChartSeries(
                    id: 'speed',
                    name: 'Speed',
                    points: generateSpeedData(),
                    color: Colors.orange,
                    yAxisId: 'speed-axis',
                    unit: 'km/h',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.leftOuter,
                    label: 'Power',
                    unit: 'W',
                    color: Colors.blue,
                    showAxisLine: true,
                    showTicks: true,
                    labelDisplay: AxisLabelDisplay.labelWithUnit,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.left,
                    label: 'Heart Rate',
                    unit: 'bpm',
                    color: Colors.red,
                    showAxisLine: false, // Hidden axis line
                    showTicks: true,
                    labelDisplay: AxisLabelDisplay.labelWithUnit,
                  ),
                  YAxisConfig(
                    id: 'cadence-axis',
                    position: YAxisPosition.right,
                    label: 'Cadence',
                    unit: 'rpm',
                    color: Colors.green,
                    showAxisLine: true,
                    showTicks: false, // Hidden ticks
                    labelDisplay: AxisLabelDisplay.labelWithUnit,
                  ),
                  YAxisConfig(
                    id: 'speed-axis',
                    position: YAxisPosition.rightOuter,
                    label: 'Speed',
                    unit: 'km/h',
                    color: Colors.orange,
                    showAxisLine: true,
                    showTicks: true,
                    labelDisplay: AxisLabelDisplay.labelWithUnit,
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
        matchesGoldenFile('goldens/four_axis_mixed_visibility.png'),
      );
    });

    testWidgets('four axis chart at smaller width', (tester) async {
      // Test that four axes fit gracefully in a narrower chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              height: 500,
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
                  LineChartSeries(
                    id: 'cadence',
                    name: 'Cadence',
                    points: generateCadenceData(),
                    color: Colors.green,
                    yAxisId: 'cadence-axis',
                    unit: 'rpm',
                  ),
                  LineChartSeries(
                    id: 'speed',
                    name: 'Speed',
                    points: generateSpeedData(),
                    color: Colors.orange,
                    yAxisId: 'speed-axis',
                    unit: 'km/h',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.leftOuter,
                    label: 'Power',
                    unit: 'W',
                    color: Colors.blue,
                    minWidth: 35,
                    maxWidth: 55,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.left,
                    label: 'HR',
                    unit: 'bpm',
                    color: Colors.red,
                    minWidth: 35,
                    maxWidth: 55,
                  ),
                  YAxisConfig(
                    id: 'cadence-axis',
                    position: YAxisPosition.right,
                    label: 'Cad',
                    unit: 'rpm',
                    color: Colors.green,
                    minWidth: 35,
                    maxWidth: 55,
                  ),
                  YAxisConfig(
                    id: 'speed-axis',
                    position: YAxisPosition.rightOuter,
                    label: 'Speed',
                    unit: 'km/h',
                    color: Colors.orange,
                    minWidth: 35,
                    maxWidth: 55,
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
        matchesGoldenFile('goldens/four_axis_narrow.png'),
      );
    });
  });
}
