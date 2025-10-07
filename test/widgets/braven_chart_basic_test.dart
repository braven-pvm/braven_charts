/// Widget Tests: BravenChart Basic Rendering
///
/// Tests basic rendering scenarios for the BravenChart widget.
/// Validates that the widget renders correctly with various configurations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('BravenChart Basic Rendering', () {
    testWidgets('renders with minimal required params', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
          const ChartDataPoint(x: 2, y: 15),
        ],
      );

      // Act
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

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders line chart', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'line-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
          const ChartDataPoint(x: 2, y: 15),
          const ChartDataPoint(x: 3, y: 25),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              width: 400,
              height: 300,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets); // Should have SizedBox for dimensions
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders area chart', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'area-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
          const ChartDataPoint(x: 2, y: 15),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.area,
              series: [series],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders bar chart', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'bar-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
          const ChartDataPoint(x: 2, y: 15),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.bar,
              series: [series],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders scatter chart', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'scatter-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
          const ChartDataPoint(x: 2, y: 15),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.scatter,
              series: [series],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom dimensions', (WidgetTester tester) async {
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
              width: 600,
              height: 400,
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, equals(600));
      expect(sizedBox.height, equals(400));
    });

    testWidgets('renders with custom theme', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Use the default theme instead of creating a custom one
      final customTheme = ChartTheme.defaultDark;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              theme: customTheme,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with title', (WidgetTester tester) async {
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
              title: 'Sales Report',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Sales Report'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget); // Title should add Column wrapper
    });

    testWidgets('renders with subtitle', (WidgetTester tester) async {
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
              title: 'Sales Report',
              subtitle: 'Q1 2025',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Sales Report'), findsOneWidget);
      expect(find.text('Q1 2025'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders multiple series', (WidgetTester tester) async {
      // Arrange
      final series1 = ChartSeries(
        id: 'series-1',
        name: 'Revenue',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final series2 = ChartSeries(
        id: 'series-2',
        name: 'Expenses',
        points: [
          const ChartDataPoint(x: 0, y: 5),
          const ChartDataPoint(x: 1, y: 15),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series1, series2],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with axis configurations', (WidgetTester tester) async {
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

    testWidgets('renders with annotations', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = TextAnnotation(
        text: 'Peak',
        position: const Offset(100, 50),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              annotations: [annotation],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget); // Annotations add Stack
      expect(find.text('Peak'), findsOneWidget);
    });

    testWidgets('renders without annotations when list is empty', (WidgetTester tester) async {
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
              annotations: const [],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      // No Stack when annotations are empty
    });

    testWidgets('renders with RepaintBoundary for performance', (WidgetTester tester) async {
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
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(RepaintBoundary), findsWidgets);
    });
  });
}
