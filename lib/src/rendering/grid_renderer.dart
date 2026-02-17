// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Canvas, Color, Offset, Paint, PaintingStyle, Rect;

import '../models/chart_theme.dart';
import '../models/grid_config.dart';

/// Renders grid lines independently from axis rendering.
///
/// GridRenderer is responsible for painting horizontal and vertical grid lines
/// across the chart's plot area. It operates independently from axis rendering
/// as part of the axis renderer unification refactor (FR-013).
///
/// The renderer is called from chart_render_box.dart BEFORE axis rendering,
/// ensuring grid lines appear behind chart data.
///
/// **Usage:**
/// ```dart
/// final renderer = GridRenderer(
///   theme: chartTheme,
///   config: GridConfig(horizontal: true, vertical: true),
/// );
///
/// // Paint horizontal grid lines at Y-axis tick positions
/// renderer.paintHorizontalGrid(canvas, plotArea, yPositions);
///
/// // Paint vertical grid lines at X-axis tick positions
/// renderer.paintVerticalGrid(canvas, plotArea, xPositions);
/// ```
///
/// The actual painting logic will be implemented in Phase 2 (Task 13/14).
/// For now, method bodies are empty skeletons.
class GridRenderer {
  /// Creates a grid renderer.
  ///
  /// [theme] provides default colors/styles from the chart theme.
  /// [config] provides grid-specific configuration (visibility, colors, widths).
  const GridRenderer({this.theme, this.config});

  /// Chart theme for default styling.
  final ChartTheme? theme;

  /// Grid configuration for visibility and styling.
  final GridConfig? config;

  /// Paints horizontal grid lines at specified Y positions.
  ///
  /// [canvas] is the drawing surface.
  /// [plotArea] defines the chart's plot area bounds.
  /// [yPositions] are the Y-coordinates where grid lines should be drawn.
  void paintHorizontalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> yPositions,
  ) {
    // Check if horizontal grid is enabled
    final effectiveConfig = config ?? const GridConfig();
    if (!effectiveConfig.horizontal) {
      return;
    }

    // Determine color (config takes precedence over theme)
    final Color gridColor =
        effectiveConfig.horizontalColor ??
        theme?.gridStyle.majorColor ??
        const Color(0xFFE0E0E0);

    // Create paint for horizontal grid lines
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = effectiveConfig.horizontalStrokeWidth
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (final y in yPositions) {
      if (y >= plotArea.top && y <= plotArea.bottom) {
        canvas.drawLine(
          Offset(plotArea.left, y),
          Offset(plotArea.right, y),
          paint,
        );
      }
    }
  }

  /// Paints vertical grid lines at specified X positions.
  ///
  /// [canvas] is the drawing surface.
  /// [plotArea] defines the chart's plot area bounds.
  /// [xPositions] are the X-coordinates where grid lines should be drawn.
  void paintVerticalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> xPositions,
  ) {
    // Check if vertical grid is enabled
    final effectiveConfig = config ?? const GridConfig();
    if (!effectiveConfig.vertical) {
      return;
    }

    // Determine color (config takes precedence over theme)
    final Color gridColor =
        effectiveConfig.verticalColor ??
        theme?.gridStyle.majorColor ??
        const Color(0xFFE0E0E0);

    // Create paint for vertical grid lines
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = effectiveConfig.verticalStrokeWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (final x in xPositions) {
      if (x >= plotArea.left && x <= plotArea.right) {
        canvas.drawLine(
          Offset(x, plotArea.top),
          Offset(x, plotArea.bottom),
          paint,
        );
      }
    }
  }
}
