// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Whole-config parity for the scale verbs.
///
/// PARITY MEANS the same discipline as `plot_lowering_parity_test.dart`: build
/// the axis through the grammar (`.yLog()` / `.xTime()`), lower it, then assert
/// the lowered axis equals — by the package's own whole-config `==` — the
/// hand-written `YAxisConfig` / `XAxisConfig` a user would author today. The
/// scale verbs therefore cannot drift from the config surface they fold onto
/// without turning this file red.
///
/// The `defaultAxis()` helper mirrors the sibling parity files: the axis a
/// chain that declares none ends up with is `YAxisConfig(position: left)`
/// numbered `axis-0` by the lowering.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row(this.v, this.date);

  final double v;
  final DateTime date;
}

double rowV(Row row) => row.v;
DateTime rowDate(Row row) => row.date;

/// A decade-spanning, all-positive dataset a log axis is defined over.
final List<Row> rows = <Row>[
  Row(1, DateTime.utc(2024)),
  Row(10, DateTime.utc(2025)),
  Row(100, DateTime.utc(2026)),
  Row(1000, DateTime.utc(2027)),
];

/// The axis the lowering synthesizes when a spec declares none — identical to
/// the sibling parity files' `defaultAxis()`.
YAxisConfig defaultAxis() =>
    YAxisConfig(position: YAxisPosition.left).copyWith(id: 'axis-0');

void main() {
  group('parity: yLog folds a whole log axis', () {
    test('.yLog(base: 2) lowers to the hand-built log YAxisConfig', () {
      final lowered = BravenChart.of(rows)
          .x(rowV)
          .y(rowV, label: 'P')
          .geomLine()
          .yLog(base: 2)
          .toSpec()
          .lower();

      // Whole-config equality against the axis a user would hand-write today:
      // the synthesized left axis, numbered axis-0, carrying the .y() label and
      // the folded log scale — NOT a field-by-field spot check.
      final expected = defaultAxis().copyWith(
        scaleType: AxisScaleType.log,
        logBase: 2,
        label: 'P',
      );
      expect(lowered.yAxes.single, expected);
      expect(lowered.yAxes, <YAxisConfig>[expected]);
      // The series carries the same whole axis config.
      expect(lowered.series.single.yAxisConfig, expected);
    });

    test('.yLog() defaults the folded log axis to base 10', () {
      final lowered = BravenChart.of(rows)
          .x(rowV)
          .y(rowV, label: 'P')
          .geomLine()
          .yLog()
          .toSpec()
          .lower();

      final expected = defaultAxis().copyWith(
        scaleType: AxisScaleType.log,
        logBase: 10,
        label: 'P',
      );
      expect(lowered.yAxes.single, expected);
    });
  });

  group('parity: xTime folds a whole time axis + epoch-millis points', () {
    test('.xTime(...) lowers to the hand-built time XAxisConfig', () {
      final lowered = BravenChart.of(rows)
          .xTime(rowDate, label: 'Date')
          .y(rowV)
          .geomLine()
          .toSpec()
          .lower();

      // Whole-config equality against the axis a user would hand-write today:
      // an X axis carrying the .xTime() label and the time scale, every other
      // field at its default.
      const expected = XAxisConfig(
        label: 'Date',
        scaleType: AxisScaleType.time,
      );
      expect(lowered.xAxis, expected);
    });

    test('.xTime wraps each DateTime to its millisecondsSinceEpoch', () {
      final lowered = BravenChart.of(rows)
          .xTime(rowDate)
          .y(rowV)
          .geomLine()
          .toSpec()
          .lower();

      expect(
        (lowered.series.single as LineChartSeries).points.map((p) => p.x),
        rows.map((row) => row.date.millisecondsSinceEpoch.toDouble()),
      );
      // With no label the synthesized time axis is the bare time config.
      expect(
        lowered.xAxis,
        const XAxisConfig(scaleType: AxisScaleType.time),
      );
    });
  });
}
