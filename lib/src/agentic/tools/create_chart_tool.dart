import '../models/axis_config.dart';
import '../models/chart_configuration.dart';
import '../models/series_config.dart';
import 'llm_tool.dart';

/// Tool that converts natural language prompts into chart configurations.
///
/// TODO: Implement in green phase.
class CreateChartTool extends LLMTool {
  @override
  String get name => 'create_chart';

  @override
  String get description =>
      'Converts a natural language prompt and dataset into a chart configuration.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'prompt': {
            'type': 'string',
            'description': 'Natural language request for the chart.'
          },
          'type': {
            'type': 'string',
            'description': 'Explicit chart type override.'
          },
          'series': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'Optional explicit series configurations.'
          },
          'xAxis': {
            'type': 'object',
            'description': 'Optional X-axis configuration.'
          },
          'yAxes': {
            'type': 'array',
            'items': {'type': 'object'},
            'description': 'Optional Y-axis configurations.'
          },
          'dataset': {
            'type': 'object',
            'properties': {
              'columns': {
                'type': 'array',
                'items': {'type': 'string'}
              },
              'rows': {
                'type': 'array',
                'items': {'type': 'object'}
              }
            }
          }
        },
        'required': ['prompt'],
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

    return ChartConfiguration(
      type: chartType,
      series: series,
      xAxis: xAxis,
      yAxes: yAxes,
    );
  }

  ChartType _resolveChartType(String? explicitType, String prompt) {
    final explicit = explicitType?.toLowerCase().trim();
    if (explicit != null && explicit.isNotEmpty) {
      final matched = ChartType.values
          .where((type) => type.name == explicit)
          .toList(growable: false);
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
      return seriesArg
          .map((entry) => SeriesConfig.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ))
          .toList(growable: false);
    }

    final dataset = args['dataset'];
    final columns = _extractColumns(dataset);
    final rows = _extractRows(dataset);

    final xColumn = _resolveXColumn(columns);
    final yColumns = columns.where((col) => col != xColumn).toList();
    final series = <SeriesConfig>[];

    if (yColumns.isEmpty) {
      series.add(
        SeriesConfig(
          id: 'series_1',
          name: 'Series 1',
          data: _buildSeriesData(rows, xColumn, null),
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
      return (dataset['columns'] as List)
          .map((entry) => entry.toString())
          .toList(growable: false);
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractRows(dynamic dataset) {
    if (dataset is Map && dataset['rows'] is List) {
      return (dataset['rows'] as List)
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
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
}
