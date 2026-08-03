// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the selection lab's RANGE AREA family Grammar pane.
///
/// Asserted against the PAGE, never a transcription: `SelectionShowcasePage` is
/// mounted, its range-area family is selected through the real family picker,
/// the live document is read off that chart's OWN controller, and the grammar
/// generator runs on it.
///
/// This family is the deliverable of roadmap item 1b-1. The `RangeAreaChartsPage`
/// is NOT: every band there carries a non-default `pathAnimation` and six of
/// seven a `fillGradient`, both roadmap 1d and both named refusals on `AreaMark`
/// today. This lab's bands diverge only on range-area-native fields, which is
/// exactly why it is the honest measure of what the mark closes.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package's own compile gate, reached by path because it lives in the
// package's `test/` tree rather than its `lib/` and so has no `package:` URI.
// Copying it here instead would fork the format-then-analyze recipe the helper
// exists to stop forking.
import '../../../test/helpers/generated_source_compile.dart';

void main() {
  testWidgets('ACCEPTANCE: the selection lab RANGE AREA family emits a '
      'COMPLETE grammar chain', (tester) async {
    await _pumpFamily(tester, 'rangeArea');

    final chart = _liveChart(tester);
    final bands = chart.series.whereType<RangeAreaChartSeries>().toList();
    final generated = _generateGrammar(
      tester,
      chart,
      'rangeAreaSelectionChart',
    );

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          "the selection lab's range-area family must emit a grammar chain, "
          'but got:\n${generated.source}',
    );
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // The family is TWO bands plus a centre line, and all three must reach the
    // chain — a one-band assertion would pass on a chain that dropped the other.
    expect(bands, hasLength(2), reason: 'the family must mount two bands');
    expect('.geomRangeArea('.allMatches(generated.source).length, bands.length);
    expect(generated.source, contains('.geomLine('));
    for (final band in bands) {
      expect(generated.source, contains("id: '${band.id}',"));
      expect(generated.source, contains("name: '${band.name}',"));
    }

    // Every point in this lab is keyed — selection is expressed against those
    // keys — so a chain that dropped `pointKey:` would render identically and
    // select differently.
    expect(generated.source, contains('pointKey: (row) =>'));

    // The FLOOR. Every assertion above reads the emitted TEXT, and text
    // assertions cannot tell a chain that would compile from one that only
    // looks right.
    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_selection_range_area_grammar',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the bands' own styling survives the reversal", (tester) async {
    await _pumpFamily(tester, 'rangeArea');

    final chart = _liveChart(tester);
    final first = chart.series.whereType<RangeAreaChartSeries>().first;
    final generated = _generateGrammar(
      tester,
      chart,
      'rangeAreaSelectionChart',
    );

    // Scoped to the FIRST band's OWN argument list, not the whole source: this
    // family mounts two bands, so a `contains` over the source would be
    // satisfied by a value emitted for the other one.
    final lines = _argumentLines(generated.source, '.geomRangeArea(');

    // Read off the LIVE series, so this cannot drift from the page.
    expect(
      lines,
      contains('interpolation: LineInterpolation.${first.interpolation.name},'),
    );
    // Compared as a VALUE parsed back out of the emitted text, not as a
    // formatted string: the assertion is about what the chain would rebuild,
    // and it must not go red over a literal-formatting change.
    expect(_emittedNumber(lines, 'fillOpacity'), first.fillOpacity);
    expect(
      lines,
      contains('showBoundaryMarkers: ${first.showBoundaryMarkers},'),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFamily(WidgetTester tester, String family) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: SelectionShowcasePage())),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('selection-family-$family')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

BravenChartPlus _liveChart(WidgetTester tester) =>
    tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-rangeArea')),
    );

/// Runs the grammar generator over [chart]'s LIVE document, extracted with the
/// page's OWN workbench options.
ChartGeneratedSource _generateGrammar(
  WidgetTester tester,
  BravenChartPlus chart,
  String variableName,
) {
  final workbench = tester.widget<BravenChartWorkbench>(
    find.byKey(const ValueKey('selection-workbench')),
  );
  final extracted = chart.bravenChartController!.extractSourceDocument(
    workbench.documentOptions,
  );
  expect(
    extracted,
    isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    reason: extracted is ChartArtifactFailure<ChartDocumentSnapshot>
        ? '${extracted.error.code}: ${extracted.error.message}'
        : null,
  );
  final result = ChartGrammarSourceGenerator.generate(
    (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value,
    options: ChartGrammarSourceOptions(variableName: variableName),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

/// The numeric value emitted for the `[name]:` argument among [lines].
double _emittedNumber(List<String> lines, String name) {
  final line = lines.firstWhere(
    (entry) => entry.startsWith('$name: '),
    orElse: () => fail('no "$name" among the emitted arguments:\n$lines'),
  );
  return double.parse(
    line.substring(name.length + 2).replaceAll(',', '').trim(),
  );
}

/// The argument literal of [source] that starts at [opening], one trimmed line
/// per entry.
List<String> _argumentLines(String source, String opening) {
  final start = source.indexOf(opening);
  expect(
    start,
    isNonNegative,
    reason: 'no "$opening" argument was emitted in:\n$source',
  );
  var depth = 0;
  for (var index = start + opening.length - 1; index < source.length; index++) {
    if (source[index] == '(') depth += 1;
    if (source[index] == ')') {
      depth -= 1;
      if (depth == 0) {
        return source
            .substring(start, index + 1)
            .split('\n')
            .map((line) => line.trim())
            .toList();
      }
    }
  }
  fail('the "$opening" argument is unbalanced in:\n$source');
}
