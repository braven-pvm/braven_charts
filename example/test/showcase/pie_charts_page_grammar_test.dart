// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the `PieChartsPage` Grammar pane.
///
/// `doc/chart_grammar.md` has claimed for two slices that "PieChartsPage is the
/// third radial page and it *does* emit" — a claim nothing asserted. This slice
/// folds pie into the acceptance gate, and a gate claim with no test behind it
/// is exactly the fixtures-vs-real-page failure this programme has already made
/// once. So the claim is asserted HERE, the same way the donut and concentric
/// pages assert theirs: the real page is mounted, the live document is read off
/// the chart's OWN controller, and the generator runs on it. There is no
/// fixture to drift.
///
/// The expected verdict is a real chain that is deliberately NOT complete: the
/// page's radial data labels carry live formatter callbacks — a
/// `valueFormatter` and a `percentageFormatter` — and a callback has no literal
/// form, so each is emitted as a named placeholder. Both are reported by ONE
/// `runtimeValueOmitted` warning at `$.series[0].style.dataLabels`, and that
/// single-warning set is pinned whole. (The sibling donut gate carries TWO,
/// because `DonutChartsPage` binds a centre formatter as well; the counts are
/// genuinely different and neither gate borrows the other's.)
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package's own compile gate, reached by path because it lives in the
// package's `test/` tree rather than its `lib/` and so has no `package:` URI.
// Copying it here instead would fork the format-then-analyze recipe the helper
// exists to stop forking.
import '../../../test/helpers/generated_source_compile.dart';

void main() {
  testWidgets('ACCEPTANCE: the real PieChartsPage emits a grammar chain, '
      'incomplete only because its label formatters are live callbacks', (
    tester,
  ) async {
    await _pumpPage(tester);

    final series = _liveSeries(tester);
    final generated = _generateGrammarFromPage(tester);

    // Matched on the ASSIGNMENT: the refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Pie showcase page must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(generated.source, contains('.geomPie('));

    // The mark's IDENTITY and its channels. Every expectation below is DERIVED
    // from the mounted series rather than transcribed from the page's source,
    // so switching the page's dataset knob moves the expectation with it
    // instead of leaving this gate asserting a name nothing builds.
    expect(series.name, isNotNull);
    expect(series.unit, isNotNull);
    expect(generated.source, contains("id: '${series.id}',"));
    expect(generated.source, contains("name: '${series.name}',"));
    expect(generated.source, contains("unit: '${series.unit}',"));
    expect(generated.source, contains('category: (row) => row.category,'));
    expect(generated.source, contains('value: (row) => row.value,'));

    // The DATA, not just the channels naming it: a chain whose rows came out
    // empty would satisfy every assertion above.
    expect(series.points, isNotEmpty);
    for (final point in series.points) {
      expect(
        generated.source,
        contains("category: '${point.label}',"),
        reason: "the '${point.label}' slice must reach a row",
      );
    }

    // The page's DEFAULT label layout is the SPLIT one — an outside category
    // callout paired with an inside percentage badge in its own callout style —
    // and that whole config has to survive the round trip. Guarded off the live
    // series first, so this cannot go on passing about a layout the page
    // stopped building.
    final labels = series.dataLabels;
    expect(
      labels.secondaryContent,
      isNotNull,
      reason: 'the page must still build its split label layout',
    );
    expect(labels.secondaryCalloutStyle?.textStyle.fontSize, isNotNull);

    // Sliced out by paren matching rather than asserted with a bare
    // `contains`: the emitted theme is full of label styles and font sizes, so
    // `contains` alone could not tell labels that carried their config from
    // ones that dropped it.
    final labelLines = _argumentLines(
      generated.source,
      'dataLabels: PieDataLabelConfig(',
    );
    expect(
      labelLines,
      contains('content: PieDataLabelContent.${labels.content.name},'),
    );
    expect(
      labelLines,
      contains(
        'secondaryContent: '
        'PieDataLabelContent.${labels.secondaryContent!.name},',
      ),
    );
    expect(
      labelLines,
      contains(
        'secondaryPosition: '
        'PieDataLabelPosition.${labels.secondaryPosition.name},',
      ),
    );
    expect(labelLines, contains('secondaryCalloutStyle: LabelStyle('));
    expect(
      labelLines,
      contains(
        'fontSize: '
        '${labels.secondaryCalloutStyle!.textStyle.fontSize!.toStringAsFixed(1)},',
      ),
    );

    // The page's slice colours come from the THEME palette, not from per-point
    // overrides, so this page carries no per-slice colour and emits no
    // `sliceColor` channel. BOTH halves are asserted outright.
    //
    // This used to be one conditional — `expect(sourceHasChannel,
    // pageHasColours)` — and with this page on the theme palette it ran as
    // `expect(false, false)`. It pinned only that the two AGREE, which is a
    // fact about the emitter, and said nothing whatever about this page: it
    // would have passed just as happily had the page grown a per-slice colour
    // knob and the emitter reversed it. Stated as two positive expectations,
    // the first goes red the day the page stops taking its colours from the
    // theme — a stale gate reported as one, which is what the sibling guards
    // in the concentric gate do — and the second pins the emitted text.
    expect(
      series.points.where((point) => point.pointStyle?.color != null),
      isEmpty,
      reason:
          'the page must still take its slice colours from the theme palette '
          'for the no-channel expectation below to mean anything',
    );
    expect(generated.source, isNot(contains('sliceColor:')));

    // The things that cannot be literals, stated honestly rather than dropped.
    // The page binds BOTH formatters, and each has to leave a named
    // placeholder — a chain that silently dropped one would still be
    // "incomplete" and still carry the same single warning.
    expect(labels.valueFormatter, isNotNull);
    expect(labels.percentageFormatter, isNotNull);
    expect(
      labelLines,
      contains(
        '// valueFormatter: (value) => ..., // Supply application formatting.',
      ),
    );
    expect(
      labelLines,
      contains(
        '// percentageFormatter: (share) => ..., '
        '// Supply application formatting.',
      ),
    );

    // The warning state as the WHOLE set, not a `contains`: those formatters
    // are the only thing this page cannot carry, so a SECOND omission
    // appearing is a regression and must not slip past this gate.
    expect(generated.isComplete, isFalse);
    expect(
      generated.warnings.map((warning) => warning.code).toList(),
      <String>[ChartSourceWarningCodes.runtimeValueOmitted],
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );

    // The FLOOR. Every assertion above reads the emitted TEXT, and text
    // assertions cannot tell a chain that would compile from one that only
    // looks right — an ambiguous import, a parameter the builder does not have,
    // a dropped paren all read the same to `contains`. The polar gate has held
    // this floor since that pane shipped; a chain a user copies out of the
    // Workbench has to compile, so this one holds it too.
    //
    // "Incomplete" is about a runtime callback that has no literal form, and
    // the placeholder it leaves is a COMMENT — so an incomplete chain still has
    // to compile, and this gate is what says so.
    //
    // Real subprocesses, so the same `runAsync` escape hatch the package-side
    // callers document applies here.
    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_pie_grammar',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's own Grammar Source pane reaches ready with that "
      'chain', (tester) async {
    // The end-to-end half: not "the generator can be driven over this page's
    // document" but "the pane a user opens shows a chain". It runs the real
    // workbench path — Source mode, Grammar form — and reads the workbench
    // controller's own generated source.
    await _pumpPage(tester);

    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    final sourceMode = find.descendant(
      of: switcher,
      matching: find.text('Source'),
    );
    await tester.ensureVisible(sourceMode);
    await tester.pump();
    await tester.tap(sourceMode);
    await tester.pumpAndSettle();

    final formToggle = find.byKey(const ValueKey('chart-source-form-toggle'));
    await tester.ensureVisible(formToggle);
    await tester.pump();
    await tester.tap(
      find.descendant(of: formToggle, matching: find.text('Grammar')),
    );
    await tester.pumpAndSettle();

    final workbench = tester.widget<BravenChartWorkbench>(
      find.byType(BravenChartWorkbench),
    );
    expect(
      workbench.workbenchController!.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    final chain = workbench.workbenchController!.generatedSource!.source;
    expect(
      chain,
      contains('= BravenChart.of('),
      reason: 'the Pie Grammar pane must show a chain, but got:\n$chain',
    );
    expect(chain, contains('.geomPie('));
    expect(chain, contains('dataLabels: PieDataLabelConfig('));
    expect(chain, contains('secondaryContent: PieDataLabelContent.'));
    expect(chain, contains('// valueFormatter:'));
    expect(chain, contains('// percentageFormatter:'));
    expect(
      find.byKey(const ValueKey('chart-grammar-source-code')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: PieChartsPage())),
  );
  await tester.pumpAndSettle();
}

BravenChartPlus _liveChart(WidgetTester tester) => tester
    .widget<BravenChartPlus>(find.byKey(const ValueKey('pie-showcase-chart')));

/// The one pie series the page mounted.
///
/// Read off the widget rather than rebuilt from the page's private dataset
/// table, so the expectations derived from it describe what is actually on
/// screen.
PieChartSeries _liveSeries(WidgetTester tester) =>
    _liveChart(tester).series.single as PieChartSeries;

/// Runs the grammar generator over the LIVE document of the chart the page
/// mounted.
///
/// The document comes off the chart's own controller through the same
/// `extractSourceDocument` seam the workbench uses — the portable
/// `extractDocument` fails closed on a runtime formatter it has no descriptor
/// for, while the source path represents it with a stable placeholder
/// descriptor.
ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) {
  final chart = _liveChart(tester);
  final extracted = chart.bravenChartController!.extractSourceDocument();
  expect(extracted, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  final snapshot =
      (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;

  final result = ChartGrammarSourceGenerator.generate(
    snapshot,
    options: const ChartGrammarSourceOptions(variableName: 'pieChart'),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

/// The argument literal of [source] that starts at [opening], one trimmed line
/// per entry.
///
/// A bare `contains('fontSize: 11.0,')` proves nothing about the LABELS — the
/// emitted theme is full of font sizes — so the argument's own list is sliced
/// out by paren matching and asserted on directly.
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
