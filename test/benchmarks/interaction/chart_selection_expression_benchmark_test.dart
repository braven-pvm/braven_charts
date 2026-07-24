import 'dart:collection';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection summary benchmark covers 100k and 1m observations', () {
    for (final pointCount in const [100000, 1000000]) {
      final points = _GeneratedPointList(pointCount);
      final snapshot = ChartSelectionSnapshot(
        expression: ChartSelectionExpression(
          clauses: const [
            ChartSelectionWholeSeriesClause(seriesId: 'benchmark'),
          ],
        ),
        revision: ChartDocumentRevision.next(),
        series: [
          LineChartSeries(id: 'benchmark', points: points, isXOrdered: true),
        ],
      );

      final stopwatch = Stopwatch()..start();
      final statistics = snapshot.statistics;
      stopwatch.stop();

      expect(statistics.pointCount, pointCount);
      expect(statistics.y?.mean, (pointCount - 1) / 2);
      expect(points.readCount, lessThanOrEqualTo(pointCount + 2));
      // ignore: avoid_print
      print(
        'Selection summary $pointCount points: '
        '${stopwatch.elapsedMicroseconds} us',
      );
    }
  });

  test('narrow ordered selection remains logarithmic plus output size', () {
    const pointCount = 1000000;
    final points = _GeneratedPointList(pointCount);
    final snapshot = ChartSelectionSnapshot(
      expression: ChartSelectionExpression(
        clauses: [
          ChartSelectionXIntervalClause(
            minimumXInclusive: 500000,
            maximumXInclusive: 500009,
          ),
        ],
      ),
      revision: ChartDocumentRevision.next(),
      series: [
        LineChartSeries(id: 'benchmark', points: points, isXOrdered: true),
      ],
    );

    expect(snapshot.statistics.pointCount, 10);
    expect(points.readCount, lessThan(100));
  });

  test('dense rectangle summaries stay lazy at 5k, 100k, and 1m', () {
    for (final pointCount in const [5000, 100000, 1000000]) {
      final points = _GeneratedPointList(pointCount);
      final expression = ChartSelectionExpression(
        clauses: [
          ChartSelectionRectangleClause(
            minimumXInclusive: -1,
            maximumXInclusive: pointCount.toDouble(),
            minimumYInclusive: -1,
            maximumYInclusive: pointCount.toDouble(),
            seriesIds: const {'benchmark'},
          ),
        ],
      );
      final snapshot = ChartSelectionSnapshot(
        expression: expression,
        revision: ChartDocumentRevision.next(),
        series: [
          LineChartSeries(id: 'benchmark', points: points, isXOrdered: true),
        ],
      );

      final stopwatch = Stopwatch()..start();
      final statistics = snapshot.statistics;
      stopwatch.stop();

      expect(statistics.pointCount, pointCount);
      expect(snapshot.debugPointRefsMaterialized, isFalse);
      expect(expression.clauses, hasLength(1));
      expect(points.readCount, lessThanOrEqualTo(pointCount + 100));
      // ignore: avoid_print
      print(
        'Rectangle summary $pointCount points: '
        '${stopwatch.elapsedMicroseconds} us',
      );
    }
  });

  test('narrow ordered rectangle remains logarithmic plus output size', () {
    const pointCount = 1000000;
    final points = _GeneratedPointList(pointCount);
    final snapshot = ChartSelectionSnapshot(
      expression: ChartSelectionExpression(
        clauses: [
          ChartSelectionRectangleClause(
            minimumXInclusive: 500000,
            maximumXInclusive: 500009,
            minimumYInclusive: 500000,
            maximumYInclusive: 500009,
          ),
        ],
      ),
      revision: ChartDocumentRevision.next(),
      series: [
        LineChartSeries(id: 'benchmark', points: points, isXOrdered: true),
      ],
    );

    expect(snapshot.pointRefs, hasLength(10));
    expect(points.readCount, lessThan(100));
  });
}

class _GeneratedPointList extends ListBase<ChartDataPoint> {
  _GeneratedPointList(this._length);

  final int _length;
  var readCount = 0;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('fixed length');

  @override
  ChartDataPoint operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    readCount++;
    return ChartDataPoint(x: index.toDouble(), y: index.toDouble());
  }

  @override
  void operator []=(int index, ChartDataPoint value) =>
      throw UnsupportedError('read only');
}
