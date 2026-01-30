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
  String get description => 'Creates a new chart configuration with data series and styling options. '
      'Use this tool to generate interactive charts from structured data.\n\n'
      'REQUIRED FIELDS:\n'
      '- prompt: Natural language description of what you want to create\n'
      '- series: Array of data series, each with id, type, and data points\n\n'
      'SERIES TYPE (per-series): Each series has its own type (line, area, bar, scatter). '
      'This enables mixed charts (e.g., line + bar on same chart). Defaults to line.\n\n'
      'FEATURES: Multi-axis support, annotations (reference lines, zones, markers, text labels), '
      'customizable styling, pan/zoom interactions, legends, and grid options.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description': 'Natural language description of the chart to create',
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
                'type': {
                  'type': 'string',
                  'enum': ['line', 'area', 'bar', 'scatter'],
                  'description':
                      'The type of chart series (line, area, bar, scatter). Each series can have its own type for mixed charts. Defaults to line.',
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
                  'description': 'Reference to a SHARED Y-axis defined in the yAxes[] array. '
                      'Use this when multiple series share the same axis. '
                      'MUTUALLY EXCLUSIVE with yAxisPosition/yAxisLabel/yAxisUnit/yAxisColor/yAxisMin/yAxisMax. '
                      'Example: yAxes: [{id: "power-axis", ...}], series: [{yAxisId: "power-axis", ...}]',
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
                  'description': 'Position for an INLINE Y-axis created specifically for this series. '
                      'Use this for simple charts where each series has its own axis. '
                      'MUTUALLY EXCLUSIVE with yAxisId. When set, also configure yAxisLabel, yAxisUnit, yAxisColor, yAxisMin, yAxisMax.',
                },
                'yAxisLabel': {
                  'type': 'string',
                  'description': 'Label for the INLINE Y-axis (used with yAxisPosition). Ignored if yAxisId is set.',
                },
                'yAxisUnit': {
                  'type': 'string',
                  'description': 'Unit for the INLINE Y-axis (used with yAxisPosition). Ignored if yAxisId is set.',
                },
                'yAxisColor': {
                  'type': 'string',
                  'description': 'Color for the INLINE Y-axis in hex format (used with yAxisPosition). Ignored if yAxisId is set.',
                },
                'yAxisMin': {
                  'type': 'number',
                  'description': 'Minimum value for the INLINE Y-axis scale (used with yAxisPosition). Ignored if yAxisId is set.',
                },
                'yAxisMax': {
                  'type': 'number',
                  'description': 'Maximum value for the INLINE Y-axis scale (used with yAxisPosition). Ignored if yAxisId is set.',
                },
                'markerStyle': {
                  'type': 'string',
                  'enum': ['none', 'circle', 'square', 'triangle', 'diamond'],
                  'description': 'Style of markers at data points. Defaults to "none".',
                },
                'markerSize': {
                  'type': 'number',
                  'minimum': 0,
                  'description': 'Size of markers in pixels. Defaults to 4.0.',
                },
                'visible': {
                  'type': 'boolean',
                  'description': 'Whether this series is visible. Defaults to true.',
                },
                'legendVisible': {
                  'type': 'boolean',
                  'description': 'Whether to show this series in the legend. Defaults to true.',
                },
                'strokeDash': {
                  'type': 'array',
                  'items': {'type': 'number'},
                  'description': 'Dash pattern for line stroke (e.g., [5, 3] for dashed). Defaults to solid line.',
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
          'yAxes': {
            'type': 'array',
            'description': 'SHARED Y-axis configurations for multi-axis charts. '
                'Series reference these via yAxisId. '
                'Alternative to inline axis (yAxisPosition+yAxisLabel+etc). '
                'Use shared axes when multiple series use the same axis, or for explicit axis control.',
            'items': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': 'string',
                  'description': 'Unique identifier for this Y-axis. Series reference this via series[].yAxisId.',
                },
                'label': {
                  'type': 'string',
                  'description': 'Label for the Y-axis (e.g., "Power").',
                },
                'unit': {
                  'type': 'string',
                  'description': 'Unit for the Y-axis (e.g., "W" for watts).',
                },
                'position': {
                  'type': 'string',
                  'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                  'description': 'Position of the Y-axis. Defaults to "left".',
                },
                'min': {
                  'type': 'number',
                  'description': 'Minimum value for the Y-axis scale. If not specified, auto-calculated.',
                },
                'max': {
                  'type': 'number',
                  'description': 'Maximum value for the Y-axis scale. If not specified, auto-calculated.',
                },
                'autoRange': {
                  'type': 'boolean',
                  'description': 'Whether to auto-calculate range from data. Defaults to true.',
                },
                'includeZero': {
                  'type': 'boolean',
                  'description': 'Whether the range should include zero. Defaults to false.',
                },
                'color': {
                  'type': 'string',
                  'description': 'Color for this Y-axis (hex format). Often matched to series color.',
                },
                'showTicks': {
                  'type': 'boolean',
                  'description': 'Whether to show tick marks. Defaults to true.',
                },
                'showAxisLine': {
                  'type': 'boolean',
                  'description': 'Whether to show the axis line. Defaults to true.',
                },
                'showGridLines': {
                  'type': 'boolean',
                  'description': 'Whether to show horizontal grid lines. Defaults to true.',
                },
              },
            },
          },
          'annotations': {
            'type': 'array',
            'description': 'Chart annotations. Each type has DIFFERENT required properties:\n'
                '• referenceLine: REQUIRES "value" (number) + "orientation" (horizontal/vertical). In perSeries mode, horizontal lines also REQUIRE "seriesId".\n'
                '• zone: REQUIRES "minValue" + "maxValue" (numbers) + "orientation".\n'
                '• textLabel: REQUIRES "text" (string) + "position" (topLeft/center/etc).\n'
                '• marker: REQUIRES "x" + "y" (numbers).\n'
                'EXAMPLES:\n'
                '  {"type": "referenceLine", "value": 80, "orientation": "horizontal", "seriesId": "cpu", "label": "Threshold"}\n'
                '  {"type": "zone", "minValue": 70, "maxValue": 90, "orientation": "horizontal", "seriesId": "cpu", "color": "#FF000033"}\n'
                '  {"type": "textLabel", "text": "Peak", "position": "topRight", "fontSize": 14}\n'
                '  {"type": "marker", "x": 30, "y": 85, "label": "Event"}',
            'items': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['referenceLine', 'zone', 'textLabel', 'marker'],
                  'description': 'Annotation type. Determines which other properties are required.',
                },
                // referenceLine properties
                'value': {
                  'type': 'number',
                  'description': 'FOR referenceLine ONLY: The Y-value where line is drawn. REQUIRED for referenceLine.',
                },
                'orientation': {
                  'type': 'string',
                  'enum': ['horizontal', 'vertical'],
                  'description': 'FOR referenceLine/zone: horizontal draws at Y-value, vertical at X-value.',
                },
                'seriesId': {
                  'type': 'string',
                  'description': 'FOR referenceLine/zone in perSeries mode: Which series range to use. REQUIRED for horizontal annotations.',
                },
                'lineWidth': {
                  'type': 'number',
                  'description': 'FOR referenceLine: Line thickness in pixels.',
                },
                'dashPattern': {
                  'type': 'array',
                  'items': {'type': 'number'},
                  'description': 'FOR referenceLine: Dash pattern e.g. [5,3] for dashed line.',
                },
                // zone properties
                'minValue': {
                  'type': 'number',
                  'description': 'FOR zone ONLY: Lower bound of shaded region. REQUIRED for zone.',
                },
                'maxValue': {
                  'type': 'number',
                  'description': 'FOR zone ONLY: Upper bound of shaded region. REQUIRED for zone.',
                },
                'opacity': {
                  'type': 'number',
                  'minimum': 0,
                  'maximum': 1,
                  'description': 'FOR zone: Fill opacity 0.0-1.0.',
                },
                // textLabel properties
                'text': {
                  'type': 'string',
                  'description': 'FOR textLabel ONLY: The text to display. REQUIRED for textLabel.',
                },
                'position': {
                  'type': 'string',
                  'enum': ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
                  'description': 'FOR textLabel ONLY: Where to place the text. REQUIRED for textLabel.',
                },
                'fontSize': {
                  'type': 'number',
                  'description': 'FOR textLabel: Font size in pixels.',
                },
                // marker properties
                'x': {
                  'type': 'number',
                  'description': 'FOR marker ONLY: X coordinate. REQUIRED for marker.',
                },
                'y': {
                  'type': 'number',
                  'description': 'FOR marker ONLY: Y coordinate. REQUIRED for marker.',
                },
                // shared properties
                'label': {
                  'type': 'string',
                  'description': 'Optional label text shown with annotation.',
                },
                'color': {
                  'type': 'string',
                  'description': 'Color in hex format e.g. "#FF0000".',
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
                'description': 'Font size for the chart title in pixels.',
              },
              'subtitleFontSize': {
                'type': 'number',
                'description': 'Font size for the chart subtitle in pixels.',
              },
              'axisFontSize': {
                'type': 'number',
                'description': 'Font size for axis labels in pixels.',
              },
              'legendFontSize': {
                'type': 'number',
                'description': 'Font size for legend text in pixels.',
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
            'description': 'Interaction configuration for pan/zoom/tooltip behavior.',
            'properties': {
              'crosshairMode': {
                'type': 'string',
                'enum': ['none', 'vertical', 'horizontal', 'both'],
                'description':
                    'Crosshair display mode. "none" hides crosshair, "vertical" shows vertical line, "horizontal" shows horizontal line, "both" shows both.',
              },
              'tooltipPosition': {
                'type': 'string',
                'enum': ['auto', 'top', 'bottom', 'left', 'right', 'nearestPoint'],
                'description': 'Preferred tooltip position relative to the cursor or data point.',
              },
              'enableZoom': {
                'type': 'boolean',
                'description': 'Whether zooming is enabled. Defaults to true.',
              },
              'enablePan': {
                'type': 'boolean',
                'description': 'Whether panning is enabled. Defaults to true.',
              },
              'snapToPoint': {
                'type': 'boolean',
                'description': 'Whether crosshair/tooltip snaps to nearest data point.',
              },
            },
          },
        },
        'required': ['prompt', 'series'],
      };

  /// Helper to return tool error result
  ToolResult _logError(String message, Map<String, dynamic> input) {
    return ToolResult(output: message, isError: true);
  }

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // Validate required fields
    final prompt = input['prompt'] as String?;
    if (prompt == null || prompt.isEmpty) {
      return _logError(
        'Error: prompt is required. Please provide a natural language '
        'description of the chart you want to create.',
        input,
      );
    }

    final seriesInput = input['series'] as List?;
    if (seriesInput == null || seriesInput.isEmpty) {
      return _logError(
        'Error: series is required and must contain at least one data series. '
        'Each series should have an id and data array.',
        input,
      );
    }

    // Validate and parse legend position
    LegendPosition legendPosition = LegendPosition.bottom; // default
    final legendPositionInput = input['legendPosition'] as String?;
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

    // Validate and parse normalization mode
    NormalizationModeConfig normalizationMode = NormalizationModeConfig.none; // default
    final normalizationModeInput = input['normalizationMode'] as String?;
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

    // Parse series data using SeriesConfig.fromJson for full property support
    final series = <SeriesConfig>[];
    for (int i = 0; i < seriesInput.length; i++) {
      final seriesMap = Map<String, dynamic>.from(seriesInput[i] as Map);

      // Validate series type if provided
      final seriesType = seriesMap['type'] as String?;
      if (seriesType != null) {
        const validTypes = ['line', 'area', 'bar', 'scatter'];
        if (!validTypes.contains(seriesType)) {
          return _logError(
            'Error: Invalid series type "$seriesType" in series "${seriesMap['id'] ?? 'unknown'}". '
            'Valid types are: line, area, bar, scatter.',
            input,
          );
        }
      }

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
      for (int i = 0; i < annotationsInput.length; i++) {
        final annotationMap = annotationsInput[i];
        final map = Map<String, dynamic>.from(annotationMap as Map);
        final parsed = AnnotationConfig.fromJson(map);
        annotations.add(parsed);
      }
    }

    // Validate annotation seriesId references
    final validSeriesIds = series.map((s) => s.id).toSet();
    for (final annotation in annotations) {
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

    // Warn if perSeries mode but annotations missing seriesId
    if (normalizationMode == NormalizationModeConfig.perSeries) {
      for (final annotation in annotations) {
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
    for (final annotation in annotations) {
      if (annotation.type == AnnotationType.referenceLine && annotation.value == null) {
        return _logError(
          'Error: referenceLine annotation requires a "value" property. '
          'The value should be in the same units as the target series data. '
          'Example: for a power series with range 0-500W, value: 200 draws a line at 200W.',
          input,
        );
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
