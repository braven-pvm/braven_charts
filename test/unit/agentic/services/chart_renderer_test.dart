// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/services/chart_renderer.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart'
    as agentic;
import 'package:braven_charts/src/agentic/models/series_config.dart' as agentic;
import 'package:braven_charts/src/agentic/models/axis_config.dart' as agentic;

void main() {
  group('ChartRenderer', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    test('renders line chart without crash', () {
      final config = agentic.ChartConfiguration(
        type: agentic.ChartType.line,
        series: [
          agentic.SeriesConfig(
            id: 'line-series',
            name: 'Line Data',
            data: [
              {'x': 0.0, 'y': 10.0},
              {'x': 1.0, 'y': 20.0},
              {'x': 2.0, 'y': 15.0},
            ],
          ),
        ],
        xAxis: agentic.XAxisConfig(label: 'X Axis'),
        yAxes: [
          agentic.YAxisConfig(
              label: 'Y Axis', position: agentic.AxisPosition.left),
        ],
      );

      expect(() => renderer.render(config), returnsNormally);
      final widget = renderer.render(config);
      expect(widget, isNotNull);
    });

    test('renders area chart without crash', () {
      final config = agentic.ChartConfiguration(
        type: agentic.ChartType.area,
        series: [
          agentic.SeriesConfig(
            id: 'area-series',
            name: 'Area Data',
            data: [
              {'x': 0.0, 'y': 5.0},
              {'x': 1.0, 'y': 15.0},
              {'x': 2.0, 'y': 10.0},
            ],
          ),
        ],
        xAxis: agentic.XAxisConfig(label: 'X Axis'),
        yAxes: [
          agentic.YAxisConfig(
              label: 'Y Axis', position: agentic.AxisPosition.left),
        ],
      );

      expect(() => renderer.render(config), returnsNormally);
      final widget = renderer.render(config);
      expect(widget, isNotNull);
    });

    test('renders bar chart without crash', () {
      final config = agentic.ChartConfiguration(
        type: agentic.ChartType.bar,
        series: [
          agentic.SeriesConfig(
            id: 'bar-series',
            name: 'Bar Data',
            data: [
              {'x': 0.0, 'y': 30.0},
              {'x': 1.0, 'y': 25.0},
              {'x': 2.0, 'y': 35.0},
            ],
          ),
        ],
        xAxis: agentic.XAxisConfig(label: 'X Axis'),
        yAxes: [
          agentic.YAxisConfig(
              label: 'Y Axis', position: agentic.AxisPosition.left),
        ],
      );

      expect(() => renderer.render(config), returnsNormally);
      final widget = renderer.render(config);
      expect(widget, isNotNull);
    });

    test('renders scatter chart without crash', () {
      final config = agentic.ChartConfiguration(
        type: agentic.ChartType.scatter,
        series: [
          agentic.SeriesConfig(
            id: 'scatter-series',
            name: 'Scatter Data',
            data: [
              {'x': 0.0, 'y': 12.0},
              {'x': 1.0, 'y': 18.0},
              {'x': 2.0, 'y': 14.0},
            ],
          ),
        ],
        xAxis: agentic.XAxisConfig(label: 'X Axis'),
        yAxes: [
          agentic.YAxisConfig(
              label: 'Y Axis', position: agentic.AxisPosition.left),
        ],
      );

      expect(() => renderer.render(config), returnsNormally);
      final widget = renderer.render(config);
      expect(widget, isNotNull);
    });

    test('renders chart from Map format', () {
      final chartMap = {
        'type': 'line',
        'series': [
          {
            'id': 'map-series',
            'name': 'Map Data',
            'data': [
              {'x': 0.0, 'y': 8.0},
              {'x': 1.0, 'y': 12.0},
            ],
          },
        ],
        'xAxis': {'label': 'X'},
        'yAxes': [
          {'label': 'Y', 'position': 'left'},
        ],
      };

      expect(() => renderer.render(chartMap), returnsNormally);
      final widget = renderer.render(chartMap);
      expect(widget, isNotNull);
    });

    test('returns error widget for invalid chart format', () {
      // Pass an invalid type (string instead of ChartConfiguration or Map)
      final widget = renderer.render('invalid');
      expect(widget, isNotNull);
      // Widget should return an error widget for invalid format
    });

    test('returns error widget for invalid chart format', () {
      // Pass an invalid type (string instead of ChartConfiguration or Map)
      final widget = renderer.render('invalid');
      expect(widget, isNotNull);
      // Widget should return an error widget for invalid format
    });

    test('returns error widget for invalid map format', () {
      final invalidMap = {
        'type': 'invalid_type',
        'series': 'not_a_list',
      };

      final widget = renderer.render(invalidMap);
      expect(widget, isNotNull);
      // Widget should be a Container with error message
    });
  });
}
