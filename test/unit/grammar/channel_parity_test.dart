// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Whole-series config-parity for the scale-driven channel lowering.
///
/// PARITY MEANS the same discipline as `plot_lowering_parity_test.dart`, but
/// for the four channel families the non-scatter geometries grew (bar colour,
/// line colour, area colour, bar size): build the chart through [PlotSpec] and
/// [PlotSpecLowering.lower], then assert `lowered.series.single` equals the
/// hand-written `ChartSeries` a user would author today — points and all — by
/// the package's own `==`. The baked colours/widths in the expected series are
/// computed by calling the SAME `ScatterColorEncoding.colorFor` /
/// `ScatterSizeEncoding` linear map the lowering bakes with, so the equality is
/// a genuine cross-check, not a restatement of literals. The emitted colour
/// LEGEND is asserted the same way (whole-`LegendColorScale` equality), plus
/// the piecewise-band and `showLegend: false` legend behaviours the reviewer
/// flagged as uncovered on the non-scatter families.
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row(this.x, this.y, this.c);
  final double x;
  final double y;
  final double c;
}

double rx(Row r) => r.x;
double ry(Row r) => r.y;
double rc(Row r) => r.c;

const rows = <Row>[
  Row(0, 10, 0), // channel domain minimum
  Row(1, 20, 5),
  Row(2, 15, 10), // channel domain maximum
];

/// The finite channel domain of [rows], which the lowering derives itself.
const domainMin = 0.0;
const domainMax = 10.0;

/// A two-stop continuous ramp. The colour cases bake and legend against this.
const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  label: 'Heat',
);

/// A discrete three-band ramp for the piecewise legend case.
const piecewise = ScatterColorEncoding(
  colors: <Color>[Color(0xFF00FF00), Color(0xFFFFFF00), Color(0xFFFF0000)],
  scaleType: ScatterColorScaleType.piecewise,
  thresholds: <double>[3, 7],
  bandLabels: <String>['Low', 'Mid', 'High'],
  label: 'Heat',
);

/// The same ramp with its legend hidden.
const hiddenRamp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  showLegend: false,
);

/// Width-multiplier range for the bar-size case.
const barWidths = ScatterSizeEncoding(minimumRadius: 0.5, maximumRadius: 1.5);

/// The axis the lowering synthesizes when a spec declares none — identical to
/// the sibling parity file's `defaultAxis()`.
YAxisConfig defaultAxis() =>
    YAxisConfig(position: YAxisPosition.left).copyWith(id: 'axis-0');

/// Per-row baked colour, via the SAME ramp the lowering bakes with, so the
/// expected series carries genuinely-computed colours.
List<Color?> bakedColors(ScatterColorEncoding encoding) => <Color?>[
  for (final row in rows)
    encoding.colorFor(
      row.c,
      resolvedMinimumValue: domainMin,
      resolvedMaximumValue: domainMax,
    ),
];

/// Per-row baked width multiplier, mirroring `_bakeChannelWidths` arithmetic
/// exactly so the doubles compare bit-for-bit under whole-series `==`.
List<double> bakedWidths(ScatterSizeEncoding encoding) {
  const span = domainMax - domainMin;
  return <double>[
    for (final row in rows)
      encoding.minimumRadius +
          (span <= 0 ? 0.5 : ((row.c - domainMin) / span).clamp(0.0, 1.0)) *
              (encoding.maximumRadius - encoding.minimumRadius),
  ];
}

void main() {
  group('parity: channel families lower to fully-styled series', () {
    test('bar colour → BarChartSeries with per-bar pointStyle.color', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          BarMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc, label: 'Heat'),
            colorEncoding: ramp,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      final colors = bakedColors(ramp);
      final handBuiltBar = BarChartSeries(
        id: 'mark-0',
        points: <ChartDataPoint>[
          for (var i = 0; i < rows.length; i++)
            ChartDataPoint(
              x: rows[i].x,
              y: rows[i].y,
              pointStyle: colors[i] == null
                  ? null
                  : PointStyle(color: colors[i]),
            ),
        ],
        yAxisId: 'axis-0',
        yAxisConfig: axis,
        barWidthPercent: 0.8,
      );
      expect(lowered.series.single, equals(handBuiltBar));
    });

    test('line colour → LineChartSeries with leading-point segmentStyle.color', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          LineMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc),
            colorEncoding: ramp,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      final colors = bakedColors(ramp);
      final handBuiltLine = LineChartSeries(
        id: 'mark-0',
        points: <ChartDataPoint>[
          for (var i = 0; i < rows.length; i++)
            ChartDataPoint(
              x: rows[i].x,
              y: rows[i].y,
              // Every point carries the leaving-segment colour, including the
              // last (its outgoing segment is unused but still set for parity).
              segmentStyle: colors[i] == null
                  ? null
                  : SegmentStyle.color(colors[i]!),
            ),
        ],
        yAxisId: 'axis-0',
        yAxisConfig: axis,
      );
      expect(lowered.series.single, equals(handBuiltLine));
    });

    test('area colour → AreaChartSeries with edge segmentStyle.color', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          AreaMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc),
            colorEncoding: ramp,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      final colors = bakedColors(ramp);
      final handBuiltArea = AreaChartSeries(
        id: 'mark-0',
        points: <ChartDataPoint>[
          for (var i = 0; i < rows.length; i++)
            ChartDataPoint(
              x: rows[i].x,
              y: rows[i].y,
              segmentStyle: colors[i] == null
                  ? null
                  : SegmentStyle.color(colors[i]!),
            ),
        ],
        yAxisId: 'axis-0',
        yAxisConfig: axis,
      );
      expect(lowered.series.single, equals(handBuiltArea));
    });

    test('bar size → BarChartSeries with per-bar pointStyle.size (linear)', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          BarMark<Row>(
            x: rx,
            y: ry,
            sizeBy: Channel<Row>(rc),
            sizeEncoding: barWidths,
          ),
        ],
      )).lower();

      final axis = defaultAxis();
      final widths = bakedWidths(barWidths);
      final handBuiltBar = BarChartSeries(
        id: 'mark-0',
        points: <ChartDataPoint>[
          for (var i = 0; i < rows.length; i++)
            ChartDataPoint(
              x: rows[i].x,
              y: rows[i].y,
              pointStyle: PointStyle(size: widths[i]),
            ),
        ],
        yAxisId: 'axis-0',
        yAxisConfig: axis,
        barWidthPercent: 0.8,
      );
      expect(lowered.series.single, equals(handBuiltBar));
    });
  });

  group('parity: emitted colour legend', () {
    test('the bar colour legend equals a hand-built LegendColorScale', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          BarMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc, label: 'Heat'),
            colorEncoding: ramp,
          ),
        ],
      )).lower();

      final midpoint = (domainMin + domainMax) / 2;
      final handBuiltScale = LegendColorScale(
        label: 'Heat',
        colors: ramp.colors,
        minimumLabel: ramp.format(domainMin),
        midpointLabel: ramp.format(midpoint),
        maximumLabel: ramp.format(domainMax),
      );
      expect(
        lowered.annotations.whereType<LegendAnnotation>().single.colorScale,
        equals(handBuiltScale),
      );
    });

    test('a piecewise colour channel emits a piecewise, banded legend', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          BarMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc),
            colorEncoding: piecewise,
          ),
        ],
      )).lower();

      final scale = lowered.annotations
          .whereType<LegendAnnotation>()
          .singleWhere((a) => a.colorScale != null)
          .colorScale!;
      expect(scale.type, LegendColorScaleType.piecewise);
      expect(scale.segmentLabels, equals(piecewise.effectiveBandLabels));
      // The encoding's own labels flow straight through, unchanged.
      expect(piecewise.effectiveBandLabels, <String>['Low', 'Mid', 'High']);
    });

    test('showLegend: false suppresses the colour legend', () {
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          BarMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc),
            colorEncoding: hiddenRamp,
          ),
        ],
      )).lower();

      // No colour-scale legend is emitted...
      expect(
        lowered.annotations
            .whereType<LegendAnnotation>()
            .where((a) => a.colorScale != null),
        isEmpty,
      );
      // ...even though the bars are still baked (suppression is legend-only).
      final bar = lowered.series.single as BarChartSeries;
      expect(bar.points.first.pointStyle?.color, isNotNull);
    });

    test('the continuous legend carries a midpoint label and continuous type', () {
      // Field coverage on a domain where min != max: the midpoint label is the
      // encoding's formatted midpoint, and a two-stop ramp is continuous.
      final lowered = (const PlotSpec<Row>(
        data: rows,
        marks: <Mark<Row>>[
          LineMark<Row>(
            x: rx,
            y: ry,
            colorBy: Channel<Row>(rc, label: 'Pace'),
            colorEncoding: ramp,
          ),
        ],
      )).lower();

      final scale = lowered.annotations
          .whereType<LegendAnnotation>()
          .single
          .colorScale!;
      expect(scale.type, LegendColorScaleType.continuous);
      expect(scale.midpointLabel, ramp.format((domainMin + domainMax) / 2));
      expect(scale.label, 'Pace');
    });
  });
}
