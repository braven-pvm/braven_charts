// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomBar size channel: value -> LINEAR map -> per-bar pointStyle.size (width).
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Bar {
  const Bar(this.cat, this.value, this.weight);
  final double cat;
  final double value;
  final double weight;
}

double bcat(Bar r) => r.cat;
double bval(Bar r) => r.value;
double bweight(Bar r) => r.weight;

const rows = <Bar>[Bar(0, 10, 0), Bar(1, 20, 5), Bar(2, 15, 10)];
// width multiplier range 0.5 .. 1.5
const widths = ScatterSizeEncoding(minimumRadius: 0.5, maximumRadius: 1.5);
const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  label: 'Weight',
);

void main() {
  test('each bar width = linear map of weight into [0.5, 1.5]', () {
    final lowered = BravenChart.of(rows)
        .x(bcat)
        .y(bval)
        .geomBar(sizeBy: Channel(bweight), sizeEncoding: widths)
        .toSpec()
        .lower();
    final bar = lowered.series.single as BarChartSeries;
    // weight 0 -> 0.5, weight 5 -> 1.0, weight 10 -> 1.5 (LINEAR, not sqrt).
    expect(bar.points[0].pointStyle?.size, closeTo(0.5, 1e-9));
    expect(bar.points[1].pointStyle?.size, closeTo(1.0, 1e-9));
    expect(bar.points[2].pointStyle?.size, closeTo(1.5, 1e-9));
  });

  test('colour + size compose on one bar mark', () {
    final lowered = BravenChart.of(rows)
        .x(bcat)
        .y(bval)
        .geomBar(
          colorBy: Channel(bweight),
          colorEncoding: ramp,
          sizeBy: Channel(bweight),
          sizeEncoding: widths,
        )
        .toSpec()
        .lower();
    final bar = lowered.series.single as BarChartSeries;
    for (var i = 0; i < rows.length; i++) {
      expect(bar.points[i].pointStyle?.color, isNotNull,
          reason: 'bar $i colour');
    }
    // Same linear width map as the size-only case, unaffected by the colour.
    expect(bar.points[0].pointStyle?.size, closeTo(0.5, 1e-9));
    expect(bar.points[1].pointStyle?.size, closeTo(1.0, 1e-9));
    expect(bar.points[2].pointStyle?.size, closeTo(1.5, 1e-9));
  });

  test('a non-native size scale raises unsupportedChannelScale', () {
    expect(
      () => BravenChart.of(rows)
          .x(bcat)
          .y(bval)
          .geomBar(
            sizeBy: Channel(bweight, scale: ChannelScale.sqrt),
            sizeEncoding: widths,
          )
          .toSpec()
          .lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.unsupportedChannelScale)),
    );
  });

  test('sizeEncoding without sizeBy raises orphanChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(bcat)
          .y(bval)
          .geomBar(sizeEncoding: widths)
          .toSpec()
          .lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.orphanChannelEncoding)),
    );
  });

  test('sizeBy without sizeEncoding uses the bar default multiplier range', () {
    final lowered = BravenChart.of(rows)
        .x(bcat)
        .y(bval)
        .geomBar(sizeBy: Channel(bweight))
        .toSpec()
        .lower();
    final bar = lowered.series.single as BarChartSeries;
    // default range 0.3 .. 1.0 -> weight 0 -> 0.3, weight 10 -> 1.0.
    expect(bar.points[0].pointStyle?.size, closeTo(0.3, 1e-9));
    expect(bar.points[2].pointStyle?.size, closeTo(1.0, 1e-9));
  });
}
