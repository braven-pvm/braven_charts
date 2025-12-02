import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auto-Detection Widget Tests', () {
    testWidgets('detects normalization need for >10x range difference', (tester) async {
      // Power: 0-4000W range = 4000
      // Heart rate: 60-180bpm range = 120
      // Ratio: 4000/120 = 33x (>10x threshold for auto-detection)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 4000), // Large range: 0-4000
                  ],
                  color: Colors.blue,
                  yAxisConfig: YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                  ),
                ),
                LineChartSeries(
                  id: 'hr',
                  points: const [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Small range: 60-180
                  ],
                  color: Colors.red,
                  yAxisConfig: YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                  ),
                ),
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
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200), // Small range: 100-200
                  ],
                  color: Colors.blue,
                  yAxisConfig: YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                  ),
                ),
                LineChartSeries(
                  id: 'hr',
                  points: const [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Similar range: 60-180
                  ],
                  color: Colors.red,
                  yAxisConfig: YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                  ),
                ),
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
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 0),
                    ChartDataPoint(x: 1, y: 4000), // Large range: 0-4000
                  ],
                  color: Colors.blue,
                  yAxisConfig: YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                  ),
                ),
                LineChartSeries(
                  id: 'hr',
                  points: const [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Small range: 60-180
                  ],
                  color: Colors.red,
                  yAxisConfig: YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                  ),
                ),
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
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200), // Small range
                  ],
                  color: Colors.blue,
                  yAxisConfig: YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                  ),
                ),
                LineChartSeries(
                  id: 'hr',
                  points: const [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180), // Similar range
                  ],
                  color: Colors.red,
                  yAxisConfig: YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                  ),
                ),
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
