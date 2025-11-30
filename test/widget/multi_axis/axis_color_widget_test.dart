import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Axis Color Widget Tests', () {
    testWidgets('axis derives color from bound series', (tester) async {
      // Create chart with colored series, axes with null color
      // The axes should derive colors from their bound series

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
                  color: Colors.blue, // Power is blue
                ),
                LineChartSeries(
                  id: 'hr',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180),
                  ],
                  color: Colors.red, // HR is red
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'power-axis',
                  position: YAxisPosition.left,
                  color: null, // Should derive blue from power series
                ),
                YAxisConfig(
                  id: 'hr-axis',
                  position: YAxisPosition.right,
                  color: null, // Should derive red from hr series
                ),
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

      // Verify AxisColorResolver behavior
      const powerSeries = ChartSeries(
        id: 'power',
        points: [],
        color: Colors.blue,
      );
      const hrSeries = ChartSeries(
        id: 'hr',
        points: [],
        color: Colors.red,
      );

      final powerAxis = YAxisConfig(
        id: 'power-axis',
        position: YAxisPosition.left,
        color: null,
      );
      final hrAxis = YAxisConfig(
        id: 'hr-axis',
        position: YAxisPosition.right,
        color: null,
      );

      const bindings = [
        SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
        SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
      ];

      const series = [powerSeries, hrSeries];

      // Power axis should use blue
      expect(
        AxisColorResolver.resolveAxisColor(powerAxis, bindings, series),
        Colors.blue,
      );

      // HR axis should use red
      expect(
        AxisColorResolver.resolveAxisColor(hrAxis, bindings, series),
        Colors.red,
      );
    });

    testWidgets('explicit axis color overrides series color', (tester) async {
      const greenColor = Color(0xFF00FF00);

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
                  color: Colors.blue, // Series is blue
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'power-axis',
                  position: YAxisPosition.left,
                  color: greenColor, // Explicit green overrides blue
                ),
              ],
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

      // Verify AxisColorResolver behavior
      const powerSeries = ChartSeries(
        id: 'power',
        points: [],
        color: Colors.blue,
      );

      final powerAxisWithColor = YAxisConfig(
        id: 'power-axis',
        position: YAxisPosition.left,
        color: greenColor, // Explicit color
      );

      const bindings = [
        SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
      ];

      const series = [powerSeries];

      // Axis should use explicit green, not series blue
      expect(
        AxisColorResolver.resolveAxisColor(powerAxisWithColor, bindings, series),
        greenColor,
      );
    });

    testWidgets('shared axis uses first bound series color', (tester) async {
      // Two series bound to same axis - axis uses first series' color

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: const [
                LineChartSeries(
                  id: 'cpu',
                  points: [
                    ChartDataPoint(x: 0, y: 50),
                    ChartDataPoint(x: 1, y: 75),
                  ],
                  color: Colors.green, // First series - GREEN
                ),
                LineChartSeries(
                  id: 'memory',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 80),
                  ],
                  color: Colors.purple, // Second series - PURPLE
                ),
              ],
              yAxes: [
                YAxisConfig(
                  id: 'percentage-axis',
                  position: YAxisPosition.left,
                  color: null, // Should use green (first bound series)
                ),
              ],
              axisBindings: const [
                SeriesAxisBinding(seriesId: 'cpu', yAxisId: 'percentage-axis'),
                SeriesAxisBinding(seriesId: 'memory', yAxisId: 'percentage-axis'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior with shared axis
      const cpuSeries = ChartSeries(
        id: 'cpu',
        points: [],
        color: Colors.green,
      );
      const memorySeries = ChartSeries(
        id: 'memory',
        points: [],
        color: Colors.purple,
      );

      final sharedAxis = YAxisConfig(
        id: 'percentage-axis',
        position: YAxisPosition.left,
        color: null,
      );

      // CPU binding comes first in the list
      const bindings = [
        SeriesAxisBinding(seriesId: 'cpu', yAxisId: 'percentage-axis'),
        SeriesAxisBinding(seriesId: 'memory', yAxisId: 'percentage-axis'),
      ];

      const series = [cpuSeries, memorySeries];

      // Axis should use green (first bound series' color)
      expect(
        AxisColorResolver.resolveAxisColor(sharedAxis, bindings, series),
        Colors.green,
      );
    });

    testWidgets('unbound axis uses default color', (tester) async {
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
              yAxes: [
                YAxisConfig(
                  id: 'unbound-axis',
                  position: YAxisPosition.left,
                  color: null, // No binding, no explicit color
                ),
              ],
              // No bindings - axis has no bound series
              axisBindings: const [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior with unbound axis
      final unboundAxis = YAxisConfig(
        id: 'unbound-axis',
        position: YAxisPosition.left,
        color: null,
      );

      const powerSeries = ChartSeries(
        id: 'power',
        points: [],
        color: Colors.blue,
      );

      // No bindings for this axis
      const bindings = <SeriesAxisBinding>[];
      const series = [powerSeries];

      // Axis should use default gray color
      const defaultGray = Color(0xFF333333);
      expect(
        AxisColorResolver.resolveAxisColor(unboundAxis, bindings, series),
        defaultGray,
      );
    });
  });
}
