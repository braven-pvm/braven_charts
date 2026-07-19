import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandlestickDataPoint', () {
    test('keeps close as canonical y and reports direction', () {
      final rising = CandlestickDataPoint(
        x: 1,
        open: 10,
        high: 13,
        low: 9,
        close: 12,
      );
      final falling = CandlestickDataPoint(
        x: 2,
        open: 12,
        high: 13,
        low: 9,
        close: 10,
      );
      final doji = CandlestickDataPoint(
        x: 3,
        open: 11,
        high: 13,
        low: 9,
        close: 11,
      );

      expect(rising.y, rising.close);
      expect(rising.direction, CandlestickDirection.rising);
      expect(falling.direction, CandlestickDirection.falling);
      expect(doji.direction, CandlestickDirection.doji);
    });

    test('rejects non-finite and invalid OHLC values without clamping', () {
      expect(
        () => CandlestickDataPoint(
          x: 1,
          open: 10,
          high: double.nan,
          low: 9,
          close: 10,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => CandlestickDataPoint(x: 1, open: 10, high: 9, low: 8, close: 10),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'candlestick.high',
          ),
        ),
      );
      expect(
        () =>
            CandlestickDataPoint(x: 1, open: 10, high: 12, low: 11, close: 10),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'candlestick.low',
          ),
        ),
      );
    });

    test('copyWith keeps y and close coupled', () {
      final source = CandlestickDataPoint(
        x: 1,
        open: 10,
        high: 14,
        low: 8,
        close: 12,
      );

      final changed = source.copyWith(y: 13, high: 15);
      expect(changed.close, 13);
      expect(changed.y, 13);
      expect(() => source.copyWith(y: 11, close: 12), throwsArgumentError);
    });

    test('atTime uses UTC epoch milliseconds and retains semantic time', () {
      final local = DateTime.parse('2026-07-19T10:30:00+02:00');
      final point = CandlestickDataPoint.atTime(
        timestamp: local,
        open: 10,
        high: 12,
        low: 9,
        close: 11,
      );

      expect(point.timestamp, local.toUtc());
      expect(point.x, local.toUtc().millisecondsSinceEpoch.toDouble());
    });
  });
}
