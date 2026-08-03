// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../elements/series_element.dart';
import '../../models/chart_data_point.dart';
import '../../models/chart_series.dart';
import '../../models/chart_theme.dart';
import '../../models/series_callout_config.dart';
import 'series_callout_layout.dart';

class _ResolvedSeriesCallout {
  const _ResolvedSeriesCallout({
    required this.element,
    required this.anchor,
    required this.textPainter,
    required this.boxSize,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.connectorWidth,
    required this.connectorOpacity,
    required this.connectorGlow,
    required this.backgroundOpacity,
    required this.borderWidth,
    required this.borderRadius,
    required this.priority,
  });

  final SeriesElement element;
  final Offset anchor;
  final TextPainter textPainter;
  final Size boxSize;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final double connectorWidth;
  final double connectorOpacity;
  final double connectorGlow;
  final double backgroundOpacity;
  final double borderWidth;
  final double borderRadius;
  final int priority;
}

/// Paints one shared, collision-aware direct-label lane for Cartesian series.
class SeriesCalloutRenderer {
  const SeriesCalloutRenderer();

  void paint({
    required Canvas canvas,
    required Size plotSize,
    required List<SeriesElement> seriesElements,
    required SeriesCalloutConfig config,
    required ChartTheme theme,
    required double textScaleFactor,
    required TextDirection textDirection,
  }) {
    if (!config.enabled || plotSize.isEmpty) return;
    final resolved = <_ResolvedSeriesCallout>[];
    for (final element in seriesElements) {
      final series = element.series;
      if ((series is! LineChartSeries && series is! AreaChartSeries) ||
          !config.showsSeries(series.id)) {
        continue;
      }
      final spec = config.specFor(series.id);
      final anchor = _resolveAnchor(
        element,
        spec.anchor ?? config.anchor,
        spec.anchorX ?? config.anchorX,
      );
      if (anchor == null ||
          !anchor.dx.isFinite ||
          !anchor.dy.isFinite ||
          anchor.dx < 0 ||
          anchor.dx > plotSize.width ||
          anchor.dy < 0 ||
          anchor.dy > plotSize.height) {
        continue;
      }
      final color = spec.color ?? config.connectorColor ?? element.themeColor;
      final background =
          spec.backgroundColor ??
          config.backgroundColor ??
          theme.backgroundColor.withValues(alpha: 0.92);
      final border =
          spec.borderColor ??
          config.borderColor ??
          color.withValues(alpha: 0.7);
      final fallbackTextColor = background.computeLuminance() > 0.45
          ? Colors.black87
          : Colors.white;
      final style = config.labelStyle
          .copyWith(
            color: config.labelStyle.color ?? fallbackTextColor,
            fontFamily:
                config.labelStyle.fontFamily ??
                theme.typographyTheme.fontFamily,
          )
          .merge(spec.textStyle);
      final painter =
          TextPainter(
            text: TextSpan(
              text: spec.label ?? series.displayName,
              style: style,
            ),
            textDirection: textDirection,
            textScaler: TextScaler.linear(textScaleFactor),
            maxLines: 2,
            ellipsis: '…',
          )..layout(
            maxWidth: math.max(
              1,
              config.laneWidth - config.labelPadding.horizontal,
            ),
          );
      resolved.add(
        _ResolvedSeriesCallout(
          element: element,
          anchor: anchor,
          textPainter: painter,
          boxSize: Size(
            painter.width + config.labelPadding.horizontal,
            painter.height + config.labelPadding.vertical,
          ),
          color: color,
          backgroundColor: background,
          borderColor: border,
          connectorWidth: spec.connectorWidth ?? config.connectorWidth,
          connectorOpacity: spec.connectorOpacity ?? config.connectorOpacity,
          connectorGlow: spec.connectorGlow ?? config.connectorGlow,
          backgroundOpacity: spec.backgroundOpacity ?? config.backgroundOpacity,
          borderWidth: spec.borderWidth ?? config.borderWidth,
          borderRadius: spec.borderRadius ?? config.borderRadius,
          priority: spec.priority,
        ),
      );
    }
    if (resolved.isEmpty) return;

    final layout = layoutSeriesCallouts(
      candidates: [
        for (final callout in resolved)
          SeriesCalloutLayoutCandidate(
            id: callout.element.series.id,
            desiredCenterY: callout.anchor.dy,
            size: callout.boxSize,
            priority: callout.priority,
          ),
      ],
      minimumY: config.inset,
      maximumY: plotSize.height - config.inset,
      gap: config.minimumGap,
      maximumVisible: config.maximumVisible,
      packing: config.packing,
    );
    final calloutById = {
      for (final callout in resolved) callout.element.series.id: callout,
    };
    final boxesById = <String, Rect>{};
    for (final position in layout) {
      final callout = calloutById[position.id]!;
      final boxLeft = config.side == SeriesCalloutSide.right
          ? plotSize.width - config.inset - callout.boxSize.width
          : config.inset;
      boxesById[position.id] = Rect.fromLTWH(
        boxLeft,
        position.top,
        callout.boxSize.width,
        callout.boxSize.height,
      );
    }
    _paintLanePanel(canvas, plotSize, config, boxesById.values.toList());
    for (final position in layout) {
      final callout = calloutById[position.id]!;
      final box = boxesById[position.id]!;
      final target = Offset(
        config.side == SeriesCalloutSide.right ? box.left : box.right,
        box.center.dy,
      );
      final connectorPaint = Paint()
        ..color = callout.color.withValues(
          alpha: callout.color.a * callout.connectorOpacity,
        )
        ..strokeWidth = callout.connectorWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final connectorPath = Path()
        ..moveTo(callout.anchor.dx, callout.anchor.dy);
      if (config.connector == SeriesCalloutConnector.elbow) {
        final elbowX = config.side == SeriesCalloutSide.right
            ? math.max(callout.anchor.dx, target.dx - 16)
            : math.min(callout.anchor.dx, target.dx + 16);
        connectorPath
          ..lineTo(elbowX, callout.anchor.dy)
          ..lineTo(target.dx, target.dy);
      } else {
        connectorPath.lineTo(target.dx, target.dy);
      }
      if (callout.connectorGlow > 0 && callout.connectorOpacity > 0) {
        canvas.drawPath(
          connectorPath,
          Paint()
            ..color = callout.color.withValues(
              alpha: callout.color.a * callout.connectorOpacity * 0.35,
            )
            ..strokeWidth = callout.connectorWidth + callout.connectorGlow * 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              callout.connectorGlow,
            ),
        );
      }
      canvas.drawPath(connectorPath, connectorPaint);
      if (config.anchorRadius > 0) {
        canvas.drawCircle(
          callout.anchor,
          config.anchorRadius,
          Paint()
            ..color = callout.color.withValues(
              alpha: callout.color.a * callout.connectorOpacity,
            ),
        );
      }
      final radius = Radius.circular(callout.borderRadius);
      final roundedBox = RRect.fromRectAndRadius(box, radius);
      canvas.drawRRect(
        roundedBox,
        Paint()
          ..color = callout.backgroundColor.withValues(
            alpha: callout.backgroundColor.a * callout.backgroundOpacity,
          )
          ..style = PaintingStyle.fill,
      );
      if (callout.borderWidth > 0) {
        canvas.drawRRect(
          roundedBox,
          Paint()
            ..color = callout.borderColor
            ..strokeWidth = callout.borderWidth
            ..style = PaintingStyle.stroke,
        );
      }
      callout.textPainter.paint(
        canvas,
        Offset(
          box.left + config.labelPadding.left,
          box.top + config.labelPadding.top,
        ),
      );
    }
  }

  void _paintLanePanel(
    Canvas canvas,
    Size plotSize,
    SeriesCalloutConfig config,
    List<Rect> labelRects,
  ) {
    final bounds = resolveSeriesCalloutPanelRect(
      labelRects: labelRects,
      plotBounds: Offset.zero & plotSize,
      padding: config.panelPadding,
    );
    if (bounds == null) return;
    final panel = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(config.panelBorderRadius),
    );
    final fill = config.panelBackgroundColor;
    if (fill != null && config.panelOpacity > 0) {
      canvas.drawRRect(
        panel,
        Paint()
          ..color = fill.withValues(alpha: fill.a * config.panelOpacity)
          ..style = PaintingStyle.fill,
      );
    }
    final border = config.panelBorderColor;
    if (border != null && config.panelBorderWidth > 0) {
      canvas.drawRRect(
        panel,
        Paint()
          ..color = border
          ..strokeWidth = config.panelBorderWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Offset? _resolveAnchor(
    SeriesElement element,
    SeriesCalloutAnchor strategy,
    double? anchorX,
  ) {
    final transform = element.currentTransform;
    final visible = element.series.points
        .where(
          (point) =>
              point.isValid &&
              point.x >= transform.dataXMin &&
              point.x <= transform.dataXMax,
        )
        .toList(growable: false);
    if (visible.isEmpty) return null;
    ChartDataPoint point;
    switch (strategy) {
      case SeriesCalloutAnchor.firstVisible:
        point = visible.reduce((a, b) => a.x <= b.x ? a : b);
      case SeriesCalloutAnchor.lastVisible:
        point = visible.reduce((a, b) => a.x >= b.x ? a : b);
      case SeriesCalloutAnchor.maximumVisible:
        point = visible.reduce((a, b) => a.y >= b.y ? a : b);
      case SeriesCalloutAnchor.minimumVisible:
        point = visible.reduce((a, b) => a.y <= b.y ? a : b);
      case SeriesCalloutAnchor.xValue:
        final x = anchorX;
        if (x == null || !x.isFinite) return null;
        final interpolated = _interpolateAtX(element.series.points, x);
        if (interpolated == null) return null;
        return element.dataToCurrentPlot(x, interpolated);
    }
    return element.dataToCurrentPlot(point.x, point.y);
  }

  double? _interpolateAtX(List<ChartDataPoint> points, double x) {
    ChartDataPoint? nearest;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (!point.isValid) continue;
      if (point.x == x) return point.y;
      if (nearest == null || (point.x - x).abs() < (nearest.x - x).abs()) {
        nearest = point;
      }
      if (index == 0) continue;
      final previous = points[index - 1];
      if (!previous.isValid || point.x == previous.x) continue;
      final low = math.min(previous.x, point.x);
      final high = math.max(previous.x, point.x);
      if (x < low || x > high) continue;
      final t = (x - previous.x) / (point.x - previous.x);
      return previous.y + (point.y - previous.y) * t;
    }
    return nearest?.y;
  }
}
