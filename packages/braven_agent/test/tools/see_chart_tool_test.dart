import 'package:braven_agent/src/llm/models/message_content.dart';
import 'package:braven_agent/src/tools/see_chart_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeeChartTool', () {
    group('interface', () {
      test('name is see_chart', () {
        final tool = SeeChartTool(onCapture: () async => null);
        expect(tool.name, equals('see_chart'));
      });

      test('description mentions screenshot and visual analysis', () {
        final tool = SeeChartTool(onCapture: () async => null);
        expect(tool.description, contains('screenshot'));
        expect(tool.description, contains('visual'));
      });

      test('inputSchema allows optional reason parameter', () {
        final tool = SeeChartTool(onCapture: () async => null);
        expect(tool.inputSchema['type'], equals('object'));
        expect(tool.inputSchema['properties']['reason']['type'], equals('string'));
        expect(tool.inputSchema['required'], isEmpty);
      });
    });

    group('execute', () {
      test('returns successful result with imageContent when capture succeeds', () async {
        const testImage = ImageContent(data: 'base64data', mediaType: 'image/png');
        final tool = SeeChartTool(onCapture: () async => testImage);

        final result = await tool.execute({});

        expect(result.isError, isFalse);
        expect(result.imageContent, equals(testImage));
        expect(result.output, contains('captured successfully'));
      });

      test('includes reason in output when provided', () async {
        const testImage = ImageContent(data: 'base64data', mediaType: 'image/png');
        final tool = SeeChartTool(onCapture: () async => testImage);

        final result = await tool.execute({'reason': 'verify axis labels'});

        expect(result.isError, isFalse);
        expect(result.output, contains('verify axis labels'));
      });

      test('returns error result when capture returns null', () async {
        final tool = SeeChartTool(onCapture: () async => null);

        final result = await tool.execute({});

        expect(result.isError, isTrue);
        expect(result.imageContent, isNull);
        expect(result.output, contains('Failed to capture'));
      });

      test('returns error result when capture throws exception', () async {
        final tool = SeeChartTool(
          onCapture: () async => throw Exception('Capture failed'),
        );

        final result = await tool.execute({});

        expect(result.isError, isTrue);
        expect(result.imageContent, isNull);
        expect(result.output, contains('Error capturing'));
      });
    });
  });
}
