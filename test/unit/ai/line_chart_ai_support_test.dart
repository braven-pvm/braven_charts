import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI builder reads X-axis placement and tick-label rotation', () {
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
      'x_axis': {'position': 'both', 'tick_label_rotation': -35},
    });

    expect(result.xAxisConfig?.position, XAxisPosition.both);
    expect(result.xAxisConfig?.tickLabelRotationDegrees, -35);
  });

  test('AI builder rejects an unknown X-axis position', () {
    expect(
      () => ChartConfigBuilder.fromJson({
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
        'x_axis': {'position': 'middle'},
      }),
      throwsFormatException,
    );
  });

  test('tool schema advertises X-axis placement and rotation', () {
    final input =
        ChartToolSchema.createChartTool['input_schema'] as Map<String, dynamic>;
    final properties = input['properties'] as Map<String, dynamic>;
    final xAxis =
        (properties['x_axis'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;

    expect((xAxis['position'] as Map<String, dynamic>)['enum'], [
      'bottom',
      'top',
      'both',
    ]);
    expect(xAxis, contains('tick_label_rotation'));
  });

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
