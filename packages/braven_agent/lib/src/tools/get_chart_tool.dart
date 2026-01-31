import 'dart:convert';

import '../models/chart_configuration.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for retrieving current chart configuration with all IDs.
///
/// Enables LLM agents to query chart state before making modifications.
/// Returns the complete chart configuration including all system-generated
/// IDs for annotations and the chart itself.
///
/// ## Parameters
///
/// - `chartId` (required): The ID of the chart to retrieve
/// - `includeData` (optional, default: false): Whether to include full data arrays
///
/// ## Example
///
/// ```dart
/// final tool = GetChartTool(
///   getChartById: (id) => chartRegistry[id],
/// );
///
/// final result = await tool.execute({
///   'chartId': 'chart-123',
///   'includeData': true,
/// });
/// ```
///
/// When `includeData` is false (default), series data is summarized as
/// `{count: N}` instead of the full array. When true, full data arrays
/// are included in the response.
class GetChartTool extends AgentTool {
  /// Callback to retrieve a chart by its ID.
  ///
  /// Returns the [ChartConfiguration] for the given ID, or null if not found.
  final ChartConfiguration? Function(String)? getChartById;

  /// Creates a [GetChartTool] with the specified chart retrieval callback.
  ///
  /// The [getChartById] callback is used to look up charts by their ID.
  /// If not provided, all lookups will return null (resulting in error responses).
  GetChartTool({this.getChartById});

  @override
  String get name => 'get_chart';

  @override
  String get description => 'Retrieves current chart configuration with all IDs including '
      'annotations. Use this to discover annotation IDs before modifying a chart.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'chartId': {
            'type': 'string',
            'description': 'The ID of the chart to retrieve',
          },
          'includeData': {
            'type': 'boolean',
            'description': 'Whether to include full data arrays. When false (default), '
                'series data is summarized as {count: N}.',
            'default': false,
          },
        },
        'required': ['chartId'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    // Validate chartId parameter
    final chartId = input['chartId'] as String?;
    if (chartId == null || chartId.isEmpty) {
      return const ToolResult(
        output: 'Error: chartId is required',
        isError: true,
      );
    }

    // Check if getChartById callback is available
    if (getChartById == null) {
      return const ToolResult(
        output: 'Error: No chart retrieval callback available',
        isError: true,
      );
    }

    // Retrieve the chart
    final chart = getChartById!(chartId);
    if (chart == null) {
      return ToolResult(
        output: 'Error: Chart not found: $chartId',
        isError: true,
      );
    }

    // Extract includeData parameter (default: false)
    final includeData = input['includeData'] as bool? ?? false;

    // Build output JSON based on includeData
    final outputJson = _buildOutputJson(chart, includeData);

    return ToolResult(
      output: outputJson,
      data: chart,
    );
  }

  /// Builds the JSON output string for the chart.
  ///
  /// When [includeData] is false, series data is summarized as `{count: N}`.
  /// When [includeData] is true, full data arrays are included.
  String _buildOutputJson(ChartConfiguration chart, bool includeData) {
    final chartJson = chart.toJson();

    if (!includeData) {
      // Replace series data with count summary
      final series = chartJson['series'] as List<dynamic>;
      for (var i = 0; i < series.length; i++) {
        final seriesMap = series[i] as Map<String, dynamic>;
        final data = seriesMap['data'] as List<dynamic>?;
        if (data != null) {
          seriesMap['data'] = {'count': data.length};
        }
      }
    }

    return const JsonEncoder.withIndent('  ').convert(chartJson);
  }
}
