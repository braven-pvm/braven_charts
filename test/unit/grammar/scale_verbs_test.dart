// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The scale verbs fold an axis scale type onto the synthesized axis config,
/// surviving lowering.
///
/// `.xLog()`/`.yLog()` set no half-built axis: they record scale intent that
/// `toSpec()` folds onto whatever axis it synthesizes, so the `.x(label:)` /
/// `.y(label:)` labels still reach the config.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row(this.v);

  final double v;
}

double rowV(Row row) => row.v;

const rows = <Row>[Row(1), Row(10), Row(100), Row(1000)];

void main() {
  test('.xLog() makes the synthesized x axis logarithmic, base 10', () {
    final lowered =
        BravenChart.of(rows).x(rowV).y(rowV).geomLine().xLog().toSpec().lower();
    expect(lowered.xAxis?.scaleType, AxisScaleType.log);
    expect(lowered.xAxis?.logBase, 10);
  });

  test('.yLog(base: 2) sets the default y axis log base 2 and keeps its label',
      () {
    final lowered = BravenChart.of(rows)
        .x(rowV)
        .y(rowV, label: 'P')
        .geomLine()
        .yLog(base: 2)
        .toSpec()
        .lower();
    expect(lowered.yAxes.single.scaleType, AxisScaleType.log);
    expect(lowered.yAxes.single.logBase, 2);
    expect(lowered.yAxes.single.label, 'P');
  });
}
