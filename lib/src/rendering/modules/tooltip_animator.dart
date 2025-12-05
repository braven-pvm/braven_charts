// Copyright (c) 2025 braven_charts. All rights reserved.
// Tooltip Animator - Extracted from ChartRenderBox

import 'dart:async';

import '../../models/interaction_config.dart';

/// Callback type for requesting a repaint.
typedef RepaintCallback = void Function();

/// Manages tooltip show/hide animations with configurable delays.
///
/// This class handles the timing and opacity animation for tooltips:
/// - Show delay: Wait before displaying tooltip on hover
/// - Hide delay: Wait before hiding tooltip when moving away
/// - Fade animation: Smooth opacity transitions
///
/// **Usage**:
/// `dart
/// final animator = TooltipAnimator(onRepaint: markNeedsPaint);
/// animator.show(markerInfo, config);
/// animator.hide(config);
/// `
///
/// **Performance**:
/// - Uses Timer.periodic for smooth 60fps fade animation
/// - Properly cancels timers to prevent memory leaks
/// - Minimal overhead when not animating
class TooltipAnimator {
  TooltipAnimator({
    required this.onRepaint,
  });

  /// Callback invoked when a repaint is needed (opacity changed).
  final RepaintCallback onRepaint;

  /// Current tooltip opacity (0.0 = hidden, 1.0 = fully visible).
  double _opacity = 0.0;

  /// Timer for delaying tooltip show.
  Timer? _showTimer;

  /// Timer for delaying tooltip hide.
  Timer? _hideTimer;

  /// Timer for fade animation steps.
  Timer? _fadeTimer;

  /// Target marker for detecting marker changes and drawing.
  /// Generic type allows different marker info objects.
  Object? _targetMarker;

  /// Whether this animator has been disposed.
  bool _disposed = false;

  /// Gets current tooltip opacity.
  double get opacity => _opacity;

  /// Whether the tooltip is visible (opacity > 0).
  bool get isVisible => _opacity > 0.001;

  /// Gets the current target marker (for drawing during fade-out).
  /// Returns null when no target is set.
  T? getTargetMarker<T>() => _targetMarker as T?;

  /// Shows tooltip with configured delay and fade-in animation.
  ///
  /// [marker] is the marker info object (stored for drawing during animations).
  /// [config] provides show delay configuration.
  void show(Object marker, TooltipConfig config) {
    // Cancel existing timers
    _showTimer?.cancel();
    _hideTimer?.cancel();

    // Cache target marker to detect changes
    _targetMarker = marker;

    // If showDelay is zero, show immediately
    if (config.showDelay == Duration.zero) {
      _animateOpacity(1.0, const Duration(milliseconds: 150));
      return;
    }

    // Start show delay timer
    _showTimer = Timer(config.showDelay, () {
      // Only show if still targeting same marker
      if (_targetMarker == marker) {
        _animateOpacity(1.0, const Duration(milliseconds: 150));
      }
    });
  }

  /// Hides tooltip with configured delay and fade-out animation.
  ///
  /// [config] provides hide delay configuration.
  /// Note: Does NOT clear the target marker immediately to allow drawing during fade-out.
  void hide(TooltipConfig config) {
    // Cancel show timer (user moved away before delay finished)
    _showTimer?.cancel();

    // If hideDelay is zero, hide immediately
    if (config.hideDelay == Duration.zero) {
      _animateOpacity(0.0, const Duration(milliseconds: 100));
      return;
    }

    // Start hide delay timer
    _hideTimer = Timer(config.hideDelay, () {
      _animateOpacity(0.0, const Duration(milliseconds: 100));
    });
  }

  /// Immediately hides tooltip without animation.
  ///
  /// IMPORTANT: This method does NOT call onRepaint() because it's typically
  /// called during the paint phase where markNeedsPaint() is invalid.
  /// The caller is already in paint(), so the current frame will reflect
  /// the new opacity value.
  void hideImmediately() {
    cancelAll();
    _opacity = 0.0;
    // Note: Do not call onRepaint() here - this is called during paint()
  }

  /// Cancels all timers and resets animation state.
  void cancelAll() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _targetMarker = null;
  }

  /// Disposes resources. Must be called when the animator is no longer needed.
  void dispose() {
    _disposed = true;
    cancelAll();
  }

  /// Safely requests a repaint if not disposed.
  void _safeRepaint() {
    if (!_disposed) {
      onRepaint();
    }
  }

  /// Animates opacity to target value over specified duration.
  void _animateOpacity(double target, Duration duration) {
    _fadeTimer?.cancel();

    // Don't animate if disposed
    if (_disposed) return;

    final startOpacity = _opacity;
    final delta = target - startOpacity;

    // If already at target, nothing to do
    if (delta.abs() < 0.001) {
      _opacity = target;
      _safeRepaint();
      return;
    }

    // Animate in small steps for smooth fade
    const fps = 60;
    const stepDuration = Duration(milliseconds: 1000 ~/ fps);
    final totalSteps = (duration.inMilliseconds * fps / 1000).round();
    var currentStep = 0;

    _fadeTimer = Timer.periodic(stepDuration, (timer) {
      // Stop if disposed during animation
      if (_disposed) {
        timer.cancel();
        return;
      }

      currentStep++;

      if (currentStep >= totalSteps) {
        _opacity = target;
        timer.cancel();
        _safeRepaint();
      } else {
        final progress = currentStep / totalSteps;
        _opacity = startOpacity + delta * progress;
        _safeRepaint();
      }
    });
  }
}
