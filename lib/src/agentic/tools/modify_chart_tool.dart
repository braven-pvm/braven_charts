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
- title, subtitle: Chart titles
- series: Array of series configs (each with id, color, strokeWidth, strokeDash, yAxisId, etc.)
- xAxis, yAxis, yAxes: Axis configurations (label, min, max, position)
- normalizationMode: "none"|"auto"|"perSeries" for multi-axis display
- legend, grid: Visibility and styling
- theme: "light" or "dark"
- annotations: Reference lines, zones, labels
- color, lineWidth, dashPattern: Quick styling for all series''',
            'properties': {
              'normalizationMode': {
                'type': 'string',
                'enum': ['none', 'auto', 'perSeries'],
                'description':
                    'Controls Y-axis normalization for multi-series charts. Use "perSeries" when overlaying metrics with different units (e.g., Power + Heart Rate). Each series should specify yAxisId and the corresponding Y-axis should have position "left" or "right".'
              },
              'series': {
                'type': 'array',
                'description':
                    'Array of series to update. Each series can have: id (required), color, strokeWidth, strokeDash, yAxisId (for multi-axis), unit.'
              },
              'yAxes': {
                'type': 'array',
                'maxItems': 4,
                'description': 'Array of Y-axis configurations. Each can have: id, label, unit, position ("left"|"right"), min, max, color.'
              }
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
      'title',
      'subtitle',
      'series',
      'style',
      'annotations',
      'normalizationMode',
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
    // Handle series-level properties (color, lineWidth, dashPattern)
    List<SeriesConfig>? modifiedSeries;

    // Handle complete series replacement (when LLM provides a full series array)
    if (properties.containsKey('series')) {
      final seriesList = properties['series'] as List;
      modifiedSeries = seriesList.map((s) => SeriesConfig.fromJson(s as Map<String, dynamic>)).toList();
    } else if (properties.containsKey('color') || properties.containsKey('lineWidth') || properties.containsKey('dashPattern')) {
      // Handle individual property modifications on existing series
      modifiedSeries = chart.series.map((series) {
        List<double>? dashPattern;
        if (properties.containsKey('dashPattern') && properties['dashPattern'] != null) {
          dashPattern = (properties['dashPattern'] as List).map((e) => (e as num).toDouble()).toList();
        }

        return series.copyWith(
          color: properties['color'] as String?,
          strokeWidth: properties['lineWidth'] != null ? (properties['lineWidth'] as num).toDouble() : null,
          strokeDash: dashPattern,
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
    String? modifiedTheme = chart.theme;
    if (properties.containsKey('theme')) {
      modifiedTheme = properties['theme'] as String?;
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

    // Create updated configuration using copyWith
    // CRITICAL: Preserve the original chart ID to ensure in-place updates
    final updated = chart.copyWith(
      title: properties.containsKey('title') ? properties['title'] as String? : null,
      subtitle: properties.containsKey('subtitle') ? properties['subtitle'] as String? : null,
      series: modifiedSeries,
      xAxis: modifiedXAxis,
      yAxes: modifiedYAxes,
      legend: modifiedLegend,
      grid: modifiedGrid,
      theme: modifiedTheme,
      annotations: modifiedAnnotations,
      normalizationMode: modifiedNormalizationMode,
    );

    // Ensure the ID is explicitly preserved (copyWith should handle this,
    // but we guarantee it here for in-place modification)
    return updated.copyWith(id: chart.id);
  }
}
