// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomLine colour channel: value -> ramp -> per-segment segmentStyle.color.
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
        .geomLine(colorBy: Channel(ppace), colorEncoding: ramp)
        .toSpec().lower();

    final line = lowered.series.single as LineChartSeries;
    for (var i = 0; i < rows.length; i++) {
      final expected = ramp.colorFor(
        rows[i].pace,
        resolvedMinimumValue: 0,
        resolvedMaximumValue: 10,
      );
      expect(line.points[i].segmentStyle?.color, expected,
          reason: 'segment leaving point $i');
    }
  });

  test('a line colour channel also emits a colour legend', () {
    final lowered = BravenChart.of(rows)
        .x(pt)
        .y(pv)
        .geomLine(colorBy: Channel(ppace, label: 'Pace'), colorEncoding: ramp)
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
          .geomLine(colorBy: Channel(ppace))
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.missingChannelEncoding)),
    );
  });
}
