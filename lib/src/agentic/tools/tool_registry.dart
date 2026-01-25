import 'llm_tool.dart';

/// Registry for LLM tools used in function calling.
class ToolRegistry {
  final Map<String, LLMTool> _tools = {};

  /// Register a tool by name (overwrites if name already exists).
  void register(LLMTool tool) {
    _tools[tool.name] = tool;
  }

  /// Get a tool by name.
  LLMTool? get(String name) {
    return _tools[name];
  }

  /// List all registered tools.
  List<LLMTool> list() {
    return _tools.values.toList(growable: false);
  }

  /// Execute a tool by name with arguments.
  Future<dynamic> execute(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) {
      throw StateError('Tool not registered: $name');
    }
    return tool.execute(args);
  }
}
