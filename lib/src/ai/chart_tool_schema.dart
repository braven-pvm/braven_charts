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
Cartesian charts support multiple overlaid series, axes, pan, zoom, and crosshair.
Pie charts support one categorical series, slice tooltips, selection, labels,
legend entries, and a Category / Value / Share data-table alternative.
Pie charts do not use axes, crosshair, pan, or zoom.
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
          'enum': ['line', 'area', 'bar', 'scatter', 'pie'],
          'description':
              'Type of chart to render. Use pie for part-to-whole category contributions; pie requires exactly one series.',
        },
        'series': {
          'type': 'array',
          'description':
              'One or more Cartesian series, or exactly one series when chart_type is pie.',
          'items': {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'string',
                'description':
                    'Unique identifier for this series (e.g., "revenue", "temperature")',
              },
              'name': {
                'type': 'string',
                'description':
                    'Display name shown in legend (e.g., "Monthly Revenue")',
              },
              'color': {
                'type': 'string',
                'description':
                    'Hex color code (e.g., "#FF5733") or named color (e.g., "blue", "red")',
              },
              'unit': {
                'type': 'string',
                'description':
                    'Unit for Y-axis values (e.g., "W", "°C", "USD", "km/h")',
              },
              'data': {
                'type': 'array',
                'description': 'Array of data points',
                'items': {
                  'type': 'object',
                  'properties': {
                    'x': {
                      'type': 'number',
                      'description':
                          'X-axis value for Cartesian charts. For pie, this is only a stable finite ordering index.',
                    },
                    'y': {
                      'type': 'number',
                      'description':
                          'Y-axis value for Cartesian charts. For pie, this is a finite non-negative contribution.',
                    },
                    'label': {
                      'type': 'string',
                      'description':
                          'Optional Cartesian point label. Required and non-empty for every pie category.',
                    },
                    'color': {
                      'type': 'string',
                      'description':
                          'Optional pie-slice color as a hex code or named color.',
                    },
                    'timestamp': {
                      'type': 'string',
                      'description':
                          'ISO 8601 timestamp if this is time-series data',
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
          'description':
              'Cartesian X-axis configuration. Omit when chart_type is pie.',
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
              'description':
                  'Explicit minimum value (auto-calculated if omitted)',
            },
            'max': {
              'type': 'number',
              'description':
                  'Explicit maximum value (auto-calculated if omitted)',
            },
          },
        },
        'y_axis': {
          'type': 'object',
          'description':
              'Cartesian Y-axis configuration. Omit when chart_type is pie; use series.unit for Cartesian multi-axis charts.',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Axis label (e.g., "Power", "Temperature")',
            },
            'unit': {
              'type': 'string',
              'description': 'Unit suffix (e.g., "W", "°C")',
            },
            'min': {'type': 'number', 'description': 'Explicit minimum value'},
            'max': {'type': 'number', 'description': 'Explicit maximum value'},
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
              'description':
                  'Allow horizontal panning for Cartesian charts. Always false for pie.',
            },
            'enable_zoom': {
              'type': 'boolean',
              'description':
                  'Allow pinch/scroll zoom for Cartesian charts. Always false for pie.',
            },
            'show_crosshair': {
              'type': 'boolean',
              'description':
                  'Show a Cartesian crosshair on hover. Always false for pie.',
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
              'description':
                  'How to interpolate between points for line/area charts',
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
            'pie_start_angle': {
              'type': 'number',
              'description':
                  'Pie-only starting angle in degrees (default: -90).',
            },
            'pie_clockwise': {
              'type': 'boolean',
              'description': 'Pie-only slice direction (default: clockwise).',
            },
            'pie_radius_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 1,
              'description': 'Pie-only radius factor in the range (0, 1].',
            },
            'pie_slice_gap': {
              'type': 'number',
              'minimum': 0,
              'description': 'Pie-only logical-pixel gap between slices.',
            },
            'pie_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Pie-only slice-border width.',
            },
            'pie_border_color': {
              'type': 'string',
              'description':
                  'Pie-only fixed shared slice-border color. When supplied, this overrides the border color mode.',
            },
            'pie_border_color_mode': {
              'type': 'string',
              'enum': ['chart_theme', 'slice'],
              'description':
                  'Pie-only fallback border policy: chart axis color or a color derived independently from each slice.',
            },
            'pie_border_hue_shift': {
              'type': 'number',
              'description':
                  'Hue rotation in degrees for slice-derived Pie borders.',
            },
            'pie_border_saturation_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL saturation shift for slice-derived Pie borders.',
            },
            'pie_border_lightness_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL lightness shift for slice-derived Pie borders; negative values create darker borders.',
            },
            'pie_selection_explode_offset': {
              'type': 'number',
              'minimum': 0,
              'description': 'Pie-only offset applied to a selected slice.',
            },
            'pie_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Pie-only slice opacity in the range [0, 1].',
            },
            'pie_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Pie-only rounded-corner radius in logical pixels.',
            },
            'pie_shadow_color': {
              'type': 'string',
              'description': 'Optional Pie slice shadow color.',
            },
            'pie_shadow_blur': {
              'type': 'number',
              'minimum': 0,
              'description': 'Pie slice shadow blur radius.',
            },
            'pie_shadow_spread': {
              'type': 'number',
              'minimum': 0,
              'description': 'Pie slice shadow spread radius.',
            },
            'pie_shadow_offset_x': {
              'type': 'number',
              'description': 'Horizontal Pie slice shadow offset.',
            },
            'pie_shadow_offset_y': {
              'type': 'number',
              'description': 'Vertical Pie slice shadow offset.',
            },
            'pie_shadow_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Pie slice shadow opacity.',
            },
            'pie_selected_glow_color': {
              'type': 'string',
              'description':
                  'Optional fixed selected-slice glow color; omit to derive it from each slice.',
            },
            'pie_selected_glow_blur': {
              'type': 'number',
              'minimum': 0,
              'description': 'Blur radius for selected-slice elevation.',
            },
            'pie_selected_glow_spread': {
              'type': 'number',
              'minimum': 0,
              'description': 'Spread radius for selected-slice elevation.',
            },
            'pie_selected_glow_offset_x': {
              'type': 'number',
              'description': 'Horizontal selected-slice elevation offset.',
            },
            'pie_selected_glow_offset_y': {
              'type': 'number',
              'description': 'Vertical selected-slice elevation offset.',
            },
            'pie_selected_glow_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Selected-slice elevation opacity.',
            },
            'pie_animation_mode': {
              'type': 'string',
              'enum': ['none', 'grow'],
              'description': 'Pie entrance animation mode.',
            },
            'show_data_labels': {
              'type': 'boolean',
              'description': 'Show labels on eligible pie slices.',
            },
            'pie_label_position': {
              'type': 'string',
              'enum': ['inside', 'outside'],
              'description': 'Pie-only data-label placement.',
            },
            'pie_label_content': {
              'type': 'string',
              'enum': [
                'category',
                'value',
                'percentage',
                'category_and_value',
                'category_and_percentage',
                'value_and_percentage',
                'category_value_and_percentage',
              ],
              'description': 'Pie-only label content.',
            },
            'pie_label_minimum_share': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Minimum pie share eligible for a label.',
            },
            'pie_label_minimum_sweep': {
              'type': 'number',
              'minimum': 0,
              'maximum': 360,
              'description':
                  'Minimum pie-slice sweep in degrees eligible for a label.',
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
