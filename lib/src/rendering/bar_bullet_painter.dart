// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../models/bar_chart_style.dart';
import 'bar_geometry.dart';

/// Paints the passive qualitative ranges behind a bullet-chart measure.
///
/// The outermost range defines one clipped frame. Ranges are then painted from
/// largest to smallest so internal thresholds remain square and easy to scan,
/// while only the complete background receives rounded corners.
abstract final class BarBulletPainter {
  static void paint({
    required Canvas canvas,
    required BarGeometry geometry,
    required ChartTransform transform,
    required BarBulletStyle style,
  }) {
    final frame = geometry.bulletRect;
    final frameRRect = geometry.bulletRRect;
    if (style.ranges.isEmpty || frame == null || frameRRect == null) return;

    final effectiveTransform = transform.copyWith(
      transposed: geometry.orientation == BarOrientation.horizontal,
    );
    canvas.save();
    canvas.clipRRect(frameRRect);
    for (final range in style.ranges.reversed) {
      final endPosition = effectiveTransform.dataToPlot(
        geometry.point.x,
        range.endValue,
      );
      final rect = geometry.orientation == BarOrientation.horizontal
          ? Rect.fromLTRB(
              math.min(geometry.baselinePosition, endPosition.dx),
              frame.top,
              math.max(geometry.baselinePosition, endPosition.dx),
              frame.bottom,
            )
          : Rect.fromLTRB(
              frame.left,
              math.min(geometry.baselinePosition, endPosition.dy),
              frame.right,
              math.max(geometry.baselinePosition, endPosition.dy),
            );
      canvas.drawRect(rect, Paint()..color = range.color);
    }
    canvas.restore();
  }
}
