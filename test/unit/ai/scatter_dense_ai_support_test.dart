import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds explicit screen-space Scatter clustering', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'observations',
          'data': [
            {'x': 1, 'y': 2},
            {'x': 1.1, 'y': 2.1},
          ],
        },
      ],
      'style': {
        'scatter_render_mode': 'clusters',
        'scatter_marker_radius': 4,
        'scatter_cluster_cell_size': 52,
        'scatter_cluster_minimum_points': 3,
        'scatter_cluster_minimum_radius': 9,
        'scatter_cluster_maximum_radius': 30,
        'scatter_cluster_show_labels': false,
        'scatter_cluster_label_minimum_points': 5,
        'scatter_cluster_show_zones': true,
        'scatter_cluster_zone_opacity': 0.14,
        'scatter_cluster_drill_on_tap': false,
        'scatter_cluster_drill_padding': 0.24,
      },
    });

    final series = result.series.single as ScatterChartSeries;
    expect(series.markerRadius, 4);
    expect(series.renderMode, ScatterRenderMode.clusters);
    expect(
      series.clusterConfig,
      const ScatterClusterConfig(
        cellSize: 52,
        minimumPointCount: 3,
        minimumRadius: 9,
        maximumRadius: 30,
        showCountLabels: false,
        labelMinimumPointCount: 5,
        showZones: true,
        zoneOpacity: 0.14,
        drillOnTap: false,
        drillPadding: 0.24,
      ),
    );
  });

  test('rejects unknown Scatter dense-data modes', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'scatter',
        'series': [
          {
            'id': 'observations',
            'data': [
              {'x': 1, 'y': 2},
            ],
          },
        ],
        'style': {'scatter_render_mode': 'magic'},
      }),
      throwsFormatException,
    );
  });

  test('rejects invalid Scatter cluster bounds in release-safe parsing', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'scatter',
        'series': [
          {
            'id': 'observations',
            'data': [
              {'x': 1, 'y': 2},
            ],
          },
        ],
        'style': {
          'scatter_render_mode': 'clusters',
          'scatter_cluster_cell_size': 4,
        },
      }),
      throwsFormatException,
    );
  });

  test('tool schema advertises Scatter cluster controls', () {
    final style =
        (ChartToolSchema.createChartTool['input_schema']
                as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    final styleProperties =
        (style['style'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    expect(styleProperties, contains('scatter_render_mode'));
    expect(styleProperties, contains('scatter_cluster_cell_size'));
    expect(styleProperties, contains('scatter_cluster_show_labels'));
    expect(styleProperties, contains('scatter_cluster_show_zones'));
    expect(styleProperties, contains('scatter_cluster_drill_on_tap'));
  });

  test('builds explicit Scatter hexagonal bins', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'observations',
          'data': [
            {'x': 1, 'y': 2},
          ],
        },
      ],
      'style': {
        'scatter_render_mode': 'hexbin',
        'scatter_bin_cell_size': 48,
        'scatter_bin_gap': 2,
        'scatter_bin_minimum_points': 3,
        'scatter_bin_minimum_opacity': 0.15,
        'scatter_bin_maximum_opacity': 0.9,
        'scatter_bin_aggregate': 'mean',
        'scatter_bin_value_source': 'color_value',
        'scatter_bin_show_labels': true,
        'scatter_bin_label_minimum_points': 8,
      },
    });

    final series = result.series.single as ScatterChartSeries;
    expect(series.renderMode, ScatterRenderMode.hexbin);
    expect(
      series.binConfig,
      const ScatterBinConfig(
        cellSize: 48,
        gap: 2,
        minimumPointCount: 3,
        minimumOpacity: 0.15,
        maximumOpacity: 0.9,
        aggregate: ScatterBinAggregate.mean,
        valueSource: ScatterBinValueSource.colorValue,
        showLabels: true,
        labelMinimumPointCount: 8,
      ),
    );
  });

  test('tool schema advertises Scatter bin controls', () {
    final style =
        (ChartToolSchema.createChartTool['input_schema']
                as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    final styleProperties =
        (style['style'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    expect(
      (styleProperties['scatter_render_mode'] as Map<String, dynamic>)['enum'],
      containsAll(['rectangular_bins', 'hexbin']),
    );
    expect(styleProperties, contains('scatter_bin_cell_size'));
    expect(styleProperties, contains('scatter_bin_aggregate'));
    expect(styleProperties, contains('scatter_bin_value_source'));
    expect(styleProperties, contains('scatter_bin_show_labels'));
  });

  test('rejects unknown Scatter bin aggregate and value source', () {
    Map<String, dynamic> config(Map<String, dynamic> style) => {
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'observations',
          'data': [
            {'x': 1, 'y': 2},
          ],
        },
      ],
      'style': {'scatter_render_mode': 'hexbin', ...style},
    };

    expect(
      () => ChartConfigBuilder.fromJson(
        config({'scatter_bin_aggregate': 'median'}),
      ),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson(
        config({'scatter_bin_value_source': 'metadata'}),
      ),
      throwsFormatException,
    );
  });

  test('builds explicit Scatter density contours', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'observations',
          'data': [
            {'x': 1, 'y': 2},
          ],
        },
      ],
      'style': {
        'scatter_render_mode': 'density',
        'scatter_density_grid_cell_size': 6,
        'scatter_density_bandwidth': 28,
        'scatter_density_contour_count': 7,
        'scatter_density_minimum': 0.12,
        'scatter_density_minimum_opacity': 0.22,
        'scatter_density_maximum_opacity': 0.84,
        'scatter_density_line_width': 2.5,
        'scatter_density_show_points': true,
      },
    });

    final series = result.series.single as ScatterChartSeries;
    expect(series.renderMode, ScatterRenderMode.density);
    expect(
      series.densityConfig,
      const ScatterDensityConfig(
        gridCellSize: 6,
        bandwidth: 28,
        contourCount: 7,
        minimumDensity: 0.12,
        minimumOpacity: 0.22,
        maximumOpacity: 0.84,
        lineWidth: 2.5,
        showPoints: true,
      ),
    );
  });

  test('tool schema advertises Scatter density controls', () {
    final style =
        (ChartToolSchema.createChartTool['input_schema']
                as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    final styleProperties =
        (style['style'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>;
    expect(
      (styleProperties['scatter_render_mode'] as Map<String, dynamic>)['enum'],
      contains('density'),
    );
    expect(styleProperties, contains('scatter_density_grid_cell_size'));
    expect(styleProperties, contains('scatter_density_bandwidth'));
    expect(styleProperties, contains('scatter_density_contour_count'));
    expect(styleProperties, contains('scatter_density_show_points'));
  });

  test('rejects invalid Scatter density bounds', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'scatter',
        'series': [
          {
            'id': 'observations',
            'data': [
              {'x': 1, 'y': 2},
            ],
          },
        ],
        'style': {
          'scatter_render_mode': 'density',
          'scatter_density_contour_count': 1,
        },
      }),
      throwsFormatException,
    );
  });
}
