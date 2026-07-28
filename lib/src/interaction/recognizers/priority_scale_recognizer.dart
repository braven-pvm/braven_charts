// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import '../core/coordinator.dart';
import '../core/interaction_mode.dart';

/// Touch viewport recognizer that preserves parent scrolling in browse mode.
///
/// Unlike Flutter's general [ScaleGestureRecognizer], this recognizer does not
/// accept a browse-profile gesture for one pointer. The surrounding
/// [Scrollable] therefore remains free to own ordinary one-finger page
/// scrolling. A second pointer is the explicit signal that the chart should
/// claim the gesture arena.
class PriorityScaleGestureRecognizer extends OneSequenceGestureRecognizer {
  PriorityScaleGestureRecognizer({
    required this.coordinator,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    super.debugOwner,
    super.supportedDevices,
  });

  final ChartInteractionCoordinator coordinator;
  final GestureScaleStartCallback onStart;
  final GestureScaleUpdateCallback onUpdate;
  final GestureScaleEndCallback onEnd;

  /// Whether this recognizer should admit new pointers.
  bool enabled = true;

  /// One for explore mode and two for browse mode.
  int minimumPointerCount = 2;

  /// Movement required before explore mode claims a one-pointer drag.
  double panThreshold = 10;

  /// Optional hit test for a one-finger chart control that must beat an
  /// ancestor scrollable while leaving ordinary chart touches scrollable.
  bool Function(PointerDownEvent event)? shouldClaimPrimaryPointer;

  final Map<int, Offset> _globalPositions = <int, Offset>{};
  final Map<int, Offset> _localPositions = <int, Offset>{};
  final Map<int, Offset> _downPositions = <int, Offset>{};

  bool _accepted = false;
  bool _ownsPrimarySequence = false;
  bool _viewportClaimed = false;
  bool _started = false;
  bool _ended = false;
  Offset _previousGlobalFocalPoint = Offset.zero;
  Offset _previousLocalFocalPoint = Offset.zero;
  double _referenceSpan = 1;
  double _segmentScaleBase = 1;
  double _currentScale = 1;
  Duration? _sourceTimeStamp;
  PointerDeviceKind? _kind;
  VelocityTracker? _focalVelocityTracker;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      enabled && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_ended) {
      super.addAllowedPointer(event);
      resolvePointer(event.pointer, GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      return;
    }
    final isFirstPointer = _globalPositions.isEmpty;
    super.addAllowedPointer(event);
    _globalPositions[event.pointer] = event.position;
    _localPositions[event.pointer] = event.localPosition;
    _downPositions[event.pointer] = event.position;
    _sourceTimeStamp ??= event.timeStamp;
    _kind ??= event.kind;
    _rebaseScaleSegment();

    if (isFirstPointer && (shouldClaimPrimaryPointer?.call(event) ?? false)) {
      _ownsPrimarySequence = true;
      // The render object owns the brush manipulation itself. This recognizer
      // claims the arena immediately so a vertical brush handle cannot drag
      // the surrounding page. It remains the same recognizer when a second
      // finger arrives, allowing the viewport gesture to take over.
      resolve(GestureDisposition.accepted);
      return;
    }

    // Browse mode may claim as soon as its explicit second pointer arrives.
    // Explore mode must leave a stationary one-pointer sequence available to
    // tap/long-press recognizers and claim only after [panThreshold] movement.
    if (minimumPointerCount > 1 &&
        _globalPositions.length >= minimumPointerCount) {
      resolve(GestureDisposition.accepted);
      if (_accepted) _tryClaimViewport();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_globalPositions.containsKey(event.pointer)) return;

    if (event is PointerMoveEvent) {
      _globalPositions[event.pointer] = event.position;
      _localPositions[event.pointer] = event.localPosition;

      if (!_accepted &&
          minimumPointerCount == 1 &&
          (event.position - _downPositions[event.pointer]!).distance >=
              panThreshold) {
        resolve(GestureDisposition.accepted);
      }

      if (_accepted && !_ended) {
        _tryClaimViewport();
        if (_viewportClaimed) {
          _startIfNeeded();
          _dispatchUpdate(event.timeStamp);
        }
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _globalPositions.remove(event.pointer);
      _localPositions.remove(event.pointer);
      _downPositions.remove(event.pointer);

      if (_started &&
          !_ended &&
          _globalPositions.length < minimumPointerCount) {
        _finish();
      } else if (!_ended && _globalPositions.isNotEmpty) {
        _rebaseScaleSegment();
      }

      if (_globalPositions.isEmpty && !_accepted) {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_accepted || _ended) return;
    if (_ownsPrimarySequence) {
      _accepted = true;
      _tryClaimViewport();
      return;
    }
    if (_globalPositions.length < minimumPointerCount ||
        !coordinator.canStartInteraction(
          InteractionMode.transformingViewport,
        )) {
      resolve(GestureDisposition.rejected);
      return;
    }
    if (!coordinator.claimMode(InteractionMode.transformingViewport)) {
      resolve(GestureDisposition.rejected);
      return;
    }
    _accepted = true;
    _viewportClaimed = true;
    _startIfNeeded();
  }

  @override
  void rejectGesture(int pointer) {
    _globalPositions.remove(pointer);
    _localPositions.remove(pointer);
    _downPositions.remove(pointer);
    stopTrackingPointer(pointer);
    if (_globalPositions.isEmpty) {
      if (_started && !_ended) _finish();
      _reset();
    }
  }

  void _startIfNeeded() {
    if (_started ||
        _ended ||
        !_viewportClaimed ||
        _globalPositions.length < minimumPointerCount) {
      return;
    }
    _started = true;
    _previousGlobalFocalPoint = _globalFocalPoint;
    _previousLocalFocalPoint = _localFocalPoint;
    final kind = _kind;
    if (kind != null) {
      _focalVelocityTracker = VelocityTracker.withKind(kind)
        ..addPosition(
          _sourceTimeStamp ?? Duration.zero,
          _previousGlobalFocalPoint,
        );
    }
    _rebaseScaleSegment();
    invokeCallback<void>('onStart', () {
      onStart(
        ScaleStartDetails(
          focalPoint: _previousGlobalFocalPoint,
          localFocalPoint: _previousLocalFocalPoint,
          pointerCount: _globalPositions.length,
          sourceTimeStamp: _sourceTimeStamp,
          kind: _kind,
        ),
      );
    });
  }

  void _dispatchUpdate(Duration timeStamp) {
    final globalFocalPoint = _globalFocalPoint;
    final localFocalPoint = _localFocalPoint;
    final span = _spanAround(globalFocalPoint, _globalPositions.values);
    final segmentScale = _referenceSpan <= 0 ? 1 : span / _referenceSpan;
    _currentScale = _segmentScaleBase * segmentScale;
    _focalVelocityTracker?.addPosition(timeStamp, globalFocalPoint);

    final details = ScaleUpdateDetails(
      focalPoint: globalFocalPoint,
      localFocalPoint: localFocalPoint,
      focalPointDelta: localFocalPoint - _previousLocalFocalPoint,
      scale: _currentScale,
      horizontalScale: _currentScale,
      verticalScale: _currentScale,
      pointerCount: _globalPositions.length,
      sourceTimeStamp: timeStamp,
    );
    _previousGlobalFocalPoint = globalFocalPoint;
    _previousLocalFocalPoint = localFocalPoint;
    invokeCallback<void>('onUpdate', () => onUpdate(details));
  }

  void _tryClaimViewport() {
    if (!_accepted ||
        _viewportClaimed ||
        _globalPositions.length < minimumPointerCount ||
        !coordinator.canStartInteraction(
          InteractionMode.transformingViewport,
        )) {
      return;
    }
    if (coordinator.claimMode(InteractionMode.transformingViewport)) {
      _viewportClaimed = true;
      _startIfNeeded();
    }
  }

  void _finish() {
    _ended = true;
    final velocity = _focalVelocityTracker?.getVelocity() ?? Velocity.zero;
    invokeCallback<void>('onEnd', () {
      onEnd(
        ScaleEndDetails(
          velocity: velocity,
          pointerCount: _globalPositions.length,
        ),
      );
    });
    if (coordinator.currentMode == InteractionMode.transformingViewport) {
      coordinator.releaseMode();
    }
  }

  void _rebaseScaleSegment() {
    if (_globalPositions.isEmpty) return;
    _segmentScaleBase = _currentScale;
    _referenceSpan = math.max(
      1,
      _spanAround(_globalFocalPoint, _globalPositions.values),
    );
    _previousGlobalFocalPoint = _globalFocalPoint;
    _previousLocalFocalPoint = _localFocalPoint;
  }

  Offset get _globalFocalPoint => _centroidOf(_globalPositions.values);

  Offset get _localFocalPoint => _centroidOf(_localPositions.values);

  static Offset _centroidOf(Iterable<Offset> positions) {
    var total = Offset.zero;
    var count = 0;
    for (final position in positions) {
      total += position;
      count++;
    }
    return count == 0 ? Offset.zero : total / count.toDouble();
  }

  static double _spanAround(Offset focalPoint, Iterable<Offset> positions) {
    var total = 0.0;
    var count = 0;
    for (final position in positions) {
      total += (position - focalPoint).distance;
      count++;
    }
    // A single pointer has translation but no measurable scale span. Keep its
    // scale neutral so Explore mode can transition from one-finger pan to a
    // two-finger pinch without rebasing from zero.
    return count <= 1 ? 1 : total / count;
  }

  void _reset() {
    _accepted = false;
    _ownsPrimarySequence = false;
    _viewportClaimed = false;
    _started = false;
    _ended = false;
    _sourceTimeStamp = null;
    _kind = null;
    _focalVelocityTracker = null;
    _referenceSpan = 1;
    _segmentScaleBase = 1;
    _currentScale = 1;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_started && !_ended) _finish();
    _reset();
  }

  @override
  void dispose() {
    if (_started && !_ended) _finish();
    super.dispose();
  }

  @override
  String get debugDescription => 'priority touch viewport transform';
}
