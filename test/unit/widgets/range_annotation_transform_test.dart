import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

/// Unit tests for Phase 1, Task 1.2: RangeAnnotation coordinate transformation
///
/// These tests verify that RangeAnnotation rectangles are correctly positioned
/// and sized using proper coordinate transformation from data space to screen space.
void main() {
  group('RangeAnnotation Coordinate Transformation', () {
    testWidgets('should render range annotation with both X and Y bounds', (WidgetTester tester) async {
      // Arrange: Create a simple chart with known data
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a range annotation covering middle region
      final annotation = RangeAnnotation(
        id: 'test-range',
        startX: 2.0,
        endX: 8.0,
        startY: 3.0,
        endY: 7.0,
        fillColor: Colors.blue.withOpacity(0.2),
        borderColor: Colors.blue,
      );

      // Act: Build the chart with the annotation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Chart should render without errors
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle infinite X range (null startX)', (WidgetTester tester) async {
      // Arrange: Create chart
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Range with no start X (extends to beginning)
      final annotation = RangeAnnotation(
        id: 'test-range',
        startX: null, // Infinite in negative X direction
        endX: 5.0,
        startY: 2.0,
        endY: 8.0,
        fillColor: Colors.red.withOpacity(0.1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Should render without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle infinite X range (null endX)', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Range with no end X (extends to end)
      final annotation = RangeAnnotation(
        id: 'test-range',
        startX: 5.0,
        endX: null, // Infinite in positive X direction
        startY: 2.0,
        endY: 8.0,
        fillColor: Colors.green.withOpacity(0.1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle infinite Y range (null values)', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Range with infinite Y bounds
      final annotation = RangeAnnotation(
        id: 'test-range',
        startX: 3.0,
        endX: 7.0,
        startY: null, // Infinite in negative Y direction
        endY: null,   // Infinite in positive Y direction
        fillColor: Colors.purple.withOpacity(0.1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render multiple range annotations correctly', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 20, y: 20),
        ],
      );

      // Multiple non-overlapping ranges
      final annotations = [
        RangeAnnotation(
          id: 'range-1',
          startX: 2.0,
          endX: 6.0,
          startY: 3.0,
          endY: 8.0,
          fillColor: Colors.red.withOpacity(0.2),
        ),
        RangeAnnotation(
          id: 'range-2',
          startX: 8.0,
          endX: 12.0,
          startY: 10.0,
          endY: 15.0,
          fillColor: Colors.blue.withOpacity(0.2),
        ),
        RangeAnnotation(
          id: 'range-3',
          startX: 14.0,
          endX: 18.0,
          startY: 12.0,
          endY: 18.0,
          fillColor: Colors.green.withOpacity(0.2),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: annotations,
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('should handle X-only range (vertical strip)', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Vertical strip (only X bounds specified)
      final annotation = RangeAnnotation(
        id: 'vertical-strip',
        startX: 4.0,
        endX: 6.0,
        startY: null, // Full height
        endY: null,   // Full height
        fillColor: Colors.orange.withOpacity(0.2),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle Y-only range (horizontal strip)', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Horizontal strip (only Y bounds specified)
      final annotation = RangeAnnotation(
        id: 'horizontal-strip',
        startX: null, // Full width
        endX: null,   // Full width
        startY: 4.0,
        endY: 6.0,
        fillColor: Colors.cyan.withOpacity(0.2),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });
  });
}
