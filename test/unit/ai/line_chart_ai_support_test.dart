import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI builder reads line_interpolation for a Line series', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'line',
      'series': [
        {
          'id': 'temp',
          'data': [
            {'x': 0, 'y': 20},
            {'x': 1, 'y': 22},
          ],
        },
      ],
      'style': {'line_interpolation': 'monotone'},
    });

    final series = result.series.single as LineChartSeries;
    expect(series.interpolation, LineInterpolation.monotone);
  });

  test('AI builder reads line_interpolation for an Area series', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'area',
      'series': [
        {
          'id': 'temp',
          'style': 'area',
          'data': [
            {'x': 0, 'y': 20},
            {'x': 1, 'y': 22},
          ],
        },
      ],
      'style': {'line_interpolation': 'stepped'},
    });

    final series = result.series.single as AreaChartSeries;
    expect(series.interpolation, LineInterpolation.stepped);
  });

  test('AI builder defaults Line interpolation to linear when absent', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'line',
      'series': [
        {
          'id': 'temp',
          'data': [
            {'x': 0, 'y': 20},
            {'x': 1, 'y': 22},
          ],
        },
      ],
    });

    final series = result.series.single as LineChartSeries;
    expect(series.interpolation, LineInterpolation.linear);
  });
}
