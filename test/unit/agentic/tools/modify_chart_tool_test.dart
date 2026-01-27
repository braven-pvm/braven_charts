import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/modify_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/services/data_store.dart';

void main() {
  group('ModifyChartTool', () {
    late DataStore<ChartConfiguration> dataStore;
    late String testChartId;

    setUp(() {
      dataStore = DataStore<ChartConfiguration>();
      // Create a test chart with an ID and store it
      testChartId = 'test-chart-id';
      final testChart = ChartConfiguration(
        id: testChartId,
        type: ChartType.line,
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [
              {'x': 0, 'y': 100},
              {'x': 1, 'y': 200},
            ],
          ),
        ],
      );
      dataStore.store(testChart, id: testChartId);
    });

    test('exposes name, description, and input schema', () {
      final LLMTool tool = ModifyChartTool();

      expect(tool.name, isNotEmpty);
      expect(tool.description, isNotEmpty);
      expect(tool.inputSchema, isNotEmpty);
      expect(tool.inputSchema['type'], equals('object'));
      expect(tool.inputSchema['properties'], isA<Map>());
      expect(tool.inputSchema['required'], contains('chartId'));
    });

    test('modifies visual properties of existing chart', () async {
      final tool = ModifyChartTool(dataStore: dataStore);

      final config = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'color': '#FF0000',
          'lineWidth': 3.0,
          'dashPattern': [5, 3],
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect(config.series.first.color, equals('#FF0000'));
      expect(config.series.first.lineWidth, equals(3.0));
      expect(config.series.first.dashPattern, equals([5, 3]));
    });

    test('updates axis properties without recreating chart', () async {
      final tool = ModifyChartTool(dataStore: dataStore);

      final config = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'xAxis': {
            'label': 'Time (seconds)',
            'min': 0,
            'max': 3600,
          },
          'yAxis': {
            'label': 'Power (W)',
            'min': 0,
            'max': 500,
          },
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect(config.xAxis?.label, equals('Time (seconds)'));
      expect(config.xAxis?.min, equals(0));
      expect(config.xAxis?.max, equals(3600));
      expect(config.yAxes.first.label, equals('Power (W)'));
    });

    test('modifies legend and grid visibility', () async {
      final tool = ModifyChartTool(dataStore: dataStore);

      final config = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'legend': {'visible': false},
          'grid': {'visible': false},
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect((config.legend as Map)['visible'], isFalse);
      expect((config.grid as Map)['visible'], isFalse);
    });

    test('applies theme changes to existing chart', () async {
      final tool = ModifyChartTool(dataStore: dataStore);

      final config = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'theme': 'dark',
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect(config.theme, equals('dark'));
    });

    test('validates required chartId parameter', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      expect(
        () => tool.execute({
          'properties': {'color': '#FF0000'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates property names', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      expect(
        () => tool.execute({
          'chartId': testChartId,
          'properties': {
            'invalidProperty': 'value',
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns updated chart with same chartId', () async {
      final tool = ModifyChartTool(dataStore: dataStore);

      final config = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'color': '#00FF00',
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect(config.id, equals(testChartId));
    });

    group('chart type changes', () {
      test('inputSchema includes type property with all chart type enums', () {
        final tool = ModifyChartTool();
        final schema = tool.inputSchema;
        final propsSchema = schema['properties']['properties']['properties']
            as Map<String, dynamic>;

        expect(propsSchema.containsKey('type'), isTrue);
        expect(propsSchema['type']['enum'],
            containsAll(['line', 'area', 'bar', 'scatter']));
      });

      test('can change chart type from line to area', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'type': 'area',
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.type, equals(ChartType.area));
      });

      test('can change chart type from line to bar', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'type': 'bar',
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.type, equals(ChartType.bar));
      });

      test('can change chart type from line to scatter', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'type': 'scatter',
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.type, equals(ChartType.scatter));
      });
    });

    group('interactions property', () {
      test(
          'inputSchema includes interactions with pan, zoom, crosshair, tooltip',
          () {
        final tool = ModifyChartTool();
        final schema = tool.inputSchema;
        final propsSchema = schema['properties']['properties']['properties']
            as Map<String, dynamic>;

        expect(propsSchema.containsKey('interactions'), isTrue);
        final interactionsProps =
            propsSchema['interactions']['properties'] as Map<String, dynamic>;
        expect(interactionsProps.containsKey('pan'), isTrue);
        expect(interactionsProps.containsKey('zoom'), isTrue);
        expect(interactionsProps.containsKey('crosshair'), isTrue);
        expect(interactionsProps.containsKey('tooltip'), isTrue);
      });

      test('applies interactions settings', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'interactions': {
              'pan': true,
              'zoom': true,
              'crosshair': true,
              'tooltip': true,
            },
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.interactions, isNotNull);
        final interactions = config.interactions as Map<String, dynamic>;
        expect(interactions['pan'], isTrue);
        expect(interactions['zoom'], isTrue);
        expect(interactions['crosshair'], isTrue);
        expect(interactions['tooltip'], isTrue);
      });
    });

    group('series styling modifications', () {
      test('applies fillOpacity when specified', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'fillOpacity': 0.3,
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.fillOpacity, equals(0.3));
      });

      test('applies markerStyle and markerSize when specified', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'markerStyle': 'diamond',
            'markerSize': 12.0,
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.markerStyle, equals(MarkerStyle.diamond));
        expect(config.series.first.markerSize, equals(12.0));
      });

      test('applies interpolation and tension when specified', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'interpolation': 'bezier',
            'tension': 0.5,
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.interpolation, equals(Interpolation.bezier));
        expect(config.series.first.tension, equals(0.5));
      });

      test('applies showPoints when specified', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'showPoints': true,
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.showPoints, isTrue);
      });
    });

    group('axisVisibility property', () {
      test('inputSchema includes axisVisibility', () {
        final tool = ModifyChartTool();
        final schema = tool.inputSchema;
        final propsSchema = schema['properties']['properties']['properties']
            as Map<String, dynamic>;

        expect(propsSchema.containsKey('axisVisibility'), isTrue);
      });

      test('applies axisVisibility for xAxis', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'axisVisibility': {
              'xAxis': false,
            },
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.xAxis?.showAxisLine, isFalse);
      });
    });

    group('tickFormatting property', () {
      test('inputSchema includes tickFormatting', () {
        final tool = ModifyChartTool();
        final schema = tool.inputSchema;
        final propsSchema = schema['properties']['properties']['properties']
            as Map<String, dynamic>;

        expect(propsSchema.containsKey('tickFormatting'), isTrue);
      });

      test('applies tickFormatting for xAxis', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'tickFormatting': {
              'xAxis': '%H:%M',
            },
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.xAxis?.tickFormat, equals('%H:%M'));
      });
    });

    group('backgroundColor and padding', () {
      test('inputSchema includes backgroundColor and padding', () {
        final tool = ModifyChartTool();
        final schema = tool.inputSchema;
        final propsSchema = schema['properties']['properties']['properties']
            as Map<String, dynamic>;

        expect(propsSchema.containsKey('backgroundColor'), isTrue);
        expect(propsSchema.containsKey('padding'), isTrue);
      });

      test('applies backgroundColor', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'backgroundColor': '#F0F0F0',
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.style?.backgroundColor, equals('#F0F0F0'));
      });

      test('applies padding', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'padding': {
              'top': 10.0,
              'bottom': 20.0,
              'left': 15.0,
              'right': 25.0,
            },
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.style, isNotNull);
        final plotArea = config.style!.plotArea as Map<String, dynamic>;
        expect(plotArea['paddingTop'], equals(10.0));
        expect(plotArea['paddingBottom'], equals(20.0));
        expect(plotArea['paddingLeft'], equals(15.0));
        expect(plotArea['paddingRight'], equals(25.0));
      });
    });

    group('validProperties set', () {
      test('accepts all new FR-004 properties', () async {
        final tool = ModifyChartTool(dataStore: dataStore);

        // This should not throw - all properties should be valid
        final config = await tool.execute({
          'chartId': testChartId,
          'properties': {
            'type': 'area',
            'interactions': {'pan': true},
            'fillOpacity': 0.5,
            'markerStyle': 'circle',
            'markerSize': 6.0,
            'interpolation': 'linear',
            'showPoints': true,
            'tension': 0.3,
            'backgroundColor': '#FFFFFF',
            'axisVisibility': {'xAxis': true},
            'tickFormatting': {'xAxis': '%Y'},
            'padding': {'top': 5.0},
          },
        });

        expect(config, isA<ChartConfiguration>());
      });
    });
  });
}
