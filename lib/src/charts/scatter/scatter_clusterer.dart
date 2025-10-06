/// Scatter chart clustering utilities
library;

import 'dart:math' show sqrt;
import 'dart:ui' show Offset;

/// Represents information about a clustered group of points in a scatter chart.
///
/// Used internally by ScatterClusterer for dense data visualization.
/// When many points are close together, they can be grouped into clusters
/// to improve performance and readability.
class ClusterInfo {
  /// Creates a cluster info.
  const ClusterInfo({
    required this.center,
    required this.pointCount,
    required this.pointIndices,
    required this.radius,
  });

  /// The center position of the cluster.
  final Offset center;

  /// The number of points in this cluster.
  final int pointCount;

  /// The indices of points that belong to this cluster.
  final List<int> pointIndices;

  /// The radius of the cluster (for visual indicator).
  final double radius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClusterInfo &&
        other.center == center &&
        other.pointCount == pointCount &&
        _listEquals(other.pointIndices, pointIndices) &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(
        center,
        pointCount,
        Object.hashAll(pointIndices),
        radius,
      );

  @override
  String toString() {
    return 'ClusterInfo('
        'center: $center, '
        'pointCount: $pointCount, '
        'pointIndices: $pointIndices, '
        'radius: $radius'
        ')';
  }

  /// Helper method to compare two lists for equality.
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Result of clustering operation containing clusters and unclustered points.
class ClusterResult {
  /// Creates a cluster result.
  const ClusterResult({
    required this.clusters,
    required this.unclusteredPoints,
  });

  /// List of detected clusters.
  final List<ClusterInfo> clusters;

  /// Indices of points that were not clustered.
  final List<int> unclusteredPoints;
}

/// Scatter chart clustering algorithm for grouping dense data points.
///
/// Implements a simple distance-based clustering algorithm:
/// - Groups points within a specified radius
/// - Only forms clusters with enough points (threshold)
/// - Can be disabled for sparse data or performance
///
/// Constitutional requirement: Performance optimization
class ScatterClusterer {
  /// Creates a scatter clusterer with configuration.
  const ScatterClusterer({
    required this.enableClustering,
    required this.clusterThreshold,
    required this.clusterRadius,
  });

  /// Whether clustering is enabled.
  final bool enableClustering;

  /// Minimum number of points required to form a cluster.
  final int clusterThreshold;

  /// Maximum distance between points in a cluster.
  final double clusterRadius;

  /// Clusters points based on proximity.
  ///
  /// Algorithm:
  /// 1. If clustering disabled, return all points as unclustered
  /// 2. Find groups of points within clusterRadius of each other
  /// 3. Only form clusters with >= clusterThreshold points
  /// 4. Calculate cluster center and radius
  ///
  /// Returns: ClusterResult with clusters and unclustered point indices
  ClusterResult cluster(List<Offset> points) {
    if (!enableClustering) {
      return ClusterResult(
        clusters: const [],
        unclusteredPoints: List.generate(points.length, (i) => i),
      );
    }

    if (points.isEmpty) {
      return const ClusterResult(clusters: [], unclusteredPoints: []);
    }

    // Track which points have been assigned to clusters
    final clustered = List<bool>.filled(points.length, false);
    final clusters = <ClusterInfo>[];

    // Simple greedy clustering algorithm
    for (int i = 0; i < points.length; i++) {
      if (clustered[i]) continue;

      // Find all points within cluster radius of this point
      final clusterIndices = <int>[i];
      for (int j = i + 1; j < points.length; j++) {
        if (clustered[j]) continue;

        final distance = _distance(points[i], points[j]);
        if (distance <= clusterRadius) {
          clusterIndices.add(j);
        }
      }

      // Only form a cluster if we meet the threshold
      if (clusterIndices.length >= clusterThreshold) {
        // Mark points as clustered
        for (final idx in clusterIndices) {
          clustered[idx] = true;
        }

        // Calculate cluster center
        final center = _calculateCenter(
          clusterIndices.map((idx) => points[idx]).toList(),
        );

        // Calculate cluster radius (farthest point from center)
        final radius = _calculateRadius(
          clusterIndices.map((idx) => points[idx]).toList(),
          center,
        );

        clusters.add(
          ClusterInfo(
            center: center,
            pointCount: clusterIndices.length,
            pointIndices: clusterIndices,
            radius: radius,
          ),
        );
      }
    }

    // Collect unclustered points
    final unclustered = <int>[];
    for (int i = 0; i < points.length; i++) {
      if (!clustered[i]) {
        unclustered.add(i);
      }
    }

    return ClusterResult(
      clusters: clusters,
      unclusteredPoints: unclustered,
    );
  }

  /// Calculates Euclidean distance between two points.
  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculates the center point (average) of a group of points.
  Offset _calculateCenter(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    double sumX = 0;
    double sumY = 0;

    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }

    return Offset(sumX / points.length, sumY / points.length);
  }

  /// Calculates the radius (farthest distance from center).
  double _calculateRadius(List<Offset> points, Offset center) {
    if (points.isEmpty) return 0;

    double maxDistance = 0;

    for (final point in points) {
      final distance = _distance(point, center);
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    return maxDistance;
  }
}
