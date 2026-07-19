import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesElement Candlestick rendering', () {
    test('materializes only candles overlapping the current viewport', () {
      final element = SeriesElement(
        series: _denseSeries(),
        transform: _transform(5000, 5010),
      );

      expect(element.visibleCandlestickGeometryCount, lessThan(20));
      expect(
        element.visibleCandlestickPointIndices,
        containsAll([5000, 5005, 5010]),
      );
      expect(element.candlestickGeometryForPoint(0), isNull);
      expect(element.candlestickGeometryForPoint(5005), isNotNull);
    });

    test('re-resolves visible source indices after a viewport pan', () {
      final element = SeriesElement(
        series: _denseSeries(),
        transform: _transform(2000, 2010),
      );

      expect(element.visibleCandlestickPointIndices, contains(2005));
      element.updateTransform(_transform(8000, 8010));

      expect(element.visibleCandlestickGeometryCount, lessThan(20));
      expect(element.visibleCandlestickPointIndices, contains(8005));
      expect(element.candlestickGeometryForPoint(2005), isNull);
    });

    test('hits the body first and retains the original source reference', () {
      final series = _smallSeries();
      final element = SeriesElement(
        series: series,
        transform: _transform(0, 4),
      );
      final geometry = element.candlestickGeometryForPoint(2)!;

      final resolved = element.candlestickGeometryAt(geometry.bodyRect.center);
      final hit = element.dataHitAt(geometry.bodyRect.center);

      expect(resolved?.pointIndex, 2);
      expect(hit?.pointIndex, 2);
      expect(hit?.point, same(series.candleAt(2)));
      expect(hit?.plotPosition, geometry.bodyRect.center);
      expect(hit?.formattedValue, '104.00 USD');
      expect(element.candlestickHitComparisonCount, lessThan(10));
    });

    test('keeps a thin wick and doji body accessible', () {
      final element = SeriesElement(
        series: _smallSeries(),
        transform: _transform(0, 4),
      );
      final wick = element.candlestickGeometryForPoint(1)!;
      final doji = element.candlestickGeometryForPoint(3)!;

      expect(element.candlestickGeometryAt(wick.upperWickStart)?.pointIndex, 1);
      expect(
        element.candlestickGeometryAt(doji.bodyRect.center)?.pointIndex,
        3,
      );
    });

    test('exposes complete OHLC semantic data hits for visible candles', () {
      final element = SeriesElement(
        series: _smallSeries(),
        transform: _transform(0, 4),
      );

      final hits = element.semanticDataHits.toList();
      expect(hits, hasLength(5));
      expect(hits.first.candlestick?.open, 100);
      expect(hits.first.candlestick?.high, 108);
      expect(hits.first.candlestick?.low, 98);
      expect(hits.first.candlestick?.close, 106);
      expect(hits.first.semanticLabel, contains('Open 100.00 USD'));
      expect(hits.first.semanticLabel, contains('rising'));
    });

    test('paints batched uniforms and per-point overrides', () async {
      final uniform = SeriesElement(
        series: _smallSeries(),
        transform: _transform(0, 4),
        candlestickTheme: CandlestickTheme.colorblindFriendly,
        selectedPointIndices: const {1},
        focusedPointIndices: const {2},
      );
      final overrideSeries = _smallSeries().copyWith(
        points: [
          ..._smallSeries().candles.take(2),
          _smallSeries()
              .candleAt(2)
              .copyWith(
                candlestickStyle: const CandlestickPointStyle(
                  bodyFillColor: Color(0xFFFF00FF),
                  borderColor: Color(0xFF111111),
                  wickColor: Color(0xFF111111),
                ),
              ),
          ..._smallSeries().candles.skip(3),
        ],
      );
      final override = SeriesElement(
        series: overrideSeries,
        transform: _transform(0, 4),
      );

      expect(await _paintedPixelCount(uniform), greaterThan(20));
      expect(await _paintedPixelCount(override), greaterThan(20));
    });
  });
}

Future<int> _paintedPixelCount(SeriesElement element) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  element.paint(canvas, const Size(400, 240));
  final image = await recorder.endRecording().toImage(400, 240);
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
  image.dispose();
  var count = 0;
  for (var index = 3; index < bytes!.lengthInBytes; index += 4) {
    if (bytes.getUint8(index) != 0) count++;
  }
  return count;
}

CandlestickChartSeries _smallSeries() => CandlestickChartSeries(
  id: 'ohlc',
  name: 'OHLC',
  unit: 'USD',
  points: [
    CandlestickDataPoint(x: 0, open: 100, high: 108, low: 98, close: 106),
    CandlestickDataPoint(x: 1, open: 106, high: 110, low: 99, close: 101),
    CandlestickDataPoint(x: 2, open: 101, high: 107, low: 100, close: 104),
    CandlestickDataPoint(x: 3, open: 104, high: 109, low: 102, close: 104),
    CandlestickDataPoint(x: 4, open: 104, high: 112, low: 103, close: 110),
  ],
);

CandlestickChartSeries _denseSeries() => CandlestickChartSeries(
  id: 'dense-ohlc',
  points: [
    for (var index = 0; index < 10000; index++)
      CandlestickDataPoint(
        x: index.toDouble(),
        open: 100 + (index % 7),
        high: 109 + (index % 7),
        low: 96 + (index % 7),
        close: 104 + (index % 7),
      ),
  ],
);

ChartTransform _transform(double xMin, double xMax) => ChartTransform(
  dataXMin: xMin,
  dataXMax: xMax,
  dataYMin: 90,
  dataYMax: 120,
  plotWidth: 400,
  plotHeight: 240,
);
