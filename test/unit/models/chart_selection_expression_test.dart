import 'dart:collection';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSelectionExpression', () {
    test('compresses resolved identities into deterministic clauses', () {
      final expression = ChartSelectionExpression.fromResolvedIdentities(
        wholeSeriesIds: const ['target', 'actual'],
        pointRefs: const [
          ChartPointRef(seriesId: 'actual', pointIndex: 9),
          ChartPointRef(seriesId: 'detail', pointIndex: 3),
          ChartPointRef(seriesId: 'detail', pointIndex: 1),
          ChartPointRef(seriesId: 'detail', pointIndex: 2),
          ChartPointRef(seriesId: 'detail', pointIndex: 7),
        ],
      );

      expect(expression.clauses, hasLength(4));
      expect(expression.clauses.take(2), const [
        ChartSelectionWholeSeriesClause(seriesId: 'actual'),
        ChartSelectionWholeSeriesClause(seriesId: 'target'),
      ]);
      expect(
        expression.clauses[2],
        const ChartSelectionPointIndexSpanClause(
          seriesId: 'detail',
          startPointIndexInclusive: 1,
          endPointIndexInclusive: 3,
        ),
      );
      expect(
        (expression.clauses[3] as ChartSelectionExplicitPointRefsClause)
            .pointRefs,
        {const ChartPointRef(seriesId: 'detail', pointIndex: 7)},
      );
    });

    test('resolves all clause types and ignores stale identities', () {
      final expression = ChartSelectionExpression(
        clauses: [
          const ChartSelectionWholeSeriesClause(seriesId: 'whole'),
          const ChartSelectionPointIndexSpanClause(
            seriesId: 'span',
            startPointIndexInclusive: 1,
            endPointIndexInclusive: 99,
          ),
          ChartSelectionXIntervalClause(
            minimumXInclusive: 2,
            maximumXInclusive: 3,
            seriesIds: const {'ordered'},
          ),
          ChartSelectionYIntervalClause(
            minimumYInclusive: 30,
            maximumYInclusive: 40,
            seriesIds: const {'unordered'},
          ),
          ChartSelectionExplicitPointRefsClause(
            pointRefs: const [
              ChartPointRef(seriesId: 'unordered', pointIndex: 0),
              ChartPointRef(seriesId: 'missing', pointIndex: 2),
            ],
          ),
        ],
      );
      final resolved = expression.resolvePointRefs([
        _series('whole', const [(0, 10), (1, 20)]),
        _series('span', const [(0, 10), (1, 20), (2, 30)]),
        _series('ordered', const [
          (0, 10),
          (1, 20),
          (2, 30),
          (3, 40),
          (4, 50),
        ], isXOrdered: true),
        _series('unordered', const [(4, 10), (1, 30), (3, 40)]),
      ]);

      expect(resolved, {
        const ChartPointRef(seriesId: 'whole', pointIndex: 0),
        const ChartPointRef(seriesId: 'whole', pointIndex: 1),
        const ChartPointRef(seriesId: 'span', pointIndex: 1),
        const ChartPointRef(seriesId: 'span', pointIndex: 2),
        const ChartPointRef(seriesId: 'ordered', pointIndex: 2),
        const ChartPointRef(seriesId: 'ordered', pointIndex: 3),
        const ChartPointRef(seriesId: 'unordered', pointIndex: 0),
        const ChartPointRef(seriesId: 'unordered', pointIndex: 1),
        const ChartPointRef(seriesId: 'unordered', pointIndex: 2),
      });
    });

    test('stable point keys resolve after reorder and reject ambiguity', () {
      final original = const LineChartSeries(
        id: 'signal',
        points: [
          ChartDataPoint(x: 0, y: 10, pointKey: 'alpha'),
          ChartDataPoint(x: 1, y: 20, pointKey: 'beta'),
        ],
      );
      final expression = ChartSelectionExpression.fromResolvedIdentities(
        pointRefs: const [ChartPointRef(seriesId: 'signal', pointIndex: 0)],
        series: [original],
      );

      expect(expression.clauses, hasLength(1));
      expect(
        (expression.clauses.single as ChartSelectionPointKeysClause).pointKeys,
        {'alpha'},
      );

      final reordered = const LineChartSeries(
        id: 'signal',
        points: [
          ChartDataPoint(x: 1, y: 20, pointKey: 'beta'),
          ChartDataPoint(x: 0, y: 10, pointKey: 'alpha'),
        ],
      );
      expect(expression.resolvePointRefs([reordered]), {
        const ChartPointRef(seriesId: 'signal', pointIndex: 1),
      });

      final ambiguous = const LineChartSeries(
        id: 'signal',
        points: [
          ChartDataPoint(x: 0, y: 10, pointKey: 'duplicate'),
          ChartDataPoint(x: 1, y: 20, pointKey: 'duplicate'),
        ],
      );
      expect(
        () => ChartPointKeyIndex(ambiguous).pointIndexFor('duplicate'),
        throwsArgumentError,
      );
    });

    test('ordered X interval snapshot stays lazy and uses binary search', () {
      final points = _CountingPointList(
        List.generate(
          100000,
          (index) => ChartDataPoint(x: index.toDouble(), y: index.toDouble()),
          growable: false,
        ),
      );
      final series = LineChartSeries(
        id: 'ordered',
        points: points,
        isXOrdered: true,
      );
      final snapshot = ChartSelectionSnapshot(
        expression: ChartSelectionExpression(
          clauses: [
            ChartSelectionXIntervalClause(
              minimumXInclusive: 50000,
              maximumXInclusive: 50009,
            ),
          ],
        ),
        revision: ChartDocumentRevision.next(),
        series: [series],
      );

      expect(points.readCount, 0);
      expect(snapshot.statistics.pointCount, 10);
      expect(points.readCount, lessThan(100));
      expect(snapshot.extents?.minimumX, 50000);
      expect(snapshot.extents?.maximumX, 50009);
    });

    test('streaming statistics deduplicate overlapping compact clauses', () {
      final series = _series('signal', const [
        (0, 10),
        (1, 20),
        (2, 30),
        (3, 40),
        (4, 50),
      ], isXOrdered: true);
      final snapshot = ChartSelectionSnapshot(
        expression: ChartSelectionExpression(
          clauses: [
            const ChartSelectionWholeSeriesClause(seriesId: 'signal'),
            ChartSelectionXIntervalClause(
              minimumXInclusive: 1,
              maximumXInclusive: 3,
            ),
            const ChartSelectionPointIndexSpanClause(
              seriesId: 'signal',
              startPointIndexInclusive: 2,
              endPointIndexInclusive: 4,
            ),
          ],
        ),
        revision: ChartDocumentRevision.next(),
        series: [series],
      );

      expect(snapshot.statistics, snapshot.result.statistics);
      expect(snapshot.statistics.pointCount, 5);
      expect(snapshot.statistics.seriesCount, 1);
      expect(snapshot.statistics.x?.mean, 2);
      expect(snapshot.statistics.y?.mean, 30);
      expect(snapshot.extents, snapshot.result.extents);
    });

    test('million-point whole-series statistics stream source points once', () {
      const pointCount = 1000000;
      final points = _GeneratedPointList(pointCount);
      final snapshot = ChartSelectionSnapshot(
        expression: ChartSelectionExpression(
          clauses: const [ChartSelectionWholeSeriesClause(seriesId: 'million')],
        ),
        revision: ChartDocumentRevision.next(),
        series: [
          LineChartSeries(id: 'million', points: points, isXOrdered: true),
        ],
      );

      expect(points.readCount, 0);
      final statistics = snapshot.statistics;
      expect(statistics.pointCount, pointCount);
      expect(statistics.seriesCount, 1);
      expect(statistics.x?.minimum, 0);
      expect(statistics.x?.maximum, pointCount - 1);
      expect(statistics.x?.mean, (pointCount - 1) / 2);
      expect(snapshot.extents?.maximumY, pointCount - 1);
      expect(
        points.readCount,
        lessThanOrEqualTo(pointCount + 2),
        reason:
            'Summary access must not first materialize one reference and result object per point.',
      );
    });
  });
}

LineChartSeries _series(
  String id,
  List<(num x, num y)> values, {
  bool isXOrdered = false,
}) => LineChartSeries(
  id: id,
  isXOrdered: isXOrdered,
  points: [
    for (final value in values)
      ChartDataPoint(x: value.$1.toDouble(), y: value.$2.toDouble()),
  ],
);

class _CountingPointList extends ListBase<ChartDataPoint> {
  _CountingPointList(this._values);

  final List<ChartDataPoint> _values;
  var readCount = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => throw UnsupportedError('fixed length');

  @override
  ChartDataPoint operator [](int index) {
    readCount++;
    return _values[index];
  }

  @override
  void operator []=(int index, ChartDataPoint value) =>
      throw UnsupportedError('read only');
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
