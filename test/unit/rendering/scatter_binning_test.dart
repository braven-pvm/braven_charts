import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/scatter_binning.dart';
import 'package:braven_charts/src/rendering/scatter_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterBinEngine', () {
    test('aggregates a deterministic rectangular grid', () {
      final layout = ScatterBinEngine.layout(
        geometries: [
          _geometry(4, 4, 2),
          _geometry(8, 8, 0),
          _geometry(25, 5, 1),
        ],
        mode: ScatterRenderMode.rectangularBins,
        config: const ScatterBinConfig(cellSize: 20, gap: 2),
      );

      expect(layout.sourcePointCount, 3);
      expect(layout.filteredPointCount, 0);
      expect(layout.bins, hasLength(2));
      expect(layout.bins.first.sourcePointIndices, [0, 2]);
      expect(layout.bins.first.center, const Offset(10, 10));
      expect(layout.bins.first.paintBounds, const Rect.fromLTWH(1, 1, 18, 18));
      expect(layout.bins.first.path.contains(const Offset(10, 10)), isTrue);
      expect(layout.bins.last.sourcePointIndices, [1]);
    });

    test('aggregates a deterministic flat-top hexagonal grid', () {
      final layout = ScatterBinEngine.layout(
        geometries: [
          _geometry(1, 1, 3),
          _geometry(3, 2, 1),
          _geometry(31, 1, 2),
        ],
        mode: ScatterRenderMode.hexbin,
        config: const ScatterBinConfig(cellSize: 20),
      );

      expect(layout.bins, hasLength(2));
      final origin = layout.bins.singleWhere(
        (bin) => bin.center == Offset.zero,
      );
      expect(origin.sourcePointIndices, [1, 3]);
      expect(origin.path.contains(Offset.zero), isTrue);
      expect(
        layout.bins
            .singleWhere((bin) => bin.center != Offset.zero)
            .sourcePointIndices,
        [2],
      );
    });

    test('filters sub-threshold bins without losing source accounting', () {
      final layout = ScatterBinEngine.layout(
        geometries: [
          _geometry(2, 2, 0),
          _geometry(24, 2, 1),
          _geometry(26, 3, 2),
        ],
        mode: ScatterRenderMode.rectangularBins,
        config: const ScatterBinConfig(cellSize: 20, minimumPointCount: 2),
      );

      expect(layout.sourcePointCount, 3);
      expect(layout.filteredPointCount, 1);
      expect(layout.binnedPointCount, 2);
      expect(layout.bins.single.sourcePointIndices, [1, 2]);
    });

    test('computes every aggregate over the configured Y values', () {
      final geometries = [
        _geometry(2, 4, 0),
        _geometry(4, 10, 1),
        _geometry(24, 20, 2),
      ];
      const expected = {
        ScatterBinAggregate.count: [2.0, 1.0],
        ScatterBinAggregate.sum: [14.0, 20.0],
        ScatterBinAggregate.mean: [7.0, 20.0],
        ScatterBinAggregate.minimum: [4.0, 20.0],
        ScatterBinAggregate.maximum: [10.0, 20.0],
        ScatterBinAggregate.proportion: [2 / 3, 1 / 3],
      };

      for (final entry in expected.entries) {
        final layout = ScatterBinEngine.layout(
          geometries: geometries,
          mode: ScatterRenderMode.rectangularBins,
          config: ScatterBinConfig(
            cellSize: 20,
            aggregate: entry.key,
            valueSource: ScatterBinValueSource.y,
          ),
        );
        expect(
          layout.bins.map((bin) => bin.aggregateValue),
          orderedEquals(entry.value),
          reason: entry.key.name,
        );
      }
    });

    test('omits bins without an optional aggregate metric', () {
      final layout = ScatterBinEngine.layout(
        geometries: [_geometry(2, 4, 0), _geometry(24, 20, 1, magnitude: 8)],
        mode: ScatterRenderMode.rectangularBins,
        config: const ScatterBinConfig(
          cellSize: 20,
          aggregate: ScatterBinAggregate.mean,
          valueSource: ScatterBinValueSource.magnitude,
        ),
      );

      expect(layout.bins, hasLength(1));
      expect(layout.bins.single.aggregateValue, 8);
      expect(layout.bins.single.aggregateSampleCount, 1);
      expect(layout.filteredPointCount, 1);
    });

    test('reads every supported numeric point field', () {
      final geometries = [
        _geometry(2, 4, 0, magnitude: 6, colorValue: 8, opacityValue: 0.4),
        _geometry(4, 10, 1, magnitude: 12, colorValue: 16, opacityValue: 0.8),
      ];
      const expected = {
        ScatterBinValueSource.x: 3.0,
        ScatterBinValueSource.y: 7.0,
        ScatterBinValueSource.magnitude: 9.0,
        ScatterBinValueSource.colorValue: 12.0,
        ScatterBinValueSource.opacityValue: 0.6,
      };

      for (final entry in expected.entries) {
        final layout = ScatterBinEngine.layout(
          geometries: geometries,
          mode: ScatterRenderMode.rectangularBins,
          config: ScatterBinConfig(
            cellSize: 20,
            aggregate: ScatterBinAggregate.mean,
            valueSource: entry.key,
          ),
        );
        expect(
          layout.bins.single.aggregateValue,
          closeTo(entry.value, 0.000001),
          reason: entry.key.name,
        );
      }
    });
  });
}

ScatterPointGeometry _geometry(
  double x,
  double y,
  int pointIndex, {
  double? magnitude,
  double? colorValue,
  double? opacityValue,
}) => ScatterPointGeometry(
  pointIndex: pointIndex,
  point: ChartDataPoint(
    x: x,
    y: y,
    magnitude: magnitude,
    colorValue: colorValue,
    opacityValue: opacityValue,
  ),
  center: Offset(x, y),
  radius: 2,
  width: 4,
  height: 4,
  shape: SeriesMarkerShape.circle,
  rotationRadians: 0,
  strokeWidth: 0,
);
