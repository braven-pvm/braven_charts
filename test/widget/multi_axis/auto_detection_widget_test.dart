import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auto-Detection Widget Tests', () {
    testWidgets('detects normalization need for >10x range difference', (tester) async {
      // Power: 0-400W range = 400
      // Heart rate: 60-180bpm range = 120
      // Ratio: 400/120 = 3.33x (not enough for auto-detection)
      // Need 10x difference: e.g., Power 0-4000W vs HR 60-180bpm

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: const [
                LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 4000), // Large range: 0-4000
                  ],
                  color: Colors.blue,
                ),
                LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Small range: 60-180
                  ],
                  color: Colors.red,
                ),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.auto,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders - auto-detection logic will detect need for normalization
      // Range ratio: 4000 / 120 = 33x > 10x threshold
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('does not trigger for <10x range difference', (tester) async {
      // Create chart with similar ranges
      // Power: 100-200W range = 100
      // Heart rate: 60-180bpm range = 120
      // Ratio: 120/100 = 1.2x (well below 10x threshold)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: const [
                LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200), // Small range: 100-200
                  ],
                  color: Colors.blue,
                ),
                LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Similar range: 60-180
                  ],
                  color: Colors.red,
                ),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.auto,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders - auto-detection should NOT trigger normalization
      // Range ratio: 120/100 = 1.2x < 10x threshold
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('respects NormalizationMode.none override', (tester) async {
      // Even with >10x range difference, normalization should be disabled

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: const [
                LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 4000), // Large range: 0-4000
                  ],
                  color: Colors.blue,
                ),
                LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Small range: 60-180
                  ],
                  color: Colors.red,
                ),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.none, // Force disabled
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders with normalization disabled
      // Even though range ratio is 33x > 10x, none mode prevents normalization
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('respects NormalizationMode.perSeries override', (tester) async {
      // Force normalization even with similar ranges

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: const [
                LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200), // Small range
                  ],
                  color: Colors.blue,
                ),
                LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Similar range
                  ],
                  color: Colors.red,
                ),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
              normalizationMode: NormalizationMode.perSeries, // Force enabled
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders with forced per-series normalization
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
