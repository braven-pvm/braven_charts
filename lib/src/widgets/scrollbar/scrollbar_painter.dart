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

import 'package:flutter/material.dart';

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

    // Always paint edge zones to make them visible (not just on hover)
    _paintEdgeZones(canvas, handleRect);

    if (config.showGripIndicator) {
      _paintGripIndicator(canvas, handleRect);
    }

    // Always paint edge grips for zoom affordance
    _paintEdgeGrips(canvas, handleRect);
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
  /// - Edge zone highlighting with separate edgeHoverColor
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

    // Paint edge zone highlights if hovering over an edge
    if (state.hoverZone == HitTestZone.leftEdge ||
        state.hoverZone == HitTestZone.rightEdge ||
        state.hoverZone == HitTestZone.topEdge ||
        state.hoverZone == HitTestZone.bottomEdge) {
      _paintEdgeHighlight(canvas, handleRect);
    }
  }

  /// Paints edge zones with default distinct color (always visible).
  ///
  /// Renders both left/right (or top/bottom) edge zones with edgeZoneColor
  /// to provide permanent visual indication of zoom affordance.
  void _paintEdgeZones(Canvas canvas, Rect handleRect) {
    final Color effectiveEdgeColor;

    // Use hover color if hovering over edge, otherwise use default edge zone color
    if (state.hoverZone == HitTestZone.leftEdge ||
        state.hoverZone == HitTestZone.rightEdge ||
        state.hoverZone == HitTestZone.topEdge ||
        state.hoverZone == HitTestZone.bottomEdge) {
      effectiveEdgeColor = config.edgeHoverColor.withOpacity(
        config.edgeHoverColor.opacity * opacity,
      );
    } else {
      effectiveEdgeColor = config.edgeZoneColor.withOpacity(
        config.edgeZoneColor.opacity * opacity,
      );
    }

    final edgePaint = Paint()
      ..color = effectiveEdgeColor
      ..style = PaintingStyle.fill;

    // Paint left/top edge zone
    final Rect leftTopEdgeRect;
    if (isHorizontal) {
      leftTopEdgeRect = Rect.fromLTWH(
        handleRect.left,
        handleRect.top,
        config.edgeGripWidth,
        handleRect.height,
      );
    } else {
      leftTopEdgeRect = Rect.fromLTWH(
        handleRect.left,
        handleRect.top,
        handleRect.width,
        config.edgeGripWidth,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        leftTopEdgeRect,
        Radius.circular(config.borderRadius),
      ),
      edgePaint,
    );

    // Paint right/bottom edge zone
    final Rect rightBottomEdgeRect;
    if (isHorizontal) {
      rightBottomEdgeRect = Rect.fromLTWH(
        handleRect.right - config.edgeGripWidth,
        handleRect.top,
        config.edgeGripWidth,
        handleRect.height,
      );
    } else {
      rightBottomEdgeRect = Rect.fromLTWH(
        handleRect.left,
        handleRect.bottom - config.edgeGripWidth,
        handleRect.width,
        config.edgeGripWidth,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rightBottomEdgeRect,
        Radius.circular(config.borderRadius),
      ),
      edgePaint,
    );
  }

  /// Paints edge zone highlight overlay when hovering over resize edges.
  ///
  /// Renders a colored overlay on the edge zone (first/last edgeGripWidth pixels)
  /// using the edgeHoverColor to provide visual feedback for zoom affordance.
  void _paintEdgeHighlight(Canvas canvas, Rect handleRect) {
    // Calculate edge zone rect based on hover zone
    final Rect edgeRect;

    if (state.hoverZone == HitTestZone.leftEdge ||
        state.hoverZone == HitTestZone.topEdge) {
      // Left/Top edge: First edgeGripWidth pixels
      if (isHorizontal) {
        edgeRect = Rect.fromLTWH(
          handleRect.left,
          handleRect.top,
          config.edgeGripWidth,
          handleRect.height,
        );
      } else {
        edgeRect = Rect.fromLTWH(
          handleRect.left,
          handleRect.top,
          handleRect.width,
          config.edgeGripWidth,
        );
      }
    } else {
      // Right/Bottom edge: Last edgeGripWidth pixels
      if (isHorizontal) {
        edgeRect = Rect.fromLTWH(
          handleRect.right - config.edgeGripWidth,
          handleRect.top,
          config.edgeGripWidth,
          handleRect.height,
        );
      } else {
        edgeRect = Rect.fromLTWH(
          handleRect.left,
          handleRect.bottom - config.edgeGripWidth,
          handleRect.width,
          config.edgeGripWidth,
        );
      }
    }

    // Apply edge hover color with opacity
    final effectiveEdgeColor = config.edgeHoverColor.withOpacity(
      config.edgeHoverColor.opacity * opacity,
    );

    final edgePaint = Paint()
      ..color = effectiveEdgeColor
      ..style = PaintingStyle.fill;

    // Draw edge highlight with border radius
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        edgeRect,
        Radius.circular(config.borderRadius),
      ),
      edgePaint,
    );
  }

  /// Determines handle color based on interaction state (FR-021A).
  Color _getHandleColor() {
    // Priority order: disabled > active > hover > default
    final interactionState = ScrollbarController.getInteractionState(
      isHovering:
          state.hoverZone != null && state.hoverZone != HitTestZone.track,
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

  /// Renders grip indicators on edge zones for zoom affordance.
  ///
  /// Paints 2 lines on each edge zone to indicate they are draggable for zoom.
  /// Always visible to provide permanent affordance.
  void _paintEdgeGrips(Canvas canvas, Rect handleRect) {
    // Use appropriate color: white when hovering (over blue), darker grey when not hovering
    final bool isHoveringEdge = state.hoverZone == HitTestZone.leftEdge ||
        state.hoverZone == HitTestZone.rightEdge ||
        state.hoverZone == HitTestZone.topEdge ||
        state.hoverZone == HitTestZone.bottomEdge;

    final effectiveColor = isHoveringEdge
        ? Colors.white.withOpacity(0.8 * opacity)
        : config.gripIndicatorColor.withOpacity(0.5 * opacity);

    final gripPaint = Paint()
      ..color = effectiveColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const lineCount = 2; // Fewer lines for edges to fit in edgeGripWidth zone
    const lineSpacing = 2.0;
    final lineLength = isHorizontal
        ? config.thickness * 0.4 // Slightly shorter for edges
        : config.thickness * 0.4;

    if (isHorizontal) {
      // Horizontal scrollbar: vertical lines on left and right edges
      final centerY = handleRect.top + handleRect.height / 2.0;
      final lineTop = centerY - lineLength / 2.0;
      final lineBottom = centerY + lineLength / 2.0;

      // Always draw left edge grips
      final leftEdgeCenter = handleRect.left + config.edgeGripWidth / 2.0;
      for (int i = 0; i < lineCount; i++) {
        final offsetX = leftEdgeCenter -
            (lineCount - 1) * lineSpacing / 2.0 +
            i * lineSpacing;
        canvas.drawLine(
          Offset(offsetX, lineTop),
          Offset(offsetX, lineBottom),
          gripPaint,
        );
      }

      // Always draw right edge grips
      final rightEdgeCenter = handleRect.right - config.edgeGripWidth / 2.0;
      for (int i = 0; i < lineCount; i++) {
        final offsetX = rightEdgeCenter -
            (lineCount - 1) * lineSpacing / 2.0 +
            i * lineSpacing;
        canvas.drawLine(
          Offset(offsetX, lineTop),
          Offset(offsetX, lineBottom),
          gripPaint,
        );
      }
    } else {
      // Vertical scrollbar: horizontal lines on top and bottom edges
      final centerX = handleRect.left + handleRect.width / 2.0;
      final lineLeft = centerX - lineLength / 2.0;
      final lineRight = centerX + lineLength / 2.0;

      // Always draw top edge grips
      final topEdgeCenter = handleRect.top + config.edgeGripWidth / 2.0;
      for (int i = 0; i < lineCount; i++) {
        final offsetY = topEdgeCenter -
            (lineCount - 1) * lineSpacing / 2.0 +
            i * lineSpacing;
        canvas.drawLine(
          Offset(lineLeft, offsetY),
          Offset(lineRight, offsetY),
          gripPaint,
        );
      }

      // Always draw bottom edge grips
      final bottomEdgeCenter = handleRect.bottom - config.edgeGripWidth / 2.0;
      for (int i = 0; i < lineCount; i++) {
        final offsetY = bottomEdgeCenter -
            (lineCount - 1) * lineSpacing / 2.0 +
            i * lineSpacing;
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
