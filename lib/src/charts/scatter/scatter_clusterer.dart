/// Scatter chart clustering utilities
library;

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
