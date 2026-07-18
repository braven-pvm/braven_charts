import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/bar_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarViewportIndex', () {
    test('queries unordered categories while preserving source indices', () {
      final index = BarViewportIndex(const [
        ChartDataPoint(x: 30, y: 1),
        ChartDataPoint(x: 10, y: 2),
        ChartDataPoint(x: 20, y: 3),
        ChartDataPoint(x: 40, y: 4),
      ]);

      expect(index.pointIndicesForViewport(minX: 15, maxX: 35), [2, 0]);
      expect(
        index.pointIndicesForViewport(
          minX: 15,
          maxX: 35,
          adjacentPointCount: 1,
        ),
        [1, 2, 0, 3],
      );
    });

    test('reuses cached category spacing at different zoom levels', () {
      final index = BarViewportIndex(const [
        ChartDataPoint(x: 0, y: 1),
        ChartDataPoint(x: 2, y: 2),
        ChartDataPoint(x: 5, y: 3),
      ]);

      expect(index.categorySpacingPixels(_transform(0, 10)), 200);
      expect(index.categorySpacingPixels(_transform(0, 20)), 100);
    });

    test('excludes points with non-finite coordinates', () {
      final index = BarViewportIndex(const [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: double.nan),
        ChartDataPoint(x: double.infinity, y: 30),
        ChartDataPoint(x: 3, y: 40),
      ]);

      expect(index.pointIndicesForViewport(minX: 0, maxX: 3), [0, 3]);
      expect(index.pointCount, 2);
    });
  });

  group('SeriesElement bar virtualization', () {
    test('materializes only visible vertical bars from a 10k series', () {
      final element = SeriesElement(
        series: _series(),
        transform: _transform(5000, 5010),
      );

      expect(element.visibleBarGeometryCount, lessThan(20));
      expect(element.visibleBarPointIndices, containsAll([5000, 5005, 5010]));
      expect(element.barGeometryForPoint(0), isNull);
      expect(element.barGeometryForPoint(5005), isNotNull);
    });

    test('re-queries original indices after a horizontal viewport pan', () {
      final element = SeriesElement(
        series: _series(orientation: BarOrientation.horizontal),
        transform: _transform(2000, 2010),
      );

      expect(element.visibleBarPointIndices, contains(2005));
      expect(element.visibleBarPointIndices, isNot(contains(8005)));

      element.updateTransform(_transform(8000, 8010));

      expect(element.visibleBarGeometryCount, lessThan(20));
      expect(element.visibleBarPointIndices, contains(8005));
      expect(element.barGeometryForPoint(2005), isNull);
      expect(element.barGeometryForPoint(8005), isNotNull);
    });

    test('uses original point indices for stacked geometry after culling', () {
      final series = _series(pointCount: 100);
      final element = SeriesElement(
        series: series,
        transform: _transform(48, 52),
        barGroupInfo: const BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.stacked,
          startValues: {50: 20},
          endValues: {50: 35},
          outerPointIndices: {50},
        ),
      );

      final geometry = element.barGeometryForPoint(50)!;
      expect(geometry.pointIndex, 50);
      expect(geometry.startValue, 20);
      expect(geometry.endValue, 35);
    });

    test('indexes hit rectangles instead of scanning the full series', () {
      final element = SeriesElement(
        series: _series(),
        transform: _transform(5000, 5010),
      );
      final geometry = element.barGeometryForPoint(5005)!;

      final hit = element.barGeometryAt(geometry.rect.center);
      final dataHit = element.dataHitAt(geometry.rect.center);

      expect(hit?.pointIndex, 5005);
      expect(dataHit?.pointIndex, 5005);
      expect(dataHit?.plotPosition, geometry.valueEndPoint);
      expect(element.barHitComparisonCount, lessThan(6));
    });

    test('does not materialize invalid points into the spatial hit index', () {
      final element = SeriesElement(
        series: const BarChartSeries(
          id: 'invalid-data',
          points: [
            ChartDataPoint(x: 0, y: 20),
            ChartDataPoint(x: 1, y: double.nan),
            ChartDataPoint(x: 2, y: 40),
          ],
          barWidthPercent: 0.7,
        ),
        transform: _transform(0, 2),
      );

      expect(element.visibleBarPointIndices, [0, 2]);
      expect(element.barGeometryForPoint(1), isNull);
      expect(element.barGeometryForPoint(2), isNotNull);
    });

    test('keeps oversized point bars whose bodies overlap the viewport', () {
      final element = SeriesElement(
        series: const BarChartSeries(
          id: 'wide-point',
          points: [
            ChartDataPoint(x: 4.7, y: 40, pointStyle: PointStyle(size: 10)),
            ChartDataPoint(x: 6, y: 50),
          ],
          barWidthPixels: 100,
          maxWidth: 100,
        ),
        transform: _transform(5, 6),
      );

      final geometry = element.barGeometryForPoint(0);
      expect(geometry, isNotNull);
      expect(geometry!.rect.right, greaterThan(0));
    });

    test('falls back safely for a non-finite point width multiplier', () {
      final element = SeriesElement(
        series: const BarChartSeries(
          id: 'invalid-width',
          points: [
            ChartDataPoint(
              x: 1,
              y: 40,
              pointStyle: PointStyle(size: double.nan),
            ),
          ],
          barWidthPixels: 20,
        ),
        transform: _transform(0, 2),
      );

      expect(element.barGeometryForPoint(0)!.rect.width, 20);
    });

    test('bounds the hit index for an extreme finite point width', () {
      final element = SeriesElement(
        series: const BarChartSeries(
          id: 'extreme-width',
          points: [
            ChartDataPoint(
              x: 1,
              y: 40,
              pointStyle: PointStyle(size: 1000000000),
            ),
          ],
          barWidthPixels: 20,
        ),
        transform: _transform(0, 2),
      );

      final geometry = element.barGeometryForPoint(0)!;
      expect(element.barGeometryAt(geometry.rect.center)?.pointIndex, 0);
      expect(element.barHitComparisonCount, 1);
    });

    test('keeps adjacent Waterfall steps for connector continuity', () {
      final points = [
        for (var index = 0; index < 100; index++)
          ChartDataPoint(x: index.toDouble(), y: index.isEven ? 3 : -2),
      ];
      final element = SeriesElement(
        series: BarChartSeries(
          id: 'waterfall',
          points: points,
          isXOrdered: true,
          barWidthPercent: 0.7,
          layoutMode: BarLayoutMode.waterfall,
        ),
        transform: _transform(49.5, 50.5),
        barGroupInfo: BarGroupInfo(
          index: 0,
          count: 1,
          layoutMode: BarLayoutMode.waterfall,
          startValues: {for (var index = 0; index < 100; index++) index: 0},
          endValues: {for (var index = 0; index < 100; index++) index: 1},
        ),
      );

      expect(element.visibleBarPointIndices, containsAll([49, 50, 51]));
      expect(element.visibleBarGeometryCount, lessThan(10));
    });
  });
}

BarChartSeries _series({
  int pointCount = 10000,
  BarOrientation orientation = BarOrientation.vertical,
}) => BarChartSeries(
  id: 'dense',
  points: [
    for (var index = 0; index < pointCount; index++)
      ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble() + 1),
  ],
  isXOrdered: true,
  barWidthPercent: 0.72,
  maxWidth: 24,
  orientation: orientation,
);

ChartTransform _transform(double minX, double maxX) => ChartTransform(
  dataXMin: minX,
  dataXMax: maxX,
  dataYMin: 0,
  dataYMax: 120,
  plotWidth: 1000,
  plotHeight: 600,
);
