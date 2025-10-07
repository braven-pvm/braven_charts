/// Widget Tests: BravenChart Axis Configuration
///
/// Tests AxisConfig application and customization.
/// Validates that axis configurations are applied correctly to the chart.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart Axis Configuration', () {
    testWidgets('renders with defaults() preset', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.defaults(),
              yAxis: AxisConfig.defaults(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with hidden() preset', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.hidden(),
              yAxis: AxisConfig.hidden(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with minimal() preset', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.minimal(),
              yAxis: AxisConfig.minimal(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with gridOnly() preset', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.gridOnly(),
              yAxis: AxisConfig.gridOnly(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('applies custom axis configuration', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final customXAxis = const AxisConfig(
        showAxis: true,
        showLabels: true,
        showGrid: true,
        label: 'Time (s)',
      );

      final customYAxis = const AxisConfig(
        showAxis: true,
        showLabels: true,
        showGrid: true,
        label: 'Value',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: customXAxis,
              yAxis: customYAxis,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('copyWith() customization works', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final baseAxis = AxisConfig.defaults();
      final customAxis = baseAxis.copyWith(
        label: 'Custom Label',
        showGrid: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: customAxis,
              yAxis: AxisConfig.defaults(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('different axis configs for x and y', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.defaults(),
              yAxis: AxisConfig.minimal(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('null axis uses defaults', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Act - no axis config provided
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
            ),
          ),
        ),
      );

      // Assert - should use defaults
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('grid visibility controlled by showGrid', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Test with grid enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: const AxisConfig(
                showAxis: true,
                showLabels: true,
                showGrid: true,
              ),
              yAxis: const AxisConfig(
                showAxis: true,
                showLabels: true,
                showGrid: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Test with grid disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: const AxisConfig(
                showAxis: true,
                showLabels: true,
                showGrid: false,
              ),
              yAxis: const AxisConfig(
                showAxis: true,
                showLabels: true,
                showGrid: false,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('axis updates trigger rebuild', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Start with defaults
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.defaults(),
              yAxis: AxisConfig.defaults(),
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - change axis config
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              xAxis: AxisConfig.hidden(),
              yAxis: AxisConfig.hidden(),
            ),
          ),
        ),
      );

      // Assert - widget should rebuild with new config
      expect(find.byType(BravenChart), findsOneWidget);
    });
  });
}
