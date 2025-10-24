import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Crash Prevention - SC-001', () {
    testWidgets('T018: 1000+ continuous mouse movements without crashes',
        (WidgetTester tester) async {
      // Arrange: Create chart with 50+ data points and full interaction enabled
      final chart = MaterialApp(
        home: Scaffold(
          body: BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(
                id: 'test-series',
                points: List.generate(
                  100, // More than 50 data points
                  (i) => ChartDataPoint(
                    x: i.toDouble(),
                    y: (i * 2 + (i % 10) * 5).toDouble(), // Varied data
                  ),
                ),
                color: Colors.blue,
              ),
            ],
            interactionConfig: const InteractionConfig(
              crosshair: CrosshairConfig(enabled: true),
              tooltip: TooltipConfig(enabled: true),
              enableZoom: true,
              enablePan: true,
            ),
          ),
        ),
      );

      await tester.pumpWidget(chart);
      await tester.pumpAndSettle();

      // Act: Perform 1000+ continuous mouse movements
      final chartFinder = find.byType(BravenChart);
      expect(chartFinder, findsOneWidget);

      final chartSize = tester.getSize(chartFinder);
      final chartTopLeft = tester.getTopLeft(chartFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
          location:
              chartTopLeft + Offset(chartSize.width / 2, chartSize.height / 2));

      // Move mouse in a pattern across the chart
      for (int i = 0; i < 1000; i++) {
        final x = chartTopLeft.dx + (i % chartSize.width.toInt());
        final y = chartTopLeft.dy + ((i ~/ 10) % chartSize.height.toInt());
        await gesture.moveTo(Offset(x, y));

        // Pump occasionally to process events
        if (i % 50 == 0) {
          await tester.pump();
        }
      }

      await tester.pump();
      await gesture.removePointer();
      await tester.pumpAndSettle();

      // Assert: Chart still renders, no crashes
      expect(find.byType(BravenChart), findsOneWidget);

      // Verify no error widgets (would indicate crash/exception)
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'No box.dart:3345 or mouse_tracker.dart:199 errors during stress test',
        (WidgetTester tester) async {
      // This test verifies the specific crashes mentioned in SC-001 don't occur

      final chart = MaterialApp(
        home: Scaffold(
          body: BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(
                id: 'stress-test',
                points: List.generate(
                  200,
                  (i) =>
                      ChartDataPoint(x: i.toDouble(), y: (i * 1.5).toDouble()),
                ),
                color: Colors.red,
              ),
            ],
            interactionConfig: const InteractionConfig(
              crosshair: CrosshairConfig(enabled: true),
              tooltip: TooltipConfig(enabled: true),
            ),
          ),
        ),
      );

      await tester.pumpWidget(chart);
      await tester.pumpAndSettle();

      // Rapid continuous movement (stress test)
      final chartFinder = find.byType(BravenChart);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(chartFinder));

      for (int i = 0; i < 500; i++) {
        await gesture.moveTo(
            tester.getCenter(chartFinder) + Offset(i % 100 - 50, i % 50 - 25));
      }

      await tester.pump();
      await gesture.removePointer();

      // Assert: No exceptions thrown (would indicate box.dart or mouse_tracker errors)
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);
    });
  });
}
