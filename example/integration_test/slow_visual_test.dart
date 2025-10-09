// Import the example app
import 'package:braven_charts_example/main.dart' as app;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// SLOW VISIBLE ChromeDriver integration test
/// This test runs SLOWLY with long delays so you can watch what's happening
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SLOW VISIBLE Zoom Tests', () {
    testWidgets('SLOW test - watch the browser!', (WidgetTester tester) async {
      print('\n🧪 ========== SLOW VISIBLE TEST - WATCH THE BROWSER! ==========');
      print('🧪 This test runs SLOWLY so you can see what\'s happening');

      // Launch the actual example app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      print('🧪 TEST: App launched - YOU SHOULD SEE IT NOW!');
      await Future.delayed(const Duration(seconds: 2));

      // Find and tap "Simple Zoom Test" card
      final simpleZoomTestFinder = find.text('🎯 Simple Zoom Test');
      expect(simpleZoomTestFinder, findsOneWidget);
      print('🧪 TEST: Found Simple Zoom Test card - WATCH IT GET CLICKED!');
      await Future.delayed(const Duration(seconds: 2));

      await tester.tap(simpleZoomTestFinder, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('🧪 TEST: Navigated to Simple Zoom Test screen');
      await Future.delayed(const Duration(seconds: 2));

      // Find and tap the chart
      final chartContainer = find.byType(SizedBox).first;
      print('🧪 TEST: TAPPING CHART NOW - WATCH!');
      await Future.delayed(const Duration(seconds: 1));
      await tester.tap(chartContainer);
      await tester.pumpAndSettle();
      print('🧪 TEST: Chart tapped - focus requested');
      await Future.delayed(const Duration(seconds: 2));

      // Test Numpad Add (zoom in) - SLOWLY
      print('\n🧪 TEST: STARTING KEYBOARD ZOOM - WATCH THE CHART ZOOM IN!');
      await Future.delayed(const Duration(seconds: 2));

      for (int i = 0; i < 5; i++) {
        print('🧪 TEST: Pressing Numpad Add #${i + 1} - WATCH ZOOM!');
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pump(const Duration(milliseconds: 500));
        await Future.delayed(const Duration(seconds: 1));
      }

      await tester.pumpAndSettle();
      print('🧪 TEST: Keyboard zoom completed - DID YOU SEE IT ZOOM?');
      await Future.delayed(const Duration(seconds: 3));

      // Verify chart is still visible
      final customPaintFinder = find.byType(CustomPaint);
      final paintCount1 = tester.widgetList(customPaintFinder).length;
      print('🧪 TEST: Chart CustomPaint widgets after keyboard zoom: $paintCount1');
      expect(customPaintFinder, findsWidgets, reason: 'Chart should still be rendered after keyboard zoom');

      // Now test SHIFT+scroll - SLOWLY
      print('\n🧪 TEST: NOW TESTING SHIFT+SCROLL - WATCH CAREFULLY!');
      await Future.delayed(const Duration(seconds: 3));

      final chartCenter = tester.getCenter(chartContainer);
      print('🧪 TEST: Chart center: $chartCenter');

      print('🧪 TEST: PRESSING SHIFT KEY NOW...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(seconds: 2));
      print('🧪 TEST: SHIFT is DOWN - now sending scroll events...');

      for (int i = 0; i < 5; i++) {
        print('🧪 TEST: SCROLL EVENT #${i + 1} - WATCH THE CHART!');
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        pointer.hover(chartCenter);
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, -20)));
        await tester.pump(const Duration(milliseconds: 500));
        await Future.delayed(const Duration(seconds: 1));

        final paintCount = tester.widgetList(customPaintFinder).length;
        print('🧪 TEST: After scroll #${i + 1}, CustomPaint count: $paintCount');
      }

      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 TEST: RELEASING SHIFT...');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // Final check
      final finalPaintCount = tester.widgetList(customPaintFinder).length;
      print('🧪 TEST: FINAL CustomPaint widgets: $finalPaintCount');

      if (finalPaintCount > 0) {
        print('🧪 TEST: ✅ CHART IS STILL VISIBLE!');
      } else {
        print('🧪 TEST: ❌ CHART DISAPPEARED!');
      }

      expect(customPaintFinder, findsWidgets, reason: 'Chart should still be rendered');

      print('\n🧪 TEST: KEEPING BROWSER OPEN FOR 5 SECONDS...');
      await Future.delayed(const Duration(seconds: 5));

      print('🧪 ========== END SLOW VISIBLE TEST ==========\n');
    });
  });
}
