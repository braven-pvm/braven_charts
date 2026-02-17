import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Axis Bounds Computation', () {
    group('computeAxisBounds', () {
      test('computes bounds from single series', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [10.0, 20.0, 30.0, 40.0, 50.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power'], isNotNull);
        expect(bounds['power']!.min, equals(10.0));
        expect(bounds['power']!.max, equals(50.0));
      });

      test('computes bounds from multiple series on same axis', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
          const SeriesAxisBinding(seriesId: 'series2', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [10.0, 20.0, 30.0], // min=10, max=30
          'series2': [5.0, 25.0, 50.0], // min=5, max=50
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power'], isNotNull);
        expect(bounds['power']!.min, equals(5.0)); // min of all
        expect(bounds['power']!.max, equals(50.0)); // max of all
      });

      test('computes separate bounds for different axes', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
          YAxisConfig.withId(id: 'heartRate', position: YAxisPosition.right),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'powerSeries', yAxisId: 'power'),
          const SeriesAxisBinding(seriesId: 'hrSeries', yAxisId: 'heartRate'),
        ];
        final seriesYValues = {
          'powerSeries': [100.0, 200.0, 300.0], // power range
          'hrSeries': [60.0, 120.0, 180.0], // heart rate range
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power'], isNotNull);
        expect(bounds['power']!.min, equals(100.0));
        expect(bounds['power']!.max, equals(300.0));

        expect(bounds['heartRate'], isNotNull);
        expect(bounds['heartRate']!.min, equals(60.0));
        expect(bounds['heartRate']!.max, equals(180.0));
      });

      test('respects explicit min from YAxisConfig', () {
        final axisConfigs = [
          YAxisConfig.withId(
            id: 'power',
            position: YAxisPosition.left,
            min: 0.0,
          ),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [50.0, 100.0, 150.0], // data min=50, but config min=0
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(0.0)); // explicit min
        expect(bounds['power']!.max, equals(150.0)); // data-derived max
      });

      test('respects explicit max from YAxisConfig', () {
        final axisConfigs = [
          YAxisConfig.withId(
            id: 'power',
            position: YAxisPosition.left,
            max: 500.0,
          ),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [50.0, 100.0, 150.0], // data max=150, but config max=500
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(50.0)); // data-derived min
        expect(bounds['power']!.max, equals(500.0)); // explicit max
      });

      test('respects both explicit min and max from YAxisConfig', () {
        final axisConfigs = [
          YAxisConfig.withId(
            id: 'power',
            position: YAxisPosition.left,
            min: 0.0,
            max: 400.0,
          ),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [50.0, 100.0, 150.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(0.0)); // explicit min
        expect(bounds['power']!.max, equals(400.0)); // explicit max
      });

      test('uses data-derived bounds when config min/max are null', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [25.0, 75.0, 125.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(25.0)); // from data
        expect(bounds['power']!.max, equals(125.0)); // from data
      });

      test('handles mixed explicit and auto bounds across axes', () {
        final axisConfigs = [
          YAxisConfig.withId(
            id: 'power',
            position: YAxisPosition.left,
            min: 0.0,
          ), // explicit min only
          YAxisConfig.withId(
            id: 'heartRate',
            position: YAxisPosition.right,
            max: 200.0,
          ), // explicit max only
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'powerSeries', yAxisId: 'power'),
          const SeriesAxisBinding(seriesId: 'hrSeries', yAxisId: 'heartRate'),
        ];
        final seriesYValues = {
          'powerSeries': [100.0, 200.0, 300.0],
          'hrSeries': [60.0, 90.0, 120.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(0.0)); // explicit
        expect(bounds['power']!.max, equals(300.0)); // from data

        expect(bounds['heartRate']!.min, equals(60.0)); // from data
        expect(bounds['heartRate']!.max, equals(200.0)); // explicit
      });
    });

    group('series to axis mapping', () {
      test('maps series with yAxisId to correct axis', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'seriesA', yAxisId: 'axis1'),
          const SeriesAxisBinding(seriesId: 'seriesB', yAxisId: 'axis2'),
        ];
        final seriesYValues = {
          'seriesA': [10.0, 20.0],
          'seriesB': [100.0, 200.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['axis1']!.min, equals(10.0));
        expect(bounds['axis1']!.max, equals(20.0));
        expect(bounds['axis2']!.min, equals(100.0));
        expect(bounds['axis2']!.max, equals(200.0));
      });

      test('maps series without explicit binding to default axis', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'primary', position: YAxisPosition.left),
        ];
        // No explicit bindings - series should use default axis
        final bindings = <SeriesAxisBinding>[];
        final seriesYValues = {
          'unboundSeries': [5.0, 15.0, 25.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
          defaultAxisId: 'primary',
        );

        expect(bounds['primary'], isNotNull);
        expect(bounds['primary']!.min, equals(5.0));
        expect(bounds['primary']!.max, equals(25.0));
      });

      test('handles unmapped series (no matching axis)', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(
            seriesId: 'orphanSeries',
            yAxisId: 'nonexistent',
          ),
        ];
        final seriesYValues = {
          'orphanSeries': [10.0, 20.0],
        };

        // Should not throw, just ignore unmapped series
        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        // The orphan series doesn't contribute to 'power' axis
        // The 'power' axis exists but has no bound series data
        expect(bounds['power'], isNotNull);
      });

      test('uses custom default axis id', () {
        final axisConfigs = [
          YAxisConfig.withId(
            id: 'custom-default',
            position: YAxisPosition.left,
          ),
        ];
        final bindings = <SeriesAxisBinding>[];
        final seriesYValues = {
          'unboundSeries': [100.0, 200.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
          defaultAxisId: 'custom-default',
        );

        expect(bounds['custom-default']!.min, equals(100.0));
        expect(bounds['custom-default']!.max, equals(200.0));
      });
    });

    group('edge cases', () {
      test('handles empty series list', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = <SeriesAxisBinding>[];
        final seriesYValues = <String, List<double>>{};

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        // Axis exists but with default bounds (0,1) or similar
        expect(bounds['power'], isNotNull);
      });

      test('handles series with no data points', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'emptySeries', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'emptySeries': <double>[], // Empty list
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        // Should not crash, provide default bounds
        expect(bounds['power'], isNotNull);
      });

      test('handles series with identical Y values', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'flatSeries', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'flatSeries': [42.0, 42.0, 42.0, 42.0], // All same value
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(42.0));
        expect(bounds['power']!.max, equals(42.0));
      });

      test('handles negative values in series', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [-50.0, -25.0, 0.0, 25.0, 50.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(-50.0));
        expect(bounds['power']!.max, equals(50.0));
      });

      test('handles single data point', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
        ];
        final seriesYValues = {
          'series1': [42.0], // Single point
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(42.0));
        expect(bounds['power']!.max, equals(42.0));
      });

      test('handles axis with no bound series', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'unusedAxis', position: YAxisPosition.left),
        ];
        final bindings = <SeriesAxisBinding>[]; // No bindings
        final seriesYValues = <String, List<double>>{}; // No data

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        // Axis should have default bounds
        expect(bounds['unusedAxis'], isNotNull);
      });

      test('handles very large number of series on one axis', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'power', position: YAxisPosition.left),
        ];
        final bindings = List.generate(
          100,
          (i) => SeriesAxisBinding(seriesId: 'series$i', yAxisId: 'power'),
        );
        final seriesYValues = Map.fromEntries(
          List.generate(
            100,
            (i) => MapEntry('series$i', [i.toDouble(), (i + 100).toDouble()]),
          ),
        );

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds['power']!.min, equals(0.0)); // series0 min
        expect(bounds['power']!.max, equals(199.0)); // series99 max
      });

      test(
        'explicit config bounds override data even if outside data range',
        () {
          final axisConfigs = [
            YAxisConfig.withId(
              id: 'power',
              position: YAxisPosition.left,
              min: -100.0, // Below all data
              max: 1000.0, // Above all data
            ),
          ];
          final bindings = [
            const SeriesAxisBinding(seriesId: 'series1', yAxisId: 'power'),
          ];
          final seriesYValues = {
            'series1': [50.0, 100.0, 150.0],
          };

          final bounds = MultiAxisNormalizer.computeAxisBounds(
            axisConfigs: axisConfigs,
            bindings: bindings,
            seriesYValues: seriesYValues,
          );

          expect(bounds['power']!.min, equals(-100.0)); // explicit
          expect(bounds['power']!.max, equals(1000.0)); // explicit
        },
      );
    });

    group('multiple axes', () {
      test('handles four axes with different series', () {
        final axisConfigs = [
          YAxisConfig.withId(id: 'axis1', position: YAxisPosition.leftOuter),
          YAxisConfig.withId(id: 'axis2', position: YAxisPosition.left),
          YAxisConfig.withId(id: 'axis3', position: YAxisPosition.right),
          YAxisConfig.withId(id: 'axis4', position: YAxisPosition.rightOuter),
        ];
        final bindings = [
          const SeriesAxisBinding(seriesId: 's1', yAxisId: 'axis1'),
          const SeriesAxisBinding(seriesId: 's2', yAxisId: 'axis2'),
          const SeriesAxisBinding(seriesId: 's3', yAxisId: 'axis3'),
          const SeriesAxisBinding(seriesId: 's4', yAxisId: 'axis4'),
        ];
        final seriesYValues = {
          's1': [0.0, 100.0],
          's2': [0.0, 200.0],
          's3': [0.0, 300.0],
          's4': [0.0, 400.0],
        };

        final bounds = MultiAxisNormalizer.computeAxisBounds(
          axisConfigs: axisConfigs,
          bindings: bindings,
          seriesYValues: seriesYValues,
        );

        expect(bounds.length, equals(4));
        expect(bounds['axis1']!.max, equals(100.0));
        expect(bounds['axis2']!.max, equals(200.0));
        expect(bounds['axis3']!.max, equals(300.0));
        expect(bounds['axis4']!.max, equals(400.0));
      });
    });
  });
}
