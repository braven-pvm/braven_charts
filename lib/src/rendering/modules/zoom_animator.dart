// Copyright (c) 2025 braven_charts. All rights reserved.
// Zoom Animator - Smooth zoom transitions with easing

import 'dart:async';

import '../../coordinates/chart_transform.dart';

/// Callback for applying animated transform and triggering repaint.
typedef ZoomUpdateCallback = void Function(ChartTransform transform);

/// Callback for completing the animation (element regeneration, etc.).
typedef ZoomCompleteCallback = void Function();

/// Manages smooth zoom animations with configurable easing.
///
/// This class handles animated transitions between zoom states:
/// - Interpolates between start and target transform states
/// - Applies configurable easing curves for natural motion
/// - Supports animation cancellation for new zoom requests
///
/// **Usage**:
/// ```dart
/// final animator = ZoomAnimator(
///   onUpdate: (transform) {
///     _transform = transform;
///     markNeedsPaint();
///   },
///   onComplete: () {
///     _rebuildElementsWithTransform();
///   },
/// );
///
/// animator.animateTo(currentTransform, targetTransform);
/// ```
///
/// **Performance**:
/// - Uses Timer.periodic for smooth 60fps animation
/// - Properly cancels timers to prevent memory leaks
/// - Eased interpolation prevents jarring visual transitions
class ZoomAnimator {
  ZoomAnimator({
    required this.onUpdate,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 250),
  });

  /// Callback invoked on each animation frame with interpolated transform.
  final ZoomUpdateCallback onUpdate;

  /// Callback invoked when animation completes (for element regeneration).
  final ZoomCompleteCallback onComplete;

  /// Default animation duration.
  final Duration duration;

  /// Timer for animation steps.
  Timer? _animationTimer;

  /// Starting transform state.
  ChartTransform? _startTransform;

  /// Target transform state.
  ChartTransform? _targetTransform;

  /// Whether this animator has been disposed.
  bool _disposed = false;

  /// Whether an animation is currently in progress.
  bool get isAnimating => _animationTimer != null;

  /// Animates from current transform to target transform.
  ///
  /// If an animation is already in progress, it will be cancelled and
  /// a new animation will start from the current interpolated position.
  ///
  /// [from] is the starting transform state.
  /// [to] is the target transform state.
  /// [customDuration] optionally overrides the default duration.
  void animateTo(
    ChartTransform from,
    ChartTransform to, {
    Duration? customDuration,
  }) {
    if (_disposed) return;

    // Cancel any existing animation
    _animationTimer?.cancel();

    _startTransform = from;
    _targetTransform = to;

    final animationDuration = customDuration ?? duration;

    // If duration is zero, apply immediately
    if (animationDuration == Duration.zero) {
      onUpdate(to);
      onComplete();
      return;
    }

    // Animate with easing
    const fps = 60;
    const stepDuration = Duration(milliseconds: 1000 ~/ fps);
    final totalSteps = (animationDuration.inMilliseconds * fps / 1000).round();
    var currentStep = 0;

    _animationTimer = Timer.periodic(stepDuration, (timer) {
      if (_disposed) {
        timer.cancel();
        _animationTimer = null;
        return;
      }

      currentStep++;

      if (currentStep >= totalSteps) {
        // Final step - apply exact target
        timer.cancel();
        _animationTimer = null;
        onUpdate(_targetTransform!);
        onComplete();
      } else {
        // Interpolate with easing
        final t = currentStep / totalSteps;
        final easedT = _easeOutCubic(t);
        final interpolated = _interpolateTransform(
          _startTransform!,
          _targetTransform!,
          easedT,
        );
        onUpdate(interpolated);
      }
    });
  }

  /// Cancels any in-progress animation.
  void cancel() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  /// Disposes resources. Must be called when the animator is no longer needed.
  void dispose() {
    _disposed = true;
    cancel();
    _startTransform = null;
    _targetTransform = null;
  }

  /// Cubic ease-out curve for natural deceleration.
  ///
  /// Starts fast, then decelerates to a smooth stop.
  double _easeOutCubic(double t) {
    return 1.0 - ((1.0 - t) * (1.0 - t) * (1.0 - t));
  }

  /// Interpolates between two transforms.
  ///
  /// Linearly interpolates all data bounds to create smooth zoom transition.
  ChartTransform _interpolateTransform(
    ChartTransform from,
    ChartTransform to,
    double t,
  ) {
    return ChartTransform(
      dataXMin: _lerp(from.dataXMin, to.dataXMin, t),
      dataXMax: _lerp(from.dataXMax, to.dataXMax, t),
      dataYMin: _lerp(from.dataYMin, to.dataYMin, t),
      dataYMax: _lerp(from.dataYMax, to.dataYMax, t),
      plotWidth: to.plotWidth,
      plotHeight: to.plotHeight,
      invertY: to.invertY,
    );
  }

  /// Linear interpolation between two values.
  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
