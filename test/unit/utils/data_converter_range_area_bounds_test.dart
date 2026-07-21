import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/data_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('range area bounds use low/high rather than canonical midpoint', () {
    final bounds = DataConverter.computeDataBounds([
      RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint(x: 0, low: -20, high: 80),
          RangeAreaDataPoint(x: 1, low: 0, high: 120),
        ],
      ),
    ]);

    expect(bounds.yMin, lessThan(-20));
    expect(bounds.yMax, greaterThan(120));
  });

  test('gaps contribute X extent but not a fake zero Y value', () {
    final bounds = DataConverter.computeDataBounds([
      RangeAreaChartSeries(
        id: 'range',
        points: [
          RangeAreaDataPoint.gap(x: 0),
          RangeAreaDataPoint(x: 1, low: 50, high: 60),
          RangeAreaDataPoint.gap(x: 2),
        ],
      ),
    ]);

    expect(bounds.xMin, lessThan(0));
    expect(bounds.xMax, greaterThan(2));
    expect(bounds.yMin, greaterThan(45));
    expect(bounds.yMax, greaterThan(60));
  });

  test('flat single interval receives finite non-zero bounds', () {
    final bounds = DataConverter.computeDataBounds([
      RangeAreaChartSeries(
        id: 'flat',
        points: [RangeAreaDataPoint(x: 5, low: 10, high: 10)],
      ),
    ]);

    expect(bounds.xMin, lessThan(5));
    expect(bounds.xMax, greaterThan(5));
    expect(bounds.yMin, lessThan(10));
    expect(bounds.yMax, greaterThan(10));
  });
}
