// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// CustomPainter for rendering dual-purpose scrollbars.
///
/// Renders:
/// - Track background with hover state
/// - Handle (scrollbar thumb) with border radius
/// - Grip indicator (3 parallel lines for affordance)
/// - Interaction states (default, hover, active, disabled)
/// - Corner overlap blending for multi-axis scrollbars
///
/// All rendering is stateless - state is passed via constructor.
library;

import 'package:flutter/rendering.dart';

import '../../theming/components/scrollbar_config.dart';
import 'hit_test_zone.dart';
import 'scrollbar_controller.dart';
import 'scrollbar_state.dart';

/// CustomPainter for rendering scrollbar with interaction states.
///
/// Constitutional Requirements:
/// - Stateless rendering (all state passed via constructor)
/// - Performance-optimized (minimal object allocation in paint())
/// - Supports both horizontal and vertical orientations
/// - Implements all FR-021 interaction states
class ScrollbarPainter extends CustomPainter {
  /// Creates a scrollbar painter.
  ///
  /// Parameters:
  /// - [config]: Visual configuration (colors, sizes, etc.)
  /// - [state]: Current UI state (handle position, hover zone, etc.)
  /// - [isHorizontal]: true for X-axis, false for Y-axis
  /// - [trackLength]: Available pixel space for handle movement
  /// - [isTrackHovered]: Whether mouse is hovering over track (not handle)
  /// - [opacity]: Global opacity for auto-hide fade animation (0.0-1.0)
  const ScrollbarPainter({
    required this.config,
    required this.state,
    required this.isHorizontal,
    required this.trackLength,
    this.isTrackHovered = false,
    this.opacity = 1.0,
  });

  /// Scrollbar visual configuration.
  final ScrollbarConfig config;

  /// Current scrollbar state.
  final ScrollbarState state;

  /// Orientation flag (true = horizontal, false = vertical).
  final bool isHorizontal;

  /// Available pixel space for handle movement (excludes padding).
  final double trackLength;

  /// Whether mouse is hovering over track area (not handle).
  ///
  /// Used for FR-021B track hover state (opacity 0.2 → 0.3).
  final bool isTrackHovered;

  /// Global opacity for auto-hide animation (0.0 = invisible, 1.0 = opaque).
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Early exit if completely transparent (optimization)
    if (opacity <= 0.0 || !state.isVisible) {
      return;
    }

    // Calculate dimensions based on orientation
    final trackRect = _calculateTrackRect(size);
    final handleRect = _calculateHandleRect(size);

    // Render layers in order (back to front)
    _paintTrack(canvas, trackRect);
    _paintHandle(canvas, handleRect);

    if (config.showGripIndicator) {
      _paintGripIndicator(canvas, handleRect);
    }
  }

  /// Calculates track bounding rectangle based on orientation.
  Rect _calculateTrackRect(Size size) {
    if (isHorizontal) {
      // Horizontal: full width, centered vertically
      return Rect.fromLTWH(
        0.0,
        (size.height - config.thickness) / 2.0,
        size.width,
        config.thickness,
      );
    } else {
      // Vertical: full height, centered horizontally
      return Rect.fromLTWH(
        (size.width - config.thickness) / 2.0,
        0.0,
        config.thickness,
        size.height,
      );
    }
  }

  /// Calculates handle bounding rectangle based on state and orientation.
  Rect _calculateHandleRect(Size size) {
    if (isHorizontal) {
      // Horizontal: position along X axis
      final centerY = (size.height - config.thickness) / 2.0;
      return Rect.fromLTWH(
        state.handlePosition,
        centerY,
        state.handleSize,
        config.thickness,
      );
    } else {
      // Vertical: position along Y axis
      final centerX = (size.width - config.thickness) / 2.0;
      return Rect.fromLTWH(
        centerX,
        state.handlePosition,
        config.thickness,
        state.handleSize,
      );
    }
  }

  /// Renders scrollbar track with hover state.
  ///
  /// Implements:
  /// - FR-021B: Track hover state (opacity 0.2 → 0.3)
  /// - Base track color from config
  void _paintTrack(Canvas canvas, Rect trackRect) {
    // Determine track color based on hover state
    final Color trackColor;
    if (isTrackHovered) {
      // FR-021B: Increased opacity on hover
      trackColor = config.trackHoverColor;
    } else {
      trackColor = config.trackColor;
    }

    // Apply global opacity for auto-hide animation
    final effectiveColor = trackColor.withOpacity(
      trackColor.opacity * opacity,
    );

    // Render track background
    final trackPaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        trackRect,
        Radius.circular(config.borderRadius),
      ),
      trackPaint,
    );
  }

  /// Renders scrollbar handle with interaction states.
  ///
  /// Implements:
  /// - FR-021A: Default, hover, active, disabled states
  /// - Border radius for rounded rectangle
  void _paintHandle(Canvas canvas, Rect handleRect) {
    // Determine handle color based on interaction state
    final Color handleColor = _getHandleColor();

    // Apply global opacity for auto-hide animation
    final effectiveColor = handleColor.withOpacity(
      handleColor.opacity * opacity,
    );

    // Render handle
    final handlePaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        handleRect,
        Radius.circular(config.borderRadius),
      ),
      handlePaint,
    );
  }

  /// Determines handle color based on interaction state (FR-021A).
  Color _getHandleColor() {
    // Priority order: disabled > active > hover > default
    final interactionState = ScrollbarController.getInteractionState(
      isHovering: state.hoverZone != null && state.hoverZone != HitTestZone.track,
      isActive: state.isDragging,
      isEnabled: true, // TODO: Wire to InteractionConfig.enablePan/enableZoom
    );

    switch (interactionState) {
      case ScrollbarInteractionState.disabled:
        return config.handleDisabledColor;
      case ScrollbarInteractionState.active:
        return config.handleActiveColor;
      case ScrollbarInteractionState.hover:
        return config.handleHoverColor;
      case ScrollbarInteractionState.default_:
        return config.handleColor;
    }
  }

  /// Renders grip indicator (3 parallel lines) on handle.
  ///
  /// Provides visual affordance for draggability.
  /// Lines are centered on handle, spaced evenly.
  void _paintGripIndicator(Canvas canvas, Rect handleRect) {
    // Apply global opacity to grip color
    final effectiveColor = config.gripIndicatorColor.withOpacity(
      config.gripIndicatorColor.opacity * opacity,
    );

    final gripPaint = Paint()
      ..color = effectiveColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Calculate grip line dimensions
    const lineCount = 3;
    const lineSpacing = 2.0;
    final lineLength = isHorizontal
        ? config.thickness * 0.5 // Half of thickness for horizontal
        : config.thickness * 0.5; // Half of thickness for vertical

    // Calculate total grip height/width
    const totalGripSize = (lineCount - 1) * lineSpacing;

    if (isHorizontal) {
      // Horizontal: vertical lines in center of handle
      final centerX = handleRect.left + handleRect.width / 2.0;
      final centerY = handleRect.top + handleRect.height / 2.0;
      final lineTop = centerY - lineLength / 2.0;
      final lineBottom = centerY + lineLength / 2.0;

      for (int i = 0; i < lineCount; i++) {
        final offsetX = centerX - totalGripSize / 2.0 + i * lineSpacing;
        canvas.drawLine(
          Offset(offsetX, lineTop),
          Offset(offsetX, lineBottom),
          gripPaint,
        );
      }
    } else {
      // Vertical: horizontal lines in center of handle
      final centerX = handleRect.left + handleRect.width / 2.0;
      final centerY = handleRect.top + handleRect.height / 2.0;
      final lineLeft = centerX - lineLength / 2.0;
      final lineRight = centerX + lineLength / 2.0;

      for (int i = 0; i < lineCount; i++) {
        final offsetY = centerY - totalGripSize / 2.0 + i * lineSpacing;
        canvas.drawLine(
          Offset(lineLeft, offsetY),
          Offset(lineRight, offsetY),
          gripPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScrollbarPainter oldDelegate) {
    // Repaint if any visual property changed
    return config != oldDelegate.config ||
        state != oldDelegate.state ||
        isHorizontal != oldDelegate.isHorizontal ||
        trackLength != oldDelegate.trackLength ||
        isTrackHovered != oldDelegate.isTrackHovered ||
        opacity != oldDelegate.opacity;
  }
}
