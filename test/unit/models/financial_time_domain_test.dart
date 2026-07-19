import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final friday = DateTime.utc(2026, 7, 17);
  final monday = DateTime.utc(2026, 7, 20);
  final tuesday = DateTime.utc(2026, 7, 21);

  group('FinancialTimeDomain', () {
    test('preserves equal ordinal slots and elapsed weekend gaps', () {
      final domain = FinancialTimeDomain([friday, monday, tuesday]);

      expect(domain.xAt(1, FinancialTimeSpacing.ordinal), 1);
      expect(
        domain.xAt(1, FinancialTimeSpacing.elapsed) -
            domain.xAt(0, FinancialTimeSpacing.elapsed),
        const Duration(days: 3).inMilliseconds,
      );
      expect(
        domain.xAt(2, FinancialTimeSpacing.elapsed) -
            domain.xAt(1, FinancialTimeSpacing.elapsed),
        const Duration(days: 1).inMilliseconds,
      );
    });

    test('resolves the nearest session with stable earlier tie breaking', () {
      final domain = FinancialTimeDomain([friday, monday, tuesday]);
      final midpoint =
          (friday.millisecondsSinceEpoch + monday.millisecondsSinceEpoch) / 2;

      expect(domain.nearestIndex(1.49, FinancialTimeSpacing.ordinal), 1);
      expect(domain.nearestIndex(midpoint, FinancialTimeSpacing.elapsed), 0);
      expect(
        domain.nearestIndex(
          monday.millisecondsSinceEpoch + 1,
          FinancialTimeSpacing.elapsed,
        ),
        1,
      );
    });

    test('formats through a runtime-supplied locale binding', () {
      final domain = FinancialTimeDomain([friday, monday]);

      expect(
        domain.formatX(
          1,
          FinancialTimeSpacing.ordinal,
          formatter: (timestamp) => '${timestamp.day}/${timestamp.month}',
        ),
        '20/7',
      );
    });

    test('rejects duplicate and unordered sessions', () {
      expect(() => FinancialTimeDomain([monday, friday]), throwsArgumentError);
      expect(() => FinancialTimeDomain([friday, friday]), throwsArgumentError);
    });
  });
}
