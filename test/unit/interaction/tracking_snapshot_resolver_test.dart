// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart'
    show TrendAnnotationElement;
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/interaction/core/tracking_snapshot_resolver.dart';
import 'package:braven_charts/src/rendering/modules/crosshair_renderer.dart'
    show MultiAxisInfo;
import 'package:flutter_test/flutter_test.dart';

/// Plot geometry shared by every scenario: 100×100 plot pixels mapping
/// X 0–10 and Y 0–100, with the plot area at the chart origin so plot-local
/// and screen coordinates coincide.
const _transform = ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 100,
  plotWidth: 100,
  plotHeight: 100,
);

const _plotArea = Rect.fromLTWH(0, 0, 100, 100);

LineChartSeries _powerSeries({
  double intercept = 0,
  Color color = const Color(0xFF2196F3),
}) => LineChartSeries(
  id: 'power',
  name: 'Power',
  points: [
    for (var i = 0; i <= 10; i++)
      ChartDataPoint(x: i.toDouble(), y: i * 10 + intercept),
  ],
  color: color,
);

LineChartSeries _heartRateSeries() => LineChartSeries(
  id: 'hr',
  name: 'Heart rate',
  points: [
    for (var i = 0; i <= 10; i++)
      ChartDataPoint(x: i.toDouble(), y: i * 2),
  ],
  color: const Color(0xFF4CAF50),
);

SeriesElement _element(ChartSeries series) =>
    SeriesElement(series: series, transform: _transform);

MultiAxisInfo _singleAxisInfo() => MultiAxisInfo(
  effectiveAxes: [
    YAxisConfig.withId(id: 'default', position: YAxisPosition.left, unit: 'W'),
  ],
  axisBounds: const {},
  axisWidths: const {},
  effectiveBindings: const [],
  normalizationMode: null,
  series: const [],
);

MultiAxisInfo _dualAxisInfo() => MultiAxisInfo(
  effectiveAxes: [
    YAxisConfig.withId(id: 'watts', position: YAxisPosition.left, unit: 'W'),
    YAxisConfig.withId(id: 'bpm', position: YAxisPosition.right, unit: 'bpm'),
  ],
  axisBounds: const {},
  axisWidths: const {},
  effectiveBindings: const [
    SeriesAxisBinding(seriesId: 'power', yAxisId: 'watts'),
    SeriesAxisBinding(seriesId: 'hr', yAxisId: 'bpm'),
  ],
  normalizationMode: NormalizationMode.perSeries,
  series: const [],
);

CartesianTrackingSnapshot? _resolve(
  CartesianTrackingSnapshotResolver resolver, {
  required Offset cursor,
  required List<ChartElement> elements,
  MultiAxisInfo? axisInfo,
  CartesianTrackingOrigin origin = CartesianTrackingOrigin.pointer,
  bool includeTrends = false,
  int dataRevision = 0,
}) {
  return resolver.resolve(
    cursorPlotPosition: cursor,
    plotArea: _plotArea,
    transform: _transform,
    elements: elements,
    axisInfo: axisInfo ?? _singleAxisInfo(),
    origin: origin,
    includeTrends: includeTrends,
    interpolateValues: false,
    dataRevision: dataRevision,
  );
}

void main() {
  group('CartesianTrackingSnapshotResolver change suppression', () {
    test('repeated resolve with identical inputs returns the same instance '
        'without republishing', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final first = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      final second = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
      expect(resolver.debugResolveCount, 2);
      expect(resolver.debugPublishCount, 1);
      expect(resolver.publishedThisFrame, isFalse);
      expect(identical(resolver.current, first), isTrue);
    });

    test('sub-datum cursor movement keeps the published instance', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final first = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      // dataX 3.2 still snaps to point index 3 with interpolation disabled, so
      // the recomputed snapshot has the same identity and is not republished.
      final second = _resolve(resolver, cursor: const Offset(32, 50), elements: elements);

      expect(identical(first, second), isTrue);
      expect(resolver.debugResolveCount, 2);
      expect(resolver.debugPublishCount, 1);
      expect(resolver.publishedThisFrame, isFalse);
    });

    test('cursor movement to a new snapped datum publishes a new snapshot', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final first = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      final second = _resolve(resolver, cursor: const Offset(72, 50), elements: elements);

      expect(identical(first, second), isFalse);
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);
      expect(second!.values.single.dataPointIndex, 7);
      expect(second.values.single.formattedY, '70');
    });
  });

  group('CartesianTrackingSnapshotResolver cache invalidation', () {
    test('data mutation without a revision bump returns the cached snapshot', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final element = _element(_powerSeries());
      final elements = <ChartElement>[element];

      final first = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      element.updateSeries(_powerSeries(intercept: 5));
      final second = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);

      expect(identical(first, second), isTrue);
      expect(second!.values.single.formattedY, '30');
      expect(resolver.debugPublishCount, 1);
    });

    test('a dataRevision change forces recomputation of changed values', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final element = _element(_powerSeries());
      final elements = <ChartElement>[element];

      _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      element.updateSeries(_powerSeries(intercept: 5));
      final updated = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
        dataRevision: 1,
      );

      expect(updated!.values.single.formattedY, '35');
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);
    });

    test('invalidate() republishes even when the recomputed snapshot has the '
        'same identity', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final element = _element(_powerSeries());
      final elements = <ChartElement>[element];

      final first =
          _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(first!.values.single.seriesColor, const Color(0xFF2196F3));
      expect(resolver.debugPublishCount, 1);

      // Same data values — the recomputed snapshot matches `sameIdentityAs`
      // (identity excludes seriesColor) — but the color changed. Only a
      // forced invalidation can surface it.
      element.updateSeries(_powerSeries(color: const Color(0xFFFF5722)));
      resolver.invalidate();
      final second =
          _resolve(resolver, cursor: const Offset(30, 50), elements: elements);

      expect(identical(first, second), isFalse);
      expect(second!.values.single.seriesColor, const Color(0xFFFF5722));
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);
      expect(identical(resolver.current, second), isTrue);
    });

    test('a dataRevision bump republishes even when the recomputed snapshot '
        'has the same identity', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final element = _element(_powerSeries());
      final elements = <ChartElement>[element];

      final first =
          _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(first!.values.single.seriesColor, const Color(0xFF2196F3));

      element.updateSeries(_powerSeries(color: const Color(0xFFFF5722)));
      final second = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
        dataRevision: 1,
      );

      expect(identical(first, second), isFalse);
      expect(second!.values.single.seriesColor, const Color(0xFFFF5722));
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);
    });

    test('invalidate() forces recomputation with unchanged inputs', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final element = _element(_powerSeries());
      final elements = <ChartElement>[element];

      _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      element.updateSeries(_powerSeries(intercept: 9));

      final cached = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(cached!.values.single.formattedY, '30');

      resolver.invalidate();
      final recomputed = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);

      expect(recomputed!.values.single.formattedY, '39');
      expect(resolver.debugPublishCount, 2);
    });
  });

  group('CartesianTrackingSnapshotResolver compute counting', () {
    test('debugComputeCount increments only on actual computation', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(resolver.debugComputeCount, 1);

      // Memoized inputs: consulted, not recomputed.
      _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(resolver.debugComputeCount, 1);
      expect(resolver.debugResolveCount, 2);

      // Sub-datum movement recomputes but suppresses publication.
      _resolve(resolver, cursor: const Offset(32, 50), elements: elements);
      expect(resolver.debugComputeCount, 2);
      expect(resolver.debugPublishCount, 1);
    });
  });

  group('CartesianTrackingSnapshotResolver clear', () {
    test('clear() publishes null once and resets the memoized inputs', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final snapshot =
          _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(snapshot, isNotNull);
      expect(resolver.debugPublishCount, 1);

      resolver.clear();
      expect(resolver.current, isNull);
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);

      // Idempotent: clearing an already-null snapshot publishes nothing.
      resolver.clear();
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isFalse);

      // The memo resets with the snapshot, so identical inputs recompute and
      // republish instead of returning the cleared null through the cache.
      final again =
          _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(again, isNotNull);
      expect(resolver.debugPublishCount, 3);
    });
  });

  group('CartesianTrackingSnapshotResolver null resolution', () {
    test('cursor outside the plot clears the published snapshot', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final inside = _resolve(resolver, cursor: const Offset(30, 50), elements: elements);
      expect(inside, isNotNull);

      final outside = _resolve(resolver, cursor: const Offset(-5, 50), elements: elements);

      expect(outside, isNull);
      expect(resolver.current, isNull);
      expect(resolver.debugPublishCount, 2);
      expect(resolver.publishedThisFrame, isTrue);
    });
  });

  group('CartesianTrackingSnapshotResolver scatter replacement', () {
    test('scatter values use plot-space nearest points instead of nearest-X', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final scatter = ScatterChartSeries(
        id: 'bubbles',
        name: 'Bubbles',
        points: const [
          ChartDataPoint(x: 1, y: 90),
          ChartDataPoint(x: 9, y: 10),
        ],
        color: const Color(0xFFFF9800),
      );
      final elements = <ChartElement>[
        _element(_powerSeries()),
        _element(scatter),
      ];

      // Plot (20, 85) → dataX 2.0. The nearest-X scatter point would be
      // (1, 90); the plot-space nearest point is (9, 10) at index 1.
      final snapshot = _resolve(
        resolver,
        cursor: const Offset(20, 85),
        elements: elements,
      );

      expect(snapshot, isNotNull);
      final bubble = snapshot!.values.singleWhere(
        (value) => value.seriesId == 'bubbles',
      );
      expect(bubble.dataPointIndex, 1);
      expect(bubble.x, 9);
      expect(bubble.y, 10);
      expect(bubble.formattedX, '9');
      expect(
        snapshot.values.any((value) => value.seriesId == 'power'),
        isTrue,
      );
    });

    test('scatter series without a plot-space hit contributes no value', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[
        _element(_powerSeries()),
        _element(
          const ScatterChartSeries(id: 'ghost', name: 'Ghost', points: []),
        ),
      ];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
      );

      expect(snapshot!.values.map((value) => value.seriesId), ['power']);
    });
  });

  group('CartesianTrackingSnapshotResolver trend values', () {
    TrendAnnotationElement trendElement(ChartSeries series) =>
        TrendAnnotationElement(
          annotation: TrendAnnotation(
            id: 'trend-1',
            label: 'Fit',
            trendType: TrendType.linear,
            seriesId: 'power',
            lineColor: const Color(0xFF9C27B0),
          ),
          series: series,
          transform: _transform,
        );

    test('trend rows are appended when includeTrends is true', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final series = _powerSeries();
      final elements = <ChartElement>[_element(series), trendElement(series)];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
        includeTrends: true,
      );

      expect(snapshot!.values, hasLength(2));
      final trend = snapshot.values.last;
      expect(trend.isTrend, isTrue);
      expect(trend.seriesId, 'trend-1');
      expect(trend.seriesName, 'Fit');
      expect(trend.linkedSeriesId, 'power');
      expect(trend.seriesColor, const Color(0xFF9C27B0));
      expect(trend.dataPointIndex, -1);
      expect(trend.y, closeTo(30, 0.001));
      expect(trend.formattedY, '30');
    });

    test('trend rows are omitted when includeTrends is false', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final series = _powerSeries();
      final elements = <ChartElement>[_element(series), trendElement(series)];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
      );

      expect(snapshot!.values.map((value) => value.seriesId), ['power']);
    });
  });

  group('CartesianTrackingSnapshotResolver formatting', () {
    test('single-axis values carry no unit label (tooltip parity)', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
      );

      final value = snapshot!.values.single;
      expect(value.unitLabel, isNull);
      expect(value.formattedY, '30');
      expect(value.formattedX, '3');
    });

    test('multi-axis values resolve units through series axis bindings', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[
        _element(_powerSeries()),
        _element(_heartRateSeries()),
      ];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
        axisInfo: _dualAxisInfo(),
      );

      final power = snapshot!.values.singleWhere(
        (value) => value.seriesId == 'power',
      );
      final heartRate = snapshot.values.singleWhere(
        (value) => value.seriesId == 'hr',
      );
      expect(power.formattedY, '30 W');
      expect(power.unitLabel, 'W');
      expect(heartRate.formattedY, '6 bpm');
      expect(heartRate.unitLabel, 'bpm');
    });

    test('snapshot carries tracked position and primary point identity', () {
      final resolver = CartesianTrackingSnapshotResolver();
      final elements = <ChartElement>[_element(_powerSeries())];

      final snapshot = _resolve(
        resolver,
        cursor: const Offset(30, 50),
        elements: elements,
        origin: CartesianTrackingOrigin.synchronized,
      );

      expect(snapshot!.dataX, 3.0);
      expect(snapshot.plotX, 30);
      expect(snapshot.origin, CartesianTrackingOrigin.synchronized);
      expect(
        snapshot.primaryPoint,
        const ChartPointRef(seriesId: 'power', pointIndex: 3),
      );
    });
  });
}
