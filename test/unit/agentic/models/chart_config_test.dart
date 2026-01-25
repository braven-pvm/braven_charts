// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/models.dart';

void main() {
  group('ChartType', () {
    test('has all required enum values', () {
      expect(ChartType.values.contains(ChartType.line), isTrue);
      expect(ChartType.values.contains(ChartType.area), isTrue);
      expect(ChartType.values.contains(ChartType.bar), isTrue);
      expect(ChartType.values.contains(ChartType.scatter), isTrue);
    });

    test('enum values serialize to string', () {
      expect(ChartType.line.toString(), contains('line'));
      expect(ChartType.area.toString(), contains('area'));
      expect(ChartType.bar.toString(), contains('bar'));
      expect(ChartType.scatter.toString(), contains('scatter'));
    });
  });

  group('ChartConfiguration', () {
    group('constructor', () {
      test('creates instance with valid parameters', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [
            SeriesConfig(
              id: 'series-1',
              name: 'Power',
              dataColumn: 'power',
              color: '#FF0000',
            ),
          ],
          yAxes: [
            YAxisConfig(
              id: 'y-axis-1',
              label: 'Power (W)',
              position: AxisPosition.left,
            ),
          ],
        );

        expect(config.type, equals(ChartType.line));
        expect(config.series.length, equals(1));
        expect(config.yAxes.length, equals(1));
        expect(config.title, isNull);
        expect(config.subtitle, isNull);
      });

      test('creates instance with title and subtitle', () {
        final config = ChartConfiguration(
          type: ChartType.bar,
          title: 'Training Analysis',
          subtitle: 'January 2026',
          series: [
            SeriesConfig(id: 's1', name: 'HR', dataColumn: 'hr'),
          ],
          yAxes: [
            YAxisConfig(id: 'y1', position: AxisPosition.left),
          ],
        );

        expect(config.title, equals('Training Analysis'));
        expect(config.subtitle, equals('January 2026'));
      });

      test('creates instance with multiple series', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [
            SeriesConfig(id: 's1', name: 'Power', dataColumn: 'power'),
            SeriesConfig(id: 's2', name: 'HR', dataColumn: 'heart_rate'),
            SeriesConfig(id: 's3', name: 'Cadence', dataColumn: 'cadence'),
          ],
          yAxes: [
            YAxisConfig(id: 'y1', position: AxisPosition.left),
          ],
        );

        expect(config.series.length, equals(3));
        expect(config.series[0].name, equals('Power'));
        expect(config.series[1].name, equals('HR'));
        expect(config.series[2].name, equals('Cadence'));
      });

      test('creates instance with multiple y-axes', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [
            SeriesConfig(
                id: 's1', name: 'Power', dataColumn: 'power', yAxisId: 'y1'),
            SeriesConfig(id: 's2', name: 'HR', dataColumn: 'hr', yAxisId: 'y2'),
          ],
          yAxes: [
            YAxisConfig(
                id: 'y1', label: 'Power (W)', position: AxisPosition.left),
            YAxisConfig(
                id: 'y2', label: 'HR (bpm)', position: AxisPosition.right),
          ],
        );

        expect(config.yAxes.length, equals(2));
        expect(config.yAxes[0].position, equals(AxisPosition.left));
        expect(config.yAxes[1].position, equals(AxisPosition.right));
      });

      test('throws assertion error when series list is empty', () {
        expect(
          () => ChartConfiguration(
            type: ChartType.line,
            series: [],
            yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
          ),
          throwsAssertionError,
        );
      });

      test('throws assertion error when more than 4 y-axes', () {
        expect(
          () => ChartConfiguration(
            type: ChartType.line,
            series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
            yAxes: [
              YAxisConfig(id: 'y1', position: AxisPosition.left),
              YAxisConfig(id: 'y2', position: AxisPosition.right),
              YAxisConfig(id: 'y3', position: AxisPosition.left),
              YAxisConfig(id: 'y4', position: AxisPosition.right),
              YAxisConfig(
                  id: 'y5', position: AxisPosition.left), // 5th axis - invalid
            ],
          ),
          throwsAssertionError,
        );
      });

      test('allows exactly 4 y-axes', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
          yAxes: [
            YAxisConfig(id: 'y1', position: AxisPosition.left),
            YAxisConfig(id: 'y2', position: AxisPosition.right),
            YAxisConfig(id: 'y3', position: AxisPosition.left),
            YAxisConfig(id: 'y4', position: AxisPosition.right),
          ],
        );

        expect(config.yAxes.length, equals(4));
      });

      test('creates instance with optional x-axis configuration', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [SeriesConfig(id: 's1', name: 'Power', dataColumn: 'power')],
          xAxis: XAxisConfig(
            label: 'Time',
            type: AxisType.time,
          ),
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
        );

        expect(config.xAxis, isNotNull);
        expect(config.xAxis?.label, equals('Time'));
        expect(config.xAxis?.type, equals(AxisType.time));
      });

      test('creates instance with style configuration', () {
        final config = ChartConfiguration(
          type: ChartType.area,
          series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
          style: ChartStyleConfig(
            backgroundColor: '#FFFFFF',
            fontFamily: 'Arial',
          ),
        );

        expect(config.style, isNotNull);
        expect(config.style?.backgroundColor, equals('#FFFFFF'));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final config = ChartConfiguration(
          type: ChartType.line,
          title: 'Test Chart',
          series: [
            SeriesConfig(id: 's1', name: 'Power', dataColumn: 'power'),
          ],
          yAxes: [
            YAxisConfig(id: 'y1', position: AxisPosition.left),
          ],
        );

        final json = config.toJson();

        expect(json['type'], equals('line'));
        expect(json['title'], equals('Test Chart'));
        expect(json['series'], isA<List>());
        expect(json['yAxes'], isA<List>());
      });

      test('fromJson creates instance from map', () {
        final json = {
          'type': 'bar',
          'title': 'Sales Data',
          'series': [
            {'id': 's1', 'name': 'Q1', 'dataColumn': 'q1_sales'},
          ],
          'yAxes': [
            {'id': 'y1', 'position': 'left'},
          ],
        };

        final config = ChartConfiguration.fromJson(json);

        expect(config.type, equals(ChartType.bar));
        expect(config.title, equals('Sales Data'));
        expect(config.series.length, equals(1));
      });

      test('JSON round-trip preserves data', () {
        final original = ChartConfiguration(
          type: ChartType.scatter,
          title: 'Power vs HR',
          subtitle: 'Training Zone Analysis',
          series: [
            SeriesConfig(
              id: 's1',
              name: 'Zone 2',
              dataColumn: 'power',
              color: '#00FF00',
            ),
          ],
          yAxes: [
            YAxisConfig(
              id: 'y1',
              label: 'Power (W)',
              position: AxisPosition.left,
              min: 0,
              max: 400,
            ),
          ],
        );

        final json = original.toJson();
        final restored = ChartConfiguration.fromJson(json);

        expect(restored.type, equals(original.type));
        expect(restored.title, equals(original.title));
        expect(restored.subtitle, equals(original.subtitle));
        expect(restored.series.length, equals(original.series.length));
        expect(restored.yAxes.length, equals(original.yAxes.length));
      });
    });

    group('copyWith', () {
      test('creates copy with updated title', () {
        final original = ChartConfiguration(
          type: ChartType.line,
          title: 'Original Title',
          series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
        );

        final copy = original.copyWith(title: 'New Title');

        expect(copy.title, equals('New Title'));
        expect(original.title, equals('Original Title'));
      });

      test('creates copy with added series', () {
        final original = ChartConfiguration(
          type: ChartType.line,
          series: [
            SeriesConfig(id: 's1', name: 'Series 1', dataColumn: 'col1')
          ],
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
        );

        final copy = original.copyWith(
          series: [
            SeriesConfig(id: 's1', name: 'Series 1', dataColumn: 'col1'),
            SeriesConfig(id: 's2', name: 'Series 2', dataColumn: 'col2'),
          ],
        );

        expect(copy.series.length, equals(2));
        expect(original.series.length, equals(1));
      });
    });

    group('equality', () {
      test('equal configurations have same hash code', () {
        final config1 = ChartConfiguration(
          type: ChartType.line,
          title: 'Test',
          series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
        );

        final config2 = ChartConfiguration(
          type: ChartType.line,
          title: 'Test',
          series: [SeriesConfig(id: 's1', name: 'Data', dataColumn: 'col')],
          yAxes: [YAxisConfig(id: 'y1', position: AxisPosition.left)],
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });
  });

  group('SeriesConfig', () {
    group('constructor', () {
      test('creates instance with required parameters', () {
        final series = SeriesConfig(
          id: 'series-1',
          name: 'Power',
          dataColumn: 'power',
        );

        expect(series.id, equals('series-1'));
        expect(series.name, equals('Power'));
        expect(series.dataColumn, equals('power'));
        expect(series.visible, isTrue);
        expect(series.legendVisible, isTrue);
      });

      test('creates instance with styling options', () {
        final series = SeriesConfig(
          id: 's1',
          name: 'HR',
          dataColumn: 'heart_rate',
          color: '#FF0000',
          strokeWidth: 2.5,
          strokeDash: [5.0, 3.0],
          fillOpacity: 0.3,
        );

        expect(series.color, equals('#FF0000'));
        expect(series.strokeWidth, equals(2.5));
        expect(series.strokeDash, equals([5.0, 3.0]));
        expect(series.fillOpacity, equals(0.3));
      });

      test('creates instance with marker configuration', () {
        final series = SeriesConfig(
          id: 's1',
          name: 'Data',
          dataColumn: 'value',
          markerStyle: MarkerStyle.circle,
          markerSize: 8.0,
          showPoints: true,
        );

        expect(series.markerStyle, equals(MarkerStyle.circle));
        expect(series.markerSize, equals(8.0));
        expect(series.showPoints, isTrue);
      });

      test('creates instance with interpolation setting', () {
        final series = SeriesConfig(
          id: 's1',
          name: 'Data',
          dataColumn: 'value',
          interpolation: Interpolation.bezier,
        );

        expect(series.interpolation, equals(Interpolation.bezier));
      });

      test('creates instance with y-axis binding', () {
        final series = SeriesConfig(
          id: 's1',
          name: 'Power',
          dataColumn: 'power',
          yAxisId: 'y-axis-1',
          unit: 'W',
        );

        expect(series.yAxisId, equals('y-axis-1'));
        expect(series.unit, equals('W'));
      });

      test('throws assertion error when id is empty', () {
        expect(
          () => SeriesConfig(
            id: '',
            name: 'Data',
            dataColumn: 'col',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final series = SeriesConfig(
          id: 's1',
          name: 'Power',
          dataColumn: 'power',
          color: '#FF0000',
          visible: true,
        );

        final json = series.toJson();

        expect(json['id'], equals('s1'));
        expect(json['name'], equals('Power'));
        expect(json['dataColumn'], equals('power'));
        expect(json['color'], equals('#FF0000'));
      });

      test('fromJson creates instance from map', () {
        final json = {
          'id': 's1',
          'name': 'HR',
          'dataColumn': 'heart_rate',
          'color': '#00FF00',
        };

        final series = SeriesConfig.fromJson(json);

        expect(series.id, equals('s1'));
        expect(series.name, equals('HR'));
        expect(series.color, equals('#00FF00'));
      });

      test('JSON round-trip preserves data', () {
        final original = SeriesConfig(
          id: 's-round-trip',
          name: 'Cadence',
          dataColumn: 'cadence',
          color: '#0000FF',
          strokeWidth: 3.0,
          interpolation: Interpolation.monotone,
          markerStyle: MarkerStyle.diamond,
          markerSize: 6.0,
        );

        final json = original.toJson();
        final restored = SeriesConfig.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.dataColumn, equals(original.dataColumn));
        expect(restored.color, equals(original.color));
        expect(restored.strokeWidth, equals(original.strokeWidth));
      });
    });

    group('copyWith', () {
      test('creates copy with updated color', () {
        final original = SeriesConfig(
          id: 's1',
          name: 'Data',
          dataColumn: 'col',
          color: '#FF0000',
        );

        final copy = original.copyWith(color: '#00FF00');

        expect(copy.color, equals('#00FF00'));
        expect(original.color, equals('#FF0000'));
      });

      test('creates copy with updated visibility', () {
        final original = SeriesConfig(
          id: 's1',
          name: 'Data',
          dataColumn: 'col',
          visible: true,
        );

        final copy = original.copyWith(visible: false);

        expect(copy.visible, isFalse);
        expect(original.visible, isTrue);
      });
    });
  });

  group('MarkerStyle', () {
    test('has all required enum values', () {
      expect(MarkerStyle.values.contains(MarkerStyle.none), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.circle), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.square), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.triangle), isTrue);
      expect(MarkerStyle.values.contains(MarkerStyle.diamond), isTrue);
    });
  });

  group('Interpolation', () {
    test('has all required enum values', () {
      expect(Interpolation.values.contains(Interpolation.linear), isTrue);
      expect(Interpolation.values.contains(Interpolation.bezier), isTrue);
      expect(Interpolation.values.contains(Interpolation.stepped), isTrue);
      expect(Interpolation.values.contains(Interpolation.monotone), isTrue);
    });
  });
}
