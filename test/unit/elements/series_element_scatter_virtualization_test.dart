import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/scatter_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScatterViewportIndex', () {
    test('queries unordered points while preserving source indices', () {
      final index = ScatterViewportIndex(const [
        ChartDataPoint(x: 30, y: 30),
        ChartDataPoint(x: 10, y: 10),
        ChartDataPoint(x: 20, y: 20),
        ChartDataPoint(x: 40, y: 40),
      ]);

      expect(
        index.pointIndicesForViewport(minX: 15, maxX: 35, minY: 15, maxY: 35),
        [0, 2],
      );
    });

    test('excludes invalid and vertically offscreen points', () {
      final index = ScatterViewportIndex(const [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: double.nan),
        ChartDataPoint(x: double.infinity, y: 30),
        ChartDataPoint(x: 2, y: 200),
        ChartDataPoint(x: 3, y: 40),
      ]);

      expect(
        index.pointIndicesForViewport(minX: 0, maxX: 3, minY: 0, maxY: 100),
        [0, 4],
      );
      expect(index.pointCount, 3);
    });
  });

  group('SeriesElement Scatter virtualization', () {
    test('materializes only visible points from a 100k series', () {
      final element = SeriesElement(
        series: _denseSeries(),
        transform: _transform(50000, 50010),
      );

      expect(element.visibleScatterGeometryCount, lessThan(20));
      expect(
        element.visibleScatterPointIndices,
        containsAll([50000, 50005, 50010]),
      );
      expect(element.dataHitForPointIndex(0), isNotNull);
      expect(element.dataHitForPointIndex(50005), isNotNull);
    });

    test('re-queries source indices after a viewport pan', () {
      final element = SeriesElement(
        series: _denseSeries(),
        transform: _transform(2000, 2010),
      );

      expect(element.visibleScatterPointIndices, contains(2005));
      expect(element.visibleScatterPointIndices, isNot(contains(8005)));

      element.updateTransform(_transform(8000, 8010));

      expect(element.visibleScatterGeometryCount, lessThan(20));
      expect(element.visibleScatterPointIndices, contains(8005));
      expect(element.visibleScatterPointIndices, isNot(contains(2005)));
    });

    test('uses indexed candidates for marker-aware hits', () {
      final element = SeriesElement(
        series: _denseSeries(),
        transform: _transform(50000, 50010),
      );
      final center = element.dataHitForPointIndex(50005)!.plotPosition;

      expect(element.hitTest(center), isTrue);
      expect(element.scatterHitComparisonCount, lessThan(8));
    });

    test('keeps markers whose painted body overlaps the viewport', () {
      final element = SeriesElement(
        series: const ScatterChartSeries(
          id: 'edge',
          points: [
            ChartDataPoint(x: -0.05, y: 50, pointStyle: PointStyle(size: 10)),
            ChartDataPoint(x: 2, y: 50),
          ],
        ),
        transform: const ChartTransform(
          dataXMin: 0,
          dataXMax: 1,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 100,
          plotHeight: 100,
        ),
      );

      expect(element.visibleScatterPointIndices, [0]);
      expect(element.hitTest(const Offset(1, 50)), isTrue);
    });
  });
}

ScatterChartSeries _denseSeries() => ScatterChartSeries(
  id: 'dense',
  points: [
    for (var index = 0; index < 100000; index++)
      ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
  ],
  isXOrdered: true,
  markerRadius: 4,
);

ChartTransform _transform(double minX, double maxX) => ChartTransform(
  dataXMin: minX,
  dataXMax: maxX,
  dataYMin: 0,
  dataYMax: 100,
  plotWidth: 1000,
  plotHeight: 600,
);
