import 'package:braven_charts/braven_charts.dart';
import 'package:test/test.dart';

void main() {
  group('AxisSwapMode', () {
    test('has two values', () {
      expect(AxisSwapMode.values, hasLength(2));
      expect(AxisSwapMode.values, containsAll([
        AxisSwapMode.sticky,
        AxisSwapMode.revert,
      ]));
    });
  });
}
