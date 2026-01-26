import '../models/annotation_config.dart';
import '../models/chart_configuration.dart';
import '../services/data_store.dart';
import 'llm_tool.dart';

/// Tool that adds annotations to existing chart configurations.
///
/// Supports adding:
/// - Horizontal and vertical reference lines
/// - Reference zones (horizontal or vertical)
/// - Text labels at specific coordinates
/// - Sport science power zone overlays
class AddAnnotationTool extends LLMTool {
  /// Data store for retrieving and storing charts
  final DataStore<ChartConfiguration> _dataStore;

  /// Creates a new AddAnnotationTool
  ///
  /// If dataStore is not provided, a default instance will be created
  AddAnnotationTool({DataStore<ChartConfiguration>? dataStore})
      : _dataStore = dataStore ?? DataStore<ChartConfiguration>();

  @override
  String get name => 'add_annotation';

  @override
  String get description =>
      'Adds annotations (reference lines, zones, labels, markers) to an existing chart.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'chartId': {
            'type': 'string',
            'description': 'Unique identifier of the chart to annotate.'
          },
          'annotationType': {
            'type': 'string',
            'description':
                'Type of annotation: referenceLine, zone, textLabel, marker, powerZones'
          },
          'orientation': {
            'type': 'string',
            'description':
                'Orientation for lines and zones: horizontal or vertical'
          },
          'value': {
            'type': 'number',
            'description': 'Value for reference lines'
          },
          'minValue': {
            'type': 'number',
            'description': 'Minimum value for zones'
          },
          'maxValue': {
            'type': 'number',
            'description': 'Maximum value for zones'
          },
          'x': {'type': 'number', 'description': 'X coordinate for labels'},
          'y': {'type': 'number', 'description': 'Y coordinate for labels'},
          'text': {'type': 'string', 'description': 'Text content for labels'},
          'label': {'type': 'string', 'description': 'Label for annotation'},
          'color': {'type': 'string', 'description': 'Color for annotation'},
          'opacity': {'type': 'number', 'description': 'Opacity (0.0 to 1.0)'},
          'fontSize': {
            'type': 'number',
            'description': 'Font size for text labels'
          },
          'ftp': {'type': 'number', 'description': 'FTP value for power zones'},
          'zones': {
            'type': 'array',
            'description': 'Zone definitions for power zones'
          },
        },
        'required': ['chartId', 'annotationType'],
      };

  @override
  Future<ChartConfiguration> execute(Map<String, dynamic> args) async {
    final chartId = args['chartId'] as String?;
    if (chartId == null || chartId.isEmpty) {
      throw ArgumentError('chartId is required');
    }

    final annotationType = args['annotationType'] as String?;
    if (annotationType == null || annotationType.isEmpty) {
      throw ArgumentError('annotationType is required');
    }

    // Validate annotation type
    const validTypes = {
      'referenceLine',
      'zone',
      'textLabel',
      'marker',
      'powerZones'
    };
    if (!validTypes.contains(annotationType)) {
      throw ArgumentError('Unsupported annotation type: $annotationType');
    }

    // Retrieve chart from data store, throw if not found
    final existingChart = _dataStore.get(chartId);
    if (existingChart == null) {
      throw Exception('Chart with ID "$chartId" not found');
    }

    // Build annotations
    final newAnnotations = _buildAnnotations(annotationType, args);

    // Add to existing annotations
    final updatedAnnotations = [
      ...?existingChart.annotations,
      ...newAnnotations,
    ];

    final updatedChart =
        existingChart.copyWith(annotations: updatedAnnotations);

    // Store the updated chart back (updates if id already exists)
    _dataStore.store(updatedChart, id: chartId);

    return updatedChart;
  }

  /// Builds annotation configurations based on type and arguments
  List<AnnotationConfig> _buildAnnotations(
    String annotationType,
    Map<String, dynamic> args,
  ) {
    switch (annotationType) {
      case 'referenceLine':
        return [
          AnnotationConfig(
            type: 'referenceLine',
            orientation: args['orientation'] as String?,
            value: args['value'] as double?,
            label: args['label'] as String?,
            color: args['color'] as String?,
            lineWidth: args['lineWidth'] as double?,
            dashPattern: args['dashPattern'] != null
                ? (args['dashPattern'] as List).cast<double>()
                : null,
          ),
        ];

      case 'zone':
        return [
          AnnotationConfig(
            type: 'zone',
            orientation: args['orientation'] as String?,
            minValue: args['minValue'] as double?,
            maxValue: args['maxValue'] as double?,
            label: args['label'] as String?,
            color: args['color'] as String?,
            opacity: args['opacity'] as double?,
          ),
        ];

      case 'textLabel':
        return [
          AnnotationConfig(
            type: 'textLabel',
            x: args['x'] as double?,
            y: args['y'] as double?,
            text: args['text'] as String?,
            label: args['label'] as String?,
            color: args['color'] as String?,
            fontSize: args['fontSize'] as double?,
          ),
        ];

      case 'marker':
        return [
          AnnotationConfig(
            type: 'marker',
            x: args['x'] as double?,
            y: args['y'] as double?,
            label: args['label'] as String?,
            color: args['color'] as String?,
          ),
        ];

      case 'powerZones':
        return _buildPowerZones(args);

      default:
        throw ArgumentError('Unsupported annotation type: $annotationType');
    }
  }

  /// Builds power zone annotations
  List<AnnotationConfig> _buildPowerZones(Map<String, dynamic> args) {
    final ftp = args['ftp'] as double?;
    final zones = args['zones'] as List?;

    if (ftp == null || zones == null) {
      throw ArgumentError('ftp and zones are required for powerZones');
    }

    return zones.map((zone) {
      final zoneMap = zone as Map<String, dynamic>;
      final min = zoneMap['min'] as double;
      final max = zoneMap['max'] as double;
      final label = zoneMap['label'] as String;

      return AnnotationConfig(
        type: 'zone',
        orientation: 'horizontal',
        minValue: ftp * min,
        maxValue: ftp * max,
        label: label,
        opacity: 0.2,
      );
    }).toList();
  }
}
