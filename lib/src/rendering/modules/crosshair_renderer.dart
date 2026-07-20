// Copyright (c) 2025 braven_charts. All rights reserved.
// Crosshair Renderer - Extracted from ChartRenderBox

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../axis/series_axis_resolver.dart';
import '../../coordinates/chart_transform.dart';
import '../../elements/annotation_elements.dart';
import '../../elements/series_element.dart';
import '../../formatting/multi_axis_value_formatter.dart';
import '../../interaction/core/crosshair_tracker.dart';
import '../../layout/axis_layout_manager.dart';
import '../../models/chart_series.dart';
import '../../models/chart_theme.dart';
import '../../models/interaction_config.dart';
import '../../models/normalization_mode.dart';
import '../../models/series_axis_binding.dart';
import '../../models/x_axis_config.dart';
import '../../models/y_axis_config.dart';
import '../../models/y_axis_position.dart';
import '../../utils/text_direction_resolver.dart';
import '../multi_axis_normalizer.dart';
import '../transposed_bar_axis_layout.dart';

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
  ///
  /// Returns true when there are multiple axes AND using perSeries normalization.
  /// This determines whether per-axis crosshair labels are rendered.
  bool get isMultiAxisMode =>
      effectiveAxes.length > 1 &&
      normalizationMode == NormalizationMode.perSeries;

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

  /// Calculates the horizontal text origin for a Y-axis crosshair label.
  ///
  /// Over-axis labels use the same per-axis rectangle as [MultiAxisPainter],
  /// keeping multiple axes on the same side in their own reserved strips.
  double calculateYAxisCrosshairLabelX({
    required Size chartSize,
    required Rect plotArea,
    required YAxisConfig axis,
    required double textWidth,
    required double labelPadding,
    required MultiAxisInfo multiAxisInfo,
  }) {
    final isLeftAxis =
        axis.position == YAxisPosition.left ||
        axis.position == YAxisPosition.leftOuter;

    if (axis.crosshairLabelPosition == CrosshairLabelPosition.insidePlot) {
      return isLeftAxis
          ? plotArea.left + labelPadding
          : plotArea.right - textWidth - labelPadding;
    }

    final axisRect = const AxisLayoutManager().getAxisRect(
      chartArea: Offset.zero & chartSize,
      axis: axis,
      axisWidths: multiAxisInfo.axisWidths,
      allAxes: multiAxisInfo.effectiveAxes,
    );

    return isLeftAxis
        ? axisRect.right - textWidth - labelPadding * 2
        : axisRect.left + labelPadding * 2;
  }

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
    InteractionConfig? interactionConfig,
    List<TrendAnnotationElement> trendElements = const [],
    XAxisConfig? xAxisConfig,
  }) {
    // Check if tracking mode should be used
    final seriesList = seriesElements.map((e) => e.series).toList();
    final totalDataPoints = CrosshairTracker.getTotalPointCount(seriesList);
    final useTrackingMode = crosshairConfig.shouldUseTrackingMode(
      totalDataPoints,
    );

    if (useTrackingMode) {
      _paintTrackingMode(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        transform: transform,
        theme: theme,
        interactionConfig: interactionConfig,
        crosshairConfig: crosshairConfig,
        multiAxisInfo: multiAxisInfo,
        seriesElements: seriesElements,
        trendElements: trendElements,
        xAxisConfig: xAxisConfig,
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
        seriesElements: seriesElements,
        xAxisConfig: xAxisConfig,
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
    required List<SeriesElement> seriesElements,
    XAxisConfig? xAxisConfig,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final axisColor = _resolveXAxisColor(xAxisConfig, seriesElements);
    final crosshairColor = isRangeCreationMode
        ? (interactionTheme?.crosshairColor ?? const Color(0xFF448AFF))
        : (interactionTheme?.crosshairColor ?? axisColor);
    final crosshairWidth = isRangeCreationMode
        ? 1.5
        : (interactionTheme?.crosshairWidth ?? 1.0);

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
      if (multiAxisInfo.isMultiAxisMode &&
          multiAxisInfo.effectiveAxes.length > 1) {
        // Extend left for leftOuter axes with showCrosshairLabel
        final hasLeftOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) =>
              a.position == YAxisPosition.leftOuter &&
              a.visible &&
              a.showCrosshairLabel,
        );
        if (hasLeftOuterLabels) {
          final leftOuterWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.leftOuter,
          );
          final leftWidth = multiAxisInfo.getPositionWidth(YAxisPosition.left);
          lineLeft = plotArea.left - leftWidth - leftOuterWidth;
        }

        // Extend right for rightOuter axes with showCrosshairLabel
        final hasRightOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) =>
              a.position == YAxisPosition.rightOuter &&
              a.visible &&
              a.showCrosshairLabel,
        );
        if (hasRightOuterLabels) {
          final rightOuterWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.rightOuter,
          );
          final rightWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.right,
          );
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
      size: size,
      cursorPosition: cursorPosition,
      plotArea: plotArea,
      transform: transform,
      theme: theme,
      multiAxisInfo: multiAxisInfo,
      seriesElements: seriesElements,
      xAxisConfig: xAxisConfig,
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
    InteractionConfig? interactionConfig,
    List<TrendAnnotationElement> trendElements = const [],
    XAxisConfig? xAxisConfig,
  }) {
    final interactionTheme = theme?.interactionTheme;
    final crosshairColor =
        interactionTheme?.crosshairColor ?? const Color(0x80666666);
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

      if (multiAxisInfo.isMultiAxisMode &&
          multiAxisInfo.effectiveAxes.length > 1) {
        final hasLeftOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) =>
              a.position == YAxisPosition.leftOuter &&
              a.visible &&
              a.showCrosshairLabel,
        );
        if (hasLeftOuterLabels) {
          final leftOuterWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.leftOuter,
          );
          final leftWidth = multiAxisInfo.getPositionWidth(YAxisPosition.left);
          lineLeft = plotArea.left - leftWidth - leftOuterWidth;
        }

        final hasRightOuterLabels = multiAxisInfo.effectiveAxes.any(
          (a) =>
              a.position == YAxisPosition.rightOuter &&
              a.visible &&
              a.showCrosshairLabel,
        );
        if (hasRightOuterLabels) {
          final rightOuterWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.rightOuter,
          );
          final rightWidth = multiAxisInfo.getPositionWidth(
            YAxisPosition.right,
          );
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
    final categoryScreenPosition = transform.transposed
        ? cursorPosition.dy
        : cursorPosition.dx;
    final trackingBounds = transform.transposed
        ? Rect.fromLTWH(plotArea.top, 0, plotArea.height, 1)
        : plotArea;
    final trackingState = CrosshairTracker.calculateTrackingState(
      screenX: categoryScreenPosition,
      chartBounds: trackingBounds,
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      seriesList: seriesList,
      interpolate: crosshairConfig.interpolateValues,
      includeScatterXFallback: false,
    );

    if (trackingState == null) return;

    // Line and Area tracking is X-oriented, while Scatter is an unordered
    // two-dimensional sample. Replace the fallback nearest-X Scatter values
    // with plot-space nearest points using each element's effective transform
    // (including per-series multi-axis normalization).
    final pointerInPlot = Offset(
      cursorPosition.dx - plotArea.left,
      cursorPosition.dy - plotArea.top,
    );
    for (final element in seriesElements) {
      final scatter = element.series;
      if (scatter is! ScatterChartSeries) continue;
      final hit = element.dataHitAt(
        pointerInPlot,
        maxDistance: double.infinity,
      );
      final nearest = hit == null
          ? null
          : CrosshairSeriesValue(
              seriesId: scatter.id,
              seriesName: scatter.displayName,
              seriesColor: hit.markerColor ?? element.themeColor,
              x: hit.point.x,
              y: hit.point.y,
              dataPointIndex: hit.pointIndex,
              isInterpolated: false,
              pointLabel: hit.point.label,
              magnitudeValue: hit.radiusValue,
              formattedMagnitudeValue: hit.formattedRadiusValue,
              magnitudeLabel: hit.radiusLabel,
              colorValue: hit.colorValue,
              formattedColorValue: hit.formattedColorValue,
              colorLabel: hit.colorLabel,
              opacityValue: hit.opacityValue,
              formattedOpacityValue: hit.formattedOpacityValue,
              opacityLabel: hit.opacityLabel,
              categoryValue: hit.categoryValue,
              categoryLabel: hit.categoryLabel,
            );
      final existingIndex = trackingState.seriesValues.indexWhere(
        (value) => value.seriesId == scatter.id,
      );
      if (nearest == null) {
        if (existingIndex >= 0) {
          trackingState.seriesValues.removeAt(existingIndex);
        }
      } else if (existingIndex >= 0) {
        trackingState.seriesValues[existingIndex] = nearest;
      } else {
        trackingState.seriesValues.add(nearest);
      }
    }

    // Append trend annotation values to tracking state
    for (final trendEl in trendElements) {
      final trendY = trendEl.evaluateAt(trackingState.dataX);
      if (trendY == null) continue;

      final label = trendEl.annotation.label;
      final displayName = (label != null && label.isNotEmpty)
          ? label
          : '${trendEl.annotation.trendType.name} trend';

      trackingState.seriesValues.add(
        CrosshairSeriesValue(
          seriesId: trendEl.annotation.id,
          seriesName: displayName,
          seriesColor: trendEl.annotation.lineColor,
          x: trackingState.dataX,
          y: trendY,
          dataPointIndex: -1,
          isInterpolated: true,
          linkedSeriesId: trendEl.annotation.seriesId,
          isTrend: true,
        ),
      );
    }

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
        seriesElements: seriesElements,
      );
    }

    // Draw tracking tooltip
    if (crosshairConfig.showTrackingTooltip &&
        trackingState.seriesValues.isNotEmpty) {
      _paintTrackingTooltip(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        interactionConfig: interactionConfig,
        trackingState: trackingState,
        multiAxisInfo: multiAxisInfo,
      );
    }

    if (transform.transposed) {
      _paintTransposedTrackingCategoryLabel(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        dataX: trackingState.dataX,
        fallbackDataX: _nearestDiscreteTrackingX(trackingState),
        seriesElements: seriesElements,
        xAxisConfig: xAxisConfig,
      );
      final isPerSeries =
          multiAxisInfo.normalizationMode == NormalizationMode.perSeries;
      final value = isPerSeries
          ? (cursorPosition.dx - plotArea.left) / plotArea.width
          : transform
                .plotToData(
                  cursorPosition.dx - plotArea.left,
                  cursorPosition.dy - plotArea.top,
                )
                .dy;
      _paintTransposedValueLabels(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        value: value,
        isNormalized: isPerSeries,
        multiAxisInfo: multiAxisInfo,
      );
      return;
    }

    // Draw X label
    if (mode == CrosshairMode.vertical || mode == CrosshairMode.both) {
      _paintTrackingXLabel(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        dataX: trackingState.dataX,
        fallbackDataX: _nearestDiscreteTrackingX(trackingState),
        seriesElements: seriesElements,
        xAxisConfig: xAxisConfig,
      );
    }

    // Draw Y label (per-axis if any axis has showCrosshairLabel)
    if (mode == CrosshairMode.horizontal || mode == CrosshairMode.both) {
      // Check if any axis wants a styled crosshair label
      final hasAxisWithCrosshairLabel = multiAxisInfo.effectiveAxes.any(
        (a) => a.showCrosshairLabel && a.visible,
      );
      final isPerSeriesMode =
          multiAxisInfo.normalizationMode == NormalizationMode.perSeries;

      if (hasAxisWithCrosshairLabel) {
        if (isPerSeriesMode) {
          // For perSeries normalization, calculate normalized Y from screen position
          // This matches the inverse of how the axis renderer positions ticks:
          // Axis: screenY = plotArea.bottom - (normalizedY * plotArea.height)
          // Inverse: normalizedY = (plotArea.bottom - cursorY) / plotArea.height
          final normalizedY =
              (plotArea.bottom - cursorPosition.dy) / plotArea.height;
          _paintPerAxisCrosshairLabels(
            canvas: canvas,
            size: size,
            cursorPosition: cursorPosition,
            plotArea: plotArea,
            theme: theme,
            yValue: normalizedY,
            multiAxisInfo: multiAxisInfo,
            isNormalized: true,
          );
        } else {
          // For non-normalized modes (none/auto), get actual data Y from transform
          final plotY = cursorPosition.dy - plotArea.top;
          final dataY = transform.plotToData(0, plotY).dy;
          _paintPerAxisCrosshairLabels(
            canvas: canvas,
            size: size,
            cursorPosition: cursorPosition,
            plotArea: plotArea,
            theme: theme,
            yValue: dataY,
            multiAxisInfo: multiAxisInfo,
            isNormalized: false,
          );
        }
      } else {
        // No axis has showCrosshairLabel - use generic Y label
        final plotY = cursorPosition.dy - plotArea.top;
        final dataY = transform.plotToData(0, plotY).dy;
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

  void _paintTransposedTrackingCategoryLabel({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double dataX,
    double? fallbackDataX,
    required List<SeriesElement> seriesElements,
    XAxisConfig? xAxisConfig,
  }) {
    if (xAxisConfig?.visible == false ||
        xAxisConfig?.showCrosshairLabel == false) {
      return;
    }
    final labelStyle = theme?.interactionTheme.crosshairLabelStyle;
    final textStyle =
        labelStyle?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final padding = labelStyle?.padding.left ?? 4.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final displayValue = _formatXAxisValue(
      dataX,
      xAxisConfig,
      fallbackValue: fallbackDataX,
    );
    final painter = TextPainter(
      text: TextSpan(text: displayValue, style: textStyle),
      textDirection: resolveChartTextDirection(displayValue),
    )..layout();
    final axisColor = _resolveXAxisColor(xAxisConfig, seriesElements);
    final inside =
        xAxisConfig?.crosshairLabelPosition ==
        CrosshairLabelPosition.insidePlot;
    final x = inside
        ? plotArea.left + padding * 2
        : plotArea.left - painter.width - padding * 2;
    final y = (cursorPosition.dy - painter.height / 2).clamp(
      plotArea.top + padding,
      plotArea.bottom - painter.height - padding,
    );
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - padding,
        y - padding,
        painter.width + padding * 2,
        painter.height + padding * 2,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(
      background,
      Paint()..color = axisColor.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..color = axisColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke,
    );
    painter.paint(canvas, Offset(x, y));
  }

  /// Paints coordinate labels (X and Y values).
  void _paintCrosshairLabels({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required ChartTheme? theme,
    required MultiAxisInfo multiAxisInfo,
    required List<SeriesElement> seriesElements,
    XAxisConfig? xAxisConfig,
  }) {
    // Convert widget space cursor to data coordinates
    // Note: cursorPosition is already in widget space, we need to offset by plotArea
    final plotX = cursorPosition.dx - plotArea.left;
    final plotY = cursorPosition.dy - plotArea.top;
    final dataPos = transform.plotToData(plotX, plotY);
    final dataX = dataPos.dx;
    final dataY = dataPos.dy;

    if (transform.transposed) {
      final isPerSeries =
          multiAxisInfo.normalizationMode == NormalizationMode.perSeries;
      _paintTransposedTrackingCategoryLabel(
        canvas: canvas,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        dataX: dataX,
        seriesElements: seriesElements,
        xAxisConfig: xAxisConfig,
      );
      _paintTransposedValueLabels(
        canvas: canvas,
        size: size,
        cursorPosition: cursorPosition,
        plotArea: plotArea,
        theme: theme,
        value: isPerSeries
            ? (cursorPosition.dx - plotArea.left) / plotArea.width
            : dataY,
        isNormalized: isPerSeries,
        multiAxisInfo: multiAxisInfo,
      );
      return;
    }

    final interactionTheme = theme?.interactionTheme;
    final labelStyle = interactionTheme?.crosshairLabelStyle;
    final textStyle =
        labelStyle?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final labelPadding = labelStyle?.padding.left ?? 4.0;

    // X coordinate label - only render if axis is visible and showCrosshairLabel is true
    if (xAxisConfig?.visible != false &&
        xAxisConfig?.showCrosshairLabel != false) {
      final axisColor = _resolveXAxisColor(xAxisConfig, seriesElements);

      final displayValue = _formatXAxisValue(dataX, xAxisConfig);

      final xTextPainter = TextPainter(
        text: TextSpan(text: displayValue, style: textStyle),
        textDirection: resolveChartTextDirection(displayValue),
      )..layout();

      var xLabelX = cursorPosition.dx - xTextPainter.width / 2;

      // Position label based on crosshairLabelPosition setting
      final double xLabelY;
      if (xAxisConfig?.crosshairLabelPosition ==
          CrosshairLabelPosition.insidePlot) {
        // Inside plot: near bottom edge
        xLabelY = plotArea.bottom - xTextPainter.height - labelPadding;
      } else {
        // Over axis (default): position just below plot area with compact padding
        xLabelY = plotArea.bottom + labelPadding * 2;
      }

      xLabelX = xLabelX.clamp(
        plotArea.left + labelPadding,
        plotArea.right - xTextPainter.width - labelPadding,
      );

      // Use themed colors with appropriate alpha values
      final backgroundColor = axisColor.withValues(alpha: 0.15);
      final borderColor = axisColor.withValues(alpha: 0.6);

      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final xBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          xLabelX - labelPadding,
          xLabelY - labelPadding,
          xTextPainter.width + labelPadding * 2,
          xTextPainter.height + labelPadding * 2,
        ),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(xBgRect, bgPaint);
      canvas.drawRRect(xBgRect, borderPaint);
      xTextPainter.paint(canvas, Offset(xLabelX, xLabelY));
    }

    // Y coordinate label: use per-axis styling if any axis has showCrosshairLabel
    final hasAxisWithCrosshairLabel = multiAxisInfo.effectiveAxes.any(
      (a) => a.showCrosshairLabel && a.visible,
    );
    final isPerSeriesMode =
        multiAxisInfo.normalizationMode == NormalizationMode.perSeries;

    if (hasAxisWithCrosshairLabel) {
      if (isPerSeriesMode) {
        // For perSeries, calculate normalized Y from screen position
        final normalizedY =
            (plotArea.bottom - cursorPosition.dy) / plotArea.height;
        _paintPerAxisCrosshairLabels(
          canvas: canvas,
          size: size,
          cursorPosition: cursorPosition,
          plotArea: plotArea,
          theme: theme,
          yValue: normalizedY,
          multiAxisInfo: multiAxisInfo,
          isNormalized: true,
        );
      } else {
        // For non-normalized, use dataY directly
        _paintPerAxisCrosshairLabels(
          canvas: canvas,
          size: size,
          cursorPosition: cursorPosition,
          plotArea: plotArea,
          theme: theme,
          yValue: dataY,
          multiAxisInfo: multiAxisInfo,
          isNormalized: false,
        );
      }
    }
    // Note: No fallback Y-label when no axis has showCrosshairLabel enabled
    // This respects the axis configuration intent
  }

  void _paintTransposedValueLabels({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double value,
    required bool isNormalized,
    required MultiAxisInfo multiAxisInfo,
  }) {
    final axes = multiAxisInfo.effectiveAxes
        .where((axis) => axis.visible && axis.showCrosshairLabel)
        .toList(growable: false);
    if (axes.isEmpty) return;
    final labelStyle = theme?.interactionTheme.crosshairLabelStyle;
    final textStyle =
        labelStyle?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final padding = labelStyle?.padding.left ?? 4.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final axisLabelStyle =
        theme?.axisStyle.labelStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 12);
    final layout = TransposedBarAxisLayout(
      axes: multiAxisInfo.effectiveAxes,
      labelStyle: axisLabelStyle,
    );
    final axisRects = layout.axisRects(plotArea);
    final bottomAxes = layout.bottomAxes;
    final topAxes = layout.topAxes;

    for (final axis in axes) {
      final bounds = multiAxisInfo.axisBounds[axis.id];
      final axisRect = axisRects[axis.id];
      if (bounds == null || axisRect == null) continue;
      final displayY = isNormalized
          ? MultiAxisNormalizer.denormalize(value, bounds.min, bounds.max)
          : value;
      final displayValue =
          axis.labelFormatter?.call(displayY) ??
          '${_formatDataValue(displayY)}${axis.unit == null ? '' : ' ${axis.unit}'}';
      final painter = TextPainter(
        text: TextSpan(text: displayValue, style: textStyle),
        textDirection: resolveChartTextDirection(displayValue),
      )..layout();
      final axisColor = multiAxisInfo.resolveAxisColor(axis);
      final isBottom = TransposedBarAxisLayout.isBottom(axis);
      final inside =
          axis.crosshairLabelPosition == CrosshairLabelPosition.insidePlot;
      final x = (cursorPosition.dx - painter.width / 2).clamp(
        plotArea.left + padding,
        plotArea.right - painter.width - padding,
      );
      final double y;
      if (inside) {
        final sideAxes = isBottom ? bottomAxes : topAxes;
        final index = sideAxes.indexWhere(
          (candidate) => candidate.id == axis.id,
        );
        final offset = (index + 1) * (painter.height + padding * 2);
        y = isBottom
            ? plotArea.bottom - offset
            : plotArea.top + offset - painter.height;
      } else {
        y = isBottom
            ? axisRect.top + padding * 2
            : axisRect.bottom - painter.height - padding * 2;
      }
      final background = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - padding,
          y - padding,
          painter.width + padding * 2,
          painter.height + padding * 2,
        ),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(
        background,
        Paint()..color = axisColor.withValues(alpha: 0.15),
      );
      canvas.drawRRect(
        background,
        Paint()
          ..color = axisColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke,
      );
      painter.paint(canvas, Offset(x, y));
    }
  }

  /// Paints per-axis crosshair labels.
  ///
  /// When [isNormalized] is true, [yValue] is in 0-1 range and will be
  /// denormalized using axis bounds. When false, [yValue] is already
  /// the data Y value and will be used directly.
  void _paintPerAxisCrosshairLabels({
    required Canvas canvas,
    required Size size,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required double yValue,
    required MultiAxisInfo multiAxisInfo,
    required bool isNormalized,
  }) {
    final axesWithLabels = multiAxisInfo.effectiveAxes
        .where((a) => a.showCrosshairLabel && a.visible)
        .toList();
    if (axesWithLabels.isEmpty) return;

    final interactionTheme = theme?.interactionTheme;
    final labelStyleConfig = interactionTheme?.crosshairLabelStyle;
    final textStyle =
        labelStyleConfig?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final labelPadding = labelStyleConfig?.padding.left ?? 4.0;
    final borderRadius = labelStyleConfig?.borderRadius ?? 3.0;

    for (final axis in axesWithLabels) {
      final bounds = multiAxisInfo.axisBounds[axis.id];
      if (bounds == null) continue;

      // For normalized mode: denormalize 0-1 value using axis bounds
      // For non-normalized mode: use the value directly (it's already data Y)
      final displayY = isNormalized
          ? MultiAxisNormalizer.denormalize(yValue, bounds.min, bounds.max)
          : yValue;

      final axisColor = multiAxisInfo.resolveAxisColor(axis);

      // Format value with unit if configured
      final displayValue = axis.shouldShowTickUnit
          ? MultiAxisValueFormatter.formatFixed(
              value: displayY,
              unit: axis.unit,
            )
          : MultiAxisValueFormatter.formatFixed(value: displayY, unit: null);

      final textPainter = TextPainter(
        text: TextSpan(text: displayValue, style: textStyle),
        textDirection: resolveChartTextDirection(displayValue),
      )..layout();

      final labelX = calculateYAxisCrosshairLabelX(
        chartSize: size,
        plotArea: plotArea,
        axis: axis,
        textWidth: textPainter.width,
        labelPadding: labelPadding,
        multiAxisInfo: multiAxisInfo,
      );

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
    required List<SeriesElement> seriesElements,
  }) {
    // Save canvas state and clip to plot area to prevent markers from
    // rendering outside the plot boundaries
    canvas.save();
    canvas.clipRect(plotArea);

    for (final value in trackingState.seriesValues) {
      var screenX = cursorPosition.dx;
      double screenY;

      SeriesElement? seriesElement;
      if (!value.isTrend) {
        for (final candidate in seriesElements) {
          if (candidate.id == value.seriesId) {
            seriesElement = candidate;
            break;
          }
        }
      }
      final barGeometry = seriesElement?.barGeometryForPoint(
        value.dataPointIndex,
      );
      final scatterHit = seriesElement?.series is ScatterChartSeries
          ? seriesElement?.dataHitForPointIndex(value.dataPointIndex)
          : null;

      if (scatterHit != null) {
        screenX = plotArea.left + scatterHit.plotPosition.dx;
        screenY = plotArea.top + scatterHit.plotPosition.dy;
      } else if (barGeometry != null) {
        screenX = plotArea.left + barGeometry.valueEndX;
        screenY = plotArea.top + barGeometry.valueEndY;
      } else if (!value.isInterpolated &&
          seriesElement != null &&
          (seriesElement.series is LineChartSeries ||
              seriesElement.series is AreaChartSeries)) {
        final point = seriesElement.dataToCurrentPlot(value.x, value.y);
        screenX = plotArea.left + point.dx;
        screenY = plotArea.top + point.dy;
      } else if (multiAxisInfo.effectiveAxes.length > 1) {
        // Look up the axis for this series (use linked series ID for trends)
        final axisConfig = SeriesAxisResolver.resolveAxis(
          value.axisSeriesId,
          multiAxisInfo.effectiveBindings,
          multiAxisInfo.effectiveAxes,
        );
        final seriesAxisBounds = axisConfig != null
            ? multiAxisInfo.axisBounds[axisConfig.id]
            : null;

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
        Offset(screenX, screenY),
        crosshairConfig.intersectionMarkerRadius,
        markerPaint,
      );

      // Draw border for visibility
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(screenX, screenY),
        crosshairConfig.intersectionMarkerRadius,
        borderPaint,
      );
    }

    // Restore canvas state after drawing markers
    canvas.restore();
  }

  /// Resolves the effective tooltip style for the tracking tooltip, following
  /// the same priority as [tooltip_renderer.dart]:
  ///   1. [interactionConfig.tooltip.style] when [interactionConfig] is set
  ///   2. Theme [LabelStyle] translated to [TooltipStyle]
  ///   3. Hardcoded defaults via [const TooltipStyle()]
  TooltipStyle _getEffectiveTrackingTooltipStyle(
    InteractionConfig? interactionConfig,
    ChartTheme? theme,
  ) {
    // Priority 1 — explicit interactionConfig style
    final configStyle = interactionConfig?.tooltip.style;
    if (configStyle != null) {
      return configStyle;
    }

    // Priority 2 — theme LabelStyle translated to TooltipStyle
    final themeStyle = theme?.interactionTheme.tooltipStyle;
    if (themeStyle != null) {
      return TooltipStyle(
        backgroundColor: themeStyle.backgroundColor,
        textColor: themeStyle.textStyle.color ?? const Color(0xFF333333),
        fontSize: themeStyle.textStyle.fontSize ?? 12.0,
        borderColor: themeStyle.borderColor,
        borderWidth: themeStyle.borderWidth,
        borderRadius: themeStyle.borderRadius,
        padding: themeStyle.padding.left,
        shadowColor: themeStyle.shadowColor ?? const Color(0x00000000),
        shadowBlurRadius: themeStyle.shadowBlurRadius ?? 0.0,
      );
    }

    // Priority 3 — library defaults
    return const TooltipStyle();
  }

  /// Paints the tracking tooltip that follows the cursor.
  void _paintTrackingTooltip({
    required Canvas canvas,
    required Offset cursorPosition,
    required Rect plotArea,
    required ChartTheme? theme,
    required CrosshairTrackingState trackingState,
    required MultiAxisInfo multiAxisInfo,
    InteractionConfig? interactionConfig,
  }) {
    final style = _getEffectiveTrackingTooltipStyle(interactionConfig, theme);

    final backgroundColor = style.backgroundColor;
    final textColor = style.textColor;
    final fontSize = style.fontSize;
    final fontFamily =
        theme?.interactionTheme.tooltipStyle.textStyle.fontFamily ??
        theme?.typographyTheme.fontFamily;
    final borderColor = style.borderColor;
    final borderWidth = style.borderWidth;
    final borderRadius = style.borderRadius;
    final padding = style.padding;

    // Build tooltip content — separate series values from trend values
    final seriesEntries = <(TextPainter, Color)>[];
    final trendEntries = <(TextPainter, Color)>[];
    double maxWidth = 0;
    double totalHeight = 0;
    const lineSpacing = 4.0;
    const markerSize = 8.0;
    const dividerSpacing = 6.0;

    for (final value in trackingState.seriesValues) {
      // Get unit from axis config for multi-axis mode
      String? yUnit;
      if (multiAxisInfo.effectiveAxes.length > 1) {
        final axisConfig = SeriesAxisResolver.resolveAxis(
          value.axisSeriesId,
          multiAxisInfo.effectiveBindings,
          multiAxisInfo.effectiveAxes,
        );
        yUnit = axisConfig?.unit;
      }

      final displayY = MultiAxisValueFormatter.format(
        value: value.y,
        unit: yUnit,
      );
      final candle = value.candlestick;
      final hasScatterDetail =
          value.pointLabel != null ||
          value.formattedMagnitudeValue != null ||
          value.formattedColorValue != null ||
          value.formattedOpacityValue != null ||
          value.categoryValue != null;
      final label = candle != null
          ? '${value.seriesName}${value.pointLabel == null ? '' : ' · ${value.pointLabel}'}\n'
                'O ${candle.formattedOpen} · H ${candle.formattedHigh}\n'
                'L ${candle.formattedLow} · C ${candle.formattedClose}\n'
                '${candle.formattedChange} · ${candle.direction.name}'
          : hasScatterDetail
          ? '${value.seriesName}${value.pointLabel == null ? '' : ' · ${value.pointLabel}'}\n'
                'X: ${_formatDataValue(value.x)} · Y: $displayY'
                '${value.formattedMagnitudeValue == null ? '' : '\n${value.magnitudeLabel ?? 'Magnitude'}: ${value.formattedMagnitudeValue}'}'
                '${value.formattedColorValue == null ? '' : '\n${value.colorLabel ?? 'Color value'}: ${value.formattedColorValue}'}'
                '${value.formattedOpacityValue == null ? '' : '\n${value.opacityLabel ?? 'Opacity value'}: ${value.formattedOpacityValue}'}'
                '${value.categoryValue == null ? '' : '\n${value.categoryLabel ?? 'Category'}: ${value.categoryValue}'}'
          : '${value.seriesName}: $displayY';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: resolveChartTextDirection(label),
      )..layout();

      final target = value.isTrend ? trendEntries : seriesEntries;
      target.add((tp, value.seriesColor));
      maxWidth = math.max(maxWidth, tp.width + markerSize + 6);
    }

    // Calculate total height: series rows + optional divider + trend rows
    for (var i = 0; i < seriesEntries.length; i++) {
      totalHeight += seriesEntries[i].$1.height + (i > 0 ? lineSpacing : 0);
    }

    // Trend header painter (only if we have both series and trend entries)
    TextPainter? trendHeaderPainter;
    final hasTrendDivider = trendEntries.isNotEmpty && seriesEntries.isNotEmpty;
    if (hasTrendDivider) {
      trendHeaderPainter = TextPainter(
        text: TextSpan(
          text: 'Trends',
          style: TextStyle(
            color: textColor.withAlpha(153),
            fontSize: fontSize - 1,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: resolveChartTextDirection('Trends'),
      )..layout();
      // divider spacing + line + spacing + header + spacing
      totalHeight +=
          dividerSpacing +
          1 +
          dividerSpacing +
          trendHeaderPainter.height +
          lineSpacing;
      maxWidth = math.max(maxWidth, trendHeaderPainter.width);
    }

    for (var i = 0; i < trendEntries.length; i++) {
      totalHeight += trendEntries[i].$1.height + (i > 0 ? lineSpacing : 0);
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

    // Draw series value rows with colored markers
    var currentY = tooltipY + padding;
    for (final (tp, color) in seriesEntries) {
      canvas.drawCircle(
        Offset(tooltipX + padding + markerSize / 2, currentY + tp.height / 2),
        markerSize / 2 - 1,
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(tooltipX + padding + markerSize + 6, currentY));
      currentY += tp.height + lineSpacing;
    }

    // Draw trend divider and header if applicable
    if (hasTrendDivider && trendHeaderPainter != null) {
      currentY += dividerSpacing - lineSpacing;
      // Thin divider line
      canvas.drawLine(
        Offset(tooltipX + padding, currentY),
        Offset(tooltipX + tooltipWidth - padding, currentY),
        Paint()
          ..color = borderColor.withAlpha(128)
          ..strokeWidth = 0.5,
      );
      currentY += 1 + dividerSpacing;
      // "Trends" header
      trendHeaderPainter.paint(canvas, Offset(tooltipX + padding, currentY));
      currentY += trendHeaderPainter.height + lineSpacing;
    }

    // Draw trend value rows with colored markers
    for (final (tp, color) in trendEntries) {
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
    double? fallbackDataX,
    required List<SeriesElement> seriesElements,
    XAxisConfig? xAxisConfig,
  }) {
    // Skip if axis is not visible or showCrosshairLabel is false
    if (xAxisConfig?.visible == false ||
        xAxisConfig?.showCrosshairLabel == false) {
      return;
    }

    final interactionTheme = theme?.interactionTheme;
    final labelStyle = interactionTheme?.crosshairLabelStyle;
    final textStyle =
        labelStyle?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final labelPadding = labelStyle?.padding.left ?? 4.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;

    final axisColor = _resolveXAxisColor(xAxisConfig, seriesElements);

    final displayValue = _formatXAxisValue(
      dataX,
      xAxisConfig,
      fallbackValue: fallbackDataX,
    );

    final xTextPainter = TextPainter(
      text: TextSpan(text: displayValue, style: textStyle),
      textDirection: resolveChartTextDirection(displayValue),
    )..layout();

    var xLabelX = cursorPosition.dx - xTextPainter.width / 2;

    final double xLabelY;
    if (xAxisConfig?.crosshairLabelPosition ==
        CrosshairLabelPosition.insidePlot) {
      xLabelY = plotArea.bottom - xTextPainter.height - labelPadding;
    } else {
      xLabelY = plotArea.bottom + labelPadding * 2;
    }

    xLabelX = xLabelX.clamp(
      plotArea.left + labelPadding,
      plotArea.right - xTextPainter.width - labelPadding,
    );

    // Use themed colors with appropriate alpha values
    final backgroundColor = axisColor.withValues(alpha: 0.15);
    final borderColor = axisColor.withValues(alpha: 0.6);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final xBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        xLabelX - labelPadding,
        xLabelY - labelPadding,
        xTextPainter.width + labelPadding * 2,
        xTextPainter.height + labelPadding * 2,
      ),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(xBgRect, bgPaint);
    canvas.drawRRect(xBgRect, borderPaint);
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
    final textStyle =
        labelStyle?.textStyle ??
        const TextStyle(color: Color(0xFF000000), fontSize: 10);
    final backgroundColor =
        labelStyle?.backgroundColor ?? const Color(0xF0FFFFFF);
    final borderColor = labelStyle?.borderColor ?? const Color(0xFFBDBDBD);
    final borderWidth = labelStyle?.borderWidth ?? 1.0;
    final borderRadius = labelStyle?.borderRadius ?? 3.0;
    final labelPadding = labelStyle?.padding.left ?? 4.0;

    final yDisplayValue = _formatDataValue(dataY);
    final yTextPainter = TextPainter(
      text: TextSpan(text: 'Y: $yDisplayValue', style: textStyle),
      textDirection: resolveChartTextDirection('Y: $yDisplayValue'),
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

  Color _resolveXAxisColor(
    XAxisConfig? xAxisConfig,
    List<SeriesElement> seriesElements,
  ) {
    if (xAxisConfig?.color != null) {
      return xAxisConfig!.color!;
    }

    for (final element in seriesElements) {
      final seriesColor = element.series.color;
      if (seriesColor != null) {
        return seriesColor;
      }
    }

    return const Color(0xFF333333);
  }

  double? _nearestDiscreteTrackingX(CrosshairTrackingState trackingState) {
    for (final value in trackingState.seriesValues) {
      if (!value.isTrend &&
          !value.isInterpolated &&
          value.dataPointIndex >= 0) {
        return value.x;
      }
    }
    return null;
  }

  String _formatXAxisValue(
    double value,
    XAxisConfig? config, {
    double? fallbackValue,
  }) {
    String? formatConfiguredValue(double candidate) {
      final categoryLabel = config?.categoryLabelFor(candidate);
      if (categoryLabel != null && categoryLabel.trim().isNotEmpty) {
        return categoryLabel;
      }
      final formatter = config?.labelFormatter;
      if (formatter != null) {
        final formatted = formatter(candidate);
        if (formatted.trim().isNotEmpty) return formatted;
      }
      return null;
    }

    final configuredValue = formatConfiguredValue(value);
    if (configuredValue != null) return configuredValue;

    if (fallbackValue != null && fallbackValue != value) {
      final fallbackLabel = formatConfiguredValue(fallbackValue);
      if (fallbackLabel != null) return fallbackLabel;
    }

    final formattedValue = _formatDataValue(value);
    return config?.unit == null
        ? formattedValue
        : '$formattedValue ${config!.unit}';
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
