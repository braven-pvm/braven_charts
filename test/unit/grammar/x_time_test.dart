// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// `.xTime` binds a `DateTime` field to the X channel as epoch-milliseconds and
/// marks the synthesized X axis as a time scale.
///
/// There is no lowering-site `DateTime` branch: every mark family already does
/// `mark.x(row).toDouble()`, and the wrapped accessor returns the `num` millis,
/// so the point positions are the raw epoch values.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row(this.date);

  final DateTime date;
}

void main() {
  test('.xTime wraps a DateTime field into epoch-millis x and a time axis', () {
    final d = DateTime.utc(2026, 1, 1);
    final rows = <Row>[Row(d)];
    final lowered = BravenChart.of(rows)
        .xTime((r) => r.date)
        .y((r) => 1)
        .geomLine()
        .toSpec()
        .lower();
    expect(lowered.xAxis?.scaleType, AxisScaleType.time);
    expect(
      (lowered.series.single as LineChartSeries).points.single.x,
      d.millisecondsSinceEpoch.toDouble(),
    );
  });
}
