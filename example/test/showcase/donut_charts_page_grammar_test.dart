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
/// The expected verdict is a real chain that is deliberately NOT complete. The
/// page's centre carries a live `valueFormatter` in every knob state, and a
/// callback has no literal form: it is emitted as a named placeholder with a
/// `runtimeValueOmitted` warning. That is the established contract for runtime
/// values, and the state `PieChartsPage` already ships in.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ACCEPTANCE: the real DonutChartsPage emits a grammar chain, '
      'incomplete only because its centre formatter is a live callback', (
    tester,
  ) async {
    await _pumpPage(tester);

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
    expect(_centerArgumentLines(generated.source), <String>[
      'center: DonutCenterContent(',
      'valueMode: DonutCenterValueMode.selectedOrTotal,',
      '// valueFormatter: (value) => ..., // Supply application formatting.',
      ')',
    ]);

    // The one thing that cannot be a literal, stated honestly rather than
    // dropped: a placeholder, a warning, and `isComplete == false`.
    expect(generated.isComplete, isFalse);
    expect(
      generated.warnings.map((warning) => warning.code),
      contains(ChartSourceWarningCodes.runtimeValueOmitted),
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

    final center = _centerArgumentLines(generated.source);
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
    expect(chain, contains('// valueFormatter:'));
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

/// Runs the grammar generator over the LIVE document of the chart the page
/// mounted.
///
/// The document comes off the chart's own controller through the same
/// `extractSourceDocument` seam the workbench uses — the portable
/// `extractDocument` fails closed on a runtime formatter it has no descriptor
/// for, while the source path represents it with a stable placeholder
/// descriptor.
ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) {
  final chart = tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('donut-showcase-chart')),
  );
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

/// The `center: DonutCenterContent(...)` argument of [source], one trimmed line
/// per entry.
///
/// A bare `contains('labelStyle:')` proves nothing about the CENTRE — the
/// emitted theme is full of label styles — so the centre's own argument list is
/// sliced out by paren matching and asserted on directly.
List<String> _centerArgumentLines(String source) {
  const opening = 'center: DonutCenterContent(';
  final start = source.indexOf(opening);
  expect(
    start,
    isNonNegative,
    reason: 'no center: argument was emitted in:\n$source',
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
  fail('the center: argument is unbalanced in:\n$source');
}
