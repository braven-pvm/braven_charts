// @orchestra-task: 6
library;

import 'package:braven_agent/src/models/annotation_config.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/data_point.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/models/series_config.dart';
import 'package:braven_agent/src/models/y_axis_config.dart';
import 'package:braven_agent/src/tools/tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create test charts on demand
final Map<String, ChartConfiguration> _chartRegistry = {};

void main() {
  // ============================================================
  // ModifyChartTool Tests
  // ============================================================
  group('ModifyChartTool', () {
    late ModifyChartTool tool;
    late ChartConfiguration currentChart;

    setUp(() {
      // Clear registry before each test for isolation
      _chartRegistry.clear();

      // Set default current chart
      currentChart = _createDefaultChart();

      // Create tool with callback that returns current chart
      tool = ModifyChartTool(
        getActiveChart: () => currentChart,
      );
    });

    // ==========================================================
    // Properties Tests
    // ==========================================================
    group('properties', () {
      test('name returns "modify_chart"', () {
        expect(tool.name, equals('modify_chart'));
      });

      test('description is non-empty and descriptive', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description.length, greaterThan(20));
      });

      test('description mentions chart modification', () {
        expect(tool.description.toLowerCase(), contains('modif'));
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

      test('required includes "modifications"', () {
        final required = tool.inputSchema['required'] as List;
        expect(required, contains('modifications'));
      });

      group('properties content', () {
        test('has modifications property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('modifications'));
          expect(properties['modifications']['type'], equals('object'));
        });

        test('modifications has description', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties['modifications']['description'], isNotEmpty);
        });

        test('modifications has nested properties', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          final modifications =
              properties['modifications'] as Map<String, dynamic>;
          expect(modifications['properties'], isA<Map<String, dynamic>>());
        });

        group('modifications properties', () {
          late Map<String, dynamic> modProps;

          setUp(() {
            final properties =
                tool.inputSchema['properties'] as Map<String, dynamic>;
            final modifications =
                properties['modifications'] as Map<String, dynamic>;
            modProps = modifications['properties'] as Map<String, dynamic>;
          });

          test('update.series items have type property with enum', () {
            final updateProps = modProps['update']['properties'] as Map;
            final seriesItems = updateProps['series']['items'] as Map;
            final seriesProps = seriesItems['properties'] as Map;
            expect(seriesProps, contains('type'));
            expect(seriesProps['type']['type'], equals('string'));
            expect(seriesProps['type']['enum'], isA<List>());
          });

          test('update.series type enum includes all chart types', () {
            final updateProps = modProps['update']['properties'] as Map;
            final seriesItems = updateProps['series']['items'] as Map;
            final seriesProps = seriesItems['properties'] as Map;
            final enumValues = seriesProps['type']['enum'] as List;
            expect(enumValues, contains('line'));
            expect(enumValues, contains('area'));
            expect(enumValues, contains('bar'));
            expect(enumValues, contains('scatter'));
          });

          test('has title property', () {
            expect(modProps, contains('title'));
            expect(modProps['title']['type'], equals('string'));
          });

          test('has subtitle property', () {
            expect(modProps, contains('subtitle'));
            expect(modProps['subtitle']['type'], equals('string'));
          });

          test('has add.series property for adding series', () {
            final addProps = modProps['add']['properties'] as Map;
            expect(addProps, contains('series'));
            expect(addProps['series']['type'], equals('array'));
          });

          test('add.series items have required structure', () {
            final addProps = modProps['add']['properties'] as Map;
            final seriesItems = addProps['series']['items'] as Map;
            expect(seriesItems['type'], equals('object'));
            expect(seriesItems['properties'], isA<Map>());
          });

          test('add.series item has id property', () {
            final addProps = modProps['add']['properties'] as Map;
            final seriesItems = addProps['series']['items'] as Map;
            final seriesProps = seriesItems['properties'] as Map;
            expect(seriesProps, contains('id'));
            expect(seriesProps['id']['type'], equals('string'));
          });

          test('add.series item has data property', () {
            final addProps = modProps['add']['properties'] as Map;
            final seriesItems = addProps['series']['items'] as Map;
            final seriesProps = seriesItems['properties'] as Map;
            expect(seriesProps, contains('data'));
            expect(seriesProps['data']['type'], equals('array'));
          });

          test('add.series item data has x,y point structure', () {
            final addProps = modProps['add']['properties'] as Map;
            final seriesItems = addProps['series']['items'] as Map;
            final seriesProps = seriesItems['properties'] as Map;
            final dataItems = seriesProps['data']['items'] as Map;
            expect(dataItems['type'], equals('object'));
            final pointProps = dataItems['properties'] as Map;
            expect(pointProps, contains('x'));
            expect(pointProps, contains('y'));
            expect(pointProps['x']['type'], equals('number'));
            expect(pointProps['y']['type'], equals('number'));
          });

          test('add.series item requires id and data', () {
            final addProps = modProps['add']['properties'] as Map;
            final seriesItems = addProps['series']['items'] as Map;
            final required = seriesItems['required'] as List;
            expect(required, contains('id'));
            expect(required, contains('data'));
          });

          test('has remove.series property for removing series', () {
            final removeProps = modProps['remove']['properties'] as Map;
            expect(removeProps, contains('series'));
            expect(removeProps['series']['type'], equals('array'));
          });

          test('remove.series items are strings (series IDs)', () {
            final removeProps = modProps['remove']['properties'] as Map;
            final items = removeProps['series']['items'] as Map;
            expect(items['type'], equals('string'));
          });

          test('has showGrid property', () {
            expect(modProps, contains('showGrid'));
            expect(modProps['showGrid']['type'], equals('boolean'));
          });

          test('has showLegend property', () {
            expect(modProps, contains('showLegend'));
            expect(modProps['showLegend']['type'], equals('boolean'));
          });

          test('has legendPosition property with enum', () {
            expect(modProps, contains('legendPosition'));
            expect(modProps['legendPosition']['type'], equals('string'));
            expect(modProps['legendPosition']['enum'], isA<List>());
          });

          test('legendPosition enum includes valid positions', () {
            final enumValues = modProps['legendPosition']['enum'] as List;
            expect(enumValues, contains('top'));
            expect(enumValues, contains('bottom'));
            expect(enumValues, contains('left'));
            expect(enumValues, contains('right'));
          });

          test('has useDarkTheme property', () {
            expect(modProps, contains('useDarkTheme'));
            expect(modProps['useDarkTheme']['type'], equals('boolean'));
          });

          test('has normalizationMode property with enum', () {
            expect(modProps, contains('normalizationMode'));
            expect(modProps['normalizationMode']['type'], equals('string'));
            expect(modProps['normalizationMode']['enum'], isA<List>());
          });

          test('normalizationMode enum includes valid modes', () {
            final enumValues = modProps['normalizationMode']['enum'] as List;
            expect(enumValues, contains('none'));
            expect(enumValues, contains('auto'));
            expect(enumValues, contains('perSeries'));
          });
        });
      });
    });

    // ==========================================================
    // Execute Method Tests
    // ==========================================================
    group('execute', () {
      group('with missing modifications', () {
        test('returns error result', () async {
          final result = await tool.execute({});

          expect(result.isError, isTrue);
        });

        test('error output mentions modifications', () async {
          final result = await tool.execute({});

          expect(result.output.toLowerCase(), contains('modifications'));
        });

        test('data is null on error', () async {
          final result = await tool.execute({});

          expect(result.data, isNull);
        });
      });

      group('with no active chart (callback returns null)', () {
        late ModifyChartTool toolWithoutChart;

        setUp(() {
          // Create tool with callback that returns null
          toolWithoutChart = ModifyChartTool(
            getActiveChart: () => null,
          );
        });

        test('returns error result', () async {
          final result = await toolWithoutChart.execute({
            'modifications': {
              'title': 'New Title',
            },
          });

          expect(result.isError, isTrue);
        });

        test('error output indicates no active chart', () async {
          final result = await toolWithoutChart.execute({
            'modifications': {
              'title': 'New Title',
            },
          });

          expect(
            result.output.toLowerCase().contains('no active chart') ||
                result.output.toLowerCase().contains('create_chart'),
            isTrue,
            reason:
                'Error message should indicate no active chart and suggest create_chart',
          );
        });

        test('data is null when no active chart', () async {
          final result = await toolWithoutChart.execute({
            'modifications': {
              'title': 'New Title',
            },
          });

          expect(result.data, isNull);
        });
      });

      group('with valid input', () {
        // NOTE: These tests use the callback pattern.
        // The tool queries currentChart during execute().

        test('returns ToolResult', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Updated Title',
            },
          });

          expect(result, isA<ToolResult>());
        });

        test('returns successful result with isError=false', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Updated Title',
            },
          });

          expect(result.isError, isFalse);
        });

        test('returns ChartConfiguration in data field', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Updated Title',
            },
          });

          expect(result.data, isA<ChartConfiguration>());
        });

        test('returns non-empty output string', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Updated Title',
            },
          });

          expect(result.output, isNotEmpty);
        });

        test('output contains chart JSON', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'bar'},
                ],
              },
            },
          });

          // Output should be JSON containing the chart type
          expect(result.output, contains('bar'));
        });
      });

      group('modifying series type', () {
        test('can change series type from line to bar', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'bar'},
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series.firstWhere((s) => s.id == 'existing_series').type,
              equals(ChartType.bar));
        });

        test('can change series type from line to area', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'area'},
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series.firstWhere((s) => s.id == 'existing_series').type,
              equals(ChartType.area));
        });

        test('can change series type from line to scatter', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'scatter'},
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.series.firstWhere((s) => s.id == 'existing_series').type,
              equals(ChartType.scatter));
        });

        test('returns error for invalid series type value', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'pie'},
                ],
              },
            },
          });

          expect(result.isError, isTrue);
        });
      });

      group('modifying title and subtitle', () {
        test('can update title', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'New Chart Title',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.title, equals('New Chart Title'));
        });

        test('can update subtitle', () async {
          final result = await tool.execute({
            'modifications': {
              'subtitle': 'New Chart Subtitle',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.subtitle, equals('New Chart Subtitle'));
        });

        test('can update both title and subtitle', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Updated Title',
              'subtitle': 'Updated Subtitle',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.title, equals('Updated Title'));
          expect(chart.subtitle, equals('Updated Subtitle'));
        });

        test('can set title to empty string', () async {
          final result = await tool.execute({
            'modifications': {
              'title': '',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.title, equals(''));
        });
      });

      group('adding series', () {
        test('can add a single series to existing chart', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'new_series',
                    'data': [
                      {'x': 0, 'y': 100},
                      {'x': 1, 'y': 200},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          // Assuming original chart had 1 series, now should have 2
          expect(chart.series.length, greaterThanOrEqualTo(2));
          expect(
            chart.series.any((s) => s.id == 'new_series'),
            isTrue,
            reason: 'New series should be present in the chart',
          );
        });

        test('can add multiple series at once', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'new_series_a',
                    'data': [
                      {'x': 0, 'y': 10},
                    ],
                  },
                  {
                    'id': 'new_series_b',
                    'data': [
                      {'x': 0, 'y': 20},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.series.any((s) => s.id == 'new_series_a'),
            isTrue,
          );
          expect(
            chart.series.any((s) => s.id == 'new_series_b'),
            isTrue,
          );
        });

        test('added series has correct data points', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'data_series',
                    'data': [
                      {'x': 1.5, 'y': 10.5},
                      {'x': 2.5, 'y': 20.5},
                      {'x': 3.5, 'y': 30.5},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final newSeries =
              chart.series.firstWhere((s) => s.id == 'data_series');
          expect(newSeries.data, hasLength(3));
          expect(newSeries.data[0].x, equals(1.5));
          expect(newSeries.data[0].y, equals(10.5));
          expect(newSeries.data[2].x, equals(3.5));
          expect(newSeries.data[2].y, equals(30.5));
        });

        test('added series preserves name when provided', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'named_series',
                    'name': 'Temperature',
                    'data': [
                      {'x': 0, 'y': 25},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final newSeries =
              chart.series.firstWhere((s) => s.id == 'named_series');
          expect(newSeries.name, equals('Temperature'));
        });

        test('added series preserves color when provided', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'colored_series',
                    'color': '#FF5733',
                    'data': [
                      {'x': 0, 'y': 50},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final newSeries =
              chart.series.firstWhere((s) => s.id == 'colored_series');
          expect(newSeries.color, equals('#FF5733'));
        });
      });

      group('removing series', () {
        test('can remove a series by id', () async {
          final result = await tool.execute({
            'modifications': {
              'remove': {
                'series': ['series_to_remove'],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.series.any((s) => s.id == 'series_to_remove'),
            isFalse,
            reason: 'Removed series should not be present',
          );
        });

        test('can remove multiple series at once', () async {
          final result = await tool.execute({
            'modifications': {
              'remove': {
                'series': ['series_a', 'series_b'],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.series.any((s) => s.id == 'series_a'),
            isFalse,
          );
          expect(
            chart.series.any((s) => s.id == 'series_b'),
            isFalse,
          );
        });

        test('removing non-existent series returns error (V011)', () async {
          // V011: Error when remove.series contains non-existent ID
          final result = await tool.execute({
            'modifications': {
              'remove': {
                'series': ['non_existent_series'],
              },
            },
          });

          // Should error per V011 validation rule
          expect(result.isError, isTrue);
          expect(result.output, contains('V011'));
        });

        test('can add and remove series in same modification', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'new_series',
                    'data': [
                      {'x': 0, 'y': 10},
                    ],
                  },
                ],
              },
              'remove': {
                'series': ['old_series'],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.series.any((s) => s.id == 'new_series'),
            isTrue,
          );
          expect(
            chart.series.any((s) => s.id == 'old_series'),
            isFalse,
          );
        });
      });

      group('updating series data', () {
        test('can update data points for existing series', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {
                    'id': 'existing_series',
                    'data': [
                      {'x': 0, 'y': 999},
                      {'x': 1, 'y': 888},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final series =
              chart.series.firstWhere((s) => s.id == 'existing_series');
          expect(series.data[0].y, equals(999));
          expect(series.data[1].y, equals(888));
        });

        test('can update series name', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {
                    'id': 'existing_series',
                    'name': 'Updated Series Name',
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final series =
              chart.series.firstWhere((s) => s.id == 'existing_series');
          expect(series.name, equals('Updated Series Name'));
        });

        test('can update series color', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {
                    'id': 'existing_series',
                    'color': '#00FF00',
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          final series =
              chart.series.firstWhere((s) => s.id == 'existing_series');
          expect(series.color, equals('#00FF00'));
        });
      });

      group('preserving unmodified properties', () {
        test('modifying title preserves series', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'New Title Only',
            },
          });

          final chart = result.data as ChartConfiguration;
          // Series should be unchanged
          expect(chart.series, isNotEmpty);
        });

        test('modifying title preserves series type', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'New Title Only',
            },
          });

          final chart = result.data as ChartConfiguration;
          // Series type should be unchanged (line)
          expect(chart.series.first.type, equals(ChartType.line));
        });

        test('modifying series type preserves title', () async {
          final result = await tool.execute({
            'modifications': {
              'update': {
                'series': [
                  {'id': 'existing_series', 'type': 'bar'},
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          // Title should be unchanged
          expect(chart.title, isNotNull);
        });

        test('modifying showGrid preserves other options', () async {
          final result = await tool.execute({
            'modifications': {
              'showGrid': false,
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showGrid, isFalse);
          // Other properties should be unchanged
          expect(chart.showLegend, isNotNull);
        });

        test('adding series preserves existing series', () async {
          final result = await tool.execute({
            'modifications': {
              'add': {
                'series': [
                  {
                    'id': 'additional_series',
                    'data': [
                      {'x': 0, 'y': 50},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          // Original series should still be present
          expect(chart.series.length, greaterThanOrEqualTo(2));
        });
      });

      group('modifying display options', () {
        test('can toggle showGrid to false', () async {
          final result = await tool.execute({
            'modifications': {
              'showGrid': false,
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showGrid, isFalse);
        });

        test('can toggle showLegend to false', () async {
          final result = await tool.execute({
            'modifications': {
              'showLegend': false,
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showLegend, isFalse);
        });

        test('can change legendPosition', () async {
          final result = await tool.execute({
            'modifications': {
              'legendPosition': 'right',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.legendPosition, equals(LegendPosition.right));
        });

        test('can toggle useDarkTheme', () async {
          final result = await tool.execute({
            'modifications': {
              'useDarkTheme': true,
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.useDarkTheme, isTrue);
        });

        test('can change normalizationMode', () async {
          final result = await tool.execute({
            'modifications': {
              'normalizationMode': 'perSeries',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
            chart.normalizationMode,
            equals(NormalizationModeConfig.perSeries),
          );
        });

        test('returns error for invalid legendPosition', () async {
          final result = await tool.execute({
            'modifications': {
              'legendPosition': 'invalid_position',
            },
          });

          expect(result.isError, isTrue);
        });

        test('returns error for invalid normalizationMode', () async {
          final result = await tool.execute({
            'modifications': {
              'normalizationMode': 'invalid_mode',
            },
          });

          expect(result.isError, isTrue);
        });
      });

      group('multiple modifications at once', () {
        test('can modify title and add series with type together', () async {
          final result = await tool.execute({
            'modifications': {
              'title': 'Multi-Modification Chart',
              'add': {
                'series': [
                  {
                    'id': 'new_data',
                    'type': 'area',
                    'data': [
                      {'x': 0, 'y': 5},
                    ],
                  },
                ],
              },
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(
              chart.series
                  .any((s) => s.id == 'new_data' && s.type == ChartType.area),
              isTrue);
          expect(chart.title, equals('Multi-Modification Chart'));
          expect(chart.series.any((s) => s.id == 'new_data'), isTrue);
        });

        test('can modify all display options at once', () async {
          final result = await tool.execute({
            'modifications': {
              'showGrid': false,
              'showLegend': false,
              'useDarkTheme': true,
              'legendPosition': 'top',
              'normalizationMode': 'auto',
            },
          });

          final chart = result.data as ChartConfiguration;
          expect(chart.showGrid, isFalse);
          expect(chart.showLegend, isFalse);
          expect(chart.useDarkTheme, isTrue);
          expect(chart.legendPosition, equals(LegendPosition.top));
          expect(
            chart.normalizationMode,
            equals(NormalizationModeConfig.auto),
          );
        });
      });
    });

    // ==========================================================
    // ChartConfiguration Output Tests
    // ==========================================================
    group('ChartConfiguration output', () {
      test('output is properly formatted JSON', () async {
        final result = await tool.execute({
          'modifications': {
            'title': 'Test Chart',
          },
        });

        // Should be valid JSON starting with { and ending with }
        expect(result.output, startsWith('{'));
        expect(result.output, endsWith('}'));
      });

      test('output contains modified series type', () async {
        final result = await tool.execute({
          'modifications': {
            'update': {
              'series': [
                {'id': 'existing_series', 'type': 'area'},
              ],
            },
          },
        });

        expect(result.output, contains('area'));
      });

      test('output contains chart id', () async {
        final result = await tool.execute({
          'modifications': {
            'title': 'Test',
          },
        });

        final chart = result.data as ChartConfiguration;
        // The chart should maintain its original ID
        expect(result.output, contains(chart.id!));
      });

      test('modified ChartConfiguration has all required fields', () async {
        final result = await tool.execute({
          'modifications': {
            'title': 'Complete Chart',
          },
        });

        final chart = result.data as ChartConfiguration;
        expect(chart.id, isNotNull);
        expect(chart.series, isNotNull);
      });
    });

    // ==========================================================
    // US2: TDD Red Phase Tests - Update/Add/Remove Operations
    // @orchestra-task: 6
    // ==========================================================
    group('US2: update/add/remove operations (TDD RED)', () {
      // ----------------------------------------------------------
      // US2: Update operation with new schema structure
      // ----------------------------------------------------------
      group('update operation with new schema', () {
        test(
          'update.series changes property on existing series',
          () async {
            // Test the NEW schema structure with explicit update.series[]
            // Uses update.series array structure
            final result = await tool.execute({
              'modifications': {
                'update': {
                  'series': [
                    {'id': 'existing_series', 'color': '#FF0000'},
                  ],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            final series =
                chart.series.firstWhere((s) => s.id == 'existing_series');
            // This test should FAIL because the new schema is not implemented yet
            expect(series.color, equals('#FF0000'));
          },
        );

        test(
          'update.annotations changes label on existing annotation',
          () async {
            // Need to set up chart with annotations first
            currentChart = _createChartWithAnnotations();

            final result = await tool.execute({
              'modifications': {
                'update': {
                  'annotations': [
                    {'id': 'ann-001', 'label': 'Updated Label'},
                  ],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            final annotation =
                chart.annotations.firstWhere((a) => a.id == 'ann-001');
            // This test should FAIL because update.annotations is not implemented
            expect(annotation.label, equals('Updated Label'));
          },
        );
      });

      // ----------------------------------------------------------
      // US2: Add operation with ID generation
      // ----------------------------------------------------------
      group('add operation with ID generation', () {
        test(
          'add.annotations generates system ID when not provided',
          () async {
            final result = await tool.execute({
              'modifications': {
                'add': {
                  'annotations': [
                    {
                      'type': 'referenceLine',
                      'value': 200.0,
                      'orientation': 'horizontal'
                    },
                  ],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            // Find the newly added annotation
            final newAnnotation = chart.annotations.firstWhere(
              (a) => a.value == 200.0 && a.type == AnnotationType.referenceLine,
              orElse: () => throw StateError('Annotation not found'),
            );
            // System should generate an ID
            expect(newAnnotation.id, isNotNull);
            expect(newAnnotation.id, isNotEmpty);
          },
        );

        test(
          'add.series adds new series with the specified ID',
          () async {
            final result = await tool.execute({
              'modifications': {
                'add': {
                  'series': [
                    {
                      'id': 'brand-new-series',
                      'data': [
                        {'x': 0, 'y': 100},
                        {'x': 1, 'y': 200},
                      ],
                    },
                  ],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            // Should find the new series with the add.series structure
            expect(
              chart.series.any((s) => s.id == 'brand-new-series'),
              isTrue,
              reason: 'add.series should add the new series',
            );
          },
        );
      });

      // ----------------------------------------------------------
      // US2: Remove operation
      // ----------------------------------------------------------
      group('remove operation', () {
        test(
          'remove.series removes series by ID',
          () async {
            final result = await tool.execute({
              'modifications': {
                'remove': {
                  'series': ['series_to_remove'],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            // This tests the new remove.series structure (not removeSeries)
            expect(
              chart.series.any((s) => s.id == 'series_to_remove'),
              isFalse,
              reason: 'remove.series should remove the specified series',
            );
          },
        );

        test(
          'remove.annotations removes annotation by ID',
          () async {
            currentChart = _createChartWithAnnotations();

            final result = await tool.execute({
              'modifications': {
                'remove': {
                  'annotations': ['ann-001'],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            // This tests the new remove.annotations structure
            expect(
              chart.annotations.any((a) => a.id == 'ann-001'),
              isFalse,
              reason:
                  'remove.annotations should remove the specified annotation',
            );
          },
        );
      });

      // ----------------------------------------------------------
      // US2: Execution Order (remove → add → update)
      // ----------------------------------------------------------
      group('execution order', () {
        test(
          'operations execute in order: remove then add then update',
          () async {
            // This tests FR-015: execution order must be remove → add → update
            // We remove a series, add one with same ID, then update it
            // If order is wrong, this will fail
            final result = await tool.execute({
              'modifications': {
                'update': {
                  'series': [
                    {'id': 'recycled-id', 'color': '#00FF00'},
                  ],
                },
                'add': {
                  'series': [
                    {
                      'id': 'recycled-id',
                      'data': [
                        {'x': 0, 'y': 50},
                      ],
                      'color': '#FF0000',
                    },
                  ],
                },
                'remove': {
                  'series': ['series_to_remove'],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            // After remove → add → update:
            // 1. series_to_remove is removed
            // 2. recycled-id is added with color #FF0000
            // 3. recycled-id is updated to color #00FF00
            expect(
              chart.series.any((s) => s.id == 'series_to_remove'),
              isFalse,
              reason: 'series_to_remove should be removed',
            );
            final recycledSeries =
                chart.series.firstWhere((s) => s.id == 'recycled-id');
            expect(
              recycledSeries.color,
              equals('#00FF00'),
              reason: 'Update should run after add, so color should be #00FF00',
            );
          },
        );
      });

      // ----------------------------------------------------------
      // US2: Deep Merge on yAxis update
      // ----------------------------------------------------------
      group('deep merge semantics', () {
        test(
          'partial yAxis update preserves non-updated properties',
          () async {
            // Set up chart with series that has yAxis config
            currentChart = _createChartWithYAxis();

            final result = await tool.execute({
              'modifications': {
                'update': {
                  'series': [
                    {
                      'id': 'series-with-yaxis',
                      'yAxis': {'label': 'Updated Label'},
                    },
                  ],
                },
              },
            });

            final chart = result.data as ChartConfiguration;
            final series =
                chart.series.firstWhere((s) => s.id == 'series-with-yaxis');
            // Deep merge should preserve unit and position
            expect(series.yAxis, isNotNull);
            expect(series.yAxis!.label, equals('Updated Label'));
            expect(
              series.yAxis!.unit,
              equals('W'),
              reason: 'Deep merge should preserve unit',
            );
            expect(
              series.yAxis!.position,
              equals(AxisPosition.left),
              reason: 'Deep merge should preserve position',
            );
          },
        );
      });
    });
  });
}

/// Creates a default chart configuration for testing.
ChartConfiguration _createDefaultChart() {
  return const ChartConfiguration(
    id: 'test-chart-123',
    title: 'Original Title',
    subtitle: 'Original Subtitle',
    series: [
      SeriesConfig(
        id: 'existing_series',
        name: 'Existing Series',
        type: ChartType.line,
        data: [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 20),
        ],
        color: '#2196F3',
      ),
      SeriesConfig(
        id: 'old_series',
        name: 'Old Series',
        type: ChartType.line,
        data: [
          DataPoint(x: 0, y: 5),
        ],
        color: '#4CAF50',
      ),
      // Additional series for removal/update tests
      SeriesConfig(
        id: 'series_to_remove',
        data: [DataPoint(x: 0, y: 20)],
      ),
      SeriesConfig(
        id: 'series_to_keep',
        data: [DataPoint(x: 0, y: 10)],
      ),
      SeriesConfig(
        id: 'series_a',
        data: [DataPoint(x: 0, y: 10)],
      ),
      SeriesConfig(
        id: 'series_b',
        data: [DataPoint(x: 0, y: 20)],
      ),
      SeriesConfig(
        id: 'series_c',
        data: [DataPoint(x: 0, y: 30)],
      ),
      SeriesConfig(
        id: 'preserved_series',
        data: [DataPoint(x: 0, y: 100)],
      ),
      SeriesConfig(
        id: 'line_series',
        data: [DataPoint(x: 0, y: 10)],
      ),
      SeriesConfig(
        id: 'titled_series',
        data: [DataPoint(x: 0, y: 10)],
      ),
      SeriesConfig(
        id: 'original_series',
        data: [DataPoint(x: 0, y: 50)],
      ),
    ],
    showGrid: true,
    showLegend: true,
    legendPosition: LegendPosition.bottom,
    useDarkTheme: false,
    normalizationMode: NormalizationModeConfig.none,
  );
}

/// Creates a chart configuration with annotations for testing.
ChartConfiguration _createChartWithAnnotations() {
  return const ChartConfiguration(
    id: 'test-chart-with-annotations',
    title: 'Chart With Annotations',
    series: [
      SeriesConfig(
        id: 'main-series',
        data: [
          DataPoint(x: 0, y: 100),
          DataPoint(x: 1, y: 150),
        ],
      ),
    ],
    annotations: [
      AnnotationConfig(
        id: 'ann-001',
        type: AnnotationType.referenceLine,
        orientation: Orientation.horizontal,
        value: 100.0,
        label: 'Original Label',
      ),
      AnnotationConfig(
        id: 'ann-002',
        type: AnnotationType.referenceLine,
        orientation: Orientation.vertical,
        value: 0.5,
        label: 'Second Annotation',
      ),
    ],
  );
}

/// Creates a chart configuration with series that has yAxis config for testing.
ChartConfiguration _createChartWithYAxis() {
  return const ChartConfiguration(
    id: 'test-chart-with-yaxis',
    title: 'Chart With YAxis',
    series: [
      SeriesConfig(
        id: 'series-with-yaxis',
        data: [
          DataPoint(x: 0, y: 200),
          DataPoint(x: 1, y: 250),
        ],
        yAxis: YAxisConfig(
          label: 'Power',
          unit: 'W',
          position: AxisPosition.left,
        ),
      ),
    ],
  );
}
