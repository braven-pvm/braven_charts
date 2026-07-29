import 'package:braven_charts/src/models/heatmap_data_point.dart';
import 'package:braven_charts/src/rendering/heatmap_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapViewportIndex', () {
    test('small viewport work stays bounded for 250k dense cells', () {
      final cells = <HeatmapDataPoint>[
        for (var y = 0; y < 500; y++)
          for (var x = 0; x < 500; x++)
            HeatmapDataPoint(
              x: x.toDouble(),
              y: y.toDouble(),
              value: (x + y).toDouble(),
            ),
      ];
      final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

      final query = index.queryViewport(minX: 10, maxX: 20, minY: 30, maxY: 40);

      expect(index.cellCount, 250000);
      expect(index.rowCount, 500);
      expect(query.visitedRowCount, 13);
      expect(query.visitedCellCount, 169);
      expect(query.pointIndices, hasLength(169));
      expect(query.visitedCellCount, lessThan(index.cellCount ~/ 1000));
    });

    test(
      'sparse viewport query returns source order with one-cell overscan',
      () {
        final cells = [
          HeatmapDataPoint(x: 40, y: 40, value: 4),
          HeatmapDataPoint(x: 2, y: 2, value: 2),
          HeatmapDataPoint(x: 1, y: 1, value: 1),
          HeatmapDataPoint(x: 3, y: 2, value: 3),
        ];
        final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

        final query = index.queryViewport(
          minX: 1.75,
          maxX: 2.25,
          minY: 1.75,
          maxY: 2.25,
        );

        expect(query.pointIndices, [1, 2, 3]);
        expect(query.visitedRowCount, 2);
        expect(query.visitedCellCount, 3);
      },
    );

    test('pointer lookup is two-dimensional and preserves overlap order', () {
      final cells = [
        HeatmapDataPoint(x: 1, y: 1, value: 1),
        HeatmapDataPoint(x: 1, y: 1, value: 2, pointKey: 'overlapping'),
        HeatmapDataPoint(x: 2, y: 1, value: 3),
        HeatmapDataPoint(x: 1, y: 2, value: 4),
      ];
      final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

      expect(index.pointIndicesAt(const Offset(1, 1)), [0, 1]);
      expect(index.pointIndicesAt(const Offset(2, 1)), [2]);
      expect(index.pointIndicesAt(const Offset(1, 2)), [3]);
      expect(index.pointIndicesAt(const Offset(20, 20)), isEmpty);
    });

    test('empty and reversed viewport bounds are supported', () {
      final empty = HeatmapViewportIndex(const [], cellWidth: 1, cellHeight: 1);
      expect(
        empty.queryViewport(minX: 2, maxX: 1, minY: 2, maxY: 1).pointIndices,
        isEmpty,
      );

      final populated = HeatmapViewportIndex(
        [HeatmapDataPoint(x: 1, y: 1, value: 1)],
        cellWidth: 1,
        cellHeight: 1,
      );
      expect(
        populated
            .queryViewport(minX: 2, maxX: 0, minY: 2, maxY: 0)
            .pointIndices,
        [0],
      );
    });
  });
}
