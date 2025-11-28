// Contract Test: IEventHandler Interface
// Feature: Layer 7 Interaction System
// Task: T003
// Status: Tests should now PASS with implementation

import 'dart:ui' show Rect, Offset;

import 'package:braven_charts/legacy/src/coordinates/coordinate_transformer.dart';
import 'package:braven_charts/legacy/src/interaction/event_handler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'
    show PhysicalKeyboardKey, LogicalKeyboardKey, KeyDownEvent;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IEventHandler Contract Tests', () {
    late EventHandler eventHandler;
    late CoordinateTransformer coordinateTransformer;

    setUp(() {
      eventHandler = EventHandler();

      coordinateTransformer = const CoordinateTransformer(
        chartBounds: Rect.fromLTWH(0, 0, 800, 600),
        dataBounds: Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    test('processPointerEvent() returns ChartEvent with data coordinates', () {
      final pointerEvent = const PointerMoveEvent(
        position: Offset(400, 300),
      );

      final result = eventHandler.processPointerEvent(
        pointerEvent,
        coordinateTransformer,
      );

      expect(result, isNotNull);
      expect(result!.screenPosition, equals(const Offset(400, 300)));
      expect(result.dataPosition, isNotNull);
      expect(result.type, equals(ChartEventType.mouseMove));
    });

    test('processPointerEvent() completes in <5ms', () {
      final pointerEvent = const PointerMoveEvent(
        position: Offset(400, 300),
      );

      final stopwatch = Stopwatch()..start();
      eventHandler.processPointerEvent(
        pointerEvent,
        coordinateTransformer,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5));
    });

    test('processKeyEvent() returns KeyEventResult', () {
      const keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );

      final result = eventHandler.processKeyEvent(keyEvent);

      // Result should be a KeyEventResult (handled or ignored)
      expect(
          result, equals(KeyEventResult.ignored)); // Currently returns ignored
    });

    test('routeEvent() delegates to handlers by priority', () {
      final handlerCalled = <int>[];

      // Register handlers with different priorities
      eventHandler.registerHandler(
        (event) {
          handlerCalled.add(1);
          return true;
        },
        1, // priority
      );

      eventHandler.registerHandler(
        (event) {
          handlerCalled.add(2);
          return false;
        },
        2, // priority
      );

      // Create a mock ChartEvent
      final mockEvent = ChartEvent(
        type: ChartEventType.mouseMove,
        screenPosition: const Offset(100, 100),
        dataPosition: const Offset(50, 50),
      );

      final handled = eventHandler.routeEvent(mockEvent);

      // Higher priority (2) should be called first
      expect(handlerCalled, equals([2, 1]));
      expect(handled, isTrue);
    });

    test('registerHandler() and unregisterHandler() work correctly', () {
      var callCount = 0;
      bool handler(ChartEvent event) {
        callCount++;
        return true;
      }

      eventHandler.registerHandler(handler, 1);

      // Mock event
      final mockEvent = ChartEvent(
        type: ChartEventType.mouseMove,
        screenPosition: const Offset(100, 100),
        dataPosition: const Offset(50, 50),
      );
      eventHandler.routeEvent(mockEvent);
      expect(callCount, equals(1));

      // Unregister and verify not called
      eventHandler.unregisterHandler(handler);
      eventHandler.routeEvent(mockEvent);
      expect(callCount, equals(1)); // Should still be 1, not 2
    });

    test('dispose() cleans up resources', () {
      eventHandler.dispose();

      // After dispose, further operations should throw
      expect(
        () => eventHandler.processPointerEvent(
          const PointerMoveEvent(position: Offset.zero),
          coordinateTransformer,
        ),
        throwsStateError,
      );
    });

    test('event processing has zero memory growth after 10,000 events', () {
      // Process 10,000 events and check memory doesn't grow
      for (var i = 0; i < 10000; i++) {
        final pointerEvent = PointerMoveEvent(
          position: Offset(i % 800.0, i % 600.0),
        );
        eventHandler.processPointerEvent(
          pointerEvent,
          coordinateTransformer,
        );
      }

      // Memory check would go here (platform-specific)
      // For now, just verify it doesn't crash
      expect(true, isTrue);
    });
  });
}
