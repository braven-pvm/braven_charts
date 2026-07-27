// Copyright (c) 2025 braven_charts. All rights reserved.
// Tooltip Animator - Extracted from ChartRenderBox

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import '../../models/interaction_config.dart';

/// Callback type for requesting a repaint.
typedef RepaintCallback = void Function();

/// Callback type for queueing work at the start of a rendered frame.
typedef RepaintFrameScheduler = void Function(void Function() callback);

/// Pre-warms text rendering infrastructure to eliminate first-tooltip latency.
///
/// Call this once during chart initialization to avoid the ~100-200ms delay
/// that occurs when the first tooltip is rendered (due to font loading,
/// glyph caching, and shader compilation).
void prewarmTooltipRendering() {
  // Create and layout a TextPainter with typical tooltip content.
  // This forces Flutter to load fonts and compile text shaders.
  final painter = TextPainter(
    text: const TextSpan(
      text: 'Series 1\nX: 100.00\nY: 100.00',
      style: TextStyle(
        color: Color(0xFF333333),
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  // Dispose immediately - we just needed to trigger the caching
  painter.dispose();
}

/// Manages tooltip show/hide animations with configurable delays.
///
/// This class handles the timing and motion animation for tooltips:
/// - Show delay: Wait before displaying tooltip on hover
/// - Hide delay: Wait before hiding tooltip when moving away
/// - Flick animation: Fast opacity and scale transitions
///
/// **Usage**:
/// `dart
/// final animator = TooltipAnimator(onRepaint: markNeedsPaint);
/// animator.show(markerInfo, config);
/// animator.hide(config);
/// `
///
/// **Performance**:
/// - Uses Timer.periodic for smooth 60fps motion
/// - Properly cancels timers to prevent memory leaks
/// - Minimal overhead when not animating
class TooltipAnimator {
  TooltipAnimator({
    required this.onRepaint,
    RepaintFrameScheduler? scheduleRepaintFrame,
  }) : _scheduleRepaintFrame = scheduleRepaintFrame ?? _scheduleOnNextFrame;

  /// Callback invoked when a repaint is needed (opacity changed).
  final RepaintCallback onRepaint;

  final RepaintFrameScheduler _scheduleRepaintFrame;

  static void _scheduleOnNextFrame(void Function() callback) {
    SchedulerBinding.instance.scheduleFrameCallback((_) => callback());
  }

  /// Current tooltip opacity (0.0 = hidden, 1.0 = fully visible).
  double _opacity = 0.0;

  /// Current tooltip scale around its data-point anchor.
  double _scale = 1.0;

  /// Timer for delaying tooltip show.
  Timer? _showTimer;

  /// Timer for delaying tooltip hide.
  Timer? _hideTimer;

  /// Timer for motion animation steps.
  Timer? _motionTimer;

  /// Target marker for detecting marker changes and drawing.
  /// Generic type allows different marker info objects.
  Object? _targetMarker;

  /// Whether this animator has been disposed.
  bool _disposed = false;

  /// Whether a delayed or active hide transition already owns the popup.
  bool _isHiding = false;

  /// Whether a repaint request is already queued for the next frame.
  bool _repaintScheduled = false;

  /// Gets current tooltip opacity.
  double get opacity => _opacity;

  /// Gets the current tooltip scale around its data-point anchor.
  double get scale => _scale;

  /// Whether the tooltip is visible (opacity > 0).
  bool get isVisible => _opacity > 0.001;

  /// Gets the current target marker (for drawing during fade-out).
  /// Returns null when no target is set.
  T? getTargetMarker<T>() => _targetMarker as T?;

  /// Shows tooltip with configured delay and flick-in animation.
  ///
  /// [marker] is the marker info object (stored for drawing during animations).
  /// [config] provides show delay configuration.
  ///
  /// If tooltip is already visible (transitioning between markers), the new
  /// marker is shown immediately without delay to provide seamless transitions.
  void show(Object marker, TooltipConfig config, {bool animate = true}) {
    // Cancel ALL existing timers including motion animation. This prevents a
    // hide transition from clearing _targetMarker after we set it.
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _motionTimer?.cancel();
    _isHiding = false;

    // Cache target marker for drawing
    _targetMarker = marker;

    if (!animate) {
      _showImmediately();
      return;
    }

    // If tooltip is already visible (switching between markers), show immediately
    // This provides seamless marker-to-marker transitions without flickering
    if (_opacity > 0.5) {
      // Already visible enough - just keep it visible, no animation needed
      _opacity = 1.0;
      _scale = 1.0;
      _safeRepaint();
      return;
    }

    // If showDelay is zero, show immediately
    if (config.showDelay == Duration.zero) {
      _animateMotion(
        showing: true,
        duration: const Duration(milliseconds: 110),
      );
      return;
    }

    // Start show delay timer (only for initial show from hidden state)
    _showTimer = Timer(config.showDelay, () {
      // Only show if still targeting same marker
      if (_targetMarker == marker) {
        _animateMotion(
          showing: true,
          duration: const Duration(milliseconds: 110),
        );
      }
    });
  }

  /// Hides tooltip with configured delay and flick-out animation.
  ///
  /// [config] provides hide delay configuration.
  /// Note: Does NOT clear the target marker immediately to allow drawing during fade-out.
  ///
  /// If tooltip is currently fully visible, uses a minimum hide delay to prevent
  /// flickering from transient marker state changes during mouse movement.
  void hide(TooltipConfig config, {bool animate = true}) {
    // Cancel show timer (user moved away before delay finished)
    _showTimer?.cancel();

    // Painting can request the same hide on every animation frame. Let the
    // first request own the transition so its clock cannot be restarted.
    if (_isHiding || _targetMarker == null) return;
    _isHiding = true;

    // If hideDelay is zero, hide immediately
    if (config.hideDelay == Duration.zero) {
      if (animate) {
        _animateMotion(
          showing: false,
          duration: const Duration(milliseconds: 80),
        );
      } else {
        _hideAndRepaintImmediately();
      }
      return;
    }

    // If tooltip is fully visible, enforce a minimum hide delay to prevent
    // flickering from transient null states during marker-to-marker transitions
    final effectiveHideDelay = _opacity > 0.9
        ? Duration(milliseconds: math.max(config.hideDelay.inMilliseconds, 100))
        : config.hideDelay;

    // Start hide delay timer
    _hideTimer = Timer(effectiveHideDelay, () {
      if (animate) {
        _animateMotion(
          showing: false,
          duration: const Duration(milliseconds: 80),
        );
      } else {
        _hideAndRepaintImmediately();
      }
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
    _scale = 1.0;
    _isHiding = false;
    // Note: Do not call onRepaint() here - this is called during paint()
  }

  /// Cancels all timers and resets animation state.
  void cancelAll() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    _motionTimer?.cancel();
    _motionTimer = null;
    _targetMarker = null;
    _isHiding = false;
  }

  /// Disposes resources. Must be called when the animator is no longer needed.
  void dispose() {
    _disposed = true;
    cancelAll();
  }

  /// Safely requests a repaint if not disposed.
  ///
  /// Schedules the repaint for the next frame to avoid calling markNeedsPaint
  /// during the paint phase (show() can be called from paint), which would
  /// cause an assertion error.
  void _safeRepaint() {
    if (_disposed || _repaintScheduled) return;
    _repaintScheduled = true;
    _scheduleRepaintFrame(() {
      _repaintScheduled = false;
      if (!_disposed) {
        onRepaint();
      }
    });
  }

  void _showImmediately() {
    _opacity = 1.0;
    _scale = 1.0;
    _isHiding = false;
    _safeRepaint();
  }

  void _hideAndRepaintImmediately() {
    _opacity = 0.0;
    _scale = 1.0;
    _targetMarker = null;
    _isHiding = false;
    _safeRepaint();
  }

  /// Animates the tooltip's opacity and anchored scale.
  void _animateMotion({required bool showing, required Duration duration}) {
    _motionTimer?.cancel();
    if (_disposed) return;

    final startOpacity = _opacity;
    final startScale = showing && startOpacity < 0.001 ? 0.88 : _scale;

    const fps = 60;
    const stepDuration = Duration(milliseconds: 1000 ~/ fps);
    final totalSteps = math.max(
      1,
      (duration.inMilliseconds * fps / 1000).round(),
    );
    var currentStep = 0;

    _scale = startScale;
    _motionTimer = Timer.periodic(stepDuration, (timer) {
      // Stop if disposed during animation
      if (_disposed) {
        timer.cancel();
        return;
      }

      currentStep++;

      if (currentStep >= totalSteps) {
        _opacity = showing ? 1.0 : 0.0;
        _scale = showing ? 1.0 : 0.94;
        if (!showing) {
          _targetMarker = null;
          _isHiding = false;
        }
        timer.cancel();
        _safeRepaint();
      } else {
        final progress = currentStep / totalSteps;
        if (showing) {
          final opacityProgress = Curves.easeOutCubic.transform(progress);
          _opacity = startOpacity + ((1.0 - startOpacity) * opacityProgress);
          _scale =
              startScale +
              ((1.0 - startScale) * Curves.easeOutBack.transform(progress));
        } else {
          final exitProgress = Curves.easeInCubic.transform(progress);
          _opacity = startOpacity * (1.0 - exitProgress);
          _scale = startScale + ((0.94 - startScale) * exitProgress);
        }
        _safeRepaint();
      }
    });
  }
}
