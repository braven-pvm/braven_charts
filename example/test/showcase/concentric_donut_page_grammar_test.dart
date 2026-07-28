// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the `ConcentricDonutPage` Grammar pane.
///
/// The package's own generator tests can only build charts by hand, and a hand
/// copy of a showcase page proves nothing once the page moves — the exact
/// failure mode that produced a false acceptance claim earlier in this
/// programme. So the claim "the Concentric Donut workbench Grammar pane emits"
/// is asserted HERE, against the page itself: `ConcentricDonutPage` is mounted,
/// the live document is read off the chart's OWN controller, and the generator
/// runs on it.
///
/// Every expectation below is DERIVED from the mounted chart — ring names, ring
/// ids, the mark id, the divergent label rings, the centre — rather than
/// transcribed from the page's source. There is therefore no fixture here to
/// drift, and no drift guard to write: if the page changes what it builds, the
/// expectations change with it, and the guards that assert the page still
/// EXERCISES each carry (per-slice colours, per-ring labels, a styled centre)
/// go red instead of quietly passing about a feature the page dropped.
///
/// This is the page that exercises all four carries at once: per-slice colours,
/// per-ring data labels, the verbatim donut centre, and the concentric ring-id
/// contract.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ACCEPTANCE: the real ConcentricDonutPage emits a COMPLETE '
      'grammar chain', (tester) async {
    await _pumpPage(tester);

    final rings = _liveRings(tester);
    final generated = _generateGrammarFromPage(tester);

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Concentric Donut showcase page must emit a grammar chain, '
          'but got:\n${generated.source}',
    );
    expect(generated.source, contains('.geomDonut('));
    expect(generated.source, contains('ring: (row) => row.ring,'));

    // COMPLETE and warning-free — but the reason is narrower than "the page
    // holds nothing runtime", and stating it that way would be false. The page
    // DOES bind a live `donutCenterBuilder` on this state. What is true is that
    // the capture layer models no widget BUILDER at all, so neither the grammar
    // form nor the config form sees one and neither warns; that is the
    // documented contract rather than a hole this slice opened —
    // `BravenChartPlus.donutCenterBuilder` names the portable centre content as
    // its artifact fallback and says the builder must be rebound after
    // hydration — and the emitted chain does carry that fallback.
    //
    // Both halves are pinned so the qualification stays VISIBLE in the gate: if
    // the page stops binding a runtime centre, or the capture layer starts
    // modelling builders (at which point "complete" would need re-earning),
    // this goes red instead of quietly continuing to claim more than it proves.
    expect(
      _liveChart(tester).donutCenterBuilder,
      isNotNull,
      reason:
          'the page must still bind a runtime centre for the completeness '
          'claim below to be the QUALIFIED one it says it is',
    );
    expect(generated.source, contains('centerContent: DonutCenterContent('));
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // Every live ring reaches the chain as a ring KEY, and the composition's
    // weights are keyed by the live series ids.
    expect(rings.length, greaterThan(1), reason: 'the page must be concentric');
    for (final ring in rings) {
      expect(generated.source, contains("ring: '${ring.name}',"));
      expect(generated.source, contains("'${ring.id}':"));
    }
    expect(generated.source, contains("id: '${_markIdOf(rings)}',"));

    // The page's ring ids CONFORM to '<markId>-<ring name>', so the emitter
    // must recover the mark id from them and emit no explicit `ringIds:` map.
    // That keeps this page on the original, byte-identical path and stops the
    // arbitrary-id fallback from silently doing the work instead.
    expect(generated.source, isNot(contains('ringIds:')));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "the page's PER-SLICE palette reaches the chain as a row channel",
    (tester) async {
      await _pumpPage(tester);

      // Guard first: if the page stops colouring its slices this test must fail
      // as a stale gate, not pass about a carry nothing exercises.
      final rings = _liveRings(tester);
      expect(
        rings.any(
          (ring) => ring.points.any((point) => point.pointStyle?.color != null),
        ),
        isTrue,
        reason: 'the page must still colour its slices per category',
      );

      final generated = _generateGrammarFromPage(tester);
      expect(
        generated.source,
        contains('sliceColor: (row) => row.sliceColor,'),
      );
      // The colours themselves, on the synthesised rows — `sliceColor:` naming a
      // channel that carried nothing would otherwise pass.
      for (final color in <Color>{
        for (final ring in rings)
          for (final point in ring.points)
            if (point.pointStyle?.color != null) point.pointStyle!.color!,
      }) {
        expect(
          generated.source,
          contains('sliceColor: Color(0x${_hex(color)})'),
          reason: 'slice colour $color must reach a row',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("the page's PER-RING label hierarchy reaches the chain", (
    tester,
  ) async {
    await _pumpPage(tester);

    // The page's default label layout is a hierarchy: the outer ring labels
    // outside with category+percentage, the inner rings inside with category
    // only. That divergence is the whole reason `dataLabelsByRing` exists, so
    // it is asserted as a property of the LIVE rings before the emission is.
    final rings = _liveRings(tester);
    final base = rings.first.dataLabels;
    final divergent = <String>[
      for (final ring in rings)
        if (ring.dataLabels != base) ring.name!,
    ];
    expect(
      divergent,
      isNotEmpty,
      reason: 'the page must still give its rings different data labels',
    );

    final generated = _generateGrammarFromPage(tester);
    expect(generated.source, contains('dataLabelsByRing: {'));
    for (final name in divergent) {
      expect(generated.source, contains("'$name': PieDataLabelConfig("));
    }
    // The BASE ring is carried by `dataLabels:` and must NOT be repeated as an
    // override — the override map exists for rings that differ.
    expect(
      generated.source,
      isNot(contains("'${rings.first.name}': PieDataLabelConfig(")),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's STYLED shared centre is carried whole", (
    tester,
  ) async {
    await _pumpPage(tester);

    final chart = _liveChart(tester);
    final center = chart.concentricDonutConfig.centerContent;
    // Guard: the page styles both halves of its centre. Before the centre was
    // carried verbatim this shape was refused outright.
    expect(center.labelStyle, isNotNull);
    expect(center.valueStyle, isNotNull);

    final generated = _generateGrammarFromPage(tester);
    // Sliced out by paren matching rather than asserted with a bare
    // `contains('labelStyle:')`: the emitted theme is full of label styles, so
    // `contains` alone could not tell a centre that carried its styles from one
    // that dropped them.
    final lines = _argumentLines(
      generated.source,
      'centerContent: DonutCenterContent(',
    );
    expect(lines, contains('labelStyle: LabelStyle('));
    expect(lines, contains('valueStyle: LabelStyle('));
    expect(
      lines,
      contains('valueMode: DonutCenterValueMode.${center.valueMode.name},'),
    );
    expect(
      lines,
      contains(
        'fontSize: ${center.labelStyle!.textStyle.fontSize!.toStringAsFixed(1)},',
      ),
    );
    expect(
      lines,
      contains(
        'fontSize: ${center.valueStyle!.textStyle.fontSize!.toStringAsFixed(1)},',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's own Grammar Source pane reaches ready with that "
      'chain', (tester) async {
    // The end-to-end half: not "the generator can be driven over this page's
    // document" but "the pane a user opens shows a chain". It runs the real
    // workbench path — the page's Source display mode, then the Grammar form —
    // and reads the workbench controller's own generated source.
    await _pumpPage(tester);

    final displayMode = find.byKey(
      const ValueKey('concentric-donut-display-mode'),
    );
    final sourceMode = find.descendant(
      of: displayMode,
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
      reason:
          'the Concentric Donut Grammar pane must show a chain, but got:\n'
          '$chain',
    );
    expect(chain, contains('.geomDonut('));
    expect(chain, contains('concentric: ConcentricDonutConfig('));
    expect(chain, contains('dataLabelsByRing: {'));
    expect(
      find.byKey(const ValueKey('chart-grammar-source-code')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ConcentricDonutPage())),
  );
  await tester.pumpAndSettle();
}

BravenChartPlus _liveChart(WidgetTester tester) =>
    tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('concentric-donut-chart')),
    );

List<DonutChartSeries> _liveRings(WidgetTester tester) =>
    _liveChart(tester).series.cast<DonutChartSeries>().toList();

/// The one mark id every live ring id is built from, asserted to be shared.
///
/// Read off the rings rather than transcribed from the page's private constant,
/// so renaming the page's composition cannot leave this gate asserting the old
/// name.
String _markIdOf(List<DonutChartSeries> rings) {
  final ids = <String>{};
  for (final ring in rings) {
    final suffix = '-${ring.name}';
    expect(
      ring.id,
      endsWith(suffix),
      reason: "'${ring.id}' must be '<markId>$suffix'",
    );
    ids.add(ring.id.substring(0, ring.id.length - suffix.length));
  }
  expect(ids, hasLength(1), reason: 'every ring must share one mark id');
  return ids.single;
}

String _hex(Color color) =>
    color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');

/// Runs the grammar generator over the LIVE document of the chart the page
/// mounted, extracted with the page's OWN workbench options.
///
/// The document comes off the chart's own controller through the same
/// `extractSourceDocument` seam the workbench uses — the portable
/// `extractDocument` fails closed on a runtime callback it has no descriptor
/// for, while the source path represents it with a stable placeholder.
ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) {
  final workbench = tester.widget<BravenChartWorkbench>(
    find.byType(BravenChartWorkbench),
  );
  final extracted = _liveChart(
    tester,
  ).bravenChartController!.extractSourceDocument(workbench.documentOptions);
  expect(
    extracted,
    isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
    reason: extracted is ChartArtifactFailure<ChartDocumentSnapshot>
        ? '${extracted.error.code}: ${extracted.error.message}'
        : null,
  );
  final snapshot =
      (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;

  final result = ChartGrammarSourceGenerator.generate(
    snapshot,
    options: const ChartGrammarSourceOptions(
      variableName: 'concentricDonutChart',
    ),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
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
