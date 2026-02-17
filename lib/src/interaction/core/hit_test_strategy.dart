// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

/// Base interface for hit-testing strategies.
///
/// **Purpose**: Provide flexible, configurable hit-testing for different element types.
///
/// **Architecture**: Strategy pattern allows each element type to use the appropriate
/// geometric hit-test algorithm (point, line, rectangle, etc.) while maintaining
/// a consistent interface.
///
/// **Usage**:
/// ```dart
/// class MyElement extends ChartElement {
///   @override
///   bool hitTest(Offset position) {
///     return PointHitStrategy(center: center, radius: 10.0).test(position);
///   }
/// }
/// ```
abstract class HitTestStrategy {
  /// Tests if the given position hits this element.
  bool test(Offset position);

  /// Returns the distance from position to the element.
  ///
  /// Used for priority sorting when multiple elements overlap.
  /// Returns null if distance calculation is not applicable for this strategy.
  double? distanceTo(Offset position);
}

/// Hit-testing strategy for point-like elements (datapoints, markers).
///
/// Uses circular hit-zone based on distance from center point.
class PointHitStrategy implements HitTestStrategy {
  const PointHitStrategy({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  bool test(Offset position) {
    return (position - center).distance <= radius;
  }

  @override
  double? distanceTo(Offset position) {
    return (position - center).distance;
  }
}

/// Hit-testing strategy for line/path elements (series, trend lines).
///
/// Uses distance-to-line-segment algorithm with configurable tolerance.
class LineHitStrategy implements HitTestStrategy {
  const LineHitStrategy({required this.points, required this.tolerance});

  final List<Offset> points;
  final double tolerance;

  @override
  bool test(Offset position) {
    if (points.length < 2) return false;

    // Check distance to each line segment
    double minDistance = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final distance = _distanceToLineSegment(position, p1, p2);
      if (distance < minDistance) {
        minDistance = distance;
      }

      if (distance <= tolerance) {
        return true;
      }
    }

    return false;
  }

  @override
  double? distanceTo(Offset position) {
    if (points.length < 2) return null;

    double minDistance = double.infinity;

    for (int i = 0; i < points.length - 1; i++) {
      final distance = _distanceToLineSegment(
        position,
        points[i],
        points[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Calculates distance from a point to a line segment.
  double _distanceToLineSegment(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;

    if (dx == 0 && dy == 0) {
      // Segment is a point
      return (point - segStart).distance;
    }

    // Parameter t represents position along segment (0 = start, 1 = end)
    final t =
        ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) /
        (dx * dx + dy * dy);

    // Clamp t to [0, 1] to stay on segment
    final tClamped = t.clamp(0.0, 1.0);

    // Find closest point on segment
    final closest = Offset(
      segStart.dx + tClamped * dx,
      segStart.dy + tClamped * dy,
    );

    return (point - closest).distance;
  }
}

/// Hit-testing strategy for rectangular elements with configurable zones.
///
/// Supports separate hit-zones for edges, body, and future extensions (labels, etc.).
/// This is the most complex strategy, designed for annotations and range elements.
class RectangleHitStrategy implements HitTestStrategy {
  const RectangleHitStrategy({
    required this.bounds,
    required this.edgeWidth,
    this.enabledZones = const {HitZone.body, HitZone.edges},
  });

  final Rect bounds;
  final double edgeWidth;
  final Set<HitZone> enabledZones;

  @override
  bool test(Offset position) {
    // Check edges first (higher priority for resize operations)
    if (enabledZones.contains(HitZone.edges)) {
      if (isOnEdge(position)) return true;
    }

    // Check body (interior area)
    // If BOTH edges and body are enabled, body includes the entire interior
    // If ONLY body is enabled, it might exclude edges (depending on use case)
    if (enabledZones.contains(HitZone.body)) {
      if (bounds.contains(position)) return true;
    }

    return false;
  }

  @override
  double? distanceTo(Offset position) {
    // For rectangles, use distance to center
    return (position - bounds.center).distance;
  }

  /// Checks if position is within edge zone (for resize operations).
  ///
  /// Edge zone extends BOTH inside and outside the rectangle bounds,
  /// creating a `2 * edgeWidth` wide band (edgeWidth pixels on each side of the edge).
  /// This ensures edges are easy to grab from both inside and outside.
  bool isOnEdge(Offset position) {
    // Expand bounds outward by edgeWidth to allow hits outside rectangle
    final expandedBounds = bounds.inflate(edgeWidth);

    // Must be within expanded bounds
    if (!expandedBounds.contains(position)) {
      return false;
    }

    // Calculate perpendicular distances from each edge
    final distFromLeft =
        position.dx - bounds.left; // Positive when inside/right of left edge
    final distFromRight =
        bounds.right - position.dx; // Positive when inside/left of right edge
    final distFromTop =
        position.dy - bounds.top; // Positive when inside/below top edge
    final distFromBottom =
        bounds.bottom - position.dy; // Positive when inside/above bottom edge

    // Position is on edge if it's within edgeWidth of ANY edge
    // This creates a band around the perimeter
    // FIX: Use <= instead of < to include the exact boundary
    final nearLeft = distFromLeft >= -edgeWidth && distFromLeft <= edgeWidth;
    final nearRight = distFromRight >= -edgeWidth && distFromRight <= edgeWidth;
    final nearTop = distFromTop >= -edgeWidth && distFromTop <= edgeWidth;
    final nearBottom =
        distFromBottom >= -edgeWidth && distFromBottom <= edgeWidth;

    return nearLeft || nearRight || nearTop || nearBottom;
  }

  /// Checks if position is in body zone (interior, excluding edges).
  bool isInBody(Offset position) {
    // Interior area excluding edge zones
    final interior = bounds.deflate(edgeWidth);
    return interior.contains(position);
  }

  /// Determines which specific zone was hit.
  ///
  /// Returns the most specific zone that was hit, with priority:
  /// 1. Edges (for resize)
  /// 2. Body (for drag)
  HitZone? getHitZone(Offset position) {
    if (!bounds.contains(position)) return null;

    if (enabledZones.contains(HitZone.edges) && isOnEdge(position)) {
      return HitZone.edges;
    }

    if (enabledZones.contains(HitZone.body) && isInBody(position)) {
      return HitZone.body;
    }

    return null;
  }

  /// Determines which edge or corner was hit (for resize operations).
  ///
  /// Returns null if not on an edge. This provides fine-grained information
  /// for determining resize direction.
  ResizeDirection? getResizeDirection(Offset position) {
    if (!isOnEdge(position)) return null;

    final left = bounds.left;
    final right = bounds.right;
    final top = bounds.top;
    final bottom = bounds.bottom;

    // Calculate perpendicular distances (same logic as isOnEdge)
    final distFromLeft = position.dx - left;
    final distFromRight = right - position.dx;
    final distFromTop = position.dy - top;
    final distFromBottom = bottom - position.dy;

    final isNearLeft = distFromLeft >= -edgeWidth && distFromLeft < edgeWidth;
    final isNearRight =
        distFromRight >= -edgeWidth && distFromRight < edgeWidth;
    final isNearTop = distFromTop >= -edgeWidth && distFromTop < edgeWidth;
    final isNearBottom =
        distFromBottom >= -edgeWidth && distFromBottom < edgeWidth;

    // Corners take precedence (smaller hit-zones, more specific)
    if (isNearTop && isNearLeft) return ResizeDirection.topLeft;
    if (isNearTop && isNearRight) return ResizeDirection.topRight;
    if (isNearBottom && isNearLeft) return ResizeDirection.bottomLeft;
    if (isNearBottom && isNearRight) return ResizeDirection.bottomRight;

    // Edges
    if (isNearTop) return ResizeDirection.top;
    if (isNearRight) return ResizeDirection.right;
    if (isNearBottom) return ResizeDirection.bottom;
    if (isNearLeft) return ResizeDirection.left;

    return null;
  }
}

/// Hit-zone types for rectangular elements.
///
/// Defines different regions within a rectangle that can be independently
/// enabled/disabled for hit-testing.
enum HitZone {
  /// Edge zones (for resize operations).
  /// Continuous band around rectangle perimeter.
  edges,

  /// Body/interior zone (for drag/select operations).
  /// Central area excluding edges.
  body,

  /// Label/title zone (future enhancement).
  /// Specific region for text/labels within annotation.
  label,

  /// Corner handles (future enhancement).
  /// More specific than edges, only at exact corner positions.
  corners,
}

/// Resize direction for edge/corner drag operations.
///
/// Used by RectangleHitStrategy to determine which edge or corner
/// was grabbed for resizing.
enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  right,
  bottom,
  left,
}
