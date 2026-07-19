import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/candlestick_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CandlestickChartSeries series(
    double open,
    double high,
    double low,
    double close,
  ) => CandlestickChartSeries(
    id: 'price',
    points: [
      CandlestickDataPoint(
        x: 1,
        open: open,
        high: high,
        low: low,
        close: close,
        timestamp: DateTime.utc(2026, 7, 19),
      ),
    ],
  );

  test('interpolates a stable OHLC identity without violating invariants', () {
    final frame = CandlestickSeriesTransition.interpolate(
      from: series(10, 14, 8, 12),
      to: series(12, 18, 9, 16),
      progress: .5,
    );
    final point = frame.candleAt(0);

    expect(point.open, 11);
    expect(point.high, 16);
    expect(point.low, 8.5);
    expect(point.close, 14);
    expect(point.timestamp, DateTime.utc(2026, 7, 19));
    expect(point.high, greaterThanOrEqualTo(point.open));
    expect(point.high, greaterThanOrEqualTo(point.close));
    expect(point.low, lessThanOrEqualTo(point.open));
    expect(point.low, lessThanOrEqualTo(point.close));
  });

  test('rejects changed X identity or sample count', () {
    final from = series(10, 14, 8, 12);
    final moved = from.copyWith(points: [from.candleAt(0).copyWith(x: 2)]);
    final appended = from.copyWith(
      points: [
        from.candleAt(0),
        CandlestickDataPoint(x: 2, open: 12, high: 13, low: 11, close: 12),
      ],
    );

    expect(CandlestickSeriesTransition.isCompatible(from, moved), isFalse);
    expect(CandlestickSeriesTransition.isCompatible(from, appended), isFalse);
  });
}
