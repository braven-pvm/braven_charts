// Copyright (c) 2025 braven_charts. All rights reserved.
// Multi-Axis Manager Tests

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisManager', () {
    late MultiAxisManager manager;

    setUp(() {
      manager = MultiAxisManager();
    });

    group('Configuration Updates', () {
      test('setNormalizationMode returns true when mode changes', () {
        expect(manager.setNormalizationMode(NormalizationMode.perSeries), isTrue);
        expect(manager.normalizationMode, equals(NormalizationMode.perSeries));
      });

      test('setNormalizationMode returns false when mode is same', () {
        manager.setNormalizationMode(NormalizationMode.perSeries);
        expect(manager.setNormalizationMode(NormalizationMode.perSeries), isFalse);
      });

      test('setSeries returns true when series changes', () {
        final series = [
          const ChartSeries(id: 's1', name: 'Series 1', points: []),
        ];
        expect(manager.setSeries(series), isTrue);
        expect(manager.series, equals(series));
      });

      test('setSeries returns false when series is same', () {
        final series = [
          const ChartSeries(id: 's1', name: 'Series 1', points: []),
        ];
        manager.setSeries(series);
        expect(manager.setSeries(series), isFalse);
      });

      test('setSeries with null converts to empty list', () {
        manager.setSeries([
          const ChartSeries(id: 's1', name: 'Series 1', points: []),
        ]);
        manager.setSeries(null);
        expect(manager.series, isEmpty);
      });
    });

    group('Multi-Axis Detection', () {
      test('hasMultipleYAxes returns false when no series', () {
        expect(manager.hasMultipleYAxes(), isFalse);
      });

      test('hasMultipleYAxes returns false with single axis config', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);
        expect(manager.hasMultipleYAxes(), isFalse);
      });

      test('hasMultipleYAxes returns true with multiple axis configs', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
          ),
        ]);
        expect(manager.hasMultipleYAxes(), isTrue);
      });

      test('isMultiAxisNormalizationActive requires both conditions', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
          ),
        ]);

        // Without normalization mode
        expect(manager.isMultiAxisNormalizationActive(), isFalse);

        // With normalization mode
        manager.setNormalizationMode(NormalizationMode.perSeries);
        expect(manager.isMultiAxisNormalizationActive(), isTrue);
      });
    });

    group('Effective Axes Resolution', () {
      test('getEffectiveYAxes creates default axis when no series', () {
        final axes = manager.getEffectiveYAxes();
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('primary_axis'));
        expect(axes.first.position, equals(YAxisPosition.left));
      });

      test('getEffectiveYAxes returns axes from inline yAxisConfig', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final axes = manager.getEffectiveYAxes();
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('axis1'));
      });

      test('getEffectiveYAxes deduplicates axes with same ID', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'shared', position: YAxisPosition.left),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'shared', position: YAxisPosition.left),
          ),
        ]);

        final axes = manager.getEffectiveYAxes();
        expect(axes, hasLength(1));
      });

      test('getEffectiveYAxes returns consistent results for same input', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final axes1 = manager.getEffectiveYAxes();
        final axes2 = manager.getEffectiveYAxes();
        // Results should be consistent (same content) but not necessarily cached (identical)
        expect(axes1.length, equals(axes2.length));
        expect(axes1.first.id, equals(axes2.first.id));
      });

      test('setSeries invalidates axes cache', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final axes1 = manager.getEffectiveYAxes();

        manager.setSeries([
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
          ),
        ]);

        final axes2 = manager.getEffectiveYAxes();
        expect(identical(axes1, axes2), isFalse);
        expect(axes2.first.id, equals('axis2'));
      });

      test('getEffectiveYAxes includes primaryYAxis parameter', () {
        final primaryAxis = YAxisConfig.withId(
          id: 'primary',
          position: YAxisPosition.left,
        );

        final axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('primary'));
        expect(axes.first.position, equals(YAxisPosition.left));
      });

      test('getEffectiveYAxes auto-generates ID for primaryYAxis if empty', () {
        // Use default constructor which automatically sets id to empty string
        final primaryAxis = YAxisConfig(
          position: YAxisPosition.left,
        );

        final axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('primary_axis'));
      });

      test('getEffectiveYAxes does not duplicate primaryYAxis with inline config', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'shared', position: YAxisPosition.left),
          ),
        ]);

        final primaryAxis = YAxisConfig.withId(
          id: 'shared',
          position: YAxisPosition.right,
        );

        final axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('shared'));
        // Should keep the inline config (first priority)
        expect(axes.first.position, equals(YAxisPosition.left));
      });

      test('getEffectiveYAxes creates default axis when no config exists', () {
        final axes = manager.getEffectiveYAxes();
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('primary_axis'));
        expect(axes.first.position, equals(YAxisPosition.left));
      });

      test('getEffectiveYAxes combines inline configs and primaryYAxis', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final primaryAxis = YAxisConfig.withId(
          id: 'primary',
          position: YAxisPosition.right,
        );

        final axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes, hasLength(2));
        expect(axes.map((a) => a.id), containsAll(['axis1', 'primary']));
      });

      test('getEffectiveYAxes does not create default when primaryYAxis provided', () {
        final primaryAxis = YAxisConfig.withId(
          id: 'custom',
          position: YAxisPosition.right,
        );

        final axes = manager.getEffectiveYAxes(primaryYAxis: primaryAxis);
        expect(axes, hasLength(1));
        expect(axes.first.id, equals('custom'));
        // No default axis should be created
      });
    });

    group('Effective Bindings Resolution', () {
      test('getEffectiveBindings returns empty list when no series', () {
        expect(manager.getEffectiveBindings(), isEmpty);
      });

      test('getEffectiveBindings creates binding from yAxisConfig', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final bindings = manager.getEffectiveBindings();
        expect(bindings, hasLength(1));
        expect(bindings.first.seriesId, equals('s1'));
        expect(bindings.first.yAxisId, equals('axis1'));
      });

      test('getEffectiveBindings creates binding from yAxisId', () {
        manager.setSeries([
          const ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [],
            yAxisId: 'referenced_axis',
          ),
        ]);

        final bindings = manager.getEffectiveBindings();
        expect(bindings, hasLength(1));
        expect(bindings.first.seriesId, equals('s1'));
        expect(bindings.first.yAxisId, equals('referenced_axis'));
      });

      test('getEffectiveBindings prioritizes yAxisConfig over yAxisId', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'inline_axis', position: YAxisPosition.left),
            yAxisId: 'referenced_axis',
          ),
        ]);

        final bindings = manager.getEffectiveBindings();
        expect(bindings, hasLength(1));
        expect(bindings.first.yAxisId, equals('inline_axis'));
      });
    });

    group('Axis Bounds Computation', () {
      test('computeAxisBounds creates default axis when no series', () {
        final bounds = manager.computeAxisBounds();
        expect(bounds, contains('primary_axis'));
        expect(bounds['primary_axis'], isNotNull);
      });

      test('computeAxisBounds uses explicit min/max from config', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [
              ChartDataPoint(x: 0, y: 50),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
              min: 0,
              max: 100,
            ),
          ),
        ]);

        final bounds = manager.computeAxisBounds();
        expect(bounds, contains('axis1'));
        // With 5% padding: 0-5 = -5, 100+5 = 105
        expect(bounds['axis1']!.min, closeTo(-5.0, 0.001));
        expect(bounds['axis1']!.max, closeTo(105.0, 0.001));
      });

      test('computeAxisBounds computes from series data', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 90),
            ],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final bounds = manager.computeAxisBounds();
        expect(bounds, contains('axis1'));
        // Data range: 10-90. With 5% padding of 80 = 4: 10-4=6, 90+4=94
        expect(bounds['axis1']!.min, closeTo(6.0, 0.001));
        expect(bounds['axis1']!.max, closeTo(94.0, 0.001));
      });

      test('computeAxisBounds uses default 0-100 when no data', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final bounds = manager.computeAxisBounds();
        expect(bounds, contains('axis1'));
        // Default 0-100 with 5% padding of 100 = 5: -5 to 105
        expect(bounds['axis1']!.min, closeTo(-5.0, 0.001));
        expect(bounds['axis1']!.max, closeTo(105.0, 0.001));
      });

      test('computeAxisBounds supports viewport transformation', () {
        manager.setNormalizationMode(NormalizationMode.perSeries);
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 100),
            ],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        final original = const ChartTransform(
          dataXMin: 0,
          dataXMax: 1,
          dataYMin: -0.05,
          dataYMax: 1.05,
          plotWidth: 800,
          plotHeight: 600,
        );

        // Zoomed transform showing middle 50%
        final zoomed = const ChartTransform(
          dataXMin: 0,
          dataXMax: 1,
          dataYMin: 0.2,
          dataYMax: 0.8,
          plotWidth: 800,
          plotHeight: 600,
        );

        final bounds = manager.computeAxisBounds(
          transform: zoomed,
          originalTransform: original,
        );

        // The bounds should be transformed based on the viewport
        expect(bounds['axis1']!.min, isNot(closeTo(-5.0, 0.001)));
        expect(bounds['axis1']!.max, isNot(closeTo(105.0, 0.001)));
      });
    });

    group('Normalization Helpers', () {
      test('normalizeYValue normalizes correctly', () {
        expect(manager.normalizeYValue(50, 0, 100), equals(0.5));
        expect(manager.normalizeYValue(0, 0, 100), equals(0.0));
        expect(manager.normalizeYValue(100, 0, 100), equals(1.0));
      });

      test('denormalizeYValue denormalizes correctly', () {
        expect(manager.denormalizeYValue(0.5, 0, 100), equals(50.0));
        expect(manager.denormalizeYValue(0.0, 0, 100), equals(0.0));
        expect(manager.denormalizeYValue(1.0, 0, 100), equals(100.0));
      });

      test('normalizeValue handles edge cases', () {
        // Zero range
        expect(manager.normalizeValue(50, 50, 50), equals(0.5));

        // Negative range
        expect(manager.normalizeValue(-50, -100, 0), equals(0.5));
      });

      test('denormalizeValue handles edge cases', () {
        // Zero range returns the value
        expect(manager.denormalizeValue(0.5, 50, 50), equals(50.0));

        // Extrapolation beyond 0-1
        expect(manager.denormalizeValue(1.5, 0, 100), equals(150.0));
        expect(manager.denormalizeValue(-0.5, 0, 100), equals(-50.0));
      });
    });

    group('MultiAxisInfo Builder', () {
      test('buildMultiAxisInfo creates complete info object', () {
        manager.setNormalizationMode(NormalizationMode.perSeries);
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 90),
            ],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 1000),
            ],
            yAxisConfig: YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
          ),
        ]);

        final info = manager.buildMultiAxisInfo();

        expect(info.effectiveAxes, hasLength(2));
        expect(info.axisBounds, hasLength(2));
        expect(info.axisWidths, hasLength(2));
        expect(info.effectiveBindings, hasLength(2));
        expect(info.normalizationMode, equals(NormalizationMode.perSeries));
        expect(info.series, hasLength(2));
        expect(info.isMultiAxisMode, isTrue);
      });

      test('MultiAxisInfo.isMultiAxisMode requires both conditions', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        // Single axis - not multi-axis mode
        var info = manager.buildMultiAxisInfo();
        expect(info.isMultiAxisMode, isFalse);

        // Add second axis but no normalization mode
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis2', position: YAxisPosition.right),
          ),
        ]);
        info = manager.buildMultiAxisInfo();
        expect(info.isMultiAxisMode, isFalse);

        // Set normalization mode
        manager.setNormalizationMode(NormalizationMode.perSeries);
        info = manager.buildMultiAxisInfo();
        expect(info.isMultiAxisMode, isTrue);
      });
    });

    group('Cache Invalidation', () {
      test('invalidateCache clears both caches', () {
        manager.setSeries([
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: const [],
            yAxisConfig: YAxisConfig.withId(id: 'axis1', position: YAxisPosition.left),
          ),
        ]);

        // Populate caches
        final axes1 = manager.getEffectiveYAxes();
        final bindings1 = manager.getEffectiveBindings();

        // Invalidate
        manager.invalidateCache();

        // Get new values
        final axes2 = manager.getEffectiveYAxes();
        final bindings2 = manager.getEffectiveBindings();

        // Should be different instances
        expect(identical(axes1, axes2), isFalse);
        expect(identical(bindings1, bindings2), isFalse);
      });
    });
  });
}
