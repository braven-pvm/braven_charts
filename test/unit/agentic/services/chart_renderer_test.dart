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

    group('per-series Y-axis configuration', () {
      test('renders chart with per-series yAxisConfig', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'power-series',
              name: 'Power',
              data: [
                {'x': 0.0, 'y': 150.0},
                {'x': 1.0, 'y': 200.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Power',
                unit: 'W',
                color: '#2196F3',
                position: agentic.AxisPosition.left,
              ),
            ),
            agentic.SeriesConfig(
              id: 'hr-series',
              name: 'Heart Rate',
              data: [
                {'x': 0.0, 'y': 120.0},
                {'x': 1.0, 'y': 140.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Heart Rate',
                unit: 'bpm',
                color: '#FF0000',
                position: agentic.AxisPosition.right,
              ),
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'Time'),
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders line chart with yAxisPosition left', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'test-series',
              name: 'Test',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Left Axis',
                position: agentic.AxisPosition.left,
              ),
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
        );

        expect(() => renderer.render(config), returnsNormally);
      });

      test('renders area chart with yAxisPosition right', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.area,
          series: [
            agentic.SeriesConfig(
              id: 'test-series',
              name: 'Test',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Right Axis',
                unit: 'units',
                position: agentic.AxisPosition.right,
              ),
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
        );

        expect(() => renderer.render(config), returnsNormally);
      });

      test('renders bar chart with yAxisConfig', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.bar,
          series: [
            agentic.SeriesConfig(
              id: 'bar-series',
              name: 'Sales',
              data: [
                {'x': 0.0, 'y': 100.0},
                {'x': 1.0, 'y': 150.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Sales',
                unit: 'USD',
                color: '#4CAF50',
                position: agentic.AxisPosition.left,
              ),
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'Quarter'),
        );

        expect(() => renderer.render(config), returnsNormally);
      });

      test('renders scatter chart with yAxisConfig', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.scatter,
          series: [
            agentic.SeriesConfig(
              id: 'scatter-series',
              name: 'Data Points',
              data: [
                {'x': 0.0, 'y': 5.0},
                {'x': 1.0, 'y': 10.0},
              ],
              // Per FR-001: use nested yAxisConfig
              yAxisConfig: agentic.YAxisConfig(
                label: 'Values',
                position: agentic.AxisPosition.right,
              ),
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
        );

        expect(() => renderer.render(config), returnsNormally);
      });

      test('renders chart without yAxisConfig (uses defaults)', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'no-yaxis-config',
              name: 'Default Series',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              // No yAxisConfig set - uses default
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });
    });

    group('series property mappings', () {
      test('renders area chart with fillOpacity', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.area,
          series: [
            agentic.SeriesConfig(
              id: 'area-series',
              name: 'Area Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              fillOpacity: 0.5,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders line chart with tension', () {
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
              tension: 0.5,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders area chart with tension', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.area,
          series: [
            agentic.SeriesConfig(
              id: 'area-series',
              name: 'Area Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              tension: 0.8,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders scatter chart with markerRadius', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.scatter,
          series: [
            agentic.SeriesConfig(
              id: 'scatter-series',
              name: 'Scatter Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              markerRadius: 8.0,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders line chart with showPoints (showDataPointMarkers)', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              showPoints: true,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders area chart with showPoints (showDataPointMarkers)', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.area,
          series: [
            agentic.SeriesConfig(
              id: 'area-series',
              name: 'Area Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              showPoints: true,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders line chart with all series properties', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'complete-series',
              name: 'Complete Line',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
                {'x': 2.0, 'y': 15.0},
              ],
              color: '#FF5722',
              strokeWidth: 3.0,
              tension: 0.4,
              showPoints: true,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders area chart with all series properties', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.area,
          series: [
            agentic.SeriesConfig(
              id: 'complete-area',
              name: 'Complete Area',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
              color: '#4CAF50',
              fillOpacity: 0.6,
              tension: 0.3,
              showPoints: true,
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });
    });

    group('interaction configuration mapping', () {
      test('renders chart with pan and zoom enabled', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          interactions: {'pan': true, 'zoom': true},
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders chart with crosshair enabled', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          interactions: {'crosshair': true},
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders chart with tooltip enabled', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          interactions: {'tooltip': true},
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders chart with all interaction features', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          interactions: {
            'pan': true,
            'zoom': true,
            'crosshair': true,
            'tooltip': true,
          },
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders chart with interactions disabled', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          interactions: {
            'pan': false,
            'zoom': false,
            'crosshair': false,
            'tooltip': false,
          },
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });

      test('renders chart without interactions (null)', () {
        final config = agentic.ChartConfiguration(
          type: agentic.ChartType.line,
          series: [
            agentic.SeriesConfig(
              id: 'line-series',
              name: 'Line Data',
              data: [
                {'x': 0.0, 'y': 10.0},
                {'x': 1.0, 'y': 20.0},
              ],
            ),
          ],
          xAxis: agentic.XAxisConfig(label: 'X'),
          yAxes: [
            agentic.YAxisConfig(
                label: 'Y', position: agentic.AxisPosition.left),
          ],
          // No interactions specified
        );

        expect(() => renderer.render(config), returnsNormally);
        final widget = renderer.render(config);
        expect(widget, isNotNull);
      });
    });
  });
}
