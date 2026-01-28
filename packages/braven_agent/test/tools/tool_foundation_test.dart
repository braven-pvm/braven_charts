import 'package:braven_agent/src/tools/tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock tool implementation for testing AgentTool abstract class.
class MockTool extends AgentTool {
  final String _name;
  final String _description;
  final Map<String, dynamic> _inputSchema;
  final Future<ToolResult> Function(Map<String, dynamic> input)? _executeHandler;

  MockTool({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
    Future<ToolResult> Function(Map<String, dynamic> input)? executeHandler,
  })  : _name = name,
        _description = description,
        _inputSchema = inputSchema,
        _executeHandler = executeHandler;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Map<String, dynamic> get inputSchema => _inputSchema;

  @override
  Future<ToolResult> execute(Map<String, dynamic> input) async {
    final handler = _executeHandler;
    if (handler != null) {
      return handler(input);
    }
    return const ToolResult(output: 'executed');
  }
}

void main() {
  // ============================================================
  // ToolResult Tests
  // ============================================================
  group('ToolResult', () {
    group('construction', () {
      test('creates with required output parameter', () {
        const result = ToolResult(output: 'success');

        expect(result.output, equals('success'));
      });

      test('isError defaults to false', () {
        const result = ToolResult(output: 'success');

        expect(result.isError, isFalse);
      });

      test('data defaults to null', () {
        const result = ToolResult(output: 'success');

        expect(result.data, isNull);
      });

      test('creates with all parameters', () {
        const data = {'key': 'value'};
        const result = ToolResult(
          output: 'error message',
          isError: true,
          data: data,
        );

        expect(result.output, equals('error message'));
        expect(result.isError, isTrue);
        expect(result.data, equals(data));
      });

      test('const constructor works correctly', () {
        // Verifies const constructor compiles and works
        const result1 = ToolResult(output: 'test');
        const result2 = ToolResult(output: 'test');

        expect(identical(result1, result2), isTrue);
      });
    });

    group('data field', () {
      test('can hold String data', () {
        const result = ToolResult(
          output: 'success',
          data: 'string data',
        );

        expect(result.data, isA<String>());
        expect(result.data, equals('string data'));
      });

      test('can hold Map data', () {
        const data = {'chartId': 'chart_123', 'type': 'line'};
        const result = ToolResult(output: 'success', data: data);

        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data, equals(data));
      });

      test('can hold List data', () {
        const data = [1, 2, 3];
        const result = ToolResult(output: 'success', data: data);

        expect(result.data, isA<List<int>>());
        expect(result.data, equals(data));
      });

      test('can hold int data', () {
        const result = ToolResult(output: 'success', data: 42);

        expect(result.data, isA<int>());
        expect(result.data, equals(42));
      });

      test('can hold custom object data', () {
        final customObject = DateTime(2026, 1, 28);
        final result = ToolResult(output: 'success', data: customObject);

        expect(result.data, isA<DateTime>());
        expect(result.data, equals(customObject));
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const result1 = ToolResult(output: 'test', isError: true);
        const result2 = ToolResult(output: 'test', isError: true);

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('different output values are not equal', () {
        const result1 = ToolResult(output: 'test1');
        const result2 = ToolResult(output: 'test2');

        expect(result1, isNot(equals(result2)));
      });

      test('different isError values are not equal', () {
        const result1 = ToolResult(output: 'test', isError: false);
        const result2 = ToolResult(output: 'test', isError: true);

        expect(result1, isNot(equals(result2)));
      });

      test('different data values are not equal', () {
        const result1 = ToolResult(output: 'test', data: 'data1');
        const result2 = ToolResult(output: 'test', data: 'data2');

        expect(result1, isNot(equals(result2)));
      });

      test('null vs non-null data are not equal', () {
        const result1 = ToolResult(output: 'test');
        const result2 = ToolResult(output: 'test', data: 'some data');

        expect(result1, isNot(equals(result2)));
      });

      test('same data objects are equal', () {
        const data = {'key': 'value'};
        const result1 = ToolResult(output: 'test', data: data);
        const result2 = ToolResult(output: 'test', data: data);

        expect(result1, equals(result2));
      });
    });

    group('toString', () {
      test('includes output length for successful result', () {
        const result = ToolResult(output: 'Hello, World!');
        final str = result.toString();

        expect(str, contains('output: 13 chars'));
        expect(str, contains('isError: false'));
      });

      test('includes isError state', () {
        const result = ToolResult(output: 'error', isError: true);
        final str = result.toString();

        expect(str, contains('isError: true'));
      });

      test('includes data type when present', () {
        const result = ToolResult(output: 'test', data: 'string data');
        final str = result.toString();

        expect(str, contains('data: String'));
      });

      test('shows null for missing data', () {
        const result = ToolResult(output: 'test');
        final str = result.toString();

        expect(str, contains('data: null'));
      });
    });

    group('props', () {
      test('props includes all fields', () {
        const result = ToolResult(
          output: 'test',
          isError: true,
          data: 'data',
        );

        expect(result.props, equals(['test', true, 'data']));
      });

      test('props handles null data', () {
        const result = ToolResult(output: 'test', isError: false);

        expect(result.props, equals(['test', false, null]));
      });
    });
  });

  // ============================================================
  // AgentTool Tests
  // ============================================================
  group('AgentTool', () {
    group('interface implementation', () {
      test('concrete implementation can be created', () {
        final tool = MockTool(
          name: 'test_tool',
          description: 'A test tool for verification',
          inputSchema: {
            'type': 'object',
            'properties': {
              'message': {'type': 'string'},
            },
          },
        );

        expect(tool, isA<AgentTool>());
      });

      test('name getter returns correct value', () {
        final tool = MockTool(
          name: 'create_chart',
          description: 'Creates a chart',
          inputSchema: {},
        );

        expect(tool.name, equals('create_chart'));
      });

      test('description getter returns correct value', () {
        final tool = MockTool(
          name: 'test',
          description: 'A detailed description of what the tool does',
          inputSchema: {},
        );

        expect(
          tool.description,
          equals('A detailed description of what the tool does'),
        );
      });

      test('inputSchema getter returns correct schema', () {
        final schema = {
          'type': 'object',
          'properties': {
            'title': {'type': 'string', 'description': 'Chart title'},
            'chartType': {
              'type': 'string',
              'enum': ['line', 'bar', 'area', 'scatter'],
            },
          },
          'required': ['chartType'],
        };

        final tool = MockTool(
          name: 'test',
          description: 'test',
          inputSchema: schema,
        );

        expect(tool.inputSchema, equals(schema));
        expect(tool.inputSchema['type'], equals('object'));
        expect(tool.inputSchema['properties'], isA<Map>());
        expect(tool.inputSchema['required'], contains('chartType'));
      });
    });

    group('execute method', () {
      test('execute returns Future<ToolResult>', () async {
        final tool = MockTool(
          name: 'test',
          description: 'test',
          inputSchema: {},
        );

        final result = tool.execute({});

        expect(result, isA<Future<ToolResult>>());
      });

      test('execute can return successful result', () async {
        final tool = MockTool(
          name: 'echo',
          description: 'Echoes the message',
          inputSchema: {},
          executeHandler: (input) async {
            final message = input['message'] as String;
            return ToolResult(output: 'Echo: $message');
          },
        );

        final result = await tool.execute({'message': 'Hello'});

        expect(result.output, equals('Echo: Hello'));
        expect(result.isError, isFalse);
      });

      test('execute can return error result', () async {
        final tool = MockTool(
          name: 'validate',
          description: 'Validates input',
          inputSchema: {},
          executeHandler: (input) async {
            if (!input.containsKey('required_field')) {
              return const ToolResult(
                output: 'Error: required_field is missing',
                isError: true,
              );
            }
            return const ToolResult(output: 'Valid');
          },
        );

        final result = await tool.execute({});

        expect(result.isError, isTrue);
        expect(result.output, contains('required_field is missing'));
      });

      test('execute can return result with structured data', () async {
        final chartData = {'id': 'chart_123', 'type': 'line'};

        final tool = MockTool(
          name: 'create_chart',
          description: 'Creates a chart',
          inputSchema: {},
          executeHandler: (input) async {
            return ToolResult(
              output: '{"id": "chart_123", "type": "line"}',
              data: chartData,
            );
          },
        );

        final result = await tool.execute({'type': 'line'});

        expect(result.data, equals(chartData));
        expect(result.isError, isFalse);
      });

      test('execute receives input parameters correctly', () async {
        Map<String, dynamic>? capturedInput;

        final tool = MockTool(
          name: 'capture',
          description: 'Captures input',
          inputSchema: {},
          executeHandler: (input) async {
            capturedInput = input;
            return const ToolResult(output: 'captured');
          },
        );

        await tool.execute({
          'string': 'value',
          'number': 42,
          'boolean': true,
          'nested': {'key': 'value'},
        });

        expect(capturedInput, isNotNull);
        expect(capturedInput!['string'], equals('value'));
        expect(capturedInput!['number'], equals(42));
        expect(capturedInput!['boolean'], isTrue);
        expect(capturedInput!['nested'], equals({'key': 'value'}));
      });
    });

    group('tool patterns', () {
      test('multiple tools can coexist with different names', () {
        final tool1 = MockTool(
          name: 'create_chart',
          description: 'Creates a chart',
          inputSchema: {},
        );

        final tool2 = MockTool(
          name: 'modify_chart',
          description: 'Modifies a chart',
          inputSchema: {},
        );

        expect(tool1.name, isNot(equals(tool2.name)));
        expect(tool1.description, isNot(equals(tool2.description)));
      });

      test('tool can be stored in collection by name', () {
        final tools = <String, AgentTool>{};

        final tool = MockTool(
          name: 'test_tool',
          description: 'Test',
          inputSchema: {},
        );

        tools[tool.name] = tool;

        expect(tools['test_tool'], equals(tool));
      });

      test('tool list can be iterated', () async {
        final tools = <AgentTool>[
          MockTool(
            name: 'tool1',
            description: 'First tool',
            inputSchema: {},
            executeHandler: (_) async => const ToolResult(output: 'one'),
          ),
          MockTool(
            name: 'tool2',
            description: 'Second tool',
            inputSchema: {},
            executeHandler: (_) async => const ToolResult(output: 'two'),
          ),
        ];

        final names = tools.map((t) => t.name).toList();
        expect(names, equals(['tool1', 'tool2']));

        final results = await Future.wait(tools.map((t) => t.execute({})));
        expect(results.map((r) => r.output).toList(), equals(['one', 'two']));
      });
    });
  });
}
