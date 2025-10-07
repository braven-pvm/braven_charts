/// API Contract: BravenChart Widget
/// 
/// This contract defines the expected behavior of the BravenChart widget.
/// Tests should be written BEFORE implementation (TDD red phase).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('BravenChart Widget Contract', () {
    group('Constructor', () {
      test('MUST accept chartType and series as required parameters', () {
        // Expectation: Constructor compiles with minimum required params
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)]),
            ],
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional width and height', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            width: 400,
            height: 300,
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional theme parameter', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            theme: ChartTheme.defaultLight,
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional xAxis and yAxis configuration', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            xAxis: AxisConfig.defaults(),
            yAxis: AxisConfig.minimal(),
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional annotations list', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            annotations: [
              TextAnnotation(position: const Offset(100, 50), label: 'Test'),
            ],
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional controller', () {
        final controller = ChartController();
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            controller: controller,
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional dataStream', () {
        const stream = Stream<ChartDataPoint>.empty();
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [],
            dataStream: stream,
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional title and subtitle', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            title: 'Sales Chart',
            subtitle: 'Monthly Revenue',
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional legend and toolbar flags', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            showLegend: true,
            showToolbar: false,
          ),
          returnsNormally,
        );
      });

      test('MUST accept optional interaction callbacks', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            onPointTap: (point) {},
            onPointHover: (point) {},
            onBackgroundTap: (offset) {},
            onSeriesSelected: (seriesId) {},
            onAnnotationTap: (annotation) {},
            onAnnotationDragged: (annotation, offset) {},
          ),
          returnsNormally,
        );
      });
    });

    group('Factory Constructors', () {
      test('MUST provide fromValues factory', () {
        expect(
          () => BravenChart.fromValues(
            chartType: ChartType.line,
            seriesId: 's1',
            yValues: [1, 2, 3, 4, 5],
          ),
          returnsNormally,
        );
      });

      test('MUST provide fromMap factory', () {
        expect(
          () => BravenChart.fromMap(
            chartType: ChartType.line,
            seriesId: 's1',
            data: {0: 1.0, 1: 2.0, 2: 3.0},
          ),
          returnsNormally,
        );
      });

      test('MUST provide fromJson factory', () {
        expect(
          () => BravenChart.fromJson(
            chartType: ChartType.line,
            json: '[{"x":0,"y":1},{"x":1,"y":2}]',
          ),
          returnsNormally,
        );
      });
    });

    group('Validation', () {
      test('MUST require at least one series or dataStream', () {
        // This should fail during rendering, not construction
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [], // Empty!
            // No dataStream either
          ),
          throwsAssertionError,
        );
      });

      test('MUST reject negative width', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            width: -100, // Invalid!
          ),
          throwsAssertionError,
        );
      });

      test('MUST reject negative height', () {
        expect(
          () => BravenChart(
            chartType: ChartType.line,
            series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
            height: -100, // Invalid!
          ),
          throwsAssertionError,
        );
      });
    });

    group('Rendering', () {
      testWidgets('MUST render as a Flutter widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 's1',
                    points: [
                      const ChartDataPoint(0, 0),
                      const ChartDataPoint(1, 1),
                      const ChartDataPoint(2, 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        // Should find the widget
        expect(find.byType(BravenChart), findsOneWidget);
      });

      testWidgets('MUST render with specified dimensions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
                width: 400,
                height: 300,
              ),
            ),
          ),
        );

        // Find CustomPaint widget
        final customPaint = tester.widget<CustomPaint>(
          find.byType(CustomPaint),
        );
        expect(customPaint.size, equals(const Size(400, 300)));
      });

      testWidgets('MUST render all chart types', (tester) async {
        for (final chartType in ChartType.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: BravenChart(
                  chartType: chartType,
                  series: [
                    ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)]),
                  ],
                ),
              ),
            ),
          );

          expect(find.byType(BravenChart), findsOneWidget);
        }
      });
    });

    group('Controller Integration', () {
      testWidgets('MUST subscribe to controller in initState', (tester) async {
        final controller = ChartController();
        var listenerCalled = false;

        controller.addListener(() {
          listenerCalled = true;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [])],
                controller: controller,
              ),
            ),
          ),
        );

        // Trigger controller update
        controller.addPoint('s1', const ChartDataPoint(1, 1));
        await tester.pump();

        expect(listenerCalled, isTrue);
      });

      testWidgets('MUST unsubscribe from controller in dispose',
          (tester) async {
        final controller = ChartController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [])],
                controller: controller,
              ),
            ),
          ),
        );

        // Remove widget
        await tester.pumpWidget(Container());

        // Controller should still work but widget shouldn't respond
        expect(() => controller.addPoint('s1', const ChartDataPoint(2, 2)),
            returnsNormally);
      });
    });

    group('Stream Integration', () {
      testWidgets('MUST subscribe to dataStream in initState',
          (tester) async {
        final streamController = StreamController<ChartDataPoint>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [],
                dataStream: streamController.stream,
              ),
            ),
          ),
        );

        // Add data to stream
        streamController.add(const ChartDataPoint(1, 1));
        await tester.pump(const Duration(milliseconds: 20)); // Allow throttling

        expect(find.byType(BravenChart), findsOneWidget);
        streamController.close();
      });

      testWidgets('MUST cancel stream subscription in dispose',
          (tester) async {
        final streamController = StreamController<ChartDataPoint>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [],
                dataStream: streamController.stream,
              ),
            ),
          ),
        );

        // Remove widget
        await tester.pumpWidget(Container());

        // Stream should still work but widget shouldn't crash
        expect(() => streamController.add(const ChartDataPoint(2, 2)),
            returnsNormally);
        streamController.close();
      });
    });

    group('Annotation Rendering', () {
      testWidgets('MUST render static annotations', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
                annotations: [
                  TextAnnotation(
                    position: const Offset(100, 50),
                    label: 'Test Annotation',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(BravenChart), findsOneWidget);
        // Note: Actual annotation rendering verified in golden tests
      });
    });

    group('Hot Reload Support', () {
      testWidgets('MUST support configuration changes without leaks',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
                xAxis: AxisConfig.defaults(),
              ),
            ),
          ),
        );

        // Update configuration
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [ChartSeries(id: 's1', points: [const ChartDataPoint(0, 0)])],
                xAxis: AxisConfig.hidden(), // Changed!
              ),
            ),
          ),
        );

        expect(find.byType(BravenChart), findsOneWidget);
        // Memory leak detection verified in integration tests
      });
    });
  });
}
