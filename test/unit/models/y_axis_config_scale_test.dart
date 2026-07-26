import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('YAxisConfig defaults to a linear scale, base 10', () {
    final c = YAxisConfig(position: YAxisPosition.left);
    expect(c.scaleType, AxisScaleType.linear);
    expect(c.logBase, 10);
  });
  test('scaleType/logBase survive copyWith and equality', () {
    final c = YAxisConfig(position: YAxisPosition.left);
    final log = c.copyWith(scaleType: AxisScaleType.log, logBase: 2);
    expect(log.scaleType, AxisScaleType.log);
    expect(log.logBase, 2);
    expect(log, isNot(c));
    expect(log, c.copyWith(scaleType: AxisScaleType.log, logBase: 2));
  });
  test('withId carries scaleType', () {
    final c = YAxisConfig.withId(
      id: 'y',
      position: YAxisPosition.left,
      scaleType: AxisScaleType.log,
    );
    expect(c.scaleType, AxisScaleType.log);
  });
}
