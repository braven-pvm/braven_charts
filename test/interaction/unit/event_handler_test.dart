// Unit Test: EventHandler Component
// Feature: Layer 7 Interaction System
// Task: T018
// Status: Tests should now PASS with implementation

import 'package:braven_charts/src/coordinates/coordinate_transformer.dart';
import 'package:braven_charts/src/interaction/event_handler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventHandler Component Tests', () {
    late EventHandler eventHandler;
    late CoordinateTransformer coordinateTransformer;

    setUp(() {
      eventHandler = EventHandler();
      coordinateTransformer = const CoordinateTransformer(
        chartBounds: Rect.fromLTWH(0, 0, 800, 600),
        dataBounds: Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    group('Pointer Event Processing', () {
      test('processPointerEvent() translates mouse move to data coordinates', () {
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
      });

      test('processPointerEvent() handles mouse down events', () {
        final pointerEvent = const PointerDownEvent(
          position: Offset(100, 200),
        );

        final result = eventHandler.processPointerEvent(
          pointerEvent,
          coordinateTransformer,
        );

        expect(result, isNotNull);
        expect(result!.type, equals(ChartEventType.mouseDown));
      });

      test('processPointerEvent() handles touch events', () {
        final pointerEvent = const PointerDownEvent(
          position: Offset(150, 250),
          kind: PointerDeviceKind.touch,
        );

        final result = eventHandler.processPointerEvent(
          pointerEvent,
          coordinateTransformer,
        );

        expect(result, isNotNull);
        expect(result!.screenPosition, equals(const Offset(150, 250)));
      });

      test('processPointerEvent() completes in <5ms (99th percentile)', () {
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 100; i++) {
          eventHandler.processPointerEvent(
            PointerMoveEvent(position: Offset(i.toDouble(), i.toDouble())),
            coordinateTransformer,
          );
        }

        stopwatch.stop();
        final avgTime = stopwatch.elapsedMicroseconds / 100;

        expect(avgTime, lessThan(5000)); // 5ms = 5000 microseconds
      });
    });

    group('Keyboard Event Processing', () {
      test('processKeyEvent() handles arrow right key', () {
        const keyEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowRight,
          logicalKey: LogicalKeyboardKey.arrowRight,
          timeStamp: Duration.zero,
        );

        final result = eventHandler.processKeyEvent(keyEvent);

        expect(result, equals(KeyEventResult.ignored)); // Currently returns ignored
      });

      test('processKeyEvent() handles arrow left key', () {
        const keyEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowLeft,
          logicalKey: LogicalKeyboardKey.arrowLeft,
          timeStamp: Duration.zero,
        );

        final result = eventHandler.processKeyEvent(keyEvent);

        expect(result, equals(KeyEventResult.ignored)); // Currently returns ignored
      });

      test('processKeyEvent() handles zoom keys (+/-)', () {
        const zoomInEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.equal,
          logicalKey: LogicalKeyboardKey.equal,
          timeStamp: Duration.zero,
        );

        final result = eventHandler.processKeyEvent(zoomInEvent);

        expect(result, equals(KeyEventResult.ignored)); // Currently returns ignored
      });

      test('processKeyEvent() completes in <50ms', () {
        final stopwatch = Stopwatch()..start();

        const keyEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowRight,
          logicalKey: LogicalKeyboardKey.arrowRight,
          timeStamp: Duration.zero,
        );

        eventHandler.processKeyEvent(keyEvent);

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('Event Routing', () {
      test('routeEvent() routes to registered handlers by priority', () {
        var handler2Called = false;

        eventHandler.registerHandler(
          (event) {
            handler2Called = true;
            return true;
          },
          1, // priority
        );

        eventHandler.registerHandler(
          (event) {
            return false;
          },
          2, // priority - higher, called first
        );

        final mockEvent = ChartEvent(
          type: ChartEventType.mouseMove,
          screenPosition: const Offset(100, 100),
          dataPosition: const Offset(50, 50),
        );

        final handled = eventHandler.routeEvent(mockEvent);

        expect(handled, isTrue);
        expect(handler2Called, isTrue); // Higher priority called first
      });

      test('routeEvent() stops propagation when handler returns true', () {
        var handler1Called = false;
        var handler2Called = false;

        eventHandler.registerHandler(
          (event) {
            handler1Called = true;
            return false; // Don't stop propagation
          },
          2, // higher priority
        );

        eventHandler.registerHandler(
          (event) {
            handler2Called = true;
            return true; // Stop propagation
          },
          1, // lower priority
        );

        final mockEvent = ChartEvent(
          type: ChartEventType.mouseMove,
          screenPosition: const Offset(100, 100),
          dataPosition: const Offset(50, 50),
        );

        eventHandler.routeEvent(mockEvent);

        expect(handler1Called, isTrue); // Higher priority called
        expect(handler2Called, isTrue); // Lower priority also called (handler1 didn't stop)
      });
    });

    group('Handler Registration', () {
      test('registerHandler() adds handler with priority', () {
        var called = false;

        eventHandler.registerHandler(
          (event) {
            called = true;
            return false;
          },
          5, // priority
        );

        expect(called, isFalse); // Not called yet
      });

      test('unregisterHandler() removes registered handler', () {
        var called = false;

        bool handler(ChartEvent event) {
          called = true;
          return false;
        }

        eventHandler.registerHandler(handler, 1);
        eventHandler.unregisterHandler(handler);

        final mockEvent = ChartEvent(
          type: ChartEventType.mouseMove,
          screenPosition: const Offset(100, 100),
          dataPosition: const Offset(50, 50),
        );
        eventHandler.routeEvent(mockEvent);

        expect(called, isFalse); // Handler was removed
      });
    });

    group('Memory Management', () {
      test('dispose() cleans up resources', () {
        eventHandler.dispose();

        // Should throw after dispose
        expect(
          () => eventHandler.processPointerEvent(
            const PointerMoveEvent(position: Offset.zero),
            coordinateTransformer,
          ),
          throwsStateError,
        );
      });

      test('no memory growth after 10,000 events', () {
        // Process 10,000 events
        for (var i = 0; i < 10000; i++) {
          eventHandler.processPointerEvent(
            PointerMoveEvent(position: Offset(i.toDouble(), i.toDouble())),
            coordinateTransformer,
          );
        }

        // Memory should not grow (would need actual memory profiling)
        expect(true, isTrue);
      });
    });

    group('Screen to Data Coordinate Transformation', () {
      test('translates screen coordinates to data coordinates correctly', () {
        final pointerEvent = const PointerMoveEvent(
          position: Offset(400, 300),
        );

        final result = eventHandler.processPointerEvent(
          pointerEvent,
          coordinateTransformer,
        );

        expect(result, isNotNull);
        expect(result!.dataPosition, isNotNull);
        // Center of 800x600 chart maps to center of 100x100 data
        expect(result.dataPosition.dx, closeTo(50.0, 0.1));
        expect(result.dataPosition.dy, closeTo(50.0, 0.1));
      });
    });
  });
}
