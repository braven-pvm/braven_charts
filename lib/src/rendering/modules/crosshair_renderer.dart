// Copyright (c) 2025 braven_charts. All rights reserved.
// Crosshair Renderer - Extracted from ChartRenderBox

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../axis/series_axis_resolver.dart';
import '../../coordinates/chart_transform.dart';
import '../../elements/series_element.dart';
import '../../formatting/multi_axis_value_formatter.dart';
import '../../interaction/core/crosshair_tracker.dart';
import '../../models/chart_series.dart';
import '../../models/chart_theme.dart';
import '../../models/interaction_config.dart';
import '../../models/normalization_mode.dart';
import '../../models/series_axis_binding.dart';
import '../../models/y_axis_config.dart';
import '../../models/y_axis_position.dart';
import '../multi_axis_normalizer.dart';

// Re-export DataRange for use by callers
export '../../models/data_range.dart' show DataRange;

/// Information about multi-axis configuration for crosshair rendering.
///
/// This record provides all the multi-axis data needed for crosshair rendering
/// without exposing the full ChartRenderBox internals.
class MultiAxisInfo {
  const MultiAxisInfo({
    required this.effectiveAxes,
    required this.axisBounds,
    required this.axisWidths,
    required this.effectiveBindings,
    required this.normalizationMode,
    required this.series,
  });

  /// List of effective Y-axis configurations.
  final List<YAxisConfig> effectiveAxes;

  /// Computed bounds for each axis (min/max values).
  final Map<String, DataRange> axisBounds;

  /// Computed widths for each axis.
  final Map<String, double> axisWidths;

  /// Series-to-axis bindings.
  final List<SeriesAxisBinding> effectiveBindings;

  /// Current normalization mode.
  final NormalizationMode? normalizationMode;

  /// List of series for color resolution.
  final List<ChartSeries> series;

  /// Whether multi-axis mode is active.
  bool get isMultiAxisMode => effectiveAxes.length > 1 && normalizationMode == NormalizationMode.perSeries;

  /// Gets the total width of axes at a specific position.
  double getPositionWidth(YAxisPosition position) {
    double total = 0;
    for (final axis in effectiveAxes) {
      if (axis.position == position && axis.visible) {
        total += axisWidths[axis.id] ?? 0;
      }
    }
    return total;
  }

  /// Resolves the color for an axis, using series color if not explicitly set.
  Color resolveAxisColor(YAxisConfig axis) {
    if (axis.color != null) return axis.color!;

    // Find series bound to this axis
    for (final binding in effectiveBindings) {
      if (binding.yAxisId == axis.id) {
        // Find series color
        for (final s in series) {
          if (s.id == binding.seriesId && s.color != null) {
            return s.color!;
          }
        }
      }
    }

    return const Color(0xFF666666); // Default gray
  }
}

/// Renders crosshair overlays including lines, coordinate labels, and tracking mode.
///
/// This class handles all crosshair-related rendering:
/// - Standard crosshair lines (horizontal/vertical)
/// - Coordinate labels (X and Y values at cursor position)
/// - Per-axis crosshair labels for multi-axis mode
/// - Tracking mode overlay with intersection markers and tooltip
///
/// **Usage**:
/// ```dart
/// final renderer = CrosshairRenderer();
/// renderer.paint(
///   canvas: canvas,
///   cursorPosition: cursorPos,
///   plotArea: plotArea,
///   transform: transform,
///   theme: theme,
///   crosshairConfig: config,
///   multiAxisInfo: axisInfo,
///   elements: elements,
///   isRangeCreationMode: false,
/// );
/// ```
class CrosshairRenderer {
  const CrosshairRenderer();

  /// Paints the crosshair overlay.
  ///
  /// This is the main entry point for crosshair rendering. It determines
  /// whether to use standard mode or tracking mode based on data point count.
  void paint({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required ChartTheme? theme,
    required CrosshairConfig crosshairConfig,
    required MultiAxisInfo multiAxisInfo,
    required List<SeriesElement> seriesElements,
    required bool isRangeCreationMode,
  }) {
    // Check if tracking mode should be used
    final seriesList = seriesElements.map((e) => e.series).toList();
    final totalDataPoints = CrosshairTracker.getTotalPointCount(seriesList);
    final useTrackingMode = crosshairConfig.shouldUseTrackingMode(totalDataPoints);

    if (useTrackingMode) {
      _paintTrackingMode(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        transform: transform,
        theme: theme,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
        seriesElements: seriesElements,
      );
    } else {
      _paintStandardMode(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        transform: transform,
        theme: theme,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
        isRangeCreationMode: isRangeCreationMode,
      );
    }
  }

  /// Paints standard crosshair mode (lines + coordinate labels).
  void _paintStandardMode({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required ChartTheme? theme,
    required CrosshairConfig crosshairConfig,
    required MultiAxisInfo multiAxisInfo,
    required bool isRangeCreationMode,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final crosshairColor = isRangeCreationMode
        ? (interactionTheme?.crosshairColor ?? const Color(0xFF448AFF))
        : (interactionTheme?.crosshairColor ?? const Color(0x80666666));
    final crosshairWidth = isRangeCreationMode ? 1.5 : (interactionTheme?.crosshairWidth ?? 1.0);

    final crosshairPaint = Paint()
      ..color = crosshairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = crosshairWidth;

    final mode = crosshairConfig.mode;

    // Horizontal line
    if (mode == CrosshairMode.horizontal || mode == CrosshairMode.both) {
      double lineLeft = plotArea.left;
      double lineRight = plotArea.right;

      // Extend line to outer axes with crosshair labels
      if (multiAxisInfo.isMultiAxisMode && multiAxisInfo.effectiveAxes.length > 1) {
        // Extend left for leftOuter axes with showCrosshairLabel
        final hasLeftOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) => a.position == YAxisPosition.leftOuter && a.visible && a.showCrosshairLabel,
        );
        if (hasLeftOuterLabels) {
          final leftOuterWidth = multiAxisInfo.getPositionWidth(YAxisPosition.leftOuter);
          final leftWidth = multiAxisInfo.getPositionWidth(YAxisPosition.left);
          lineLeft = plotArea.left - leftWidth - leftOuterWidth;
        }

        // Extend right for rightOuter axes with showCrosshairLabel
        final hasRightOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) => a.position == YAxisPosition.rightOuter && a.visible && a.showCrosshairLabel,
        );
        if (hasRightOuterLabels) {
          final rightOuterWidth = multiAxisInfo.getPositionWidth(YAxisPosition.rightOuter);
          final rightWidth = multiAxisInfo.getPositionWidth(YAxisPosition.right);
          lineRight = plotArea.right + rightWidth + rightOuterWidth;
        }
      }

      canvas.drawLine(
        Offset(lineLeft, cursorPosition.dy),
        Offset(lineRight, cursorPosition.dy),
        crosshairPaint,
      );
    }

    // Vertical line
    if (mode == CrosshairMode.vertical || mode == CrosshairMode.both) {
      canvas.drawLine(
        Offset(cursorPosition.dx, plotArea.top),
        Offset(cursorPosition.dx, plotArea.bottom),
        crosshairPaint,
      );
    }

    // Draw coordinate labels
    _paintCrosshairLabels(
      canvas: canvas,
      cursorPosition: cursorPosition,
      plotArea: plotArea,
      transform: transform,
      theme: theme,
      multiAxisInfo: multiAxisInfo,
    );
  }

  /// Paints tracking mode overlay (vertical line + intersection markers + tooltip).
  void _paintTrackingMode({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required ChartTheme? theme,
    required CrosshairConfig crosshairConfig,
    required MultiAxisInfo multiAxisInfo,
    required List<SeriesElement> seriesElements,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final crosshairColor = interactionTheme?.crosshairColor ?? const Color(0x80666666);
    final crosshairWidth = interactionTheme?.crosshairWidth ?? 1.0;

    final crosshairPaint = Paint()
      ..color = crosshairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = crosshairWidth;

    final mode = crosshairConfig.mode;

    // Vertical line (primary line for tracking mode)
    if (mode == CrosshairMode.vertical || mode == CrosshairMode.both) {
      canvas.drawLine(
        Offset(cursorPosition.dx, plotArea.top),
        Offset(cursorPosition.dx, plotArea.bottom),
        crosshairPaint,
      );
    }

    // Horizontal line (optional, with multi-axis extension)
    if (mode == CrosshairMode.horizontal || mode == CrosshairMode.both) {
      double lineLeft = plotArea.left;
      double lineRight = plotArea.right;

      if (multiAxisInfo.isMultiAxisMode && multiAxisInfo.effectiveAxes.length > 1) {
        final hasLeftOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) => a.position == YAxisPosition.leftOuter && a.visible && a.showCrosshairLabel,
        );
        if (hasLeftOuterLabels) {
          final leftOuterWidth = multiAxisInfo.getPositionWidth(YAxisPosition.leftOuter);
          final leftWidth = multiAxisInfo.getPositionWidth(YAxisPosition.left);
          lineLeft = plotArea.left - leftWidth - leftOuterWidth;
        }

        final hasRightOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) => a.position == YAxisPosition.rightOuter && a.visible && a.showCrosshairLabel,
        );
        if (hasRightOuterLabels) {
          final rightOuterWidth = multiAxisInfo.getPositionWidth(YAxisPosition.rightOuter);
          final rightWidth = multiAxisInfo.getPositionWidth(YAxisPosition.right);
          lineRight = plotArea.right + rightWidth + rightOuterWidth;
        }
      }

      canvas.drawLine(
        Offset(lineLeft, cursorPosition.dy),
        Offset(lineRight, cursorPosition.dy),
        crosshairPaint,
      );
    }

    // Calculate tracking state
    final seriesList = seriesElements.map((e) => e.series).toList();
    final trackingState = CrosshairTracker.calculateTrackingState(
      screenX: cursorPosition.dx,
      chartBounds: plotArea,
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      seriesList: seriesList,
      interpolate: crosshairConfig.interpolateValues,
    );

    if (trackingState == null) return;

    // Draw intersection markers
    if (crosshairConfig.showIntersectionMarkers) {
      _paintIntersectionMarkers(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        transform: transform,
        trackingState: trackingState,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
      );
    }

    // Draw tracking tooltip
    if (crosshairConfig.showTrackingTooltip && trackingState.seriesValues.isNotEmpty) {
      _paintTrackingTooltip(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        trackingState: trackingState,
        multiAxisInfo: multiAxisInfo,
      );
    }

    // Draw X label
    if (mode == CrosshairMode.vertical || mode == CrosshairMode.both) {
      _paintTrackingXLabel(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        dataX: trackingState.dataX,
      );
    }

    // Draw Y label (per-axis in multi-axis mode)
    if (mode == CrosshairMode.horizontal || mode == CrosshairMode.both) {
      if (multiAxisInfo.isMultiAxisMode) {
        final dataY = transform.plotToData(cursorPosition.dx, cursorPosition.dy).dy;
        _paintPerAxisCrosshairLabels(
          canvas: canvas,
          cursorPosition: cursorPosition,
          plotArea: plotArea,
          theme: theme,
          normalizedY: dataY,
          multiAxisInfo: multiAxisInfo,
        );
      } else {
        final dataY = transform.plotToData(cursorPosition.dx, cursorPosition.dy).dy;
        _paintTrackingYLabel(
          canvas: canvas,
          cursorPosition: cursorPosition,
          plotArea: plotArea,
          theme: theme,
          dataY: dataY,
        );
      }
    }
  }

  /// Paints coordinate labels (X and Y values).
  void _paintCrosshairLabels({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required ChartTheme? theme,
    required MultiAxisInfo multiAxisInfo,
  }) {
    // Convert widget space cursor to data coordinates
    // Note: cursorPosition is already in widget space, we need to offset by plotArea
    final plotX = cursorPosition.dx - plotArea.left;
    final plotY = cursorPosition.dy - plotArea.top;
    final dataPos = transform.plotToData(plotX, plotY);
    final dataX = dataPos.dx;
    final dataY = dataPos.dy;

    final interactionTheme = theme?.interactionTheme;
    final labelStyle = interactionTheme?.crosshairLabelStyle;
    final textStyle = labelStyle?.textStyle ?? const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final backgroundColor = labelStyle?.backgroundColor ?? const Color(0xF0FFFFFF);
    final borderColor = labelStyle?.borderColor ?? const Color(0xFFBDBDBD);
    final borderWidth = labelStyle?.borderWidth ?? 1.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final labelPadding = labelStyle?.padding.left ?? 4.0;

    final labelBackgroundPaint = Paint()..color = backgroundColor;
    final labelBorderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // X coordinate label
    final xDisplayValue = _formatDataValue(dataX);
    final xTextPainter = TextPainter(
      text: TextSpan(text: 'X: $xDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    var xLabelX = cursorPosition.dx - xTextPainter.width / 2;
    final xLabelY = plotArea.bottom - xTextPainter.height - 8;

    xLabelX = xLabelX.clamp(
      plotArea.left + labelPadding,
      plotArea.right - xTextPainter.width - labelPadding,
    );

    final xBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        xLabelX - labelPadding,
        xLabelY - labelPadding,
        xTextPainter.width + labelPadding * 2,
        xTextPainter.height + labelPadding * 2,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(xBgRect, labelBackgroundPaint);
    if (borderWidth > 0) {
      canvas.drawRRect(xBgRect, labelBorderPaint);
    }
    xTextPainter.paint(canvas, Offset(xLabelX, xLabelY));

    // Y coordinate label (single-axis mode) or per-axis labels (multi-axis mode)
    if (multiAxisInfo.isMultiAxisMode) {
      _paintPerAxisCrosshairLabels(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        normalizedY: dataY,
        multiAxisInfo: multiAxisInfo,
      );
    } else {
      final yDisplayValue = _formatDataValue(dataY);
      final yTextPainter = TextPainter(
        text: TextSpan(text: 'Y: $yDisplayValue', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final yLabelX = plotArea.left + 8;
      var yLabelY = cursorPosition.dy - yTextPainter.height / 2;
      yLabelY = yLabelY.clamp(
        plotArea.top + labelPadding,
        plotArea.bottom - yTextPainter.height - labelPadding,
      );

      final yBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          yLabelX - labelPadding,
          yLabelY - labelPadding,
          yTextPainter.width + labelPadding * 2,
          yTextPainter.height + labelPadding * 2,
        ),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(yBgRect, labelBackgroundPaint);
      if (borderWidth > 0) {
        canvas.drawRRect(yBgRect, labelBorderPaint);
      }
      yTextPainter.paint(canvas, Offset(yLabelX, yLabelY));
    }
  }

  /// Paints per-axis crosshair labels for multi-axis mode.
  void _paintPerAxisCrosshairLabels({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double normalizedY,
    required MultiAxisInfo multiAxisInfo,
  }) {
    final axesWithLabels = multiAxisInfo.effectiveAxes.where((a) => a.showCrosshairLabel && a.visible).toList();
    if (axesWithLabels.isEmpty) return;

    final interactionTheme = theme?.interactionTheme;
    final labelStyleConfig = interactionTheme?.crosshairLabelStyle;
    final textStyle = labelStyleConfig?.textStyle ?? const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final labelPadding = labelStyleConfig?.padding.left ?? 4.0;
    final borderRadius = labelStyleConfig?.borderRadius ?? 3.0;

    for (final axis in axesWithLabels) {
      final bounds = multiAxisInfo.axisBounds[axis.id];
      if (bounds == null) continue;

      // Denormalize the Y value for this axis
      final denormalizedY = MultiAxisNormalizer.denormalize(normalizedY, bounds.min, bounds.max);

      final axisColor = multiAxisInfo.resolveAxisColor(axis);

      // Format value with unit if configured
      final displayValue = axis.shouldShowTickUnit
          ? MultiAxisValueFormatter.formatFixed(value: denormalizedY, unit: axis.unit)
          : MultiAxisValueFormatter.formatFixed(value: denormalizedY, unit: null);

      final textPainter = TextPainter(
        text: TextSpan(text: displayValue, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Calculate label X position based on axis position
      final double labelX;
      final isLeftAxis = axis.position == YAxisPosition.left || axis.position == YAxisPosition.leftOuter;

      if (isLeftAxis) {
        final axisLineX = axis.position == YAxisPosition.left ? plotArea.left : plotArea.left - multiAxisInfo.getPositionWidth(YAxisPosition.left);
        labelX = axisLineX - textPainter.width - labelPadding * 2;
      } else {
        final axisLineX =
            axis.position == YAxisPosition.right ? plotArea.right : plotArea.right + multiAxisInfo.getPositionWidth(YAxisPosition.right);
        labelX = axisLineX + labelPadding * 2;
      }

      final labelY = (cursorPosition.dy - textPainter.height / 2).clamp(
        plotArea.top + labelPadding,
        plotArea.bottom - textPainter.height - labelPadding,
      );

      // Use semi-transparent background with axis color tint
      final bgColor = axisColor.withValues(alpha: 0.15);
      final bgPaint = Paint()..color = bgColor;
      final borderPaint = Paint()
        ..color = axisColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelX - labelPadding,
          labelY - labelPadding,
          textPainter.width + labelPadding * 2,
          textPainter.height + labelPadding * 2,
        ),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(bgRect, bgPaint);
      canvas.drawRRect(bgRect, borderPaint);
      textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  /// Paints intersection markers at series intersections.
  void _paintIntersectionMarkers({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required CrosshairTrackingState trackingState,
    required CrosshairConfig crosshairConfig,
    required MultiAxisInfo multiAxisInfo,
  }) {
    for (final value in trackingState.seriesValues) {
      double screenY;

      if (multiAxisInfo.effectiveAxes.length > 1) {
        // Look up the axis for this series
        final axisConfig = SeriesAxisResolver.resolveAxis(
          value.seriesId,
          multiAxisInfo.effectiveBindings,
          multiAxisInfo.effectiveAxes,
        );
        final seriesAxisBounds = axisConfig != null ? multiAxisInfo.axisBounds[axisConfig.id] : null;

        if (seriesAxisBounds != null) {
          screenY = CrosshairTracker.dataToScreenYForAxis(
            dataY: value.y,
            chartBounds: plotArea,
            axisMin: seriesAxisBounds.min,
            axisMax: seriesAxisBounds.max,
          );
        } else {
          screenY = CrosshairTracker.dataToScreenY(
            dataY: value.y,
            chartBounds: plotArea,
            yMin: transform.dataYMin,
            yMax: transform.dataYMax,
          );
        }
      } else {
        screenY = CrosshairTracker.dataToScreenY(
          dataY: value.y,
          chartBounds: plotArea,
          yMin: transform.dataYMin,
          yMax: transform.dataYMax,
        );
      }

      // Draw filled circle marker
      final markerPaint = Paint()
        ..color = value.seriesColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(cursorPosition.dx, screenY),
        crosshairConfig.intersectionMarkerRadius,
        markerPaint,
      );

      // Draw border for visibility
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(cursorPosition.dx, screenY),
        crosshairConfig.intersectionMarkerRadius,
        borderPaint,
      );
    }
  }

  /// Paints the tracking tooltip that follows the cursor.
  void _paintTrackingTooltip({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required CrosshairTrackingState trackingState,
    required MultiAxisInfo multiAxisInfo,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final tooltipTheme = interactionTheme?.tooltipStyle;

    final backgroundColor = tooltipTheme?.backgroundColor ?? const Color(0xF0FFFFFF);
    final textColor = tooltipTheme?.textStyle.color ?? const Color(0xFF333333);
    final fontSize = tooltipTheme?.textStyle.fontSize ?? 12.0;
    final borderColor = tooltipTheme?.borderColor ?? const Color(0xFFBDBDBD);
    final borderWidth = tooltipTheme?.borderWidth ?? 1.0;
    final borderRadius = tooltipTheme?.borderRadius ?? 4.0;
    final padding = tooltipTheme?.padding.left ?? 8.0;

    // Build tooltip content
    final textPainters = <(TextPainter, Color)>[];
    double maxWidth = 0;
    double totalHeight = 0;
    const lineSpacing = 4.0;
    const markerSize = 8.0;

    for (final value in trackingState.seriesValues) {
      // Get unit from axis config for multi-axis mode
      String? yUnit;
      if (multiAxisInfo.effectiveAxes.length > 1) {
        final axisConfig = SeriesAxisResolver.resolveAxis(
          value.seriesId,
          multiAxisInfo.effectiveBindings,
          multiAxisInfo.effectiveAxes,
        );
        yUnit = axisConfig?.unit;
      }

      final displayY = MultiAxisValueFormatter.format(value: value.y, unit: yUnit);
      final label = '${value.seriesName}: $displayY';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainters.add((tp, value.seriesColor));
      maxWidth = math.max(maxWidth, tp.width + markerSize + 6);
      totalHeight += tp.height + (textPainters.length > 1 ? lineSpacing : 0);
    }

    // Calculate tooltip position
    const cursorOffset = 12.0;
    var tooltipX = cursorPosition.dx + cursorOffset;
    var tooltipY = cursorPosition.dy - totalHeight / 2 - padding;

    final tooltipWidth = maxWidth + padding * 2;
    final tooltipHeight = totalHeight + padding * 2;

    // Keep tooltip within plot area bounds
    if (tooltipX + tooltipWidth > plotArea.right) {
      tooltipX = cursorPosition.dx - tooltipWidth - cursorOffset;
    }
    tooltipY = tooltipY.clamp(plotArea.top, plotArea.bottom - tooltipHeight);

    // Draw background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      Radius.circular(borderRadius),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x20000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(bgRect.shift(const Offset(2, 2)), shadowPaint);

    // Background and border
    canvas.drawRRect(bgRect, Paint()..color = backgroundColor);
    if (borderWidth > 0) {
      canvas.drawRRect(
        bgRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }

    // Draw text lines with colored markers
    var currentY = tooltipY + padding;
    for (final (tp, color) in textPainters) {
      canvas.drawCircle(
        Offset(tooltipX + padding + markerSize / 2, currentY + tp.height / 2),
        markerSize / 2 - 1,
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(tooltipX + padding + markerSize + 6, currentY));
      currentY += tp.height + lineSpacing;
    }
  }

  /// Paints the X-axis label for tracking mode.
  void _paintTrackingXLabel({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double dataX,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final labelStyle = interactionTheme?.crosshairLabelStyle;
    final textStyle = labelStyle?.textStyle ?? const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final backgroundColor = labelStyle?.backgroundColor ?? const Color(0xF0FFFFFF);
    final borderColor = labelStyle?.borderColor ?? const Color(0xFFBDBDBD);
    final borderWidth = labelStyle?.borderWidth ?? 1.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final labelPadding = labelStyle?.padding.left ?? 4.0;

    final xDisplayValue = _formatDataValue(dataX);
    final xTextPainter = TextPainter(
      text: TextSpan(text: 'X: $xDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    var xLabelX = cursorPosition.dx - xTextPainter.width / 2;
    final xLabelY = plotArea.bottom - xTextPainter.height - 8;

    xLabelX = xLabelX.clamp(
      plotArea.left + labelPadding,
      plotArea.right - xTextPainter.width - labelPadding,
    );

    final xBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        xLabelX - labelPadding,
        xLabelY - labelPadding,
        xTextPainter.width + labelPadding * 2,
        xTextPainter.height + labelPadding * 2,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(xBgRect, Paint()..color = backgroundColor);
    if (borderWidth > 0) {
      canvas.drawRRect(
        xBgRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
    xTextPainter.paint(canvas, Offset(xLabelX, xLabelY));
  }

  /// Paints the Y-axis label for tracking mode (single-axis mode).
  void _paintTrackingYLabel({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double dataY,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final labelStyle = interactionTheme?.crosshairLabelStyle;
    final textStyle = labelStyle?.textStyle ?? const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final backgroundColor = labelStyle?.backgroundColor ?? const Color(0xF0FFFFFF);
    final borderColor = labelStyle?.borderColor ?? const Color(0xFFBDBDBD);
    final borderWidth = labelStyle?.borderWidth ?? 1.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final labelPadding = labelStyle?.padding.left ?? 4.0;

    final yDisplayValue = _formatDataValue(dataY);
    final yTextPainter = TextPainter(
      text: TextSpan(text: 'Y: $yDisplayValue', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final yLabelX = plotArea.left + 8;
    var yLabelY = cursorPosition.dy - yTextPainter.height / 2;

    yLabelY = yLabelY.clamp(
      plotArea.top + labelPadding,
      plotArea.bottom - yTextPainter.height - labelPadding,
    );

    final yBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        yLabelX - labelPadding,
        yLabelY - labelPadding,
        yTextPainter.width + labelPadding * 2,
        yTextPainter.height + labelPadding * 2,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(yBgRect, Paint()..color = backgroundColor);
    if (borderWidth > 0) {
      canvas.drawRRect(
        yBgRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
    yTextPainter.paint(canvas, Offset(yLabelX, yLabelY));
  }

  /// Formats data values for display.
  String _formatDataValue(double value) {
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.round().toString();
    }
  }
}
