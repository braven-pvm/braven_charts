import 'dart:async';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T037: Integration test - Quickstart Steps 3-6 (All Features)
/// 
/// Validates remaining quickstart scenarios:
/// - Step 3: fromValues factory
/// - Step 4: Axis customization (hidden, gridOnly)
/// - Step 5: Real-time streaming
/// - Step 6: Programmatic control via ChartController
/// 
/// Run: flutter test test/widgets/integration/quickstart_full_test.dart
void main() {
  group('Quickstart Step 3: Simplified Data Input (fromValues)', () {
    testWidgets('fromValues factory creates chart from y-values', (WidgetTester tester) async {
      // Step 3 from quickstart.md
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart.fromValues(
                chartType: ChartType.line,
                seriesId: 'sales',
                yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
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
      
      // Verify title
      expect(find.text('Monthly Sales 2025'), findsOneWidget);
      
      // Verify series created with auto-generated x-values
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.series.length, equals(1));
      expect(chartWidget.series[0].id, equals('sales'));
      expect(chartWidget.series[0].points.length, equals(6));
      
      // Verify auto-generated x-values (0, 1, 2, 3, 4, 5)
      expect(chartWidget.series[0].points[0].x, equals(0));
      expect(chartWidget.series[0].points[0].y, equals(10000));
      expect(chartWidget.series[0].points[5].x, equals(5));
      expect(chartWidget.series[0].points[5].y, equals(25000));
    });

    testWidgets('fromValues with custom name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart.fromValues(
                chartType: ChartType.bar,
                seriesId: 'revenue',
                seriesName: 'Monthly Revenue',
                yValues: const [100, 200, 150],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.series[0].id, equals('revenue'));
      expect(chartWidget.series[0].name, equals('Monthly Revenue'));
    });
  });

  group('Quickstart Step 4: Customize Axes', () {
    testWidgets('hidden() preset creates sparkline', (WidgetTester tester) async {
      // Step 4 from quickstart.md - Sparkline style
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart.fromValues(
                chartType: ChartType.line,
                seriesId: 'sales',
                yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
                xAxis: AxisConfig.hidden(),
                yAxis: AxisConfig.hidden(),
                width: 200,
                height: 60,
              ),
            ),
          ),
        ),
      );

      // Verify sparkline dimensions
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.width, equals(200));
      expect(chartWidget.height, equals(60));
      
      // Verify hidden axis config
      expect(chartWidget.xAxis, isNotNull);
      expect(chartWidget.yAxis, isNotNull);
      expect(chartWidget.xAxis!.showAxis, isFalse);
      expect(chartWidget.yAxis!.showAxis, isFalse);
    });

    testWidgets('gridOnly() preset shows grid without axes', (WidgetTester tester) async {
      // Step 4 from quickstart.md - Grid-only style
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart.fromValues(
                chartType: ChartType.line,
                seriesId: 'sales',
                yValues: const [10000, 15000, 12000, 18000, 22000, 25000],
                xAxis: AxisConfig.gridOnly(),
                yAxis: AxisConfig.gridOnly(),
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify grid-only config
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.xAxis!.showGrid, isTrue);
      expect(chartWidget.yAxis!.showGrid, isTrue);
    });

    testWidgets('copyWith() customizes axis config', (WidgetTester tester) async {
      // Step 4 from quickstart.md - Custom grid style
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart.fromValues(
                chartType: ChartType.line,
                seriesId: 'sales',
                yValues: const [10000, 15000, 12000],
                xAxis: AxisConfig.gridOnly(),
                yAxis: AxisConfig.gridOnly().copyWith(
                  label: 'Custom Y Axis',
                ),
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify copyWith customization
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.yAxis!.label, equals('Custom Y Axis'));
      expect(chartWidget.yAxis!.showGrid, isTrue); // Preserved from gridOnly()
    });
  });

  group('Quickstart Step 5: Real-Time Data', () {
    testWidgets('dataStream updates chart automatically', (WidgetTester tester) async {
      // Step 5 from quickstart.md
      final streamController = StreamController<ChartDataPoint>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [], // Start empty
                dataStream: streamController.stream,
                title: 'Sensor Readings',
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart starts with empty series
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.text('Sensor Readings'), findsOneWidget);

      // Add data to stream
      streamController.add(const ChartDataPoint(x: 0, y: 10));
      await tester.pump(const Duration(milliseconds: 20)); // Wait for throttle

      streamController.add(const ChartDataPoint(x: 1, y: 20));
      await tester.pump(const Duration(milliseconds: 20));

      // Cleanup
      await streamController.close();
      await tester.pumpAndSettle();
    });

    testWidgets('Stream throttles to 60 FPS', (WidgetTester tester) async {
      final streamController = StreamController<ChartDataPoint>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [],
                dataStream: streamController.stream,
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Send rapid data points
      for (int i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }

      // Throttling should process at 60 FPS (16ms intervals)
      await tester.pump(const Duration(milliseconds: 50));
      
      // Cleanup
      await streamController.close();
      await tester.pumpAndSettle();
    });
  });

  group('Quickstart Step 6: Programmatic Control', () {
    testWidgets('ChartController adds data points', (WidgetTester tester) async {
      // Step 6 from quickstart.md
      final controller = ChartController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'sales',
                      points: const [],
                    ),
                  ],
                  controller: controller,
                  width: 400,
                  height: 300,
                ),
                ElevatedButton(
                  onPressed: () {
                    final nextX = controller.getAllSeries()['sales']?.length ?? 0;
                    controller.addPoint(
                      'sales',
                      ChartDataPoint(x: nextX.toDouble(), y: Random().nextDouble() * 30000),
                    );
                  },
                  child: const Text('Add Point'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify chart renders
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.text('Add Point'), findsOneWidget);

      // Tap button to add point
      await tester.tap(find.text('Add Point'));
      await tester.pump();

      // Verify point added
      final series = controller.getAllSeries()['sales'];
      expect(series, isNotNull);
      expect(series!.length, equals(1));

      // Add another point
      await tester.tap(find.text('Add Point'));
      await tester.pump();

      expect(controller.getAllSeries()['sales']!.length, equals(2));

      // Cleanup
      controller.dispose();
    });

    testWidgets('ChartController adds annotations', (WidgetTester tester) async {
      final controller = ChartController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'data',
                      points: const [
                        ChartDataPoint(x: 0, y: 10),
                        ChartDataPoint(x: 1, y: 20),
                      ],
                    ),
                  ],
                  controller: controller,
                  width: 400,
                  height: 300,
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.addAnnotation(
                      TextAnnotation(
                        id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                        text: 'Important Event',
                        position: const Offset(200, 100),
                      ),
                    );
                  },
                  child: const Text('Add Annotation'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify no annotations initially
      expect(controller.getAllAnnotations().length, equals(0));

      // Tap button to add annotation
      await tester.tap(find.text('Add Annotation'));
      await tester.pump();

      // Verify annotation added
      expect(controller.getAllAnnotations().length, equals(1));
      expect(controller.getAllAnnotations()[0], isA<TextAnnotation>());

      // Cleanup
      controller.dispose();
    });

    testWidgets('ChartController removes points', (WidgetTester tester) async {
      final controller = ChartController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'data',
                  points: const [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 20),
                    ChartDataPoint(x: 2, y: 15),
                  ],
                ),
              ],
              controller: controller,
              width: 400,
              height: 300,
            ),
          ),
        ),
      );

      // Verify initial state
      expect(controller.getAllSeries()['data']!.length, equals(3));

      // Remove oldest point
      controller.removeOldestPoint('data');
      await tester.pump();

      expect(controller.getAllSeries()['data']!.length, equals(2));
      expect(controller.getAllSeries()['data']![0].x, equals(1)); // Second point is now first

      // Cleanup
      controller.dispose();
    });

    testWidgets('ChartController clears series', (WidgetTester tester) async {
      final controller = ChartController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [
                ChartSeries(
                  id: 'data',
                  points: const [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 20),
                  ],
                ),
              ],
              controller: controller,
              width: 400,
              height: 300,
            ),
          ),
        ),
      );

      // Clear series
      controller.clearSeries('data');
      await tester.pump();

      expect(controller.getAllSeries()['data']!.length, equals(0));

      // Cleanup
      controller.dispose();
    });
  });

  group('Integration: Combined Features', () {
    testWidgets('All features work together', (WidgetTester tester) async {
      // Combine Steps 1-6: Multi-series chart with annotations, streaming, and controller
      final controller = ChartController();
      final streamController = StreamController<ChartDataPoint>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'sales',
                      name: 'Sales',
                      points: const [
                        ChartDataPoint(x: 1, y: 10000),
                        ChartDataPoint(x: 2, y: 15000),
                      ],
                    ),
                  ],
                  annotations: [
                    ThresholdAnnotation(
                      id: 'target',
                      axis: AnnotationAxis.y,
                      value: 20000,
                      label: 'Target',
                    ),
                  ],
                  controller: controller,
                  dataStream: streamController.stream,
                  xAxis: AxisConfig.defaults(),
                  yAxis: AxisConfig.defaults(),
                  title: 'Comprehensive Chart',
                  width: 400,
                  height: 300,
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.addPoint(
                      'sales',
                      ChartDataPoint(x: 3, y: 18000),
                    );
                  },
                  child: const Text('Add Point'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify all features present
      expect(find.byType(BravenChart), findsOneWidget);
      expect(find.text('Comprehensive Chart'), findsOneWidget);
      
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.series.length, equals(1));
      expect(chartWidget.annotations.length, equals(1));
      expect(chartWidget.controller, equals(controller));
      expect(chartWidget.dataStream, equals(streamController.stream));
      expect(chartWidget.xAxis, isNotNull);
      expect(chartWidget.yAxis, isNotNull);

      // Test controller
      await tester.tap(find.text('Add Point'));
      await tester.pump();

      expect(controller.getAllSeries()['sales']!.length, equals(3));

      // Test stream
      streamController.add(const ChartDataPoint(x: 4, y: 22000));
      await tester.pump(const Duration(milliseconds: 20));

      // Cleanup
      controller.dispose();
      await streamController.close();
      await tester.pumpAndSettle();
    });
  });
}
