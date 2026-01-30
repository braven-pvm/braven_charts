import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/annotation_config.dart';
import '../models/chart_configuration.dart';
import '../models/chart_style_config.dart';
import '../models/enums.dart';
import '../models/series_config.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for creating chart configurations from LLM input.
///
/// This tool lets an LLM produce a complete [ChartConfiguration] by supplying
/// structured input including data series, chart type, and styling options.
/// It is typically registered on an [AgentSessionImpl] so the model can call
/// it during `transform()`.
///
/// Use this tool when there is no active chart yet or when you want a
/// full replacement configuration from a prompt.
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
///
/// This tool validates required fields and returns user-friendly errors
/// instead of throwing exceptions.
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
  String get description => 'Creates a new chart configuration with the specified type, data series, and styling options. '
      'Use this tool to generate interactive charts from structured data.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description': 'Natural language description of the chart to create',
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
                'yAxisId': {
                  'type': 'string',
                  'description': 'ID of the Y-axis this series should use (for multi-axis charts).',
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
                  'description': 'Curve tension for bezier interpolation (0.0 to 1.0). Only applicable for line/area charts.',
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
                'barWidthPercent': {
                  'type': 'number',
                  'minimum': 0,
                  'maximum': 1,
                  'description': 'Bar width as a percentage of available space (0.0 to 1.0). Defaults to 0.7.',
                },
                'barWidthPixels': {
                  'type': 'number',
                  'minimum': 0,
                  'description': 'Fixed bar width in pixels. Overrides barWidthPercent if specified.',
                },
                'barMinWidth': {
                  'type': 'number',
                  'minimum': 0,
                  'description': 'Minimum bar width in pixels. Defaults to 4.0.',
                },
                'barMaxWidth': {
                  'type': 'number',
                  'minimum': 0,
                  'description': 'Maximum bar width in pixels. Defaults to 100.0.',
                },
                'yAxisPosition': {
                  'type': 'string',
                  'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                  'description': 'Position of the Y-axis for this series in multi-axis charts.',
                },
                'yAxisLabel': {
                  'type': 'string',
                  'description': 'Label for the Y-axis associated with this series.',
                },
                'yAxisUnit': {
                  'type': 'string',
                  'description': 'Unit for the Y-axis associated with this series.',
                },
                'yAxisColor': {
                  'type': 'string',
                  'description': 'Color for the Y-axis associated with this series in hex format.',
                },
                'yAxisMin': {
                  'type': 'number',
                  'description': 'Minimum value for the Y-axis scale. If not specified, auto-calculated from data.',
                },
                'yAxisMax': {
                  'type': 'number',
                  'description': 'Maximum value for the Y-axis scale. If not specified, auto-calculated from data.',
                },
              },
              'required': ['id', 'data'],
            },
          },
          'xAxis': {
            'type': 'object',
            'description': 'X-axis configuration',
            'properties': {
              'label': {
                'type': 'string',
                'description': 'Label for the X-axis (e.g., "Time").',
              },
              'unit': {
                'type': 'string',
                'description': 'Unit for the X-axis (e.g., "seconds").',
              },
              'min': {
                'type': 'number',
                'description': 'Minimum value for the X-axis scale. If not specified, auto-calculated from data.',
              },
              'max': {
                'type': 'number',
                'description': 'Maximum value for the X-axis scale. If not specified, auto-calculated from data.',
              },
              'visible': {
                'type': 'boolean',
                'description': 'Whether the X-axis is visible.',
              },
              'showAxisLine': {
                'type': 'boolean',
                'description': 'Whether to show the X-axis line.',
              },
              'showTicks': {
                'type': 'boolean',
                'description': 'Whether to show tick marks on the X-axis.',
              },
              'tickCount': {
                'type': 'integer',
                'minimum': 0,
                'description': 'Number of ticks to display on the X-axis.',
              },
            },
          },
          'annotations': {
            'type': 'array',
            'description': 'Annotations to display on the chart (reference lines, zones, markers, text labels)',
            'items': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['referenceLine', 'zone', 'textLabel', 'marker'],
                  'description':
                      'Type of annotation: referenceLine (horizontal/vertical line at value), zone (shaded region), textLabel (text at position), marker (point marker)',
                },
                'value': {
                  'type': 'number',
                  'description': 'Value for referenceLine (Y value for horizontal, X for vertical)',
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
                  'description': 'Line width for referenceLine annotations',
                },
                'dashPattern': {
                  'type': 'array',
                  'items': {'type': 'number'},
                  'description': 'Dash pattern for referenceLine (e.g., [5, 3] for dashed)',
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
                  'enum': ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
                  'description': 'Position for textLabel annotation',
                },
                'fontSize': {
                  'type': 'number',
                  'description': 'Font size for textLabel annotation',
                },
                'seriesId': {
                  'type': 'string',
                  'description': 'Series ID to bind annotation to (required for perSeries normalization mode)',
                },
              },
              'required': ['type'],
            },
          },
          'style': {
            'type': 'object',
            'description': 'Visual styling configuration',
          },
          'width': {
            'type': 'number',
            'description': 'Width of the chart in pixels.',
          },
          'height': {
            'type': 'number',
            'description': 'Height of the chart in pixels.',
          },
          'backgroundColor': {
            'type': 'string',
            'description': 'Background color of the chart (e.g., "#FFFFFF").',
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
          'showScrollbar': {
            'type': 'boolean',
            'description': 'Whether to show scrollbars for panning.',
          },
          'showYScrollbar': {
            'type': 'boolean',
            'description': 'Whether to show the Y-axis scrollbar.',
          },
          'normalizationMode': {
            'type': 'string',
            'enum': ['none', 'auto', 'perSeries'],
            'description': 'Normalization mode for multi-series charts',
          },
          'interactions': {
            'type': 'object',
            'description': 'Interaction configuration for pan/zoom/tooltip.',
            'properties': {
              'crosshairMode': {
                'type': 'string',
                'description': 'Crosshair display mode.',
              },
              'tooltipPosition': {
                'type': 'string',
                'description': 'Preferred tooltip position.',
              },
              'enableZoom': {
                'type': 'boolean',
                'description': 'Whether zooming is enabled.',
              },
              'enablePan': {
                'type': 'boolean',
                'description': 'Whether panning is enabled.',
              },
            },
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
        output: 'Error: series is required and must contain at least one data series. '
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
    NormalizationModeConfig normalizationMode = NormalizationModeConfig.none; // default
    final normalizationModeInput = input['normalizationMode'] as String?;
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

    // Parse series data using SeriesConfig.fromJson for full property support
    final series = <SeriesConfig>[];
    for (int i = 0; i < seriesInput.length; i++) {
      final seriesMap = Map<String, dynamic>.from(seriesInput[i] as Map);

      // Assign default color if not provided
      if (seriesMap['color'] == null) {
        seriesMap['color'] = _defaultColors[i % _defaultColors.length];
      }

      // Use fromJson to parse ALL properties (25+ including strokeWidth,
      // fillOpacity, tension, showPoints, markerSize, bar properties, etc.)
      series.add(SeriesConfig.fromJson(seriesMap));
    }

    // Parse annotations if provided
    final annotations = <AnnotationConfig>[];
    final annotationsInput = input['annotations'] as List?;
    if (annotationsInput != null) {
      for (final annotationMap in annotationsInput) {
        final map = Map<String, dynamic>.from(annotationMap as Map);
        annotations.add(AnnotationConfig.fromJson(map));
      }
    }

    // Parse xAxis if provided
    XAxisConfig? xAxis;
    final xAxisInput = input['xAxis'] as Map<String, dynamic>?;
    if (xAxisInput != null) {
      xAxis = XAxisConfig.fromJson(xAxisInput);
    }

    // Parse yAxes if provided
    final yAxes = <YAxisConfig>[];
    final yAxesInput = input['yAxes'] as List?;
    if (yAxesInput != null) {
      for (final yAxisMap in yAxesInput) {
        final map = Map<String, dynamic>.from(yAxisMap as Map);
        yAxes.add(YAxisConfig.fromJson(map));
      }
    }

    // Parse style if provided
    ChartStyleConfig? style;
    final styleInput = input['style'] as Map<String, dynamic>?;
    if (styleInput != null) {
      style = ChartStyleConfig.fromJson(styleInput);
    }

    // Parse interactions if provided
    final interactions = input['interactions'] as Map<String, dynamic>?;

    // Generate unique chart ID
    final chartId = _uuid.v4();

    // Build chart configuration with ALL properties
    final chart = ChartConfiguration(
      id: chartId,
      type: chartType,
      title: input['title'] as String?,
      subtitle: input['subtitle'] as String?,
      series: series,
      xAxis: xAxis,
      yAxes: yAxes,
      annotations: annotations,
      style: style,
      interactions: interactions,
      showGrid: input['showGrid'] as bool? ?? true,
      showLegend: input['showLegend'] as bool? ?? true,
      legendPosition: legendPosition,
      useDarkTheme: input['useDarkTheme'] as bool? ?? false,
      showScrollbar: input['showScrollbar'] as bool? ?? false,
      normalizationMode: normalizationMode,
      width: (input['width'] as num?)?.toDouble(),
      height: (input['height'] as num?)?.toDouble(),
      backgroundColor: input['backgroundColor'] as String?,
    );

    // Return success result with JSON output and ChartConfiguration data
    return ToolResult(
      output: jsonEncode(chart.toJson()),
      data: chart,
    );
  }
}
