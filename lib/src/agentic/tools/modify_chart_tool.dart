import '../models/axis_config.dart';
import '../models/chart_configuration.dart';
import '../models/series_config.dart';
import '../services/data_store.dart';
import 'llm_tool.dart';

/// Tool that modifies existing chart configurations in-place.
///
/// Supports modifying:
/// - Visual properties (color, line width, dash pattern)
/// - Axis properties (labels, ranges, grid visibility)
/// - Legend and grid visibility
/// - Theme changes
/// - Series properties
class ModifyChartTool extends LLMTool {
  /// Data store for retrieving and storing charts
  final DataStore<ChartConfiguration> _dataStore;

  /// Creates a new ModifyChartTool
  ///
  /// If dataStore is not provided, a default instance will be created
  ModifyChartTool({DataStore<ChartConfiguration>? dataStore}) : _dataStore = dataStore ?? DataStore<ChartConfiguration>();

  @override
  String get name => 'modify_chart';

  @override
  String get description => '''Modifies visual properties, axes, or other settings of an existing chart without recreating it.

For multi-axis charts with different data ranges (e.g., Power in watts and Heart Rate in bpm), use normalizationMode:
- "none": Single shared Y-axis for all series
- "auto": Automatically detect when series need separate axes (default)
- "perSeries": Each series gets its own Y-axis scale

When using perSeries normalization, set each series' yAxisId to specify which Y-axis it uses, and configure each Y-axis with position "left" or "right" in the yAxes array.''';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'chartId': {'type': 'string', 'description': 'Unique identifier of the chart to modify.'},
          'properties': {
            'type': 'object',
            'description': '''Properties to modify. Supports:
- type: Chart type ("line", "area", "bar", "scatter")
- title, subtitle: Chart titles
- series: Array of series configs (each with id, color, strokeWidth, strokeDash, yAxisId, fillOpacity, markerStyle, markerSize, interpolation, showPoints, tension, etc.)
- xAxis, yAxis, yAxes: Axis configurations (label, min, max, position)
- normalizationMode: "none"|"auto"|"perSeries" for multi-axis display
- legend, grid: Visibility and styling
- theme: "light" or "dark" (string)
- useDarkTheme: true/false (boolean, alternative to theme)
- annotations: Reference lines, zones, labels
- color, lineWidth, dashPattern: Quick styling for all series
- interactions: Pan, zoom, crosshair, tooltip settings
- backgroundColor, padding: Style properties
- axisVisibility: Show/hide axes
- tickFormatting: Customize tick formats''',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['line', 'area', 'bar', 'scatter'],
                'description': 'Chart type to change to.',
              },
              'normalizationMode': {
                'type': 'string',
                'enum': ['none', 'auto', 'perSeries'],
                'description':
                    'Controls Y-axis normalization for multi-series charts. Use "perSeries" when overlaying metrics with different units (e.g., Power + Heart Rate). Each series should specify yAxisId and the corresponding Y-axis should have position "left" or "right".'
              },
              'series': {
                'type': 'array',
                'description':
                    'Array of series to update. Each series can have: id (required), color, strokeWidth, strokeDash, yAxisId (for multi-axis), unit, fillOpacity, markerStyle, markerSize, interpolation, showPoints, tension, yAxisPosition ("left"|"right"), yAxisLabel, yAxisUnit, yAxisColor.'
              },
              'yAxes': {
                'type': 'array',
                'maxItems': 4,
                'description': 'Array of Y-axis configurations. Each can have: id, label, unit, position ("left"|"right"), min, max, color.'
              },
              'interactions': {
                'type': 'object',
                'description': 'Interaction settings for the chart.',
                'properties': {
                  'pan': {
                    'type': 'boolean',
                    'description': 'Enable panning on the chart.',
                  },
                  'zoom': {
                    'type': 'boolean',
                    'description': 'Enable zooming on the chart.',
                  },
                  'crosshair': {
                    'type': 'boolean',
                    'description': 'Enable crosshair display on hover.',
                  },
                  'tooltip': {
                    'type': 'boolean',
                    'description': 'Enable tooltips on data points.',
                  },
                },
              },
              'axisVisibility': {
                'type': 'object',
                'description': 'Axis visibility settings.',
                'properties': {
                  'xAxis': {
                    'type': 'boolean',
                    'description': 'Show or hide the X-axis.',
                  },
                  'yAxis': {
                    'type': 'boolean',
                    'description': 'Show or hide the Y-axis (or primary Y-axis for multi-axis charts).',
                  },
                },
              },
              'tickFormatting': {
                'type': 'object',
                'description': 'Tick formatting settings.',
                'properties': {
                  'xAxis': {
                    'type': 'string',
                    'description': 'Format string for X-axis tick labels.',
                  },
                  'yAxis': {
                    'type': 'string',
                    'description': 'Format string for Y-axis tick labels.',
                  },
                },
              },
              'backgroundColor': {
                'type': 'string',
                'description': 'Background color of the chart (e.g., "#FFFFFF").',
              },
              'padding': {
                'type': 'object',
                'description': 'Padding around the chart plot area.',
                'properties': {
                  'top': {'type': 'number', 'minimum': 0, 'description': 'Top padding in pixels.'},
                  'bottom': {'type': 'number', 'minimum': 0, 'description': 'Bottom padding in pixels.'},
                  'left': {'type': 'number', 'minimum': 0, 'description': 'Left padding in pixels.'},
                  'right': {'type': 'number', 'minimum': 0, 'description': 'Right padding in pixels.'},
                },
              },
              'fillOpacity': {
                'type': 'number',
                'minimum': 0,
                'maximum': 1,
                'description': 'Fill opacity for all series (0.0 to 1.0).',
              },
              'markerStyle': {
                'type': 'string',
                'enum': ['none', 'circle', 'square', 'triangle', 'diamond'],
                'description': 'Marker style for all series.',
              },
              'markerSize': {
                'type': 'number',
                'minimum': 0,
                'description': 'Marker size for all series.',
              },
              'interpolation': {
                'type': 'string',
                'enum': ['linear', 'bezier', 'stepped', 'monotone'],
                'description': 'Line interpolation for all series.',
              },
              'showPoints': {
                'type': 'boolean',
                'description': 'Show data points for all series.',
              },
              'tension': {
                'type': 'number',
                'minimum': 0,
                'maximum': 1,
                'description': 'Curve tension for all series (0.0 to 1.0).',
              },
            }
          },
        },
        'required': ['chartId'],
      };

  @override
  Future<ChartConfiguration> execute(Map<String, dynamic> args) async {
    final chartId = args['chartId'] as String?;
    if (chartId == null || chartId.isEmpty) {
      throw ArgumentError('chartId is required');
    }

    // Retrieve chart from data store, throw if not found
    final existingChart = _dataStore.get(chartId);
    if (existingChart == null) {
      throw Exception('Chart with ID "$chartId" not found');
    }

    final properties = args['properties'] as Map<String, dynamic>?;
    if (properties == null || properties.isEmpty) {
      return existingChart;
    }

    // Validate property names
    _validateProperties(properties);

    // Apply modifications
    final modifiedChart = _applyModifications(existingChart, properties);

    // Store the modified chart back (updates if id already exists)
    _dataStore.store(modifiedChart, id: chartId);

    return modifiedChart;
  }

  /// Validates that all property names are supported
  void _validateProperties(Map<String, dynamic> properties) {
    const validProperties = {
      'color',
      'lineWidth',
      'dashPattern',
      'xAxis',
      'yAxis',
      'yAxes',
      'legend',
      'grid',
      'theme',
      'useDarkTheme',
      'title',
      'subtitle',
      'series',
      'style',
      'annotations',
      'normalizationMode',
      // New properties for FR-004
      'type',
      'interactions',
      'fillOpacity',
      'markerStyle',
      'markerSize',
      'interpolation',
      'showPoints',
      'tension',
      'backgroundColor',
      'axisVisibility',
      'tickFormatting',
      'padding',
    };

    for (final key in properties.keys) {
      if (!validProperties.contains(key)) {
        throw ArgumentError('Invalid property: $key');
      }
    }
  }

  /// Applies modifications to the chart configuration
  ChartConfiguration _applyModifications(
    ChartConfiguration chart,
    Map<String, dynamic> properties,
  ) {
    // Handle chart type changes
    ChartType? modifiedType;
    if (properties.containsKey('type')) {
      final typeStr = properties['type'] as String?;
      if (typeStr != null) {
        modifiedType = ChartType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => chart.type,
        );
      }
    }

    // Handle series-level properties (color, lineWidth, dashPattern, fillOpacity, markerStyle, etc.)
    List<SeriesConfig>? modifiedSeries;

    // Handle series modifications (merge with existing series, preserving data source)
    if (properties.containsKey('series')) {
      final seriesList = properties['series'] as List;
      modifiedSeries = _mergeSeriesModifications(chart.series, seriesList);
    } else if (_hasSeriesLevelProperties(properties)) {
      // Handle individual property modifications on existing series
      modifiedSeries = chart.series.map((series) {
        List<double>? dashPattern;
        if (properties.containsKey('dashPattern') && properties['dashPattern'] != null) {
          dashPattern = (properties['dashPattern'] as List).map((e) => (e as num).toDouble()).toList();
        }

        MarkerStyle? markerStyle;
        if (properties.containsKey('markerStyle') && properties['markerStyle'] != null) {
          markerStyle = MarkerStyle.values.firstWhere(
            (e) => e.name == properties['markerStyle'],
            orElse: () => series.markerStyle,
          );
        }

        Interpolation? interpolation;
        if (properties.containsKey('interpolation') && properties['interpolation'] != null) {
          interpolation = Interpolation.values.firstWhere(
            (e) => e.name == properties['interpolation'],
            orElse: () => series.interpolation,
          );
        }

        return series.copyWith(
          color: properties['color'] as String?,
          strokeWidth: properties['lineWidth'] != null ? (properties['lineWidth'] as num).toDouble() : null,
          strokeDash: dashPattern,
          fillOpacity: properties['fillOpacity'] != null ? (properties['fillOpacity'] as num).toDouble() : null,
          markerStyle: markerStyle,
          markerSize: properties['markerSize'] != null ? (properties['markerSize'] as num).toDouble() : null,
          interpolation: interpolation,
          showPoints: properties['showPoints'] as bool?,
          tension: properties['tension'] != null ? (properties['tension'] as num).toDouble() : null,
        );
      }).toList();
    }

    // Handle xAxis modifications
    XAxisConfig? modifiedXAxis;
    if (properties.containsKey('xAxis')) {
      final xAxisProps = properties['xAxis'] as Map<String, dynamic>;
      modifiedXAxis = chart.xAxis?.copyWith(
            label: xAxisProps['label'] as String?,
            min: (xAxisProps['min'] as num?)?.toDouble(),
            max: (xAxisProps['max'] as num?)?.toDouble(),
          ) ??
          XAxisConfig(
            label: xAxisProps['label'] as String?,
            min: (xAxisProps['min'] as num?)?.toDouble(),
            max: (xAxisProps['max'] as num?)?.toDouble(),
          );
    }

    // Handle yAxis modifications (singular form - modifies first Y-axis)
    List<YAxisConfig>? modifiedYAxes;
    if (properties.containsKey('yAxis')) {
      final yAxisProps = properties['yAxis'] as Map<String, dynamic>;
      if (chart.yAxes.isNotEmpty) {
        modifiedYAxes = [
          chart.yAxes.first.copyWith(
            label: yAxisProps['label'] as String?,
            min: (yAxisProps['min'] as num?)?.toDouble(),
            max: (yAxisProps['max'] as num?)?.toDouble(),
          ),
          ...chart.yAxes.skip(1),
        ];
      } else {
        modifiedYAxes = [
          YAxisConfig(
            label: yAxisProps['label'] as String?,
            min: (yAxisProps['min'] as num?)?.toDouble(),
            max: (yAxisProps['max'] as num?)?.toDouble(),
          ),
        ];
      }
    }

    // Handle yAxes modifications (plural form - replaces all Y-axes)
    if (properties.containsKey('yAxes')) {
      final yAxesList = properties['yAxes'] as List;
      if (yAxesList.length > 4) {
        throw ArgumentError('Maximum 4 Y-axes supported. Please remove an axis before adding another.');
      }
      modifiedYAxes = yAxesList.map((axis) => YAxisConfig.fromJson(axis as Map<String, dynamic>)).toList();
    }

    // Handle legend modifications (stored in style or interactions)
    // For now, we'll store it as a dynamic field in the chart
    dynamic modifiedLegend = chart.legend;
    if (properties.containsKey('legend')) {
      modifiedLegend = properties['legend'];
    }

    // Handle grid modifications
    dynamic modifiedGrid = chart.grid;
    if (properties.containsKey('grid')) {
      modifiedGrid = properties['grid'];
    }

    // Handle theme modifications
    // Support both 'theme' (string: "light"/"dark") and 'useDarkTheme' (boolean)
    String? modifiedTheme = chart.theme;
    bool? modifiedUseDarkTheme = chart.useDarkTheme;
    if (properties.containsKey('theme')) {
      modifiedTheme = properties['theme'] as String?;
      // Sync useDarkTheme with theme string
      modifiedUseDarkTheme = modifiedTheme == 'dark';
    }
    if (properties.containsKey('useDarkTheme')) {
      modifiedUseDarkTheme = properties['useDarkTheme'] as bool?;
      // Sync theme string with useDarkTheme
      if (modifiedUseDarkTheme == true) {
        modifiedTheme = 'dark';
      } else if (modifiedUseDarkTheme == false) {
        modifiedTheme = 'light';
      }
    }

    // Handle annotations modifications
    List<dynamic>? modifiedAnnotations = chart.annotations;
    if (properties.containsKey('annotations')) {
      modifiedAnnotations = properties['annotations'] as List<dynamic>?;
    }

    // Handle normalizationMode modifications
    NormalizationModeConfig? modifiedNormalizationMode = chart.normalizationMode;
    if (properties.containsKey('normalizationMode')) {
      final modeStr = properties['normalizationMode'] as String?;
      if (modeStr != null) {
        modifiedNormalizationMode = NormalizationModeConfig.values.firstWhere(
          (e) => e.name == modeStr,
          orElse: () => NormalizationModeConfig.auto,
        );
      }
    }

    // Handle interactions modifications
    dynamic modifiedInteractions = chart.interactions;
    if (properties.containsKey('interactions')) {
      modifiedInteractions = properties['interactions'];
    }

    // Handle style modifications (backgroundColor, padding)
    ChartStyleConfig? modifiedStyle = chart.style;
    if (properties.containsKey('backgroundColor') || properties.containsKey('padding') || properties.containsKey('style')) {
      final existingStyle = chart.style;
      dynamic plotArea = existingStyle?.plotArea;

      // Handle padding property
      if (properties.containsKey('padding')) {
        final paddingProps = properties['padding'] as Map<String, dynamic>;
        plotArea = {
          if (paddingProps['top'] != null) 'paddingTop': (paddingProps['top'] as num).toDouble(),
          if (paddingProps['bottom'] != null) 'paddingBottom': (paddingProps['bottom'] as num).toDouble(),
          if (paddingProps['left'] != null) 'paddingLeft': (paddingProps['left'] as num).toDouble(),
          if (paddingProps['right'] != null) 'paddingRight': (paddingProps['right'] as num).toDouble(),
        };
      }

      modifiedStyle = ChartStyleConfig(
        backgroundColor: properties['backgroundColor'] ?? existingStyle?.backgroundColor,
        gridColor: existingStyle?.gridColor,
        axisColor: existingStyle?.axisColor,
        fontFamily: existingStyle?.fontFamily,
        fontSize: existingStyle?.fontSize,
        plotArea: plotArea,
      );
    }

    // Handle axisVisibility modifications (update xAxis and yAxis showAxisLine)
    if (properties.containsKey('axisVisibility')) {
      final axisVisibility = properties['axisVisibility'] as Map<String, dynamic>;
      if (axisVisibility.containsKey('xAxis')) {
        final showXAxis = axisVisibility['xAxis'] as bool;
        modifiedXAxis = (modifiedXAxis ?? chart.xAxis)?.copyWith(showAxisLine: showXAxis) ?? XAxisConfig(showAxisLine: showXAxis);
      }
      if (axisVisibility.containsKey('yAxis')) {
        final showYAxis = axisVisibility['yAxis'] as bool;
        if (chart.yAxes.isNotEmpty) {
          modifiedYAxes = [
            (modifiedYAxes?.first ?? chart.yAxes.first).copyWith(showAxisLine: showYAxis),
            ...(modifiedYAxes?.skip(1) ?? chart.yAxes.skip(1)),
          ];
        }
      }
    }

    // Handle tickFormatting modifications (update xAxis and yAxis tickFormat)
    if (properties.containsKey('tickFormatting')) {
      final tickFormatting = properties['tickFormatting'] as Map<String, dynamic>;
      if (tickFormatting.containsKey('xAxis')) {
        final xTickFormat = tickFormatting['xAxis'] as String;
        modifiedXAxis = (modifiedXAxis ?? chart.xAxis)?.copyWith(tickFormat: xTickFormat) ?? XAxisConfig(tickFormat: xTickFormat);
      }
      if (tickFormatting.containsKey('yAxis')) {
        final yTickFormat = tickFormatting['yAxis'] as String;
        if (chart.yAxes.isNotEmpty) {
          modifiedYAxes = [
            (modifiedYAxes?.first ?? chart.yAxes.first).copyWith(tickFormat: yTickFormat),
            ...(modifiedYAxes?.skip(1) ?? chart.yAxes.skip(1)),
          ];
        }
      }
    }

    // Create updated configuration using copyWith
    // CRITICAL: Preserve the original chart ID to ensure in-place updates
    final updated = chart.copyWith(
      type: modifiedType,
      title: properties.containsKey('title') ? properties['title'] as String? : null,
      subtitle: properties.containsKey('subtitle') ? properties['subtitle'] as String? : null,
      series: modifiedSeries,
      xAxis: modifiedXAxis,
      yAxes: modifiedYAxes,
      style: modifiedStyle,
      interactions: modifiedInteractions,
      legend: modifiedLegend,
      grid: modifiedGrid,
      theme: modifiedTheme,
      useDarkTheme: modifiedUseDarkTheme,
      annotations: modifiedAnnotations,
      normalizationMode: modifiedNormalizationMode,
    );

    // Ensure the ID is explicitly preserved (copyWith should handle this,
    // but we guarantee it here for in-place modification)
    return updated.copyWith(id: chart.id);
  }

  /// Checks if the properties contain any series-level styling properties
  bool _hasSeriesLevelProperties(Map<String, dynamic> properties) {
    const seriesProps = {
      'color',
      'lineWidth',
      'dashPattern',
      'fillOpacity',
      'markerStyle',
      'markerSize',
      'interpolation',
      'showPoints',
      'tension',
    };
    return properties.keys.any((key) => seriesProps.contains(key));
  }

  /// Merges agent-provided series modifications with existing series.
  ///
  /// For each series the agent modifies, we:
  /// 1. Find the matching existing series by ID
  /// 2. Preserve the existing data source (data or dataColumn)
  /// 3. Apply only the visual/config property changes from the agent
  ///
  /// If the agent provides a series ID that doesn't exist, it's skipped.
  /// If the agent provides data/dataColumn, it's ignored (we preserve existing).
  List<SeriesConfig> _mergeSeriesModifications(
    List<SeriesConfig> existingSeries,
    List<dynamic> agentSeriesList,
  ) {
    // Create a map of existing series by ID for quick lookup
    final existingById = {for (final s in existingSeries) s.id: s};

    // Track which existing series have been modified
    final modifiedIds = <String>{};
    final result = <SeriesConfig>[];

    for (final agentSeries in agentSeriesList) {
      final seriesJson = agentSeries as Map<String, dynamic>;
      final id = seriesJson['id'] as String?;

      if (id == null || !existingById.containsKey(id)) {
        // Skip series without ID or unknown IDs
        continue;
      }

      modifiedIds.add(id);
      final existing = existingById[id]!;

      // Merge: use agent's values if provided, otherwise keep existing
      // CRITICAL: Always preserve data source from existing series
      result.add(existing.copyWith(
        name: seriesJson['name'] as String? ?? existing.name,
        color: seriesJson['color'] as String? ?? existing.color,
        strokeWidth: seriesJson['strokeWidth'] != null ? (seriesJson['strokeWidth'] as num).toDouble() : existing.strokeWidth,
        strokeDash:
            seriesJson['strokeDash'] != null ? (seriesJson['strokeDash'] as List).map((e) => (e as num).toDouble()).toList() : existing.strokeDash,
        fillOpacity: seriesJson['fillOpacity'] != null ? (seriesJson['fillOpacity'] as num).toDouble() : existing.fillOpacity,
        markerStyle: seriesJson['markerStyle'] != null
            ? MarkerStyle.values.firstWhere(
                (e) => e.name == seriesJson['markerStyle'],
                orElse: () => existing.markerStyle,
              )
            : existing.markerStyle,
        markerSize: seriesJson['markerSize'] != null ? (seriesJson['markerSize'] as num).toDouble() : existing.markerSize,
        interpolation: seriesJson['interpolation'] != null
            ? Interpolation.values.firstWhere(
                (e) => e.name == seriesJson['interpolation'],
                orElse: () => existing.interpolation,
              )
            : existing.interpolation,
        showPoints: seriesJson['showPoints'] as bool? ?? existing.showPoints,
        yAxisId: seriesJson['yAxisId'] as String? ?? existing.yAxisId,
        unit: seriesJson['unit'] as String? ?? existing.unit,
        visible: seriesJson['visible'] as bool? ?? existing.visible,
        legendVisible: seriesJson['legendVisible'] as bool? ?? existing.legendVisible,
        tension: seriesJson['tension'] != null ? (seriesJson['tension'] as num).toDouble() : existing.tension,
        // Per-series Y-axis configuration fields
        yAxisPosition: seriesJson['yAxisPosition'] as String? ?? existing.yAxisPosition,
        yAxisLabel: seriesJson['yAxisLabel'] as String? ?? existing.yAxisLabel,
        yAxisUnit: seriesJson['yAxisUnit'] as String? ?? existing.yAxisUnit,
        yAxisColor: seriesJson['yAxisColor'] as String? ?? existing.yAxisColor,
        // NOTE: data and dataColumn are NEVER modified - always preserved from existing
      ));
    }

    // Add any existing series that weren't modified (preserve order)
    for (final existing in existingSeries) {
      if (!modifiedIds.contains(existing.id)) {
        result.add(existing);
      }
    }

    return result;
  }
}
