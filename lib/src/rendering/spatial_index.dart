// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import '../interaction/core/chart_element.dart';

/// Spatial index data structure for efficient hit testing.
///
/// **Purpose**: Enable O(log n) hit testing instead of O(n) linear search.
///
/// **Performance** (per INTERACTION_ARCHITECTURE_DESIGN.md):
/// - Insert: O(log n)
/// - Query: O(log n)
/// - Remove: O(log n)
/// - Handles 100+ elements efficiently at 60fps
///
/// **Algorithm**: Quad-tree spatial partitioning
/// - Recursively divides 2D space into quadrants
/// - Each node can hold up to [maxElementsPerNode] elements
/// - When capacity exceeded, node splits into 4 child quadrants
///
/// **Usage**:
/// ```dart
/// final tree = QuadTree(bounds: Rect.fromLTWH(0, 0, 800, 600));
/// tree.insert(element);
/// final hits = tree.query(Offset(100, 100), radius: 10);
/// ```
class QuadTree {
  QuadTree({
    required this.bounds,
    this.maxElementsPerNode = 4,
    this.maxDepth = 8,
    this.depth = 0,
  });

  /// Bounding rectangle for this tree/node.
  final Rect bounds;

  /// Maximum elements per node before splitting.
  final int maxElementsPerNode;

  /// Maximum depth to prevent infinite recursion.
  final int maxDepth;

  /// Current depth of this node (0 = root).
  final int depth;

  /// Elements stored in this node (if not split).
  final List<ChartElement> _elements = [];

  /// Child quadrants (null if not split).
  /// Order: [topLeft, topRight, bottomLeft, bottomRight]
  List<QuadTree>? _children;

  /// Whether this node has been split into child quadrants.
  bool get isSplit => _children != null;

  // ============================================================================
  // Insert
  // ============================================================================

  /// Inserts an element into the tree.
  ///
  /// Returns true if inserted successfully, false if element is outside bounds.
  bool insert(ChartElement element) {
    // Check if element is within this node's bounds
    if (!bounds.overlaps(element.bounds)) {
      return false;
    }

    // If not split and still have capacity, add to this node
    if (!isSplit && _elements.length < maxElementsPerNode) {
      _elements.add(element);
      return true;
    }

    // Split if at capacity and not at max depth
    if (!isSplit && depth < maxDepth) {
      _split();
    }

    // Insert into child quadrants, but keep spanning elements at this level
    // to prevent exponential tree explosion (4^maxDepth node duplication).
    if (isSplit) {
      // Count how many children this element overlaps
      int overlapCount = 0;
      for (final child in _children!) {
        if (child.bounds.overlaps(element.bounds)) {
          overlapCount++;
        }
      }

      // Keep spanning elements (overlap 3+ quadrants) at this node level
      if (overlapCount >= 3) {
        _elements.add(element);
        return true;
      }

      // Push localized elements into overlapping children
      bool inserted = false;
      for (final child in _children!) {
        if (child.bounds.overlaps(element.bounds)) {
          if (child.insert(element)) {
            inserted = true;
          }
        }
      }

      return inserted;
    }

    // At max depth and capacity - add to this node anyway
    _elements.add(element);
    return true;
  }

  /// Splits this node into 4 child quadrants.
  void _split() {
    final halfWidth = bounds.width / 2;
    final halfHeight = bounds.height / 2;
    final x = bounds.left;
    final y = bounds.top;

    _children = [
      // Top-left
      QuadTree(
        bounds: Rect.fromLTWH(x, y, halfWidth, halfHeight),
        maxElementsPerNode: maxElementsPerNode,
        maxDepth: maxDepth,
        depth: depth + 1,
      ),
      // Top-right
      QuadTree(
        bounds: Rect.fromLTWH(x + halfWidth, y, halfWidth, halfHeight),
        maxElementsPerNode: maxElementsPerNode,
        maxDepth: maxDepth,
        depth: depth + 1,
      ),
      // Bottom-left
      QuadTree(
        bounds: Rect.fromLTWH(x, y + halfHeight, halfWidth, halfHeight),
        maxElementsPerNode: maxElementsPerNode,
        maxDepth: maxDepth,
        depth: depth + 1,
      ),
      // Bottom-right
      QuadTree(
        bounds: Rect.fromLTWH(
          x + halfWidth,
          y + halfHeight,
          halfWidth,
          halfHeight,
        ),
        maxElementsPerNode: maxElementsPerNode,
        maxDepth: maxDepth,
        depth: depth + 1,
      ),
    ];

    // Re-insert elements: keep spanning elements at this level to prevent
    // exponential duplication when elements overlap most/all quadrants.
    final spanning = <ChartElement>[];
    for (final element in _elements) {
      int overlapCount = 0;
      for (final child in _children!) {
        if (child.bounds.overlaps(element.bounds)) {
          overlapCount++;
        }
      }
      if (overlapCount >= 3) {
        // Element spans most quadrants - keep at this level
        spanning.add(element);
      } else {
        // Element fits in 1-2 quadrants - push down
        for (final child in _children!) {
          if (child.bounds.overlaps(element.bounds)) {
            child.insert(element);
          }
        }
      }
    }
    _elements.clear();
    _elements.addAll(spanning);
  }

  // ============================================================================
  // Query
  // ============================================================================

  /// Queries for elements at a specific point.
  ///
  /// [position] is the query point in chart coordinates.
  /// [radius] is the search radius (default 0 = exact point).
  ///
  /// Returns all elements whose bounds contain the query region.
  List<ChartElement> query(Offset position, {double radius = 0}) {
    final searchRect = Rect.fromCenter(
      center: position,
      width: radius * 2,
      height: radius * 2,
    );
    return queryRect(searchRect);
  }

  /// Queries for elements within a rectangular region.
  ///
  /// Returns unique elements whose bounds overlap the query rectangle.
  /// Uses identity-based deduplication to handle elements stored in
  /// multiple quadrant nodes (e.g., full-chart-spanning annotations).
  List<ChartElement> queryRect(Rect rect) {
    final results = <ChartElement>{};
    _queryRectInternal(rect, results);
    return results.toList();
  }

  /// Internal recursive query that collects results into a Set for deduplication.
  void _queryRectInternal(Rect rect, Set<ChartElement> results) {
    // Check if query region intersects this node's bounds
    if (!bounds.overlaps(rect)) {
      return;
    }

    // Check elements at this node (leaf elements or spanning elements on split nodes)
    for (final element in _elements) {
      if (element.bounds.overlaps(rect)) {
        results.add(element);
      }
    }

    // If split, also query children
    if (isSplit) {
      for (final child in _children!) {
        child._queryRectInternal(rect, results);
      }
    }
  }

  /// Queries for the nearest element to a point.
  ///
  /// [position] is the query point.
  /// [maxDistance] is the maximum search distance (null = unlimited).
  ///
  /// Returns the nearest element and its distance, or null if none found.
  ///
  /// Per conflict resolution scenario 4: Used for selecting nearest datapoint
  /// when multiple points are close together.
  ({ChartElement element, double distance})? queryNearest(
    Offset position, {
    double? maxDistance,
  }) {
    // Get all elements within search radius
    final searchRadius = maxDistance ?? bounds.width.abs();
    final candidates = query(position, radius: searchRadius);

    if (candidates.isEmpty) return null;

    // Find nearest by Euclidean distance
    ChartElement? nearest;
    double nearestDistance = double.infinity;

    for (final element in candidates) {
      final elementCenter = element.bounds.center;
      final distance = (position - elementCenter).distance;

      if (distance < nearestDistance &&
          (maxDistance == null || distance <= maxDistance)) {
        nearest = element;
        nearestDistance = distance;
      }
    }

    if (nearest == null) return null;
    return (element: nearest, distance: nearestDistance);
  }

  /// Queries for all elements within a distance threshold of a point.
  ///
  /// Per conflict resolution scenario 4: When multiple datapoints are within
  /// 3px of the click, show a picker UI.
  ///
  /// Returns elements sorted by distance (nearest first).
  List<({ChartElement element, double distance})> queryNearby(
    Offset position, {
    required double maxDistance,
  }) {
    final candidates = query(position, radius: maxDistance);
    final results = <({ChartElement element, double distance})>[];

    for (final element in candidates) {
      final elementCenter = element.bounds.center;
      final distance = (position - elementCenter).distance;

      if (distance <= maxDistance) {
        results.add((element: element, distance: distance));
      }
    }

    // Sort by distance (nearest first)
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results;
  }

  // ============================================================================
  // Remove
  // ============================================================================

  /// Removes an element from the tree.
  ///
  /// Returns true if the element was found and removed.
  bool remove(ChartElement element) {
    // Check if element is within this node's bounds
    if (!bounds.overlaps(element.bounds)) {
      return false;
    }

    // Try to remove from this node's elements (leaf or spanning on split nodes)
    if (_elements.remove(element)) {
      return true;
    }

    if (!isSplit) {
      return false;
    }

    // Remove from child quadrants
    bool removed = false;
    for (final child in _children!) {
      if (child.remove(element)) {
        removed = true;
      }
    }

    // Check if we should merge children back (optional optimization)
    if (removed) {
      _tryMerge();
    }

    return removed;
  }

  /// Attempts to merge child quadrants if they're all small enough.
  void _tryMerge() {
    if (!isSplit) return;

    // Count spanning elements at this level plus all children's elements
    int totalElements = _elements.length;
    for (final child in _children!) {
      totalElements += child._countElements();
      if (totalElements > maxElementsPerNode) {
        return; // Too many elements to merge
      }
    }

    // Collect all elements from children into this node
    for (final child in _children!) {
      child._collectElements(_elements);
    }
    _children = null;
  }

  /// Counts total elements in this node and all descendants.
  int _countElements() {
    int count = _elements.length;
    if (isSplit) {
      for (final child in _children!) {
        count += child._countElements();
      }
    }
    return count;
  }

  /// Collects all elements in this node and descendants.
  void _collectElements(List<ChartElement> output) {
    output.addAll(_elements);
    if (isSplit) {
      for (final child in _children!) {
        child._collectElements(output);
      }
    }
  }

  // ============================================================================
  // Clear & Stats
  // ============================================================================

  /// Removes all elements from the tree.
  void clear() {
    _elements.clear();
    _children = null;
  }

  /// Returns the total number of elements in the tree.
  int get elementCount => _countElements();

  /// Returns statistics about the tree structure.
  QuadTreeStats get stats {
    int nodeCount = 0;
    int leafCount = 0;
    int maxDepthReached = depth;
    int totalElements = 0;

    void traverse(QuadTree node) {
      nodeCount++;
      totalElements += node._elements.length;
      if (!node.isSplit) {
        leafCount++;
        if (node.depth > maxDepthReached) {
          maxDepthReached = node.depth;
        }
      } else {
        for (final child in node._children!) {
          traverse(child);
        }
      }
    }

    traverse(this);

    return QuadTreeStats(
      nodeCount: nodeCount,
      leafCount: leafCount,
      maxDepth: maxDepthReached,
      elementCount: totalElements,
    );
  }

  /// Returns a debug string representation of the tree.
  String debugString([int indent = 0]) {
    final buffer = StringBuffer();
    final prefix = '  ' * indent;

    buffer.writeln(
      '${prefix}QuadTree(depth=$depth, elements=${_elements.length}, bounds=$bounds)',
    );

    if (isSplit) {
      for (int i = 0; i < _children!.length; i++) {
        final quadrant = ['TL', 'TR', 'BL', 'BR'][i];
        buffer.write('$prefix  [$quadrant] ');
        buffer.write(_children![i].debugString(indent + 2));
      }
    }

    return buffer.toString();
  }
}

/// Statistics about a QuadTree structure.
class QuadTreeStats {
  const QuadTreeStats({
    required this.nodeCount,
    required this.leafCount,
    required this.maxDepth,
    required this.elementCount,
  });

  /// Total number of nodes (including internal and leaf nodes).
  final int nodeCount;

  /// Number of leaf nodes (nodes with elements).
  final int leafCount;

  /// Maximum depth reached in the tree.
  final int maxDepth;

  /// Total number of elements stored.
  final int elementCount;

  @override
  String toString() {
    return 'QuadTreeStats(nodes: $nodeCount, leaves: $leafCount, '
        'maxDepth: $maxDepth, elements: $elementCount)';
  }
}
