// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:math' as math;
import 'dart:ui';

import '../models/chart_series.dart';

typedef CoordinateGetter<T> = double Function(T point);

/// Immutable cubic segment representation shared by rendering and tracking.
class CubicSegment {
  const CubicSegment({
    required this.startX,
    required this.startY,
    required this.control1X,
    required this.control1Y,
    required this.control2X,
    required this.control2Y,
    required this.endX,
    required this.endY,
  });

  final double startX;
  final double startY;
  final double control1X;
  final double control1Y;
  final double control2X;
  final double control2Y;
  final double endX;
  final double endY;

  double evaluateX(double t) {
    final omt = 1.0 - t;
    final omt2 = omt * omt;
    final omt3 = omt2 * omt;
    final t2 = t * t;
    final t3 = t2 * t;
    return omt3 * startX +
        3.0 * omt2 * t * control1X +
        3.0 * omt * t2 * control2X +
        t3 * endX;
  }

  double evaluateY(double t) {
    final omt = 1.0 - t;
    final omt2 = omt * omt;
    final omt3 = omt2 * omt;
    final t2 = t * t;
    final t3 = t2 * t;
    return omt3 * startY +
        3.0 * omt2 * t * control1Y +
        3.0 * omt * t2 * control2Y +
        t3 * endY;
  }

  double solveTForX(double targetX) {
    if ((targetX - startX).abs() < 1e-10) return 0.0;
    if ((targetX - endX).abs() < 1e-10) return 1.0;

    double lower = 0.0;
    double upper = 1.0;
    double t;
    final xSpan = endX - startX;
    if (xSpan.abs() < 1e-10) {
      t = 0.0;
    } else {
      t = ((targetX - startX) / xSpan).clamp(0.0, 1.0);
    }

    for (int i = 0; i < 8; i++) {
      final currentX = evaluateX(t);
      final delta = currentX - targetX;
      if (delta.abs() < 1e-8) {
        return t;
      }

      if (delta < 0) {
        lower = t;
      } else {
        upper = t;
      }

      final derivative = _evaluateDerivativeX(t);
      if (derivative.abs() < 1e-10) {
        break;
      }

      final next = t - delta / derivative;
      if (next <= lower || next >= upper) {
        break;
      }
      t = next;
    }

    for (int i = 0; i < 24; i++) {
      final mid = (lower + upper) / 2.0;
      final currentX = evaluateX(mid);
      if ((currentX - targetX).abs() < 1e-8) {
        return mid;
      }
      if (currentX < targetX) {
        lower = mid;
      } else {
        upper = mid;
      }
    }

    return (lower + upper) / 2.0;
  }

  double _evaluateDerivativeX(double t) {
    final omt = 1.0 - t;
    return 3.0 * omt * omt * (control1X - startX) +
        6.0 * omt * t * (control2X - control1X) +
        3.0 * t * t * (endX - control2X);
  }
}

/// Shared interpolation math used by both series rendering and crosshair tracking.
abstract final class InterpolationGeometry {
  static void addPathSegments<T>({
    required Path path,
    required List<T> points,
    required LineInterpolation interpolation,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
    int startIndex = 1,
    int? endIndex,
    double tension = 0.25,
  }) {
    if (points.length < 2) return;

    final lastIndex = points.length - 1;
    final segmentStart = startIndex.clamp(1, lastIndex);
    final segmentEnd = math.min(endIndex ?? lastIndex, lastIndex);
    if (segmentStart > segmentEnd) return;

    for (int i = segmentStart - 1; i < segmentEnd; i++) {
      switch (interpolation) {
        case LineInterpolation.linear:
          path.lineTo(getX(points[i + 1]), getY(points[i + 1]));
          break;
        case LineInterpolation.stepped:
          path.lineTo(getX(points[i + 1]), getY(points[i]));
          path.lineTo(getX(points[i + 1]), getY(points[i + 1]));
          break;
        case LineInterpolation.bezier:
        case LineInterpolation.monotone:
          final segment = cubicSegmentFor(
            points: points,
            startIndex: i,
            interpolation: interpolation,
            getX: getX,
            getY: getY,
            tension: tension,
          );
          if (segment == null) {
            path.lineTo(getX(points[i + 1]), getY(points[i + 1]));
            break;
          }
          path.cubicTo(
            segment.control1X,
            segment.control1Y,
            segment.control2X,
            segment.control2Y,
            segment.endX,
            segment.endY,
          );
          break;
      }
    }
  }

  static CubicSegment? cubicSegmentFor<T>({
    required List<T> points,
    required int startIndex,
    required LineInterpolation interpolation,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
    double tension = 0.25,
  }) {
    if (startIndex < 0 || startIndex >= points.length - 1) {
      return null;
    }

    return switch (interpolation) {
      LineInterpolation.bezier => _bezierSegmentFor(
        points: points,
        startIndex: startIndex,
        getX: getX,
        getY: getY,
        tension: tension,
      ),
      LineInterpolation.monotone => _monotoneSegmentFor(
        points: points,
        startIndex: startIndex,
        getX: getX,
        getY: getY,
      ),
      _ => null,
    };
  }

  static double interpolateYForX<T>({
    required List<T> points,
    required int startIndex,
    required double targetX,
    required LineInterpolation interpolation,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
    double tension = 0.25,
  }) {
    final x1 = getX(points[startIndex]);
    final y1 = getY(points[startIndex]);
    final x2 = getX(points[startIndex + 1]);
    final y2 = getY(points[startIndex + 1]);

    return switch (interpolation) {
      LineInterpolation.linear => _linearInterpolate(x1, y1, x2, y2, targetX),
      LineInterpolation.stepped => y1,
      LineInterpolation.bezier || LineInterpolation.monotone => () {
        final segment = cubicSegmentFor(
          points: points,
          startIndex: startIndex,
          interpolation: interpolation,
          getX: getX,
          getY: getY,
          tension: tension,
        );
        if (segment == null) {
          return _linearInterpolate(x1, y1, x2, y2, targetX);
        }
        final resolvedT = segment.solveTForX(targetX);
        return segment.evaluateY(resolvedT);
      }(),
    };
  }

  static CubicSegment _bezierSegmentFor<T>({
    required List<T> points,
    required int startIndex,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
    required double tension,
  }) {
    final p0 = points[startIndex > 0 ? startIndex - 1 : 0];
    final p1 = points[startIndex];
    final p2 = points[startIndex + 1];
    final p3 =
        points[startIndex + 2 < points.length
            ? startIndex + 2
            : points.length - 1];
    final alpha = tension * 2.0;

    final startX = getX(p1);
    final startY = getY(p1);
    final endX = getX(p2);
    final endY = getY(p2);

    return CubicSegment(
      startX: startX,
      startY: startY,
      control1X: startX + (getX(p2) - getX(p0)) * alpha / 3.0,
      control1Y: startY + (getY(p2) - getY(p0)) * alpha / 3.0,
      control2X: endX - (getX(p3) - startX) * alpha / 3.0,
      control2Y: endY - (getY(p3) - startY) * alpha / 3.0,
      endX: endX,
      endY: endY,
    );
  }

  static CubicSegment? _monotoneSegmentFor<T>({
    required List<T> points,
    required int startIndex,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
  }) {
    final start = points[startIndex];
    final end = points[startIndex + 1];
    final startX = getX(start);
    final endX = getX(end);
    final h = endX - startX;
    if (h.abs() < 1e-10) {
      return null;
    }

    final startY = getY(start);
    final endY = getY(end);
    final startSlope = _monotoneTangentFor(
      points: points,
      index: startIndex,
      getX: getX,
      getY: getY,
    );
    final endSlope = _monotoneTangentFor(
      points: points,
      index: startIndex + 1,
      getX: getX,
      getY: getY,
    );

    return CubicSegment(
      startX: startX,
      startY: startY,
      control1X: startX + h / 3.0,
      control1Y: startY + startSlope * h / 3.0,
      control2X: endX - h / 3.0,
      control2Y: endY - endSlope * h / 3.0,
      endX: endX,
      endY: endY,
    );
  }

  static double _monotoneTangentFor<T>({
    required List<T> points,
    required int index,
    required CoordinateGetter<T> getX,
    required CoordinateGetter<T> getY,
  }) {
    if (points.length < 2) return 0.0;
    if (points.length == 2) {
      return _slope(points, 0, 1, getX, getY);
    }

    if (index <= 0) {
      return _endpointTangent(
        x0: getX(points[0]),
        y0: getY(points[0]),
        x1: getX(points[1]),
        y1: getY(points[1]),
        x2: getX(points[2]),
        y2: getY(points[2]),
      );
    }

    if (index >= points.length - 1) {
      return _endpointTangent(
        x0: getX(points[points.length - 1]),
        y0: getY(points[points.length - 1]),
        x1: getX(points[points.length - 2]),
        y1: getY(points[points.length - 2]),
        x2: getX(points[points.length - 3]),
        y2: getY(points[points.length - 3]),
      );
    }

    final xPrev = getX(points[index - 1]);
    final xCurrent = getX(points[index]);
    final xNext = getX(points[index + 1]);
    final hPrev = xCurrent - xPrev;
    final hNext = xNext - xCurrent;
    if (hPrev.abs() < 1e-10 || hNext.abs() < 1e-10) {
      return 0.0;
    }

    final dPrev = (getY(points[index]) - getY(points[index - 1])) / hPrev;
    final dNext = (getY(points[index + 1]) - getY(points[index])) / hNext;

    if (dPrev.abs() < 1e-10 ||
        dNext.abs() < 1e-10 ||
        dPrev.sign != dNext.sign) {
      return 0.0;
    }

    final w1 = 2.0 * hNext + hPrev;
    final w2 = hNext + 2.0 * hPrev;
    return (w1 + w2) / ((w1 / dPrev) + (w2 / dNext));
  }

  static double _endpointTangent({
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) {
    final h0 = x1 - x0;
    final h1 = x2 - x1;
    if (h0.abs() < 1e-10 || h1.abs() < 1e-10) {
      return 0.0;
    }

    final d0 = (y1 - y0) / h0;
    final d1 = (y2 - y1) / h1;
    final tangent = ((2.0 * h0 + h1) * d0 - h0 * d1) / (h0 + h1);

    if (tangent.sign != d0.sign) {
      return 0.0;
    }
    if (d0.sign != d1.sign && tangent.abs() > 3.0 * d0.abs()) {
      return 3.0 * d0;
    }
    return tangent;
  }

  static double _slope<T>(
    List<T> points,
    int startIndex,
    int endIndex,
    CoordinateGetter<T> getX,
    CoordinateGetter<T> getY,
  ) {
    final dx = getX(points[endIndex]) - getX(points[startIndex]);
    if (dx.abs() < 1e-10) return 0.0;
    return (getY(points[endIndex]) - getY(points[startIndex])) / dx;
  }

  static double _linearInterpolate(
    double x1,
    double y1,
    double x2,
    double y2,
    double targetX,
  ) {
    final dx = x2 - x1;
    if (dx.abs() < 1e-10) {
      return y1;
    }
    final t = (targetX - x1) / dx;
    return y1 + (y2 - y1) * t;
  }
}
