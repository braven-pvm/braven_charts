import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/create_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';

void main() {
  group('CreateChartTool', () {
    test('exposes name, description, and input schema', () {
      final LLMTool tool = CreateChartTool();

      expect(tool.name, isNotEmpty);
      expect(tool.description, isNotEmpty);
      expect(tool.inputSchema, isNotEmpty);
      expect(tool.inputSchema['type'], equals('object'));
      expect(tool.inputSchema['properties'], isA<Map>());
    });

    test('converts natural language into a ChartConfiguration', () async {
      final tool = CreateChartTool();

      final config = await tool.execute({
        'prompt': 'Show me a line chart of power over time',
        'dataset': {
          'columns': ['time', 'power'],
          'rows': [
            {'time': 0, 'power': 120},
            {'time': 1, 'power': 140},
          ],
        },
      });

      expect(config, isA<ChartConfiguration>());
      expect(config.type, ChartType.line);
      expect(config.series, isNotEmpty);
      expect(config.xAxis, isNotNull);
      expect(config.yAxes, isNotEmpty);
    });

    test('returns an error for unsupported chart types', () async {
      final CreateChartTool tool = CreateChartTool();

      expect(
        () => tool.execute({
          'prompt': 'Create a waterfall chart of power over time',
          'dataset': {
            'columns': ['time', 'power'],
            'rows': [
              {'time': 0, 'power': 120},
            ],
          },
        }),
        throwsA(isA<Exception>()),
      );
    });

    group('series styling properties', () {
      test('inputSchema includes fillOpacity, markerStyle, markerSize, interpolation, showPoints, tension', () {
        final tool = CreateChartTool();
        final schema = tool.inputSchema;
        final seriesItems = schema['properties']['series']['items']['properties'] as Map<String, dynamic>;

        expect(seriesItems.containsKey('fillOpacity'), isTrue);
        expect(seriesItems['fillOpacity']['type'], equals('number'));
        expect(seriesItems['fillOpacity']['minimum'], equals(0));
        expect(seriesItems['fillOpacity']['maximum'], equals(1));

        expect(seriesItems.containsKey('markerStyle'), isTrue);
        expect(seriesItems['markerStyle']['enum'], containsAll(['none', 'circle', 'square', 'triangle', 'diamond']));

        expect(seriesItems.containsKey('markerSize'), isTrue);
        expect(seriesItems['markerSize']['type'], equals('number'));
        expect(seriesItems['markerSize']['minimum'], equals(0));

        expect(seriesItems.containsKey('interpolation'), isTrue);
        expect(seriesItems['interpolation']['enum'], containsAll(['linear', 'bezier', 'stepped', 'monotone']));

        expect(seriesItems.containsKey('showPoints'), isTrue);
        expect(seriesItems['showPoints']['type'], equals('boolean'));

        expect(seriesItems.containsKey('tension'), isTrue);
        expect(seriesItems['tension']['type'], equals('number'));
      });

      test('applies markerStyle and markerSize when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'name': 'Test',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
              'markerStyle': 'circle',
              'markerSize': 8.0,
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.markerStyle, equals(MarkerStyle.circle));
        expect(config.series.first.markerSize, equals(8.0));
      });

      test('applies fillOpacity when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me an area chart',
          'type': 'area',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
              'fillOpacity': 0.3,
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.fillOpacity, equals(0.3));
      });

      test('applies interpolation and showPoints when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
              'interpolation': 'bezier',
              'showPoints': true,
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.interpolation, equals(Interpolation.bezier));
        expect(config.series.first.showPoints, isTrue);
      });

      test('applies tension for line/area charts', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
              'tension': 0.4,
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.tension, equals(0.4));
      });
    });

    group('style configuration', () {
      test('inputSchema includes style with backgroundColor and padding properties', () {
        final tool = CreateChartTool();
        final schema = tool.inputSchema;

        expect(schema['properties'].containsKey('style'), isTrue);
        final styleProps = schema['properties']['style']['properties'] as Map<String, dynamic>;

        expect(styleProps.containsKey('backgroundColor'), isTrue);
        expect(styleProps.containsKey('paddingTop'), isTrue);
        expect(styleProps.containsKey('paddingBottom'), isTrue);
        expect(styleProps.containsKey('paddingLeft'), isTrue);
        expect(styleProps.containsKey('paddingRight'), isTrue);
      });

      test('applies backgroundColor via style configuration', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
            },
          ],
          'style': {
            'backgroundColor': '#FFFFFF',
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.style, isNotNull);
        expect(config.style!.backgroundColor, equals('#FFFFFF'));
      });

      test('applies padding via style configuration', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
            },
          ],
          'style': {
            'paddingTop': 10.0,
            'paddingBottom': 15.0,
            'paddingLeft': 20.0,
            'paddingRight': 25.0,
          },
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.style, isNotNull);
        expect(config.style!.plotArea, isNotNull);
        final plotArea = config.style!.plotArea as Map<String, dynamic>;
        expect(plotArea['paddingTop'], equals(10.0));
        expect(plotArea['paddingBottom'], equals(15.0));
        expect(plotArea['paddingLeft'], equals(20.0));
        expect(plotArea['paddingRight'], equals(25.0));
      });
    });

    group('per-series Y-axis configuration', () {
      test('inputSchema includes yAxisPosition, yAxisLabel, yAxisUnit, yAxisColor', () {
        final tool = CreateChartTool();
        final schema = tool.inputSchema;
        final seriesItems = schema['properties']['series']['items']['properties'] as Map<String, dynamic>;

        expect(seriesItems.containsKey('yAxisPosition'), isTrue);
        expect(seriesItems['yAxisPosition']['enum'], equals(['left', 'right', 'leftOuter', 'rightOuter']));

        expect(seriesItems.containsKey('yAxisLabel'), isTrue);
        expect(seriesItems['yAxisLabel']['type'], equals('string'));

        expect(seriesItems.containsKey('yAxisUnit'), isTrue);
        expect(seriesItems['yAxisUnit']['type'], equals('string'));

        expect(seriesItems.containsKey('yAxisColor'), isTrue);
        expect(seriesItems['yAxisColor']['type'], equals('string'));
      });

      test('applies yAxisPosition when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a multi-axis chart',
          'type': 'line',
          'series': [
            {
              'id': 'power-series',
              'name': 'Power',
              'data': [
                {'x': 0, 'y': 100},
                {'x': 1, 'y': 200},
              ],
              'yAxisPosition': 'left',
            },
            {
              'id': 'hr-series',
              'name': 'Heart Rate',
              'data': [
                {'x': 0, 'y': 120},
                {'x': 1, 'y': 140},
              ],
              'yAxisPosition': 'right',
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.length, equals(2));
        expect(config.series[0].yAxisPosition, equals('left'));
        expect(config.series[1].yAxisPosition, equals('right'));
      });

      test('applies yAxisLabel and yAxisUnit when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a chart with power and heart rate',
          'type': 'line',
          'series': [
            {
              'id': 'power-series',
              'data': [
                {'x': 0, 'y': 250},
                {'x': 1, 'y': 300},
              ],
              'yAxisPosition': 'left',
              'yAxisLabel': 'Power',
              'yAxisUnit': 'W',
            },
            {
              'id': 'hr-series',
              'data': [
                {'x': 0, 'y': 130},
                {'x': 1, 'y': 145},
              ],
              'yAxisPosition': 'right',
              'yAxisLabel': 'Heart Rate',
              'yAxisUnit': 'bpm',
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series[0].yAxisLabel, equals('Power'));
        expect(config.series[0].yAxisUnit, equals('W'));
        expect(config.series[1].yAxisLabel, equals('Heart Rate'));
        expect(config.series[1].yAxisUnit, equals('bpm'));
      });

      test('applies yAxisColor when specified', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me a line chart',
          'series': [
            {
              'id': 'test-series',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
              ],
              'yAxisPosition': 'left',
              'yAxisColor': '#0000FF',
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.first.yAxisColor, equals('#0000FF'));
      });

      test('creates multi-axis chart with left and right positioning', () async {
        final tool = CreateChartTool();

        final config = await tool.execute({
          'prompt': 'Show me power and heart rate overlay',
          'type': 'line',
          'normalizationMode': 'perSeries',
          'series': [
            {
              'id': 'power',
              'name': 'Power',
              'data': [
                {'x': 0, 'y': 150},
                {'x': 1, 'y': 200},
                {'x': 2, 'y': 180},
              ],
              'color': '#2196F3',
              'yAxisPosition': 'left',
              'yAxisLabel': 'Power',
              'yAxisUnit': 'W',
              'yAxisColor': '#2196F3',
            },
            {
              'id': 'heartRate',
              'name': 'Heart Rate',
              'data': [
                {'x': 0, 'y': 120},
                {'x': 1, 'y': 145},
                {'x': 2, 'y': 135},
              ],
              'color': '#FF0000',
              'yAxisPosition': 'right',
              'yAxisLabel': 'Heart Rate',
              'yAxisUnit': 'bpm',
              'yAxisColor': '#FF0000',
            },
          ],
        });

        expect(config, isA<ChartConfiguration>());
        expect(config.series.length, equals(2));

        // Verify power series Y-axis config
        final powerSeries = config.series[0];
        expect(powerSeries.id, equals('power'));
        expect(powerSeries.yAxisPosition, equals('left'));
        expect(powerSeries.yAxisLabel, equals('Power'));
        expect(powerSeries.yAxisUnit, equals('W'));
        expect(powerSeries.yAxisColor, equals('#2196F3'));

        // Verify heart rate series Y-axis config
        final hrSeries = config.series[1];
        expect(hrSeries.id, equals('heartRate'));
        expect(hrSeries.yAxisPosition, equals('right'));
        expect(hrSeries.yAxisLabel, equals('Heart Rate'));
        expect(hrSeries.yAxisUnit, equals('bpm'));
        expect(hrSeries.yAxisColor, equals('#FF0000'));
      });
    });
  });
}
