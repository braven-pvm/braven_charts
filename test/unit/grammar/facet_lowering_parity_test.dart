// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Faceting is pure composition: a panel's lowered config equals the config of
/// the equivalent STANDALONE spec (the same marks, the same injected range, the
/// panel's own row subset). The standalone side is written by hand — deriving
/// it from the facet resolution would make this tautological.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/grammar/braven_facet_plot.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.time, required this.power, required this.zone});
  final double time;
  final double power;
  final Object? zone;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
Object? sampleZone(Sample row) => row.zone;

const rows = <Sample>[
  Sample(time: 0, power: 180, zone: 'easy'),
  Sample(time: 1, power: 260, zone: 'hard'),
  Sample(time: 2, power: 220, zone: 'easy'),
];

void main() {
  test('a fixed-scale panel lowers to the standalone spec it equals', () {
    const faceted = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    // The 'easy' panel: rows 0 and 2, global x-range [0, 2], y-range [180, 260].
    final panel = resolveFacetPanels(faceted).first;
    final panelLowered = panel.spec.lower();

    // Hand-written standalone equivalent — the subset, the injected range.
    final standalone = PlotSpec<Sample>(
      data: const <Sample>[
        Sample(time: 0, power: 180, zone: 'easy'),
        Sample(time: 2, power: 220, zone: 'easy'),
      ],
      marks: const <Mark<Sample>>[
        LineMark<Sample>(x: sampleTime, y: samplePower),
      ],
      xAxis: const XAxisConfig(min: 0, max: 2),
      yAxes: <YAxisConfig>[
        YAxisConfig(position: YAxisPosition.left, min: 180, max: 260),
      ],
    );
    final standaloneLowered = standalone.lower();

    expect(panelLowered.series, standaloneLowered.series);
    expect(panelLowered.yAxes, standaloneLowered.yAxes);
    expect(panelLowered.xAxis, standaloneLowered.xAxis);
    expect(panelLowered.annotations, standaloneLowered.annotations);
  });

  test('a free-scale panel lowers with no injected range', () {
    const faceted = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
    );
    final panel = resolveFacetPanels(faceted).first;
    final lowered = panel.spec.lower();

    expect(lowered.xAxis, isNull);
    // The synthesized default axis carries no bounds under free scaling.
    expect(lowered.yAxes.single.min, isNull);
    expect(lowered.yAxes.single.max, isNull);
    // Same series the standalone subset produces.
    final standalone = const PlotSpec<Sample>(
      data: <Sample>[
        Sample(time: 0, power: 180, zone: 'easy'),
        Sample(time: 2, power: 220, zone: 'easy'),
      ],
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
    ).lower();
    expect(lowered.series, standalone.series);
  });
}
