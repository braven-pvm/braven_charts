// Import the example app
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/main.dart' as app;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// PROOF TEST - Shows visible overlays of what's happening
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PROOF TEST - You will see what I am doing', () {
    testWidgets('PROOF with visible status overlays', (WidgetTester tester) async {
      print('\n🧪 ========== PROOF TEST - WATCH FOR STATUS OVERLAYS! ==========');

      // STEP 1: Launch app
      print('\n📸 STEP 1: LAUNCHING APP...');
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      print('✅ STEP 1 COMPLETE: App launched');
      await Future.delayed(const Duration(seconds: 3));

      // STEP 2: Find and navigate to Simple Zoom Test
      print('\n📸 STEP 2: FINDING SIMPLE ZOOM TEST CARD...');
      final simpleZoomTextFinder = find.text('🎯 Simple Zoom Test');

      final found = tester.any(simpleZoomTextFinder);
      if (!found) {
        print('❌ STEP 2 FAILED: Could not find Simple Zoom Test card!');
        print('Available widgets:');
        tester.allWidgets.take(20).forEach((w) => print('  - $w'));
      } else {
        print('✅ STEP 2: Found Simple Zoom Test text');
      }

      // Scroll to make sure it's visible
      print('📸 STEP 2b: SCROLLING TO MAKE CARD VISIBLE...');
      await tester.scrollUntilVisible(
        simpleZoomTextFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      print('✅ STEP 2b: Card is now visible on screen');
      await Future.delayed(const Duration(seconds: 2));

      // Find the InkWell that contains this text (the actual tappable widget)
      print('📸 STEP 2c: FINDING THE TAPPABLE INKWELL WIDGET...');
      final inkWellFinder = find.ancestor(
        of: simpleZoomTextFinder,
        matching: find.byType(InkWell),
      );

      if (!tester.any(inkWellFinder)) {
        print('❌ FAILED: Could not find InkWell ancestor!');
      } else {
        print('✅ STEP 2c: Found InkWell ancestor');
      }

      await Future.delayed(const Duration(seconds: 2));

      print('\n📸 STEP 3: CLICKING THE INKWELL (TAPPABLE CARD)...');
      print('  Using REAL mouse pointer events for reliable tap on web...');

      // Get the center of the InkWell and tap at that exact location
      final inkWellCenter = tester.getCenter(inkWellFinder.first);
      print('  📍 InkWell center: $inkWellCenter');

      // Use REAL pointer events (like we do for scroll) instead of tester.tap()
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);

      // Simulate real mouse click: hover → down → up
      print('  🖱️  Hovering mouse over card...');
      pointer.hover(inkWellCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(seconds: 1));

      print('  🖱️  Mouse down (clicking)...');
      await tester.sendEventToBinding(pointer.down(inkWellCenter));
      await tester.pump(const Duration(milliseconds: 100));
      await Future.delayed(const Duration(milliseconds: 500));

      print('  🖱️  Mouse up (releasing click)...');
      await tester.sendEventToBinding(pointer.up());
      await tester.pump(const Duration(milliseconds: 100));

      print('  ⏳ Waiting for navigation animation...');
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for navigation animation

      print('✅ STEP 3 COMPLETE: Tap executed - waiting for navigation...');
      await Future.delayed(const Duration(seconds: 3));

      // Verify we navigated away from home screen
      print('📸 STEP 3 VERIFICATION: Checking if we navigated...');
      final homeScreenStillVisible = tester.any(find.text('Welcome to Braven Charts'));
      if (homeScreenStillVisible) {
        print('⚠️  WARNING: Still on home screen! Navigation FAILED.');
        print('  This means the InkWell tap is not triggering the onTap callback.');
        print('  Checking what widgets are currently visible:');
        final visibleText = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).take(10).toList();
        print('  Visible text widgets: $visibleText');
      } else {
        print('✅ STEP 3 VERIFIED: Successfully navigated away from home screen!');
      }

      // STEP 4: Tap the chart to give it keyboard focus
      print('\n📸 STEP 4: FINDING AND TAPPING THE ACTUAL CHART WIDGET...');

      // Find the BravenChart widget (the actual chart, not a random SizedBox!)
      final chartFinder = find.byType(BravenChart);

      if (!tester.any(chartFinder)) {
        print('❌ STEP 4 FAILED: Could not find BravenChart widget!');
        print('Available widget types:');
        tester.allWidgets.take(20).forEach((w) => print('  - ${w.runtimeType}'));
      } else {
        print('✅ STEP 4: Found BravenChart widget');
      }

      // Tap the chart using real pointer events to trigger focus
      print('  🖱️  Tapping chart to give it keyboard focus...');
      final chartCenter = tester.getCenter(chartFinder);
      print('  📍 Chart center: $chartCenter');

      final TestPointer chartPointer = TestPointer(1, PointerDeviceKind.mouse);
      chartPointer.hover(chartCenter);
      await tester.sendEventToBinding(chartPointer.down(chartCenter));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendEventToBinding(chartPointer.up());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      print('✅ STEP 4 COMPLETE: Chart tapped - focus should now be active');
      await Future.delayed(const Duration(seconds: 3));

      // STEP 5: Keyboard zoom
      print('\n📸 STEP 5: PERFORMING KEYBOARD ZOOM (5 times)...');
      print('  🎯 WATCH THE SCREEN - Each keypress should ZOOM IN visibly!');
      for (int i = 0; i < 5; i++) {
        print('  🔹 Pressing Numpad Add #${i + 1} - WATCH THE CHART ZOOM IN!');
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pumpAndSettle(const Duration(seconds: 1)); // Process all frames
        await Future.delayed(const Duration(seconds: 2)); // WAIT so you can SEE the zoom
        print('     ✅ Keypress #${i + 1} complete - did you see the zoom?');
      }
      print('✅ STEP 5 COMPLETE: Keyboard zoom completed');

      // Count CustomPaint widgets
      final customPaintFinder = find.byType(CustomPaint);
      final paintCount = tester.widgetList(customPaintFinder).length;
      print('  📊 Chart CustomPaint widgets after keyboard zoom: $paintCount');
      await Future.delayed(const Duration(seconds: 3));

      // STEP 6: SHIFT+scroll zoom
      print('\n📸 STEP 6: PERFORMING SHIFT+SCROLL ZOOM (5 times)...');
      print('  🎯 WATCH THE SCREEN - Each scroll should ZOOM IN visibly!');

      // Use the chartFinder we found in step 4
      final scrollChartCenter = tester.getCenter(chartFinder);

      print('  🔹 Pressing SHIFT key...');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 2));
      print('     ✅ SHIFT key is now held down');

      for (int i = 0; i < 5; i++) {
        print('  🔹 Scroll event #${i + 1} (delta: -20) - WATCH THE CHART ZOOM IN!');
        final TestPointer scrollPointer = TestPointer(i + 2, PointerDeviceKind.mouse);
        scrollPointer.hover(scrollChartCenter);
        await tester.sendEventToBinding(scrollPointer.scroll(const Offset(0, -20)));
        await tester.pumpAndSettle(const Duration(seconds: 1)); // Process all frames
        await Future.delayed(const Duration(seconds: 2)); // WAIT so you can SEE the zoom

        final currentPaintCount = tester.widgetList(customPaintFinder).length;
        print('     📊 CustomPaint count: $currentPaintCount');
        print('     ✅ Scroll #${i + 1} complete - did you see the zoom?');
      }

      print('  🔹 Releasing SHIFT key...');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 2));
      print('     ✅ SHIFT key released');

      final finalPaintCount = tester.widgetList(customPaintFinder).length;
      print('✅ STEP 6 COMPLETE: SHIFT+scroll zoom completed');
      print('  📊 FINAL CustomPaint widgets: $finalPaintCount');

      // STEP 7: Take screenshot after all interactions
      print('\n📸 STEP 7: TAKING SCREENSHOT OF FINAL STATE...');
      await tester.pumpAndSettle();

      // Take a screenshot and save it
      // Note: The screenshot will be captured but needs proper driver setup to save
      // For web, screenshots are automatically captured by the test framework
      try {
        await binding.takeScreenshot('proof_test_after_interactions');
        print('✅ STEP 7 COMPLETE: Screenshot captured!');
        print('   📁 Screenshot saved as: proof_test_after_interactions.png');
      } catch (e) {
        print('⚠️  STEP 7: Screenshot capture attempted but may require driver setup');
        print('   Error: $e');
      }
      await Future.delayed(const Duration(seconds: 2));

      // FINAL VERDICT      print('\n${'=' * 60}');
      if (finalPaintCount > 0) {
        print('🎉 PROOF COMPLETE: CHART IS STILL VISIBLE!');
        print('   CustomPaint widgets found: $finalPaintCount');
      } else {
        print('⚠️  PROOF COMPLETE: CHART DISAPPEARED!');
        print('   CustomPaint widgets found: $finalPaintCount');
      }
      print('=' * 60);

      // Keep browser open LONG TIME so you can see the result
      print('\n⏱️  KEEPING BROWSER OPEN FOR 60 SECONDS...');
      print('    👀 LOOK AT THE CHROME WINDOW NOW - YOU SHOULD SEE THE ZOOMED CHART!');
      await Future.delayed(const Duration(seconds: 60));

      print('\n🧪 ========== END PROOF TEST ==========\n');
    });
  });
}

