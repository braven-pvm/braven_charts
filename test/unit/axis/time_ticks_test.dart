import 'package:braven_charts/src/axis/time_ticks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('time_ticks', () {
    test('a ~3-year span ticks on year boundaries', () {
      final jan2024 = DateTime.utc(2024).millisecondsSinceEpoch.toDouble();
      final jan2027 = DateTime.utc(2027).millisecondsSinceEpoch.toDouble();
      final ticks = dateTicks(jan2024, jan2027);
      final years = ticks.map(
        (m) => DateTime.fromMillisecondsSinceEpoch(m.toInt(), isUtc: true).year,
      );
      expect(years, containsAll([2024, 2025, 2026, 2027]));
      expect(intervalFor(jan2024, jan2027), TimeTickInterval.year);
    });

    test('labels format per interval', () {
      final m = DateTime.utc(2026, 2, 3).millisecondsSinceEpoch.toDouble();
      expect(dateLabel(m, TimeTickInterval.year), '2026');
      expect(dateLabel(m, TimeTickInterval.day), 'Feb 3');
    });
  });
}
