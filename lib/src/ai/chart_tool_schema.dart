// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// JSON Schema definitions for LLM function calling / tool use.
///
/// These schemas define the contract between an AI agent and BravenChartPlus,
/// enabling agents to generate charts from natural language requests.
///
/// Compatible with:
/// - Anthropic Claude (tool_use)
/// - OpenAI (function_calling)
/// - Google Gemini (function_declarations)
library;

/// Tool definitions for AI chart generation.
///
/// These can be passed directly to LLM APIs that support function calling.
///
/// Example usage with Claude:
/// ```dart
/// final response = await anthropic.messages.create(
///   model: 'claude-sonnet-4-20250514',
///   tools: ChartToolSchema.tools,
///   messages: [...],
/// );
/// ```
abstract final class ChartToolSchema {
  /// All available chart tools.
  static const List<Map<String, dynamic>> tools = [
    createChartTool,
    modifyChartTool,
    explainDataTool,
  ];

  /// Tool for creating a new chart from data.
  static const Map<String, dynamic> createChartTool = {
    'name': 'create_chart',
    'description': '''
Creates an interactive BravenChartPlus chart from provided data.
Use this tool when the user wants to visualize data as a chart.
The chart will be rendered as a Flutter widget that supports:
- Pan and zoom interactions
- Crosshair with value tooltips
- Multiple series overlay
- Annotations and markers
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'Chart title displayed above the chart',
        },
        'chart_type': {
          'type': 'string',
          'enum': ['line', 'area', 'bar', 'scatter'],
          'description': 'Type of chart to render. Line is best for trends, bar for comparisons, scatter for correlations.',
        },
        'series': {
          'type': 'array',
          'description': 'One or more data series to plot',
          'items': {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'string',
                'description': 'Unique identifier for this series (e.g., "revenue", "temperature")',
              },
              'name': {
                'type': 'string',
                'description': 'Display name shown in legend (e.g., "Monthly Revenue")',
              },
              'color': {
                'type': 'string',
                'description': 'Hex color code (e.g., "#FF5733") or named color (e.g., "blue", "red")',
              },
              'unit': {
                'type': 'string',
                'description': 'Unit for Y-axis values (e.g., "W", "°C", "USD", "km/h")',
              },
              'data': {
                'type': 'array',
                'description': 'Array of data points',
                'items': {
                  'type': 'object',
                  'properties': {
                    'x': {
                      'type': 'number',
                      'description': 'X-axis value (numeric)',
                    },
                    'y': {
                      'type': 'number',
                      'description': 'Y-axis value',
                    },
                    'label': {
                      'type': 'string',
                      'description': 'Optional label for this point',
                    },
                    'timestamp': {
                      'type': 'string',
                      'description': 'ISO 8601 timestamp if this is time-series data',
                    },
                  },
                  'required': ['x', 'y'],
                },
              },
            },
            'required': ['id', 'data'],
          },
        },
        'x_axis': {
          'type': 'object',
          'description': 'X-axis configuration',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Axis label (e.g., "Time", "Distance")',
            },
            'unit': {
              'type': 'string',
              'description': 'Unit suffix (e.g., "s", "km")',
            },
            'min': {
              'type': 'number',
              'description': 'Explicit minimum value (auto-calculated if omitted)',
            },
            'max': {
              'type': 'number',
              'description': 'Explicit maximum value (auto-calculated if omitted)',
            },
          },
        },
        'y_axis': {
          'type': 'object',
          'description': 'Y-axis configuration (for single axis; use series.unit for multi-axis)',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Axis label (e.g., "Power", "Temperature")',
            },
            'unit': {
              'type': 'string',
              'description': 'Unit suffix (e.g., "W", "°C")',
            },
            'min': {
              'type': 'number',
              'description': 'Explicit minimum value',
            },
            'max': {
              'type': 'number',
              'description': 'Explicit maximum value',
            },
            'position': {
              'type': 'string',
              'enum': ['left', 'right'],
              'description': 'Which side to show the Y-axis',
            },
          },
        },
        'interactions': {
          'type': 'object',
          'description': 'Interaction configuration',
          'properties': {
            'enable_pan': {
              'type': 'boolean',
              'description': 'Allow horizontal panning (default: true)',
            },
            'enable_zoom': {
              'type': 'boolean',
              'description': 'Allow pinch/scroll zoom (default: true)',
            },
            'show_crosshair': {
              'type': 'boolean',
              'description': 'Show crosshair on hover (default: true)',
            },
            'show_tooltip': {
              'type': 'boolean',
              'description': 'Show value tooltip on hover (default: true)',
            },
          },
        },
        'style': {
          'type': 'object',
          'description': 'Visual styling options',
          'properties': {
            'line_interpolation': {
              'type': 'string',
              'enum': ['linear', 'bezier', 'stepped', 'monotone'],
              'description': 'How to interpolate between points for line/area charts',
            },
            'show_grid': {
              'type': 'boolean',
              'description': 'Show background grid lines (default: true)',
            },
            'show_legend': {
              'type': 'boolean',
              'description': 'Show legend for multiple series (default: true)',
            },
            'height': {
              'type': 'number',
              'description': 'Chart height in pixels (default: 300)',
            },
          },
        },
      },
      'required': ['series'],
    },
  };

  /// Tool for modifying an existing chart.
  static const Map<String, dynamic> modifyChartTool = {
    'name': 'modify_chart',
    'description': '''
Modifies an existing chart by updating its configuration or data.
Use this when the user wants to change aspects of a chart that was already created.
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'chart_id': {
          'type': 'string',
          'description': 'ID of the chart to modify',
        },
        'action': {
          'type': 'string',
          'enum': [
            'add_series',
            'remove_series',
            'update_series',
            'change_type',
            'update_axis',
            'add_annotation',
            'zoom_to_range',
            'reset_view',
          ],
          'description': 'The modification action to perform',
        },
        'parameters': {
          'type': 'object',
          'description': 'Action-specific parameters',
        },
      },
      'required': ['chart_id', 'action'],
    },
  };

  /// Tool for analyzing/explaining data patterns.
  static const Map<String, dynamic> explainDataTool = {
    'name': 'explain_data',
    'description': '''
Analyzes data and explains patterns, trends, or anomalies.
Use this tool to provide insights about the data being visualized.
Returns statistical analysis and natural language explanations.
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'chart_id': {
          'type': 'string',
          'description': 'ID of the chart containing the data to analyze',
        },
        'analysis_type': {
          'type': 'string',
          'enum': [
            'summary',
            'trends',
            'anomalies',
            'correlations',
            'comparison',
          ],
          'description': 'Type of analysis to perform',
        },
        'series_ids': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Specific series to analyze (all if omitted)',
        },
      },
      'required': ['analysis_type'],
    },
  };

  /// Returns the tool schema in Anthropic's format.
  static List<Map<String, dynamic>> toAnthropicFormat() {
    return tools.map((tool) {
      return {
        'name': tool['name'],
        'description': tool['description'],
        'input_schema': tool['input_schema'],
      };
    }).toList();
  }

  /// Returns the tool schema in OpenAI's format.
  static List<Map<String, dynamic>> toOpenAIFormat() {
    return tools.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool['name'],
          'description': tool['description'],
          'parameters': tool['input_schema'],
        },
      };
    }).toList();
  }
}
