import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/scatter_density.dart';
import 'package:braven_charts/src/rendering/scatter_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterDensityEngine', () {
    test('produces a deterministic normalized field and contour family', () {
      final geometries = [
        for (var index = 0; index < 24; index++)
          _geometry(index, Offset(42 + (index % 6) * 3, 38 + (index ~/ 6) * 3)),
      ];

      final first = ScatterDensityEngine.layout(
        geometries: geometries,
        plotSize: const Size(120, 100),
        config: const ScatterDensityConfig(
          gridCellSize: 5,
          bandwidth: 12,
          contourCount: 5,
          minimumDensity: 0.1,
        ),
      );
      final second = ScatterDensityEngine.layout(
        geometries: geometries,
        plotSize: const Size(120, 100),
        config: const ScatterDensityConfig(
          gridCellSize: 5,
          bandwidth: 12,
          contourCount: 5,
          minimumDensity: 0.1,
        ),
      );

      expect(first.sourcePointCount, 24);
      expect(first.maximumDensity, greaterThan(0));
      expect(first.relativeDensityAt(const Offset(50, 44)), greaterThan(0.9));
      expect(first.relativeDensityAt(const Offset(110, 90)), lessThan(0.05));
      expect(first.contours, isNotEmpty);
      expect(first.contours.length, lessThanOrEqualTo(5));
      expect(
        first.contours.map((contour) => contour.relativeDensity),
        orderedEquals(
          second.contours.map((contour) => contour.relativeDensity),
        ),
      );
      expect(
        first.contours.map((contour) => contour.segmentCount),
        orderedEquals(second.contours.map((contour) => contour.segmentCount)),
      );
    });

    test('larger bandwidth spreads density farther from a cluster', () {
      final geometries = [
        for (var index = 0; index < 12; index++)
          _geometry(index, Offset(35.0 + index % 3, 35.0 + index ~/ 3)),
      ];
      final narrow = ScatterDensityEngine.layout(
        geometries: geometries,
        plotSize: const Size(100, 100),
        config: const ScatterDensityConfig(gridCellSize: 4, bandwidth: 6),
      );
      final wide = ScatterDensityEngine.layout(
        geometries: geometries,
        plotSize: const Size(100, 100),
        config: const ScatterDensityConfig(gridCellSize: 4, bandwidth: 20),
      );

      expect(
        wide.relativeDensityAt(const Offset(68, 38)),
        greaterThan(narrow.relativeDensityAt(const Offset(68, 38))),
      );
    });

    test('returns an empty, safely sampleable layout for no observations', () {
      final layout = ScatterDensityEngine.layout(
        geometries: const [],
        plotSize: const Size(90, 60),
        config: const ScatterDensityConfig(),
      );

      expect(layout.isEmpty, isTrue);
      expect(layout.contours, isEmpty);
      expect(layout.sourcePointCount, 0);
      expect(layout.relativeDensityAt(const Offset(30, 20)), 0);
      expect(
        layout.sampleBoundsAt(const Offset(30, 20)),
        const Rect.fromLTRB(24, 16, 32, 24),
      );
    });

    test('clips every contour to exact plot bounds', () {
      final layout = ScatterDensityEngine.layout(
        geometries: [
          for (var index = 0; index < 20; index++)
            _geometry(index, Offset(index.isEven ? 0 : 2, 20 + index % 4)),
        ],
        plotSize: const Size(80, 60),
        config: const ScatterDensityConfig(gridCellSize: 4, bandwidth: 10),
      );

      for (final contour in layout.contours) {
        expect(contour.paintBounds.left, greaterThanOrEqualTo(0));
        expect(contour.paintBounds.top, greaterThanOrEqualTo(0));
        expect(contour.paintBounds.right, lessThanOrEqualTo(80));
        expect(contour.paintBounds.bottom, lessThanOrEqualTo(60));
      }
    });
  });
}

ScatterPointGeometry _geometry(int pointIndex, Offset center) =>
    ScatterPointGeometry(
      pointIndex: pointIndex,
      point: ChartDataPoint(x: center.dx, y: center.dy),
      center: center,
      radius: 3,
      width: 6,
      height: 6,
      shape: SeriesMarkerShape.circle,
    );
