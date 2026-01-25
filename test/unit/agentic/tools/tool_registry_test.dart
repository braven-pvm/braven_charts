library tool_registry_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';

class _SumTool extends LLMTool {
  @override
  String get name => 'sum';

  @override
  String get description => 'Adds two numbers.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'a': {'type': 'number'},
          'b': {'type': 'number'},
        },
        'required': ['a', 'b'],
      };

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return (args['a'] as num) + (args['b'] as num);
  }
}

void main() {
  group('ToolRegistry', () {
    test('registers and retrieves tools by name', () {
      final registry = ToolRegistry();
      final tool = _SumTool();

      registry.register(tool);

      final fetched = registry.get('sum');
      expect(fetched, same(tool));
    });

    test('lists all registered tools', () {
      final registry = ToolRegistry();
      registry.register(_SumTool());

      final tools = registry.list();
      expect(tools.length, 1);
      expect(tools.first.name, 'sum');
    });

    test('executes a tool by name with args', () async {
      final registry = ToolRegistry();
      registry.register(_SumTool());

      final result = await registry.execute('sum', {'a': 2, 'b': 3});
      expect(result, 5);
    });
  });
}
