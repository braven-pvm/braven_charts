import '../models/chart_configuration.dart';
import 'llm_tool.dart';

/// Tool that converts natural language prompts into chart configurations.
///
/// TODO: Implement in green phase.
class CreateChartTool extends LLMTool {
  @override
  String get name => throw UnimplementedError('CreateChartTool.name');

  @override
  String get description => throw UnimplementedError('CreateChartTool.description');

  @override
  Map<String, dynamic> get inputSchema => throw UnimplementedError('CreateChartTool.inputSchema');

  @override
  Future<ChartConfiguration> execute(Map<String, dynamic> args) async {
    throw UnimplementedError('CreateChartTool.execute');
  }
}
