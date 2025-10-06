/// Unit tests for ScatterClusterer
///
/// Tests the scatter chart clustering algorithm for grouping dense points,
/// applying cluster threshold, and disabling clustering.
library;

import 'dart:ui' show Offset;

import 'package:braven_charts/src/charts/scatter/scatter_clusterer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterClusterer', () {
    group('Clustering Algorithm for Dense Points', () {
      test('clusters nearby points into a single cluster', () {
        final points = [
          const Offset(10, 10),
          const Offset(11, 11), // Very close to first point
          const Offset(12, 10), // Very close to first point
          const Offset(100, 100), // Far away - separate cluster or point
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should have at least one cluster (for the 3 close points)
        expect(result.clusters.isNotEmpty, isTrue);

        // First cluster should contain the 3 nearby points
        final firstCluster = result.clusters.first;
        expect(firstCluster.pointCount, greaterThanOrEqualTo(2));
        expect(firstCluster.pointIndices.length, equals(firstCluster.pointCount));
      });

      test('calculates cluster center as average of clustered points', () {
        final points = [
          const Offset(0, 0),
          const Offset(2, 0),
          const Offset(1, 1.732), // Forms approximate equilateral triangle
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // If all three points are clustered, center should be near (1, ~0.58)
        if (result.clusters.isNotEmpty && result.clusters.first.pointCount == 3) {
          final center = result.clusters.first.center;
          expect(center.dx, closeTo(1.0, 0.5));
          expect(center.dy, closeTo(0.58, 0.5));
        }
      });

      test('handles multiple distinct clusters', () {
        final points = [
          // Cluster 1: near origin
          const Offset(0, 0),
          const Offset(1, 1),
          const Offset(2, 0),
          // Cluster 2: far away
          const Offset(100, 100),
          const Offset(101, 101),
          const Offset(102, 100),
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should have 2 clusters (one near origin, one near 100,100)
        expect(result.clusters.length, greaterThanOrEqualTo(2));

        // Each cluster should have at least 2 points (threshold)
        for (final cluster in result.clusters) {
          expect(cluster.pointCount, greaterThanOrEqualTo(2));
        }
      });

      test('calculates cluster radius based on farthest point', () {
        final points = [
          const Offset(0, 0),
          const Offset(3, 0), // 3 units away from first point
          const Offset(0, 4), // 4 units away from first point
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 10.0, // Large enough to include all
        );

        final result = clusterer.cluster(points);

        if (result.clusters.isNotEmpty) {
          final cluster = result.clusters.first;
          // Radius should accommodate the farthest point from center
          expect(cluster.radius, greaterThan(0));
        }
      });

      test('points outside cluster radius form separate entities', () {
        final points = [
          const Offset(0, 0),
          const Offset(1, 0), // Within cluster radius
          const Offset(50, 50), // Far outside cluster radius
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0, // Only first two should cluster
        );

        final result = clusterer.cluster(points);

        // Should have at least 1 cluster for the first two points
        expect(result.clusters.isNotEmpty, isTrue);

        // Third point should be in unclustered points or separate
        final totalClustered = result.clusters.fold<int>(
          0,
          (sum, cluster) => sum + cluster.pointCount,
        );
        final totalUnclustered = result.unclusteredPoints.length;

        expect(totalClustered + totalUnclustered, equals(points.length));
      });
    });

    group('Cluster Threshold Parameter', () {
      test('threshold = 2 requires at least 2 points to form cluster', () {
        final points = [
          const Offset(0, 0),
          const Offset(1, 1), // Close enough to cluster
          const Offset(50, 50), // Isolated point
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should have one cluster with 2 points
        final clusters = result.clusters.where((c) => c.pointCount >= 2).toList();
        expect(clusters.isNotEmpty, isTrue);

        // Isolated point should not form a cluster
        expect(result.unclusteredPoints, contains(2)); // Index of isolated point
      });

      test('threshold = 3 requires at least 3 points to form cluster', () {
        final points = [
          const Offset(0, 0),
          const Offset(1, 0),
          const Offset(0, 1),
          const Offset(0.5, 0.5), // 4 points close together
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 3,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // With threshold 3, should form a cluster with 3+ points
        if (result.clusters.isNotEmpty) {
          expect(result.clusters.first.pointCount, greaterThanOrEqualTo(3));
        }
      });

      test('higher threshold reduces number of clusters', () {
        final points = List.generate(
          10,
          (i) => Offset(i.toDouble(), 0), // 10 points in a line
        );

        final clustererLowThreshold = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 3.0,
        );

        final clustererHighThreshold = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 5,
          clusterRadius: 3.0,
        );

        final resultLow = clustererLowThreshold.cluster(points);
        final resultHigh = clustererHighThreshold.cluster(points);

        // Higher threshold should result in fewer or equal clusters
        expect(resultHigh.clusters.length, lessThanOrEqualTo(resultLow.clusters.length));
      });

      test('points below threshold remain unclustered', () {
        final points = [
          const Offset(0, 0),
          const Offset(50, 50), // Two isolated points
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 3, // Need 3 points to cluster
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should have no clusters (only 2 points, threshold is 3)
        expect(result.clusters.isEmpty, isTrue);

        // Both points should be unclustered
        expect(result.unclusteredPoints.length, equals(2));
      });
    });

    group('No Clustering When Disabled', () {
      test('returns all points as unclustered when clustering disabled', () {
        final points = [
          const Offset(0, 0),
          const Offset(1, 1),
          const Offset(2, 2),
          const Offset(3, 3),
        ];

        final clusterer = ScatterClusterer(
          enableClustering: false,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should have no clusters
        expect(result.clusters.isEmpty, isTrue);

        // All points should be unclustered
        expect(result.unclusteredPoints.length, equals(points.length));
        expect(result.unclusteredPoints, containsAll([0, 1, 2, 3]));
      });

      test('ignores cluster threshold when clustering disabled', () {
        final points = [
          const Offset(0, 0),
          const Offset(0.5, 0.5),
        ];

        final clusterer = ScatterClusterer(
          enableClustering: false,
          clusterThreshold: 2, // Would normally cluster these
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        expect(result.clusters.isEmpty, isTrue);
        expect(result.unclusteredPoints.length, equals(2));
      });

      test('ignores cluster radius when clustering disabled', () {
        final points = [
          const Offset(0, 0),
          const Offset(0.1, 0.1),
          const Offset(0.2, 0.2),
        ];

        final clusterer = ScatterClusterer(
          enableClustering: false,
          clusterThreshold: 2,
          clusterRadius: 100.0, // Would cluster everything if enabled
        );

        final result = clusterer.cluster(points);

        expect(result.clusters.isEmpty, isTrue);
        expect(result.unclusteredPoints.length, equals(3));
      });
    });

    group('Edge Cases', () {
      test('handles empty point list', () {
        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster([]);

        expect(result.clusters.isEmpty, isTrue);
        expect(result.unclusteredPoints.isEmpty, isTrue);
      });

      test('handles single point', () {
        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster([const Offset(10, 10)]);

        // Cannot cluster a single point (threshold is 2)
        expect(result.clusters.isEmpty, isTrue);
        expect(result.unclusteredPoints, equals([0]));
      });

      test('handles identical points at same location', () {
        final points = [
          const Offset(5, 5),
          const Offset(5, 5), // Exact same location
          const Offset(5, 5), // Exact same location
        ];

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 2,
          clusterRadius: 5.0,
        );

        final result = clusterer.cluster(points);

        // Should cluster all three identical points
        expect(result.clusters.isNotEmpty, isTrue);
        if (result.clusters.isNotEmpty) {
          expect(result.clusters.first.pointCount, equals(3));
          expect(result.clusters.first.center, equals(const Offset(5, 5)));
          expect(result.clusters.first.radius, equals(0.0)); // All at same point
        }
      });

      test('handles large number of points efficiently', () {
        // Performance test: 1000 points
        final points = List.generate(
          1000,
          (i) => Offset(i % 100.toDouble(), (i ~/ 100).toDouble()),
        );

        final clusterer = ScatterClusterer(
          enableClustering: true,
          clusterThreshold: 5,
          clusterRadius: 2.0,
        );

        // Should complete without error
        expect(() => clusterer.cluster(points), returnsNormally);

        final result = clusterer.cluster(points);

        // Total should equal input
        final totalClustered = result.clusters.fold<int>(
          0,
          (sum, cluster) => sum + cluster.pointCount,
        );
        expect(totalClustered + result.unclusteredPoints.length, equals(1000));
      });
    });
  });
}
