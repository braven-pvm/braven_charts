import 'dart:convert';

import '../models/annotation_config.dart';
import '../models/chart_configuration.dart';
import '../models/chart_style_config.dart';
import '../models/data_point.dart';
import '../models/enums.dart';
import '../models/series_config.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for modifying existing chart configurations.
///
/// This tool applies incremental changes to an existing chart configuration
/// obtained through a callback function. Unlike [CreateChartTool] which builds
/// new charts from scratch, ModifyChartTool updates specific properties while
/// preserving unchanged ones.
///
/// Register this tool on an [AgentSessionImpl] so the LLM can update the
/// current chart after it has been created. It is intended for partial
/// updates such as changing titles, adding/removing series, or tweaking
/// styling/interaction options.
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
///
/// When no active chart is available, the tool returns a helpful error
/// explaining that `create_chart` must be called first.
class ModifyChartTool extends AgentTool {
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
  ModifyChartTool({required ChartConfiguration? Function() getActiveChart})
      : _getActiveChart = getActiveChart;
  @override
  String get name => 'modify_chart';

  @override
  String get description =>
      'Modifies the currently active chart by applying partial updates. '
      'Use this tool to change chart type, update titles, add/remove/update series, '
      'add/remove annotations, or adjust styling options. '
      'Requires an active chart created previously.\n\n'
      'IMPORTANT - How to REMOVE items:\n'
      '- To REMOVE ALL annotations: set "annotations": []\n'
      '- To REMOVE ALL series: set "series": []\n'
      '- To remove SPECIFIC series: use "removeSeries": ["seriesId1", "seriesId2"]\n'
      '- Setting an array property to [] replaces it with an empty array, effectively removing all items.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'modifications': {
            'type': 'object',
            'description': 'Partial chart configuration to merge',
            'properties': {
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
                'description':
                    'REPLACES ALL existing series with this array. To REMOVE ALL SERIES, set to []. '
                        'To add series without removing existing ones, use addSeries instead.',
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
                    'type': {
                      'type': 'string',
                      'enum': ['line', 'area', 'bar', 'scatter'],
                      'description':
                          'Type of chart series (line, area, bar, scatter). Each series can have its own type. Defaults to line.',
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
                    'yAxisId': {
                      'type': 'string',
                      'description': 'Reference to a SHARED Y-axis by its id. '
                          'Must match an id from yAxes[] array (e.g., yAxes: [{id: "power-axis", ...}] → yAxisId: "power-axis"). '
                          'MUTUALLY EXCLUSIVE with inline axis fields (yAxisPosition/yAxisLabel/etc). '
                          'Will be validated - invalid references cause an error.',
                    },
                    'unit': {
                      'type': 'string',
                      'description':
                          'Unit of measurement for this series (e.g., "W", "bpm").',
                    },
                    'interpolation': {
                      'type': 'string',
                      'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                      'description':
                          'Line interpolation type. Defaults to "linear".',
                    },
                    'strokeWidth': {
                      'type': 'number',
                      'minimum': 0,
                      'description':
                          'Width of the line stroke in pixels. Defaults to 2.0.',
                    },
                    'tension': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description':
                          'Curve tension for bezier interpolation (0.0 to 1.0).',
                    },
                    'showPoints': {
                      'type': 'boolean',
                      'description':
                          'Whether to show data point markers. Defaults to false.',
                    },
                    'fillOpacity': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description':
                          'Fill opacity for area charts (0.0 to 1.0). Defaults to 0.3.',
                    },
                    'markerStyle': {
                      'type': 'string',
                      'enum': [
                        'none',
                        'circle',
                        'square',
                        'triangle',
                        'diamond'
                      ],
                      'description': 'Style of markers at data points.',
                    },
                    'markerSize': {
                      'type': 'number',
                      'minimum': 0,
                      'description':
                          'Size of markers in pixels. Defaults to 4.0.',
                    },
                    'barWidthPercent': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description':
                          'Bar width as a percentage of available space (0.0 to 1.0).',
                    },
                    'barWidthPixels': {
                      'type': 'number',
                      'minimum': 0,
                      'description':
                          'Fixed bar width in pixels. Overrides barWidthPercent.',
                    },
                    'barMinWidth': {
                      'type': 'number',
                      'minimum': 0,
                      'description': 'Minimum bar width in pixels.',
                    },
                    'barMaxWidth': {
                      'type': 'number',
                      'minimum': 0,
                      'description': 'Maximum bar width in pixels.',
                    },
                    'yAxisPosition': {
                      'type': 'string',
                      'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                      'description':
                          'Position for INLINE Y-axis. MUTUALLY EXCLUSIVE with yAxisId.',
                    },
                    'yAxisLabel': {
                      'type': 'string',
                      'description':
                          'Label for INLINE Y-axis (used with yAxisPosition).',
                    },
                    'yAxisUnit': {
                      'type': 'string',
                      'description':
                          'Unit for INLINE Y-axis (used with yAxisPosition).',
                    },
                    'yAxisColor': {
                      'type': 'string',
                      'description':
                          'Color for INLINE Y-axis (used with yAxisPosition).',
                    },
                    'yAxisMin': {
                      'type': 'number',
                      'description':
                          'Min value for INLINE Y-axis (used with yAxisPosition).',
                    },
                    'yAxisMax': {
                      'type': 'number',
                      'description':
                          'Max value for INLINE Y-axis (used with yAxisPosition).',
                    },
                    'visible': {
                      'type': 'boolean',
                      'description': 'Whether this series is visible.',
                    },
                    'legendVisible': {
                      'type': 'boolean',
                      'description':
                          'Whether to show this series in the legend.',
                    },
                    'strokeDash': {
                      'type': 'array',
                      'items': {'type': 'number'},
                      'description':
                          'Dash pattern for line stroke (e.g., [5, 3] for dashed).',
                    },
                  },
                  'required': ['id', 'data'],
                },
              },
              'removeSeries': {
                'type': 'array',
                'description':
                    'IDs of series to remove from the chart. Does not affect other series.',
                'items': {
                  'type': 'string',
                },
              },
              'updateSeries': {
                'type': 'object',
                'description': 'Map of series ID to partial update. Only specified properties are changed; unspecified ones remain. '
                    'Supports: type, name, color, data, strokeWidth, strokeDash, fillOpacity, '
                    'markerStyle, markerSize, interpolation, tension, showPoints, '
                    'yAxisPosition, yAxisLabel, yAxisUnit, yAxisColor, yAxisMin, '
                    'yAxisMax, barWidthPercent, barWidthPixels, barMinWidth, '
                    'barMaxWidth, yAxisId, visible, legendVisible, unit.',
                'additionalProperties': {
                  'type': 'object',
                  'description': 'Partial series properties to update',
                  'properties': {
                    'type': {
                      'type': 'string',
                      'enum': ['line', 'area', 'bar', 'scatter'],
                      'description':
                          'Change the series type (line, area, bar, scatter)',
                    },
                    'name': {'type': 'string', 'description': 'Display name'},
                    'color': {
                      'type': 'string',
                      'description': 'Color (hex format, e.g., "#FF0000")'
                    },
                    'data': {
                      'type': 'array',
                      'description': 'New data points (replaces existing data)',
                      'items': {
                        'type': 'object',
                        'properties': {
                          'x': {'type': 'number'},
                          'y': {'type': 'number'},
                        },
                        'required': ['x', 'y'],
                      },
                    },
                    'strokeWidth': {
                      'type': 'number',
                      'minimum': 0,
                      'description': 'Line width in pixels'
                    },
                    'strokeDash': {
                      'type': 'array',
                      'items': {'type': 'number'},
                      'description':
                          'Dash pattern for line (e.g., [5, 3] for dashed)',
                    },
                    'fillOpacity': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description': 'Fill opacity for area charts'
                    },
                    'tension': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description': 'Bezier curve tension'
                    },
                    'showPoints': {
                      'type': 'boolean',
                      'description': 'Whether to show data point markers'
                    },
                    'interpolation': {
                      'type': 'string',
                      'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                      'description': 'Line interpolation type',
                    },
                    'markerStyle': {
                      'type': 'string',
                      'enum': [
                        'none',
                        'circle',
                        'square',
                        'triangle',
                        'diamond'
                      ],
                      'description': 'Style of markers at data points',
                    },
                    'markerSize': {
                      'type': 'number',
                      'minimum': 0,
                      'description': 'Marker size in pixels'
                    },
                    'yAxisId': {
                      'type': 'string',
                      'description':
                          'SHARED axis reference (mutually exclusive with yAxisPosition)'
                    },
                    'unit': {
                      'type': 'string',
                      'description': 'Unit of measurement'
                    },
                    'visible': {
                      'type': 'boolean',
                      'description': 'Whether series is visible'
                    },
                    'legendVisible': {
                      'type': 'boolean',
                      'description': 'Whether to show in legend'
                    },
                    'yAxisPosition': {
                      'type': 'string',
                      'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                      'description':
                          'INLINE axis position (mutually exclusive with yAxisId)',
                    },
                    'yAxisLabel': {
                      'type': 'string',
                      'description': 'INLINE axis label'
                    },
                    'yAxisUnit': {
                      'type': 'string',
                      'description': 'INLINE axis unit'
                    },
                    'yAxisColor': {
                      'type': 'string',
                      'description': 'INLINE axis color (hex)'
                    },
                    'yAxisMin': {
                      'type': 'number',
                      'description': 'INLINE axis minimum value'
                    },
                    'yAxisMax': {
                      'type': 'number',
                      'description': 'INLINE axis maximum value'
                    },
                    'barWidthPercent': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1
                    },
                    'barWidthPixels': {'type': 'number', 'minimum': 0},
                    'barMinWidth': {'type': 'number', 'minimum': 0},
                    'barMaxWidth': {'type': 'number', 'minimum': 0},
                  },
                },
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
                'description':
                    'Position of the legend relative to the chart area',
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
              'xAxis': {
                'type': 'object',
                'description':
                    'X-axis configuration. Partial updates merge with existing config.',
                'properties': {
                  'label': {
                    'type': 'string',
                    'description': 'Axis label (e.g., "Time")'
                  },
                  'unit': {
                    'type': 'string',
                    'description': 'Unit string (e.g., "seconds")'
                  },
                  'min': {
                    'type': 'number',
                    'description': 'Minimum value for X-axis scale'
                  },
                  'max': {
                    'type': 'number',
                    'description': 'Maximum value for X-axis scale'
                  },
                  'autoRange': {
                    'type': 'boolean',
                    'description': 'Auto-calculate range from data'
                  },
                  'tickCount': {
                    'type': 'integer',
                    'description': 'Number of ticks to display'
                  },
                  'showTicks': {
                    'type': 'boolean',
                    'description': 'Whether to show tick marks'
                  },
                  'showAxisLine': {
                    'type': 'boolean',
                    'description': 'Whether to show the axis line'
                  },
                  'showGridLines': {
                    'type': 'boolean',
                    'description': 'Whether to show vertical grid lines'
                  },
                  'visible': {
                    'type': 'boolean',
                    'description': 'Whether the X-axis is visible'
                  },
                },
              },
              'yAxes': {
                'type': 'array',
                'description':
                    'SHARED Y-axis configurations. REPLACES all existing Y-axes. '
                        'Each axis needs a unique id that series reference via yAxisId. '
                        'Example: yAxes: [{id: "temp-axis", label: "Temp", position: "left"}], '
                        'series: [{..., yAxisId: "temp-axis"}]',
                'items': {
                  'type': 'object',
                  'properties': {
                    'id': {
                      'type': 'string',
                      'description': 'REQUIRED. Unique identifier for this Y-axis. '
                          'Series reference this exact string via series[].yAxisId. '
                          'Example: id: "power-axis" → series yAxisId: "power-axis"',
                    },
                    'label': {
                      'type': 'string',
                      'description': 'Axis label (e.g., "Power")'
                    },
                    'unit': {
                      'type': 'string',
                      'description': 'Unit string (e.g., "W")'
                    },
                    'position': {
                      'type': 'string',
                      'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                      'description': 'Position of the Y-axis',
                    },
                    'min': {
                      'type': 'number',
                      'description': 'Minimum value for Y-axis scale'
                    },
                    'max': {
                      'type': 'number',
                      'description': 'Maximum value for Y-axis scale'
                    },
                    'autoRange': {
                      'type': 'boolean',
                      'description': 'Auto-calculate range from data'
                    },
                    'includeZero': {
                      'type': 'boolean',
                      'description': 'Whether range should include zero'
                    },
                    'color': {
                      'type': 'string',
                      'description': 'Axis color (hex format)'
                    },
                    'showTicks': {
                      'type': 'boolean',
                      'description': 'Whether to show tick marks'
                    },
                    'showAxisLine': {
                      'type': 'boolean',
                      'description': 'Whether to show the axis line'
                    },
                    'showGridLines': {
                      'type': 'boolean',
                      'description': 'Whether to show horizontal grid lines'
                    },
                  },
                },
              },
              'annotations': {
                'type': 'array',
                'description': 'Annotations to display on the chart. REPLACES all existing annotations. '
                    'To REMOVE ALL ANNOTATIONS, set this to an empty array: []. '
                    'IMPORTANT for perSeries normalization: horizontal annotations MUST include seriesId '
                    'to specify which series data range to use for positioning.',
                'items': {
                  'type': 'object',
                  'properties': {
                    'type': {
                      'type': 'string',
                      'enum': ['referenceLine', 'zone', 'textLabel', 'marker'],
                      'description':
                          'Type of annotation: referenceLine (horizontal/vertical line at value), '
                              'zone (shaded region), textLabel (text at position), marker (point marker)',
                    },
                    'value': {
                      'type': 'number',
                      'description':
                          'Value for referenceLine. For horizontal lines, this is the Y-axis value '
                              'in the SAME UNITS as the target series data. In perSeries mode, '
                              'seriesId determines which series range to use.',
                    },
                    'minValue': {
                      'type': 'number',
                      'description': 'Minimum value for zone annotation',
                    },
                    'maxValue': {
                      'type': 'number',
                      'description': 'Maximum value for zone annotation',
                    },
                    'x': {
                      'type': 'number',
                      'description': 'X coordinate for marker annotation',
                    },
                    'y': {
                      'type': 'number',
                      'description': 'Y coordinate for marker annotation',
                    },
                    'text': {
                      'type': 'string',
                      'description': 'Text content for textLabel annotation',
                    },
                    'label': {
                      'type': 'string',
                      'description':
                          'Label text displayed with the annotation (for all types)',
                    },
                    'color': {
                      'type': 'string',
                      'description':
                          'Color of the annotation (hex format, e.g., "#FF0000")',
                    },
                    'lineWidth': {
                      'type': 'number',
                      'description': 'Line width for referenceLine annotations',
                    },
                    'dashPattern': {
                      'type': 'array',
                      'items': {'type': 'number'},
                      'description':
                          'Dash pattern for referenceLine (e.g., [5, 3] for dashed)',
                    },
                    'opacity': {
                      'type': 'number',
                      'minimum': 0,
                      'maximum': 1,
                      'description': 'Opacity for zone fill (0.0 to 1.0)',
                    },
                    'orientation': {
                      'type': 'string',
                      'enum': ['horizontal', 'vertical'],
                      'description':
                          'Orientation for referenceLine/zone (horizontal = Y axis, vertical = X axis)',
                    },
                    'position': {
                      'type': 'string',
                      'enum': [
                        'topLeft',
                        'topCenter',
                        'topRight',
                        'centerLeft',
                        'center',
                        'centerRight',
                        'bottomLeft',
                        'bottomCenter',
                        'bottomRight'
                      ],
                      'description': 'Position for textLabel annotation',
                    },
                    'fontSize': {
                      'type': 'number',
                      'description': 'Font size for textLabel annotation',
                    },
                    'seriesId': {
                      'type': 'string',
                      'description':
                          'REQUIRED for perSeries normalization: ID of the series whose data range '
                              'determines annotation positioning. Must match a series.id value exactly. '
                              'Without this, horizontal annotations appear at zero in perSeries mode.',
                    },
                  },
                  'required': ['type'],
                },
              },
              'style': {
                'type': 'object',
                'description': 'Visual styling configuration for the chart',
                'properties': {
                  'titleFontSize': {
                    'type': 'number',
                    'description': 'Font size for chart title'
                  },
                  'subtitleFontSize': {
                    'type': 'number',
                    'description': 'Font size for chart subtitle'
                  },
                  'axisFontSize': {
                    'type': 'number',
                    'description': 'Font size for axis labels'
                  },
                  'legendFontSize': {
                    'type': 'number',
                    'description': 'Font size for legend text'
                  },
                  'padding': {
                    'type': 'object',
                    'description': 'Padding around the chart area',
                    'properties': {
                      'top': {'type': 'number'},
                      'right': {'type': 'number'},
                      'bottom': {'type': 'number'},
                      'left': {'type': 'number'},
                    },
                  },
                },
              },
              'interactions': {
                'type': 'object',
                'description':
                    'Interaction configuration for pan/zoom/tooltip behavior',
                'properties': {
                  'crosshairMode': {
                    'type': 'string',
                    'enum': ['none', 'vertical', 'horizontal', 'both'],
                    'description': 'Crosshair display mode',
                  },
                  'tooltipPosition': {
                    'type': 'string',
                    'enum': [
                      'auto',
                      'top',
                      'bottom',
                      'left',
                      'right',
                      'nearestPoint'
                    ],
                    'description': 'Preferred tooltip position',
                  },
                  'enableZoom': {
                    'type': 'boolean',
                    'description': 'Whether zooming is enabled'
                  },
                  'enablePan': {
                    'type': 'boolean',
                    'description': 'Whether panning is enabled'
                  },
                  'snapToPoint': {
                    'type': 'boolean',
                    'description': 'Whether crosshair snaps to nearest point'
                  },
                },
              },
              'width': {
                'type': 'number',
                'description': 'Width of the chart in pixels',
              },
              'height': {
                'type': 'number',
                'description': 'Height of the chart in pixels',
              },
              'backgroundColor': {
                'type': 'string',
                'description':
                    'Background color of the chart (hex format, e.g., "#FFFFFF")',
              },
              'showScrollbar': {
                'type': 'boolean',
                'description': 'Whether to show scrollbars for panning',
              },
            },
          },
        },
        'required': ['modifications'],
      };

  /// Helper to return tool error result
  ToolResult _logError(String message, Map<String, dynamic> input) {
    return ToolResult(output: message, isError: true);
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // Get the active chart from the callback
    final activeChart = _getActiveChart();
    if (activeChart == null) {
      return _logError(
        'Error: No active chart to modify. '
        'Please use create_chart first to create a chart.',
        input,
      );
    }

    // Validate modifications object
    final modifications = input['modifications'] as Map<String, dynamic>?;
    if (modifications == null) {
      return _logError(
        'Error: modifications is required. Please provide an object '
        'with the chart properties you want to change.',
        input,
      );
    }

    // Parse and validate legend position if provided
    LegendPosition? legendPosition;
    final legendPositionInput = modifications['legendPosition'] as String?;
    if (legendPositionInput != null) {
      try {
        legendPosition = LegendPosition.values.byName(legendPositionInput);
      } catch (_) {
        return _logError(
          'Error: Invalid legend position "$legendPositionInput". '
          'Valid positions are: top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight.',
          input,
        );
      }
    }

    // Parse and validate normalization mode if provided
    NormalizationModeConfig? normalizationMode;
    final normalizationModeInput =
        modifications['normalizationMode'] as String?;
    if (normalizationModeInput != null) {
      try {
        normalizationMode =
            NormalizationModeConfig.values.byName(normalizationModeInput);
      } catch (_) {
        return _logError(
          'Error: Invalid normalization mode "$normalizationModeInput". '
          'Valid modes are: none, auto, perSeries.',
          input,
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
      updatedSeries =
          updatedSeries.where((s) => !idsToRemove.contains(s.id)).toList();
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
      // Validate series types before applying updates
      const validTypes = ['line', 'area', 'bar', 'scatter'];
      for (final entry in updateSeries.entries) {
        final seriesId = entry.key;
        final update = entry.value as Map<String, dynamic>?;
        if (update != null && update['type'] != null) {
          final typeValue = update['type'] as String;
          if (!validTypes.contains(typeValue)) {
            return _logError(
              'Error: Invalid series type "$typeValue" for series "$seriesId". '
              'Valid types are: line, area, bar, scatter.',
              input,
            );
          }
        }
      }

      updatedSeries = updatedSeries.map((series) {
        final update = updateSeries[series.id] as Map<String, dynamic>?;
        if (update != null) {
          return _applySeriesUpdate(series, update);
        }
        return series;
      }).toList();
    }

    // Parse xAxis if provided
    XAxisConfig? xAxis;
    final xAxisInput = modifications['xAxis'] as Map<String, dynamic>?;
    if (xAxisInput != null) {
      xAxis = _parseXAxis(xAxisInput);
    }

    // Parse yAxes if provided
    List<YAxisConfig>? yAxes;
    final yAxesInput = modifications['yAxes'] as List?;
    if (yAxesInput != null) {
      yAxes = _parseYAxes(yAxesInput);
    }

    // Parse annotations if provided
    List<AnnotationConfig>? annotations;
    final annotationsInput = modifications['annotations'] as List?;
    if (annotationsInput != null) {
      annotations = <AnnotationConfig>[];
      for (int i = 0; i < annotationsInput.length; i++) {
        final annotationMap = annotationsInput[i];
        final map = Map<String, dynamic>.from(annotationMap as Map);
        final parsed = AnnotationConfig.fromJson(map);
        annotations.add(parsed);
      }

      // Validate annotation seriesId references against updated series
      final validSeriesIds = updatedSeries.map((s) => s.id).toSet();
      for (final annotation in annotations) {
        if (annotation.seriesId != null &&
            !validSeriesIds.contains(annotation.seriesId)) {
          return _logError(
            'Error: Annotation references non-existent series '
            '"${annotation.seriesId}". '
            'Valid series IDs are: ${validSeriesIds.join(", ")}. '
            'The seriesId must exactly match a series id from the series array.',
            input,
          );
        }
      }

      // Determine effective normalization mode
      final effectiveNormMode =
          normalizationMode ?? activeChart.normalizationMode;

      // Validate horizontal annotations have seriesId in perSeries mode
      if (effectiveNormMode == NormalizationModeConfig.perSeries) {
        for (final annotation in annotations) {
          if (annotation.type == AnnotationType.referenceLine &&
              annotation.orientation != Orientation.vertical &&
              annotation.seriesId == null) {
            return _logError(
              'Error: Horizontal referenceLine annotation requires '
              '"seriesId" in perSeries normalization mode. '
              'Without seriesId, the annotation cannot be positioned correctly. '
              'Add seriesId matching one of: ${validSeriesIds.join(", ")}',
              input,
            );
          }
        }
      }

      // Validate referenceLine annotations have a value
      for (final annotation in annotations) {
        if (annotation.type == AnnotationType.referenceLine &&
            annotation.value == null) {
          return _logError(
            'Error: referenceLine annotation requires a "value" property. '
            'The value should be in the same units as the target series data. '
            'Example: for a power series with range 0-500W, value: 200 draws a line at 200W.',
            input,
          );
        }
      }
    }

    // Parse style if provided
    ChartStyleConfig? style;
    final styleInput = modifications['style'] as Map<String, dynamic>?;
    if (styleInput != null) {
      style = ChartStyleConfig.fromJson(styleInput);
    }

    // Parse interactions if provided
    Map<String, dynamic>? interactions;
    final interactionsInput =
        modifications['interactions'] as Map<String, dynamic>?;
    if (interactionsInput != null) {
      interactions = interactionsInput;
    }

    // Build modified chart configuration using copyWith
    final modifiedChart = activeChart.copyWith(
      title: modifications.containsKey('title')
          ? modifications['title'] as String?
          : activeChart.title,
      subtitle: modifications.containsKey('subtitle')
          ? modifications['subtitle'] as String?
          : activeChart.subtitle,
      series: updatedSeries,
      xAxis: xAxis ?? activeChart.xAxis,
      yAxes: yAxes ?? activeChart.yAxes,
      annotations: annotations ?? activeChart.annotations,
      style: style ?? activeChart.style,
      interactions: interactions ?? activeChart.interactions,
      showGrid: modifications['showGrid'] as bool? ?? activeChart.showGrid,
      showLegend:
          modifications['showLegend'] as bool? ?? activeChart.showLegend,
      legendPosition: legendPosition ?? activeChart.legendPosition,
      useDarkTheme:
          modifications['useDarkTheme'] as bool? ?? activeChart.useDarkTheme,
      showScrollbar:
          modifications['showScrollbar'] as bool? ?? activeChart.showScrollbar,
      normalizationMode: normalizationMode ?? activeChart.normalizationMode,
      width: modifications.containsKey('width')
          ? (modifications['width'] as num?)?.toDouble()
          : activeChart.width,
      height: modifications.containsKey('height')
          ? (modifications['height'] as num?)?.toDouble()
          : activeChart.height,
      backgroundColor: modifications.containsKey('backgroundColor')
          ? modifications['backgroundColor'] as String?
          : activeChart.backgroundColor,
    );

    // Return success result with JSON output and ChartConfiguration data
    return ToolResult(
      output: jsonEncode(modifiedChart.toJson()),
      isError: false,
      data: modifiedChart,
    );
  }

  /// Parses a list of series input into [SeriesConfig] objects.
  ///
  /// Uses [SeriesConfig.fromJson] to parse ALL 25+ properties including
  /// strokeWidth, fillOpacity, tension, showPoints, markerSize, bar properties, etc.
  ///
  /// [startColorIndex] is used to assign default colors starting from that index.
  List<SeriesConfig> _parseSeries(
      List<dynamic> seriesInput, int startColorIndex) {
    final series = <SeriesConfig>[];
    for (int i = 0; i < seriesInput.length; i++) {
      final seriesMap = Map<String, dynamic>.from(seriesInput[i] as Map);

      // Assign default color if not provided
      if (seriesMap['color'] == null) {
        seriesMap['color'] =
            _defaultColors[(startColorIndex + i) % _defaultColors.length];
      }

      // Use fromJson to parse ALL properties
      series.add(SeriesConfig.fromJson(seriesMap));
    }
    return series;
  }

  /// Applies a partial update to a series, returning a new [SeriesConfig].
  ///
  /// Supports ALL 25+ series properties including type, strokeWidth, fillOpacity,
  /// tension, showPoints, markerSize, interpolation, bar properties, etc.
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

    // Parse enum values if provided
    ChartType? seriesType;
    if (update['type'] != null) {
      seriesType = ChartType.values.byName(update['type'] as String);
    }

    Interpolation? interpolation;
    if (update['interpolation'] != null) {
      interpolation =
          Interpolation.values.byName(update['interpolation'] as String);
    }

    MarkerStyle? markerStyle;
    if (update['markerStyle'] != null) {
      markerStyle = MarkerStyle.values.byName(update['markerStyle'] as String);
    }

    // Apply ALL properties via copyWith
    // Per FR-001/FR-002: Use nested yAxis instead of flat yAxisPosition/Label/etc.
    YAxisConfig? updatedYAxis;
    final hasYAxisUpdate = update['yAxisPosition'] != null ||
        update['yAxisLabel'] != null ||
        update['yAxisUnit'] != null ||
        update['yAxisColor'] != null ||
        update['yAxisMin'] != null ||
        update['yAxisMax'] != null ||
        update['yAxis'] != null;

    if (hasYAxisUpdate) {
      // Check if update provides a nested yAxis object (preferred format)
      final yAxisUpdate = update['yAxis'] as Map<String, dynamic>?;
      if (yAxisUpdate != null) {
        updatedYAxis = YAxisConfig(
          position: yAxisUpdate['position'] != null
              ? AxisPosition.values.byName(yAxisUpdate['position'] as String)
              : series.yAxis?.position ?? AxisPosition.left,
          label: yAxisUpdate['label'] as String? ?? series.yAxis?.label,
          unit: yAxisUpdate['unit'] as String? ?? series.yAxis?.unit,
          color: yAxisUpdate['color'] as String? ?? series.yAxis?.color,
          min: (yAxisUpdate['min'] as num?)?.toDouble() ?? series.yAxis?.min,
          max: (yAxisUpdate['max'] as num?)?.toDouble() ?? series.yAxis?.max,
        );
      } else {
        // Support legacy flat fields for backwards compatibility in input
        updatedYAxis = YAxisConfig(
          position: update['yAxisPosition'] != null
              ? AxisPosition.values.byName(update['yAxisPosition'] as String)
              : series.yAxis?.position ?? AxisPosition.left,
          label: update['yAxisLabel'] as String? ?? series.yAxis?.label,
          unit: update['yAxisUnit'] as String? ?? series.yAxis?.unit,
          color: update['yAxisColor'] as String? ?? series.yAxis?.color,
          min: (update['yAxisMin'] as num?)?.toDouble() ?? series.yAxis?.min,
          max: (update['yAxisMax'] as num?)?.toDouble() ?? series.yAxis?.max,
        );
      }
    }

    return series.copyWith(
      type: seriesType,
      name: update['name'] as String?,
      data: updatedData,
      color: update['color'] as String?,
      strokeWidth: (update['strokeWidth'] as num?)?.toDouble(),
      strokeDash: (update['strokeDash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      fillOpacity: (update['fillOpacity'] as num?)?.toDouble(),
      markerStyle: markerStyle,
      markerSize: (update['markerSize'] as num?)?.toDouble(),
      interpolation: interpolation,
      tension: (update['tension'] as num?)?.toDouble(),
      showPoints: update['showPoints'] as bool?,
      // Per FR-001: Use nested yAxis
      yAxis: updatedYAxis,
      barWidthPercent: (update['barWidthPercent'] as num?)?.toDouble(),
      barWidthPixels: (update['barWidthPixels'] as num?)?.toDouble(),
      barMinWidth: (update['barMinWidth'] as num?)?.toDouble(),
      barMaxWidth: (update['barMaxWidth'] as num?)?.toDouble(),
      // Per FR-003: yAxisId removed
      visible: update['visible'] as bool?,
      legendVisible: update['legendVisible'] as bool?,
      unit: update['unit'] as String?,
    );
  }

  /// Parses an X-axis configuration from a JSON map.
  XAxisConfig _parseXAxis(Map<String, dynamic> json) {
    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] != null
          ? AxisType.values.byName(json['type'] as String)
          : AxisType.numeric,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      autoRange: json['autoRange'] as bool? ?? true,
      paddingPercent: (json['paddingPercent'] as num?)?.toDouble() ?? 0.0,
      tickCount: json['tickCount'] as int?,
      tickFormat: json['tickFormat'] as String?,
      tickRotation: (json['tickRotation'] as num?)?.toDouble() ?? 0.0,
      showTicks: json['showTicks'] as bool? ?? true,
      showAxisLine: json['showAxisLine'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? true,
      gridColor: json['gridColor'] as String?,
      gridDash: (json['gridDash'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  /// Parses a list of Y-axis configurations from a JSON list.
  List<YAxisConfig> _parseYAxes(List<dynamic> yAxesInput) {
    return yAxesInput.map((json) {
      final map = json as Map<String, dynamic>;
      return YAxisConfig(
        id: map['id'] as String?,
        label: map['label'] as String?,
        unit: map['unit'] as String?,
        position: map['position'] != null
            ? AxisPosition.values.byName(map['position'] as String)
            : AxisPosition.left,
        min: (map['min'] as num?)?.toDouble(),
        max: (map['max'] as num?)?.toDouble(),
        autoRange: map['autoRange'] as bool? ?? true,
        includeZero: map['includeZero'] as bool? ?? false,
        paddingPercent: (map['paddingPercent'] as num?)?.toDouble() ?? 0.0,
        tickCount: map['tickCount'] as int?,
        tickFormat: map['tickFormat'] as String?,
        showTicks: map['showTicks'] as bool? ?? true,
        showAxisLine: map['showAxisLine'] as bool? ?? true,
        showGridLines: map['showGridLines'] as bool? ?? true,
        gridColor: map['gridColor'] as String?,
        color: map['color'] as String?,
      );
    }).toList();
  }
}
