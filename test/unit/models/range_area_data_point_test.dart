import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeAreaDataPoint', () {
    test('uses midpoint as canonical y and exposes interval measures', () {
      final point = RangeAreaDataPoint(x: 3, low: 8, high: 14);

      expect(point.y, 11);
      expect(point.midpoint, 11);
      expect(point.span, 6);
      expect(point.isGap, isFalse);
      expect(point.isValid, isTrue);
    });

    test('represents a gap explicitly without inventing an interval', () {
      final gap = RangeAreaDataPoint.gap(x: 4, label: 'missing');

      expect(gap.isGap, isTrue);
      expect(gap.low, isNull);
      expect(gap.high, isNull);
      expect(gap.midpoint, isNull);
      expect(gap.span, isNull);
      expect(gap.isValid, isTrue);
      expect(gap.label, 'missing');
    });

    test('rejects non-finite coordinates and inverted intervals', () {
      expect(
        () => RangeAreaDataPoint(x: double.nan, low: 1, high: 2),
        throwsArgumentError,
      );
      expect(
        () => RangeAreaDataPoint(x: 1, low: double.infinity, high: 2),
        throwsArgumentError,
      );
      expect(
        () => RangeAreaDataPoint(x: 1, low: 3, high: 2),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'rangeArea.high',
          ),
        ),
      );
      expect(
        () => RangeAreaDataPoint.gap(x: double.infinity),
        throwsArgumentError,
      );
    });

    test('copyWith preserves typed midpoint and can create or fill a gap', () {
      final source = RangeAreaDataPoint(x: 1, low: 10, high: 14);
      final changed = source.copyWith(low: 12, high: 18);
      final gap = changed.copyWith(makeGap: true);
      final filled = gap.copyWith(low: 20, high: 24);

      expect(changed, isA<RangeAreaDataPoint>());
      expect(changed.y, 15);
      expect(gap.isGap, isTrue);
      expect(filled.isGap, isFalse);
      expect(filled.y, 22);
      expect(() => gap.copyWith(low: 20), throwsArgumentError);
      expect(() => source.copyWith(y: 99), throwsArgumentError);
    });

    test('atTime uses UTC epoch milliseconds and semantic time', () {
      final local = DateTime.parse('2026-07-21T10:30:00+02:00');
      final point = RangeAreaDataPoint.atTime(
        timestamp: local,
        low: 2,
        high: 8,
      );

      expect(point.timestamp, local.toUtc());
      expect(point.x, local.toUtc().millisecondsSinceEpoch.toDouble());
    });
  });
}
