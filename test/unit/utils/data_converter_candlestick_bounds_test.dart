import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('candlestick bounds use low/high rather than canonical close', () {
    final bounds = DataConverter.computeDataBounds([
      CandlestickChartSeries(
        id: 'price',
        points: [
          _candle(x: 0, open: 100, high: 125, low: 80, close: 105),
          _candle(x: 1, open: 105, high: 130, low: 95, close: 110),
        ],
      ),
    ]);

    expect(bounds.yMin, lessThan(80));
    expect(bounds.yMax, greaterThan(130));
    expect(bounds.xMin, lessThanOrEqualTo(-0.35));
    expect(bounds.xMax, greaterThanOrEqualTo(1.35));
  });

  test('flat single candle receives finite non-zero bounds', () {
    final bounds = DataConverter.computeDataBounds([
      CandlestickChartSeries(
        id: 'flat',
        points: [_candle(x: 5, open: 10, high: 10, low: 10, close: 10)],
      ),
    ]);

    expect(bounds.xMin, lessThan(5));
    expect(bounds.xMax, greaterThan(5));
    expect(bounds.yMin, lessThan(10));
    expect(bounds.yMax, greaterThan(10));
  });
}

CandlestickDataPoint _candle({
  required double x,
  required double open,
  required double high,
  required double low,
  required double close,
}) =>
    CandlestickDataPoint(x: x, open: open, high: high, low: low, close: close);
