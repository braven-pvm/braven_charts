// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The family list behind the legacy single-axis shape, pinned once.
///
/// `BravenPlot`'s mount and `ChartGrammarSourceGenerator`'s round-trip
/// comparison both ask "can this series be unbound?", and they answer with
/// OPPOSITE fallbacks: the mount abandons the legacy shape on a null, the
/// generator maps a null back to the bound series so the comparison fails
/// closed. Written as two switches they would drift the moment a sixth
/// Cartesian family arrives — the generator would normalise a binding away and
/// emit a chain the widget then mounts multi-axis, so the chain would hand back
/// `axisId` + `inlineAxis` the captured chart does not have. Neither the
/// round-trip proof (lowered vs captured, never MOUNTED vs captured) nor the
/// hand-written `rebuilt` twins would see it.
///
/// This file pins the single list both callers share.
library;

import 'dart:ui' show Color;

import 'package:braven_charts/src/grammar/series_axis_unbinding.dart';
import 'package:braven_charts/src/models/candlestick_chart_series.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/range_area_chart_series.dart';
import 'package:braven_charts/src/models/range_area_data_point.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

final YAxisConfig axis = YAxisConfig.withId(
  id: 'y',
  position: YAxisPosition.left,
);

const List<ChartDataPoint> points = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 1),
  ChartDataPoint(x: 1, y: 2),
];

void main() {
  group('seriesWithoutAxisBinding', () {
    test('clears BOTH bindings on every Cartesian family the grammar carries', () {
      final bound = <ChartSeries>[
        LineChartSeries(
          id: 'line',
          points: points,
          name: 'line series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
        AreaChartSeries(
          id: 'area',
          points: points,
          name: 'area series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
        BarChartSeries(
          id: 'bar',
          points: points,
          barWidthPercent: 0.8,
          name: 'bar series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
        ScatterChartSeries(
          id: 'scatter',
          points: points,
          name: 'scatter series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
        CandlestickChartSeries(
          id: 'candle',
          points: <CandlestickDataPoint>[
            CandlestickDataPoint(x: 0, open: 1, high: 3, low: 0, close: 2),
          ],
          name: 'candle series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
      ];

      for (final series in bound) {
        final stripped = seriesWithoutAxisBinding(series);
        expect(
          stripped,
          isNotNull,
          reason: '${series.runtimeType} must be unbindable',
        );
        expect(stripped!.yAxisId, isNull, reason: '${series.runtimeType}');
        expect(stripped.yAxisConfig, isNull, reason: '${series.runtimeType}');
        // Nothing but the binding moves: re-binding the stripped series has to
        // reproduce the original exactly, which is what makes the mount and the
        // round-trip comparison the SAME chart. The fixtures carry non-default
        // `name`, `color` and `unit` so this has teeth — a `copyWith` that
        // dropped a field would compare equal if every field were left at its
        // default. When a new `ChartSeries` field lands, add it here.
        expect(
          stripped.copyWith(yAxisId: 'y', yAxisConfig: axis),
          series,
          reason: '${series.runtimeType} lost more than its binding',
        );
      }
    });

    test('returns null for a family that cannot express an unbound series', () {
      // `RangeAreaChartSeries` has no grammar mark yet (roadmap item 1b adds
      // one). Until its `copyWith` can clear the binding, the answer must stay
      // null so BOTH callers keep failing closed instead of one of them
      // guessing.
      final series = RangeAreaChartSeries(
        id: 'range',
        points: <RangeAreaDataPoint>[RangeAreaDataPoint(x: 0, low: 1, high: 2)],
        yAxisId: 'y',
        yAxisConfig: axis,
      );

      expect(seriesWithoutAxisBinding(series), isNull);
    });
  });
}
