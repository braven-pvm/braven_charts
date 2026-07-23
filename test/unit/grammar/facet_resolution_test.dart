// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// `resolveFacetPanels` composition: partition → subset → injected ranges.
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

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  test('one panel per distinct value in first-seen order, with subset data', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    final panels = resolveFacetPanels(spec);
    expect(panels.map((p) => p.value), <Object?>['easy', 'hard']);
    expect(panels.first.spec.data, <Sample>[rows[0], rows[2]]);
    expect(panels.last.spec.data, <Sample>[rows[1]]);
    // Each panel spec is facet-cleared so BravenPlot can lower it.
    expect(panels.every((p) => p.spec.facet == null), isTrue);
  });

  test('fixed scales inject the same global x and y range into every panel', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    for (final panel in resolveFacetPanels(spec)) {
      expect(panel.spec.xAxis?.min, 0);
      expect(panel.spec.xAxis?.max, 2);
      expect(panel.spec.yAxes.single.min, 180);
      expect(panel.spec.yAxes.single.max, 260);
    }
  });

  test('freeY leaves y unbounded and keeps x shared', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.freeY),
    );
    final panel = resolveFacetPanels(spec).first;
    expect(panel.spec.xAxis?.min, 0);
    expect(panel.spec.yAxes, isEmpty);
  });

  test('free leaves both axes to auto-scale each subset', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
    );
    final panel = resolveFacetPanels(spec).first;
    expect(panel.spec.xAxis, isNull);
    expect(panel.spec.yAxes, isEmpty);
  });

  test('the label prefixes the strip when provided', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, label: 'Zone'),
    );
    expect(resolveFacetPanels(spec).map((p) => p.label),
        <String>['Zone: easy', 'Zone: hard']);
  });

  test('no facet, empty rows and the panel cap are diagnostics', () {
    expect(
      () => resolveFacetPanels(const PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      )),
      throwsGrammarCode(GrammarDiagnosticCode.notFaceted),
    );
    expect(
      () => resolveFacetPanels(const PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
        facet: FacetSpec<Sample>(by: sampleZone),
      )),
      throwsGrammarCode(GrammarDiagnosticCode.emptyFacetValues),
    );
    final many = <Sample>[
      for (var i = 0; i < facetPanelCap + 1; i++)
        Sample(time: i.toDouble(), power: 1, zone: 'z$i'),
    ];
    expect(
      () => resolveFacetPanels(PlotSpec<Sample>(
        data: many,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
        facet: const FacetSpec<Sample>(by: sampleZone),
      )),
      throwsGrammarCode(GrammarDiagnosticCode.facetPanelCapExceeded),
    );
  });
}
