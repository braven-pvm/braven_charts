// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the `LineChartsPage` Grammar pane — the first CARTESIAN one.
///
/// Every acceptance gate this programme built before item 1c′ was radial, and
/// every round-trip test in the package's own `test/unit/source/` authors its
/// original through `BravenChart.of(...)`, which always produces explicit axes.
/// So nothing ever exercised a chart authored the way a showcase page authors
/// one, and a census on 2026-07-29 found that **no** config-authored Cartesian
/// page had ever emitted a chain. This file is the gate that stops that being
/// true again for Line: `LineChartsPage` is mounted, a preset is chosen through
/// the real picker, the live document is read off the chart's OWN controller,
/// and the generator runs on that. There is no fixture here to drift.
///
/// Two things this file is deliberate about, both of them lessons paid for:
///
/// 1. **The round-trip proof does not read the emitted text.** The generator's
///    own docstring records it and mutation confirms it — deleting an emission
///    line produces zero refusals. So a missing writer line or a missing builder
///    parameter would ship a chain that silently drops a value while every
///    proof-based test stays green. Every field 1c′ carries is therefore
///    asserted against the emitted TEXT here, and asserted **inside the verb's
///    own argument list** rather than against the whole file: `unit:` is a
///    `YAxisConfig` field as well as a mark field, so a bare
///    `contains('unit:')` could be satisfied by text that says nothing about
///    the mark.
/// 2. **The argument list is pinned WHOLE, not sampled.** A `contains` per
///    field can only notice fields the list happens to name, so a field dropped
///    from the emitter is invisible to it. Each geom's complete top-level
///    argument list is asserted instead, which is also what proves the legacy
///    single-axis reconstruction: no `yAxisId:` appears on any mark, because
///    the page never bound one.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package's own compile gate, reached by path because it lives in the
// package's `test/` tree rather than its `lib/` and so has no `package:` URI.
// Copying it here instead would fork the format-then-analyze recipe the helper
// exists to stop forking.
import '../../../test/helpers/generated_source_compile.dart';

void main() {
  testWidgets('ACCEPTANCE: the real LineChartsPage emits a COMPLETE, '
      'warning-free grammar chain for its Interpolation preset', (
    tester,
  ) async {
    await _pumpPreset(tester, 'Interpolation');

    final chart = _liveChart(tester);
    final series = chart.series.cast<LineChartSeries>().toList();
    final generated = _generateGrammarFromPage(tester);

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Line showcase page must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // The LEGACY SINGLE-AXIS SHAPE, asserted on the page before it is asserted
    // on the chain. This preset is authored the way a config author writes one
    // — a widget-level `yAxis:` and series that bind nothing — which is exactly
    // the shape that made every Cartesian page refuse until 1c′ reconstructed
    // it. If the page ever starts binding per series, this gate stops claiming
    // to cover the legacy path.
    expect(chart.yAxis, isNotNull);
    expect(series.every((entry) => entry.yAxisId == null), isTrue);
    expect(series.every((entry) => entry.yAxisConfig == null), isTrue);

    // One axis reaches the chain, carrying the page's own label, and the marks
    // carry NO binding — the reconstruction, read off the emitted text.
    final axis = _verbBlocks(generated.source, 'YAxisConfig.withId(');
    expect(axis, hasLength(1));
    expect(axis.single, contains('position: YAxisPosition.left,'));
    expect(axis.single, contains("label: '${chart.yAxis!.label}',"));

    // Every mark, WHOLE. Values come from the live series, so this cannot go on
    // passing about a chart the page stopped building; the argument NAME list
    // is pinned, so a dropped, added or renamed argument fails too.
    final marks = _verbBlocks(generated.source, '.geomLine(');
    expect(marks, hasLength(series.length));
    expect(series, hasLength(4), reason: 'the Interpolation preset draws four');
    for (var index = 0; index < series.length; index++) {
      final entry = series[index];
      expect(
        marks[index].map(_argumentName).toList(),
        <String>[
          'id',
          'y',
          'name',
          'color',
          'strokeWidth',
          'dashPattern',
          'interpolation',
          'showDataPointMarkers',
        ],
        reason: 'mark $index of the emitted chain:\n${marks[index]}',
      );
      expect(marks[index], contains("id: '${entry.id}',"));
      expect(marks[index], contains("name: '${entry.name}',"));
      expect(marks[index], contains('color: ${_colorLiteral(entry.color!)},'));
      expect(
        marks[index],
        contains(
          'interpolation: LineInterpolation.${entry.interpolation.name},',
        ),
      );
      // The BYTE-IDENTITY CONTROL for `unit`. These four series carry none, so
      // the argument must not appear at all — a `unit:` written unconditionally
      // (or defaulted to `''`) would change what every existing chain emits.
      expect(entry.unit, isNull);
    }

    // The FLOOR. Every assertion above reads the emitted TEXT, and text
    // assertions cannot tell a chain that would compile from one that only
    // looks right — an ambiguous import, a parameter the builder does not have,
    // a dropped paren all read the same to `contains`. This floor caught a real
    // defect in an earlier slice that every text assertion passed over.
    //
    // Real subprocesses, so the same `runAsync` escape hatch the package-side
    // callers document applies here.
    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_line_grammar_interpolation',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's UNIT-bearing Comparison preset carries its unit onto "
      'every emitted mark', (tester) async {
    // The Interpolation preset carries no unit, so on its own it proves only
    // that the unit no longer BLOCKS. `unit` was the widest-reach blocker in
    // the census — 31 states — and the proof cannot see whether the emitter
    // actually writes it, so this is the assertion that says it does.
    await _pumpPreset(tester, 'Comparison');

    final series = _liveChart(tester).series.cast<LineChartSeries>().toList();
    final generated = _generateGrammarFromPage(tester);

    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Comparison preset must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(generated.warnings, isEmpty);
    expect(generated.isComplete, isTrue);

    // Guarded off the LIVE series first: an emitted-text assertion about a unit
    // the page stopped setting would pass forever while proving nothing.
    expect(series, isNotEmpty);
    expect(series.map((entry) => entry.unit).toSet(), <String>{'W'});

    final marks = _verbBlocks(generated.source, '.geomLine(');
    expect(marks, hasLength(series.length));
    for (var index = 0; index < series.length; index++) {
      // SCOPED to the mark's own argument list. `unit:` is a `YAxisConfig`
      // field too, so a whole-file `contains("unit: 'W'")` could be satisfied
      // by an axis that says nothing about the mark under test.
      expect(
        marks[index],
        contains("unit: '${series[index].unit}',"),
        reason: 'mark $index dropped its unit:\n${marks[index]}',
      );
      expect(
        marks[index].map(_argumentName).toList(),
        <String>[
          'id',
          'y',
          'name',
          'color',
          'unit',
          'strokeWidth',
          'dashPattern',
          'interpolation',
          'showDataPointMarkers',
          'dataPointLabels',
        ],
        reason: 'mark $index of the emitted chain:\n${marks[index]}',
      );
    }

    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_line_grammar_comparison',
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
    await _pumpPreset(tester, 'Comparison');

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
      find.byKey(const ValueKey('line-workbench')),
    );
    expect(
      workbench.workbenchController!.sourceState.phase,
      ChartWorkbenchSourcePhase.ready,
    );
    final chain = workbench.workbenchController!.generatedSource!.source;
    expect(
      chain,
      contains('= BravenChart.of('),
      reason: 'the Line Grammar pane must show a chain, but got:\n$chain',
    );
    expect(chain, contains('.geomLine('));
    // The unit reaches the pane a user actually opens, not just the generator
    // this file drives directly.
    expect(_verbBlocks(chain, '.geomLine(').first, contains("unit: 'W',"));
    expect(
      find.byKey(const ValueKey('chart-grammar-source-code')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPreset(WidgetTester tester, String preset) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: LineChartsPage())),
  );
  await tester.pumpAndSettle();

  // Chosen through the REAL picker, so the gate covers the state a user
  // reaches rather than one this file constructed.
  final chip = find.byKey(ValueKey('line-preset-$preset'));
  expect(
    chip,
    findsOneWidget,
    reason: 'the Line page must still offer a "$preset" preset',
  );
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

BravenChartPlus _liveChart(WidgetTester tester) =>
    tester.widget<BravenChartPlus>(
      find.byWidgetPredicate(
        (widget) =>
            widget is BravenChartPlus &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('line-chart-'),
        description: 'active preset-keyed Line chart',
      ),
    );

/// Runs the grammar generator over the LIVE document of the chart the page
/// mounted, extracted with the page's OWN workbench options.
ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) {
  final workbench = tester.widget<BravenChartWorkbench>(
    find.byKey(const ValueKey('line-workbench')),
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
  final result = ChartGrammarSourceGenerator.generate(
    (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value,
    options: const ChartGrammarSourceOptions(variableName: 'lineChart'),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

/// The colour literal [color] is emitted as, built the way the writer builds it
/// so this cannot go red over a formatting choice it does not own.
String _colorLiteral(Color color) =>
    'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})';

/// The parameter name an emitted argument line names.
String _argumentName(String line) => line.split(':').first.trim();

/// Every occurrence of [opening] in [source], each as its own list of TOP-LEVEL
/// argument lines, trimmed and in emitted order.
///
/// Returning the complete list — rather than answering `contains` per field —
/// is what makes a DROPPED argument visible: a fragment list can only notice
/// the fields it happens to name.
///
/// The literal is delimited by indentation: its closing paren sits at the same
/// column as the opening token, so a nested literal's deeper one cannot end it.
/// Lines indented further belong to a nested literal and are skipped, as is the
/// nested literal's own closing line.
List<List<String>> _verbBlocks(String source, String opening) {
  final blocks = <List<String>>[];
  var from = 0;
  while (true) {
    final start = source.indexOf(opening, from);
    if (start < 0) break;
    from = start + opening.length;
    final indent = start - (source.lastIndexOf('\n', start) + 1);
    final bodyStart = source.indexOf('\n', start) + 1;
    final end = source.indexOf('\n${' ' * indent})', start);
    expect(end, isNonNegative, reason: 'unterminated "$opening" in:\n$source');
    final inner = ' ' * (indent + 2);
    blocks.add([
      for (final line in source.substring(bodyStart, end).split('\n'))
        if (line.startsWith(inner) &&
            line.length > indent + 2 &&
            line[indent + 2] != ' ' &&
            line.trim() != ')' &&
            line.trim() != '),')
          line.trim(),
    ]);
  }
  expect(blocks, isNotEmpty, reason: 'no "$opening" in:\n$source');
  return blocks;
}
