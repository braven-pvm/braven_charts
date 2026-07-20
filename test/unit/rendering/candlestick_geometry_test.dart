import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandlestickGeometryEngine', () {
    test('resolves rising body, wick, paint, and hit geometry', () {
      final point = _candle(x: 5, open: 10, high: 15, low: 8, close: 12);
      final geometry = CandlestickGeometryEngine.resolve(
        index: CandlestickViewportIndex([point]),
        transform: _transform(),
        style: const CandlestickChartStyle(),
      ).single;

      expect(geometry.pointIndex, 0);
      expect(geometry.direction, CandlestickDirection.rising);
      expect(geometry.centerX, 500);
      expect(geometry.bodyWidth, 18);
      expect(geometry.bodyRect.top, 80);
      expect(geometry.bodyRect.bottom, 100);
      expect(geometry.upperWickStart.dy, 50);
      expect(geometry.upperWickEnd.dy, 80);
      expect(geometry.lowerWickStart.dy, 100);
      expect(geometry.lowerWickEnd.dy, 120);
      expect(geometry.paintBounds.contains(const Offset(500, 50)), isTrue);
      expect(geometry.hitBounds.contains(geometry.bodyRect.center), isTrue);
    });

    test('gives falling and doji candles deterministic minimum bodies', () {
      final geometry = CandlestickGeometryEngine.resolve(
        index: CandlestickViewportIndex([
          _candle(x: 3, open: 12, high: 14, low: 9, close: 10),
          _candle(x: 4, open: 11, high: 13, low: 8, close: 11),
        ]),
        transform: _transform(),
        style: const CandlestickChartStyle(minimumBodyHeight: 2),
      );

      expect(geometry[0].direction, CandlestickDirection.falling);
      expect(geometry[1].direction, CandlestickDirection.doji);
      expect(geometry[1].bodyRect.height, 2);
    });

    test('uses robust spacing and clamps one large-gap body width', () {
      final points = [_candle(x: 0), _candle(x: 1), _candle(x: 100)];
      final index = CandlestickViewportIndex(points);
      final geometry = CandlestickGeometryEngine.resolve(
        index: index,
        transform: const ChartTransform(
          dataXMin: 0,
          dataXMax: 100,
          dataYMin: 0,
          dataYMax: 20,
          plotWidth: 1000,
          plotHeight: 200,
        ),
        style: const CandlestickChartStyle(maxBodyWidth: 16),
      );

      expect(index.nominalSpacingData, 1);
      expect(geometry.every((item) => item.bodyWidth <= 16), isTrue);
      expect(geometry.first.bodyWidth, 7);
    });

    test('aligns centers deterministically at different pixel ratios', () {
      final point = _candle(x: 1 / 3);
      for (final ratio in const [1.0, 2.0, 3.0]) {
        final geometry = CandlestickGeometryEngine.resolve(
          index: CandlestickViewportIndex([point]),
          transform: _transform(),
          style: const CandlestickChartStyle(),
          devicePixelRatio: ratio,
        ).single;
        expect(geometry.centerX * ratio, (geometry.centerX * ratio).round());
      }
    });

    test('binary-searches 50,000 points and returns only visible candles', () {
      final index = CandlestickViewportIndex([
        for (var pointIndex = 0; pointIndex < 50000; pointIndex++)
          _candle(x: pointIndex.toDouble()),
      ]);
      const transform = ChartTransform(
        dataXMin: 25000,
        dataXMax: 25999,
        dataYMin: 0,
        dataYMax: 20,
        plotWidth: 1000,
        plotHeight: 200,
      );

      final geometry = CandlestickGeometryEngine.resolve(
        index: index,
        transform: transform,
        style: const CandlestickChartStyle(),
      );

      expect(geometry.length, inInclusiveRange(1000, 1002));
      expect(geometry.first.pointIndex, inInclusiveRange(24999, 25000));
      expect(geometry.last.pointIndex, inInclusiveRange(25999, 26000));
    });

    test('groups dense OHLC while retaining every represented source', () {
      final points = [
        _candle(x: 0, open: 10, high: 12, low: 8, close: 11),
        _candle(x: 1, open: 11, high: 15, low: 9, close: 14),
        _candle(x: 2, open: 14, high: 16, low: 7, close: 8),
        _candle(x: 3, open: 8, high: 13, low: 6, close: 12),
        _candle(x: 4, open: 12, high: 17, low: 10, close: 16),
        _candle(x: 5, open: 16, high: 18, low: 11, close: 13),
      ];
      final projections = CandlestickDensityProjector.project(
        index: CandlestickViewportIndex(points),
        xMin: 0,
        xMax: 5,
        plotWidth: 10,
        grouping: const CandlestickDensityGrouping(enabled: true),
      );

      expect(projections, hasLength(2));
      expect(projections.first.groupKey, '0:3');
      expect(projections.first.sourcePointIndices, [0, 1, 2]);
      expect(projections.first.point.x, 0);
      expect(projections.first.point.open, 10);
      expect(projections.first.point.high, 16);
      expect(projections.first.point.low, 7);
      expect(projections.first.point.close, 8);
      expect(projections.last.sourcePointIndices, [3, 4, 5]);
    });

    test('keeps the raw projection when density grouping is disabled', () {
      final projections = CandlestickDensityProjector.project(
        index: CandlestickViewportIndex([
          for (var index = 0; index < 20; index++) _candle(x: index.toDouble()),
        ]),
        xMin: 0,
        xMax: 19,
        plotWidth: 10,
        grouping: const CandlestickDensityGrouping(),
      );

      expect(projections, hasLength(20));
      expect(projections.every((projection) => !projection.isGrouped), isTrue);
    });

    test(
      'returns no geometry when the viewport is outside the source range',
      () {
        final geometry = CandlestickGeometryEngine.resolve(
          index: CandlestickViewportIndex([_candle(x: 5)]),
          transform: const ChartTransform(
            dataXMin: 10,
            dataXMax: 20,
            dataYMin: 0,
            dataYMax: 20,
            plotWidth: 100,
            plotHeight: 100,
          ),
          style: const CandlestickChartStyle(),
        );

        expect(geometry, isEmpty);
      },
    );
  });
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 20,
  plotWidth: 1000,
  plotHeight: 200,
);

CandlestickDataPoint _candle({
  required double x,
  double open = 10,
  double high = 13,
  double low = 9,
  double close = 12,
}) =>
    CandlestickDataPoint(x: x, open: open, high: high, low: low, close: close);
