import '../models/annotation_config.dart';
import '../models/axis_config.dart';
import '../models/chart_configuration.dart';
import '../models/series_config.dart';
import 'llm_tool.dart';

/// Default colors for chart series when none are specified.
const List<String> _defaultSeriesColors = [
  '#2196F3', // Blue
  '#F44336', // Red
  '#4CAF50', // Green
  '#FF9800', // Orange
  '#9C27B0', // Purple
  '#00BCD4', // Cyan
  '#795548', // Brown
  '#607D8B', // Blue Grey
];

/// Tool that converts natural language prompts into chart configurations.
///
/// TODO: Implement in green phase.
class CreateChartTool extends LLMTool {
  @override
  String get name => 'create_chart';

  @override
  String get description => '''
Creates an interactive chart from provided data.
Use this tool when the user wants to visualize data as a chart.
Always include the data array with x,y values when calling this tool.
''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description': 'Natural language description of the chart.',
          },
          'type': {
            'type': 'string',
            'enum': ['line', 'area', 'bar', 'scatter'],
            'description': 'Type of chart to render.',
          },
          'series': {
            'type': 'array',
            'description': 'Data series to plot. REQUIRED - include your data here.',
            'items': {
              'type': 'object',
              'properties': {
                'id': {
                  'type': 'string',
                  'description': 'Unique series identifier (e.g., "sales", "revenue").',
                },
                'name': {
                  'type': 'string',
                  'description': 'Display name for legend (e.g., "Quarterly Sales").',
                },
                'color': {
                  'type': 'string',
                  'description':
                      'Hex color for this series (e.g., "#FF0000" for red, "#2196F3" for blue). If not specified, a default color will be assigned.',
                },
                'data': {
                  'type': 'array',
                  'description': 'Array of data points with x and y values.',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'x': {'type': 'number', 'description': 'X-axis value'},
                      'y': {'type': 'number', 'description': 'Y-axis value'},
                    },
                    'required': ['x', 'y'],
                  },
                },
                'fillOpacity': {
                  'type': 'number',
                  'minimum': 0,
                  'maximum': 1,
                  'description': 'Fill opacity for area charts (0.0 to 1.0). Defaults to 0.0.',
                },
                'markerStyle': {
                  'type': 'string',
                  'enum': ['none', 'circle', 'square', 'triangle', 'diamond'],
                  'description': 'Style of data point markers. Defaults to "none".',
                },
                'markerSize': {
                  'type': 'number',
                  'minimum': 0,
                  'description':
                      'Size/radius of markers in pixels. Used for data points on line/area charts (when showPoints=true) and scatter plot markers. Defaults to 4.0.',
                },
                'interpolation': {
                  'type': 'string',
                  'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                  'description': 'Line interpolation type. Defaults to "linear".',
                },
                'showPoints': {
                  'type': 'boolean',
                  'description': 'Whether to show data points. Defaults to false.',
                },
                // NOTE: markerSize (above) is the canonical property for marker size.
                // It applies to all chart types: line/area (data point markers) and scatter (plot markers).
                // Removed duplicate dataPointMarkerRadius and markerRadius to avoid LLM confusion.
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
                'tension': {
                  'type': 'number',
                  'minimum': 0,
                  'maximum': 1,
                  'description': 'Curve tension for bezier interpolation (0.0 to 1.0). Only applicable for line/area charts.',
                },
                'strokeWidth': {
                  'type': 'number',
                  'minimum': 0,
                  'description': 'Width of the line stroke in pixels. Defaults to 2.0.',
                },
                'strokeDash': {
                  'type': 'array',
                  'items': {'type': 'number'},
                  'description': 'Dash pattern for the line (e.g., [5, 3] for dashed line).',
                },
                'yAxisId': {
                  'type': 'string',
                  'description': 'ID of the Y-axis this series should use (for multi-axis charts).',
                },
                'unit': {
                  'type': 'string',
                  'description': 'Unit of measurement for this series (e.g., "W", "bpm").',
                },
                'visible': {
                  'type': 'boolean',
                  'description': 'Whether the series is visible. Defaults to true.',
                },
                'legendVisible': {
                  'type': 'boolean',
                  'description': 'Whether to show this series in the legend. Defaults to true.',
                },
                'yAxisPosition': {
                  'type': 'string',
                  'enum': ['left', 'right', 'leftOuter', 'rightOuter'],
                  'description': 'Position of the Y-axis for this series. Use "left", "right", "leftOuter", or "rightOuter" for multi-axis charts.',
                },
                'yAxisLabel': {
                  'type': 'string',
                  'description': 'Label for the Y-axis associated with this series (e.g., "Power", "Heart Rate").',
                },
                'yAxisUnit': {
                  'type': 'string',
                  'description': 'Unit for the Y-axis associated with this series (e.g., "W", "bpm").',
                },
                'yAxisColor': {
                  'type': 'string',
                  'description': 'Color for the Y-axis associated with this series in hex format (e.g., "#FF0000").',
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
          'style': {
            'type': 'object',
            'description': 'Visual styling configuration for the chart.',
            'properties': {
              'backgroundColor': {
                'type': 'string',
                'description': 'Background color of the chart (e.g., "#FFFFFF" for white).',
              },
              'gridColor': {
                'type': 'string',
                'description': 'Color for grid lines.',
              },
              'axisColor': {
                'type': 'string',
                'description': 'Color for axes.',
              },
              'fontFamily': {
                'type': 'string',
                'description': 'Font family for text.',
              },
              'fontSize': {
                'type': 'number',
                'description': 'Font size for text.',
              },
              'paddingTop': {
                'type': 'number',
                'minimum': 0,
                'description': 'Top padding in pixels.',
              },
              'paddingBottom': {
                'type': 'number',
                'minimum': 0,
                'description': 'Bottom padding in pixels.',
              },
              'paddingLeft': {
                'type': 'number',
                'minimum': 0,
                'description': 'Left padding in pixels.',
              },
              'paddingRight': {
                'type': 'number',
                'minimum': 0,
                'description': 'Right padding in pixels.',
              },
            },
          },
          'annotations': {
            'type': 'array',
            'description': 'Annotations to overlay on the chart (reference lines, zones, text labels).',
            'items': {
              'type': 'object',
              'properties': {
                'type': {
                  'type': 'string',
                  'enum': ['referenceLine', 'zone', 'textLabel', 'marker'],
                  'description': 'Type of annotation.',
                },
                'orientation': {
                  'type': 'string',
                  'enum': ['horizontal', 'vertical'],
                  'description': 'Orientation for reference lines and zones. horizontal draws at a Y value, vertical draws at an X value.',
                },
                'value': {
                  'type': 'number',
                  'description': 'Y-axis value for horizontal lines, X-axis value for vertical lines.',
                },
                'minValue': {
                  'type': 'number',
                  'description': 'Minimum value for zones.',
                },
                'maxValue': {
                  'type': 'number',
                  'description': 'Maximum value for zones.',
                },
                'x': {
                  'type': 'number',
                  'description': 'X data coordinate for markers (not used for textLabel).',
                },
                'y': {
                  'type': 'number',
                  'description': 'Y data coordinate for markers (not used for textLabel).',
                },
                'position': {
                  'type': 'string',
                  'enum': ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
                  'description': 'Semantic position for text labels. Defaults to topLeft if not specified.',
                },
                'text': {
                  'type': 'string',
                  'description': 'Text content for text labels.',
                },
                'label': {
                  'type': 'string',
                  'description': 'Label to display on the annotation.',
                },
                'color': {
                  'type': 'string',
                  'description': 'Hex color for the annotation (e.g., "#FF0000").',
                },
                'opacity': {
                  'type': 'number',
                  'description': 'Opacity for zones (0.0 to 1.0).',
                },
                'seriesId': {
                  'type': 'string',
                  'description':
                      'Series ID for threshold annotations in perSeries normalization mode. When normalizationMode is "perSeries", each series has its own Y-axis range. This field specifies which series the threshold value belongs to. REQUIRED for horizontal threshold lines when using perSeries normalization.',
                },
              },
              'required': ['type'],
            },
          },
          // Config panel properties - controls chart display options
          'showGrid': {
            'type': 'boolean',
            'description': 'Whether to show grid lines on the chart. Defaults to true.',
          },
          'showLegend': {
            'type': 'boolean',
            'description': 'Whether to show the legend. Defaults to true.',
          },
          'legendPosition': {
            'type': 'string',
            'enum': ['top', 'bottom', 'left', 'right', 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'],
            'description': 'Position of the legend. Defaults to bottom.',
          },
          'useDarkTheme': {
            'type': 'boolean',
            'description': 'Whether to use dark theme. Defaults to false (light theme).',
          },
          'showScrollbar': {
            'type': 'boolean',
            'description': 'Whether to show the scrollbar for panning. Defaults to false.',
          },
          'showYScrollbar': {
            'type': 'boolean',
            'description': 'Whether to show the Y-axis scrollbar. Defaults to false.',
          },
          'title': {
            'type': 'string',
            'description': 'Chart title displayed at the top.',
          },
          'subtitle': {
            'type': 'string',
            'description': 'Chart subtitle displayed below the title.',
          },
          'width': {
            'type': 'number',
            'minimum': 0,
            'description': 'Chart width in pixels. Defaults to full width.',
          },
          'height': {
            'type': 'number',
            'minimum': 0,
            'description': 'Chart height in pixels. Defaults to 350.',
          },
          'backgroundColor': {
            'type': 'string',
            'description': 'Background color of the chart in hex format (e.g., "#FFFFFF").',
          },
          'xAxis': {
            'type': 'object',
            'description': 'X-axis configuration.',
            'properties': {
              'label': {
                'type': 'string',
                'description': 'Label for the X-axis.',
              },
              'unit': {
                'type': 'string',
                'description': 'Unit for the X-axis values (e.g., "s", "min").',
              },
              'min': {
                'type': 'number',
                'description': 'Minimum value for the X-axis scale.',
              },
              'max': {
                'type': 'number',
                'description': 'Maximum value for the X-axis scale.',
              },
              'visible': {
                'type': 'boolean',
                'description': 'Whether to show the X-axis. Defaults to true.',
              },
              'showAxisLine': {
                'type': 'boolean',
                'description': 'Whether to show the axis line. Defaults to true.',
              },
              'showTicks': {
                'type': 'boolean',
                'description': 'Whether to show tick marks. Defaults to true.',
              },
              'tickCount': {
                'type': 'integer',
                'description': 'Number of tick marks to display.',
              },
            },
          },
          'interactions': {
            'type': 'object',
            'description': 'Interaction configuration for the chart.',
            'properties': {
              'crosshairMode': {
                'type': 'string',
                'enum': ['none', 'vertical', 'horizontal', 'both'],
                'description': 'Crosshair display mode. Defaults to vertical.',
              },
              'tooltipPosition': {
                'type': 'string',
                'enum': ['followCursor', 'fixed', 'nearestPoint'],
                'description': 'Tooltip position mode.',
              },
              'enableZoom': {
                'type': 'boolean',
                'description': 'Whether to enable zoom interactions. Defaults to false.',
              },
              'enablePan': {
                'type': 'boolean',
                'description': 'Whether to enable pan interactions. Defaults to false.',
              },
            },
          },
          'normalizationMode': {
            'type': 'string',
            'enum': ['none', 'auto', 'perSeries'],
            'description': '''Controls Y-axis normalization for multi-series charts.
- "none": All series share a single Y-axis with combined min/max.
- "auto": Automatically detect when ranges differ significantly (>10x) and normalize.
- "perSeries": Each series gets its own Y-axis using the full chart height.
Use "perSeries" when overlaying metrics with different units (e.g., Power in watts + Heart Rate in bpm). Each series should have a yAxisId and corresponding yAxes entry with position "left" or "right".''',
          },
        },
        'required': ['prompt', 'series'],
      };

  @override
  Future<ChartConfiguration> execute(Map<String, dynamic> args) async {
    final prompt = (args['prompt'] ?? '').toString().trim();
    if (prompt.isEmpty) {
      throw ArgumentError('prompt is required');
    }

    final chartType = _resolveChartType(args['type'] as String?, prompt);

    final series = _buildSeries(args);
    final xAxis = _buildXAxis(args);
    final yAxes = _buildYAxes(args, series);
    final annotations = _buildAnnotations(args);

    // Extract config panel properties
    final showGrid = args['showGrid'] as bool?;
    final showLegend = args['showLegend'] as bool?;
    final legendPosition = args['legendPosition'] as String?;
    final useDarkTheme = args['useDarkTheme'] as bool?;
    final showScrollbar = args['showScrollbar'] as bool?;
    final normalizationMode = _parseNormalizationMode(args['normalizationMode'] as String?);
    final chartStyle = _buildStyle(args);

    return ChartConfiguration(
      type: chartType,
      series: series,
      xAxis: xAxis,
      yAxes: yAxes,
      annotations: annotations.isNotEmpty ? annotations : null,
      style: chartStyle,
      showGrid: showGrid,
      showLegend: showLegend,
      legendPosition: legendPosition,
      useDarkTheme: useDarkTheme,
      showScrollbar: showScrollbar,
      normalizationMode: normalizationMode,
    );
  }

  /// Builds the chart style configuration from args
  ChartStyleConfig? _buildStyle(Map<String, dynamic> args) {
    final styleArg = args['style'];
    if (styleArg is! Map) {
      return null;
    }

    final styleMap = Map<String, dynamic>.from(styleArg);

    // Build plotArea with padding if any padding values are specified
    Map<String, dynamic>? plotArea;
    if (styleMap.containsKey('paddingTop') ||
        styleMap.containsKey('paddingBottom') ||
        styleMap.containsKey('paddingLeft') ||
        styleMap.containsKey('paddingRight')) {
      plotArea = {
        if (styleMap['paddingTop'] != null) 'paddingTop': (styleMap['paddingTop'] as num).toDouble(),
        if (styleMap['paddingBottom'] != null) 'paddingBottom': (styleMap['paddingBottom'] as num).toDouble(),
        if (styleMap['paddingLeft'] != null) 'paddingLeft': (styleMap['paddingLeft'] as num).toDouble(),
        if (styleMap['paddingRight'] != null) 'paddingRight': (styleMap['paddingRight'] as num).toDouble(),
      };
    }

    return ChartStyleConfig(
      backgroundColor: styleMap['backgroundColor'],
      gridColor: styleMap['gridColor'],
      axisColor: styleMap['axisColor'],
      fontFamily: styleMap['fontFamily'] as String?,
      fontSize: (styleMap['fontSize'] as num?)?.toDouble(),
      plotArea: plotArea,
    );
  }

  /// Builds annotations from the args
  List<AnnotationConfig> _buildAnnotations(Map<String, dynamic> args) {
    final annotationsArg = args['annotations'];
    if (annotationsArg is! List || annotationsArg.isEmpty) {
      return [];
    }

    return annotationsArg.map((entry) {
      final map = Map<String, dynamic>.from(entry as Map);
      return AnnotationConfig(
        type: map['type'] as String? ?? 'referenceLine',
        orientation: map['orientation'] as String?,
        value: (map['value'] as num?)?.toDouble(),
        minValue: (map['minValue'] as num?)?.toDouble(),
        maxValue: (map['maxValue'] as num?)?.toDouble(),
        x: (map['x'] as num?)?.toDouble(),
        y: (map['y'] as num?)?.toDouble(),
        position: map['position'] as String?,
        text: map['text'] as String?,
        label: map['label'] as String?,
        color: map['color'] as String?,
        opacity: (map['opacity'] as num?)?.toDouble(),
      );
    }).toList();
  }

  /// Parses normalizationMode string to enum
  NormalizationModeConfig? _parseNormalizationMode(String? mode) {
    if (mode == null || mode.isEmpty) return null;
    return NormalizationModeConfig.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => NormalizationModeConfig.auto,
    );
  }

  ChartType _resolveChartType(String? explicitType, String prompt) {
    final explicit = explicitType?.toLowerCase().trim();
    if (explicit != null && explicit.isNotEmpty) {
      final matched = ChartType.values.where((type) => type.name == explicit).toList(growable: false);
      if (matched.isEmpty) {
        throw Exception('Unsupported chart type: $explicitType');
      }
      return matched.first;
    }

    final lower = prompt.toLowerCase();
    if (lower.contains('line')) {
      return ChartType.line;
    }
    if (lower.contains('area')) {
      return ChartType.area;
    }
    if (lower.contains('bar')) {
      return ChartType.bar;
    }
    if (lower.contains('scatter')) {
      return ChartType.scatter;
    }

    throw Exception('Unsupported chart type for prompt: $prompt');
  }

  List<SeriesConfig> _buildSeries(Map<String, dynamic> args) {
    final seriesArg = args['series'];
    if (seriesArg is List && seriesArg.isNotEmpty) {
      final seriesList = <SeriesConfig>[];
      for (var i = 0; i < seriesArg.length; i++) {
        final entry = Map<String, dynamic>.from(seriesArg[i] as Map);
        // Assign default color if not provided
        if (entry['color'] == null) {
          entry['color'] = _defaultSeriesColors[i % _defaultSeriesColors.length];
        }
        seriesList.add(SeriesConfig.fromJson(entry));
      }
      return seriesList;
    }

    final dataset = args['dataset'];
    final columns = _extractColumns(dataset);
    final rows = _extractRows(dataset);

    // If no data provided, generate sample data based on prompt
    if (rows.isEmpty) {
      return _generateSampleSeries(args);
    }

    final xColumn = _resolveXColumn(columns);
    final yColumns = columns.where((col) => col != xColumn).toList();
    final series = <SeriesConfig>[];

    if (yColumns.isEmpty) {
      series.add(
        SeriesConfig(
          id: 'series_1',
          name: 'Series 1',
          data: _buildSeriesData(rows, xColumn, null),
          color: _defaultSeriesColors[0],
        ),
      );
      return series;
    }

    for (var i = 0; i < yColumns.length; i++) {
      final yColumn = yColumns[i];
      series.add(
        SeriesConfig(
          id: 'series_${i + 1}',
          name: yColumn,
          data: _buildSeriesData(rows, xColumn, yColumn),
          color: _defaultSeriesColors[i % _defaultSeriesColors.length],
        ),
      );
    }

    return series;
  }

  XAxisConfig? _buildXAxis(Map<String, dynamic> args) {
    final xAxisArg = args['xAxis'];
    if (xAxisArg is Map) {
      return XAxisConfig.fromJson(Map<String, dynamic>.from(xAxisArg));
    }

    final dataset = args['dataset'];
    final columns = _extractColumns(dataset);
    final xColumn = _resolveXColumn(columns);
    if (xColumn == null) {
      return XAxisConfig();
    }

    return XAxisConfig(
      label: xColumn,
      type: _inferAxisType(xColumn),
    );
  }

  List<YAxisConfig> _buildYAxes(
    Map<String, dynamic> args,
    List<SeriesConfig> series,
  ) {
    final yAxesArg = args['yAxes'];
    if (yAxesArg is List && yAxesArg.isNotEmpty) {
      return yAxesArg
          .map((entry) => YAxisConfig.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ))
          .toList(growable: false);
    }

    final seriesName = series.isNotEmpty ? series.first.name : null;
    return [YAxisConfig(label: seriesName)];
  }

  List<String> _extractColumns(dynamic dataset) {
    if (dataset is Map && dataset['columns'] is List) {
      return (dataset['columns'] as List).map((entry) => entry.toString()).toList(growable: false);
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractRows(dynamic dataset) {
    if (dataset is Map && dataset['rows'] is List) {
      return (dataset['rows'] as List).whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList(growable: false);
    }
    return const [];
  }

  String? _resolveXColumn(List<String> columns) {
    if (columns.isEmpty) {
      return null;
    }
    if (columns.contains('time')) {
      return 'time';
    }
    return columns.first;
  }

  AxisType _inferAxisType(String column) {
    final lower = column.toLowerCase();
    if (lower.contains('time') || lower.contains('date')) {
      return AxisType.time;
    }
    return AxisType.numeric;
  }

  List<Map<String, dynamic>> _buildSeriesData(
    List<Map<String, dynamic>> rows,
    String? xColumn,
    String? yColumn,
  ) {
    if (rows.isEmpty) {
      return [];
    }
    final data = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row.isEmpty) {
        continue;
      }
      final xValue = xColumn != null ? row[xColumn] : row.values.first;
      final yValue = yColumn != null
          ? row[yColumn]
          : row.values.length > 1
              ? row.values.elementAt(1)
              : row.values.first;
      data.add({'x': xValue, 'y': yValue});
    }
    return data;
  }

  /// Generates sample data when no dataset is provided.
  List<SeriesConfig> _generateSampleSeries(Map<String, dynamic> args) {
    final prompt = (args['prompt'] ?? '').toString().toLowerCase();

    // Generate sample data based on the prompt context
    List<Map<String, dynamic>> sampleData;
    String seriesName;

    if (prompt.contains('sales') || prompt.contains('quarterly')) {
      // Quarterly sales data
      seriesName = 'Sales';
      sampleData = [
        {'x': 0, 'y': 85000},
        {'x': 1, 'y': 95000},
        {'x': 2, 'y': 105000},
        {'x': 3, 'y': 125000},
        {'x': 4, 'y': 90000},
        {'x': 5, 'y': 110000},
        {'x': 6, 'y': 130000},
        {'x': 7, 'y': 145000},
      ];
    } else if (prompt.contains('power') || prompt.contains('watts')) {
      // Power output data
      seriesName = 'Power (W)';
      sampleData = [
        {'x': 0, 'y': 150},
        {'x': 1, 'y': 180},
        {'x': 2, 'y': 220},
        {'x': 3, 'y': 195},
        {'x': 4, 'y': 240},
        {'x': 5, 'y': 210},
      ];
    } else if (prompt.contains('temperature') || prompt.contains('temp')) {
      // Temperature data
      seriesName = 'Temperature';
      sampleData = [
        {'x': 0, 'y': 20},
        {'x': 1, 'y': 22},
        {'x': 2, 'y': 25},
        {'x': 3, 'y': 28},
        {'x': 4, 'y': 26},
        {'x': 5, 'y': 23},
      ];
    } else {
      // Generic sample data
      seriesName = 'Value';
      sampleData = [
        {'x': 0, 'y': 10},
        {'x': 1, 'y': 25},
        {'x': 2, 'y': 35},
        {'x': 3, 'y': 30},
        {'x': 4, 'y': 45},
        {'x': 5, 'y': 50},
      ];
    }

    return [
      SeriesConfig(
        id: 'sample_series',
        name: seriesName,
        data: sampleData,
        color: _defaultSeriesColors[0],
      ),
    ];
  }
}
