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

/// A range-area row: either bound may be null, so a row can be a GAP.
class BandRow {
  const BandRow(this.t, this.low, this.high);

  final double t;
  final double? low;
  final double? high;
}

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

Matcher throwsGrammarCodeNaming(GrammarDiagnosticCode code, String markId) =>
    throwsA(
      isA<GrammarSpecException>()
          .having((e) => e.code, 'code', code)
          .having((e) => e.message, 'message', contains(markId)),
    );

LoweredPlot lowerBand(List<BandRow> rows) => BravenChart.of(rows)
    .x((r) => r.t)
    .geomRangeArea(id: 'band', low: (r) => r.low, high: (r) => r.high)
    .yLog()
    .toSpec()
    .lower();

void main() {
  final rows = <Row>[Row(1, DateTime.utc(2024)), Row(2, DateTime.utc(2025))];

  test('a log axis with a value <= 0 raises nonPositiveLogValue', () {
    expect(
      () => BravenChart.of(<Row>[
        Row(0, DateTime.utc(2024)),
      ]).x((r) => r.v).y((r) => r.v).geomLine().yLog().toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.nonPositiveLogValue),
    );
  });

  test('a range-area band with a non-positive LOW bound on a log y raises '
      'nonPositiveLogValue naming the mark', () {
    expect(
      () => lowerBand(const <BandRow>[BandRow(0, 10, 20), BandRow(1, 0, 30)]),
      throwsGrammarCodeNaming(
        GrammarDiagnosticCode.nonPositiveLogValue,
        'band',
      ),
    );
  });

  test('a range-area band with a non-positive HIGH bound on a log y raises '
      'nonPositiveLogValue naming the mark', () {
    expect(
      () => lowerBand(const <BandRow>[
        BandRow(0, 10, 20),
        // Low stays positive, so only the high bound can trip the check.
        BandRow(1, 5, -1),
      ]),
      throwsGrammarCodeNaming(
        GrammarDiagnosticCode.nonPositiveLogValue,
        'band',
      ),
    );
  });

  test('a range-area GAP on a log y does NOT raise — a gap positions '
      'nothing', () {
    final lowered = lowerBand(const <BandRow>[
      BandRow(0, 10, 20),
      BandRow(1, null, null),
      BandRow(2, 30, 40),
    ]);
    expect(lowered.series, hasLength(1));
    expect(lowered.yAxes.single.scaleType, AxisScaleType.log);
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
