import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/scatter_clustering.dart';
import 'package:braven_charts/src/rendering/scatter_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterClusterEngine', () {
    test('aggregates fixed plot-space cells in deterministic order', () {
      final geometries = [
        _geometry(4, const Offset(82, 8), 8.2, 0.8),
        _geometry(0, const Offset(4, 6), 0.4, 0.6),
        _geometry(3, const Offset(85, 5), 8.5, 0.5),
        _geometry(1, const Offset(8, 10), 0.8, 1.0),
        _geometry(2, const Offset(12, 8), 1.2, 0.8),
        _geometry(5, const Offset(160, 90), 16, 9),
      ];

      final layout = ScatterClusterEngine.layout(
        geometries: geometries,
        config: const ScatterClusterConfig(
          cellSize: 40,
          minimumPointCount: 2,
          minimumRadius: 8,
          maximumRadius: 20,
        ),
      );

      expect(layout.sourcePointCount, 6);
      expect(layout.renderedMarkerCount, 3);
      expect(layout.clusteredPointCount, 5);
      expect(layout.clusters, hasLength(2));
      expect(layout.clusters[0].sourcePointIndices, [0, 1, 2]);
      expect(layout.clusters[1].sourcePointIndices, [3, 4]);
      expect(layout.unclusteredPoints.single.pointIndex, 5);
      expect(layout.clusters[0].center, const Offset(8, 8));
      expect(layout.clusters[0].dataCentroid.dx, closeTo(0.8, 1e-12));
      expect(layout.clusters[0].dataCentroid.dy, closeTo(0.8, 1e-12));
      expect(layout.clusters[0].dataXRange, (minimum: 0.4, maximum: 1.2));
      expect(layout.clusters[0].radius, 20);
      expect(layout.clusters[1].radius, 8);
    });

    test('never merges points across a screen-space cell boundary', () {
      final layout = ScatterClusterEngine.layout(
        geometries: [
          _geometry(0, const Offset(39.9, 20), 0, 0),
          _geometry(1, const Offset(40.1, 20), 1, 1),
        ],
        config: const ScatterClusterConfig(cellSize: 40),
      );

      expect(layout.clusters, isEmpty);
      expect(layout.unclusteredPoints, hasLength(2));
    });

    test('retains complete source identity and centroid metadata', () {
      final cluster = ScatterClusterEngine.layout(
        geometries: [
          _geometry(7, const Offset(8, 8), 4, 10),
          _geometry(2, const Offset(10, 10), 8, 20),
        ],
        config: const ScatterClusterConfig(cellSize: 40),
      ).clusters.single;

      final point = ScatterClusterEngine.centroidPoint(cluster);
      expect(cluster.sourcePointIndices, [2, 7]);
      expect(point.x, 6);
      expect(point.y, 15);
      expect(point.metadata?['clusterPointCount'], 2);
      expect(point.metadata?['clusterYMaximum'], 20);
    });
  });
}

ScatterPointGeometry _geometry(
  int pointIndex,
  Offset center,
  double x,
  double y,
) => ScatterPointGeometry(
  pointIndex: pointIndex,
  point: ChartDataPoint(x: x, y: y),
  center: center,
  radius: 4,
  width: 8,
  height: 8,
  shape: SeriesMarkerShape.circle,
);
