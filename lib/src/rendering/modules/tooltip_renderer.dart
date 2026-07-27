// Copyright (c) 2025 braven_charts. All rights reserved.
// Tooltip Renderer Module - Extracted from ChartRenderBox

import 'package:flutter/painting.dart';

import '../../axis/series_axis_resolver.dart';
import '../../elements/series_element.dart';
import '../../formatting/multi_axis_value_formatter.dart';
import '../../interaction/core/chart_element.dart';
import '../../interaction/core/coordinator.dart';
import '../../interaction/core/data_hit.dart';
import '../../models/chart_series.dart';
import '../../models/bar_chart_style.dart';
import '../../models/chart_theme.dart';
import '../../models/interaction_config.dart';
import '../../models/series_axis_binding.dart';
import '../../models/y_axis_config.dart';
import '../../utils/text_direction_resolver.dart';
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

  /// Builds the renderer-neutral tooltip body for one resolved datum.
  ///
  /// Composed radial data may add a group heading. Standalone radial and
  /// Cartesian tooltips keep their existing text because their group fields
  /// are null.
  String buildBaseTooltipText({
    required ChartDataHit dataHit,
    required String seriesName,
    required String formattedCartesianY,
    required String Function(double) formatDataValue,
  }) {
    if (dataHit.candlestick case final candle?) {
      final heading = dataHit.point.label == null
          ? seriesName
          : '$seriesName · ${dataHit.point.label}';
      return '$heading\n'
          'Open: ${candle.formattedOpen}\n'
          'High: ${candle.formattedHigh}\n'
          'Low: ${candle.formattedLow}\n'
          'Close: ${candle.formattedClose}\n'
          'Change: ${candle.formattedChange} · ${candle.direction.name}';
    }
    if (dataHit.category == null || dataHit.share == null) {
      final isAggregate =
          dataHit.sourcePointIndices.length > 1 ||
          dataHit.formattedAggregateValue != null ||
          (dataHit.category?.endsWith(' bin') ?? false);
      if (isAggregate) {
        final aggregateLabel =
            dataHit.category ??
            '${dataHit.sourcePointIndices.length} observations';
        final sampleCount = dataHit.aggregateSampleCount;
        final sourceCount = dataHit.effectiveSourcePointIndices.length;
        final aggregateSampleLine =
            sampleCount != null && sampleCount < sourceCount
            ? '\nAggregate sample: $sampleCount of $sourceCount observations'
            : '';
        final rangeLines = [
          if (dataHit.formattedXRange != null)
            'X range: ${dataHit.formattedXRange}',
          if (dataHit.formattedYRange != null)
            'Y range: ${dataHit.formattedYRange}',
        ];
        final rangeSummary = rangeLines.isEmpty
            ? ''
            : '\n${rangeLines.join('\n')}';
        final activationSummary = dataHit.activationHint == null
            ? ''
            : '\n${dataHit.activationHint}';
        return '$seriesName\n$aggregateLabel'
            '\nX mean: ${dataHit.formattedXValue ?? formatDataValue(dataHit.point.x)}'
            '\nY mean: ${dataHit.formattedValue}'
            '$rangeSummary'
            '${dataHit.formattedAggregateValue == null ? '' : '\n${dataHit.aggregateLabel ?? 'Aggregate'}: ${dataHit.formattedAggregateValue}'}'
            '$aggregateSampleLine'
            '$activationSummary';
      }
      final sizeLine = dataHit.formattedRadiusValue == null
          ? ''
          : '\n${dataHit.radiusLabel ?? 'Magnitude'}: ${dataHit.formattedRadiusValue}';
      final colorLine = dataHit.formattedColorValue == null
          ? ''
          : '\n${dataHit.colorLabel ?? 'Color value'}: ${dataHit.formattedColorValue}';
      final opacityLine = dataHit.formattedOpacityValue == null
          ? ''
          : '\n${dataHit.opacityLabel ?? 'Opacity value'}: ${dataHit.formattedOpacityValue}';
      final categoryLine = dataHit.categoryValue == null
          ? ''
          : '\n${dataHit.categoryLabel ?? 'Category'}: ${dataHit.categoryValue}';
      return '$seriesName\nX: ${formatDataValue(dataHit.point.x)}\n'
          'Y: $formattedCartesianY$sizeLine$colorLine$opacityLine$categoryLine';
    }
    final groupHeading = dataHit.groupLabel == null
        ? ''
        : '${dataHit.groupLabel} · ${dataHit.groupName ?? dataHit.seriesId}\n';
    return '$groupHeading${dataHit.category}\n'
        'Value: ${dataHit.formattedValue}\n'
        'Share: ${dataHit.formattedShare ?? '${(dataHit.share! * 100).toStringAsFixed(1)}%'}'
        '${dataHit.formattedRadiusValue == null ? '' : '\n${dataHit.radiusLabel ?? 'Radius'}: ${dataHit.formattedRadiusValue}'}';
  }

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
    double textScaleFactor = 1,
  }) {
    // Get tooltip configuration (use default if not provided)
    final config = interactionConfig?.tooltip ?? const TooltipConfig();

    // Get effective tooltip style (uses theme defaults when config doesn't specify)
    final style = resolveStyle(interactionConfig, theme);

    // Find the renderer-neutral data element containing this marker.
    final dataElement = elements.whereType<DataHitElement>().firstWhere(
      (e) => e.id == markerInfo.seriesId,
      orElse: () => throw StateError('Series ${markerInfo.seriesId} not found'),
    );

    // Get the exact data point
    final dataHit =
        markerInfo.dataHit ??
        dataElement.dataHitForPointIndex(markerInfo.markerIndex);
    if (dataHit == null) return;
    final dataPoint = dataHit.point;

    // Convert data point to screen coordinates for tooltip anchor
    // If followCursor is enabled, use current cursor position instead of marker position
    final tooltipAnchor = config.followCursor && cursorPosition != null
        ? cursorPosition
        : plotToWidget(markerInfo.plotPosition);

    // Build tooltip text with Y-value formatting including units (T023)
    final seriesName = dataElement.series.name ?? dataElement.id;

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
    final tooltipValue = switch (dataElement.series) {
      final BarChartSeries barSeries
          when barSeries.layoutMode == BarLayoutMode.waterfall =>
        barSeries.waterfallDisplayValueFor(markerInfo.markerIndex),
      _ => dataPoint.y,
    };
    final formattedY = MultiAxisValueFormatter.format(
      value: tooltipValue,
      unit: yUnit,
    );

    final baseTooltipText = buildBaseTooltipText(
      dataHit: dataHit,
      seriesName: seriesName,
      formattedCartesianY: formattedY,
      formatDataValue: formatDataValue,
    );
    final barSeries = dataElement.series is BarChartSeries
        ? dataElement.series as BarChartSeries
        : null;
    final targetValue = barSeries?.targetValueFor(markerInfo.markerIndex);
    final errorLower = barSeries?.errorLowerValueFor(markerInfo.markerIndex);
    final errorUpper = barSeries?.errorUpperValueFor(markerInfo.markerIndex);
    final qualitativeRange = barSeries?.bulletStyle?.rangeForValue(dataPoint.y);
    final tooltipBuffer = StringBuffer(baseTooltipText);
    if (barSeries?.layoutMode == BarLayoutMode.divergingStacked) {
      tooltipBuffer.write('\nResponse: ${barSeries!.divergingRole.name}');
    }
    if (targetValue != null) {
      tooltipBuffer.write(
        '\nTarget: ${MultiAxisValueFormatter.format(value: targetValue, unit: yUnit)}',
      );
    }
    if (errorLower != null && errorUpper != null) {
      tooltipBuffer.write(
        '\nUncertainty: '
        '${MultiAxisValueFormatter.format(value: errorLower, unit: yUnit)} – '
        '${MultiAxisValueFormatter.format(value: errorUpper, unit: yUnit)}',
      );
    }
    if (qualitativeRange?.label case final label?) {
      tooltipBuffer.write('\nRange: $label');
    }
    final tooltipText = tooltipBuffer.toString();

    // Create text painter with configured style
    final textStyle = TextStyle(
      color: style.textColor,
      fontSize: style.fontSize * textScaleFactor,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: tooltipText, style: textStyle),
      textDirection: resolveChartTextDirection(tooltipText),
      textAlign: TextAlign.center,
    )..layout();

    // Calculate tooltip size with configured padding
    final padding = style.padding;
    final tooltipWidth = textPainter.width + padding * 2;
    final tooltipHeight = textPainter.height + padding * 2;

    // Get marker radius to offset tooltip position
    double markerRadius = 0.0;
    if (dataElement is SeriesElement && dataElement.series is LineChartSeries) {
      markerRadius =
          (dataElement.series as LineChartSeries).dataPointMarkerRadius;
    } else if (dataElement is SeriesElement &&
        dataElement.series is ScatterChartSeries) {
      markerRadius = (dataElement.series as ScatterChartSeries).markerRadius;
    } else if (dataElement is SeriesElement &&
        dataElement.series is AreaChartSeries) {
      markerRadius =
          (dataElement.series as AreaChartSeries).dataPointMarkerRadius;
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

    final tooltipRect = Rect.fromLTWH(
      tooltipX,
      tooltipY,
      tooltipWidth,
      tooltipHeight,
    );

    final tooltipPath = _createTooltipPath(
      tooltipRect: tooltipRect,
      arrowAnchor: tooltipAnchor,
      arrowSize: arrowSize,
      borderRadius: style.borderRadius,
    );

    // Scale the complete popup around its data-point attachment. The arrow
    // therefore stays pinned while the card performs its brief flick motion.
    canvas.save();
    canvas.translate(tooltipAnchor.dx, tooltipAnchor.dy);
    canvas.scale(animator.scale, animator.scale);
    canvas.translate(-tooltipAnchor.dx, -tooltipAnchor.dy);

    // Draw shadow if configured (with opacity)
    if (style.shadowBlurRadius > 0) {
      final shadowPath = tooltipPath.shift(const Offset(0, 2));
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = style.shadowColor.withValues(
            alpha: style.shadowColor.a * animator.opacity,
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            style.shadowBlurRadius,
          ),
      );
    }

    // Draw background with configured color (with opacity)
    canvas.drawPath(
      tooltipPath,
      Paint()
        ..color = style.backgroundColor.withValues(
          alpha: style.backgroundColor.a * animator.opacity,
        )
        ..style = PaintingStyle.fill,
    );

    // Draw border if configured (with opacity)
    if (style.borderWidth > 0) {
      canvas.drawPath(
        tooltipPath,
        Paint()
          ..color = style.borderColor.withValues(
            alpha: style.borderColor.a * animator.opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.borderWidth,
      );
    }

    // Draw text (with opacity)
    final textPaintWithOpacity = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: textStyle.copyWith(
          color: style.textColor.withValues(alpha: animator.opacity),
        ),
      ),
      textDirection: resolveChartTextDirection(tooltipText),
      textAlign: TextAlign.center,
    )..layout();
    textPaintWithOpacity.paint(
      canvas,
      Offset(tooltipX + padding, tooltipY + padding),
    );
    canvas.restore();
  }

  /// Resolves an explicit tooltip style before the chart-theme fallback.
  ///
  /// [TooltipConfig] predates theme-level tooltip styling and therefore owns a
  /// non-null default style. Treat that exact default value as unspecified so
  /// [ChartTheme.interactionTheme] can style tooltips without requiring every
  /// chart to duplicate the same configuration.
  TooltipStyle resolveStyle(
    InteractionConfig? interactionConfig,
    ChartTheme? theme,
  ) {
    final configStyle = interactionConfig?.tooltip.style;
    final themeTooltipStyle = theme?.interactionTheme.tooltipStyle;

    // A non-default per-chart value is an explicit override.
    if (configStyle != null && configStyle != const TooltipStyle()) {
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
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.top,
        tooltipRect.right,
        tooltipRect.top + borderRadius,
      );
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.bottom,
        tooltipRect.right - borderRadius,
        tooltipRect.bottom,
      );
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.bottom,
        tooltipRect.left,
        tooltipRect.bottom - borderRadius,
      );
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.top,
        tooltipRect.left + borderRadius,
        tooltipRect.top,
      );
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
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.top,
        tooltipRect.right,
        tooltipRect.top + borderRadius,
      );
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.bottom,
        tooltipRect.right - borderRadius,
        tooltipRect.bottom,
      );
      path.lineTo(tooltipRect.left + arrowRight, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + arrowX, arrowBottom); // Arrow point
      path.lineTo(tooltipRect.left + arrowLeft, tooltipRect.bottom);
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.bottom,
        tooltipRect.left,
        tooltipRect.bottom - borderRadius,
      );
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.top,
        tooltipRect.left + borderRadius,
        tooltipRect.top,
      );
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
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.bottom,
        tooltipRect.left + borderRadius,
        tooltipRect.bottom,
      );
      path.lineTo(tooltipRect.right - borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.bottom,
        tooltipRect.right,
        tooltipRect.bottom - borderRadius,
      );
      path.lineTo(tooltipRect.right, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.top,
        tooltipRect.right - borderRadius,
        tooltipRect.top,
      );
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.top);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.top,
        tooltipRect.left,
        tooltipRect.top + borderRadius,
      );
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
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.top,
        tooltipRect.right,
        tooltipRect.top + borderRadius,
      );
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowTop);
      path.lineTo(arrowRight, tooltipRect.top + arrowY); // Arrow point
      path.lineTo(tooltipRect.right, tooltipRect.top + arrowBottom);
      path.lineTo(tooltipRect.right, tooltipRect.bottom - borderRadius);
      path.quadraticBezierTo(
        tooltipRect.right,
        tooltipRect.bottom,
        tooltipRect.right - borderRadius,
        tooltipRect.bottom,
      );
      path.lineTo(tooltipRect.left + borderRadius, tooltipRect.bottom);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.bottom,
        tooltipRect.left,
        tooltipRect.bottom - borderRadius,
      );
      path.lineTo(tooltipRect.left, tooltipRect.top + borderRadius);
      path.quadraticBezierTo(
        tooltipRect.left,
        tooltipRect.top,
        tooltipRect.left + borderRadius,
        tooltipRect.top,
      );
    }

    path.close();
    return path;
  }
}
