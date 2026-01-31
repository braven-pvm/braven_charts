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
    // TDD RED PHASE: Stub implementation that throws UnimplementedError
    // This allows tests to compile but ensures they fail as expected
    throw UnimplementedError('GetChartTool.execute not implemented');
  }
}
