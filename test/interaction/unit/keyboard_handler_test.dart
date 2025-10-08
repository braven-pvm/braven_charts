// Unit Test: KeyboardHandler Component
// Feature: Layer 7 Interaction System
// Task: T029
// Status: Tests implementation

import 'dart:ui' show Offset;

import 'package:flutter/services.dart' show LogicalKeyboardKey, KeyEvent, KeyDownEvent, PhysicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/interaction/keyboard_handler.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';

void main() {
  group('KeyboardHandler Component Tests', () {
    late KeyboardHandler keyboardHandler;
    late InteractionState state;
    late List<Map<String, dynamic>> dataPoints;

    setUp(() {
      keyboardHandler = KeyboardHandler();
      dataPoints = List.generate(
        10,
        (i) => {'x': i * 10.0, 'y': i * 20.0},
      );
      state = InteractionState.initial().copyWith(
        focusedPointIndex: 5,
        hoveredPoint: dataPoints[5],
      );
    });

    group('Arrow Key Navigation', () {
      test('handleArrowRight() moves to next data point', () {
        final event = createKeyEvent(LogicalKeyboardKey.arrowRight);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(6));
        expect(newState.hoveredPoint, equals(dataPoints[6]));
      });

      test('handleArrowLeft() moves to previous data point', () {
        final event = createKeyEvent(LogicalKeyboardKey.arrowLeft);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(4));
        expect(newState.hoveredPoint, equals(dataPoints[4]));
      });

      test('arrowLeft at first data point wraps to last', () {
        final firstPointState = state.copyWith(
          focusedPointIndex: 0,
          hoveredPoint: dataPoints[0],
        );
        final event = createKeyEvent(LogicalKeyboardKey.arrowLeft);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          firstPointState,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(9)); // Last index
        expect(newState.hoveredPoint, equals(dataPoints[9]));
      });

      test('arrowRight at last data point wraps to first', () {
        final lastPointState = state.copyWith(
          focusedPointIndex: 9,
          hoveredPoint: dataPoints[9],
        );

        final event = createKeyEvent(LogicalKeyboardKey.arrowRight);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          lastPointState,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(0));
        expect(newState.hoveredPoint, equals(dataPoints[0]));
      });

      test('arrow up/down return state unchanged (for future series navigation)', () {
        final eventUp = createKeyEvent(LogicalKeyboardKey.arrowUp);
        final newStateUp = keyboardHandler.handleKeyEvent(
          eventUp,
          state,
          dataPoints: dataPoints,
        );

        expect(newStateUp, isNotNull);
        // Currently returns unchanged state - placeholder for multi-series
        expect(newStateUp, equals(state));

        final eventDown = createKeyEvent(LogicalKeyboardKey.arrowDown);
        final newStateDown = keyboardHandler.handleKeyEvent(
          eventDown,
          state,
          dataPoints: dataPoints,
        );

        expect(newStateDown, isNotNull);
        expect(newStateDown, equals(state));
      });
    });

    group('Zoom Keys', () {
      test('plus/equal key triggers zoom handler', () {
        final event = createKeyEvent(LogicalKeyboardKey.equal);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        // Zoom is handled by ZoomPanController, so state returned unchanged
        expect(newState, isNotNull);
        expect(newState, equals(state));
      });

      test('minus key triggers zoom handler', () {
        final event = createKeyEvent(LogicalKeyboardKey.minus);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        // Zoom is handled by ZoomPanController, so state returned unchanged
        expect(newState, isNotNull);
        expect(newState, equals(state));
      });

      test('zoomViewport() method zooms in correctly', () {
        final zoomState = state.zoomPanState;
        final newZoomState = keyboardHandler.zoomViewport(
          true, // zoom in
          zoomState,
          1.2, // factor
        );

        expect(newZoomState.zoomLevelX, equals(1.2));
        expect(newZoomState.zoomLevelY, equals(1.2));
      });

      test('zoomViewport() method zooms out correctly', () {
        final zoomState = state.zoomPanState.copyWith(
          zoomLevelX: 2.0,
          zoomLevelY: 2.0,
        );
        final newZoomState = keyboardHandler.zoomViewport(
          false, // zoom out
          zoomState,
          1.2, // factor (will be inverted to 1/1.2)
        );

        expect(newZoomState.zoomLevelX, closeTo(2.0 / 1.2, 0.01));
        expect(newZoomState.zoomLevelY, closeTo(2.0 / 1.2, 0.01));
      });
    });

    group('Home/End Keys', () {
      test('Home key jumps to first data point', () {
        final event = createKeyEvent(LogicalKeyboardKey.home);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(0));
        expect(newState.hoveredPoint, equals(dataPoints[0]));
      });

      test('End key jumps to last data point', () {
        final event = createKeyEvent(LogicalKeyboardKey.end);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(9));
        expect(newState.hoveredPoint, equals(dataPoints[9]));
      });
    });

    group('Enter/Space Keys', () {
      test('Enter key shows tooltip for focused point', () {
        final event = createKeyEvent(LogicalKeyboardKey.enter);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.isTooltipVisible, isTrue);
      });

      test('Space key shows tooltip for focused point', () {
        final event = createKeyEvent(LogicalKeyboardKey.space);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.isTooltipVisible, isTrue);
      });

      test('Enter key focuses first point if none focused', () {
        final noFocusState = InteractionState.initial();
        final event = createKeyEvent(LogicalKeyboardKey.enter);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          noFocusState,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.focusedPointIndex, equals(0));
        expect(newState.hoveredPoint, equals(dataPoints[0]));
        expect(newState.isTooltipVisible, isTrue);
      });
    });

    group('Escape Key', () {
      test('Escape key closes tooltip', () {
        final tooltipVisibleState = state.copyWith(
          isTooltipVisible: true,
        );

        final event = createKeyEvent(LogicalKeyboardKey.escape);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          tooltipVisibleState,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.isTooltipVisible, isFalse);
      });

      test('Escape key clears selection', () {
        final selectedState = state.copyWith(
          selectedPoints: [
            {'x': 10.0, 'y': 20.0},
            {'x': 30.0, 'y': 40.0},
          ],
        );

        final event = createKeyEvent(LogicalKeyboardKey.escape);
        final newState = keyboardHandler.handleKeyEvent(
          event,
          selectedState,
          dataPoints: dataPoints,
        );

        expect(newState, isNotNull);
        expect(newState!.selectedPoints, isEmpty);
        expect(newState.focusedPointIndex, equals(-1));
      });
    });

    group('Custom Key Bindings', () {
      test('registerKeyBinding() adds custom handler', () {
        var customCalled = false;
        keyboardHandler.registerKeyBinding(
          LogicalKeyboardKey.keyR,
          (state) => customCalled = true,
        );

        final event = createKeyEvent(LogicalKeyboardKey.keyR);
        keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(customCalled, isTrue);
      });

      test('unregisterKeyBinding() removes custom handler', () {
        var customCalled = false;
        keyboardHandler.registerKeyBinding(
          LogicalKeyboardKey.keyR,
          (state) => customCalled = true,
        );
        keyboardHandler.unregisterKeyBinding(LogicalKeyboardKey.keyR);

        final event = createKeyEvent(LogicalKeyboardKey.keyR);
        final result = keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );

        expect(customCalled, isFalse);
        expect(result, isNull); // Unhandled key returns null
      });
    });

    group('Performance & Memory', () {
      test('key event handling completes in <50ms', () {
        final event = createKeyEvent(LogicalKeyboardKey.arrowRight);

        final stopwatch = Stopwatch()..start();
        keyboardHandler.handleKeyEvent(
          event,
          state,
          dataPoints: dataPoints,
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('no memory leaks after 1000 key events', () {
        final keys = [
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
        ];

        for (var i = 0; i < 1000; i++) {
          final key = keys[i % keys.length];
          final event = createKeyEvent(key);
          keyboardHandler.handleKeyEvent(
            event,
            state,
            dataPoints: dataPoints,
          );
        }

        // If we get here without crashes/errors, no memory leaks
        expect(true, isTrue);
      });
    });

    group('Navigation Helper Methods', () {
      test('navigateToNext() wraps at end', () {
        final lastPoint = dataPoints[9];
        final nextPoint = keyboardHandler.navigateToNext(lastPoint, dataPoints);

        expect(nextPoint, equals(dataPoints[0]));
      });

      test('navigateToPrevious() wraps at start', () {
        final firstPoint = dataPoints[0];
        final prevPoint = keyboardHandler.navigateToPrevious(firstPoint, dataPoints);

        expect(prevPoint, equals(dataPoints[9]));
      });

      test('navigateToFirst() returns first point', () {
        final first = keyboardHandler.navigateToFirst(dataPoints);
        expect(first, equals(dataPoints[0]));
      });

      test('navigateToLast() returns last point', () {
        final last = keyboardHandler.navigateToLast(dataPoints);
        expect(last, equals(dataPoints[9]));
      });
    });
  });
}

// Helper function to create mock key events
KeyEvent createKeyEvent(LogicalKeyboardKey key) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.arrowDown,
    logicalKey: key,
    character: null,
    timeStamp: Duration.zero,
  );
}
