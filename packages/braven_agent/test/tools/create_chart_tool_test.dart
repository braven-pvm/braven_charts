// @orchestra-task: 12
@Tags(['tdd-red'])
library;

import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/tools/create_chart_tool.dart';
import 'package:braven_agent/src/tools/tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // CreateChartTool Tests
  // ============================================================
  group('CreateChartTool', () {
    late CreateChartTool tool;

    setUp(() {
      tool = CreateChartTool();
    });

    // ==========================================================
    // Properties Tests
    // ==========================================================
    group('properties', () {
      test('name returns "create_chart"', () {
        expect(tool.name, equals('create_chart'));
      });

      test('description is non-empty and descriptive', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description.length, greaterThan(20));
      });

      test('description mentions chart creation', () {
        expect(tool.description.toLowerCase(), contains('chart'));
      });

      test('implements AgentTool interface', () {
        expect(tool, isA<AgentTool>());
      });
    });

    // ==========================================================
    // Input Schema Structure Tests
    // ==========================================================
    group('inputSchema structure', () {
      test('has type: object', () {
        expect(tool.inputSchema['type'], equals('object'));
      });

      test('has properties object', () {
        expect(tool.inputSchema['properties'], isA<Map<String, dynamic>>());
      });

      test('has required array', () {
        expect(tool.inputSchema['required'], isA<List>());
      });

      test('required includes "prompt"', () {
        final required = tool.inputSchema['required'] as List;
        expect(required, contains('prompt'));
      });

      test('required includes "series"', () {
        final required = tool.inputSchema['required'] as List;
        expect(required, contains('series'));
      });

      group('properties content', () {
        test('has prompt property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('prompt'));
          expect(properties['prompt']['type'], equals('string'));
        });

        test('prompt has description', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties['prompt']['description'], isNotEmpty);
        });

        test('has type property with enum', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('type'));
          expect(properties['type']['type'], equals('string'));
          expect(properties['type']['enum'], isA<List>());
        });

        test('type enum includes all chart types', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final enumValues = properties['type']['enum'] as List;
          expect(enumValues, contains('line'));
          expect(enumValues, contains('area'));
          expect(enumValues, contains('bar'));
          expect(enumValues, contains('scatter'));
        });

        test('has title property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('title'));
          expect(properties['title']['type'], equals('string'));
        });

        test('has subtitle property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('subtitle'));
          expect(properties['subtitle']['type'], equals('string'));
        });

        test('has series property as array', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('series'));
          expect(properties['series']['type'], equals('array'));
        });

        test('series items have required structure', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          expect(seriesItems['type'], equals('object'));
          expect(seriesItems['properties'], isA<Map>());
        });

        test('series item has id property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final seriesProps = seriesItems['properties'] as Map;
          expect(seriesProps, contains('id'));
          expect(seriesProps['id']['type'], equals('string'));
        });

        test('series item has data property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final seriesProps = seriesItems['properties'] as Map;
          expect(seriesProps, contains('data'));
          expect(seriesProps['data']['type'], equals('array'));
        });

        test('series item data has x,y point structure', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final seriesProps = seriesItems['properties'] as Map;
          final dataItems = seriesProps['data']['items'] as Map;
          expect(dataItems['type'], equals('object'));
          final pointProps = dataItems['properties'] as Map;
          expect(pointProps, contains('x'));
          expect(pointProps, contains('y'));
          expect(pointProps['x']['type'], equals('number'));
          expect(pointProps['y']['type'], equals('number'));
        });

        test('series item requires id and data', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final required = seriesItems['required'] as List;
          expect(required, contains('id'));
          expect(required, contains('data'));
        });

        test('has xAxis property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('xAxis'));
          expect(properties['xAxis']['type'], equals('object'));
        });

        test('has annotations property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('annotations'));
          expect(properties['annotations']['type'], equals('array'));
        });

        test('has style property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('style'));
          expect(properties['style']['type'], equals('object'));
        });

        test('has showGrid property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('showGrid'));
          expect(properties['showGrid']['type'], equals('boolean'));
        });

        test('has showLegend property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('showLegend'));
          expect(properties['showLegend']['type'], equals('boolean'));
        });

        test('has legendPosition property with enum', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('legendPosition'));
          expect(properties['legendPosition']['type'], equals('string'));
          expect(properties['legendPosition']['enum'], isA<List>());
        });

        test('legendPosition enum includes valid positions', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final enumValues = properties['legendPosition']['enum'] as List;
          expect(enumValues, contains('top'));
          expect(enumValues, contains('bottom'));
          expect(enumValues, contains('left'));
          expect(enumValues, contains('right'));
        });

        test('has useDarkTheme property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('useDarkTheme'));
          expect(properties['useDarkTheme']['type'], equals('boolean'));
        });

        test('has normalizationMode property with enum', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('normalizationMode'));
          expect(properties['normalizationMode']['type'], equals('string'));
          expect(properties['normalizationMode']['enum'], isA<List>());
        });

        test('normalizationMode enum includes valid modes', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final enumValues = properties['normalizationMode']['enum'] as List;
          expect(enumValues, contains('none'));
          expect(enumValues, contains('auto'));
          expect(enumValues, contains('perSeries'));
        });
      });
    });

    // ==========================================================
    // Execute Method Tests
    // ==========================================================
    group('execute', () {
      group('with valid input', () {
        test('returns ToolResult', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                  {'x': 1, 'y': 20},
                ],
              },
            ],
          });

          expect(result, isA<ToolResult>());
        });

        test('returns successful result with isError=false', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.isError, isFalse);
        });

        test('returns ChartConfiguration in data field', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'temp',
                'data': [
                  {'x': 0, 'y': 20},
                ],
              },
            ],
          });

          expect(result.data, isA<ChartConfiguration>());
        });

        test('returns non-empty output string', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'temp',
                'data': [
                  {'x': 0, 'y': 20},
                ],
              },
            ],
          });

          expect(result.output, isNotEmpty);
        });

        test('output contains JSON representation', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'type': 'line',
            'series': [
              {
                'id': 'temp',
                'data': [
                  {'x': 0, 'y': 20},
                ],
              },
            ],
          });

          expect(result.output, contains('line'));
        });

        test('respects chart type parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a bar chart',
            'type': 'bar',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.type, equals(ChartType.bar));
        });

        test('defaults to line chart when type not specified', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.type, equals(ChartType.line));
        });

        test('respects title parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'title': 'My Chart Title',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.title, equals('My Chart Title'));
        });

        test('respects subtitle parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'subtitle': 'Chart Subtitle',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.subtitle, equals('Chart Subtitle'));
        });

        test('generates unique chart id', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.id, isNotNull);
          expect(chart.id, isNotEmpty);
        });

        test('parses multiple series correctly', () async {
          final result = await tool.execute({
            'prompt': 'Create a multi-series chart',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
              {
                'id': 'series2',
                'data': [
                  {'x': 0, 'y': 20},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series, hasLength(2));
          expect(chart.series[0].id, equals('series1'));
          expect(chart.series[1].id, equals('series2'));
        });

        test('parses data points correctly', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 1.5, 'y': 10.5},
                  {'x': 2.5, 'y': 20.5},
                  {'x': 3.5, 'y': 30.5},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series[0].data, hasLength(3));
          expect(chart.series[0].data[0].x, equals(1.5));
          expect(chart.series[0].data[0].y, equals(10.5));
          expect(chart.series[0].data[2].x, equals(3.5));
          expect(chart.series[0].data[2].y, equals(30.5));
        });

        test('respects showGrid parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'showGrid': false,
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showGrid, isFalse);
        });

        test('respects showLegend parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'showLegend': false,
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showLegend, isFalse);
        });

        test('respects legendPosition parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'legendPosition': 'right',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.legendPosition, equals(LegendPosition.right));
        });

        test('respects useDarkTheme parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'useDarkTheme': true,
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.useDarkTheme, isTrue);
        });

        test('respects normalizationMode parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'normalizationMode': 'perSeries',
            'series': [
              {
                'id': 'data',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.normalizationMode,
            equals(NormalizationModeConfig.perSeries),
          );
        });
      });

      group('with missing prompt', () {
        test('returns error result', () async {
          final result = await tool.execute({
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.isError, isTrue);
        });

        test('error output mentions prompt', () async {
          final result = await tool.execute({
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.output.toLowerCase(), contains('prompt'));
        });

        test('data is null on error', () async {
          final result = await tool.execute({
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.data, isNull);
        });
      });

      group('with missing series', () {
        test('returns error result', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
          });

          expect(result.isError, isTrue);
        });

        test('error output mentions series', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
          });

          expect(result.output.toLowerCase(), contains('series'));
        });

        test('data is null on error', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
          });

          expect(result.data, isNull);
        });
      });

      group('with empty series', () {
        test('returns error result', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
            'series': <Map<String, dynamic>>[],
          });

          expect(result.isError, isTrue);
        });

        test('error output mentions series', () async {
          final result = await tool.execute({
            'prompt': 'Create a line chart',
            'series': <Map<String, dynamic>>[],
          });

          expect(result.output.toLowerCase(), contains('series'));
        });
      });

      group('with invalid type enum', () {
        test('returns error result for invalid type', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'type': 'invalid_chart_type',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.isError, isTrue);
        });

        test('error output mentions type', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'type': 'pie',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.output.toLowerCase(), contains('type'));
        });

        test('error suggests valid types', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'type': 'histogram',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          // Error should mention valid types
          final output = result.output.toLowerCase();
          expect(
            output.contains('line') ||
                output.contains('bar') ||
                output.contains('area') ||
                output.contains('scatter'),
            isTrue,
            reason: 'Error should suggest valid chart types',
          );
        });
      });

      group('with invalid legendPosition enum', () {
        test('returns error result', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'legendPosition': 'invalid_position',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.isError, isTrue);
        });
      });

      group('with invalid normalizationMode enum', () {
        test('returns error result', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'normalizationMode': 'invalid_mode',
            'series': [
              {
                'id': 'series1',
                'data': [
                  {'x': 0, 'y': 10},
                ],
              },
            ],
          });

          expect(result.isError, isTrue);
        });
      });
    });

    // ==========================================================
    // ChartConfiguration Output Tests
    // ==========================================================
    group('ChartConfiguration output', () {
      test('output is properly formatted JSON', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
        });

        // Output should be parseable JSON
        expect(result.output, startsWith('{'));
        expect(result.output, endsWith('}'));
      });

      test('output contains chart type', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'type': 'area',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
        });

        expect(result.output, contains('area'));
      });

      test('output contains chart id', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
        });

        final chart = result.data as ChartConfiguration;
        expect(result.output, contains(chart.id!));
      });

      test('ChartConfiguration has correct series count', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'series1',
              'data': [
                {'x': 0, 'y': 10},
              ],
            },
            {
              'id': 'series2',
              'data': [
                {'x': 0, 'y': 20},
              ],
            },
            {
              'id': 'series3',
              'data': [
                {'x': 0, 'y': 30},
              ],
            },
          ],
        });

        final chart = result.data as ChartConfiguration;
        expect(chart.series, hasLength(3));
      });

      test('series preserves series name when provided', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'temp',
              'name': 'Temperature',
              'data': [
                {'x': 0, 'y': 20},
              ],
            },
          ],
        });

        final chart = result.data as ChartConfiguration;
        expect(chart.series[0].name, equals('Temperature'));
      });

      test('series preserves color when provided', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'temp',
              'color': '#FF5733',
              'data': [
                {'x': 0, 'y': 20},
              ],
            },
          ],
        });

        final chart = result.data as ChartConfiguration;
        expect(chart.series[0].color, equals('#FF5733'));
      });

      test('ChartConfiguration defaults are sensible', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
        });

        final chart = result.data as ChartConfiguration;
        // Check sensible defaults
        expect(chart.showGrid, isTrue);
        expect(chart.showLegend, isTrue);
        expect(chart.legendPosition, equals(LegendPosition.bottom));
        expect(chart.useDarkTheme, isFalse);
        expect(chart.normalizationMode, equals(NormalizationModeConfig.none));
      });
    });
  });
}
