import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../theming/components/series_theme.dart';

/// Adds one filled Scatter marker to [path].
///
/// Circle markers use the renderer's `drawPoints` fast path. This helper owns
/// the remaining marker silhouettes so painting and precise hit testing share
/// one geometry definition.
void addScatterMarkerPath(
  Path path, {
  required Offset center,
  required double radius,
  required SeriesMarkerShape shape,
  double? width,
  double? height,
  double rotationRadians = 0,
}) {
  if (radius <= 0 || shape == SeriesMarkerShape.none) return;
  final markerWidth = width ?? radius * 2;
  final markerHeight = height ?? radius * 2;
  if (markerWidth <= 0 || markerHeight <= 0) return;
  final local = Path();
  final halfWidth = markerWidth / 2;
  final halfHeight = markerHeight / 2;
  switch (shape) {
    case SeriesMarkerShape.circle:
      local.addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: markerWidth,
          height: markerHeight,
        ),
      );
      break;
    case SeriesMarkerShape.square:
      local.addRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: markerWidth,
          height: markerHeight,
        ),
      );
      break;
    case SeriesMarkerShape.triangle:
      local
        ..moveTo(0, -halfHeight)
        ..lineTo(halfWidth, halfHeight)
        ..lineTo(-halfWidth, halfHeight)
        ..close();
      break;
    case SeriesMarkerShape.invertedTriangle:
      local
        ..moveTo(-halfWidth, -halfHeight)
        ..lineTo(halfWidth, -halfHeight)
        ..lineTo(0, halfHeight)
        ..close();
      break;
    case SeriesMarkerShape.diamond:
      local
        ..moveTo(0, -halfHeight)
        ..lineTo(halfWidth, 0)
        ..lineTo(0, halfHeight)
        ..lineTo(-halfWidth, 0)
        ..close();
      break;
    case SeriesMarkerShape.star:
      _addStar(local, halfWidth, halfHeight);
      break;
    case SeriesMarkerShape.cross:
      _addCross(local, halfWidth, halfHeight);
      break;
    case SeriesMarkerShape.plus:
      _addPlus(local, halfWidth, halfHeight);
      break;
    case SeriesMarkerShape.none:
      break;
  }
  path.addPath(
    local.transform(_markerTransform(center, rotationRadians)),
    Offset.zero,
  );
}

/// Whether [position] falls inside the visible marker silhouette.
bool scatterMarkerContains({
  required Offset position,
  required Offset center,
  required double radius,
  required SeriesMarkerShape shape,
  double hitSlop = 0,
  double? width,
  double? height,
  double rotationRadians = 0,
}) {
  if (shape == SeriesMarkerShape.none || radius < 0) return false;
  final slop = math.max(0, hitSlop);
  final effectiveWidth = (width ?? radius * 2) + slop * 2;
  final effectiveHeight = (height ?? radius * 2) + slop * 2;
  if (shape == SeriesMarkerShape.circle &&
      effectiveWidth == effectiveHeight &&
      rotationRadians == 0) {
    final effectiveRadius = effectiveWidth / 2;
    return (position - center).distanceSquared <=
        effectiveRadius * effectiveRadius;
  }
  final path = Path();
  addScatterMarkerPath(
    path,
    center: center,
    radius: math.max(effectiveWidth, effectiveHeight) / 2,
    shape: shape,
    width: effectiveWidth,
    height: effectiveHeight,
    rotationRadians: rotationRadians,
  );
  return path.contains(position);
}

Float64List _markerTransform(Offset center, double rotationRadians) {
  final cosine = math.cos(rotationRadians);
  final sine = math.sin(rotationRadians);
  return Float64List.fromList([
    cosine,
    sine,
    0,
    0,
    -sine,
    cosine,
    0,
    0,
    0,
    0,
    1,
    0,
    center.dx,
    center.dy,
    0,
    1,
  ]);
}

void _addStar(Path path, double halfWidth, double halfHeight) {
  const pointCount = 10;
  for (var index = 0; index < pointCount; index++) {
    final angle = -math.pi / 2 + index * math.pi / 5;
    final scale = index.isEven ? 1.0 : 0.42;
    final point = Offset(
      math.cos(angle) * halfWidth * scale,
      math.sin(angle) * halfHeight * scale,
    );
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
}

void _addPlus(Path path, double halfWidth, double halfHeight) {
  final armX = halfWidth * 0.34;
  final armY = halfHeight * 0.34;
  path.addPolygon([
    Offset(-armX, -halfHeight),
    Offset(armX, -halfHeight),
    Offset(armX, -armY),
    Offset(halfWidth, -armY),
    Offset(halfWidth, armY),
    Offset(armX, armY),
    Offset(armX, halfHeight),
    Offset(-armX, halfHeight),
    Offset(-armX, armY),
    Offset(-halfWidth, armY),
    Offset(-halfWidth, -armY),
    Offset(-armX, -armY),
  ], true);
}

void _addCross(Path path, double halfWidth, double halfHeight) {
  final insetX = halfWidth * 0.34;
  final insetY = halfHeight * 0.34;
  path.addPolygon([
    Offset(-halfWidth, -halfHeight + insetY),
    Offset(-halfWidth + insetX, -halfHeight),
    Offset(0, -insetY),
    Offset(halfWidth - insetX, -halfHeight),
    Offset(halfWidth, -halfHeight + insetY),
    Offset(insetX, 0),
    Offset(halfWidth, halfHeight - insetY),
    Offset(halfWidth - insetX, halfHeight),
    Offset(0, insetY),
    Offset(-halfWidth + insetX, halfHeight),
    Offset(-halfWidth, halfHeight - insetY),
    Offset(-insetX, 0),
  ], true);
}
