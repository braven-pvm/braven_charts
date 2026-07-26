import 'package:braven_charts/src/axis/log_ticks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('log_ticks', () {
    test('decadeTicks over 1..1000 base 10 are the decades', () {
      expect(decadeTicks(1, 1000), [1, 10, 100, 1000]);
    });

    test('decadeTicks base 2 over 1..8 are 1,2,4,8', () {
      expect(decadeTicks(1, 8, base: 2), [1, 2, 4, 8]);
    });

    test('logValue/logInverse round-trip', () {
      expect(logInverse(logValue(50, 10), 10), closeTo(50, 1e-9));
    });
  });
}
