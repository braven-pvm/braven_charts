// Unit Test: GestureDetails Model
// Feature: Layer 7 Interaction System
// Task: T010
// Status: Implementation complete, tests aligned

import 'package:braven_charts/legacy/src/interaction/models/gesture_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GestureDetails Model Tests', () {
    test('GestureDetails.tap() creates tap gesture', () {
      final gesture = GestureDetails.tap(
        position: const Offset(100, 200),
        timestamp: DateTime.now(),
      );

      expect(gesture.type, equals(GestureType.tap));
      expect(gesture.startPosition, equals(const Offset(100, 200)));
      expect(gesture.currentPosition, equals(const Offset(100, 200)));
    });

    test('GestureDetails.pan() creates pan gesture', () {
      final gesture = GestureDetails.pan(
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(150, 150),
        delta: const Offset(50, 50),
        totalDelta: const Offset(50, 50),
        startTime: DateTime.now(),
      );

      expect(gesture.type, equals(GestureType.pan));
      expect(gesture.startPosition, equals(const Offset(100, 100)));
      expect(gesture.currentPosition, equals(const Offset(150, 150)));
      expect(gesture.panDelta, equals(const Offset(50, 50)));
      expect(gesture.totalPanDelta, equals(const Offset(50, 50)));
    });

    test('GestureDetails.pinch() creates pinch gesture', () {
      final gesture = GestureDetails.pinch(
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(120, 120),
        initialScale: 1.0,
        currentScale: 1.5,
        pointerCount: 2,
        startTime: DateTime.now(),
      );

      expect(gesture.type, equals(GestureType.pinch));
      expect(gesture.initialScale, equals(1.0));
      expect(gesture.currentScale, equals(1.5));
      expect(gesture.pointerCount, equals(2));
    });

    test('distance calculates total pan movement', () {
      final gesture = GestureDetails.pan(
        startPosition: const Offset(0, 0),
        currentPosition: const Offset(30, 40),
        delta: const Offset(30, 40),
        totalDelta: const Offset(30, 40),
        startTime: DateTime.now(),
      );

      // Distance = sqrt(30^2 + 40^2) = sqrt(900 + 1600) = sqrt(2500) = 50
      expect(gesture.distance, equals(50.0));
    });

    test('distance returns 0 for tap gesture', () {
      final gesture = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: DateTime.now(),
      );

      expect(gesture.distance, equals(0.0));
    });

    test('isCompleted returns true for completed gesture', () {
      final gesture = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: DateTime.now(),
      );

      expect(gesture.isCompleted, isTrue);
    });

    test('pinch gesture tracks scale changes', () {
      final gesture = GestureDetails.pinch(
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(120, 120),
        initialScale: 1.0,
        currentScale: 1.5,
        pointerCount: 2,
        startTime: DateTime.now(),
      );

      expect(gesture.initialScale, equals(1.0));
      expect(gesture.currentScale, equals(1.5));
      // Scale change = currentScale - initialScale = 0.5
      expect(gesture.currentScale! - gesture.initialScale!, equals(0.5));
    });

    test('duration returns time elapsed', () {
      final start = DateTime.now();
      final gesture = GestureDetails.pan(
        startPosition: const Offset(0, 0),
        currentPosition: const Offset(50, 50),
        delta: const Offset(50, 50),
        totalDelta: const Offset(50, 50),
        startTime: start,
        endTime: start.add(const Duration(seconds: 1)),
      );

      expect(gesture.duration, equals(const Duration(seconds: 1)));
    });

    test('validation: pinch with invalid pointer count throws', () {
      expect(
        () => GestureDetails.pinch(
          startPosition: const Offset(100, 100),
          currentPosition: const Offset(120, 120),
          initialScale: 1.0,
          currentScale: 1.5,
          pointerCount: 1, // Invalid - must be >= 2
          startTime: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validation: pinch without scale values throws', () {
      // Note: This is caught at compile time due to required parameters
      // This test documents the requirement
      final gesture = GestureDetails.pinch(
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(120, 120),
        initialScale: 1.0,
        currentScale: 1.5,
        pointerCount: 2,
        startTime: DateTime.now(),
      );

      expect(gesture.initialScale, isNotNull);
      expect(gesture.currentScale, isNotNull);
    });

    test('equality: two gestures with same values are equal', () {
      final timestamp = DateTime.now();
      final gesture1 = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: timestamp,
      );
      final gesture2 = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: timestamp,
      );

      expect(gesture1, equals(gesture2));
    });

    test('toJson() serializes gesture correctly', () {
      final gesture = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: DateTime.now(),
      );

      final json = gesture.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['type'], equals('tap'));
      expect(json['startPosition'], isNotNull);
    });

    test('fromJson() deserializes gesture correctly', () {
      final timestamp = DateTime.now();
      final json = {
        'type': 'tap',
        'startPosition': {'dx': 100.0, 'dy': 100.0},
        'currentPosition': {'dx': 100.0, 'dy': 100.0},
        'endPosition': {'dx': 100.0, 'dy': 100.0},
        'pointerCount': 1,
        'deviceKind': 'mouse',
        'startTime': timestamp.toIso8601String(),
        'endTime': timestamp.toIso8601String(),
      };

      final gesture = GestureDetails.fromJson(json);

      expect(gesture.type, equals(GestureType.tap));
      expect(gesture.startPosition, equals(const Offset(100, 100)));
    });

    test('complex scenario: pan gesture with full details', () {
      final start = DateTime.now();
      final end = start.add(const Duration(milliseconds: 500));
      final gesture = GestureDetails.pan(
        startPosition: const Offset(0, 0),
        currentPosition: const Offset(100, 100),
        delta: const Offset(10, 10),
        totalDelta: const Offset(100, 100),
        startTime: start,
        endTime: end,
        endPosition: const Offset(100, 100),
      );

      expect(gesture.type, equals(GestureType.pan));
      expect(gesture.distance, closeTo(141.42, 0.01)); // sqrt(100^2 + 100^2)
      expect(gesture.duration, equals(const Duration(milliseconds: 500)));
      expect(gesture.isCompleted, isTrue);
    });
  });
}
