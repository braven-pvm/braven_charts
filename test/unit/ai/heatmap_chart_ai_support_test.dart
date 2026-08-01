import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI builder creates typed Heatmap cells, scale, and presentation', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'heatmap',
      'series': [
        {
          'id': 'temperature',
          'name': 'Temperature',
          'type': 'heatmap',
          'unit': '°C',
          'heatmap_color_scale': {
            'type': 'sequential',
            'colors': ['#EFF6FF', '#2563EB', '#172554'],
            'minimum': 0,
            'maximum': 40,
            'missing_color': '#CBD5E1',
            'label': 'Temperature',
            'unit': '°C',
            'show_legend': false,
          },
          'heatmap_empty_value_style': {
            'value': 0,
            'fill_color': '#E5E7EB',
            'border_color': '#D1D5DB',
            'border_width': 0.8,
            'show_label': true,
            'show_in_legend': true,
            'legend_label': 'No contributions',
          },
          'heatmap_value_filter': {
            'minimum_value': 10,
            'maximum_value': 30,
            'mode': 'hide',
            'excluded_opacity': 0.2,
          },
          'heatmap_cell_width': 0.8,
          'heatmap_cell_height': 0.9,
          'heatmap_gap_fraction': 0.12,
          'heatmap_border_color': '#FFFFFF',
          'heatmap_border_width': 1.5,
          'heatmap_corner_radius': 3,
          'heatmap_show_cell_labels': true,
          'heatmap_cell_label_color': '#111827',
          'heatmap_cell_label_font_size': 10,
          'data': [
            {
              'x': 0,
              'y': 0,
              'value': 18.5,
              'point_key': 'monday-am',
              'label': '18.5 °C',
              'timestamp': '2026-07-29T08:00:00Z',
              'bounds': {
                'x_minimum': -0.4,
                'x_maximum': 0.6,
                'y_minimum': -0.3,
                'y_maximum': 0.4,
              },
            },
            {
              'x': 1,
              'y': 0,
              'missing': true,
              'point_key': 'tuesday-am',
              'label': 'No sample',
            },
          ],
        },
      ],
    });

    expect(result.series, hasLength(1));
    final series = result.series.single as HeatmapChartSeries;
    expect(series.id, 'temperature');
    expect(series.name, 'Temperature');
    expect(series.unit, '°C');
    expect(series.cells, hasLength(2));
    expect(series.cells.first.value, 18.5);
    expect(series.cells.first.pointKey, 'monday-am');
    expect(series.cells.first.label, '18.5 °C');
    expect(series.cells.first.timestamp, DateTime.utc(2026, 7, 29, 8));
    expect(
      series.cells.first.bounds,
      HeatmapCellBounds(
        xMinimum: -0.4,
        xMaximum: 0.6,
        yMinimum: -0.3,
        yMaximum: 0.4,
      ),
    );
    expect(series.cells.last.isMissing, isTrue);
    expect(series.cells.last.value, isNull);
    expect(series.cells.last.pointKey, 'tuesday-am');

    expect(series.colorScale.type, HeatmapColorScaleType.sequential);
    expect(series.colorScale.colors, hasLength(3));
    expect(series.colorScale.minimumValue, 0);
    expect(series.colorScale.maximumValue, 40);
    expect(series.colorScale.missingColor, const Color(0xFFCBD5E1));
    expect(series.colorScale.label, 'Temperature');
    expect(series.colorScale.unit, '°C');
    expect(series.colorScale.showLegend, isFalse);
    expect(series.cellWidth, 0.8);
    expect(series.cellHeight, 0.9);
    expect(series.gapFraction, 0.12);
    expect(series.borderColor, const Color(0xFFFFFFFF));
    expect(series.borderWidth, 1.5);
    expect(series.cornerRadius, 3);
    expect(series.showCellLabels, isTrue);
    expect(series.cellLabelColor, const Color(0xFF111827));
    expect(series.cellLabelFontSize, 10);
    expect(
      series.emptyValueStyle,
      const HeatmapEmptyValueStyle(
        fillColor: Color(0xFFE5E7EB),
        borderColor: Color(0xFFD1D5DB),
        borderWidth: 0.8,
        showLabel: true,
        showInLegend: true,
        legendLabel: 'No contributions',
      ),
    );
    expect(
      series.valueFilter,
      const HeatmapValueFilter(
        minimumValue: 10,
        maximumValue: 30,
        mode: HeatmapValueFilterMode.hide,
        excludedOpacity: 0.2,
      ),
    );
  });

  test('AI builder preserves independent scales for multiple Heatmaps', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'heatmap',
      'series': [
        {
          'id': 'latency-axis',
          'name': 'Latency',
          'type': 'heatmap',
          'unit': 'ms',
          'heatmap_color_scale': {
            'type': 'sequential',
            'colors': ['#E0F2FE', '#075985'],
            'minimum': 35,
            'maximum': 100,
            'label': 'Latency',
            'unit': 'ms',
          },
          'data': [
            {'x': 0, 'y': 0, 'value': 42},
          ],
        },
        {
          'id': 'error-rate-axis',
          'name': 'Error rate',
          'type': 'heatmap',
          'unit': '%',
          'heatmap_color_scale': {
            'type': 'sequential',
            'colors': ['#FFF7ED', '#C2410C'],
            'minimum': 0,
            'maximum': 3,
            'label': 'Error rate',
            'unit': '%',
          },
          'data': [
            {'x': 0, 'y': 1, 'value': 1.8},
          ],
        },
      ],
    });

    expect(result.series, hasLength(2));
    final latency = result.series[0] as HeatmapChartSeries;
    final errors = result.series[1] as HeatmapChartSeries;
    expect((latency.id, latency.unit), ('latency-axis', 'ms'));
    expect(latency.colorScale.minimumValue, 35);
    expect(latency.colorScale.maximumValue, 100);
    expect((errors.id, errors.unit), ('error-rate-axis', '%'));
    expect(errors.colorScale.minimumValue, 0);
    expect(errors.colorScale.maximumValue, 3);
  });

  test('AI builder creates diverging and threshold Heatmap scales', () {
    final diverging = _build(
      scale: {
        'type': 'diverging',
        'low_color': '#2563EB',
        'midpoint_color': '#F8FAFC',
        'high_color': '#DC2626',
        'minimum': -20,
        'midpoint': 0,
        'maximum': 20,
        'reverse': true,
      },
    ).colorScale;
    expect(diverging.type, HeatmapColorScaleType.diverging);
    expect(diverging.colors, [
      const Color(0xFF2563EB),
      const Color(0xFFF8FAFC),
      const Color(0xFFDC2626),
    ]);
    expect(diverging.midpoint, 0);
    expect(diverging.reverse, isTrue);

    final threshold = _build(
      scale: {
        'type': 'threshold',
        'thresholds': [10, 20],
        'colors': ['#DCFCE7', '#FDE68A', '#FCA5A5'],
        'band_labels': ['Low', 'Expected', 'High'],
      },
    ).colorScale;
    expect(threshold.type, HeatmapColorScaleType.threshold);
    expect(threshold.thresholds, [10, 20]);
    expect(threshold.bandLabels, ['Low', 'Expected', 'High']);
  });

  test('AI builder requires Heatmap scale and independent cell value', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'series': [
          {
            'id': 'matrix',
            'type': 'heatmap',
            'data': [
              {'x': 0, 'y': 0, 'value': 1},
            ],
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('heatmap_color_scale'),
        ),
      ),
    );

    expect(
      () => _build(
        data: [
          {'x': 0, 'y': 0},
        ],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('numeric value'),
        ),
      ),
    );
  });

  test('AI builder rejects contradictory missing Heatmap cells', () {
    expect(
      () => _build(
        data: [
          {'x': 0, 'y': 0, 'missing': true, 'value': 0},
        ],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('cannot include a value'),
        ),
      ),
    );
  });

  test('AI builder rejects incomplete Heatmap cell bounds', () {
    expect(
      () => _build(
        data: [
          {
            'x': 0,
            'y': 0,
            'value': 1,
            'bounds': {'x_minimum': -0.5, 'x_maximum': 0.5, 'y_minimum': -0.5},
          },
        ],
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('y_maximum'),
        ),
      ),
    );
  });

  test('AI builder rejects malformed Heatmap scale and colors', () {
    expect(
      () => _build(
        scale: {
          'type': 'threshold',
          'thresholds': [20, 10],
          'colors': ['#DCFCE7', '#FDE68A', '#FCA5A5'],
        },
      ),
      throwsArgumentError,
    );

    expect(
      () => _build(
        scale: {
          'type': 'sequential',
          'colors': ['#FFFFFF', 'definitely-not-a-color'],
        },
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('tool schema advertises Heatmap data, scale, and styling', () {
    final input =
        ChartToolSchema.createChartTool['input_schema']!
            as Map<String, dynamic>;
    final properties = input['properties']! as Map<String, dynamic>;
    final chartType = properties['chart_type']! as Map<String, dynamic>;
    final series = properties['series']! as Map<String, dynamic>;
    final seriesItem = series['items']! as Map<String, dynamic>;
    final seriesProperties = seriesItem['properties']! as Map<String, dynamic>;
    final type = seriesProperties['type']! as Map<String, dynamic>;
    final scale =
        seriesProperties['heatmap_color_scale']! as Map<String, dynamic>;
    final scaleProperties = scale['properties']! as Map<String, dynamic>;
    final data = seriesProperties['data']! as Map<String, dynamic>;
    final point = data['items']! as Map<String, dynamic>;
    final pointProperties = point['properties']! as Map<String, dynamic>;

    expect(chartType['enum'], contains('heatmap'));
    expect(type['enum'], contains('heatmap'));
    expect(
      seriesProperties.keys,
      containsAll([
        'heatmap_color_scale',
        'heatmap_empty_value_style',
        'heatmap_cell_width',
        'heatmap_cell_height',
        'heatmap_gap_fraction',
        'heatmap_border_color',
        'heatmap_border_width',
        'heatmap_corner_radius',
        'heatmap_show_cell_labels',
        'heatmap_cell_label_color',
        'heatmap_cell_label_font_size',
      ]),
    );
    expect(
      scaleProperties.keys,
      containsAll([
        'type',
        'colors',
        'low_color',
        'midpoint_color',
        'high_color',
        'midpoint',
        'thresholds',
        'band_labels',
        'minimum',
        'maximum',
        'missing_color',
      ]),
    );
    expect(
      pointProperties.keys,
      containsAll(['x', 'y', 'value', 'missing', 'bounds']),
    );
    final bounds = pointProperties['bounds']! as Map<String, dynamic>;
    expect(bounds['required'], [
      'x_minimum',
      'x_maximum',
      'y_minimum',
      'y_maximum',
    ]);
  });
}

HeatmapChartSeries _build({
  Map<String, dynamic>? scale,
  List<Map<String, dynamic>>? data,
}) {
  final result = ChartConfigBuilder.fromJson({
    'series': [
      {
        'id': 'matrix',
        'type': 'heatmap',
        'heatmap_color_scale':
            scale ??
            {
              'type': 'sequential',
              'colors': ['#EFF6FF', '#2563EB'],
            },
        'data':
            data ??
            [
              {'x': 0, 'y': 0, 'value': 1},
            ],
      },
    ],
  });
  return result.series.single as HeatmapChartSeries;
}
