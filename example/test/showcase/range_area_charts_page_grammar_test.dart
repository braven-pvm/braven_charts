// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the Range Area page's Grammar pane, preset by preset.
///
/// Asserted against the PAGE, never a transcription: `RangeAreaChartsPage` is
/// mounted, each preset is chosen through the page's OWN chip picker, the live
/// document is read off that preset's chart controller, and the grammar
/// generator runs on it.
///
/// This page is the deliverable of roadmap item 1d's path-field slice. Before
/// it, the census read `RangeArea [7, 7, 0]` — every band carries a
/// `pathAnimation` and six of seven a `fillGradient`, and `RangeAreaMark`
/// carried neither, so the page emitted NOTHING. Its sibling
/// `selection_showcase_range_area_grammar_test.dart` (BC-0038) exists because
/// the selection lab's bands diverge only on range-area-native fields and so
/// could be accepted a slice earlier; this file is the one that could not.
///
/// SIX of seven presets emit. `confidence` still refuses, and the seventh
/// assertion below pins WHY: its bands and its observed line have different x
/// domains, which is the shared-x limitation — its own design, listed as out of
/// scope in this slice's spec. It is pinned by NAME so that a later slice
/// cannot quietly count it as this one's win, and so that the day shared-x
/// lands this file fails and is updated deliberately.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/range_area_charts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package's own compile gate, reached by path because it lives in the
// package's `test/` tree rather than its `lib/` and so has no `package:` URI.
import '../../../test/helpers/generated_source_compile.dart';

/// Every preset the page's chip picker offers, in the order it offers them.
///
/// Kept beside a guard that reads the LIVE chip set (see the first test), so a
/// preset added tomorrow fails this file rather than silently sitting outside
/// its denominator — the same rule the census file applies to its page list.
const List<String> _presets = <String>[
  'temperature',
  'seasonal',
  'confidence',
  'forecastFan',
  'volatility',
  'gapsAndSteps',
  'interactionStates',
];

/// The one preset that does NOT emit, and the phrase its refusal must contain.
const String _blockedPreset = 'confidence';

void main() {
  testWidgets('the walked preset set IS the page\'s own chip set', (
    tester,
  ) async {
    // The guard on the guard. Every assertion below is scoped to [_presets];
    // if the page grows a chip this file does not walk, "6 of 7" becomes a
    // claim about a subset while reading like a claim about the page.
    await _pumpPage(tester);

    final mounted = tester
        .widgetList<Widget>(find.byWidgetPredicate(_isPresetChip))
        .map(_presetOf)
        .toList();

    expect(
      mounted..sort(),
      List<String>.from(_presets)..sort(),
      reason:
          'the page mounts a preset chip this acceptance file does not walk, '
          'so its 6-of-7 claim would be about a subset of the page',
    );
    expect(tester.takeException(), isNull);
  });

  for (final preset in _presets.where((name) => name != _blockedPreset)) {
    testWidgets('ACCEPTANCE: the "$preset" preset emits a COMPLETE grammar '
        'chain', (tester) async {
      await _pumpPage(tester);
      await _selectPreset(tester, preset);

      final chart = _liveChart(tester, preset);
      final generated = _generateGrammar(tester, chart, 'rangeAreaChart');

      // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
      // entry point while explaining why it does not fit, so `BravenChart.of(`
      // alone would pass for a blocked chart.
      expect(
        generated.source,
        contains('= BravenChart.of('),
        reason:
            'the "$preset" preset must emit a grammar chain, but got:\n'
            '${generated.source}',
      );
      expect(
        generated.warnings,
        isEmpty,
        reason: generated.warnings.map((warning) => warning.message).join('\n'),
      );
      expect(generated.isComplete, isTrue);

      // Every band on the page has to reach the chain. A `contains` on one
      // `.geomRangeArea(` would pass on a chain that dropped a second band —
      // `forecastFan` and `interactionStates` both mount two.
      final bands = chart.series.whereType<RangeAreaChartSeries>().toList();
      expect(bands, isNotEmpty, reason: 'the preset must mount a band');
      expect(
        '.geomRangeArea('.allMatches(generated.source).length,
        bands.length,
      );
      for (final band in bands) {
        expect(generated.source, contains("id: '${band.id}',"));
      }
      final lines = chart.series.whereType<LineChartSeries>().toList();
      expect(
        '.geomLine('.allMatches(generated.source).length,
        lines.length,
        reason: 'the observed line must survive the reversal too',
      );

      // The FLOOR. Every assertion above reads the emitted TEXT, and text
      // assertions cannot tell a chain that would compile from one that only
      // looks right.
      await tester.runAsync(
        () => expectGeneratedSourceCompiles(
          generated.source,
          fixtureName: 'showcase_range_area_page_$preset',
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the path fields the page actually sets reach the chain', (
    tester,
  ) async {
    // The slice's own claim, read off the LIVE series rather than transcribed:
    // this page is the reason `RangeAreaMark` gained `fillGradient` and
    // `pathAnimation`, and `LineMark` its marker radius, so all three must
    // appear in the emitted text of a preset that sets them.
    await _pumpPage(tester);
    await _selectPreset(tester, 'temperature');

    final chart = _liveChart(tester, 'temperature');
    final band = chart.series.whereType<RangeAreaChartSeries>().first;
    final line = chart.series.whereType<LineChartSeries>().first;
    expect(
      band.fillGradient,
      isNotNull,
      reason: 'the fixture is vacuous if the page stops setting a gradient',
    );
    expect(band.pathAnimation, isNot(const PathAnimationStyle()));
    expect(line.dataPointMarkerRadius, isNot(3.0));

    final generated = _generateGrammar(tester, chart, 'rangeAreaChart');
    final bandArguments = _argumentLines(generated.source, '.geomRangeArea(');
    expect(bandArguments, contains('fillGradient: AreaGradient('));
    expect(bandArguments, contains('pathAnimation: PathAnimationStyle('));
    expect(
      _argumentLines(generated.source, '.geomLine('),
      contains('dataPointMarkerRadius: ${line.dataPointMarkerRadius},'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the "$_blockedPreset" preset still refuses, on the X-DOMAIN '
      'divergence and NOT on a field', (tester) async {
    // Pinned deliberately, and by the reason rather than the outcome. This
    // preset is blocked by shared-x alignment — one row list cannot express
    // series whose x domains differ — which is a separate design listed as out
    // of scope in this slice's spec. Asserting only "does not emit" would let
    // a later field slice claim it, and asserting the emission would be a lie;
    // asserting the SENTENCE keeps the boundary where the design put it.
    await _pumpPage(tester);
    await _selectPreset(tester, _blockedPreset);

    final chart = _liveChart(tester, _blockedPreset);
    final generated = _generateGrammar(tester, chart, 'rangeAreaChart');

    expect(generated.source, isNot(contains('= BravenChart.of(')));
    final message = generated.warnings
        .map((warning) => warning.message)
        .join('\n');
    expect(
      message,
      allOf(
        contains('x domains differ'),
        contains('confidence-range'),
        contains('confidence-observed'),
      ),
      reason:
          'the refusal must name the x-domain divergence, not a series field: '
          '$message',
    );
    // The complement, and the load-bearing half: no path or marker field may
    // appear in the reason, or this slice left the preset one field short
    // rather than one DESIGN short.
    for (final field in const <String>[
      'fill gradient',
      'path animation',
      'data-point marker',
      'curve tension',
      'line glow',
      'inline series label',
      'split baseline fill',
    ]) {
      expect(
        message,
        isNot(contains(field)),
        reason: '"$field" is carried by this slice; it cannot be the blocker',
      );
    }
    expect(tester.takeException(), isNull);
  });
}

bool _isPresetChip(Widget widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('range-area-preset-') &&
      key.value != 'range-area-preset-picker';
}

String _presetOf(Widget widget) => ((widget.key! as ValueKey<String>).value)
    .substring('range-area-preset-'.length);

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: RangeAreaChartsPage())),
  );
  await tester.pumpAndSettle();
}

/// Drives the page's OWN chip picker, then lets its entrance animation land.
Future<void> _selectPreset(WidgetTester tester, String preset) async {
  final chip = find.byKey(ValueKey('range-area-preset-$preset'));
  await tester.ensureVisible(chip);
  await tester.pump();
  await tester.tap(chip, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

BravenChartPlus _liveChart(WidgetTester tester, String preset) => tester
    .widget<BravenChartPlus>(find.byKey(ValueKey('range-area-chart-$preset')));

/// Runs the grammar generator over [chart]'s LIVE document, extracted with the
/// page's OWN workbench options.
ChartGeneratedSource _generateGrammar(
  WidgetTester tester,
  BravenChartPlus chart,
  String variableName,
) {
  final workbench = tester.widget<BravenChartWorkbench>(
    find.byKey(const ValueKey('range-area-workbench')),
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
