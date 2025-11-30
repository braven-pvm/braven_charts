import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Chart Widget', () {
    testWidgets('renders chart with multiple Y-axes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                const LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue,
                ),
                const LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 80),
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
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('applies normalization mode when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                const LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 400),
                  ],
                  color: Colors.blue,
                ),
                const LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180),
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
              normalizationMode: NormalizationMode.perSeries,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error with perSeries normalization
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('uses default axis when no binding specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                const LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue,
                ),
                const LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 80),
                  ],
                  color: Colors.red,
                ),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              // Only power has binding, hr uses default (first axis)
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Test SeriesAxisResolver behavior
      const bindings = [
        SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
      ];
      final axes = [
        YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
        YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
      ];

      // Power should use explicit binding
      expect(
        SeriesAxisResolver.resolveAxisId('power', bindings, axes),
        'power-axis',
      );

      // HR should use first (default) axis
      expect(
        SeriesAxisResolver.resolveAxisId('hr', bindings, axes),
        'power-axis',
      );
    });

    testWidgets('handles empty yAxes gracefully', (tester) async {
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
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue,
                ),
              ],
              // Null yAxes - falls back to single axis mode
              yAxes: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error in single-axis mode
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('handles single axis in yAxes list', (tester) async {
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
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue,
                ),
              ],
              // Single axis - should not trigger multi-axis mode
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });
  });
}
