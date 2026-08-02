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

    test('explicit rectangles participate in viewport and pointer queries', () {
      final cells = [
        HeatmapDataPoint(x: 0, y: 0, value: 1),
        HeatmapDataPoint(
          x: 5,
          y: 2,
          value: 2,
          bounds: HeatmapCellBounds(
            xMinimum: 2,
            xMaximum: 8,
            yMinimum: 1,
            yMaximum: 3,
          ),
        ),
        HeatmapDataPoint(
          x: 12,
          y: 7,
          value: 3,
          bounds: HeatmapCellBounds(
            xMinimum: 11,
            xMaximum: 13,
            yMinimum: 6,
            yMaximum: 9,
          ),
        ),
      ];
      final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

      expect(index.cellCount, 3);
      expect(index.irregularCellCount, 2);
      expect(
        index
            .queryViewport(minX: 2.5, maxX: 3, minY: 1.5, maxY: 2.5)
            .pointIndices,
        [1],
      );
      expect(index.pointIndicesAt(const Offset(2.1, 1.1)), [1]);
      expect(index.pointIndicesAt(const Offset(8.1, 2)), isEmpty);
      expect(index.pointIndicesAt(const Offset(12, 8)), [2]);
    });

    test('mixed regular and explicit query results retain source order', () {
      final cells = [
        HeatmapDataPoint(
          x: 2,
          y: 2,
          value: 1,
          bounds: HeatmapCellBounds(
            xMinimum: 1,
            xMaximum: 3,
            yMinimum: 1,
            yMaximum: 3,
          ),
        ),
        HeatmapDataPoint(x: 2, y: 2, value: 2),
      ];
      final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

      expect(index.pointIndicesAt(const Offset(2, 2)), [0, 1]);
      expect(
        index.queryViewport(minX: 2, maxX: 2, minY: 2, maxY: 2).pointIndices,
        [0, 1],
      );
    });

    test('small viewport work stays bounded for 10k explicit rectangles', () {
      final cells = <HeatmapDataPoint>[
        for (var y = 0; y < 100; y++)
          for (var x = 0; x < 100; x++)
            HeatmapDataPoint(
              x: x + 0.4,
              y: y + 0.4,
              value: (x + y).toDouble(),
              bounds: HeatmapCellBounds(
                xMinimum: x.toDouble(),
                xMaximum: x + 0.8,
                yMinimum: y.toDouble(),
                yMaximum: y + 0.8,
              ),
            ),
      ];
      final index = HeatmapViewportIndex(cells, cellWidth: 1, cellHeight: 1);

      final query = index.queryViewport(
        minX: 40.1,
        maxX: 41.7,
        minY: 20.1,
        maxY: 21.7,
        overscanCellCount: 0,
      );

      expect(index.cellCount, 10000);
      expect(index.rowCount, 0);
      expect(index.irregularCellCount, 10000);
      expect(query.pointIndices, [2040, 2041, 2140, 2141]);
      expect(query.visitedCellCount, lessThan(300));
      expect(query.visitedCellCount, lessThan(index.cellCount ~/ 30));
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
