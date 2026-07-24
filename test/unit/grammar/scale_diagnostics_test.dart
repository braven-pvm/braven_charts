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
}
