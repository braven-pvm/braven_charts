// Contract Test: IGestureRecognizer Interface
// Feature: Layer 7 Interaction System
// Task: T028
// Status: Testing implementation

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/interaction/gesture_recognizer.dart' as bc;
import 'package:braven_charts/src/interaction/models/gesture_details.dart';

void main() {
  group('IGestureRecognizer Contract Tests', () {
    late bc.GestureRecognizer gestureRecognizer;

    setUp(() {
      gestureRecognizer = bc.GestureRecognizer();
    });

    test('recognizeGesture() detects gestures from pointer events', () {
      const pointerEvent = PointerDownEvent(
        position: Offset(400, 300),
      );
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );

      final result = gestureRecognizer.recognizeGesture(
        pointerEvent,
        state,
      );

      // Result can be null (gesture not complete) or GestureDetails
      expect(result == null || result is GestureDetails, isTrue);
    });

    test('recognizeGesture() completes in <10ms', () {
      const pointerEvent = PointerDownEvent(
        position: Offset(400, 300),
      );
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );

      final stopwatch = Stopwatch()..start();
      gestureRecognizer.recognizeGesture(
        pointerEvent,
        state,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('startGesture() initializes gesture tracking', () {
      const position = Offset(400, 300);
      const pointerCount = 1;
      const deviceKind = PointerDeviceKind.touch;

      final state = gestureRecognizer.startGesture(
        position,
        pointerCount,
        deviceKind,
      );

      expect(state, isNotNull);
      expect(state.startPosition, equals(position));
      expect(state.pointerCount, equals(pointerCount));
    });

    test('updateGesture() tracks gesture progress', () {
      final initialState = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );
      const position = Offset(410, 305);
      const delta = Offset(10, 5);

      final updatedState = gestureRecognizer.updateGesture(
        initialState,
        position,
        delta,
      );

      expect(updatedState, isNotNull);
      expect(updatedState.currentPosition, equals(position));
    });

    test('completeGesture() finalizes gesture', () {
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );
      const position = Offset(420, 310);

      final details = gestureRecognizer.completeGesture(
        state,
        position,
      );

      expect(details, isNotNull);
      expect(details, isA<GestureDetails>());
    });

    test('cancelGesture() cancels gesture tracking', () {
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );

      // Should not throw
      gestureRecognizer.cancelGesture(state);
      expect(true, isTrue);
    });

    test('resolveConflict() handles tap vs pan conflict', () {
      final candidates = <GestureType>[GestureType.tap, GestureType.pan];
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        1,
        PointerDeviceKind.touch,
      );

      final winner = gestureRecognizer.resolveConflict(
        candidates,
        state,
      );

      expect(winner, isNotNull);
      expect([GestureType.tap, GestureType.pan].contains(winner), isTrue);
    });

    test('resolveConflict() handles pan vs pinch conflict', () {
      final candidates = <GestureType>[GestureType.pan, GestureType.pinch];
      final state = gestureRecognizer.startGesture(
        const Offset(400, 300),
        2, // 2 pointers
        PointerDeviceKind.touch,
      );

      final winner = gestureRecognizer.resolveConflict(
        candidates,
        state,
      );

      expect(winner, isNotNull);
      // With 2 pointers, pinch should be preferred
      expect(winner, equals(GestureType.pinch));
    });

    test('tap gesture recognized within 10ms of touch-up', () {
      // Simulate tap sequence
      const downPosition = Offset(400, 300);
      const deviceKind = PointerDeviceKind.touch;

      final state = gestureRecognizer.startGesture(
        downPosition,
        1,
        deviceKind,
      );

      final stopwatch = Stopwatch()..start();

      final details = gestureRecognizer.completeGesture(
        state,
        downPosition, // No movement = tap
      );

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(details, isNotNull);
    });

    test('pan distinguishes from tap with >10px movement', () {
      const startPosition = Offset(400, 300);
      const endPosition = Offset(420, 300); // 20px movement
      const deviceKind = PointerDeviceKind.touch;

      var state = gestureRecognizer.startGesture(
        startPosition,
        1,
        deviceKind,
      );

      state = gestureRecognizer.updateGesture(
        state,
        endPosition,
        endPosition - startPosition,
      );

      final details = gestureRecognizer.completeGesture(
        state,
        endPosition,
      );

      expect(details, isNotNull);
      // With 20px movement, should be pan, not tap
      expect(details.type, equals(GestureType.pan));
    });

    test('long-press cancels if finger moves >10px', () {
      const startPosition = Offset(400, 300);
      const movedPosition = Offset(412, 300); // 12px movement
      const deviceKind = PointerDeviceKind.touch;

      var state = gestureRecognizer.startGesture(
        startPosition,
        1,
        deviceKind,
      );

      state = gestureRecognizer.updateGesture(
        state,
        movedPosition,
        movedPosition - startPosition,
      );

      // Long-press should be cancelled from candidates due to movement
      expect(state, isNotNull);
      expect(state.candidateGestures.contains(GestureType.longPress), isFalse);
    });
  });
}
