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
/// page's radial data labels carry live formatter callbacks, and a callback has
/// no literal form, so it is emitted as a named placeholder with a
/// `runtimeValueOmitted` warning.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ACCEPTANCE: the real PieChartsPage emits a grammar chain', (
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
          'the Pie showcase page must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(generated.source, contains('.geomPie('));

    // The one thing that cannot be a literal, stated honestly rather than
    // dropped: the page's radial label formatters are live callbacks, so the
    // chain is real but deliberately not complete.
    expect(generated.isComplete, isFalse);
    expect(
      generated.warnings.map((warning) => warning.code),
      contains(ChartSourceWarningCodes.runtimeValueOmitted),
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
    find.byKey(const ValueKey('pie-showcase-chart')),
  );
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
