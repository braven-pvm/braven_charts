import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarRacePeriodFormat', () {
    test('expands portable date and authored-label tokens', () {
      final frame = BarRaceFrame(
        id: 'jan-1965',
        label: 'January checkpoint',
        timestamp: DateTime(1965, 1, 7, 9, 5, 3),
        values: {'a': 1},
      );

      expect(
        const BarRacePeriodFormat(
          pattern: '{label} · {MMM} {d}, {yyyy}',
        ).format(frame),
        'January checkpoint · Jan 7, 1965',
      );
      expect(
        const BarRacePeriodFormat(pattern: '{yyyy}-{MM}-{dd}').format(frame),
        '1965-01-07',
      );
      expect(
        const BarRacePeriodFormat(
          pattern: '{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}',
        ).format(frame),
        '1965-01-07 09:05:03',
      );
    });

    test('falls back to frame label when timestamp is unavailable', () {
      const frame = BarRaceFrame(
        id: 'step-one',
        label: 'Simulation step 1',
        values: {'a': 1},
      );

      expect(
        const BarRacePeriodFormat(pattern: '{MMMM} {yyyy}').format(frame),
        'Simulation step 1',
      );
    });
  });

  group('BarRaceValueFormat', () {
    test('groups, scales, and embeds standard values in custom text', () {
      const format = BarRaceValueFormat(
        pattern: r'$ {value}M residents',
        decimalPlaces: 2,
        scale: 1000,
      );

      expect(format.format(1234567), r'$ 1,234.57M residents');
    });

    test('supports compact and scientific notation', () {
      expect(
        const BarRaceValueFormat(
          notation: BarRaceValueNotation.compact,
          decimalPlaces: 1,
        ).format(1250000),
        '1.3M',
      );
      expect(
        const BarRaceValueFormat(
          notation: BarRaceValueNotation.scientific,
          decimalPlaces: 2,
          pattern: '{value} kg',
        ).format(1250),
        '1.25e+3 kg',
      );
    });

    test('can preserve trailing zeros and disable grouping', () {
      expect(
        const BarRaceValueFormat(
          decimalPlaces: 2,
          useGrouping: false,
          trimTrailingZeros: false,
        ).format(1200),
        '1200.00',
      );
    });
  });
}
