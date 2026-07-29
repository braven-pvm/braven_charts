import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapDataPoint', () {
    test('keeps position and measured value as independent channels', () {
      final point = HeatmapDataPoint(
        x: 3,
        y: 1,
        value: 92,
        pointKey: 'tuesday:marie',
        label: '92',
        metadata: const {'employee': 'Marie'},
      );

      expect(point.x, 3);
      expect(point.y, 1);
      expect(point.value, 92);
      expect(point.isMissing, isFalse);
      expect(point.isValid, isTrue);
      expect(point.identity, HeatmapCellIdentity.keyed('tuesday:marie'));
    });

    test('uses coordinates as stable identity when no key is supplied', () {
      final point = HeatmapDataPoint(x: 2.5, y: 7, value: 12);

      expect(point.identity, HeatmapCellIdentity.coordinate(2.5, 7));
      expect(
        HeatmapDataPoint(x: 2.5, y: 7, value: 99).identity,
        point.identity,
      );
    });

    test('represents missing explicitly without confusing it with zero', () {
      final missing = HeatmapDataPoint.missing(x: 4, y: 2, label: 'No sample');
      final zero = HeatmapDataPoint(x: 4, y: 3, value: 0);

      expect(missing.value, isNull);
      expect(missing.isMissing, isTrue);
      expect(missing.isValid, isTrue);
      expect(zero.value, 0);
      expect(zero.isMissing, isFalse);
    });

    test('rejects non-finite coordinates and measured values', () {
      expect(
        () => HeatmapDataPoint(x: double.nan, y: 1, value: 2),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDataPoint(x: 1, y: double.infinity, value: 2),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDataPoint(x: 1, y: 2, value: double.nan),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDataPoint.missing(x: 1, y: double.negativeInfinity),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDataPoint(x: 1, y: 2, value: 3, pointKey: ''),
        throwsArgumentError,
      );
    });

    test('copyWith preserves type and supports missing/value transitions', () {
      final source = HeatmapDataPoint(
        x: 1,
        y: 2,
        value: 10,
        pointKey: 'cell',
        label: 'source',
      );

      final changed = source.copyWith(value: 14, label: 'changed');
      final missing = changed.copyWith(makeMissing: true);
      final restored = missing.copyWith(value: 0);

      expect(changed, isA<HeatmapDataPoint>());
      expect(changed.value, 14);
      expect(changed.label, 'changed');
      expect(missing.isMissing, isTrue);
      expect(missing.identity, source.identity);
      expect(restored.value, 0);
      expect(restored.isMissing, isFalse);
      expect(
        () => source.copyWith(value: 5, makeMissing: true),
        throwsArgumentError,
      );
    });

    test('atTime keeps UTC semantic time and row coordinate', () {
      final timestamp = DateTime.parse('2026-07-28T10:30:00+02:00');
      final point = HeatmapDataPoint.atTime(
        timestamp: timestamp,
        y: 5,
        value: 18.5,
      );

      expect(point.timestamp, timestamp.toUtc());
      expect(point.x, timestamp.toUtc().millisecondsSinceEpoch.toDouble());
      expect(point.y, 5);
      expect(point.value, 18.5);
    });
  });

  group('HeatmapCellIdentity', () {
    test('distinguishes keyed identity from coordinate identity', () {
      expect(
        HeatmapCellIdentity.keyed('1:2'),
        isNot(HeatmapCellIdentity.coordinate(1, 2)),
      );
    });

    test('rejects invalid direct identities at runtime', () {
      expect(() => HeatmapCellIdentity.keyed(''), throwsArgumentError);
      expect(
        () => HeatmapCellIdentity.coordinate(double.nan, 1),
        throwsArgumentError,
      );
    });
  });
}
