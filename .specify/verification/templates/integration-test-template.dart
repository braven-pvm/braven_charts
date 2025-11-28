/// INTEGRATION TEST TEMPLATE
/// 
/// Copy this template when creating new integration tests for visual verification.
/// 
/// SCREENSHOT MANIFEST for Task T###
/// 
/// This test produces the following screenshots:
/// - T###_[testname]_01_initial_state.png - [Description]
/// - T###_[testname]_02_[step].png - [Description]
/// - T###_[testname]_03_final_state.png - [Description]
/// 
/// Screenshots saved to: example/screenshots/
/// 
/// VERIFICATION: Compare against expected behavior in spec.md Section X.X
/// 
/// Links to Task: T###
/// Spec Reference: spec.md Section X.X
/// Expected Screenshots: X
/// Screenshot Location: example/screenshots/T###_*.png

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/main.dart' as app;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Whether to include human-observable pauses (set via --dart-define=PROOF_PAUSES=true/false)
const bool showProofPauses =
    bool.fromEnvironment('PROOF_PAUSES', defaultValue: true);

/// Pause for visual verification (only when PROOF_PAUSES=true)
Future<void> proofPause(Duration duration) async {
  if (showProofPauses) {
    await Future.delayed(duration);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // TASK IDENTIFICATION - Update these for each task
  // ============================================================
  const String taskId = 'T###'; // e.g., 'T015'
  const String testName = 'feature_test'; // e.g., 'zoom_test'
  const String taskDescription = 'Description of what this test verifies';

  // ============================================================
  // SCREENSHOT HELPER
  // ============================================================
  Future<void> takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding,
    int step,
    String description,
  ) async {
    final screenshotName = '${taskId}_${testName}_${step.toString().padLeft(2, '0')}_$description';
    try {
      await binding.takeScreenshot(screenshotName);
      print('📸 Screenshot saved: $screenshotName.png');
    } catch (e) {
      print('⚠️  Screenshot failed: $e');
    }
  }

  group('$taskId: $taskDescription', () {
    testWidgets('$taskId: Full integration test with screenshots',
        (WidgetTester tester) async {
      print('\n🧪 ========== $taskId: $taskDescription ==========');

      // ============================================================
      // STEP 1: Launch app and capture initial state
      // ============================================================
      print('\n📸 STEP 1: Launching app...');
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await takeScreenshot(binding, 1, 'initial_state');
      print('✅ STEP 1 COMPLETE: App launched');
      await proofPause(const Duration(seconds: 2));

      // ============================================================
      // STEP 2: Navigate to target screen (customize as needed)
      // ============================================================
      print('\n📸 STEP 2: Navigating to target screen...');

      // Example: Find and tap a navigation element
      // final targetFinder = find.text('Target Screen');
      // if (tester.any(targetFinder)) {
      //   await tester.tap(targetFinder);
      //   await tester.pumpAndSettle();
      // }

      await takeScreenshot(binding, 2, 'target_screen');
      print('✅ STEP 2 COMPLETE: Navigated to target');
      await proofPause(const Duration(seconds: 2));

      // ============================================================
      // STEP 3: Perform interaction (customize as needed)
      // ============================================================
      print('\n📸 STEP 3: Performing interaction...');

      // Example: Find the widget to interact with
      final widgetFinder = find.byType(BravenChart);
      expect(widgetFinder, findsOneWidget, reason: 'Target widget must exist');

      final widgetCenter = tester.getCenter(widgetFinder);
      print('  📍 Widget center: $widgetCenter');

      // Example: Mouse interaction
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.moveTo(widgetCenter);
      await tester.pumpAndSettle();

      // Example: Keyboard interaction
      // await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      // await tester.pumpAndSettle();

      await takeScreenshot(binding, 3, 'after_interaction');
      print('✅ STEP 3 COMPLETE: Interaction performed');
      await proofPause(const Duration(seconds: 2));

      // Clean up gesture
      await gesture.removePointer();

      // ============================================================
      // STEP 4: Verify expected state
      // ============================================================
      print('\n📸 STEP 4: Verifying expected state...');

      // IMPORTANT: Use meaningful assertions, NOT just findsOneWidget
      // ❌ BAD:  expect(find.byType(Widget), findsOneWidget);
      // ✅ GOOD: expect(controller.zoomLevel, greaterThan(1.0));
      // ✅ GOOD: expect(find.text('Expected Label'), findsOneWidget);

      // Example assertions:
      expect(widgetFinder, findsOneWidget, reason: 'Widget should still exist');

      // Add your specific verification assertions here:
      // expect(someController.someProperty, expectedValue);

      await takeScreenshot(binding, 4, 'final_state');
      print('✅ STEP 4 COMPLETE: State verified');

      // ============================================================
      // STEP 5: Final summary
      // ============================================================
      print('\n${'=' * 60}');
      print('🎉 $taskId TEST COMPLETE');
      print('   Screenshots captured: 4');
      print('   Location: example/screenshots/$taskId_$testName_*.png');
      print('=' * 60);

      // Keep browser open for manual inspection (when pauses enabled)
      if (showProofPauses) {
        print('\n⏱️  Keeping browser open for 30 seconds for inspection...');
        await proofPause(const Duration(seconds: 30));
      }

      print('\n🧪 ========== END $taskId ==========\n');
    });
  });
}
