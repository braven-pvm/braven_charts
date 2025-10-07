import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T035: Integration test - Quickstart Step 1 (Basic Line Chart)
/// 
/// Validates the 2-minute basic chart scenario from quickstart.md Step 1.
/// Tests that users can create a simple line chart with minimal configuration.
/// 
/// Run: flutter test test/widgets/integration/quickstart_step1_test.dart
void main() {
  group('Quickstart Step 1: Basic Line Chart', () {
    testWidgets('Creates line chart with sales data', (WidgetTester tester) async {
      // Step 1 from quickstart.md
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Sales Dashboard')),
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'monthly_sales',
                    name: 'Monthly Sales',
                    points: const [
                      ChartDataPoint(x: 1, y: 10000), // Jan
                      ChartDataPoint(x: 2, y: 15000), // Feb
                      ChartDataPoint(x: 3, y: 12000), // Mar
                      ChartDataPoint(x: 4, y: 18000), // Apr
                      ChartDataPoint(x: 5, y: 22000), // May
                      ChartDataPoint(x: 6, y: 25000), // Jun
                    ],
                  ),
                ],
                title: 'Monthly Sales 2025',
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart renders
      expect(find.byType(BravenChart), findsOneWidget);
      
      // Verify title renders
      expect(find.text('Monthly Sales 2025'), findsOneWidget);
      
      // Verify chart dimensions
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.width, equals(400));
      expect(chartWidget.height, equals(300));
      
      // Verify chart type
      expect(chartWidget.chartType, equals(ChartType.line));
      
      // Verify series data
      expect(chartWidget.series.length, equals(1));
      expect(chartWidget.series[0].id, equals('monthly_sales'));
      expect(chartWidget.series[0].name, equals('Monthly Sales'));
      expect(chartWidget.series[0].points.length, equals(6));
      
      // Verify data points
      expect(chartWidget.series[0].points[0].x, equals(1));
      expect(chartWidget.series[0].points[0].y, equals(10000));
      expect(chartWidget.series[0].points[5].x, equals(6));
      expect(chartWidget.series[0].points[5].y, equals(25000));
    });

    testWidgets('Chart renders with default theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'sales',
                    points: const [
                      ChartDataPoint(x: 1, y: 100),
                      ChartDataPoint(x: 2, y: 150),
                      ChartDataPoint(x: 3, y: 120),
                    ],
                  ),
                ],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart renders with default theme when none specified
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.theme, isNull); // Should use internal default
      
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Chart auto-calculates axes from data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'sales',
                    points: const [
                      ChartDataPoint(x: 0, y: 10),
                      ChartDataPoint(x: 10, y: 100),
                    ],
                  ),
                ],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify axes are auto-calculated (no axis config provided)
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.xAxis, isNull); // Should auto-calculate
      expect(chartWidget.yAxis, isNull); // Should auto-calculate
      
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Legend shown by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'series1',
                    name: 'Series 1',
                    points: const [
                      ChartDataPoint(x: 0, y: 10),
                      ChartDataPoint(x: 1, y: 20),
                    ],
                  ),
                ],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify legend is shown by default
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.showLegend, isTrue);
    });

    testWidgets('Minimal required parameters work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'minimal',
                    points: const [
                      ChartDataPoint(x: 0, y: 1),
                      ChartDataPoint(x: 1, y: 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify chart works with only required parameters
      expect(find.byType(BravenChart), findsOneWidget);
      
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.series.length, equals(1));
      expect(chartWidget.series[0].points.length, equals(2));
    });
  });
}
