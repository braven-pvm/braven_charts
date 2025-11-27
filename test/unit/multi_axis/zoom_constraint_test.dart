// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for Y-axis zoom constraint in multi-axis mode (FR-013)

import 'dart:ui' show Offset, Rect;

import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:braven_charts/src_plus/interaction/multi_axis_zoom_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test for FR-013: Y-axis zoom must be disabled when multi-axis mode is active.
///
/// Rationale: In multi-axis mode, each series is normalized to its own axis.
/// Zooming on Y would change which part of normalized space is visible,
/// breaking the visual mapping. X-axis zoom remains functional.
void main() {
  group('Y-axis zoom constraint in multi-axis mode', () {
    late MultiAxisZoomController controller;
    late ZoomPanState initialState;

    setUp(() {
      controller = MultiAxisZoomController();
      // Create initial state with known values
      const dataBounds = Rect.fromLTWH(0, 0, 100, 100);
      initialState = const ZoomPanState(
        zoomLevelX: 1.0,
        zoomLevelY: 1.0,
        panOffset: Offset.zero,
        visibleDataBounds: dataBounds,
        originalDataBounds: dataBounds,
        minZoomLevel: 0.5,
        maxZoomLevel: 4.0,
        allowOverscroll: false,
      );
    });

    group('Normal mode (multi-axis disabled)', () {
      test('should allow both X and Y zoom when multi-axis mode is inactive', () {
        // Zoom in normal mode (isMultiAxisMode = false)
        final zoomedState = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: false,
        );

        // Both X and Y should be zoomed
        expect(zoomedState.zoomLevelX, equals(2.0));
        expect(zoomedState.zoomLevelY, equals(2.0));
      });

      test('should apply zoom factor to both axes in normal mode', () {
        final state = controller.zoom(
          initialState,
          zoomFactor: 1.5,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: false,
        );

        expect(state.zoomLevelX, equals(1.5));
        expect(state.zoomLevelY, equals(1.5));
      });
    });

    group('Multi-axis mode X-axis zoom', () {
      test('should allow X-axis zoom when multi-axis mode is active', () {
        final zoomedState = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // X should be zoomed
        expect(zoomedState.zoomLevelX, equals(2.0));
      });

      test('should correctly calculate X zoom with various zoom factors', () {
        // Test zoom in
        var state = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );
        expect(state.zoomLevelX, equals(2.0));

        // Test zoom out
        state = controller.zoom(
          state,
          zoomFactor: 0.5,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );
        expect(state.zoomLevelX, equals(1.0)); // Back to original
      });

      test('should respect X zoom limits in multi-axis mode', () {
        // Try to zoom beyond max
        final tooMuchZoom = controller.zoom(
          initialState,
          zoomFactor: 10.0, // Exceed maxZoomLevel of 4.0
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        expect(tooMuchZoom.zoomLevelX, equals(4.0)); // Clamped to max

        // Try to zoom below min
        final tooLittleZoom = controller.zoom(
          initialState,
          zoomFactor: 0.1, // Below minZoomLevel of 0.5
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        expect(tooLittleZoom.zoomLevelX, equals(0.5)); // Clamped to min
      });
    });

    group('Multi-axis mode Y-axis zoom constraint', () {
      test('should prevent Y-axis zoom when multi-axis mode is active', () {
        final zoomedState = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // Y should remain at 1.0 (unchanged)
        expect(zoomedState.zoomLevelY, equals(1.0));
      });

      test('should maintain Y zoom level of 1.0 through multiple zoom operations', () {
        var state = initialState;

        // Apply multiple zoom operations
        for (var i = 0; i < 5; i++) {
          state = controller.zoom(
            state,
            zoomFactor: 1.2,
            focalPoint: const Offset(400, 200),
            isMultiAxisMode: true,
          );

          // Y should always remain at 1.0
          expect(state.zoomLevelY, equals(1.0));
        }

        // X should have been zoomed (1.2 ^ 5 = 2.48832)
        expect(state.zoomLevelX, closeTo(2.48832, 0.001));
      });

      test('should preserve Y zoom level during zoom out operations', () {
        // First zoom in on X
        var state = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        expect(state.zoomLevelY, equals(1.0));

        // Then zoom out on X
        state = controller.zoom(
          state,
          zoomFactor: 0.5,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // Y should still be at 1.0
        expect(state.zoomLevelY, equals(1.0));
      });
    });

    group('Pan behavior in multi-axis mode', () {
      test('should allow X-axis pan in multi-axis mode', () {
        final pannedState = controller.pan(
          initialState,
          const Offset(50, 0), // Pan right
          isMultiAxisMode: true,
        );

        expect(pannedState.panOffset.dx, equals(50.0));
      });

      test('should prevent Y-axis pan in multi-axis mode', () {
        final pannedState = controller.pan(
          initialState,
          const Offset(0, 50), // Attempt to pan down
          isMultiAxisMode: true,
        );

        // Y pan should be blocked
        expect(pannedState.panOffset.dy, equals(0.0));
      });

      test('should allow X pan while blocking Y pan in multi-axis mode', () {
        final pannedState = controller.pan(
          initialState,
          const Offset(50, 30), // Attempt diagonal pan
          isMultiAxisMode: true,
        );

        // X should be panned, Y should remain at 0
        expect(pannedState.panOffset.dx, equals(50.0));
        expect(pannedState.panOffset.dy, equals(0.0));
      });

      test('should allow both X and Y pan in normal mode', () {
        final pannedState = controller.pan(
          initialState,
          const Offset(50, 30),
          isMultiAxisMode: false,
        );

        expect(pannedState.panOffset.dx, equals(50.0));
        expect(pannedState.panOffset.dy, equals(30.0));
      });
    });

    group('Mode switching behavior', () {
      test('should preserve Y zoom at 1.0 when switching to multi-axis mode', () {
        // First zoom in normal mode
        var state = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: false,
        );

        expect(state.zoomLevelY, equals(2.0));

        // Then zoom in multi-axis mode should constrain Y to 1.0
        // Note: In practice, mode switching would reset Y zoom to 1.0
        state = controller.zoom(
          state,
          zoomFactor: 1.0, // No additional zoom
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // Y should be constrained to 1.0 in multi-axis mode
        expect(state.zoomLevelY, equals(1.0));
      });
    });

    group('Edge cases', () {
      test('should handle zoom factor of 1.0 (no zoom)', () {
        final state = controller.zoom(
          initialState,
          zoomFactor: 1.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        expect(state.zoomLevelX, equals(1.0));
        expect(state.zoomLevelY, equals(1.0));
      });

      test('should handle very small zoom factors', () {
        final state = controller.zoom(
          initialState,
          zoomFactor: 0.001,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // Should be clamped to minZoomLevel
        expect(state.zoomLevelX, equals(0.5));
        expect(state.zoomLevelY, equals(1.0)); // Y unaffected
      });

      test('should handle very large zoom factors', () {
        final state = controller.zoom(
          initialState,
          zoomFactor: 1000.0,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );

        // Should be clamped to maxZoomLevel
        expect(state.zoomLevelX, equals(4.0));
        expect(state.zoomLevelY, equals(1.0)); // Y unaffected
      });

      test('should handle zoom at origin focal point', () {
        final state = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: Offset.zero,
          isMultiAxisMode: true,
        );

        expect(state.zoomLevelX, equals(2.0));
        expect(state.zoomLevelY, equals(1.0));
      });

      test('should handle negative focal point coordinates', () {
        // Edge case - focal point outside normal bounds
        final state = controller.zoom(
          initialState,
          zoomFactor: 2.0,
          focalPoint: const Offset(-100, -50),
          isMultiAxisMode: true,
        );

        expect(state.zoomLevelX, equals(2.0));
        expect(state.zoomLevelY, equals(1.0));
      });
    });

    group('Integration scenarios', () {
      test('should support typical multi-axis chart interaction pattern', () {
        var state = initialState;

        // User pans horizontally
        state = controller.pan(state, const Offset(50, 0), isMultiAxisMode: true);
        expect(state.panOffset.dx, equals(50.0));
        expect(state.panOffset.dy, equals(0.0));

        // User zooms in on X
        state = controller.zoom(
          state,
          zoomFactor: 1.5,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );
        expect(state.zoomLevelX, equals(1.5));
        expect(state.zoomLevelY, equals(1.0));

        // User pans more
        state = controller.pan(state, const Offset(25, 10), isMultiAxisMode: true);
        expect(state.panOffset.dy, equals(0.0)); // Y pan blocked

        // User zooms out
        state = controller.zoom(
          state,
          zoomFactor: 0.5,
          focalPoint: const Offset(400, 200),
          isMultiAxisMode: true,
        );
        expect(state.zoomLevelX, closeTo(0.75, 0.001));
        expect(state.zoomLevelY, equals(1.0));
      });
    });
  });
}
