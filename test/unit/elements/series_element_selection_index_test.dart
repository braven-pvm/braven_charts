import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dense Line rectangle and lasso queries use bounded candidates', () {
    final points = List<ChartDataPoint>.generate(
      100000,
      (index) =>
          ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
      growable: false,
    );
    final element = SeriesElement(
      series: LineChartSeries(
        id: 'dense-line',
        points: points,
        isXOrdered: true,
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 100000,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 500,
      ),
    );

    final rectangleHits = element.dataHitsInPlotRect(
      const Rect.fromLTRB(499.9, 0, 500.1, 500),
    );
    expect(rectangleHits, isNotEmpty);
    expect(element.selectionCandidateCount, lessThan(32));

    final lassoHits = element.dataHitsInPlotPolygon(const [
      Offset(499.9, 0),
      Offset(500.1, 0),
      Offset(500.1, 500),
      Offset(499.9, 500),
    ]);
    expect(lassoHits, isNotEmpty);
    expect(element.selectionCandidateCount, lessThan(32));
  });

  test('dense Range Area rectangle query uses its ordered viewport index', () {
    final element = SeriesElement(
      series: RangeAreaChartSeries(
        id: 'dense-range',
        points: List<RangeAreaDataPoint>.generate(
          10000,
          (index) => RangeAreaDataPoint(x: index.toDouble(), low: 20, high: 80),
          growable: false,
        ),
      ),
      transform: const ChartTransform(
        dataXMin: 0,
        dataXMax: 10000,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 500,
      ),
    );

    final hits = element.dataHitsInPlotRect(
      const Rect.fromLTRB(499.9, 0, 500.1, 500),
    );
    expect(hits, isNotEmpty);
    expect(element.selectionCandidateCount, lessThan(8));
  });

  test('dense Bar rectangle query reuses plot-space geometry cells', () {
    final element = SeriesElement(
      series: BarChartSeries(
        id: 'dense-bars',
        barWidthPercent: 0.7,
        points: List<ChartDataPoint>.generate(
          10000,
          (index) =>
              ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
          growable: false,
        ),
      ),
      transform: const ChartTransform(
        dataXMin: 4900,
        dataXMax: 5100,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 500,
      ),
    );

    final hits = element.dataHitsInPlotRect(
      const Rect.fromLTRB(490, 0, 510, 500),
    );
    expect(hits, isNotEmpty);
    expect(element.selectionCandidateCount, lessThan(32));
  });
}
