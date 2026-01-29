import '../models/chart_configuration.dart';
import 'agent_tool.dart';
import 'tool_result.dart';

/// Tool for creating chart configurations from LLM input.
///
/// This tool allows the LLM to create interactive charts by providing
/// structured input including data series, chart type, and styling options.
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
class CreateChartTool extends AgentTool {
  @override
  String get name => throw UnimplementedError();

  @override
  String get description => throw UnimplementedError();

  @override
  Map<String, dynamic> get inputSchema => throw UnimplementedError();

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    throw UnimplementedError();
  }
}
