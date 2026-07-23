// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomBar colour channel: value -> ramp -> per-bar pointStyle.color, + legend.
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Bar {
  const Bar(this.cat, this.value, this.heat);
  final double cat;
  final double value;
  final double heat;
}

double barCat(Bar r) => r.cat;
double barValue(Bar r) => r.value;
double barHeat(Bar r) => r.heat;

const rows = <Bar>[
  Bar(0, 10, 0), // heat min
  Bar(1, 20, 5),
  Bar(2, 15, 10), // heat max
];

const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  label: 'Heat',
);

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  test('each bar gets pointStyle.color = colorFor(heat) over the domain', () {
    final lowered = BravenChart.of(rows)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat), colorEncoding: ramp)
        .toSpec().lower();

    final bar = lowered.series.single as BarChartSeries;
    for (var i = 0; i < rows.length; i++) {
      final expected = ramp.colorFor(
        rows[i].heat,
        resolvedMinimumValue: 0,
        resolvedMaximumValue: 10,
      );
      expect(bar.points[i].pointStyle?.color, expected,
          reason: 'bar $i colour');
    }
  });

  test('a colour channel emits a colour-ramp legend annotation', () {
    final lowered = BravenChart.of(rows)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat, label: 'Heat'), colorEncoding: ramp)
        .toSpec().lower();

    final legend = lowered.annotations
        .whereType<LegendAnnotation>()
        .singleWhere((a) => a.colorScale != null);
    expect(legend.colorScale!.label, 'Heat');
    expect(legend.colorScale!.colors, ramp.colors);
    expect(legend.colorScale!.minimumLabel, '0');
    expect(legend.colorScale!.maximumLabel, '10');
  });

  test('colorBy without colorEncoding raises missingChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(colorBy: Channel(barHeat))
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.missingChannelEncoding),
    );
  });

  test('colorEncoding without colorBy raises orphanChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(colorEncoding: ramp)
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.orphanChannelEncoding),
    );
  });

  test('a non-native colour scale raises unsupportedChannelScale', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(
            colorBy: Channel(barHeat, scale: ChannelScale.sqrt),
            colorEncoding: ramp,
          )
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.unsupportedChannelScale),
    );
  });

  test('a non-finite channel value leaves that bar without a baked colour', () {
    const withNaN = <Bar>[Bar(0, 10, 0), Bar(1, 20, double.nan)];
    final lowered = BravenChart.of(withNaN)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat), colorEncoding: ramp)
        .toSpec().lower();
    final bar = lowered.series.single as BarChartSeries;
    expect(bar.points[1].pointStyle?.color, isNull);
  });
}
