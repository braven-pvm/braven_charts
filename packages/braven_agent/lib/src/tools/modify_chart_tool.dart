import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/annotation_config.dart';
import '../models/chart_configuration.dart';
import '../models/chart_style_config.dart';
import '../models/data_point.dart';
import '../models/enums.dart';
import '../models/series_config.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../validation/schema_validator.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for modifying existing chart configurations (V2 Schema).
///
/// This tool applies incremental changes to an existing chart configuration
/// using add/update/remove operations. It implements deep merge semantics
/// for nested objects like [YAxisConfig].
///
/// ## V2 Schema: Deep Merge Behavior
///
/// When updating a series, nested objects are **deep-merged**:
///
/// - **Scalar values**: Replaced with new values
/// - **Nested objects** (e.g., yAxis): Merged field-by-field
/// - **Arrays** (e.g., data): Replaced entirely
/// - **Unspecified fields**: Preserved from original
///
/// ### Example: Partial yAxis Update
///
/// Original series:
/// ```json
/// {"id": "temp", "yAxis": {"min": 0, "max": 100, "label": "Temp"}}
/// ```
///
/// Update:
/// ```json
/// {"modifications": {"update": {"series": [{"id": "temp", "yAxis": {"max": 150}}]}}}
/// ```
///
/// Result (min and label preserved):
/// ```json
/// {"id": "temp", "yAxis": {"min": 0, "max": 150, "label": "Temp"}}
/// ```
///
/// ## Operations
///
/// The tool supports three operation types in `modifications`:
///
/// ### add
/// Adds new series or annotations. Annotation IDs are system-generated.
/// ```json
/// {"add": {"series": [{"id": "new", "data": [...]}]}}
/// ```
///
/// ### update
/// Updates existing series or annotations by ID.
/// ```json
/// {"update": {"series": [{"id": "existing", "color": "#FF0000"}]}}
/// ```
///
/// ### remove
/// Removes series or annotations by ID.
/// ```json
/// {"remove": {"series": ["old_series"], "annotations": ["ann-uuid"]}}
/// ```
///
/// ## Validation (V010-V022)
///
/// The tool validates operations using [SchemaValidator]:
/// - **V010**: Error if update.series[].id not found
/// - **V011**: Error if remove.series contains non-existent ID
/// - **V012**: Error if add.series[].id already exists
/// - **V020**: Error if update.annotations[].id not found
/// - **V021**: Error if remove.annotations contains non-existent ID
/// - **V022**: Warning if agent supplies annotation ID (ignored)
///
/// ## Output
///
/// Returns a [ToolResult] with:
/// - `output`: JSON string describing modifications applied
/// - `data`: Updated [ChartConfiguration] object
/// - `isError`: true if no active chart or validation fails
///
/// See also:
/// - [CreateChartTool] for creating new charts
/// - [GetChartTool] for discovering IDs before modification
/// - [SchemaValidator] for validation rules V010-V022
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

  /// UUID generator for new annotation IDs.
  static const _uuid = Uuid();

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
      'Use this tool to change chart type, update titles, add/remove/update series, '
      'add/remove annotations, or adjust styling options. '
      'Requires an active chart created previously.\n\n'
      'IMPORTANT - How to REMOVE items:\n'
      '- To REMOVE SPECIFIC series: use "remove.series": ["seriesId1", "seriesId2"]\n'
      '- To REMOVE SPECIFIC annotations: use "remove.annotations": ["annId1", "annId2"]\n'
      '- Remove operations only affect the listed items; all others are preserved.';

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
              'update': {
                'type': 'object',
                'description': 'Update existing series/annotations by id. Only specified properties are changed.',
                'properties': {
                  'series': {
                    'type': 'array',
                    'description': 'Series updates (matched by id).',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'id': {
                          'type': 'string',
                          'description': 'ID of the series to update',
                        },
                        'type': {
                          'type': 'string',
                          'enum': ['line', 'area', 'bar', 'scatter'],
                          'description': 'Change the series type (line, area, bar, scatter)',
                        },
                        'name': {
                          'type': 'string',
                          'description': 'Display name',
                        },
                        'color': {
                          'type': 'string',
                          'description': 'Color (hex format, e.g., "#FF0000")',
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
                        },
                        'strokeDash': {
                          'type': 'array',
                          'items': {'type': 'number'},
                        },
                        'fillOpacity': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                        },
                        'tension': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                        },
                        'showPoints': {'type': 'boolean'},
                        'interpolation': {
                          'type': 'string',
                          'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                        },
                        'markerStyle': {
                          'type': 'string',
                          'enum': ['none', 'circle', 'square', 'triangle', 'diamond'],
                        },
                        'markerSize': {
                          'type': 'number',
                          'minimum': 0,
                        },
                        'unit': {
                          'type': 'string',
                        },
                        'visible': {'type': 'boolean'},
                        'legendVisible': {'type': 'boolean'},
                        'barWidthPercent': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                        },
                        'barWidthPixels': {'type': 'number', 'minimum': 0},
                        'barMinWidth': {'type': 'number', 'minimum': 0},
                        'barMaxWidth': {'type': 'number', 'minimum': 0},
                        'yAxis': {
                          'type': 'object',
                          'description': 'Nested yAxis updates (deep-merged with existing).',
                          'properties': {
                            'position': {
                              'type': 'string',
                              'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                            },
                            'label': {'type': 'string'},
                            'unit': {'type': 'string'},
                            'color': {'type': 'string'},
                            'min': {'type': 'number'},
                            'max': {'type': 'number'},
                          },
                        },
                      },
                      'required': ['id'],
                    },
                  },
                  'annotations': {
                    'type': 'array',
                    'description': 'Update existing annotations by ID. Use get_chart first to discover annotation IDs.',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'id': {
                          'type': 'string',
                          'description': 'REQUIRED: ID of the annotation to update (use get_chart to find IDs)',
                        },
                        'type': {
                          'type': 'string',
                          'enum': ['referenceLine', 'zone', 'textLabel', 'marker', 'trendLine'],
                          'description': 'Cannot change type after creation.',
                        },
                        'value': {
                          'type': 'number',
                          'description': 'For referenceLine: the position value.',
                        },
                        'minValue': {
                          'type': 'number',
                          'description': 'For zone: lower bound.',
                        },
                        'maxValue': {
                          'type': 'number',
                          'description': 'For zone: upper bound.',
                        },
                        'startX': {'type': 'number', 'description': 'For zone custom rectangle: left X bound.'},
                        'endX': {'type': 'number', 'description': 'For zone custom rectangle: right X bound.'},
                        'startY': {'type': 'number', 'description': 'For zone custom rectangle: bottom Y bound.'},
                        'endY': {'type': 'number', 'description': 'For zone custom rectangle: top Y bound.'},
                        'x': {'type': 'number', 'description': 'For textLabel/marker: X position.'},
                        'y': {'type': 'number', 'description': 'For textLabel/marker: Y position.'},
                        'text': {'type': 'string', 'description': 'For textLabel: text content.'},
                        'label': {'type': 'string', 'description': 'Display label.'},
                        'color': {'type': 'string', 'description': 'Color in hex format.'},
                        'lineWidth': {'type': 'number', 'description': 'For lines: thickness.'},
                        'dashPattern': {
                          'type': 'array',
                          'items': {'type': 'number'},
                          'description': 'Dash pattern for lines.',
                        },
                        'opacity': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                          'description': 'For zone: fill opacity.',
                        },
                        'orientation': {
                          'type': 'string',
                          'enum': ['horizontal', 'vertical'],
                          'description': 'For referenceLine/zone.',
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
                          'description': 'For textLabel: position in chart.',
                        },
                        'fontSize': {'type': 'number', 'description': 'For textLabel: font size.'},
                        'seriesId': {'type': 'string', 'description': 'Series association.'},
                        'trendType': {
                          'type': 'string',
                          'enum': ['linear', 'polynomial', 'movingAverage', 'exponentialMovingAverage'],
                          'description': 'ONLY for trendLine type.',
                        },
                      },
                      'required': ['id'],
                    },
                  },
                },
              },
              'add': {
                'type': 'object',
                'description': 'Add new series and annotations.',
                'properties': {
                  'series': {
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
                          'description': 'Type of chart series (line, area, bar, scatter). Each series can have its own type. Defaults to line.',
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
                        'unit': {
                          'type': 'string',
                          'description': 'Unit of measurement for this series (e.g., "W", "bpm").',
                        },
                        'interpolation': {
                          'type': 'string',
                          'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                          'description': 'Line interpolation type. Defaults to "linear".',
                        },
                        'strokeWidth': {
                          'type': 'number',
                          'minimum': 0,
                          'description': 'Width of the line stroke in pixels. Defaults to 2.0.',
                        },
                        'tension': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                          'description': 'Curve tension for bezier interpolation (0.0 to 1.0).',
                        },
                        'showPoints': {
                          'type': 'boolean',
                          'description': 'Whether to show data point markers. Defaults to false.',
                        },
                        'fillOpacity': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                          'description': 'Fill opacity for area charts (0.0 to 1.0). Defaults to 0.3.',
                        },
                        'markerStyle': {
                          'type': 'string',
                          'enum': ['none', 'circle', 'square', 'triangle', 'diamond'],
                          'description': 'Style of markers at data points.',
                        },
                        'markerSize': {
                          'type': 'number',
                          'minimum': 0,
                          'description': 'Size of markers in pixels. Defaults to 4.0.',
                        },
                        'barWidthPercent': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                          'description': 'Bar width as a percentage of available space (0.0 to 1.0).',
                        },
                        'barWidthPixels': {
                          'type': 'number',
                          'minimum': 0,
                          'description': 'Fixed bar width in pixels. Overrides barWidthPercent.',
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
                        'visible': {
                          'type': 'boolean',
                          'description': 'Whether this series is visible.',
                        },
                        'legendVisible': {
                          'type': 'boolean',
                          'description': 'Whether to show this series in the legend.',
                        },
                        'strokeDash': {
                          'type': 'array',
                          'items': {'type': 'number'},
                          'description': 'Dash pattern for line stroke (e.g., [5, 3] for dashed).',
                        },
                        'yAxis': {
                          'type': 'object',
                          'description': 'Nested Y-axis configuration for this series.',
                          'properties': {
                            'position': {
                              'type': 'string',
                              'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                              'description': 'Position of the y-axis (left, right, leftOuter, rightOuter).',
                            },
                            'label': {
                              'type': 'string',
                              'description': 'Label for the y-axis.',
                            },
                            'unit': {
                              'type': 'string',
                              'description': 'Unit of measurement (e.g., "W", "bpm").',
                            },
                            'color': {
                              'type': 'string',
                              'description': 'Color for the y-axis elements.',
                            },
                            'min': {
                              'type': 'number',
                              'description': 'Minimum value for the y-axis.',
                            },
                            'max': {
                              'type': 'number',
                              'description': 'Maximum value for the y-axis.',
                            },
                          },
                        },
                      },
                      'required': ['id', 'data'],
                    },
                  },
                  'annotations': {
                    'type': 'array',
                    'description': '''Annotations to add. IMPORTANT: Include ALL properties in ONE annotation object.

ANNOTATION TYPE REQUIREMENTS:
- referenceLine: REQUIRES value, orientation. Use color, lineWidth, label. NO trendType!
- zone: REQUIRES (minValue + maxValue + orientation) OR (startX/endX and/or startY/endY). Use color, opacity, label. NO trendType!
- trendLine: REQUIRES seriesId, trendType. Use color, lineWidth, label.
- textLabel: REQUIRES x, y, text. Use color, fontSize.
- marker: REQUIRES x, y. Use color, label.

CRITICAL: Do NOT add trendType to zones or referenceLines - it will be ignored.
CRITICAL: Include color, opacity, label in the SAME call - do not make separate update calls.''',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'id': {
                          'type': 'string',
                          'description': 'Ignored - system generates IDs automatically.',
                        },
                        'type': {
                          'type': 'string',
                          'enum': ['referenceLine', 'zone', 'textLabel', 'marker', 'trendLine'],
                          'description': 'Annotation type. Each type has different required fields - see description above.',
                        },
                        'value': {
                          'type': 'number',
                          'description': 'REQUIRED for referenceLine only. The Y-value (horizontal) or X-value (vertical) where line appears.',
                        },
                        'minValue': {
                          'type': 'number',
                          'description': 'For zone with orientation: lower bound of the range.',
                        },
                        'maxValue': {
                          'type': 'number',
                          'description': 'For zone with orientation: upper bound of the range.',
                        },
                        'startX': {
                          'type': 'number',
                          'description': 'For zone custom rectangle: left X bound.',
                        },
                        'endX': {
                          'type': 'number',
                          'description': 'For zone custom rectangle: right X bound.',
                        },
                        'startY': {
                          'type': 'number',
                          'description': 'For zone custom rectangle: bottom Y bound.',
                        },
                        'endY': {
                          'type': 'number',
                          'description': 'For zone custom rectangle: top Y bound.',
                        },
                        'x': {
                          'type': 'number',
                          'description': 'For textLabel/marker: X position.',
                        },
                        'y': {
                          'type': 'number',
                          'description': 'For textLabel/marker: Y position.',
                        },
                        'text': {
                          'type': 'string',
                          'description': 'For textLabel: the text content to display.',
                        },
                        'label': {
                          'type': 'string',
                          'description': 'Display label for any annotation type.',
                        },
                        'color': {
                          'type': 'string',
                          'description': 'Color in hex format (e.g., "#FF0000"). Always specify for visibility.',
                        },
                        'lineWidth': {
                          'type': 'number',
                          'description': 'Line thickness for referenceLine/trendLine.',
                        },
                        'dashPattern': {
                          'type': 'array',
                          'items': {'type': 'number'},
                          'description': 'Dash pattern for lines, e.g., [5, 3] for dashed.',
                        },
                        'opacity': {
                          'type': 'number',
                          'minimum': 0,
                          'maximum': 1,
                          'description': 'For zone: fill opacity (0.1-0.2 recommended).',
                        },
                        'orientation': {
                          'type': 'string',
                          'enum': ['horizontal', 'vertical'],
                          'description': 'For referenceLine/zone: horizontal (Y-axis) or vertical (X-axis).',
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
                          'description': 'For textLabel: position within chart area.',
                        },
                        'fontSize': {
                          'type': 'number',
                          'description': 'For textLabel: font size in pixels.',
                        },
                        'seriesId': {
                          'type': 'string',
                          'description':
                              'REQUIRED for trendLine. For horizontal referenceLine/zone in perSeries mode, specifies which series Y-axis to use.',
                        },
                        'trendType': {
                          'type': 'string',
                          'enum': ['linear', 'polynomial', 'movingAverage', 'exponentialMovingAverage'],
                          'description': 'ONLY for trendLine type. Do NOT use with zone or referenceLine.',
                        },
                      },
                      'required': ['type'],
                    },
                  },
                },
              },
              'remove': {
                'type': 'object',
                'description': 'Remove series or annotations by id.',
                'properties': {
                  'series': {
                    'type': 'array',
                    'description': 'IDs of series to remove from the chart.',
                    'items': {'type': 'string'},
                  },
                  'annotations': {
                    'type': 'array',
                    'description': 'IDs of annotations to remove from the chart.',
                    'items': {'type': 'string'},
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
              'xAxis': {
                'type': 'object',
                'description': 'X-axis configuration. Partial updates merge with existing config.',
                'properties': {
                  'label': {'type': 'string', 'description': 'Axis label (e.g., "Time")'},
                  'unit': {'type': 'string', 'description': 'Unit string (e.g., "seconds")'},
                  'min': {'type': 'number', 'description': 'Minimum value for X-axis scale'},
                  'max': {'type': 'number', 'description': 'Maximum value for X-axis scale'},
                  'autoRange': {'type': 'boolean', 'description': 'Auto-calculate range from data'},
                  'tickCount': {'type': 'integer', 'description': 'Number of ticks to display'},
                  'showTicks': {'type': 'boolean', 'description': 'Whether to show tick marks'},
                  'showAxisLine': {'type': 'boolean', 'description': 'Whether to show the axis line'},
                  'showGridLines': {'type': 'boolean', 'description': 'Whether to show vertical grid lines'},
                  'visible': {'type': 'boolean', 'description': 'Whether the X-axis is visible'},
                },
              },
              'yAxes': {
                'type': 'array',
                'description': 'SHARED Y-axis configurations. REPLACES all existing Y-axes. '
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
                    'label': {'type': 'string', 'description': 'Axis label (e.g., "Power")'},
                    'unit': {'type': 'string', 'description': 'Unit string (e.g., "W")'},
                    'position': {
                      'type': 'string',
                      'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                      'description': 'Position of the Y-axis',
                    },
                    'min': {'type': 'number', 'description': 'Minimum value for Y-axis scale'},
                    'max': {'type': 'number', 'description': 'Maximum value for Y-axis scale'},
                    'autoRange': {'type': 'boolean', 'description': 'Auto-calculate range from data'},
                    'includeZero': {'type': 'boolean', 'description': 'Whether range should include zero'},
                    'color': {'type': 'string', 'description': 'Axis color (hex format)'},
                    'showTicks': {'type': 'boolean', 'description': 'Whether to show tick marks'},
                    'showAxisLine': {'type': 'boolean', 'description': 'Whether to show the axis line'},
                    'showGridLines': {'type': 'boolean', 'description': 'Whether to show horizontal grid lines'},
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
                      'enum': ['referenceLine', 'zone', 'textLabel', 'marker', 'trendLine'],
                      'description': 'Type of annotation: referenceLine (horizontal/vertical line at value), '
                          'zone (shaded region), textLabel (text at position), marker (point marker), '
                          'trendLine (trend line calculated from series data)',
                    },
                    'value': {
                      'type': 'number',
                      'description': 'Value for referenceLine. For horizontal lines, this is the Y-axis value '
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
                      'description': 'Label text displayed with the annotation (for all types)',
                    },
                    'color': {
                      'type': 'string',
                      'description': 'Color of the annotation (hex format, e.g., "#FF0000")',
                    },
                    'lineWidth': {
                      'type': 'number',
                      'description': 'Line width for referenceLine/trendLine annotations',
                    },
                    'dashPattern': {
                      'type': 'array',
                      'items': {'type': 'number'},
                      'description': 'Dash pattern for referenceLine/trendLine (e.g., [5, 3] for dashed)',
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
                      'description': 'Orientation for referenceLine/zone (horizontal = Y axis, vertical = X axis)',
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
                      'description': 'REQUIRED for trendLine. REQUIRED for perSeries normalization on referenceLine/zone: '
                          'ID of the series whose data range determines annotation positioning.',
                    },
                    'trendType': {
                      'type': 'string',
                      'enum': ['linear', 'polynomial', 'movingAverage', 'exponentialMovingAverage'],
                      'description': 'REQUIRED for trendLine: Type of trend. Use "linear" for best-fit line (most common).',
                    },
                  },
                  'required': ['type'],
                },
              },
              'style': {
                'type': 'object',
                'description': 'Visual styling configuration for the chart',
                'properties': {
                  'titleFontSize': {'type': 'number', 'description': 'Font size for chart title'},
                  'subtitleFontSize': {'type': 'number', 'description': 'Font size for chart subtitle'},
                  'axisFontSize': {'type': 'number', 'description': 'Font size for axis labels'},
                  'legendFontSize': {'type': 'number', 'description': 'Font size for legend text'},
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
                'description': 'Interaction configuration for pan/zoom/tooltip behavior',
                'properties': {
                  'crosshairMode': {
                    'type': 'string',
                    'enum': ['none', 'vertical', 'horizontal', 'both'],
                    'description': 'Crosshair display mode',
                  },
                  'tooltipPosition': {
                    'type': 'string',
                    'enum': ['auto', 'top', 'bottom', 'left', 'right', 'nearestPoint'],
                    'description': 'Preferred tooltip position',
                  },
                  'enableZoom': {'type': 'boolean', 'description': 'Whether zooming is enabled'},
                  'enablePan': {'type': 'boolean', 'description': 'Whether panning is enabled'},
                  'snapToPoint': {'type': 'boolean', 'description': 'Whether crosshair snaps to nearest point'},
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
                'description': 'Background color of the chart (hex format, e.g., "#FFFFFF")',
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

  /// Validates an annotation config and returns an error message if invalid.
  /// Returns null if valid.
  String? _validateAnnotation(AnnotationConfig annotation, List<SeriesConfig> series) {
    final seriesIds = series.map((s) => s.id).toSet();

    // V030: seriesId reference validation for trendLine
    if (annotation.type == AnnotationType.trendLine) {
      if (annotation.seriesId == null || annotation.seriesId!.isEmpty) {
        return 'INVALID TRENDLINE - MISSING seriesId. REQUIRED: seriesId from [${seriesIds.join(", ")}]. '
            'SEND THIS: {"type": "trendLine", "seriesId": "${seriesIds.firstOrNull ?? "series1"}", "trendType": "linear", "color": "#FF6600"}';
      }
      if (!seriesIds.contains(annotation.seriesId)) {
        return 'INVALID TRENDLINE - seriesId "${annotation.seriesId}" NOT FOUND. '
            'USE ONE OF: [${seriesIds.join(", ")}]. '
            'SEND THIS: {"type": "trendLine", "seriesId": "${seriesIds.first}", "trendType": "linear", "color": "#FF6600"}';
      }
    }

    // V040: referenceLine requires value
    if (annotation.type == AnnotationType.referenceLine && annotation.value == null) {
      final orientation = annotation.orientation?.name ?? 'horizontal';
      return 'INVALID REFERENCELINE - MISSING value. '
          'SEND THIS: {"type": "referenceLine", "value": 50, "orientation": "$orientation", "color": "#FF0000", "lineWidth": 2, "label": "Threshold"}';
    }

    // V041: zone requires bounds
    if (annotation.type == AnnotationType.zone) {
      final hasMinMax = annotation.minValue != null && annotation.maxValue != null;
      final hasCustomBounds = annotation.startX != null || annotation.endX != null || annotation.startY != null || annotation.endY != null;

      if (!hasMinMax && !hasCustomBounds) {
        // CRITICAL: Put the fix FIRST, make it extremely short and direct
        final orientation = annotation.orientation?.name ?? 'vertical';
        return 'INVALID ZONE - MISSING BOUNDS. '
            'REQUIRED FIELDS: minValue, maxValue. '
            'SEND THIS: {"type": "zone", "orientation": "$orientation", "minValue": 2.5, "maxValue": 6, "color": "#0000FF", "opacity": 0.15, "label": "mid-range"}';
      }
    }

    // V042: marker with seriesId requires dataPointIndex or x/y
    if (annotation.type == AnnotationType.marker &&
        annotation.seriesId != null &&
        annotation.seriesId!.isNotEmpty &&
        annotation.dataPointIndex == null &&
        annotation.x == null &&
        annotation.y == null) {
      return '[V042] Marker with seriesId requires dataPointIndex or x/y coordinates.';
    }

    // V044: textLabel requires text
    if (annotation.type == AnnotationType.textLabel && (annotation.text == null || annotation.text!.isEmpty)) {
      return '[V044] TextLabel requires text property.';
    }

    return null; // Valid
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

    // Debug: Log the annotations in the active chart
    // ignore: avoid_print
    print('[ModifyChartTool] Active chart has ${activeChart.annotations.length} annotations:');
    for (final ann in activeChart.annotations) {
      // ignore: avoid_print
      print('[ModifyChartTool]   - ${ann.id}: ${ann.type.name} "${ann.label ?? 'no label'}"');
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
    final normalizationModeInput = modifications['normalizationMode'] as String?;
    if (normalizationModeInput != null) {
      try {
        normalizationMode = NormalizationModeConfig.values.byName(normalizationModeInput);
      } catch (_) {
        return _logError(
          'Error: Invalid normalization mode "$normalizationModeInput". '
          'Valid modes are: none, auto, perSeries.',
          input,
        );
      }
    }

    final updateInput = modifications['update'] as Map<String, dynamic>?;
    final addInput = modifications['add'] as Map<String, dynamic>?;
    final removeInput = modifications['remove'] as Map<String, dynamic>?;

    final validation = SchemaValidator.validateModification(
      activeChart,
      _buildModificationRequest(updateInput, addInput, removeInput),
    );
    if (validation.errors.isNotEmpty) {
      final message = validation.errors.map((e) => e.toString()).join(' ');
      return _logError('Error: $message', input);
    }

    final addedSeriesIds = <String>[];
    final addedAnnotationIds = <String>[];

    // Start with the existing series/annotations
    var updatedSeries = List<SeriesConfig>.from(activeChart.series);
    var updatedAnnotations = List<AnnotationConfig>.from(activeChart.annotations);

    // Execution order: remove -> add -> update
    final removeSeries = removeInput?['series'] as List?;
    if (removeSeries != null) {
      final idsToRemove = removeSeries.cast<String>().toSet();
      updatedSeries = updatedSeries.where((s) => !idsToRemove.contains(s.id)).toList();
    }
    final removeAnnotations = removeInput?['annotations'] as List?;
    if (removeAnnotations != null) {
      final idsToRemove = removeAnnotations.cast<String>().toSet();
      updatedAnnotations = updatedAnnotations.where((a) => a.id == null || !idsToRemove.contains(a.id)).toList();
    }

    final addSeries = addInput?['series'] as List?;
    if (addSeries != null) {
      final newSeries = _parseSeries(addSeries, updatedSeries.length);
      updatedSeries.addAll(newSeries);
      addedSeriesIds.addAll(newSeries.map((s) => s.id));
    }

    final addAnnotations = addInput?['annotations'] as List?;
    if (addAnnotations != null) {
      final annotationErrors = <String>[];
      for (final entry in addAnnotations) {
        final annotationMap = Map<String, dynamic>.from(entry as Map);
        annotationMap.remove('id');
        final parsed = AnnotationConfig.fromJson(annotationMap);

        // Validate annotation before adding
        final error = _validateAnnotation(parsed, updatedSeries);
        if (error != null) {
          annotationErrors.add(error);
          continue;
        }

        final annotationWithId = parsed.copyWith(id: 'ann-${_uuid.v4()}');
        updatedAnnotations.add(annotationWithId);
        addedAnnotationIds.add(annotationWithId.id!);
      }

      if (annotationErrors.isNotEmpty) {
        // Don't add extra "Error: " prefix - the validation messages are self-explanatory
        return _logError(annotationErrors.join(' '), input);
      }
    }

    final updateSeriesInput = updateInput?['series'] as List?;
    if (updateSeriesInput != null) {
      const validTypes = ['line', 'area', 'bar', 'scatter'];
      final updatesById = <String, Map<String, dynamic>>{};
      for (final entry in updateSeriesInput) {
        final updateMap = Map<String, dynamic>.from(entry as Map);
        final seriesId = updateMap['id'] as String?;
        if (seriesId == null || seriesId.isEmpty) {
          continue;
        }
        final typeValue = updateMap['type'] as String?;
        if (typeValue != null && !validTypes.contains(typeValue)) {
          return _logError(
            'Error: Invalid series type "$typeValue" for series "$seriesId". '
            'Valid types are: line, area, bar, scatter.',
            input,
          );
        }
        updatesById[seriesId] = updateMap;
      }

      updatedSeries = updatedSeries.map((series) {
        final update = updatesById[series.id];
        if (update != null) {
          return _applySeriesUpdate(series, update);
        }
        return series;
      }).toList();
    }

    final updateAnnotationsInput = updateInput?['annotations'] as List?;
    if (updateAnnotationsInput != null) {
      final updatesById = <String, Map<String, dynamic>>{};
      for (final entry in updateAnnotationsInput) {
        final updateMap = Map<String, dynamic>.from(entry as Map);
        final annotationId = updateMap['id'] as String?;
        if (annotationId == null || annotationId.isEmpty) {
          continue;
        }
        updatesById[annotationId] = updateMap;
      }

      updatedAnnotations = updatedAnnotations.map((annotation) {
        final update = annotation.id != null ? updatesById[annotation.id] : null;
        if (update != null) {
          return _applyAnnotationUpdate(annotation, update);
        }
        return annotation;
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

    // Validate annotation seriesId references against updated series
    final validSeriesIds = updatedSeries.map((s) => s.id).toSet();
    for (final annotation in updatedAnnotations) {
      if (annotation.seriesId != null && !validSeriesIds.contains(annotation.seriesId)) {
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
    final effectiveNormMode = normalizationMode ?? activeChart.normalizationMode;

    // Validate horizontal annotations have seriesId in perSeries mode
    if (effectiveNormMode == NormalizationModeConfig.perSeries) {
      for (final annotation in updatedAnnotations) {
        if (annotation.type == AnnotationType.referenceLine && annotation.orientation != Orientation.vertical && annotation.seriesId == null) {
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
    for (final annotation in updatedAnnotations) {
      if (annotation.type == AnnotationType.referenceLine && annotation.value == null) {
        return _logError(
          'Error: referenceLine annotation requires a "value" property. '
          'The value should be in the same units as the target series data. '
          'Example: for a power series with range 0-500W, value: 200 draws a line at 200W.',
          input,
        );
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
    final interactionsInput = modifications['interactions'] as Map<String, dynamic>?;
    if (interactionsInput != null) {
      interactions = interactionsInput;
    }

    // Build modified chart configuration using copyWith
    final modifiedChart = activeChart.copyWith(
      title: modifications.containsKey('title') ? modifications['title'] as String? : activeChart.title,
      subtitle: modifications.containsKey('subtitle') ? modifications['subtitle'] as String? : activeChart.subtitle,
      series: updatedSeries,
      xAxis: xAxis ?? activeChart.xAxis,
      yAxes: yAxes ?? activeChart.yAxes,
      annotations: updatedAnnotations,
      style: style ?? activeChart.style,
      interactions: interactions ?? activeChart.interactions,
      showGrid: modifications['showGrid'] as bool? ?? activeChart.showGrid,
      showLegend: modifications['showLegend'] as bool? ?? activeChart.showLegend,
      legendPosition: legendPosition ?? activeChart.legendPosition,
      useDarkTheme: modifications['useDarkTheme'] as bool? ?? activeChart.useDarkTheme,
      showScrollbar: modifications['showScrollbar'] as bool? ?? activeChart.showScrollbar,
      normalizationMode: normalizationMode ?? activeChart.normalizationMode,
      width: modifications.containsKey('width') ? (modifications['width'] as num?)?.toDouble() : activeChart.width,
      height: modifications.containsKey('height') ? (modifications['height'] as num?)?.toDouble() : activeChart.height,
      backgroundColor: modifications.containsKey('backgroundColor') ? modifications['backgroundColor'] as String? : activeChart.backgroundColor,
    );

    // Return success result with JSON output and ChartConfiguration data
    final outputPayload = <String, dynamic>{
      'chart': modifiedChart.toJson(),
    };
    if (addedSeriesIds.isNotEmpty || addedAnnotationIds.isNotEmpty) {
      outputPayload['added'] = {
        if (addedSeriesIds.isNotEmpty) 'series': addedSeriesIds,
        if (addedAnnotationIds.isNotEmpty) 'annotations': addedAnnotationIds,
      };
    }
    if (validation.warnings.isNotEmpty) {
      outputPayload['warnings'] = validation.warnings
          .map((warning) => {
                'code': warning.code,
                'message': warning.message,
              })
          .toList();
    }

    return ToolResult(
      output: jsonEncode(outputPayload),
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
  List<SeriesConfig> _parseSeries(List<dynamic> seriesInput, int startColorIndex) {
    final series = <SeriesConfig>[];
    for (int i = 0; i < seriesInput.length; i++) {
      final seriesMap = Map<String, dynamic>.from(seriesInput[i] as Map);

      // Assign default color if not provided
      if (seriesMap['color'] == null) {
        seriesMap['color'] = _defaultColors[(startColorIndex + i) % _defaultColors.length];
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
      interpolation = Interpolation.values.byName(update['interpolation'] as String);
    }

    MarkerStyle? markerStyle;
    if (update['markerStyle'] != null) {
      markerStyle = MarkerStyle.values.byName(update['markerStyle'] as String);
    }

    // Apply ALL properties via copyWith
    YAxisConfig? updatedYAxis;
    final yAxisUpdate = update['yAxis'] as Map<String, dynamic>?;
    if (yAxisUpdate != null) {
      updatedYAxis = _mergeYAxis(series.yAxis, yAxisUpdate);
    }

    return series.copyWith(
      type: seriesType,
      name: update['name'] as String?,
      data: updatedData,
      color: update['color'] as String?,
      strokeWidth: (update['strokeWidth'] as num?)?.toDouble(),
      strokeDash: (update['strokeDash'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
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

  YAxisConfig _mergeYAxis(
    YAxisConfig? existing,
    Map<String, dynamic> update,
  ) {
    final base = existing?.toJson() ?? <String, dynamic>{};
    final merged = _deepMerge(base, update);
    return YAxisConfig.fromJson(merged);
  }

  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> update,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in update.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(
          Map<String, dynamic>.from(result[key] as Map),
          value,
        );
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  AnnotationConfig _applyAnnotationUpdate(
    AnnotationConfig annotation,
    Map<String, dynamic> update,
  ) {
    AnnotationType? updatedType;
    if (update['type'] != null) {
      updatedType = AnnotationType.values.byName(update['type'] as String);
    }

    Orientation? orientation;
    if (update['orientation'] != null) {
      orientation = Orientation.values.byName(update['orientation'] as String);
    }

    AnnotationPosition? position;
    if (update['position'] != null) {
      position = AnnotationPosition.values.byName(update['position'] as String);
    }

    TrendType? trendType;
    if (update['trendType'] != null) {
      trendType = TrendType.values.byName(update['trendType'] as String);
    }

    return annotation.copyWith(
      type: updatedType,
      orientation: orientation,
      value: (update['value'] as num?)?.toDouble(),
      minValue: (update['minValue'] as num?)?.toDouble(),
      maxValue: (update['maxValue'] as num?)?.toDouble(),
      startX: (update['startX'] as num?)?.toDouble(),
      endX: (update['endX'] as num?)?.toDouble(),
      startY: (update['startY'] as num?)?.toDouble(),
      endY: (update['endY'] as num?)?.toDouble(),
      x: (update['x'] as num?)?.toDouble(),
      y: (update['y'] as num?)?.toDouble(),
      position: position,
      text: update['text'] as String?,
      label: update['label'] as String?,
      color: update['color'] as String?,
      opacity: (update['opacity'] as num?)?.toDouble(),
      fontSize: (update['fontSize'] as num?)?.toDouble(),
      lineWidth: (update['lineWidth'] as num?)?.toDouble(),
      dashPattern: (update['dashPattern'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      seriesId: update['seriesId'] as String?,
      trendType: trendType,
      degree: update['degree'] as int?,
      windowSize: update['windowSize'] as int?,
    );
  }

  ModificationRequest _buildModificationRequest(
    Map<String, dynamic>? updateInput,
    Map<String, dynamic>? addInput,
    Map<String, dynamic>? removeInput,
  ) {
    UpdateOperation? update;
    if (updateInput != null) {
      final seriesInput = updateInput['series'] as List?;
      final updateSeries = seriesInput
          ?.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            final id = map['id'] as String?;
            if (id == null || id.isEmpty) {
              return null;
            }
            return SeriesModification(
              id: id,
              name: map['name'] as String?,
              color: map['color'] as String?,
              yAxis: map['yAxis'] as Map<String, dynamic>?,
            );
          })
          .whereType<SeriesModification>()
          .toList();

      final annotationsInput = updateInput['annotations'] as List?;
      final updateAnnotations = annotationsInput
          ?.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            final id = map['id'] as String?;
            if (id == null || id.isEmpty) {
              return null;
            }
            return AnnotationModification(
              id: id,
              label: map['label'] as String?,
              color: map['color'] as String?,
              value: (map['value'] as num?)?.toDouble(),
            );
          })
          .whereType<AnnotationModification>()
          .toList();

      if ((updateSeries != null && updateSeries.isNotEmpty) || (updateAnnotations != null && updateAnnotations.isNotEmpty)) {
        update = UpdateOperation(
          series: updateSeries,
          annotations: updateAnnotations,
        );
      }
    }

    AddOperation? add;
    if (addInput != null) {
      final seriesInput = addInput['series'] as List?;
      final addSeries = seriesInput
          ?.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            final id = map['id'] as String?;
            if (id == null || id.isEmpty) {
              return null;
            }
            return SeriesAddition(
              id: id,
              data: (map['data'] as List?) ?? const <dynamic>[],
              name: map['name'] as String?,
              color: map['color'] as String?,
            );
          })
          .whereType<SeriesAddition>()
          .toList();

      final annotationsInput = addInput['annotations'] as List?;
      final addAnnotations = annotationsInput
          ?.map((entry) {
            final map = Map<String, dynamic>.from(entry as Map);
            final typeValue = map['type'] as String?;
            if (typeValue == null) {
              return null;
            }
            AnnotationType type;
            try {
              type = AnnotationType.values.byName(typeValue);
            } catch (_) {
              return null;
            }
            Orientation? orientation;
            final orientationValue = map['orientation'] as String?;
            if (orientationValue != null) {
              try {
                orientation = Orientation.values.byName(orientationValue);
              } catch (_) {
                orientation = null;
              }
            }
            return AnnotationAddition(
              id: map['id'] as String?,
              type: type,
              value: (map['value'] as num?)?.toDouble(),
              orientation: orientation,
              label: map['label'] as String?,
            );
          })
          .whereType<AnnotationAddition>()
          .toList();

      if ((addSeries != null && addSeries.isNotEmpty) || (addAnnotations != null && addAnnotations.isNotEmpty)) {
        add = AddOperation(
          series: addSeries,
          annotations: addAnnotations,
        );
      }
    }

    RemoveOperation? remove;
    if (removeInput != null) {
      final removeSeries = removeInput['series'] as List?;
      final removeAnnotations = removeInput['annotations'] as List?;
      if (removeSeries != null || removeAnnotations != null) {
        remove = RemoveOperation(
          series: removeSeries?.cast<String>(),
          annotations: removeAnnotations?.cast<String>(),
        );
      }
    }

    return ModificationRequest(update: update, add: add, remove: remove);
  }

  /// Parses an X-axis configuration from a JSON map.
  XAxisConfig _parseXAxis(Map<String, dynamic> json) {
    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] != null ? AxisType.values.byName(json['type'] as String) : AxisType.numeric,
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
      gridDash: (json['gridDash'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
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
        position: map['position'] != null ? AxisPosition.values.byName(map['position'] as String) : AxisPosition.left,
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
