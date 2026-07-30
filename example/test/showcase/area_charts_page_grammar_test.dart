// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the `AreaChartsPage` Grammar pane.
///
/// The companion to `line_charts_page_grammar_test.dart`, and asserted the same
/// way: `AreaChartsPage` is mounted, a preset is chosen through the real picker,
/// the live document is read off the chart's OWN controller, and the generator
/// runs on that. No fixture, so nothing to drift.
///
/// Item 1c′'s three carries all show up on this page, and each is asserted
/// against the emitted TEXT because the round-trip proof cannot read a
/// character of it (the generator's own docstring records this, verified by
/// mutation — deleting an emission line produces zero refusals):
///
/// - the **legacy single-axis binding**, which the page authors as a
///   widget-level `yAxis:` with unbound series, and which every Cartesian page
///   refused on until 1c′ reconstructed it;
/// - **`unit`**, on the Forecast preset's observed line;
/// - and the byte-identity control that a series carrying NO unit still emits
///   no `unit:` argument at all.
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
  testWidgets('ACCEPTANCE: the real AreaChartsPage emits a COMPLETE, '
      'warning-free grammar chain for its Layered preset', (tester) async {
    await _pumpPreset(tester, 'Layered');

    final chart = _liveChart(tester);
    final series = chart.series.cast<AreaChartSeries>().toList();
    final generated = _generateGrammarFromPage(tester);

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Area showcase page must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // The LEGACY SINGLE-AXIS SHAPE, asserted on the page before it is asserted
    // on the chain: a widget-level `yAxis:` and series that bind nothing. If
    // the page ever starts binding per series, this gate stops claiming to
    // cover the legacy path and says so by failing.
    expect(chart.yAxis, isNotNull);
    expect(series.every((entry) => entry.yAxisId == null), isTrue);
    expect(series.every((entry) => entry.yAxisConfig == null), isTrue);

    final axis = _verbBlocks(generated.source, 'YAxisConfig.withId(');
    expect(axis, hasLength(1));
    expect(axis.single, contains('position: YAxisPosition.left,'));
    expect(axis.single, contains("label: '${chart.yAxis!.label}',"));

    // Every mark, WHOLE. Values come from the live series, so this cannot go on
    // passing about a chart the page stopped building; the argument NAME list
    // is pinned, so a dropped, added or renamed argument fails too — and its
    // lack of a `yAxisId` entry is the reconstruction, read off the text.
    final marks = _verbBlocks(generated.source, '.geomArea(');
    expect(marks, hasLength(series.length));
    expect(series, hasLength(2), reason: 'the Layered preset draws two');
    for (var index = 0; index < series.length; index++) {
      final entry = series[index];
      expect(
        marks[index].map(_argumentName).toList(),
        <String>[
          'id',
          'y',
          'name',
          'color',
          'fillOpacity',
          'strokeWidth',
          'dashPattern',
          'interpolation',
          'showDataPointMarkers',
          'dataPointLabels',
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
      // The BYTE-IDENTITY CONTROL for `unit`: these series carry none, so the
      // argument must not appear at all. A `unit:` written unconditionally
      // would change what every existing chain emits.
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
        fixtureName: 'showcase_area_grammar_layered',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ACCEPTANCE: the Selection preset emits a COMPLETE, warning-free '
      'chain too', (tester) async {
    // The second state the census showed newly emitting on this page, and a
    // different shape from Layered: three filled series under one unbound axis.
    await _pumpPreset(tester, 'Selection');

    final chart = _liveChart(tester);
    final series = chart.series.cast<AreaChartSeries>().toList();
    final generated = _generateGrammarFromPage(tester);

    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Area Selection preset must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    expect(chart.yAxis, isNotNull);
    expect(series.every((entry) => entry.yAxisId == null), isTrue);
    expect(series.every((entry) => entry.yAxisConfig == null), isTrue);

    final marks = _verbBlocks(generated.source, '.geomArea(');
    expect(marks, hasLength(series.length));
    expect(series, hasLength(3), reason: 'the Selection preset draws three');
    for (var index = 0; index < series.length; index++) {
      expect(marks[index], contains("id: '${series[index].id}',"));
      expect(marks[index], contains("name: '${series[index].name}',"));
      expect(
        marks[index].map(_argumentName),
        isNot(contains('yAxisId')),
        reason:
            'the page binds no axis per series, so the chain must not either',
      );
    }

    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_area_grammar_selection',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the page's UNIT-bearing Forecast preset carries its unit onto "
      'the mark that has one, and onto no other', (tester) async {
    // Layered and Selection carry no unit, so on their own they prove only that
    // the unit no longer BLOCKS. `unit` was the widest-reach blocker in the
    // census — 31 states — and the proof cannot see whether the emitter
    // actually writes it, so this is the assertion that says it does. This
    // preset is the sharper case: an area band with NO unit under an observed
    // line WITH one, so the same chain carries both the carry and its control.
    await _pumpPreset(tester, 'Forecast');

    final series = _liveChart(tester).series;
    final generated = _generateGrammarFromPage(tester);

    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          'the Area Forecast preset must emit a grammar chain, but got:\n'
          '${generated.source}',
    );
    expect(generated.warnings, isEmpty);
    expect(generated.isComplete, isTrue);

    // Guarded off the LIVE series first: an emitted-text assertion about a unit
    // the page stopped setting would pass forever while proving nothing.
    final band = series.whereType<AreaChartSeries>().single;
    final observed = series.whereType<LineChartSeries>().single;
    expect(band.unit, isNull);
    expect(observed.unit, isNotNull);

    // SCOPED to each mark's own argument list. `unit:` is a `YAxisConfig` field
    // too, so a whole-file `contains("unit: 'k'")` could be satisfied by an
    // axis that says nothing about the mark under test — and a whole-file
    // `isNot(contains(...))` could not tell the band from the line at all.
    final areaMark = _verbBlocks(generated.source, '.geomArea(').single;
    final lineMark = _verbBlocks(generated.source, '.geomLine(').single;
    expect(lineMark, contains("unit: '${observed.unit}',"));
    expect(areaMark.map(_argumentName), isNot(contains('unit')));

    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_area_grammar_forecast',
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPreset(WidgetTester tester, String preset) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: AreaChartsPage())),
  );
  await tester.pumpAndSettle();

  // Chosen through the REAL picker, so the gate covers the state a user
  // reaches rather than one this file constructed.
  final chip = find.byKey(ValueKey('area-preset-$preset'));
  expect(
    chip,
    findsOneWidget,
    reason: 'the Area page must still offer a "$preset" preset',
  );
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

BravenChartPlus _liveChart(WidgetTester tester) =>
    tester.widget<BravenChartPlus>(find.byKey(const ValueKey('area-chart')));

/// Runs the grammar generator over the LIVE document of the chart the page
/// mounted, extracted with the page's OWN workbench options.
ChartGeneratedSource _generateGrammarFromPage(WidgetTester tester) {
  final workbench = tester.widget<BravenChartWorkbench>(
    find.byKey(const ValueKey('area-workbench')),
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
    options: const ChartGrammarSourceOptions(variableName: 'areaChart'),
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
