// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomArea colour channel: value -> ramp -> per-segment segmentStyle.color on
/// the area's TOP EDGE (leading-point rule), NOT the fill.
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class P {
  const P(this.t, this.v, this.pace);
  final double t;
  final double v;
  final double pace;
}

double pt(P r) => r.t;
double pv(P r) => r.v;
double ppace(P r) => r.pace;

const rows = <P>[P(0, 5, 0), P(1, 7, 5), P(2, 6, 10)];
const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF00FF00), Color(0xFFFF0000)],
);

void main() {
  test('each point gets segmentStyle.color = colorFor(pace) (leading rule)', () {
    final lowered = BravenChart.of(rows)
        .x(pt)
        .y(pv)
        .geomArea(colorBy: Channel(ppace), colorEncoding: ramp)
        .toSpec().lower();

    final area = lowered.series.single as AreaChartSeries;
    for (var i = 0; i < rows.length; i++) {
      final expected = ramp.colorFor(
        rows[i].pace,
        resolvedMinimumValue: 0,
        resolvedMaximumValue: 10,
      );
      expect(area.points[i].segmentStyle?.color, expected,
          reason: 'edge segment leaving point $i');
    }
  });

  test('an area colour channel also emits a colour legend', () {
    final lowered = BravenChart.of(rows)
        .x(pt)
        .y(pv)
        .geomArea(colorBy: Channel(ppace, label: 'Pace'), colorEncoding: ramp)
        .toSpec().lower();
    final legend = lowered.annotations
        .whereType<LegendAnnotation>()
        .singleWhere((a) => a.colorScale != null);
    expect(legend.colorScale!.label, 'Pace');
  });

  test('colorBy without colorEncoding raises missingChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(pt)
          .y(pv)
          .geomArea(colorBy: Channel(ppace))
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.missingChannelEncoding)),
    );
  });

  test('colorEncoding without colorBy raises orphanChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(pt)
          .y(pv)
          .geomArea(colorEncoding: ramp)
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.orphanChannelEncoding)),
    );
  });
}
