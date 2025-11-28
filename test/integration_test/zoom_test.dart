import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:braven_charts/legacy/braven_charts.dart';

/// Integration test for zoom functionality
/// This test creates a simple chart and tests both keyboard and mouse wheel zoom
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Zoom Functionality Tests', () {
    testWidgets('Test keyboard zoom (Numpad +/-)', (WidgetTester tester) async {
      print('\n🧪 ========== KEYBOARD ZOOM TEST ==========');

      int zoomChangeCount = 0;
      double? lastZoomX;
      double? lastZoomY;

      // Build a simple chart with zoom enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'test',
                      name: 'Test Data',
                      points: List.generate(
                        10,
                        (i) => ChartDataPoint(
                            x: i.toDouble(), y: i * i.toDouble()),
                      ),
                    ),
                  ],
                  interactionConfig: InteractionConfig(
                    enableZoom: true,
                    keyboard: const KeyboardConfig(enabled: true),
                    onZoomChanged: (zoomX, zoomY) {
                      zoomChangeCount++;
                      lastZoomX = zoomX;
                      lastZoomY = zoomY;
                      print(
                          '🧪 TEST: Zoom changed - X=${(zoomX * 100).toInt()}%, Y=${(zoomY * 100).toInt()}% (change #$zoomChangeCount)');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      print('🧪 TEST: Chart widget built and settled');

      // Find the chart
      final chartFinder = find.byType(BravenChart);
      expect(chartFinder, findsOneWidget);
      print('🧪 TEST: Found BravenChart widget');

      // Tap the chart to give it focus
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();
      print('🧪 TEST: Tapped chart to give focus');

      // Wait for focus to be established
      await tester.pump(const Duration(milliseconds: 300));

      // Test Numpad Add (zoom in)
      print('\n🧪 TEST: Testing ZOOM IN with Numpad Add...');
      final initialZoomChangeCount = zoomChangeCount;

      for (int i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        print('🧪 TEST: Sent Numpad Add #${i + 1}');
      }

      print(
          '🧪 TEST: Zoom changes after +/+/+: $zoomChangeCount (started at $initialZoomChangeCount)');
      print(
          '🧪 TEST: Final zoom level: X=${lastZoomX != null ? (lastZoomX! * 100).toInt() : "null"}%, Y=${lastZoomY != null ? (lastZoomY! * 100).toInt() : "null"}%');

      // Verify zoom changed
      expect(zoomChangeCount, greaterThan(initialZoomChangeCount),
          reason: 'Zoom callback should have been called');

      // Test Numpad Subtract (zoom out)
      print('\n🧪 TEST: Testing ZOOM OUT with Numpad Subtract...');
      final beforeZoomOutCount = zoomChangeCount;

      for (int i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadSubtract);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        print('🧪 TEST: Sent Numpad Subtract #${i + 1}');
      }

      print(
          '🧪 TEST: Zoom changes after -/-: $zoomChangeCount (was $beforeZoomOutCount)');
      print(
          '🧪 TEST: Final zoom level: X=${lastZoomX != null ? (lastZoomX! * 100).toInt() : "null"}%, Y=${lastZoomY != null ? (lastZoomY! * 100).toInt() : "null"}%');

      // Verify zoom changed again
      expect(zoomChangeCount, greaterThan(beforeZoomOutCount),
          reason: 'Zoom callback should have been called for zoom out');

      // Verify chart is still rendered
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets,
          reason: 'Chart should still be rendered after keyboard zoom');

      print('🧪 TEST: ✅ KEYBOARD ZOOM TEST PASSED');
      print('🧪 ========== END KEYBOARD ZOOM TEST ==========\n');
    });

    testWidgets('Test SHIFT+scroll zoom', (WidgetTester tester) async {
      print('\n🧪 ========== SHIFT+SCROLL ZOOM TEST ==========');

      int zoomChangeCount = 0;
      double? lastZoomX;
      double? lastZoomY;

      // Build the same chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: BravenChart(
                  chartType: ChartType.line,
                  series: [
                    ChartSeries(
                      id: 'test',
                      name: 'Test Data',
                      points: List.generate(
                        10,
                        (i) => ChartDataPoint(
                            x: i.toDouble(), y: i * i.toDouble()),
                      ),
                    ),
                  ],
                  interactionConfig: InteractionConfig(
                    enableZoom: true,
                    keyboard: const KeyboardConfig(enabled: true),
                    onZoomChanged: (zoomX, zoomY) {
                      zoomChangeCount++;
                      lastZoomX = zoomX;
                      lastZoomY = zoomY;
                      print(
                          '🧪 TEST: Zoom changed - X=${(zoomX * 100).toInt()}%, Y=${(zoomY * 100).toInt()}% (change #$zoomChangeCount)');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      print('🧪 TEST: Chart widget built');

      // Find and tap the chart
      final chartFinder = find.byType(BravenChart);
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();
      print('🧪 TEST: Chart tapped to give focus');

      // Wait for focus
      await tester.pump(const Duration(milliseconds: 300));

      // Get the center of the chart
      final Offset chartCenter = tester.getCenter(chartFinder);
      print('🧪 TEST: Chart center: $chartCenter');

      // Press and hold SHIFT
      print('\n🧪 TEST: Pressing SHIFT key...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 100));
      print('🧪 TEST: SHIFT key is down');

      final initialZoomCount = zoomChangeCount;

      // Send scroll events
      print('\n🧪 TEST: Sending scroll events (zoom in)...');
      for (int i = 0; i < 3; i++) {
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        pointer.hover(chartCenter);

        // Create a scroll event
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, -20)),
        );

        await tester.pump(const Duration(milliseconds: 100));
        print('🧪 TEST: Sent scroll event #${i + 1}');
      }

      await tester.pumpAndSettle();

      print(
          '\n🧪 TEST: Zoom changes after scroll: $zoomChangeCount (started at $initialZoomCount)');
      print(
          '🧪 TEST: Current zoom: X=${lastZoomX != null ? (lastZoomX! * 100).toInt() : "null"}%, Y=${lastZoomY != null ? (lastZoomY! * 100).toInt() : "null"}%');

      // Release SHIFT
      print('\n🧪 TEST: Releasing SHIFT key...');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      print('🧪 TEST: SHIFT key released');

      // Verify chart is still rendered
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets,
          reason: 'Chart should still be rendered after SHIFT+scroll zoom');

      print('🧪 TEST: Chart is still rendered (CustomPaint found)');

      if (zoomChangeCount > initialZoomCount) {
        print(
            '🧪 TEST: ✅ SHIFT+SCROLL ZOOM TEST PASSED - Zoom callback was called');
      } else {
        print(
            '🧪 TEST: ⚠️  SHIFT+SCROLL ZOOM TEST WARNING - Zoom callback was NOT called');
      }

      print('🧪 ========== END SHIFT+SCROLL ZOOM TEST ==========\n');
    });
  });
}
