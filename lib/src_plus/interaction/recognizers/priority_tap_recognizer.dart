// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';

import '../core/interaction_mode.dart';
import 'context_aware_recognizer.dart';

/// Tap recognizer with coordinator integration for element selection.
///
/// **Purpose**: Implement left-click selection per
/// CONFLICT_RESOLUTION_TABLE.md Mouse Event Responsibilities.
///
/// **Behavior** (per conflict resolution):
/// - **Left button (button=0)**: Element selection, respects priority
/// - **Priority**: Varies by element (datapoint=6, annotation=7-9, series=5)
/// - **Mode claiming**: Claims `InteractionMode.selecting` on tap
/// - **Multi-select**: Supports Ctrl+click for multi-selection
///
/// **Usage**:
/// ```dart
/// final recognizer = PriorityTapGestureRecognizer(
///   coordinator: coordinator,
///   onTapDown: (details) => handleTapDown(details.globalPosition),
///   onTapUp: (details) => handleSelection(),
///   onTapCancel: () => clearSelection(),
/// );
/// ```
class PriorityTapGestureRecognizer extends ContextAwareGestureRecognizer<TapGestureRecognizer> {
  PriorityTapGestureRecognizer({
    required super.coordinator,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    super.debugOwner,
    super.supportedDevices,
  });

  /// Called when pointer down detected (potential tap start).
  final GestureTapDownCallback? onTapDown;

  /// Called when tap completes successfully.
  final GestureTapUpCallback? onTapUp;

  /// Called when tap is cancelled.
  final GestureTapCancelCallback? onTapCancel;

  // ============================================================================
  // State Tracking
  // ============================================================================

  /// The pointer that started this tap gesture.
  int? _activePointer;

  /// Starting position of the tap.
  Offset? _downPosition;

  /// Whether we've claimed the selecting mode.
  bool _hasClaimedMode = false;

  /// Guard to prevent recursive cleanup.
  bool _isCleaningUp = false;

  /// Maximum allowed movement for a tap (px).
  static const double _kTapSlop = 18.0;

  // ============================================================================
  // Gesture Detection
  // ============================================================================

  @override
  void addPointer(PointerDownEvent event) {
    // Only accept left button for selection (per conflict resolution)
    if (event.buttons != kPrimaryMouseButton) {
      return;
    }

    // Don't accept if coordinator already in incompatible mode
    if (!coordinator.canStartInteraction(InteractionMode.selecting)) {
      return;
    }

    startTrackingPointer(event.pointer);
    _activePointer = event.pointer;
    _downPosition = event.position;

    // Notify tap down
    onTapDown?.call(TapDownDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      kind: event.kind,
    ));

    resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    // Required by OneSequenceGestureRecognizer
    _cleanup();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;

    if (event is PointerMoveEvent) {
      _handlePointerMove(event);
    } else if (event is PointerUpEvent) {
      _handlePointerUp(event);
    } else if (event is PointerCancelEvent) {
      _handlePointerCancel(event);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_downPosition == null) return;

    // Check if moved beyond tap slop threshold
    final distance = (event.position - _downPosition!).distance;
    if (distance > _kTapSlop) {
      // Moved too far - check if coordinator has claimed a higher priority mode
      // If dragging/resizing annotation (priority 8-9), let it continue
      // Otherwise cancel tap (might be drag/box-select)
      if (!coordinator.currentMode.isDragging && coordinator.currentMode != InteractionMode.resizingAnnotation) {
        _cancel();
      } else {
        // Higher priority drag in progress - silently cleanup without releasing mode
        _cleanupWithoutRelease();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_downPosition == null) return;

    // Check if still within tap slop
    final distance = (event.position - _downPosition!).distance;
    if (distance <= _kTapSlop) {
      // Valid tap - claim mode and complete
      if (canAcceptGesture()) {
        handleGestureAccepted();

        onTapUp?.call(TapUpDetails(
          kind: event.kind,
          globalPosition: event.position,
          localPosition: event.localPosition,
        ));
      }
    }

    _cleanup();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _cancel();
  }

  void _cancel() {
    onTapCancel?.call();
    _cleanup();
  }

  void _cleanup() {
    // Guard against recursive cleanup (didStopTrackingLastPointer calls this)
    if (_isCleaningUp) {
      return;
    }

    _isCleaningUp = true;

    if (_activePointer != null) {
      stopTrackingPointer(_activePointer!);
    }
    _activePointer = null;
    _downPosition = null;

    if (_hasClaimedMode) {
      if (coordinator.currentMode == InteractionMode.boxSelecting) {
        // Skip release because we've transitioned to box select
      } else {
        handleGestureRejected();
      }
      _hasClaimedMode = false;
    }

    _isCleaningUp = false;
  }

  /// Cleanup without releasing coordinator mode (for when higher priority mode has taken over).
  void _cleanupWithoutRelease() {
    if (_isCleaningUp) {
      return;
    }

    _isCleaningUp = true;

    if (_activePointer != null) {
      stopTrackingPointer(_activePointer!);
    }
    _activePointer = null;
    _downPosition = null;
    _hasClaimedMode = false; // Clear flag without calling handleGestureRejected

    _isCleaningUp = false;
  }

  // ============================================================================
  // ContextAwareGestureRecognizer Implementation
  // ============================================================================

  @override
  bool canAcceptGesture() {
    // Can select if not currently panning, zooming, or in context menu
    return coordinator.canStartInteraction(InteractionMode.selecting);
  }

  @override
  void handleGestureAccepted() {
    final claimed = coordinator.claimMode(InteractionMode.selecting);
    if (claimed) {
      _hasClaimedMode = true;
    }
  }

  @override
  void handleGestureRejected() {
    if (_hasClaimedMode) {
      coordinator.releaseMode();
      _hasClaimedMode = false;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  String get debugDescription => 'priority tap recognizer (left-click selection)';
}
