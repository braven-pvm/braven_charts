// @orchestra-task: 16
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/add_annotation_tool.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';

void main() {
  group('AddAnnotationTool', () {
    test('exposes name, description, and input schema', () {
      final LLMTool tool = AddAnnotationTool();

      expect(tool.name, isNotEmpty);
      expect(tool.description, isNotEmpty);
      expect(tool.inputSchema, isNotEmpty);
      expect(tool.inputSchema['type'], equals('object'));
      expect(tool.inputSchema['properties'], isA<Map>());
      expect(tool.inputSchema['required'], contains('chartId'));
      expect(tool.inputSchema['required'], contains('annotationType'));
    });

    test('adds horizontal reference line with label', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'referenceLine',
        'orientation': 'horizontal',
        'value': 250.0,
        'label': 'FTP Threshold',
        'color': '#FF0000',
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.annotations, isNotEmpty);
      expect(config.annotations.first.type, equals('referenceLine'));
      expect(config.annotations.first.orientation, equals('horizontal'));
      expect(config.annotations.first.value, equals(250.0));
      expect(config.annotations.first.label, equals('FTP Threshold'));
    });

    test('adds vertical reference line', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'referenceLine',
        'orientation': 'vertical',
        'value': 1800.0,
        'label': 'Interval Start',
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.annotations.first.orientation, equals('vertical'));
      expect(config.annotations.first.value, equals(1800.0));
    });

    test('adds reference zone with transparency', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'zone',
        'orientation': 'horizontal',
        'minValue': 200.0,
        'maxValue': 250.0,
        'label': 'Zone 3',
        'color': '#FFA500',
        'opacity': 0.3,
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.annotations.first.type, equals('zone'));
      expect(config.annotations.first.minValue, equals(200.0));
      expect(config.annotations.first.maxValue, equals(250.0));
      expect(config.annotations.first.opacity, equals(0.3));
    });

    test('adds text label at specific coordinates', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'textLabel',
        'x': 1200.0,
        'y': 280.0,
        'text': 'Peak Power',
        'fontSize': 14.0,
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.annotations.first.type, equals('textLabel'));
      expect(config.annotations.first.x, equals(1200.0));
      expect(config.annotations.first.y, equals(280.0));
      expect(config.annotations.first.text, equals('Peak Power'));
    });

    test('adds sport science power zone overlays', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'powerZones',
        'ftp': 250.0,
        'zones': [
          {'min': 0.0, 'max': 0.55, 'label': 'Active Recovery'},
          {'min': 0.56, 'max': 0.75, 'label': 'Endurance'},
          {'min': 0.76, 'max': 0.90, 'label': 'Tempo'},
          {'min': 0.91, 'max': 1.05, 'label': 'Threshold'},
          {'min': 1.06, 'max': 1.20, 'label': 'VO2Max'},
        ],
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.annotations.length, equals(5));
      expect(config.annotations.first.type, equals('zone'));
      expect(config.annotations.first.label, contains('Active Recovery'));
    });

    test('validates required chartId parameter', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      expect(
        () => tool.execute({
          'annotationType': 'referenceLine',
          'value': 250.0,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates required annotationType parameter', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      expect(
        () => tool.execute({
          'chartId': 'test-chart-123',
          'value': 250.0,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates annotation type is supported', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      expect(
        () => tool.execute({
          'chartId': 'test-chart-123',
          'annotationType': 'unsupportedType',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns updated chart with annotation added', () async {
      final AddAnnotationTool tool = AddAnnotationTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'annotationType': 'referenceLine',
        'orientation': 'horizontal',
        'value': 250.0,
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.id, equals('test-chart-123'));
      expect(config.annotations, isNotEmpty);
    });
  });
}
