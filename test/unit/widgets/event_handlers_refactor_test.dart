import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event Handler ValueNotifier Refactoring', () {
    Widget buildTestChart() {
      return MaterialApp(
        home: Scaffold(
          body: BravenChart(
            chartType: ChartType.line,
            series: [
              ChartSeries(
                id: 'test',
                points: List.generate(
                  50,
                  (i) => ChartDataPoint(x: i.toDouble(), y: (i * 2).toDouble()),
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
    }

    testWidgets('T012: onHover updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Hover over chart
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: chartCenter);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(chartCenter + const Offset(10, 10));
      await tester.pump();

      // Assert: No crashes, chart still renders
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T013: onExit updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Hover then exit chart
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: chartCenter);
      await gesture.moveTo(chartCenter + const Offset(10, 10));
      await tester.pump();

      // Move outside chart bounds
      await gesture.moveTo(const Offset(0, 0));
      await tester.pump();
      await gesture.removePointer();

      // Assert: No crashes
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T014: onPointerDown updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Pointer down (middle mouse)
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder, buttons: kMiddleMouseButton);
      await tester.pump();

      // Assert: No crashes
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T015: onPointerUp updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Pointer down then up
      final chartFinder = find.byType(BravenChart);
      final gesture = await tester.startGesture(tester.getCenter(chartFinder), buttons: kMiddleMouseButton);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Assert: No crashes
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T016: onPointerMove updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Drag with middle mouse
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      await tester.drag(chartFinder, const Offset(50, 50), kind: PointerDeviceKind.mouse, buttons: kMiddleMouseButton);
      await tester.pump();

      // Assert: No crashes
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('T017: onPointerSignal (zoom) updates notifier without crashing', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestChart());
      await tester.pumpAndSettle();

      // Act: Simulate scroll event (zoom)
      final chartFinder = find.byType(BravenChart);
      final chartCenter = tester.getCenter(chartFinder);

      // Simulate scroll wheel with SHIFT held
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(chartCenter));
      await tester.sendEventToBinding(
        pointer.scroll(const Offset(0, 20)), // Scroll down
      );
      await tester.pump();

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      // Assert: No crashes
      expect(find.byType(BravenChart), findsOneWidget);
    });
  });
}
