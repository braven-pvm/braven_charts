// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/gestures.dart';

import '../core/coordinator.dart';

/// Base class for custom gesture recognizers that integrate with the coordinator.
///
/// **Purpose**: Enable gesture recognizers to participate in gesture arena while
/// respecting coordinator state, preventing conflicts documented in
/// CONFLICT_RESOLUTION_TABLE.md.
///
/// **Integration**: All custom recognizers extend this class and override:
/// - `canAcceptGesture()`: Check if coordinator allows this gesture
/// - `handleGestureAccepted()`: Claim appropriate mode when gesture wins arena
/// - `handleGestureRejected()`: Release mode if gesture loses arena
///
/// **Example**:
/// ```dart
/// class MyRecognizer extends ContextAwareGestureRecognizer<MyRecognizer> {
///   @override
///   bool canAcceptGesture() => coordinator.canClaimMode(InteractionMode.panning);
///
///   @override
///   void handleGestureAccepted() {
///     coordinator.claimMode(InteractionMode.panning);
///   }
/// }
/// ```
abstract class ContextAwareGestureRecognizer<T extends GestureRecognizer> extends OneSequenceGestureRecognizer {
  ContextAwareGestureRecognizer({
    required this.coordinator,
    super.debugOwner,
    super.supportedDevices,
  });

  /// The interaction coordinator managing gesture state.
  final ChartInteractionCoordinator coordinator;

  /// Subclasses override to check if the gesture can be accepted.
  ///
  /// This is called during gesture arena competition. Return false to
  /// reject the gesture if coordinator state prevents it.
  ///
  /// **Examples**:
  /// - Panning: check `coordinator.canClaimMode(InteractionMode.panning)`
  /// - Selecting: check if not already panning/zooming
  /// - Context menu: check if right-click and not in other modes
  bool canAcceptGesture();

  /// Subclasses override to claim appropriate mode when gesture wins.
  ///
  /// Called after gesture wins arena competition. Claim the appropriate
  /// mode from the coordinator to block conflicting gestures.
  ///
  /// **Examples**:
  /// - Panning: `coordinator.claimMode(InteractionMode.panning)`
  /// - Selecting: `coordinator.claimMode(InteractionMode.selecting)`
  void handleGestureAccepted();

  /// Subclasses override to release mode when gesture loses or ends.
  ///
  /// Called when gesture loses arena or completes. Release any claimed
  /// modes to allow other gestures.
  ///
  /// **Example**: `coordinator.releaseMode()`
  void handleGestureRejected();

  // ============================================================================
  // Arena Integration
  // ============================================================================

  @override
  void rejectGesture(int pointer) {
    handleGestureRejected();
    super.rejectGesture(pointer);
  }

  @override
  void acceptGesture(int pointer) {
    if (!canAcceptGesture()) {
      // Coordinator doesn't allow this gesture - reject it
      rejectGesture(pointer);
      return;
    }

    handleGestureAccepted();
    super.acceptGesture(pointer);
  }

  @override
  String get debugDescription => 'context-aware gesture recognizer';
}
