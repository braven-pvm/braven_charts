// Copyright (c) 2025 braven_charts. All rights reserved.
// Tooltip Renderer Module - Extracted from ChartRenderBox

import 'package:flutter/painting.dart';

import '../../axis/series_axis_resolver.dart';
import '../../elements/series_element.dart';
import '../../formatting/multi_axis_value_formatter.dart';
import '../../interaction/core/chart_element.dart';
import '../../interaction/core/coordinator.dart';
import '../../models/chart_series.dart';
import '../../models/chart_theme.dart';
import '../../models/interaction_config.dart';
import '../../models/series_axis_binding.dart';
import '../../models/y_axis_config.dart';
import 'tooltip_animator.dart';

/// Renders marker tooltips with smart positioning and arrow pointers.
///
/// This module handles all tooltip rendering logic:
/// - Building tooltip content (series name, X value, Y value with units)
/// - Smart positioning to avoid clipping at canvas edges
/// - Arrow pointer that points to the data marker
/// - Styling with background, border, shadow, and opacity animation
///
/// **Extracted from ChartRenderBox** to reduce class complexity and improve
/// testability of tooltip rendering logic.
class TooltipRenderer {
  const TooltipRenderer();

  /// Draws a tooltip for the hovered marker.
  ///
  /// **Parameters**:
  /// - [canvas]: Canvas to draw on
  /// - [size]: Total widget size (for edge clipping avoidance)
  /// - [markerInfo]: Information about the hovered marker
  /// - [elements]: List of chart elements to find the series
  /// - [animator]: TooltipAnimator for opacity animation
  /// - [cursorPosition]: Current cursor position (for followCursor mode)
  /// - [interactionConfig]: Tooltip configuration (delays, position, style)
  /// - [theme]: Chart theme for default styling
  /// - [effectiveAxes]: Y-axis configurations for unit formatting
  /// - [effectiveBindings]: Series-to-axis bindings for unit resolution
  /// - [formatDataValue]: Function to format data values for display
  /// - [plotToWidget]: Function to convert plot coordinates to widget coordinates
  void drawMarkerTooltip({
    required Canvas canvas,
    required Size size,
    required HoveredMarkerInfo markerInfo,
    required List<ChartElement> elements,
    required TooltipAnimator animator,
    required Offset? cursorPosition,
    required InteractionConfig? interactionConfig,
    required ChartTheme? theme,
    required List<YAxisConfig> effectiveAxes,
    required List<SeriesAxisBinding> effectiveBindings,
    required String Function(double) formatDataValue,
    required Offset Function(Offset) plotToWidget,
  }) {
    // Get tooltip configuration (use default if not provided)
    final config = interactionConfig?.tooltip ?? const TooltipConfig();

    // Get effective tooltip style (uses theme defaults when config doesn't specify)
    final style = _getEffectiveTooltipStyle(interactionConfig, theme);

    // Find the series element containing this marker
    final seriesElement = elements.whereType<SeriesElement>().firstWhere(
          (e) => e.id == markerInfo.seriesId,
          orElse: () =>
              throw StateError('Series ${markerInfo.seriesId} not found'),
        );

    // Get the exact data point
    final dataPoint = seriesElement.series.points[markerInfo.markerIndex];

    // Convert data point to screen coordinates for tooltip anchor
    // If followCursor is enabled, use current cursor position instead of marker position
    final tooltipAnchor = config.followCursor && cursorPosition != null
        ? cursorPosition
        : plotToWidget(markerInfo.plotPosition);

    // Build tooltip text with Y-value formatting including units (T023)
    final seriesName = seriesElement.series.name ?? seriesElement.id;

    // Get the axis config for this series to retrieve unit (T023, T042)
    String? yUnit;
    if (effectiveAxes.isNotEmpty) {
      final axisConfig = SeriesAxisResolver.resolveAxis(
        markerInfo.seriesId,
        effectiveBindings,
        effectiveAxes,
      );
      yUnit = axisConfig?.unit;
    }

    // Format Y value with unit using MultiAxisValueFormatter (T042, T045)
    final formattedY = MultiAxisValueFormatter.format(
      value: dataPoint.y,
      unit: yUnit,
    );

    final tooltipText =
        '$seriesName\nX: ${formatDataValue(dataPoint.x)}\nY: $formattedY';

    // Create text painter with configured style
    final textStyle = TextStyle(
      color: style.textColor,
      fontSize: style.fontSize,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: tooltipText, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // Calculate tooltip size with configured padding
    final padding = style.padding;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    // Get marker radius to offset tooltip position
    double markerRadius = 0.0;
    if (seriesElement.series is LineChartSeries) {
      markerRadius =
          (seriesElement.series as LineChartSeries).dataPointMarkerRadius;
    } else if (seriesElement.series is ScatterChartSeries) {
      markerRadius = (seriesElement.series as ScatterChartSeries).markerRadius;
    } else if (seriesElement.series is AreaChartSeries) {
      markerRadius =
          (seriesElement.series as AreaChartSeries).dataPointMarkerRadius;
    }

    // Smart positioning: Respect preferredPosition, but auto-adjust to avoid clipping
    // Add marker radius to offset so arrow starts at marker edge, not center
    final offset = config.offsetFromPoint + markerRadius;
    const edgeMargin = 10.0; // Margin from canvas edges

    double tooltipX;
    double tooltipY;

    // Determine initial position based on preferredPosition
    switch (config.preferredPosition) {
      case TooltipPosition.top:
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
        break;
      case TooltipPosition.bottom:
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy + offset;
        break;
      case TooltipPosition.left:
        tooltipX = tooltipAnchor.dx - tooltipWidth - offset;
        tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
        break;
      case TooltipPosition.right:
        tooltipX = tooltipAnchor.dx + offset;
        tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
        break;
      case TooltipPosition.auto:
        // Auto mode: default to top, but will flip if needed
        tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
        break;
    }

    // Adjust X position to avoid clipping left/right edges
    if (tooltipX < edgeMargin) {
      tooltipX = edgeMargin;
    } else if (tooltipX + tooltipWidth > size.width - edgeMargin) {
      tooltipX = size.width - tooltipWidth - edgeMargin;
    }

    // Adjust Y position to avoid clipping top/bottom edges
    if (tooltipY < edgeMargin) {
      // Would clip top - flip to bottom if in top/auto mode
      if (config.preferredPosition == TooltipPosition.top ||
          config.preferredPosition == TooltipPosition.auto) {
        tooltipY = tooltipAnchor.dy + offset;
      } else {
        // Otherwise just push down
        tooltipY = edgeMargin;
      }
    } else if (tooltipY + tooltipHeight > size.height - edgeMargin) {
      // Would clip bottom - flip to top if in bottom mode
      if (config.preferredPosition == TooltipPosition.bottom) {
        tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
      } else {
        // Otherwise just push up
        tooltipY = size.height - tooltipHeight - edgeMargin;
      }
    }

    // Create tooltip path with arrow pointer
    const arrowSize = 8.0; // Height/width of arrow

    final tooltipRect =
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);

    final tooltipPath = _createTooltipPath(
      tooltipRect: tooltipRect,
      arrowAnchor: tooltipAnchor,
      arrowSize: arrowSize,
      borderRadius: style.borderRadius,
    );

    // Draw shadow if configured (with opacity)
    if (style.shadowBlurRadius > 0) {
      final shadowPath = tooltipPath.shift(const Offset(0, 2));
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = style.shadowColor
              .withValues(alpha: style.shadowColor.a * animator.opacity)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, style.shadowBlurRadius),
      );
    }

    // Draw background with configured color (with opacity)
    canvas.drawPath(
      tooltipPath,
      Paint()
        ..color = style.backgroundColor
            .withValues(alpha: style.backgroundColor.a * animator.opacity)
        ..style = PaintingStyle.fill,
    );

    // Draw border if configured (with opacity)
    if (style.borderWidth > 0) {
      canvas.drawPath(
        tooltipPath,
        Paint()
          ..color = style.borderColor
              .withValues(alpha: style.borderColor.a * animator.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.borderWidth,
      );
    }

    // Draw text (with opacity)
    final textPaintWithOpacity = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: textStyle.copyWith(
            color: style.textColor.withValues(alpha: animator.opacity)),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPaintWithOpacity.paint(
        canvas, Offset(tooltipX + padding, tooltipY + padding));
  }

  /// Gets the effective tooltip style, using theme defaults when config is not provided.
  TooltipStyle _getEffectiveTooltipStyle(
    InteractionConfig? interactionConfig,
    ChartTheme? theme,
  ) {
    final configStyle = interactionConfig?.tooltip.style;
    final themeTooltipStyle = theme?.interactionTheme.tooltipStyle;

    // If user provided a config, use it as-is
    if (configStyle != null) {
      return configStyle;
    }

    // Otherwise, create a style from theme LabelStyle
    if (themeTooltipStyle != null) {
      return TooltipStyle(
        backgroundColor: themeTooltipStyle.backgroundColor,
        textColor: themeTooltipStyle.textStyle.color ?? const Color(0xFF333333),
        fontSize: themeTooltipStyle.textStyle.fontSize ?? 12.0,
        borderColor: themeTooltipStyle.borderColor,
        borderWidth: themeTooltipStyle.borderWidth,
        borderRadius: themeTooltipStyle.borderRadius,
        padding: themeTooltipStyle.padding.left, // Use left as uniform padding
        shadowColor: themeTooltipStyle.shadowColor ?? const Color(0x00000000),
        shadowBlurRadius: themeTooltipStyle.shadowBlurRadius ?? 0.0,
      );
    }

    // Fallback to hardcoded defaults if no theme
    return const TooltipStyle();
  }

  /// Creates a tooltip path with an arrow pointer pointing to the data point.
  ///
  /// [tooltipRect] The rectangle bounds of the tooltip
  /// [arrowAnchor] The exact point the arrow should point to (data point position)
  /// [arrowSize] The height/width of the arrow pointer
  /// [borderRadius] The corner radius of the tooltip
  ///
  /// Returns a Path that includes rounded corners and an arrow pointer
  /// positioned on the side closest to the anchor point.
  Path _createTooltipPath({
    required Rect tooltipRect,
    required Offset arrowAnchor,
    required double arrowSize,
    required double borderRadius,
  }) {
    final path = Path();

    // Determine which side should have the arrow based on anchor position
    // Arrow points TO the anchor from the tooltip

    // Calculate which edge is closest to anchor
    final leftDist = (arrowAnchor.dx - tooltipRect.left).abs();
    final rightDist = (arrowAnchor.dx - tooltipRect.right).abs();
    final topDist = (arrowAnchor.dy - tooltipRect.top).abs();
    final bottomDist = (arrowAnchor.dy - tooltipRect.bottom).abs();

    final minHorizDist = leftDist < rightDist ? leftDist : rightDist;
    final minVertDist = topDist < bottomDist ? topDist : bottomDist;

    // Determine arrow position (prefer vertical positioning for typical top/bottom tooltips)
    final bool arrowOnTop = topDist < bottomDist && minVertDist < minHorizDist;
    final bool arrowOnBottom =
        bottomDist <= topDist && minVertDist < minHorizDist;
    final bool arrowOnLeft =
        !arrowOnTop && !arrowOnBottom && leftDist < rightDist;
    // arrowOnRight is the else case

    // Calculate arrow offset along the edge (clamped to stay within rect with margin)
    const edgeMargin = 10.0; // Keep arrow away from corners

    if (arrowOnTop) {
      // Arrow on top edge pointing up to anchor
      final arrowX = (arrowAnchor.dx - tooltipRect.left).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.width - edgeMargin - arrowSize / 2,
      );
      final arrowLeft = arrowX - arrowSize / 2;
      final arrowRight = arrowX + arrowSize / 2;
      final arrowTop = tooltipRect.top - arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.left + arrowLeft, tooltipRect.top);
      path.lineTo(tooltipRect.left + arrowX, arrowTop); // Arrow point
      path.lineTo(tooltipRect.left + arrowRight, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top,
          tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom,
          tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom,
          tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top,
          tooltipRect.left + borderRadius, tooltipRect.top);
    } else if (arrowOnBottom) {
      // Arrow on bottom edge pointing down to anchor
      final arrowX = (arrowAnchor.dx - tooltipRect.left).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.width - edgeMargin - arrowSize / 2,
      );
      final arrowLeft = arrowX - arrowSize / 2;
      final arrowRight = arrowX + arrowSize / 2;
      final arrowBottom = tooltipRect.bottom + arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top,
          tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom,
          tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + arrowRight, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + arrowX, arrowBottom); // Arrow point
      path.lineTo(tooltipRect.left + arrowLeft, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom,
          tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top,
          tooltipRect.left + borderRadius, tooltipRect.top);
    } else if (arrowOnLeft) {
      // Arrow on left edge pointing left to anchor
      final arrowY = (arrowAnchor.dy - tooltipRect.top).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.height - edgeMargin - arrowSize / 2,
      );
      final arrowTop = arrowY - arrowSize / 2;
      final arrowBottom = arrowY + arrowSize / 2;
      final arrowLeft = tooltipRect.left - arrowSize;

      path.moveTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + arrowTop);
      path.lineTo(arrowLeft, tooltipRect.top + arrowY); // Arrow point
      path.lineTo(tooltipRect.left, tooltipRect.top + arrowBottom);
      path.lineTo(tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom,
          tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom,
          tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top,
          tooltipRect.right - borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top,
          tooltipRect.left, tooltipRect.top + borderRadius);
    } else {
      // arrowOnRight
      // Arrow on right edge pointing right to anchor
      final arrowY = (arrowAnchor.dy - tooltipRect.top).clamp(
        edgeMargin + arrowSize / 2,
        tooltipRect.height - edgeMargin - arrowSize / 2,
      );
      final arrowTop = arrowY - arrowSize / 2;
      final arrowBottom = arrowY + arrowSize / 2;
      final arrowRight = tooltipRect.right + arrowSize;

      path.moveTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.top);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.top,
          tooltipRect.right, tooltipRect.top + borderRadius);
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowTop);
      path.lineTo(arrowRight, tooltipRect.top + arrowY); // Arrow point
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowBottom);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(tooltipRect.right, tooltipRect.bottom,
          tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.bottom,
          tooltipRect.left, tooltipRect.bottom - borderRadius);
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(tooltipRect.left, tooltipRect.top,
          tooltipRect.left + borderRadius, tooltipRect.top);
    }

    path.close();
    return path;
  }
}
