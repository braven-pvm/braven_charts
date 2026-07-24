// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Scale diagnostics: a log axis rejects a non-positive value it would have to
/// position (data-dependent), and a time/log axis rejects a category mode on
/// the same axis (structural).
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  Row(this.v, this.date);

  final double v;
  final DateTime date;
}

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  final rows = <Row>[
    Row(1, DateTime.utc(2024)),
    Row(2, DateTime.utc(2025)),
  ];

  test('a log axis with a value <= 0 raises nonPositiveLogValue', () {
    expect(
      () => BravenChart.of(<Row>[Row(0, DateTime.utc(2024))])
          .x((r) => r.v)
          .y((r) => r.v)
          .geomLine()
          .yLog()
          .toSpec()
          .lower(),
      throwsGrammarCode(GrammarDiagnosticCode.nonPositiveLogValue),
    );
  });

  test('time + category on the same x raises conflictingAxisMode', () {
    expect(
      () => BravenChart.of(rows)
          .xTime((r) => r.date)
          .y((r) => 1)
          .geomLine()
          .xAxis(
            const XAxisConfig(
              categoryAxis: CategoryAxisConfig(categories: ['a']),
            ),
          )
          .toSpec()
          .lower(),
      throwsGrammarCode(GrammarDiagnosticCode.conflictingAxisMode),
    );
  });

  test('log + category on the same x raises conflictingAxisMode', () {
    expect(
      () => BravenChart.of(rows)
          .x((r) => r.v)
          .y((r) => 1)
          .geomLine()
          .xLog()
          .xAxis(
            const XAxisConfig(
              categoryAxis: CategoryAxisConfig(categories: ['a']),
            ),
          )
          .toSpec()
          .lower(),
      throwsGrammarCode(GrammarDiagnosticCode.conflictingAxisMode),
    );
  });

  test('time + an EMPTY category axis (label-styling carrier) is honored, '
      'not a conflict', () {
    final lowered = BravenChart.of(rows)
        .xTime((r) => r.date)
        .y((r) => 1)
        .geomLine()
        .xAxis(
          const XAxisConfig(
            categoryAxis: CategoryAxisConfig(
              categories: [],
              labelRotationDegrees: 45,
            ),
          ),
        )
        .toSpec()
        .lower();

    // The empty CategoryAxisConfig has no discrete slots, so it does not
    // contradict the numeric time positioning: the scale stays time and the
    // 45deg label rotation it carries is honored.
    expect(lowered.xAxis!.scaleType, AxisScaleType.time);
    expect(lowered.xAxis!.isCategorical, isFalse);
    expect(lowered.xAxis!.effectiveTickLabelRotationDegrees, 45);
  });

  test('log + an EMPTY category axis (label-styling carrier) is honored, '
      'not a conflict', () {
    final lowered = BravenChart.of(rows)
        .x((r) => r.v)
        .y((r) => 1)
        .geomLine()
        .xLog()
        .xAxis(
          const XAxisConfig(
            categoryAxis: CategoryAxisConfig(
              categories: [],
              labelRotationDegrees: 45,
            ),
          ),
        )
        .toSpec()
        .lower();

    expect(lowered.xAxis!.scaleType, AxisScaleType.log);
    expect(lowered.xAxis!.isCategorical, isFalse);
    expect(lowered.xAxis!.effectiveTickLabelRotationDegrees, 45);
  });
}
