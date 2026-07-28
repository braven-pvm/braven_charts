// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the selection lab's CONCENTRIC DONUT family Grammar pane.
///
/// Asserted against the PAGE, never a transcription: `SelectionShowcasePage` is
/// mounted, its concentric family is selected through the real family picker,
/// the live document is read off that chart's OWN controller, and the grammar
/// generator runs on it. Every expectation is derived from the mounted chart —
/// ring names, the shared mark id, the composition knobs — so there is no
/// fixture here to drift and no drift guard to write.
///
/// The lab reaches the Grammar pane through a fix this slice made to the PAGE,
/// not to the generator, and the last test pins the difference. The lab draws
/// read-only projection overlays and so authored `interactiveAnnotations:
/// false` unconditionally — including on every radial family, which never draws
/// one. `BravenPlot` cannot express that flag and the captured document records
/// it, so the refusal was correct and stays correct: the page now authors the
/// non-default only while an annotation exists for it to govern.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ACCEPTANCE: the selection lab CONCENTRIC family emits a '
      'COMPLETE grammar chain', (tester) async {
    await _pumpFamily(tester, 'concentricDonut');

    final rings = _liveRings(tester);
    final generated = _generateGrammarFromPage(tester);

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          "the selection lab's concentric family must emit a grammar chain, "
          'but got:\n${generated.source}',
    );
    expect(generated.source, contains('.geomDonut('));
    expect(generated.source, contains('ring: (row) => row.ring,'));
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // Every live ring reaches the chain as a ring key, under the one mark id
    // its conforming series ids are built from.
    expect(rings.length, greaterThan(1), reason: 'the family must be ringed');
    for (final ring in rings) {
      expect(generated.source, contains("ring: '${ring.name}',"));
    }
    expect(generated.source, contains("id: '${_markIdOf(rings)}',"));

    // Conforming ids, so the mark id is RECOVERED from them and no explicit
    // `ringIds:` map is written — this family stays on the original path.
    expect(generated.source, isNot(contains('ringIds:')));

    expect(tester.takeException(), isNull);
  });

  testWidgets("the family's shared composition knobs survive the reversal", (
    tester,
  ) async {
    await _pumpFamily(tester, 'concentricDonut');

    final config = _liveChart(tester).concentricDonutConfig;
    final generated = _generateGrammarFromPage(tester);
    final lines = _argumentLines(
      generated.source,
      'concentric: ConcentricDonutConfig(',
    );

    // Compared as VALUES parsed back out of the emitted text, not as formatted
    // strings: the assertion is about what the chain would rebuild, and it must
    // not go red over a literal-formatting change.
    double emitted(String name) {
      final line = lines.firstWhere(
        (entry) => entry.startsWith('$name: '),
        orElse: () => fail('no "$name" in the emitted composition:\n$lines'),
      );
      return double.parse(
        line.substring(name.length + 2).replaceAll(',', '').trim(),
      );
    }

    expect(emitted('innerRadiusFactor'), config.innerRadiusFactor);
    expect(emitted('outerRadiusFactor'), config.outerRadiusFactor);
    expect(emitted('ringGap'), config.ringGap);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lab still authors interactiveAnnotations: false when it '
      'HAS annotations, and the Grammar pane still refuses it', (tester) async {
    // The other half of this slice's page fix, and the reason it is not a
    // loosening. Switch the lab's projection overlays on for a Cartesian family
    // and the read-only flag comes back — where it means something — and the
    // generator refuses the chart by name, exactly as it did before.
    await _pumpFamily(tester, 'line');
    _inspectorEntry<BoolOption>(
      tester,
      const ValueKey('selection-lab-projection-annotations'),
    ).onChanged(true);
    await tester.pumpAndSettle();

    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('selection-chart-line')),
    );
    expect(chart.annotations, isNotEmpty);
    expect(chart.interactiveAnnotations, isFalse);

    final generated = _generateGrammar(tester, chart, 'lineSelectionChart');
    expect(generated.source, isNot(contains('= BravenChart.of(')));
    expect(
      generated.warnings.single.message,
      contains('interactiveAnnotations: false'),
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
      find.byKey(const ValueKey('selection-chart-concentricDonut')),
    );

List<DonutChartSeries> _liveRings(WidgetTester tester) =>
    _liveChart(tester).series.cast<DonutChartSeries>().toList();

/// The one mark id every live ring id is built from, asserted to be shared.
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

ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) =>
    _generateGrammar(
      tester,
      _liveChart(tester),
      'concentricDonutSelectionChart',
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

/// The options-panel entry keyed [key], read out of the page's own inspector.
T _inspectorEntry<T extends Widget>(WidgetTester tester, Key key) {
  final panel = tester.widget<OptionsPanel>(find.byType(OptionsPanel));
  final entries = <Widget>[];

  void visit(Widget widget) {
    entries.add(widget);
    if (widget is OptionSection) {
      for (final child in widget.children) {
        visit(child);
      }
    }
  }

  for (final child in panel.children) {
    visit(child);
  }
  return entries.whereType<T>().singleWhere((widget) => widget.key == key);
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
