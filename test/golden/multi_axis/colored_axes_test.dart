// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Golden tests for color-coded axis configurations.
///
/// These tests verify that axis colors correctly match their bound series,
/// testing both explicit color assignment and color inheritance from series.
///
/// Run: flutter test test/golden/multi_axis/colored_axes_test.dart
/// Update: flutter test --update-goldens test/golden/multi_axis/colored_axes_test.dart
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Colored Axes Golden Tests', () {
    /// Generate sample data with a sine-like wave pattern
    List<ChartDataPoint> generateWaveData(int count, double amplitude, double offset) {
      return List.generate(count, (i) {
        final phase = i / count * 4 * 3.14159;
        return ChartDataPoint(
          x: i.toDouble(),
          y: offset + amplitude * (0.5 + 0.5 * (phase - phase.truncate()).abs()),
        );
      });
    }

    testWidgets('explicit axis colors match series', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'voltage',
                    name: 'Voltage',
                    points: generateWaveData(50, 100, 200),
                    color: Colors.deepPurple,
                    yAxisId: 'voltage-axis',
                    unit: 'V',
                  ),
                  LineChartSeries(
                    id: 'current',
                    name: 'Current',
                    points: generateWaveData(50, 5, 10),
                    color: Colors.amber,
                    yAxisId: 'current-axis',
                    unit: 'A',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'voltage-axis',
                    position: YAxisPosition.left,
                    label: 'Voltage',
                    unit: 'V',
                    color: Colors.deepPurple, // Explicit color matching series
                  ),
                  YAxisConfig(
                    id: 'current-axis',
                    position: YAxisPosition.right,
                    label: 'Current',
                    unit: 'A',
                    color: Colors.amber, // Explicit color matching series
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
        matchesGoldenFile('goldens/colored_axes_explicit.png'),
      );
    });

    testWidgets('vibrant color palette for visual distinction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'metric1',
                    name: 'Revenue',
                    points: generateWaveData(40, 50000, 100000),
                    color: const Color(0xFF1E88E5), // Blue
                    yAxisId: 'axis1',
                    unit: '\$',
                  ),
                  LineChartSeries(
                    id: 'metric2',
                    name: 'Users',
                    points: generateWaveData(40, 500, 1000),
                    color: const Color(0xFFD81B60), // Pink
                    yAxisId: 'axis2',
                    unit: 'K',
                  ),
                  LineChartSeries(
                    id: 'metric3',
                    name: 'Sessions',
                    points: generateWaveData(40, 2000, 5000),
                    color: const Color(0xFF43A047), // Green
                    yAxisId: 'axis3',
                    unit: '',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'axis1',
                    position: YAxisPosition.left,
                    label: 'Revenue',
                    unit: '\$',
                    color: const Color(0xFF1E88E5),
                  ),
                  YAxisConfig(
                    id: 'axis2',
                    position: YAxisPosition.right,
                    label: 'Users',
                    unit: 'K',
                    color: const Color(0xFFD81B60),
                  ),
                  YAxisConfig(
                    id: 'axis3',
                    position: YAxisPosition.rightOuter,
                    label: 'Sessions',
                    color: const Color(0xFF43A047),
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
        matchesGoldenFile('goldens/colored_axes_vibrant.png'),
      );
    });

    testWidgets('colorblind-friendly palette', (tester) async {
      // Using Okabe-Ito colorblind-safe colors
      const okabeBlue = Color(0xFF0072B2);
      const okabeOrange = Color(0xFFE69F00);
      const okabeGreen = Color(0xFF009E73);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'sales',
                    name: 'Sales',
                    points: generateWaveData(30, 800, 2000),
                    color: okabeBlue,
                    yAxisId: 'sales-axis',
                    unit: 'units',
                  ),
                  LineChartSeries(
                    id: 'profit',
                    name: 'Profit',
                    points: generateWaveData(30, 200, 500),
                    color: okabeOrange,
                    yAxisId: 'profit-axis',
                    unit: '\$K',
                  ),
                  LineChartSeries(
                    id: 'margin',
                    name: 'Margin',
                    points: generateWaveData(30, 15, 25),
                    color: okabeGreen,
                    yAxisId: 'margin-axis',
                    unit: '%',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'sales-axis',
                    position: YAxisPosition.left,
                    label: 'Sales',
                    unit: 'units',
                    color: okabeBlue,
                  ),
                  YAxisConfig(
                    id: 'profit-axis',
                    position: YAxisPosition.right,
                    label: 'Profit',
                    unit: '\$K',
                    color: okabeOrange,
                  ),
                  YAxisConfig(
                    id: 'margin-axis',
                    position: YAxisPosition.rightOuter,
                    label: 'Margin',
                    unit: '%',
                    color: okabeGreen,
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
        matchesGoldenFile('goldens/colored_axes_colorblind.png'),
      );
    });

    testWidgets('dark theme with colored axes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF1E1E1E),
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                backgroundColor: const Color(0xFF1E1E1E),
                series: [
                  LineChartSeries(
                    id: 'cpu',
                    name: 'CPU Usage',
                    points: generateWaveData(60, 40, 50),
                    color: Colors.lightBlueAccent,
                    yAxisId: 'cpu-axis',
                    unit: '%',
                  ),
                  LineChartSeries(
                    id: 'memory',
                    name: 'Memory Usage',
                    points: generateWaveData(60, 20, 60),
                    color: Colors.pinkAccent,
                    yAxisId: 'memory-axis',
                    unit: 'GB',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'cpu-axis',
                    position: YAxisPosition.left,
                    label: 'CPU',
                    unit: '%',
                    color: Colors.lightBlueAccent,
                  ),
                  YAxisConfig(
                    id: 'memory-axis',
                    position: YAxisPosition.right,
                    label: 'Memory',
                    unit: 'GB',
                    color: Colors.pinkAccent,
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
        matchesGoldenFile('goldens/colored_axes_dark_theme.png'),
      );
    });
  });
}
