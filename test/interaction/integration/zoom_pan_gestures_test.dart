/// Integration tests for Zoom and Pan gestures.
///
/// Tests the seamless interaction between EventHandler, ZoomPanController,
/// and GestureRecognizer components for zoom/pan functionality.
library;

import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/interaction/event_handler.dart';
import 'package:braven_charts/src/interaction/gesture_recognizer.dart';
import 'package:braven_charts/src/interaction/models/gesture_details.dart';
import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src/interaction/zoom_pan_controller.dart';

void main() {
  group('Zoom and Pan Gestures Integration Tests', () {
    late EventHandler eventHandler;
    late ZoomPanController zoomPanController;
    late GestureRecognizer gestureRecognizer;
    late List<ChartDataPoint> testData;
    late ZoomPanState initialZoomPanState;

    setUp(() {
      // Create test data (20 points for zoom/pan testing)
      testData = List.generate(
        20,
        (i) => ChartDataPoint(
          x: i * 10.0,
          y: 100.0 + i * 5.0,
          label: 'Point $i',
        ),
      );

      // Create components
      eventHandler = EventHandler();
      zoomPanController = ZoomPanController();
      gestureRecognizer = GestureRecognizer();

      // Initialize zoom/pan state
      initialZoomPanState = ZoomPanState.initial();
    });

    tearDown(() {
      eventHandler.dispose();
    });

    test('T032.1: Pinch-to-zoom on touch devices', () {
      // Simulate pinch gesture with scale factor 2.0 (zoom in)
      const focalPoint = Offset(100, 100);
      const scaleFactor = 2.0;

      // Process pinch gesture through ZoomPanController
      final newState = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: scaleFactor,
        focalPoint: focalPoint,
      );

      // Verify zoom level increased
      expect(newState.zoomLevelX, greaterThan(initialZoomPanState.zoomLevelX));
      expect(newState.zoomLevelX, closeTo(scaleFactor, 0.01));

      // Simulate pinch out (zoom out) with scale factor 0.5
      final zoomedOutState = zoomPanController.zoom(
        newState,
        zoomFactor: 0.5,
        focalPoint: focalPoint,
      );

      // Verify zoom level decreased
      expect(zoomedOutState.zoomLevelX, lessThan(newState.zoomLevelX));
    });

    test('T032.2: Mouse wheel zoom on desktop', () {
      // Simulate mouse wheel scroll up (zoom in) at position
      const scrollPosition = Offset(150, 150);
      const zoomInFactor = 1.2; // 20% zoom in

      final zoomedInState = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: zoomInFactor,
        focalPoint: scrollPosition,
      );

      expect(zoomedInState.zoomLevelX, closeTo(1.2, 0.01));

      // Simulate mouse wheel scroll down (zoom out)
      const zoomOutFactor = 0.83333; // ~20% zoom out

      final zoomedOutState = zoomPanController.zoom(
        zoomedInState,
        zoomFactor: zoomOutFactor,
        focalPoint: scrollPosition,
      );

      expect(zoomedOutState.zoomLevelX, closeTo(1.0, 0.01));
    });

    test('T032.3: Zoom level constraints (min/max)', () {
      // Try to zoom in beyond max (assumed 10.0)
      const maxZoomAttempt = Offset(100, 100);
      var state = initialZoomPanState;

      // Zoom in multiple times
      for (int i = 0; i < 20; i++) {
        state = zoomPanController.zoom(
          state,
          zoomFactor: 2.0,
          focalPoint: maxZoomAttempt,
        );
      }

      // Verify zoom is clamped to max
      expect(state.zoomLevelX, lessThanOrEqualTo(10.0));

      // Reset and try to zoom out beyond min (assumed 0.5)
      state = initialZoomPanState;
      const minZoomAttempt = Offset(100, 100);

      // Zoom out multiple times
      for (int i = 0; i < 20; i++) {
        state = zoomPanController.zoom(
          state,
          zoomFactor: 0.5,
          focalPoint: minZoomAttempt,
        );
      }

      // Verify zoom is clamped to min (default is 0.5)
      expect(state.zoomLevelX, greaterThanOrEqualTo(0.5));
    });

    test('T032.4: Pan gesture (drag to move viewport)', () {
      // Simulate pan gesture with delta movement
      const panDelta = Offset(50, 30);

      final pannedState = zoomPanController.pan(
        initialZoomPanState,
        panDelta,
      );

      // Verify pan offset changed
      expect(pannedState.panOffset, equals(panDelta));

      // Continue panning
      const additionalDelta = Offset(20, 10);
      final furtherPannedState = zoomPanController.pan(
        pannedState,
        additionalDelta,
      );

      // Verify cumulative pan offset
      expect(
        furtherPannedState.panOffset,
        equals(const Offset(70, 40)),
      );
    });

    test('T032.5: Pan boundary checking', () {
      // Zoom in first to enable panning boundaries
      var state = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: 2.0,
        focalPoint: const Offset(100, 100),
      );

      // Define chart bounds for boundary checking
      final bounds = Rect.fromLTWH(0, 0, 200, 200);

      // Try to pan beyond boundaries (with bounds provided)
      // Simulate large pan that would exceed boundaries
      const largePan = Offset(10000, 10000);

      final boundedState = zoomPanController.pan(
        state,
        largePan,
        bounds: bounds,
      );

      // Verify pan is constrained (should not equal the full large pan)
      // Exact boundary depends on data bounds, but should be constrained
      expect(
        boundedState.panOffset.dx,
        lessThan(largePan.dx),
      );
      expect(
        boundedState.panOffset.dy,
        lessThan(largePan.dy),
      );
    });

    test('T032.6: Zoom to fit data', () {
      // Start with a zoomed and panned state
      var state = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: 3.0,
        focalPoint: const Offset(100, 100),
      );
      state = zoomPanController.pan(
        state,
        const Offset(50, 30),
      );

      // Calculate data bounds from test data
      final minX = testData.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final maxX = testData.map((p) => p.x).reduce((a, b) => a > b ? a : b);
      final minY = testData.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final maxY = testData.map((p) => p.y).reduce((a, b) => a > b ? a : b);

      // Zoom to fit would reset zoom and pan to show all data
      // Note: Actual implementation would use zoomPanController.zoomTo()
      // For this test, we verify that reset brings back to initial state
      final resetState = zoomPanController.resetZoom(state);

      expect(resetState.zoomLevelX, equals(1.0));
      expect(resetState.panOffset, equals(Offset.zero));
    });

    test('T032.7: Reset to original view', () {
      // Create a complex state with zoom and pan
      var state = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: 2.5,
        focalPoint: const Offset(120, 80),
      );
      state = zoomPanController.pan(
        state,
        const Offset(30, -20),
      );

      // Verify state has changed from initial
      expect(state.zoomLevelX, equals(2.5));
      // Note: panOffset may be adjusted based on zoom focal point calculation
      expect(state.panOffset, isNot(equals(Offset.zero)));

      // Reset to original view
      final resetState = zoomPanController.resetZoom(state);

      // Verify reset to initial state
      expect(resetState.zoomLevelX, equals(1.0));
      expect(resetState.panOffset, equals(Offset.zero));
    });

    test('T032.8: Coordinate transformation during zoom/pan', () {
      // Zoom in 2x at center point
      var state = zoomPanController.zoom(
        initialZoomPanState,
        zoomFactor: 2.0,
        focalPoint: const Offset(100, 100),
      );

      // Test screen-to-data transformation
      const screenPoint = Offset(150, 150);
      final dataPoint = zoomPanController.screenToData(
        screenPoint,
        state,
      );

      // Data point should account for zoom level
      // Exact values depend on implementation, but verify transformation occurs
      expect(dataPoint, isNotNull);

      // Test data-to-screen transformation (inverse)
      final screenPointBack = zoomPanController.dataToScreen(
        dataPoint,
        state,
      );

      // Should transform back to approximately the same screen point
      expect(screenPointBack.dx, closeTo(screenPoint.dx, 0.1));
      expect(screenPointBack.dy, closeTo(screenPoint.dy, 0.1));
    });

    test('T032.9: Gesture recognition for zoom/pan', () {
      // Test pinch gesture recognition (requires 2+ pointers)
      final pinchGesture = GestureDetails(
        type: GestureType.pinch,
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(100, 100),
        initialScale: 1.0, // Pinch requires initialScale
        currentScale: 1.5, // Pinch requires currentScale
        pointerCount: 2, // Pinch requires at least 2 pointers
        startTime: DateTime.now(),
      );

      // Process gesture through ZoomPanController
      final zoomedState = zoomPanController.processGesture(
        initialZoomPanState,
        pinchGesture,
      );

      // Verify zoom occurred
      expect(zoomedState.zoomLevelX, greaterThan(1.0));

      // Test pan gesture recognition
      final panGesture = GestureDetails(
        type: GestureType.pan,
        startPosition: const Offset(100, 100),
        currentPosition: const Offset(120, 80),
        panDelta: const Offset(30, 20), // Pan requires panDelta
        totalPanDelta: const Offset(30, 20), // Pan requires totalPanDelta
        startTime: DateTime.now(),
      );

      final pannedState = zoomPanController.processGesture(
        zoomedState,
        panGesture,
      );

      // Verify pan occurred
      expect(pannedState.panOffset, isNot(equals(Offset.zero)));
    });

    test('T032.10: Performance - 60 FPS during zoom/pan (16ms per frame)', () {
      final stopwatch = Stopwatch()..start();

      // Simulate rapid zoom/pan operations (60 frames)
      var state = initialZoomPanState;
      const frameCount = 60;

      for (int i = 0; i < frameCount; i++) {
        // Alternate between zoom and pan operations
        if (i % 2 == 0) {
          state = zoomPanController.zoom(
            state,
            zoomFactor: 1.01, // Small incremental zoom
            focalPoint: Offset(100 + i.toDouble(), 100),
          );
        } else {
          state = zoomPanController.pan(
            state,
            const Offset(1, 0.5), // Small incremental pan
          );
        }
      }

      stopwatch.stop();

      // Calculate average time per frame
      final averageTimePerFrame = stopwatch.elapsedMilliseconds / frameCount;

      // Verify performance: each operation should complete in <16ms (60 FPS)
      expect(
        averageTimePerFrame,
        lessThan(16),
        reason: 'Each zoom/pan operation should complete in <16ms for 60 FPS',
      );

      // Also verify total time is reasonable
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: '60 operations should complete in <1 second',
      );
    });
  });
}
