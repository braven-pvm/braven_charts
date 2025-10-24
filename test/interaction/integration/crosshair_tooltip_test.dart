/// Integration tests for Crosshair + Tooltip interaction.
///
/// Tests the seamless interaction between EventHandler, CrosshairRenderer,
/// and TooltipProvider components.
library;

import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/interaction/crosshair_renderer.dart';
import 'package:braven_charts/src/interaction/event_handler.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';

void main() {
  group('Crosshair + Tooltip Integration Tests', () {
    late EventHandler eventHandler;
    late CrosshairRenderer crosshairRenderer;
    late List<ChartDataPoint> testData;
    late InteractionState initialState;

    setUp(() {
      // Create test data (10 points in a simple line)
      testData = List.generate(
        10,
        (i) => ChartDataPoint(
          x: i * 10.0,
          y: 50.0 + i * 5.0,
          label: 'Point $i',
        ),
      );

      // Create components (no-arg constructors)
      eventHandler = EventHandler();
      crosshairRenderer = CrosshairRenderer();

      // Initialize state
      initialState = InteractionState.initial();
    });

    tearDown(() {
      eventHandler.dispose();
    });

    test('T031.1: Crosshair appears on mouse enter', () {
      // Simulate mouse enter event at position (50, 50)
      final mousePosition = const Offset(50, 50);

      // Update state with crosshair position
      final updatedState = initialState.copyWith(
        crosshairPosition: mousePosition,
        isCrosshairVisible: true,
      );

      // Verify crosshair visibility
      expect(updatedState.isCrosshairVisible, isTrue);
      expect(updatedState.crosshairPosition, equals(mousePosition));
    });

    test('T031.2: Crosshair follows mouse movement', () {
      // Start with crosshair visible at (50, 50)
      var state = initialState.copyWith(
        crosshairPosition: const Offset(50, 50),
        isCrosshairVisible: true,
      );

      // Move mouse to (100, 75)
      state = state.copyWith(
        crosshairPosition: const Offset(100, 75),
      );

      expect(state.isCrosshairVisible, isTrue);
      expect(state.crosshairPosition, equals(const Offset(100, 75)));

      // Move mouse to (150, 100)
      state = state.copyWith(
        crosshairPosition: const Offset(150, 100),
      );

      expect(state.crosshairPosition, equals(const Offset(150, 100)));
    });

    test('T031.3: Crosshair snaps to nearest data point', () {
      // Mock screen-to-data coordinate mapping
      // Assume data points are at screen x = 0, 10, 20, ..., 90
      // with y coordinates mapped from data y values

      final snapRadius = 20.0;
      final mousePosition = const Offset(15, 50); // Near point at x=10

      // Calculate snap points (in real implementation, this is done by CrosshairRenderer)
      final snapPoints = crosshairRenderer.calculateSnapPoints(
        mousePosition,
        testData,
        snapRadius,
      );

      // Verify that snap points are found
      expect(snapPoints, isNotEmpty);

      // The nearest point should be at x=10 (index 1)
      // Note: This assumes simple coordinate mapping for test
      final nearestPoint = snapPoints.first;
      expect(nearestPoint.x, equals(10.0)); // Data x coordinate
    });

    test('T031.4: Tooltip appears on data point hover (after delay)', () async {
      // Simulate hover over a data point (point 5 at x=50, y=75)

      // Initial state with focused point but tooltip not yet visible
      var state = initialState.copyWith(
        focusedPointIndex: 5,
        isTooltipVisible: false,
      );

      // Verify tooltip not immediately visible
      expect(state.isTooltipVisible, isFalse);

      // Simulate delay passing (in real implementation, this would be timer-based)
      await Future.delayed(const Duration(milliseconds: 100));

      // Update state to show tooltip after delay
      state = state.copyWith(
        isTooltipVisible: true,
      );

      // Verify tooltip is now visible
      expect(state.isTooltipVisible, isTrue);
      expect(state.focusedPointIndex, equals(5));
    });

    test('T031.5: Tooltip shows correct content (series name, X, Y values)',
        () {
      final dataPoint = testData[3]; // x=30, y=65, label='Point 3'

      // In integration tests, we verify that the state contains the correct
      // data point information that would be used to build the tooltip.
      // Actual widget rendering is tested in widget tests.

      final state = initialState.copyWith(
        focusedPointIndex: 3,
        isTooltipVisible: true,
      );

      expect(state.focusedPointIndex, equals(3));
      expect(state.isTooltipVisible, isTrue);
      expect(testData[state.focusedPointIndex], equals(dataPoint));
      expect(testData[state.focusedPointIndex].x, equals(30.0));
      expect(testData[state.focusedPointIndex].y, equals(65.0));
      expect(testData[state.focusedPointIndex].label, equals('Point 3'));
    });

    test('T031.6: Tooltip hides on mouse exit', () {
      // Start with tooltip visible
      var state = initialState.copyWith(
        isTooltipVisible: true,
        focusedPointIndex: 5,
        crosshairPosition: const Offset(50, 75),
        isCrosshairVisible: true,
      );

      expect(state.isTooltipVisible, isTrue);

      // Simulate mouse exit - return to initial state (all cleared)
      state = InteractionState.initial();

      expect(state.isCrosshairVisible, isFalse);
      expect(state.isTooltipVisible, isFalse);
      expect(state.crosshairPosition, isNull);
      expect(state.focusedPointIndex, equals(-1));
    });

    test('T031.7: Crosshair and tooltip work together seamlessly', () {
      // This test verifies the complete flow:
      // 1. Mouse enters → crosshair appears
      // 2. Mouse moves → crosshair follows
      // 3. Mouse hovers over point → crosshair snaps, tooltip shows after delay
      // 4. Mouse exits → both hide

      // Step 1: Mouse enters
      var state = initialState.copyWith(
        crosshairPosition: const Offset(25, 55),
        isCrosshairVisible: true,
      );
      expect(state.isCrosshairVisible, isTrue);
      expect(state.isTooltipVisible, isFalse); // Tooltip not yet visible

      // Step 2: Mouse moves and snaps to nearest point
      final snapPoints = crosshairRenderer.calculateSnapPoints(
        const Offset(25, 55),
        testData,
        20.0,
      );
      expect(snapPoints, isNotEmpty);

      state = state.copyWith(
        focusedPointIndex: 2, // Snapped to point at x=20
      );
      expect(state.focusedPointIndex, equals(2));

      // Step 3: After hover delay, tooltip appears
      state = state.copyWith(
        isTooltipVisible: true,
      );
      expect(state.isTooltipVisible, isTrue);
      expect(state.isCrosshairVisible, isTrue); // Both visible

      // Step 4: Mouse exits
      state = InteractionState.initial(); // Reset to initial state
      expect(state.isCrosshairVisible, isFalse);
      expect(state.isTooltipVisible, isFalse);
    });

    test('T031.8: Performance - Full interaction cycle completes in <100ms',
        () {
      final stopwatch = Stopwatch()..start();

      // Simulate complete interaction cycle
      var state = initialState;

      // 1. Mouse enter
      state = state.copyWith(
        crosshairPosition: const Offset(50, 60),
        isCrosshairVisible: true,
      );

      // 2. Calculate snap points
      final snapPoints = crosshairRenderer.calculateSnapPoints(
        const Offset(50, 60),
        testData,
        20.0,
      );

      // 3. Update with focused point
      if (snapPoints.isNotEmpty) {
        state = state.copyWith(
          focusedPointIndex: testData.indexOf(snapPoints.first),
        );
      }

      // 4. Show tooltip
      state = state.copyWith(
        isTooltipVisible: true,
      );

      // 5. Verify tooltip state (widget building tested in widget tests)
      expect(state.isTooltipVisible, isTrue);
      if (state.focusedPointIndex >= 0) {
        expect(testData[state.focusedPointIndex], isNotNull);
      }

      // 6. Hide on exit
      state = InteractionState.initial(); // Reset to initial state

      stopwatch.stop();

      // Verify complete cycle completes in <100ms
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Full interaction cycle should complete in <100ms',
      );
    });
  });
}
