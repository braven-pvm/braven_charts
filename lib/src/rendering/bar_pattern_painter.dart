// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/painting.dart';

import '../models/bar_chart_style.dart';

/// Paints portable bar patterns inside canonical rounded geometry.
abstract final class BarPatternPainter {
  static void paint({
    required Canvas canvas,
    required RRect clip,
    required BarPatternStyle style,
    required Color baseColor,
    double opacityMultiplier = 1.0,
  }) {
    if (clip.isEmpty || style.opacity <= 0 || opacityMultiplier <= 0) return;
    final rect = clip.outerRect;
    final patternColor =
        style.color ??
        (baseColor.computeLuminance() > 0.45
            ? const Color(0xFF111827)
            : const Color(0xFFFFFFFF));
    final paint = Paint()
      ..color = patternColor.withValues(
        alpha: (style.opacity * opacityMultiplier).clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth
      ..strokeCap = StrokeCap.square;

    canvas.save();
    canvas.clipRRect(clip, doAntiAlias: true);
    switch (style.pattern) {
      case BarFillPattern.diagonalUp:
        _paintDiagonal(canvas, rect, paint, style.spacing, rising: true);
      case BarFillPattern.diagonalDown:
        _paintDiagonal(canvas, rect, paint, style.spacing, rising: false);
      case BarFillPattern.crosshatch:
        _paintDiagonal(canvas, rect, paint, style.spacing, rising: true);
        _paintDiagonal(canvas, rect, paint, style.spacing, rising: false);
      case BarFillPattern.horizontal:
        for (
          var y = rect.top + style.spacing;
          y < rect.bottom;
          y += style.spacing
        ) {
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
        }
      case BarFillPattern.vertical:
        for (
          var x = rect.left + style.spacing;
          x < rect.right;
          x += style.spacing
        ) {
          canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
        }
    }
    canvas.restore();
  }

  static void _paintDiagonal(
    Canvas canvas,
    Rect rect,
    Paint paint,
    double spacing, {
    required bool rising,
  }) {
    final height = rect.height;
    for (var x = rect.left - height + spacing; x < rect.right; x += spacing) {
      canvas.drawLine(
        rising ? Offset(x, rect.bottom) : Offset(x, rect.top),
        rising ? Offset(x + height, rect.top) : Offset(x + height, rect.bottom),
        paint,
      );
    }
  }
}
