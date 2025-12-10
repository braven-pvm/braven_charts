import 'package:braven_charts/braven_charts.dart';
// Import internal classes for resolver unit tests
import 'package:braven_charts/src/models/series_axis_binding.dart';
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
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue, // Power is blue
                  yAxisConfig: YAxisConfig.withId(id: 'power-axis',
                    position: YAxisPosition.left,
                    color: null, // Should derive blue from series
                  ),
                ),
                LineChartSeries(
                  id: 'hr',
                  points: const [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 180),
                  ],
                  color: Colors.red, // HR is red
                  yAxisConfig: YAxisConfig.withId(id: 'hr-axis',
                    position: YAxisPosition.right,
                    color: null, // Should derive red from series
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior (internal API)
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

      final powerAxis = YAxisConfig.withId(id: 'power-axis',
        position: YAxisPosition.left,
        color: null,
      );
      final hrAxis = YAxisConfig.withId(id: 'hr-axis',
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
              series: [
                LineChartSeries(
                  id: 'power',
                  points: const [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue, // Series is blue
                  yAxisConfig: YAxisConfig.withId(id: 'power-axis',
                    position: YAxisPosition.left,
                    color: greenColor, // Explicit green overrides blue
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior (internal API)
      const powerSeries = ChartSeries(
        id: 'power',
        points: [],
        color: Colors.blue,
      );

      final powerAxisWithColor = YAxisConfig.withId(id: 'power-axis',
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
      // Two series bound to same axis via yAxisId - axis uses first series' color

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              series: const [
                LineChartSeries(
                  id: 'cpu',
                  points: [
                    ChartDataPoint(x: 0, y: 50),
                    ChartDataPoint(x: 1, y: 75),
                  ],
                  color: Colors.green, // First series - GREEN
                  yAxisId: 'percentage-axis',
                ),
                LineChartSeries(
                  id: 'memory',
                  points: [
                    ChartDataPoint(x: 0, y: 60),
                    ChartDataPoint(x: 1, y: 80),
                  ],
                  color: Colors.purple, // Second series - PURPLE
                  yAxisId: 'percentage-axis',
                ),
              ],
              yAxes: [
                YAxisConfig.withId(id: 'percentage-axis',
                  position: YAxisPosition.left,
                  color: null, // Should use green (first bound series)
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior with shared axis (internal API)
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

      final sharedAxis = YAxisConfig.withId(id: 'percentage-axis',
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
              series: const [
                LineChartSeries(
                  id: 'power',
                  points: [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
                  color: Colors.blue,
                  // No yAxisId or yAxisConfig - not bound to unbound-axis
                ),
              ],
              yAxes: [
                YAxisConfig.withId(id: 'unbound-axis',
                  position: YAxisPosition.left,
                  color: null, // No binding, no explicit color
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);

      // Verify AxisColorResolver behavior with unbound axis (internal API)
      final unboundAxis = YAxisConfig.withId(id: 'unbound-axis',
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
