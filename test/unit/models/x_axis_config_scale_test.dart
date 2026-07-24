import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('XAxisConfig defaults to a linear scale, base 10', () {
    const c = XAxisConfig(label: 'x');
    expect(c.scaleType, AxisScaleType.linear);
    expect(c.logBase, 10);
  });
  test('scaleType/logBase survive copyWith and equality', () {
    const c = XAxisConfig(label: 'x');
    final log = c.copyWith(scaleType: AxisScaleType.log, logBase: 2);
    expect(log.scaleType, AxisScaleType.log);
    expect(log.logBase, 2);
    expect(log, isNot(c));
    expect(log, c.copyWith(scaleType: AxisScaleType.log, logBase: 2));
  });
}
