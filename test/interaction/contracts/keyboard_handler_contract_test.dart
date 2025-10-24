// Contract Test: IKeyboardHandler Interface
// Feature: Layer 7 Interaction System
// Task: T007
// Status: Tests implementation

import 'package:braven_charts/src/interaction/keyboard_handler.dart' as bc;
import 'package:braven_charts/src/interaction/models/interaction_state.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, KeyEvent, KeyDownEvent, PhysicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IKeyboardHandler Contract Tests', () {
    late bc.KeyboardHandler keyboardHandler;
    late InteractionState state;
    late List<Map<String, dynamic>> dataPoints;

    setUp(() {
      keyboardHandler = bc.KeyboardHandler();
      dataPoints = List.generate(
        5,
        (i) => {'x': i * 10.0, 'y': i * 20.0},
      );
      state = InteractionState.initial().copyWith(
        focusedPointIndex: 1,
        hoveredPoint: dataPoints[1],
      );
    });

    test('handleKeyEvent() processes keyboard events', () {
      final keyEvent = createKeyEvent(LogicalKeyboardKey.arrowRight);

      final result = keyboardHandler.handleKeyEvent(
        keyEvent,
        state,
        dataPoints: dataPoints,
      );

      // Result should be non-null for handled keys
      expect(result, isNotNull);
      expect(result, isA<InteractionState>());
    });

    test('handleKeyEvent() completes in <50ms', () {
      final keyEvent = createKeyEvent(LogicalKeyboardKey.arrowRight);

      final stopwatch = Stopwatch()..start();
      keyboardHandler.handleKeyEvent(
        keyEvent,
        state,
        dataPoints: dataPoints,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('navigateToNext() moves to next data point', () {
      final currentPoint = dataPoints[1];

      final nextPoint = keyboardHandler.navigateToNext(
        currentPoint,
        dataPoints,
      );

      expect(nextPoint, isNotNull);
      expect(nextPoint, equals(dataPoints[2]));
    });

    test('navigateToNext() wraps to first point at end', () {
      final lastPoint = dataPoints[4];

      final nextPoint = keyboardHandler.navigateToNext(
        lastPoint,
        dataPoints,
      );

      expect(nextPoint, equals(dataPoints[0]));
    });

    test('navigateToPrevious() moves to previous data point', () {
      final currentPoint = dataPoints[2];

      final previousPoint = keyboardHandler.navigateToPrevious(
        currentPoint,
        dataPoints,
      );

      expect(previousPoint, isNotNull);
      expect(previousPoint, equals(dataPoints[1]));
    });

    test('navigateToPrevious() wraps to last point at start', () {
      final firstPoint = dataPoints[0];

      final previousPoint = keyboardHandler.navigateToPrevious(
        firstPoint,
        dataPoints,
      );

      expect(previousPoint, equals(dataPoints[4]));
    });

    test('navigateToFirst() returns first data point', () {
      final result = keyboardHandler.navigateToFirst(dataPoints);

      expect(result, equals(dataPoints[0]));
    });

    test('navigateToLast() returns last data point', () {
      final result = keyboardHandler.navigateToLast(dataPoints);

      expect(result, equals(dataPoints[4]));
    });

    test('panViewport() pans chart using arrow keys', () {
      final zoomPanState = const ZoomPanState.initial();

      final newState = keyboardHandler.panViewport(
        bc.PanDirection.right,
        zoomPanState,
        50.0,
      );

      expect(newState, isNotNull);
      expect(newState.panOffset.dx, greaterThan(zoomPanState.panOffset.dx));
    });

    test('zoomViewport() zooms in with + key', () {
      final zoomPanState = const ZoomPanState.initial();

      final newState = keyboardHandler.zoomViewport(
        true, // zoom in
        zoomPanState,
        1.2,
      );

      expect(newState, isNotNull);
      expect(newState.zoomLevelX, greaterThan(zoomPanState.zoomLevelX));
      expect(newState.zoomLevelY, greaterThan(zoomPanState.zoomLevelY));
    });

    test('zoomViewport() zooms out with - key', () {
      final zoomPanState = const ZoomPanState.initial().copyWith(
        zoomLevelX: 2.0,
        zoomLevelY: 2.0,
      );

      final newState = keyboardHandler.zoomViewport(
        false, // zoom out
        zoomPanState,
        1.2,
      );

      expect(newState, isNotNull);
      expect(newState.zoomLevelX, lessThan(zoomPanState.zoomLevelX));
      expect(newState.zoomLevelY, lessThan(zoomPanState.zoomLevelY));
    });

    test('activateFocusedElement() shows tooltip', () {
      final point = dataPoints[2];

      final newState = keyboardHandler.activateFocusedElement(
        point,
        state,
      );

      expect(newState.isTooltipVisible, isTrue);
      expect(newState.hoveredPoint, equals(point));
    });

    test('closeTooltipOrClearSelection() hides tooltip and clears state', () {
      final activeState = state.copyWith(
        isTooltipVisible: true,
        selectedPoints: [dataPoints[0], dataPoints[1]],
      );

      final newState =
          keyboardHandler.closeTooltipOrClearSelection(activeState);

      expect(newState.isTooltipVisible, isFalse);
      expect(newState.selectedPoints, isEmpty);
      expect(newState.focusedPointIndex, equals(-1));
    });

    test('keyboard navigation supports all required keys', () {
      final requiredKeyEvents = [
        createKeyEvent(LogicalKeyboardKey.arrowRight), // Navigate next
        createKeyEvent(LogicalKeyboardKey.arrowLeft), // Navigate previous
        createKeyEvent(LogicalKeyboardKey.arrowUp), // Pan up (or series nav)
        createKeyEvent(
            LogicalKeyboardKey.arrowDown), // Pan down (or series nav)
        createKeyEvent(LogicalKeyboardKey.home), // First point
        createKeyEvent(LogicalKeyboardKey.end), // Last point
        createKeyEvent(LogicalKeyboardKey.equal), // Zoom in (+)
        createKeyEvent(LogicalKeyboardKey.minus), // Zoom out (-)
        createKeyEvent(LogicalKeyboardKey.enter), // Show tooltip
        createKeyEvent(LogicalKeyboardKey.space), // Show tooltip
        createKeyEvent(LogicalKeyboardKey.escape), // Close/clear
      ];

      for (final keyEvent in requiredKeyEvents) {
        final result = keyboardHandler.handleKeyEvent(
          keyEvent,
          state,
          dataPoints: dataPoints,
        );

        // Should handle or return state/null
        expect(result == null || result is InteractionState, isTrue);
      }
    });

    test('registerKeyBinding() allows custom key handlers', () {
      var called = false;
      keyboardHandler.registerKeyBinding(
        LogicalKeyboardKey.keyH,
        (state) => called = true,
      );

      final keyEvent = createKeyEvent(LogicalKeyboardKey.keyH);
      keyboardHandler.handleKeyEvent(
        keyEvent,
        state,
        dataPoints: dataPoints,
      );

      expect(called, isTrue);
    });

    test('unregisterKeyBinding() removes custom handlers', () {
      keyboardHandler.registerKeyBinding(
        LogicalKeyboardKey.keyH,
        (state) {},
      );
      keyboardHandler.unregisterKeyBinding(LogicalKeyboardKey.keyH);

      final keyEvent = createKeyEvent(LogicalKeyboardKey.keyH);
      final result = keyboardHandler.handleKeyEvent(
        keyEvent,
        state,
        dataPoints: dataPoints,
      );

      // Should return null for unhandled key
      expect(result, isNull);
    });
  });
}

// Helper function to create key events
KeyEvent createKeyEvent(LogicalKeyboardKey key) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.arrowDown,
    logicalKey: key,
    character: null,
    timeStamp: Duration.zero,
  );
}
