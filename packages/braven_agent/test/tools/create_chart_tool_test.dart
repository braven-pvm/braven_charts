// @orchestra-task: 4

import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/enums.dart';
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

        test('series item has type property with enum', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final seriesProps = seriesItems['properties'] as Map;
          expect(seriesProps, contains('type'));
          expect(seriesProps['type']['type'], equals('string'));
          expect(seriesProps['type']['enum'], isA<List>());
        });

        test('series item type enum includes all chart types', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final seriesItems = properties['series']['items'] as Map;
          final seriesProps = seriesItems['properties'] as Map;
          final enumValues = seriesProps['type']['enum'] as List;
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

        test('respects series type parameter', () async {
          final result = await tool.execute({
            'prompt': 'Create a bar chart',
            'series': [
              {
                'id': 'data',
                'type': 'bar',
                'data': [
                  {'x': 0, 'y': 100},
                ],
              },
            ],
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series.first.type, equals(ChartType.bar));
        });

        test('defaults to line series when type not specified', () async {
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
          expect(chart.series.first.type, equals(ChartType.line));
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

      group('with invalid series type enum', () {
        test('returns error result for invalid type', () async {
          final result = await tool.execute({
            'prompt': 'Create a chart',
            'series': [
              {
                'id': 'series1',
                'type': 'invalid_chart_type',
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
            'series': [
              {
                'id': 'series1',
                'type': 'pie',
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
            'series': [
              {
                'id': 'series1',
                'type': 'histogram',
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

      test('output contains series type', () async {
        final result = await tool.execute({
          'prompt': 'Create a chart',
          'series': [
            {
              'id': 'data',
              'type': 'area',
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

    // ==========================================================
    // [tdd-red] T020: V2 Schema Contract Tests (US1)
    // ==========================================================
    // @orchestra-task: 4
    group('[tdd-red] V2 Schema - nested yAxis (US1)', () {
      test('[tdd-red] inputSchema series items include nested yAxis property',
          tags: ['tdd-red'], () {
        // T020: Per FR-001, series must support nested yAxis object
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;

        // Should have nested yAxis property
        expect(seriesProps, contains('yAxis'),
            reason: 'FR-001: series must have nested yAxis property');
        expect(seriesProps['yAxis'], isA<Map>(),
            reason: 'FR-001: yAxis must be an object schema');
        expect(seriesProps['yAxis']['type'], equals('object'),
            reason: 'FR-001: yAxis must be type object');
      });

      test('[tdd-red] inputSchema series yAxis has position property with enum',
          tags: ['tdd-red'], () {
        // T020: yAxis must include position field for left/right placement
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;
        final yAxisProps = seriesProps['yAxis']['properties'] as Map;

        expect(yAxisProps, contains('position'),
            reason: 'FR-001: yAxis must have position property');
        expect(yAxisProps['position']['enum'], isA<List>(),
            reason: 'position must be an enum');
        expect(yAxisProps['position']['enum'], contains('left'));
        expect(yAxisProps['position']['enum'], contains('right'));
      });

      test('[tdd-red] inputSchema series yAxis has label and unit properties',
          tags: ['tdd-red'], () {
        // T020: yAxis must include label and unit for axis display
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;
        final yAxisProps = seriesProps['yAxis']['properties'] as Map;

        expect(yAxisProps, contains('label'),
            reason: 'FR-001: yAxis must have label property');
        expect(yAxisProps, contains('unit'),
            reason: 'FR-001: yAxis must have unit property');
      });

      test('[tdd-red] inputSchema series yAxis has min/max properties',
          tags: ['tdd-red'], () {
        // T020: yAxis must include min/max for axis range
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;
        final yAxisProps = seriesProps['yAxis']['properties'] as Map;

        expect(yAxisProps, contains('min'),
            reason: 'FR-001: yAxis must have min property');
        expect(yAxisProps, contains('max'),
            reason: 'FR-001: yAxis must have max property');
        expect(yAxisProps['min']['type'], equals('number'));
        expect(yAxisProps['max']['type'], equals('number'));
      });

      test(
          '[tdd-red] inputSchema does NOT have flat yAxis fields on series (FR-002)',
          tags: ['tdd-red'], () {
        // T020: Per FR-002, flat y-axis fields are prohibited
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;

        // These flat fields should NOT exist
        expect(seriesProps.containsKey('yAxisPosition'), isFalse,
            reason: 'FR-002: yAxisPosition flat field is prohibited');
        expect(seriesProps.containsKey('yAxisLabel'), isFalse,
            reason: 'FR-002: yAxisLabel flat field is prohibited');
        expect(seriesProps.containsKey('yAxisUnit'), isFalse,
            reason: 'FR-002: yAxisUnit flat field is prohibited');
        expect(seriesProps.containsKey('yAxisColor'), isFalse,
            reason: 'FR-002: yAxisColor flat field is prohibited');
        expect(seriesProps.containsKey('yAxisMin'), isFalse,
            reason: 'FR-002: yAxisMin flat field is prohibited');
        expect(seriesProps.containsKey('yAxisMax'), isFalse,
            reason: 'FR-002: yAxisMax flat field is prohibited');
      });

      test(
          '[tdd-red] inputSchema does NOT have yAxisId reference field (FR-003)',
          tags: ['tdd-red'], () {
        // T020: Per FR-003, yAxisId references are prohibited
        final properties =
            tool.inputSchema['properties'] as Map<String, dynamic>;
        final seriesItems = properties['series']['items'] as Map;
        final seriesProps = seriesItems['properties'] as Map;

        expect(seriesProps.containsKey('yAxisId'), isFalse,
            reason: 'FR-003: yAxisId reference field is prohibited');
      });

      test('[tdd-red] execute parses nested yAxis from series input',
          tags: ['tdd-red'], () async {
        // T020: Tool must parse nested yAxis configuration
        final result = await tool.execute({
          'prompt': 'Create a dual-axis chart',
          'series': [
            {
              'id': 'power',
              'data': [
                {'x': 0, 'y': 250},
              ],
              'yAxis': {
                'position': 'left',
                'label': 'Power',
                'unit': 'W',
                'min': 0,
                'max': 500,
              },
            },
            {
              'id': 'heart-rate',
              'data': [
                {'x': 0, 'y': 145},
              ],
              'yAxis': {
                'position': 'right',
                'label': 'Heart Rate',
                'unit': 'bpm',
                'min': 60,
                'max': 200,
              },
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        // Verify series have yAxis configuration
        expect(chart.series[0].yAxis, isNotNull,
            reason: 'First series must have yAxis');
        expect(chart.series[0].yAxis!.label, equals('Power'));
        expect(chart.series[0].yAxis!.unit, equals('W'));

        expect(chart.series[1].yAxis, isNotNull,
            reason: 'Second series must have yAxis');
        expect(chart.series[1].yAxis!.label, equals('Heart Rate'));
        expect(chart.series[1].yAxis!.unit, equals('bpm'));
      });

      test('[tdd-red] execute respects yAxis position for multi-axis chart',
          tags: ['tdd-red'], () async {
        // T020: Each series yAxis position should be preserved
        final result = await tool.execute({
          'prompt': 'Create a multi-axis chart',
          'normalizationMode': 'perSeries',
          'series': [
            {
              'id': 'power',
              'data': [
                {'x': 0, 'y': 250},
              ],
              'yAxis': {
                'position': 'left',
                'label': 'Power',
              },
            },
            {
              'id': 'cadence',
              'data': [
                {'x': 0, 'y': 90},
              ],
              'yAxis': {
                'position': 'right',
                'label': 'Cadence',
              },
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        expect(chart.series[0].yAxis!.position, equals(AxisPosition.left));
        expect(chart.series[1].yAxis!.position, equals(AxisPosition.right));
      });
    });

    // ==========================================================
    // [tdd-red] T021: Annotation ID Generation Tests (US1)
    // ==========================================================
    // @orchestra-task: 4
    group('[tdd-red] Annotation ID generation (US1)', () {
      test('[tdd-red] annotations get system-generated IDs on create',
          tags: ['tdd-red'], () async {
        // T021: Per FR-004, annotation IDs are system-generated
        final result = await tool.execute({
          'prompt': 'Create a chart with annotation',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
          'annotations': [
            {
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 75,
              'label': 'Threshold',
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        expect(chart.annotations, hasLength(1));
        expect(chart.annotations[0].id, isNotNull,
            reason: 'FR-004: annotation must have system-generated ID');
        expect(chart.annotations[0].id, isNotEmpty,
            reason: 'FR-004: annotation ID must be non-empty');
      });

      test('[tdd-red] each annotation gets unique ID', tags: ['tdd-red'],
          () async {
        // T021: Multiple annotations should get unique IDs
        final result = await tool.execute({
          'prompt': 'Create a chart with multiple annotations',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
          'annotations': [
            {
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 75,
              'label': 'Lower Threshold',
            },
            {
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 125,
              'label': 'Upper Threshold',
            },
            {
              'type': 'zone',
              'orientation': 'horizontal',
              'minValue': 75,
              'maxValue': 125,
              'label': 'Target Zone',
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        expect(chart.annotations, hasLength(3));

        // All IDs should be non-null and unique
        final ids = chart.annotations.map((a) => a.id).toList();
        expect(ids.every((id) => id != null && id.isNotEmpty), isTrue,
            reason: 'All annotations must have non-empty IDs');

        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, equals(3),
            reason: 'All annotation IDs must be unique');
      });

      test('[tdd-red] agent-supplied annotation ID is ignored (edge case)',
          tags: ['tdd-red'], () async {
        // T021: If agent supplies ID, system should ignore and generate new one
        final result = await tool.execute({
          'prompt': 'Create a chart with annotation',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
          'annotations': [
            {
              'id': 'agent-supplied-id', // This should be ignored
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 75,
              'label': 'Threshold',
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        expect(chart.annotations, hasLength(1));
        // The agent-supplied ID should be ignored, system generates its own
        expect(chart.annotations[0].id, isNot(equals('agent-supplied-id')),
            reason: 'System should ignore agent-supplied annotation ID');
        expect(chart.annotations[0].id, isNotEmpty,
            reason: 'System should generate a new ID');
      });

      test('[tdd-red] output JSON includes annotation IDs', tags: ['tdd-red'],
          () async {
        // T021: The tool output should include generated IDs per FR-011
        final result = await tool.execute({
          'prompt': 'Create a chart with annotation',
          'series': [
            {
              'id': 'data',
              'data': [
                {'x': 0, 'y': 100},
              ],
            },
          ],
          'annotations': [
            {
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 75,
            },
          ],
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;
        final annotationId = chart.annotations[0].id;

        // The output string should contain the generated annotation ID
        expect(result.output, contains(annotationId!),
            reason: 'FR-011: output must include generated annotation IDs');
      });
    });
  });
}
