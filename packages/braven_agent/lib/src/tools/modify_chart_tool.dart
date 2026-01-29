import 'dart:convert';

import '../models/chart_configuration.dart';
import '../models/data_point.dart';
import '../models/enums.dart';
import '../models/series_config.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for modifying existing chart configurations.
///
/// This tool applies incremental changes to an existing chart configuration
/// obtained through a callback function. Unlike [CreateChartTool] which builds
/// new charts from scratch, ModifyChartTool updates specific properties while
/// preserving unchanged ones.
///
/// The tool uses a callback architecture where it queries the active chart
/// from the session at execution time, ensuring it always works with the
/// current chart state.
///
/// ## Example Usage (LLM perspective)
///
/// ```json
/// {
///   "modifications": {
///     "type": "bar",
///     "title": "Updated Title",
///     "addSeries": [{
///       "id": "new_series",
///       "data": [{"x": 0, "y": 10}]
///     }]
///   }
/// }
/// ```
///
/// ## Architecture
///
/// Instead of a static registry, ModifyChartTool uses dependency injection:
/// the session provides a callback function that returns the current active
/// chart at execution time. This allows:
/// - Direct integration with AgentSession without manual registration
/// - Always working with the session's current chart state
/// - Clean separation of concerns
/// - Testability through callback injection
///
/// ## Output
///
/// Returns a [ToolResult] with:
/// - `output`: String describing the modification result
/// - `data`: [ChartConfiguration] object with applied modifications
/// - `isError`: true if no active chart exists or input validation fails
class ModifyChartTool extends AgentTool {
  /// Callback function that returns the currently active chart.
  ///
  /// The session provides this function at construction time. The tool
  /// calls it during execute() to get the current chart to modify.
  /// Returns null if no active chart exists.
  final ChartConfiguration? Function() _getActiveChart;

  /// Creates a [ModifyChartTool] that modifies the active chart.
  ///
  /// [getActiveChart] is a required callback that the tool uses to retrieve
  /// the current active chart at execution time.
  ModifyChartTool({required ChartConfiguration? Function() getActiveChart}) : _getActiveChart = getActiveChart;
  @override
  String get name => 'modify_chart';

  @override
  String get description => 'Modifies the currently active chart by applying partial updates. '
      'Use this tool to change chart type, update titles, add/remove series, '
      'or adjust styling options. Requires an active chart created previously.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'modifications': {
            'type': 'object',
            'description': 'Partial chart configuration to merge',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['line', 'area', 'bar', 'scatter'],
                'description': 'New chart type',
              },
              'title': {
                'type': 'string',
                'description': 'New title for the chart',
              },
              'subtitle': {
                'type': 'string',
                'description': 'New subtitle for the chart',
              },
              'series': {
                'type': 'array',
                'description': 'Replace all series with this array',
              },
              'addSeries': {
                'type': 'array',
                'description': 'Series to add to the existing chart',
                'items': {
                  'type': 'object',
                  'properties': {
                    'id': {
                      'type': 'string',
                      'description': 'Unique identifier for this series',
                    },
                    'name': {
                      'type': 'string',
                      'description': 'Display name for the series',
                    },
                    'color': {
                      'type': 'string',
                      'description': 'Color for the series (hex string)',
                    },
                    'data': {
                      'type': 'array',
                      'description': 'Data points in this series',
                      'items': {
                        'type': 'object',
                        'properties': {
                          'x': {
                            'type': 'number',
                            'description': 'X coordinate',
                          },
                          'y': {
                            'type': 'number',
                            'description': 'Y coordinate',
                          },
                        },
                        'required': ['x', 'y'],
                      },
                    },
                  },
                  'required': ['id', 'data'],
                },
              },
              'removeSeries': {
                'type': 'array',
                'description': 'IDs of series to remove from the chart',
                'items': {
                  'type': 'string',
                },
              },
              'updateSeries': {
                'type': 'object',
                'description': 'Map of series ID to partial update (e.g., new data points)',
              },
              'showGrid': {
                'type': 'boolean',
                'description': 'Whether to show grid lines',
              },
              'showLegend': {
                'type': 'boolean',
                'description': 'Whether to show the chart legend',
              },
              'legendPosition': {
                'type': 'string',
                'enum': [
                  'top',
                  'bottom',
                  'left',
                  'right',
                  'topLeft',
                  'topRight',
                  'bottomLeft',
                  'bottomRight',
                ],
                'description': 'Position of the legend relative to the chart area',
              },
              'useDarkTheme': {
                'type': 'boolean',
                'description': 'Whether to use dark theme colors',
              },
              'normalizationMode': {
                'type': 'string',
                'enum': ['none', 'auto', 'perSeries'],
                'description': 'Normalization mode for multi-series charts',
              },
            },
          },
        },
        'required': ['modifications'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // Get the active chart from the callback
    final activeChart = _getActiveChart();
    if (activeChart == null) {
      return const ToolResult(
        output: 'Error: No active chart to modify. '
            'Please use create_chart first to create a chart.',
        isError: true,
      );
    }

    // Validate modifications object
    final modifications = input['modifications'] as Map<String, dynamic>?;
    if (modifications == null) {
      return const ToolResult(
        output: 'Error: modifications is required. Please provide an object '
            'with the chart properties you want to change.',
        isError: true,
      );
    }

    // Parse and validate chart type if provided
    ChartType? chartType;
    final typeInput = modifications['type'] as String?;
    if (typeInput != null) {
      try {
        chartType = ChartType.values.byName(typeInput);
      } catch (_) {
        return ToolResult(
          output: 'Error: Invalid chart type "$typeInput". '
              'Valid types are: line, area, bar, scatter.',
          isError: true,
        );
      }
    }

    // Parse and validate legend position if provided
    LegendPosition? legendPosition;
    final legendPositionInput = modifications['legendPosition'] as String?;
    if (legendPositionInput != null) {
      try {
        legendPosition = LegendPosition.values.byName(legendPositionInput);
      } catch (_) {
        return ToolResult(
          output: 'Error: Invalid legend position "$legendPositionInput". '
              'Valid positions are: top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight.',
          isError: true,
        );
      }
    }

    // Parse and validate normalization mode if provided
    NormalizationModeConfig? normalizationMode;
    final normalizationModeInput = modifications['normalizationMode'] as String?;
    if (normalizationModeInput != null) {
      try {
        normalizationMode = NormalizationModeConfig.values.byName(normalizationModeInput);
      } catch (_) {
        return ToolResult(
          output: 'Error: Invalid normalization mode "$normalizationModeInput". '
              'Valid modes are: none, auto, perSeries.',
          isError: true,
        );
      }
    }

    // Start with the existing series
    var updatedSeries = List<SeriesConfig>.from(activeChart.series);

    // Handle series replacement (replaces all series)
    final seriesInput = modifications['series'] as List?;
    if (seriesInput != null) {
      updatedSeries = _parseSeries(seriesInput, 0);
    }

    // Handle removeSeries (remove series by ID)
    final removeSeries = modifications['removeSeries'] as List?;
    if (removeSeries != null) {
      final idsToRemove = removeSeries.cast<String>().toSet();
      updatedSeries = updatedSeries.where((s) => !idsToRemove.contains(s.id)).toList();
    }

    // Handle addSeries (add new series)
    final addSeries = modifications['addSeries'] as List?;
    if (addSeries != null) {
      final newSeries = _parseSeries(addSeries, updatedSeries.length);
      updatedSeries.addAll(newSeries);
    }

    // Handle updateSeries (update existing series)
    final updateSeries = modifications['updateSeries'] as Map<String, dynamic>?;
    if (updateSeries != null) {
      updatedSeries = updatedSeries.map((series) {
        final update = updateSeries[series.id] as Map<String, dynamic>?;
        if (update != null) {
          return _applySeriesUpdate(series, update);
        }
        return series;
      }).toList();
    }

    // Build modified chart configuration using copyWith
    final modifiedChart = activeChart.copyWith(
      type: chartType ?? activeChart.type,
      title: modifications.containsKey('title') ? modifications['title'] as String? : activeChart.title,
      subtitle: modifications.containsKey('subtitle') ? modifications['subtitle'] as String? : activeChart.subtitle,
      series: updatedSeries,
      showGrid: modifications['showGrid'] as bool? ?? activeChart.showGrid,
      showLegend: modifications['showLegend'] as bool? ?? activeChart.showLegend,
      legendPosition: legendPosition ?? activeChart.legendPosition,
      useDarkTheme: modifications['useDarkTheme'] as bool? ?? activeChart.useDarkTheme,
      normalizationMode: normalizationMode ?? activeChart.normalizationMode,
    );

    // Return success result with ChartConfiguration data
    return ToolResult(
      output: 'Chart modified successfully.',
      isError: false,
      data: modifiedChart,
    );
  }

  /// Parses a list of series input into [SeriesConfig] objects.
  ///
  /// [startColorIndex] is used to assign default colors starting from that index.
  List<SeriesConfig> _parseSeries(List<dynamic> seriesInput, int startColorIndex) {
    final series = <SeriesConfig>[];
    for (int i = 0; i < seriesInput.length; i++) {
      final seriesMap = seriesInput[i] as Map<String, dynamic>;
      final dataInput = seriesMap['data'] as List;
      final dataPoints = dataInput.map((point) {
        final pointMap = point as Map<String, dynamic>;
        return DataPoint(
          x: (pointMap['x'] as num).toDouble(),
          y: (pointMap['y'] as num).toDouble(),
        );
      }).toList();

      // Assign default color if not provided
      final color = seriesMap['color'] as String? ?? _defaultColors[(startColorIndex + i) % _defaultColors.length];

      series.add(SeriesConfig(
        id: seriesMap['id'] as String,
        name: seriesMap['name'] as String?,
        data: dataPoints,
        color: color,
      ));
    }
    return series;
  }

  /// Applies a partial update to a series, returning a new [SeriesConfig].
  SeriesConfig _applySeriesUpdate(
    SeriesConfig series,
    Map<String, dynamic> update,
  ) {
    // Parse updated data points if provided
    List<DataPoint>? updatedData;
    final dataInput = update['data'] as List?;
    if (dataInput != null) {
      updatedData = dataInput.map((point) {
        final pointMap = point as Map<String, dynamic>;
        return DataPoint(
          x: (pointMap['x'] as num).toDouble(),
          y: (pointMap['y'] as num).toDouble(),
        );
      }).toList();
    }

    return series.copyWith(
      name: update['name'] as String? ?? series.name,
      data: updatedData ?? series.data,
      color: update['color'] as String? ?? series.color,
    );
  }
}
