// Integration test for incremental keyboard zoom debugging
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// INCREMENTAL KEYBOARD ZOOM TEST
/// Tests keyboard zoom one step at a time with screenshots to debug the zoom issue
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Incremental Keyboard Zoom Test', () {
    testWidgets('Zoom incrementally and capture screenshots at each step', (WidgetTester tester) async {
      print('\n🔬 ========== INCREMENTAL KEYBOARD ZOOM DEBUG TEST ==========');
      print('Purpose: Test keyboard zoom step-by-step to identify when chart data disappears\n');

      // ========== SETUP ==========
      print('📋 SETUP: Launching app and navigating to Simple Zoom Test...');
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Simple Zoom Test
      final simpleZoomTextFinder = find.text('🎯 Simple Zoom Test');
      await tester.scrollUntilVisible(
        simpleZoomTextFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap to navigate
      final inkWellFinder = find.ancestor(
        of: simpleZoomTextFinder,
        matching: find.byType(InkWell),
      );
      await tester.tap(inkWellFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and focus the chart
      final chartFinder = find.byType(BravenChart);
      expect(tester.any(chartFinder), true, reason: 'BravenChart should be visible');

      // TAP AND REQUEST FOCUS
      await tester.tap(chartFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // EXPLICITLY REQUEST FOCUS on the Focus widget
      final focusFinder = find.byType(Focus);
      if (tester.any(focusFinder)) {
        print('🎯 Found Focus widget, requesting focus explicitly...');
        // Get the element and request focus
        final focusElement = tester.element(focusFinder);
        FocusScope.of(focusElement).requestFocus();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // VERIFY FOCUS with a test key event
      print('🔍 Testing keyboard focus...');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.pumpAndSettle(const Duration(seconds: 1));

      print('✅ SETUP COMPLETE: Chart is ready and focused\n');

      // ========== BASELINE SCREENSHOT ==========
      print('📸 STEP 0: Taking BASELINE screenshot (no zoom)...');
      await tester.pumpAndSettle();
      await binding.takeScreenshot('keyboard_zoom_0_baseline');
      print('   ✅ Baseline screenshot saved: keyboard_zoom_0_baseline.png');
      print('   📊 Expected: Chart with data visible at 100% zoom\n');
      await Future.delayed(const Duration(seconds: 1));

      // ========== ZOOM TEST 1: Single Zoom ==========
      print('📸 STEP 1: Zooming ONCE with Numpad Add (+)...');
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final customPaintFinder = find.byType(CustomPaint);
      final paintCount1 = tester.widgetList(customPaintFinder).length;

      await binding.takeScreenshot('keyboard_zoom_1_single');
      print('   ✅ Screenshot saved: keyboard_zoom_1_single.png');
      print('   📊 CustomPaint count: $paintCount1');
      print('   📊 Expected: Chart zoomed slightly, data still visible\n');
      await Future.delayed(const Duration(seconds: 1));

      // ========== ZOOM TEST 2: Two More Zooms ==========
      print('📸 STEP 2: Zooming TWO more times (total 3 zooms)...');

      // Zoom #2
      print('   🔹 Zoom #2...');
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await binding.takeScreenshot('keyboard_zoom_2_second');
      final paintCount2 = tester.widgetList(customPaintFinder).length;
      print('      ✅ Screenshot saved: keyboard_zoom_2_second.png');
      print('      📊 CustomPaint count: $paintCount2\n');
      await Future.delayed(const Duration(milliseconds: 500));

      // Zoom #3
      print('   🔹 Zoom #3...');
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await binding.takeScreenshot('keyboard_zoom_3_third');
      final paintCount3 = tester.widgetList(customPaintFinder).length;
      print('      ✅ Screenshot saved: keyboard_zoom_3_third.png');
      print('      📊 CustomPaint count: $paintCount3');
      print('      📊 Expected: Chart more zoomed, data should still be visible\n');
      await Future.delayed(const Duration(seconds: 1));

      // ========== ZOOM TEST 3: Three More Zooms ==========
      print('📸 STEP 3: Zooming THREE more times (total 6 zooms)...');

      for (int i = 4; i <= 6; i++) {
        print('   🔹 Zoom #$i...');
        await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await binding.takeScreenshot('keyboard_zoom_${i}_zoom$i');
        final paintCount = tester.widgetList(customPaintFinder).length;
        print('      ✅ Screenshot saved: keyboard_zoom_${i}_zoom$i.png');
        print('      📊 CustomPaint count: $paintCount\n');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final finalPaintCount = tester.widgetList(customPaintFinder).length;

      // ========== SUMMARY ==========
      print('\n${'=' * 70}');
      print('📊 TEST SUMMARY:');
      print('   - Total zoom operations: 6');
      print('   - Screenshots captured: 7 (baseline + 6 zoom states)');
      print('   - Final CustomPaint count: $finalPaintCount');
      print('   - CustomPaint count remained stable: ${paintCount1 == finalPaintCount}');
      print('=' * 70);

      print('\n📁 All screenshots saved to: example/screenshots/');
      print('   Review them to identify when/if chart data disappears!\n');

      // Keep browser open for inspection
      print('⏱️  Keeping browser open for 30 seconds for visual inspection...');
      await Future.delayed(const Duration(seconds: 30));

      print('\n🔬 ========== TEST COMPLETE ==========\n');
    });
  });
}

