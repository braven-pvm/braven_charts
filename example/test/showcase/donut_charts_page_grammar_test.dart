// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the `DonutChartsPage` Grammar pane.
///
/// The package's own generator tests can only build charts by hand, and a hand
/// copy of a showcase page proves nothing once the page moves — the exact
/// failure mode that produced a false acceptance claim earlier in this
/// programme. So the claim "the Donut workbench Grammar pane emits" is asserted
/// HERE, against the page itself: `DonutChartsPage` is mounted, the live
/// document is read off the chart's OWN controller, and the generator runs on
/// it. There is no fixture to drift.
///
/// The expected verdict is a real chain that is deliberately NOT complete, on
/// TWO counts — not one, as this file claimed until it was checked against the
/// generator. The page binds a live `valueFormatter` on its donut CENTRE in
/// every knob state, and a live `valueFormatter` AND `percentageFormatter` on
/// its radial DATA LABELS. A callback has no literal form, so each is emitted
/// as a named placeholder, and the generator reports two `runtimeValueOmitted`
/// warnings:
///
/// 1. `$.series[0].style.centerContent.valueFormatter` — the centre formatter,
/// 2. `$.series[0].style.dataLabels` — the label formatters, one warning
///    covering both of them, leaving two placeholder comments.
///
/// That is the established contract for runtime values, and the state
/// `PieChartsPage` already ships in. The gate pins that WHOLE set, so a third
/// omission appearing cannot slip past it as a `contains` would.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package's own compile gate, reached by path because it lives in the
// package's `test/` tree rather than its `lib/` and so has no `package:` URI.
// Copying it here instead would fork the format-then-analyze recipe the helper
// exists to stop forking.
import '../../../test/helpers/generated_source_compile.dart';

void main() {
  testWidgets('ACCEPTANCE: the real DonutChartsPage emits a grammar chain, '
      'incomplete only because its centre AND label formatters are live '
      'callbacks', (tester) async {
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
          'the Donut showcase page must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(generated.source, contains('.geomDonut('));
    // The per-slice palette the page passes as `sliceColors`, reversed onto its
    // own row channel.
    expect(generated.source, contains('sliceColor: (row) => row.sliceColor,'));

    // The centre, asserted as a WHOLE argument rather than by fragments: the
    // emitted theme is full of `labelStyle:` lines, so `contains` alone could
    // not tell a centre that carried its styles from one that dropped them.
    // The page's default centre preset is theme-driven (both styles null) and
    // its default value mode is `selectedOrTotal`, which the page pairs with a
    // null label — so this block is exactly that mode plus the formatter
    // placeholder.
    expect(series.centerContent.valueFormatter, isNotNull);
    final centerLines = _argumentLines(
      generated.source,
      'center: DonutCenterContent(',
    );
    expect(centerLines, <String>[
      'center: DonutCenterContent(',
      'valueMode: DonutCenterValueMode.selectedOrTotal,',
      '// valueFormatter: (value) => ..., // Supply application formatting.',
      ')',
    ]);

    // The SECOND runtime omission, which this gate did not name until it was
    // checked against the generator: the page's radial data labels bind BOTH
    // formatter callbacks, and each has to leave its own named placeholder.
    // Guarded off the live series first, so this cannot go on passing about
    // formatters the page stopped binding — and sliced out by paren matching,
    // because the centre emits a `// valueFormatter:` line too and a bare
    // `contains` could not tell the two apart.
    expect(series.dataLabels.valueFormatter, isNotNull);
    expect(series.dataLabels.percentageFormatter, isNotNull);
    final labelLines = _argumentLines(
      generated.source,
      'dataLabels: PieDataLabelConfig(',
    );
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

    // The warning state as the WHOLE set, not a `contains`: those two
    // callbacks are the only things this page cannot carry, so a THIRD
    // omission appearing is a regression and must not slip past this gate.
    // The PATHS are pinned alongside the codes, so the pair also cannot
    // silently collapse into two warnings about the same value.
    expect(generated.isComplete, isFalse);
    expect(
      generated.warnings
          .map((warning) => '${warning.code} @ ${warning.path}')
          .toList(),
      <String>[
        '${ChartSourceWarningCodes.runtimeValueOmitted} @ '
            r'$.series[0].style.centerContent.valueFormatter',
        '${ChartSourceWarningCodes.runtimeValueOmitted} @ '
            r'$.series[0].style.dataLabels',
      ],
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
        fixtureName: 'showcase_donut_grammar',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's STYLED centre preset emits its two label styles too", (
    tester,
  ) async {
    // The default preset leaves both centre styles null, so on its own it would
    // not prove the styles survive — only that the formatter no longer blocks.
    // The `Compact` preset sets a real `labelStyle` AND `valueStyle`, which is
    // the shape that was refused outright before the centre was carried whole.
    await _pumpPage(tester);
    await _selectCenterStyle(tester, 'Compact');

    final generated = _generateGrammarFromPage(tester);
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Donut page must still emit with a styled centre, but got:\n'
          '${generated.source}',
    );

    final center = _argumentLines(
      generated.source,
      'center: DonutCenterContent(',
    );
    expect(center, contains('labelStyle: LabelStyle('));
    expect(center, contains('valueStyle: LabelStyle('));
    // The values, not just the argument names: the compact preset's label is
    // 10pt slate and its value is 18pt near-black.
    expect(center, contains('fontSize: 10.0,'));
    expect(center, contains('fontSize: 18.0,'));
    expect(center, contains('fontWeight: FontWeight.w700,'));
    expect(
      center,
      contains(
        '// valueFormatter: (value) => ..., // Supply application formatting.',
      ),
    );
    expect(generated.isComplete, isFalse);
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
      reason: 'the Donut Grammar pane must show a chain, but got:\n$chain',
    );
    expect(chain, contains('.geomDonut('));
    expect(chain, contains('center: DonutCenterContent('));
    expect(chain, contains('dataLabels: PieDataLabelConfig('));
    // BOTH omissions reach the pane a user actually opens, not just the
    // generator this file drives directly.
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
    const MaterialApp(home: Scaffold(body: DonutChartsPage())),
  );
  await tester.pumpAndSettle();
}

BravenChartPlus _liveChart(WidgetTester tester) =>
    tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('donut-showcase-chart')),
    );

/// The one donut series the page mounted.
///
/// Read off the widget rather than rebuilt from the page's private dataset
/// table, so the guards derived from it describe what is actually on screen.
DonutChartSeries _liveSeries(WidgetTester tester) =>
    _liveChart(tester).series.single as DonutChartSeries;

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
    options: const ChartGrammarSourceOptions(variableName: 'donutChart'),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

Future<void> _selectCenterStyle(WidgetTester tester, String label) async {
  final centerStyle = find.byKey(const ValueKey('donut-center-style'));
  await tester.scrollUntilVisible(
    centerStyle,
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: centerStyle, matching: find.text('Theme default')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// The argument literal of [source] that starts at [opening], one trimmed line
/// per entry.
///
/// A bare `contains('labelStyle:')` proves nothing about the CENTRE — the
/// emitted theme is full of label styles — and a bare
/// `contains('// valueFormatter:')` proves nothing about the LABELS, because
/// the centre emits one of those too. So each argument's own list is sliced out
/// by paren matching and asserted on directly.
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
