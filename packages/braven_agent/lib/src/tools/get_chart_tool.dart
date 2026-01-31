import 'dart:convert';

import '../models/chart_configuration.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for retrieving current chart configuration (V2 Schema).
///
/// Enables LLM agents to query chart state before making modifications.
/// Returns the complete chart configuration including all system-generated
/// IDs for the chart and its annotations.
///
/// ## V2 Schema: ID Discovery
///
/// This tool is essential for the V2 schema workflow where IDs are
/// system-generated. Use it to:
///
/// - **Discover annotation IDs** before calling `modify_chart` to update/remove
/// - **Inspect current series IDs** to target specific series for updates
/// - **Verify chart state** after modifications
///
/// ## Parameters
///
/// - `chartId` (required): The ID of the chart to retrieve
/// - `includeData` (optional, default: false): Whether to include full data arrays
///
/// ## includeData Behavior
///
/// When `includeData` is **false** (default), series data is summarized:
/// ```json
/// {"series": [{"id": "temp", "data": {"count": 100}, ...}]}
/// ```
///
/// When `includeData` is **true**, full data arrays are included:
/// ```json
/// {"series": [{"id": "temp", "data": [{"x": 0, "y": 20}, ...], ...}]}
/// ```
///
/// Use `includeData: false` for efficient ID discovery and chart inspection.
/// Use `includeData: true` when you need to analyze actual data values.
///
/// ## Example
///
/// ```dart
/// final tool = GetChartTool(
///   getChartById: (id) => chartRegistry[id],
/// );
///
/// // Discover IDs (efficient)
/// final result = await tool.execute({
///   'chartId': 'chart-uuid',
///   'includeData': false,
/// });
///
/// // Full data retrieval
/// final fullResult = await tool.execute({
///   'chartId': 'chart-uuid',
///   'includeData': true,
/// });
/// ```
///
/// ## Output
///
/// Returns a [ToolResult] with:
/// - `output`: JSON string of the chart configuration
/// - `data`: [ChartConfiguration] object for programmatic use
/// - `isError`: true if chart not found
///
/// See also:
/// - [ModifyChartTool] for updating charts using discovered IDs
/// - [CreateChartTool] for creating new charts
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
  String get description =>
      'Retrieves current chart configuration with all IDs including '
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
            'description':
                'Whether to include full data arrays. When false (default), '
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
