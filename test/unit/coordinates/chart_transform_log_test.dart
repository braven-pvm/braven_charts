import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/axis_scale_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a y-log transform positions the geometric midpoint at value = '
    'sqrt(min*max)',
    () {
      const t = ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 1,
        dataYMax: 100,
        plotWidth: 100,
        plotHeight: 100,
        yScaleType: AxisScaleType.log,
      );
      // value 10 is the log-midpoint of [1,100] → relativeY 0.5 → invertY →
      // plotY 50.
      expect(t.dataToPlot(0, 10).dy, closeTo(50, 1e-6));
      // linear x is unchanged:
      expect(t.dataToPlot(5, 10).dx, closeTo(50, 1e-6));
    },
  );
  test('plotToData inverts the y-log mapping', () {
    const t = ChartTransform(
      dataXMin: 0,
      dataXMax: 10,
      dataYMin: 1,
      dataYMax: 100,
      plotWidth: 100,
      plotHeight: 100,
      yScaleType: AxisScaleType.log,
    );
    expect(t.plotToData(50, 50).dy, closeTo(10, 1e-6));
  });
  test('a linear transform is byte-identical (regression)', () {
    const t = ChartTransform(
      dataXMin: 0,
      dataXMax: 10,
      dataYMin: 0,
      dataYMax: 100,
      plotWidth: 100,
      plotHeight: 100,
    );
    expect(t.dataToPlot(5, 50), const Offset(50, 50));
  });
}
