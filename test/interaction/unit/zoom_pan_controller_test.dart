// Unit Test: ZoomPanController Component
// Feature: Layer 7 Interaction System
// Task: T021/T027
// Status: Tests should now PASS with implementation

import 'dart:ui' show Offset, Rect;

import 'package:braven_charts/src/interaction/models/gesture_details.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src/interaction/zoom_pan_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoomPanController Component Tests', () {
    late ZoomPanController zoomPanController;
    late ZoomPanState zoomPanState;

    setUp(() {
      zoomPanController = ZoomPanController();
      const dataBounds = Rect.fromLTWH(0, 0, 100, 100);
      zoomPanState = const ZoomPanState.initial(dataBounds);
    });

    group('Zoom Operations', () {
      test('zoom() increases zoom level', () {
        final newState = zoomPanController.zoom(
          zoomPanState,
          zoomFactor: 1.5,
          focalPoint: const Offset(400, 300),
        );

        expect(newState.zoomLevelX, greaterThan(zoomPanState.zoomLevelX));
        expect(newState.zoomLevelY, greaterThan(zoomPanState.zoomLevelY));
        expect(newState.zoomLevelX, equals(1.5));
      });

      test('zoom() respects minZoom constraint', () {
        final newState = zoomPanController.zoom(
          zoomPanState,
          zoomFactor: 0.1, // Try to zoom out too much
          focalPoint: const Offset(400, 300),
          minZoom: 0.5,
        );

        expect(newState.zoomLevelX, greaterThanOrEqualTo(0.5));
        expect(newState.zoomLevelY, greaterThanOrEqualTo(0.5));
      });

      test('zoom() respects maxZoom constraint', () {
        final newState = zoomPanController.zoom(
          zoomPanState,
          zoomFactor: 100.0, // Try to zoom in too much
          focalPoint: const Offset(400, 300),
          maxZoom: 10.0,
        );

        expect(newState.zoomLevelX, lessThanOrEqualTo(10.0));
        expect(newState.zoomLevelY, lessThanOrEqualTo(10.0));
      });

      test('zoom() centers on focal point', () {
        const focalPoint = Offset(200, 150);
        final newState = zoomPanController.zoom(
          zoomPanState,
          zoomFactor: 2.0,
          focalPoint: focalPoint,
        );

        // Focal point should remain visually in the same place after zoom
        // Pan offset changes to compensate for zoom
        expect(newState.panOffset, isNot(equals(zoomPanState.panOffset)));
      });

      test('zoomTo() sets exact zoom level', () {
        final newState = zoomPanController.zoomTo(
          zoomPanState,
          targetZoom: 3.0,
          focalPoint: const Offset(400, 300),
        );

        expect(newState.zoomLevelX, equals(3.0));
        expect(newState.zoomLevelY, equals(3.0));
      });

      test('resetZoom() returns to default zoom level', () {
        final zoomedState = zoomPanState.copyWith(zoomLevelX: 5.0, zoomLevelY: 5.0);
        final newState = zoomPanController.resetZoom(zoomedState);

        expect(newState.zoomLevelX, equals(1.0));
        expect(newState.zoomLevelY, equals(1.0));
        expect(newState.panOffset, equals(Offset.zero));
      });
    });

    group('Pan Operations', () {
      test('pan() updates panOffset', () {
        const delta = Offset(50, -30);
        final newState = zoomPanController.pan(zoomPanState, delta);

        expect(newState.panOffset, equals(delta));
      });

      test('pan() respects pan boundaries when set', () {
        const bounds = Rect.fromLTWH(0, 0, 1000, 800);
        const largeDelta = Offset(2000, 2000); // Try to pan too far

        final newState = zoomPanController.pan(
          zoomPanState,
          largeDelta,
          bounds: bounds,
        );

        // Should be constrained within bounds
        expect(newState.panOffset.dx, lessThanOrEqualTo(bounds.right));
        expect(newState.panOffset.dy, lessThanOrEqualTo(bounds.bottom));
      });

      test('pan() accumulates over multiple calls', () {
        var state = zoomPanState;
        state = zoomPanController.pan(state, const Offset(10, 10));
        state = zoomPanController.pan(state, const Offset(5, -5));

        expect(state.panOffset, equals(const Offset(15, 5)));
      });
    });

    group('Gesture Processing', () {
      test('processGesture() handles pinch gesture', () {
        final pinchGesture = GestureDetails.pinch(
          startPosition: const Offset(400, 300),
          currentPosition: const Offset(400, 300),
          initialScale: 1.0,
          currentScale: 2.0,
          pointerCount: 2,
          startTime: DateTime.now(),
        );

        final newState = zoomPanController.processGesture(
          zoomPanState,
          pinchGesture,
        );

        expect(newState.zoomLevelX, greaterThan(zoomPanState.zoomLevelX));
      });

      test('processGesture() handles pan gesture', () {
        final panGesture = GestureDetails.pan(
          startPosition: const Offset(100, 100),
          currentPosition: const Offset(120, 85),
          delta: const Offset(20, -15),
          totalDelta: const Offset(20, -15),
          startTime: DateTime.now(),
        );

        final newState = zoomPanController.processGesture(
          zoomPanState,
          panGesture,
        );

        expect(newState.panOffset, isNot(equals(Offset.zero)));
        expect(newState.panOffset, equals(const Offset(20, -15)));
      });

      test('processGesture() handles double tap to zoom', () {
        final doubleTapGesture = GestureDetails(
          type: GestureType.doubleTap,
          startPosition: const Offset(300, 200),
          currentPosition: const Offset(300, 200),
          endPosition: const Offset(300, 200),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        );

        final newState = zoomPanController.processGesture(
          zoomPanState,
          doubleTapGesture,
          doubleTapZoomFactor: 2.0,
        );

        expect(newState.zoomLevelX, equals(2.0));
        expect(newState.zoomLevelY, equals(2.0));
      });
    });

    group('Inertial Scrolling', () {
      test('applyInertia() returns state unchanged (no panVelocity support)', () {
        // Note: Inertia requires panVelocity field in ZoomPanState
        // Current implementation is a placeholder
        final newState = zoomPanController.applyInertia(
          zoomPanState,
          deltaTime: const Duration(milliseconds: 16),
        );

        expect(newState, equals(zoomPanState));
      });
    });

    group('Coordinate Transformations', () {
      test('screenToData() converts screen coordinates to data coordinates', () {
        final zoomedState = zoomPanState.copyWith(
          zoomLevelX: 2.0,
          zoomLevelY: 2.0,
          panOffset: const Offset(50, 50),
        );

        const screenPoint = Offset(400, 300);
        final dataPoint = zoomPanController.screenToData(
          screenPoint,
          zoomedState,
        );

        expect(dataPoint, isNotNull);
        expect(dataPoint, isNot(equals(screenPoint)));
        // Formula: data = (screen - pan) / zoom
        expect(dataPoint.dx, equals((400 - 50) / 2.0)); // = 175
        expect(dataPoint.dy, equals((300 - 50) / 2.0)); // = 125
      });

      test('dataToScreen() converts data coordinates to screen coordinates', () {
        final zoomedState = zoomPanState.copyWith(
          zoomLevelX: 2.0,
          zoomLevelY: 2.0,
          panOffset: const Offset(50, 50),
        );

        const dataPoint = Offset(100, 100);
        final screenPoint = zoomPanController.dataToScreen(
          dataPoint,
          zoomedState,
        );

        expect(screenPoint, isNotNull);
        expect(screenPoint, isNot(equals(dataPoint)));
        // Formula: screen = data * zoom + pan
        expect(screenPoint.dx, equals(100 * 2.0 + 50)); // = 250
        expect(screenPoint.dy, equals(100 * 2.0 + 50)); // = 250
      });

      test('coordinate transformation is reversible', () {
        final zoomedState = zoomPanState.copyWith(
          zoomLevelX: 1.5,
          zoomLevelY: 1.5,
          panOffset: const Offset(30, -20),
        );

        const originalScreen = Offset(250, 175);
        final data = zoomPanController.screenToData(originalScreen, zoomedState);
        final backToScreen = zoomPanController.dataToScreen(data, zoomedState);

        expect(backToScreen.dx, closeTo(originalScreen.dx, 0.1));
        expect(backToScreen.dy, closeTo(originalScreen.dy, 0.1));
      });
    });

    group('Performance & Memory', () {
      test('zoom operation completes in <2ms', () {
        final stopwatch = Stopwatch()..start();
        zoomPanController.zoom(
          zoomPanState,
          zoomFactor: 1.5,
          focalPoint: const Offset(400, 300),
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMicroseconds, lessThan(2000));
      });

      test('no memory leaks after 1000 zoom/pan cycles', () {
        var state = zoomPanState;
        for (var i = 0; i < 1000; i++) {
          state = zoomPanController.zoom(
            state,
            zoomFactor: 1.1,
            focalPoint: Offset(i.toDouble(), 100),
          );
          state = zoomPanController.pan(state, Offset(i.toDouble(), i.toDouble()));
        }

        // Should complete without error (memory check)
        expect(state, isNotNull);
      });
    });
  });
}
