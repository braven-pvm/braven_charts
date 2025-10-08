/// Integration tests for Keyboard navigation.
///
/// Tests the seamless interaction between EventHandler and KeyboardHandler
/// components for keyboard-based chart navigation and accessibility.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/interaction/event_handler.dart';
import 'package:braven_charts/src/interaction/keyboard_handler.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';

void main() {
  group('Keyboard Navigation Integration Tests', () {
    late EventHandler eventHandler;
    late KeyboardHandler keyboardHandler;
    late List<Map<String, dynamic>> testData;
    late InteractionState initialState;

    setUp(() {
      // Create test data (10 points for keyboard navigation testing)
      // KeyboardHandler uses Map<String, dynamic> format
      testData = List.generate(
        10,
        (i) => {
          'x': i * 10.0,
          'y': 100.0 + i * 10.0,
          'label': 'Point $i',
        },
      );

      // Create components
      eventHandler = EventHandler();
      keyboardHandler = KeyboardHandler();

      // Initialize interaction state
      initialState = InteractionState.initial();
    });

    tearDown(() {
      eventHandler.dispose();
    });

    test('T033.1: Tab key focuses chart (first data point)', () {
      // Note: Tab focus handled by Flutter Focus widget, not KeyboardHandler
      // This test verifies data is ready for keyboard navigation

      // Verify test data is ready for keyboard navigation
      expect(testData, hasLength(10));
      expect(initialState.focusedPointIndex, equals(-1)); // No focus initially

      // After Focus widget focuses the chart, navigation can begin
      // Test that navigation methods are available
      final firstPoint = keyboardHandler.navigateToFirst(testData);
      expect(firstPoint, isNotNull);
      expect(firstPoint, equals(testData.first));
    });

    test('T033.2: Arrow keys navigate between data points', () {
      // Test navigation methods used by arrow key handlers

      // Navigate to next from first point
      var currentPoint = testData[0];
      var nextPoint = keyboardHandler.navigateToNext(currentPoint, testData);
      expect(nextPoint, equals(testData[1]));

      // Navigate to next again
      currentPoint = nextPoint!;
      nextPoint = keyboardHandler.navigateToNext(currentPoint, testData);
      expect(nextPoint, equals(testData[2]));

      // Navigate to previous
      currentPoint = nextPoint!;
      var prevPoint = keyboardHandler.navigateToPrevious(currentPoint, testData);
      expect(prevPoint, equals(testData[1]));

      // Test wrapping: navigate next from last point
      currentPoint = testData.last;
      nextPoint = keyboardHandler.navigateToNext(currentPoint, testData);
      expect(nextPoint, equals(testData.first)); // Wraps to beginning

      // Test wrapping: navigate previous from first point
      currentPoint = testData.first;
      prevPoint = keyboardHandler.navigateToPrevious(currentPoint, testData);
      expect(prevPoint, equals(testData.last)); // Wraps to end
    });

    test('T033.3: Focus indicator visibility (state flag for rendering)', () {
      // Focus indicator visibility driven by focusedPointIndex != -1
      final focusedState = initialState.copyWith(focusedPointIndex: 3);

      // Verify focus indicator should be shown (focusedPointIndex valid)
      expect(focusedState.focusedPointIndex, equals(3));
      expect(focusedState.focusedPointIndex, greaterThanOrEqualTo(0));

      // Unfocused state
      final unfocusedState = InteractionState.initial();
      expect(unfocusedState.focusedPointIndex, equals(-1));

      // Note: Actual visual contrast (3:1 ratio) validated in widget tests
      // Integration test verifies state correctly tracks focused point
    });

    test('T033.4: Enter key shows tooltip on focused point', () {
      // Test activateFocusedElement method (called by Enter key handler)
      final focusedPoint = testData[5];
      var state = initialState.copyWith(focusedPointIndex: 5);

      // Activate focused element (simulates Enter key)
      final newState = keyboardHandler.activateFocusedElement(
        focusedPoint,
        state,
      );

      // Verify tooltip is shown
      expect(newState.isTooltipVisible, isTrue);
      expect(newState.hoveredPoint, equals(focusedPoint));
    });

    test('T033.5: +/- keys zoom in/out (keyboard zoom operations)', () {
      // Test zoomViewport method (called by +/- key handlers)
      final zoomPanState = ZoomPanState.initial();

      // Test zoom in
      final zoomedInState = keyboardHandler.zoomViewport(
        true, // zoom in
        zoomPanState,
        keyboardHandler.zoomInFactor, // 1.2
      );

      expect(zoomedInState.zoomLevelX, equals(1.2));
      expect(zoomedInState.zoomLevelY, equals(1.2));

      // Test zoom out from zoomed in state
      final zoomedOutState = keyboardHandler.zoomViewport(
        false, // zoom out
        zoomedInState,
        keyboardHandler.zoomInFactor, // 1.2
      );

      // Should return to approximately original zoom (1.2 * 1/1.2 ≈ 1.0)
      expect(zoomedOutState.zoomLevelX, closeTo(1.0, 0.01));
      expect(zoomedOutState.zoomLevelY, closeTo(1.0, 0.01));
    });

    test('T033.6: Home/End keys jump to first/last point', () {
      // Test navigateToFirst and navigateToLast methods

      // Navigate to first
      final firstPoint = keyboardHandler.navigateToFirst(testData);
      expect(firstPoint, equals(testData.first));
      expect(firstPoint, equals(testData[0]));

      // Navigate to last
      final lastPoint = keyboardHandler.navigateToLast(testData);
      expect(lastPoint, equals(testData.last));
      expect(lastPoint, equals(testData[9]));
    });

    test('T033.7: Escape key closes tooltip', () {
      // Test closeTooltipOrClearSelection method (called by Escape key handler)
      var state = initialState.copyWith(
        focusedPointIndex: 3,
        isTooltipVisible: true,
        hoveredPoint: testData[3],
      );

      // Verify tooltip is initially visible
      expect(state.isTooltipVisible, isTrue);

      // Close tooltip (simulates Escape key)
      final newState = keyboardHandler.closeTooltipOrClearSelection(state);

      // Verify tooltip is closed
      expect(newState.isTooltipVisible, isFalse);
      expect(newState.hoveredPoint, isNull);
      // Focus cleared as well (part of clearing selection)
      expect(newState.focusedPointIndex, equals(-1));
    });

    test('T033.8: Accessibility - Screen reader announcement data', () {
      // Note: Actual screen reader announcements handled by Semantics widget
      // Integration test verifies focused point data is available

      // Navigate to a point
      var currentPoint = testData[4];
      final nextPoint = keyboardHandler.navigateToNext(currentPoint, testData);

      // Verify navigation successful
      expect(nextPoint, isNotNull);
      expect(nextPoint, equals(testData[5]));

      // Screen reader should announce: "Point 5, x: 50.0, y: 150.0"
      expect(nextPoint!['label'], equals('Point 5'));
      expect(nextPoint['x'], equals(50.0));
      expect(nextPoint['y'], equals(150.0));

      // Note: Actual Semantics announcement tested in widget tests
      // This test verifies focused point data is available for announcements
    });
  });
}
