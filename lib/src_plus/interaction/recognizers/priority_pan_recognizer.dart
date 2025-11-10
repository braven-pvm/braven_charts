// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';

import '../core/interaction_mode.dart';
import 'context_aware_recognizer.dart';

/// Pan recognizer with coordinator integration for conflict-free panning.
///
/// **Purpose**: Implement middle-click exclusive panning per
/// CONFLICT_RESOLUTION_TABLE.md Mouse Event Responsibilities.
///
/// **Behavior** (per conflict resolution):
/// - **Middle button (button=1)**: EXCLUSIVE pan - no conflicts allowed
/// - **Priority**: CRITICAL (10) - wins all conflicts
/// - **Mode claiming**: Claims `InteractionMode.panning` on gesture start
/// - **Conflict handling**: Rejects gesture if coordinator busy with higher priority
///
/// **Usage**:
/// ```dart
/// final recognizer = PriorityPanGestureRecognizer(
///   coordinator: coordinator,
///   onPanStart: (details) => print('Pan started'),
///   onPanUpdate: (details) => applyPan(details.delta),
///   onPanEnd: (details) => print('Pan ended'),
/// );
/// ```
class PriorityPanGestureRecognizer extends ContextAwareGestureRecognizer<PanGestureRecognizer> {
  PriorityPanGestureRecognizer({
    required super.coordinator,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    super.debugOwner,
    super.supportedDevices,
  });

  /// Called when pan gesture starts.
  final GestureDragStartCallback? onPanStart;

  /// Called when pan position updates.
  final GestureDragUpdateCallback? onPanUpdate;

  /// Called when pan gesture ends normally.
  final GestureDragEndCallback? onPanEnd;

  /// Called when pan gesture is cancelled.
  final GestureDragCancelCallback? onPanCancel;

  // ============================================================================
  // State Tracking
  // ============================================================================

  /// The pointer that started this pan gesture.
  int? _activePointer;

  /// Starting position of the pan.
  Offset? _startPosition;

  /// Whether we've claimed the panning mode.
  bool _hasClaimedMode = false;

  // ============================================================================
  // Gesture Detection
  // ============================================================================

  @override
  void addPointer(PointerDownEvent event) {
    // DISABLED: Middle mouse panning is handled by ChartRenderBox.handleEvent()
    // Gesture recognizer should NOT handle middle mouse to avoid double-processing
    // This recognizer is reserved for touch/primary button gestures (future use)
    return;

    // Old code (caused double-pan bug with RenderBox):
    // if (event.buttons != kMiddleMouseButton) {
    //   return;
    // }
    // startTrackingPointer(event.pointer);
    // _activePointer = event.pointer;
    // _startPosition = event.position;
    // resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    // Required by OneSequenceGestureRecognizer
    // Clean up when pointer tracking stops
    _cleanup();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;

    if (event is PointerMoveEvent) {
      _handlePointerMove(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePointerEnd(event);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_startPosition == null) return;

    // Claim mode on first move (lazy claiming)
    if (!_hasClaimedMode && canAcceptGesture()) {
      handleGestureAccepted();
    }

    if (_hasClaimedMode) {
      onPanUpdate?.call(
        DragUpdateDetails(sourceTimeStamp: event.timeStamp, delta: event.delta, globalPosition: event.position, localPosition: event.localPosition),
      );
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_hasClaimedMode) {
      if (event is PointerUpEvent) {
        onPanEnd?.call(DragEndDetails(velocity: Velocity.zero, primaryVelocity: 0.0));
      } else {
        onPanCancel?.call();
      }
    }

    _cleanup();
  }

  void _cleanup() {
    if (_activePointer != null) {
      stopTrackingPointer(_activePointer!);
    }
    _activePointer = null;
    _startPosition = null;

    if (_hasClaimedMode) {
      handleGestureRejected();
      _hasClaimedMode = false;
    }
  }

  // ============================================================================
  // ContextAwareGestureRecognizer Implementation
  // ============================================================================

  @override
  bool canAcceptGesture() {
    // Per conflict resolution: middle-click pan is CRITICAL priority (10)
    // Can claim mode unless context menu is open (blocks everything)
    return coordinator.canStartInteraction(InteractionMode.panning);
  }

  @override
  void handleGestureAccepted() {
    final claimed = coordinator.claimMode(InteractionMode.panning);
    if (claimed) {
      _hasClaimedMode = true;
      onPanStart?.call(
        DragStartDetails(sourceTimeStamp: null, globalPosition: _startPosition ?? Offset.zero, localPosition: _startPosition ?? Offset.zero),
      );
    }
  }

  @override
  void handleGestureRejected() {
    if (_hasClaimedMode) {
      coordinator.releaseMode();
      _hasClaimedMode = false;
      onPanCancel?.call();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  String get debugDescription => 'priority pan recognizer (middle-click)';
}
