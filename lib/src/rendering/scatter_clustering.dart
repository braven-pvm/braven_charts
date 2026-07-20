// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../models/chart_data_point.dart';
import '../models/scatter_render_config.dart';
import 'scatter_geometry.dart';

/// One deterministic screen-space aggregation of source observations.
class ScatterClusterGeometry {
  ScatterClusterGeometry({
    required List<int> sourcePointIndices,
    required this.center,
    required this.dataCentroid,
    required this.dataXRange,
    required this.dataYRange,
    required this.radius,
    required this.zoneBounds,
  }) : assert(sourcePointIndices.length >= 2),
       sourcePointIndices = List<int>.unmodifiable(sourcePointIndices);

  /// Source identities retained by this rendered cluster.
  final List<int> sourcePointIndices;

  /// Mean marker center in plot-local logical pixels.
  final Offset center;

  /// Mean source coordinate represented by the cluster.
  final Offset dataCentroid;

  /// Minimum and maximum source X values represented by the cluster.
  final ({double minimum, double maximum}) dataXRange;

  /// Minimum and maximum source Y values represented by the cluster.
  final ({double minimum, double maximum}) dataYRange;

  /// Visible cluster marker radius in logical pixels.
  final double radius;

  /// Plot-local extent occupied by the source markers in this cluster.
  final Rect zoneBounds;

  int get pointCount => sourcePointIndices.length;
  int get representativePointIndex => sourcePointIndices.first;
  Rect get paintBounds => Rect.fromCircle(center: center, radius: radius);
  Rect hitBounds(double hitSlop) =>
      Rect.fromCircle(center: center, radius: radius + math.max(0, hitSlop));
}

/// Result of one viewport-specific clustering pass.
class ScatterClusterLayout {
  const ScatterClusterLayout({
    required this.clusters,
    required this.unclusteredPoints,
    required this.sourcePointCount,
  });

  final List<ScatterClusterGeometry> clusters;
  final List<ScatterPointGeometry> unclusteredPoints;
  final int sourcePointCount;

  int get renderedMarkerCount => clusters.length + unclusteredPoints.length;
  int get clusteredPointCount => clusters.fold(
    0,
    (total, cluster) => total + cluster.sourcePointIndices.length,
  );
}

/// Linear-time deterministic plot-space cluster layout.
///
/// Each visible marker enters exactly one fixed-size cell. Cells are emitted
/// in row-major order, and source identities inside a cell remain in document
/// order. The algorithm therefore performs O(n) candidate work and never
/// compares every point with every other point.
abstract final class ScatterClusterEngine {
  static ScatterClusterLayout layout({
    required List<ScatterPointGeometry> geometries,
    required ScatterClusterConfig config,
  }) {
    if (geometries.isEmpty) {
      return const ScatterClusterLayout(
        clusters: [],
        unclusteredPoints: [],
        sourcePointCount: 0,
      );
    }

    final cells = <(int, int), List<ScatterPointGeometry>>{};
    for (final geometry in geometries) {
      final cell = (
        (geometry.center.dx / config.cellSize).floor(),
        (geometry.center.dy / config.cellSize).floor(),
      );
      cells.putIfAbsent(cell, () => []).add(geometry);
    }

    final orderedCells = cells.keys.toList()
      ..sort((left, right) {
        final row = left.$2.compareTo(right.$2);
        return row != 0 ? row : left.$1.compareTo(right.$1);
      });
    var largestCount = config.minimumPointCount;
    for (final cell in orderedCells) {
      final count = cells[cell]!.length;
      if (count >= config.minimumPointCount && count > largestCount) {
        largestCount = count;
      }
    }

    final clusters = <ScatterClusterGeometry>[];
    final unclustered = <ScatterPointGeometry>[];
    for (final cell in orderedCells) {
      final members = cells[cell]!;
      if (members.length < config.minimumPointCount) {
        unclustered.addAll(members);
        continue;
      }
      var plotX = 0.0;
      var plotY = 0.0;
      var minimumPlotX = double.infinity;
      var maximumPlotX = double.negativeInfinity;
      var minimumPlotY = double.infinity;
      var maximumPlotY = double.negativeInfinity;
      var dataX = 0.0;
      var dataY = 0.0;
      var minimumX = double.infinity;
      var maximumX = double.negativeInfinity;
      var minimumY = double.infinity;
      var maximumY = double.negativeInfinity;
      final indices = <int>[];
      for (final member in members) {
        plotX += member.center.dx;
        plotY += member.center.dy;
        minimumPlotX = math.min(minimumPlotX, member.center.dx);
        maximumPlotX = math.max(maximumPlotX, member.center.dx);
        minimumPlotY = math.min(minimumPlotY, member.center.dy);
        maximumPlotY = math.max(maximumPlotY, member.center.dy);
        dataX += member.point.x;
        dataY += member.point.y;
        minimumX = math.min(minimumX, member.point.x);
        maximumX = math.max(maximumX, member.point.x);
        minimumY = math.min(minimumY, member.point.y);
        maximumY = math.max(maximumY, member.point.y);
        indices.add(member.pointIndex);
      }
      indices.sort();
      final count = members.length;
      final zonePadding = math.min(6.0, config.cellSize * 0.12);
      final normalized = largestCount == config.minimumPointCount
          ? 0.0
          : math.sqrt(
              (count - config.minimumPointCount) /
                  (largestCount - config.minimumPointCount),
            );
      clusters.add(
        ScatterClusterGeometry(
          sourcePointIndices: indices,
          center: Offset(plotX / count, plotY / count),
          dataCentroid: Offset(dataX / count, dataY / count),
          dataXRange: (minimum: minimumX, maximum: maximumX),
          dataYRange: (minimum: minimumY, maximum: maximumY),
          radius:
              config.minimumRadius +
              (config.maximumRadius - config.minimumRadius) * normalized,
          zoneBounds: Rect.fromLTRB(
            minimumPlotX,
            minimumPlotY,
            maximumPlotX,
            maximumPlotY,
          ).inflate(zonePadding),
        ),
      );
    }

    return ScatterClusterLayout(
      clusters: List.unmodifiable(clusters),
      unclusteredPoints: List.unmodifiable(unclustered),
      sourcePointCount: geometries.length,
    );
  }

  /// Synthetic centroid datum used by generic hit and tooltip infrastructure.
  static ChartDataPoint centroidPoint(ScatterClusterGeometry cluster) =>
      ChartDataPoint(
        x: cluster.dataCentroid.dx,
        y: cluster.dataCentroid.dy,
        label: '${cluster.pointCount} observations',
        metadata: {
          'clusterPointCount': cluster.pointCount,
          'clusterXMinimum': cluster.dataXRange.minimum,
          'clusterXMaximum': cluster.dataXRange.maximum,
          'clusterYMinimum': cluster.dataYRange.minimum,
          'clusterYMaximum': cluster.dataYRange.maximum,
        },
      );
}
