import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T031: Golden test - Chart types
/// 
/// Visual regression tests for all 4 chart types.
/// Ensures rendering consistency across code changes.
/// 
/// Run: flutter test test/widgets/golden/chart_types_golden_test.dart
/// Update: flutter test --update-goldens test/widgets/golden/chart_types_golden_test.dart
void main() {
  group('Chart Types Golden Tests', () {
    // Common test data for all chart types
    final testSeries = [
      ChartSeries(
        id: 'sales',
        name: 'Sales',
        points: const [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: 150),
          ChartDataPoint(x: 2, y: 120),
          ChartDataPoint(x: 3, y: 180),
          ChartDataPoint(x: 4, y: 160),
        ],
      ),
    ];

    testWidgets('LineChart golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Line Chart',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/line_chart.png'),
      );
    });

    testWidgets('AreaChart golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.area,
                series: testSeries,
                title: 'Area Chart',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/area_chart.png'),
      );
    });

    testWidgets('BarChart golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.bar,
                series: testSeries,
                title: 'Bar Chart',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/bar_chart.png'),
      );
    });

    testWidgets('ScatterChart golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.scatter,
                series: testSeries,
                title: 'Scatter Chart',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/scatter_chart.png'),
      );
    });

    testWidgets('Multiple series golden', (WidgetTester tester) async {
      final multiSeries = [
        ChartSeries(
          id: 'sales',
          name: 'Sales',
          points: const [
            ChartDataPoint(x: 0, y: 100),
            ChartDataPoint(x: 1, y: 150),
            ChartDataPoint(x: 2, y: 120),
            ChartDataPoint(x: 3, y: 180),
            ChartDataPoint(x: 4, y: 160),
          ],
        ),
        ChartSeries(
          id: 'costs',
          name: 'Costs',
          points: const [
            ChartDataPoint(x: 0, y: 80),
            ChartDataPoint(x: 1, y: 90),
            ChartDataPoint(x: 2, y: 85),
            ChartDataPoint(x: 3, y: 95),
            ChartDataPoint(x: 4, y: 100),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: multiSeries,
                title: 'Multiple Series',
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/multiple_series.png'),
      );
    });
  });
}
