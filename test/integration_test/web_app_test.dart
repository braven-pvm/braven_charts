import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import the example app
import 'package:braven_charts_example/main.dart' as app;

/// ChromeDriver integration test for zoom functionality
/// This test runs in a REAL Chrome browser using ChromeDriver
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real Browser Zoom Tests', () {
    testWidgets('Test keyboard zoom in real Chrome browser',
        (WidgetTester tester) async {
      print('\n🧪 ========== REAL BROWSER KEYBOARD ZOOM TEST ==========');

      // Launch the actual example app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('🧪 TEST: Example app launched in Chrome');

      // Find and tap "Simple Zoom Test" card
      final simpleZoomTestFinder = find.text('🎯 Simple Zoom Test');
      expect(simpleZoomTestFinder, findsOneWidget,
          reason: 'Simple Zoom Test card should be visible');
      print('🧪 TEST: Found Simple Zoom Test card');

      await tester.tap(simpleZoomTestFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('🧪 TEST: Navigated to Simple Zoom Test screen');

      // Wait for chart to render
      await tester.pump(const Duration(milliseconds: 500));

      // Find the chart - look for the SizedBox container
      final chartContainer = find.byType(SizedBox).first;
      expect(chartContainer, findsOneWidget);
      print('🧪 TEST: Found chart container');

      // Tap the chart to give it focus
      await tester.tap(chartContainer);
      await tester.pumpAndSettle();
      print('🧪 TEST: Tapped chart to give focus');

      // Wait for focus to be established
      await tester.pump(const Duration(milliseconds: 500));

      // Test Numpad Add (zoom in)
      print('\n🧪 TEST: Testing keyboard zoom with Numpad Add...');
      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pump(const Duration(milliseconds: 200));
        print('🧪 TEST: Sent Numpad Add #${i + 1}');
      }

      await tester.pumpAndSettle();
      print('🧪 TEST: Keyboard zoom in completed');

      // Verify chart is still visible
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets,
          reason: 'Chart should still be rendered after keyboard zoom');
      print('🧪 TEST: ✅ Chart is still rendered after keyboard zoom');

      // Test Numpad Subtract (zoom out)
      print('\n🧪 TEST: Testing keyboard zoom with Numpad Subtract...');
      for (int i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadSubtract);
        await tester.pump(const Duration(milliseconds: 200));
        print('🧪 TEST: Sent Numpad Subtract #${i + 1}');
      }

      await tester.pumpAndSettle();
      print('🧪 TEST: Keyboard zoom out completed');

      // Verify chart is still visible
      expect(customPaintFinder, findsWidgets,
          reason: 'Chart should still be rendered after zoom out');
      print('🧪 TEST: ✅ Chart is still rendered after zoom out');

      print('🧪 ========== END KEYBOARD ZOOM TEST ==========\n');
    });

    testWidgets('Test SHIFT+scroll zoom in real Chrome browser',
        (WidgetTester tester) async {
      print('\n🧪 ========== REAL BROWSER SHIFT+SCROLL ZOOM TEST ==========');

      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('🧪 TEST: Example app launched in Chrome');

      // Navigate to Simple Zoom Test
      final simpleZoomTestFinder = find.text('🎯 Simple Zoom Test');
      await tester.tap(simpleZoomTestFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('🧪 TEST: Navigated to Simple Zoom Test screen');

      // Wait for chart to render
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap the chart
      final chartContainer = find.byType(SizedBox).first;
      await tester.tap(chartContainer);
      await tester.pumpAndSettle();
      print('🧪 TEST: Tapped chart to give focus');

      // Wait for focus
      await tester.pump(const Duration(milliseconds: 500));

      // Get the center of the chart
      final Offset chartCenter = tester.getCenter(chartContainer);
      print('🧪 TEST: Chart center: $chartCenter');

      // Press and hold SHIFT
      print('\n🧪 TEST: Pressing SHIFT key...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 200));
      print('🧪 TEST: SHIFT key is down');

      // Send scroll events (zoom in)
      print('\n🧪 TEST: Sending scroll events while SHIFT is held...');
      for (int i = 0; i < 3; i++) {
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        pointer.hover(chartCenter);

        // Scroll down (negative delta) = zoom in
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, -20)),
        );

        await tester.pump(const Duration(milliseconds: 200));
        print('🧪 TEST: Sent scroll event #${i + 1}');

        // Check if chart is still visible after each scroll
        final customPaintFinder = find.byType(CustomPaint);
        final paintCount = tester.widgetList(customPaintFinder).length;
        print('🧪 TEST: CustomPaint widgets found: $paintCount');
      }

      await tester.pumpAndSettle();

      // Release SHIFT
      print('\n🧪 TEST: Releasing SHIFT key...');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      print('🧪 TEST: SHIFT key released');

      // Verify chart is still rendered
      final customPaintFinder = find.byType(CustomPaint);
      final paintCount = tester.widgetList(customPaintFinder).length;
      print('🧪 TEST: Final CustomPaint widgets found: $paintCount');

      if (paintCount > 0) {
        print('🧪 TEST: ✅ Chart is still rendered after SHIFT+scroll zoom');
      } else {
        print('🧪 TEST: ❌ Chart disappeared after SHIFT+scroll zoom!');
      }

      expect(customPaintFinder, findsWidgets,
          reason: 'Chart should still be rendered after SHIFT+scroll zoom');

      print('🧪 ========== END SHIFT+SCROLL ZOOM TEST ==========\n');
    });

    testWidgets('Test visual zoom behavior in real browser',
        (WidgetTester tester) async {
      print('\n🧪 ========== REAL BROWSER VISUAL ZOOM TEST ==========');

      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Simple Zoom Test
      final simpleZoomTestFinder = find.text('🎯 Simple Zoom Test');
      await tester.tap(simpleZoomTestFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('🧪 TEST: Navigated to Simple Zoom Test screen');

      // Initial state check
      final customPaintFinder = find.byType(CustomPaint);
      final initialPaintCount = tester.widgetList(customPaintFinder).length;
      print('🧪 TEST: Initial CustomPaint widgets: $initialPaintCount');

      // Tap chart
      final chartContainer = find.byType(SizedBox).first;
      await tester.tap(chartContainer);
      await tester.pumpAndSettle();

      // Keyboard zoom test
      print('\n🧪 TEST: Testing keyboard zoom visual behavior...');
      for (int i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pump(const Duration(milliseconds: 150));

        final paintCount = tester.widgetList(customPaintFinder).length;
        print('🧪 TEST: After zoom #${i + 1}, CustomPaint count: $paintCount');
      }

      await tester.pumpAndSettle();

      final afterKeyboardZoomCount =
          tester.widgetList(customPaintFinder).length;
      print(
          '🧪 TEST: After keyboard zoom, CustomPaint widgets: $afterKeyboardZoomCount');

      expect(afterKeyboardZoomCount, greaterThan(0),
          reason: 'Chart should still be rendered after keyboard zoom');

      // SHIFT+scroll zoom test
      print('\n🧪 TEST: Testing SHIFT+scroll visual behavior...');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 200));

      final chartCenter = tester.getCenter(chartContainer);

      for (int i = 0; i < 3; i++) {
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        pointer.hover(chartCenter);
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, -20)));
        await tester.pump(const Duration(milliseconds: 150));

        final paintCount = tester.widgetList(customPaintFinder).length;
        print(
            '🧪 TEST: After scroll #${i + 1}, CustomPaint count: $paintCount');

        if (paintCount == 0) {
          print('🧪 TEST: ⚠️ WARNING: Chart disappeared during scroll!');
          break;
        }
      }

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      final finalPaintCount = tester.widgetList(customPaintFinder).length;
      print('🧪 TEST: Final CustomPaint widgets: $finalPaintCount');

      if (finalPaintCount > 0) {
        print('🧪 TEST: ✅ Chart remained visible throughout test');
      } else {
        print('🧪 TEST: ❌ Chart disappeared during SHIFT+scroll!');
      }

      print('🧪 ========== END VISUAL ZOOM TEST ==========\n');
    });
  });
}
