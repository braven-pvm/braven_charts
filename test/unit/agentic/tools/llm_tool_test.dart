library llm_tool_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';

class _EchoTool extends LLMTool {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echoes the input message.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'message': {'type': 'string'},
        },
        'required': ['message'],
      };

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    return args['message'];
  }
}

void main() {
  group('LLMTool', () {
    test('exposes name, description, input schema, and execute', () async {
      final tool = _EchoTool();

      expect(tool.name, 'echo');
      expect(tool.description, contains('Echoes'));
      expect(tool.inputSchema['type'], 'object');

      final result = await tool.execute({'message': 'hello'});
      expect(result, 'hello');
    });
  });
}
