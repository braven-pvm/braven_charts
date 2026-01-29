import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/chart_configuration.dart';
import '../models/data_point.dart';
import '../models/enums.dart';
import '../models/series_config.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for creating chart configurations from LLM input.
///
/// This tool allows the LLM to create interactive charts by providing
/// structured input including data series, chart type, and styling options.
///
/// ## Example Usage (LLM perspective)
///
/// ```json
/// {
///   "prompt": "Create a line chart showing temperature over time",
///   "type": "line",
///   "title": "Temperature Trends",
///   "series": [{
///     "id": "temp",
///     "data": [{"x": 0, "y": 20}, {"x": 1, "y": 22}]
///   }]
/// }
/// ```
///
/// ## Required Fields
///
/// - `prompt`: Natural language description of the chart
/// - `series`: Array of data series to plot
///
/// ## Output
///
/// Returns a [ToolResult] with:
/// - `output`: JSON string of the created chart configuration
/// - `data`: [ChartConfiguration] object for programmatic use
/// - `isError`: true if input validation fails
class CreateChartTool extends AgentTool {
  /// Default color palette for series that don't specify their own color.
  static const List<String> _defaultColors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FF5722', // Deep Orange
    '#607D8B', // Blue Grey
  ];

  /// UUID generator for unique chart IDs.
  static const _uuid = Uuid();

  @override
  String get name => 'create_chart';

  @override
  String get description =>
      'Creates a new chart configuration with the specified type, data series, and styling options. '
      'Use this tool to generate interactive charts from structured data.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description':
                'Natural language description of the chart to create',
          },
          'type': {
            'type': 'string',
            'enum': ['line', 'area', 'bar', 'scatter'],
            'description': 'The type of chart to render',
          },
          'title': {
            'type': 'string',
            'description': 'Title displayed at the top of the chart',
          },
          'subtitle': {
            'type': 'string',
            'description': 'Subtitle displayed below the title',
          },
          'series': {
            'type': 'array',
            'description': 'Data series to plot on the chart',
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
          'xAxis': {
            'type': 'object',
            'description': 'X-axis configuration',
          },
          'annotations': {
            'type': 'array',
            'description': 'Annotations to display on the chart',
          },
          'style': {
            'type': 'object',
            'description': 'Visual styling configuration',
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
        'required': ['prompt', 'series'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // Validate required fields
    final prompt = input['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return const ToolResult(
        output: 'Error: prompt is required. Please provide a natural language '
            'description of the chart you want to create.',
        isError: true,
      );
    }

    final seriesInput = input['series'] as List?;
    if (seriesInput == null || seriesInput.isEmpty) {
      return const ToolResult(
        output:
            'Error: series is required and must contain at least one data series. '
            'Each series should have an id and data array.',
        isError: true,
      );
    }

    // Validate and parse chart type
    ChartType chartType = ChartType.line; // default
    final typeInput = input['type'] as String?;
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

    // Validate and parse legend position
    LegendPosition legendPosition = LegendPosition.bottom; // default
    final legendPositionInput = input['legendPosition'] as String?;
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

    // Validate and parse normalization mode
    NormalizationModeConfig normalizationMode =
        NormalizationModeConfig.none; // default
    final normalizationModeInput = input['normalizationMode'] as String?;
    if (normalizationModeInput != null) {
      try {
        normalizationMode =
            NormalizationModeConfig.values.byName(normalizationModeInput);
      } catch (_) {
        return ToolResult(
          output:
              'Error: Invalid normalization mode "$normalizationModeInput". '
              'Valid modes are: none, auto, perSeries.',
          isError: true,
        );
      }
    }

    // Parse series data
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
      final color = seriesMap['color'] as String? ??
          _defaultColors[i % _defaultColors.length];

      series.add(SeriesConfig(
        id: seriesMap['id'] as String,
        name: seriesMap['name'] as String?,
        data: dataPoints,
        color: color,
      ));
    }

    // Generate unique chart ID
    final chartId = _uuid.v4();

    // Build chart configuration
    final chart = ChartConfiguration(
      id: chartId,
      type: chartType,
      title: input['title'] as String?,
      subtitle: input['subtitle'] as String?,
      series: series,
      showGrid: input['showGrid'] as bool? ?? true,
      showLegend: input['showLegend'] as bool? ?? true,
      legendPosition: legendPosition,
      useDarkTheme: input['useDarkTheme'] as bool? ?? false,
      normalizationMode: normalizationMode,
    );

    // Return success result with JSON output and ChartConfiguration data
    return ToolResult(
      output: jsonEncode(chart.toJson()),
      data: chart,
    );
  }
}
