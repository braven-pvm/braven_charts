import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for modifying existing chart configurations.
///
/// This tool allows the LLM to make incremental changes to existing charts
/// by providing a chart ID and a partial modification specification.
///
/// Unlike [CreateChartTool] which builds new charts from scratch,
/// ModifyChartTool applies partial updates to existing chart configurations.
///
/// ## Example Usage (LLM perspective)
///
/// ```json
/// {
///   "chart_id": "abc-123",
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
/// ## Required Fields
///
/// - `chart_id`: ID of the existing chart to modify
/// - `modifications`: Object with partial chart configuration to apply
///
/// ## Supported Modifications
///
/// - Change chart type (line, area, bar, scatter)
/// - Update title and subtitle
/// - Replace entire series array
/// - Add new series with `addSeries`
/// - Remove series by ID with `removeSeries`
/// - Update specific series data
/// - Toggle showGrid, showLegend
/// - Change legendPosition, useDarkTheme, normalizationMode
///
/// ## Output
///
/// Returns a [ToolResult] with:
/// - `output`: JSON string of the modified chart configuration
/// - `data`: [ChartConfiguration] object with applied modifications
/// - `isError`: true if chart_id doesn't exist or input validation fails
class ModifyChartTool extends AgentTool {
  @override
  String get name => 'modify_chart';

  @override
  String get description => 'Modifies an existing chart configuration by applying partial updates. '
      'Use this tool to change chart type, update titles, add/remove series, '
      'or adjust styling options on a previously created chart.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'chart_id': {
            'type': 'string',
            'description': 'ID of the chart to modify',
          },
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
        'required': ['chart_id', 'modifications'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // STUB: This is a companion stub for TDD red-phase tests.
    // The green-phase implementation will:
    // 1. Validate chart_id exists in chart registry
    // 2. Apply modifications to existing chart configuration
    // 3. Return updated ChartConfiguration
    throw UnimplementedError(
      'ModifyChartTool.execute() is not yet implemented. '
      'This is a TDD red-phase stub.',
    );
  }
}
