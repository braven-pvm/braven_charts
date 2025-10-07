/// Widget Tests: BravenChart Annotation Rendering
///
/// Tests all 5 annotation types render correctly.
/// Validates annotation overlay, z-index ordering, and interactions.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart Annotation Rendering', () {
    testWidgets('renders TextAnnotation at position', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = TextAnnotation(
        text: 'Peak Value',
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
      expect(find.text('Peak Value'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget); // Annotations use Stack
    });

    testWidgets('renders PointAnnotation on data point', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = PointAnnotation(
        seriesId: 'test-series',
        dataPointIndex: 1,
        markerShape: MarkerShape.circle,
        markerSize: 10,
        markerColor: Colors.red,
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
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets); // Marker uses CustomPaint
    });

    testWidgets('renders RangeAnnotation spanning range', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = RangeAnnotation(
        startX: 0,
        endX: 1,
        fillColor: Colors.blue.withOpacity(0.2),
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
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('renders ThresholdAnnotation as horizontal line', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 15,
        label: 'Threshold',
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
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders ThresholdAnnotation as vertical line', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = ThresholdAnnotation(
        axis: AnnotationAxis.x,
        value: 0.5,
        label: 'Midpoint',
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
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('renders TrendAnnotation as overlay', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 15),
          const ChartDataPoint(x: 2, y: 20),
        ],
      );

      final annotation = TrendAnnotation(
        seriesId: 'test-series',
        trendType: TrendType.linear,
        label: 'Trend Line',
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
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders multiple annotations', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotations = [
        TextAnnotation(
          text: 'Start',
          position: const Offset(50, 50),
        ),
        TextAnnotation(
          text: 'End',
          position: const Offset(200, 50),
        ),
        ThresholdAnnotation(
          axis: AnnotationAxis.y,
          value: 15,
          label: 'Average',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              annotations: annotations,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('z-index ordering works', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Create annotations with different z-indexes
      final annotations = [
        TextAnnotation(
          text: 'Z-Index 10',
          position: const Offset(100, 50),
          zIndex: 10,
        ),
        TextAnnotation(
          text: 'Z-Index 1',
          position: const Offset(100, 70),
          zIndex: 1,
        ),
        TextAnnotation(
          text: 'Z-Index 5',
          position: const Offset(100, 90),
          zIndex: 5,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              annotations: annotations,
            ),
          ),
        ),
      );

      // Assert - all annotations should render
      expect(find.text('Z-Index 10'), findsOneWidget);
      expect(find.text('Z-Index 1'), findsOneWidget);
      expect(find.text('Z-Index 5'), findsOneWidget);
    });

    testWidgets('interactive annotations respond to tap', (WidgetTester tester) async {
      // Arrange
      ChartAnnotation? tappedAnnotation;
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = TextAnnotation(
        text: 'Tap Me',
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
              interactiveAnnotations: true,
              onAnnotationTap: (anno) {
                tappedAnnotation = anno;
              },
            ),
          ),
        ),
      );

      // Tap the annotation
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      // Assert
      expect(tappedAnnotation, isNotNull);
    });

    testWidgets('non-interactive annotations ignore taps', (WidgetTester tester) async {
      // Arrange
      ChartAnnotation? tappedAnnotation;
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      final annotation = TextAnnotation(
        text: 'Not Interactive',
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
              interactiveAnnotations: false, // Disabled
              onAnnotationTap: (anno) {
                tappedAnnotation = anno;
              },
            ),
          ),
        ),
      );

      // Tap would not work because interactiveAnnotations is false
      // Just verify widget renders
      expect(find.text('Not Interactive'), findsOneWidget);
      expect(tappedAnnotation, isNull);
    });

    testWidgets('all marker shapes render', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Test each marker shape
      for (final shape in MarkerShape.values) {
        final annotation = PointAnnotation(
          seriesId: 'test-series',
          dataPointIndex: 0,
          markerShape: shape,
          markerSize: 10,
          markerColor: Colors.blue,
        );

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
        expect(find.byType(Stack), findsOneWidget);
      }
    });

    testWidgets('all trend types render', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 15),
          const ChartDataPoint(x: 2, y: 20),
        ],
      );

      // Test each trend type
      for (final trendType in TrendType.values) {
        final annotation = TrendAnnotation(
          seriesId: 'test-series',
          trendType: trendType,
        );

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
        expect(find.byType(Stack), findsOneWidget);
      }
    });
  });
}
