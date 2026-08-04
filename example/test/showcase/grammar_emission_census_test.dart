// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// THE EMISSION CENSUS, as a test rather than a memory.
///
/// The Theme-1 acceptance bar is "every Workbench-bearing showcase page shows a
/// faithful grammar chain". Twice now that bar has been reported from a number
/// that was *re-discovered* by hand — once by a probe that sampled only the
/// pages a slice touched, and once by a run that was reconstructed from an
/// earlier run's output format rather than re-executed. Both were wrong, in
/// both directions. This file exists so the number is DERIVED, not remembered:
/// it mounts every page that mounts a [BravenChartWorkbench], walks every state
/// its own picker offers, reads each chart's live document off that chart's own
/// controller, runs the grammar generator on it, and prints the census.
///
/// Four things it is deliberate about, each of them a defect that has actually
/// shipped in a recorded census:
///
///  1. **The page list is DISCOVERED, not transcribed.** [_censusPages] is
///     checked against a `grep` for `BravenChartWorkbench` under `example/lib`
///     by [_mountSiteGuard], so a page added tomorrow fails this file rather
///     than quietly sitting outside the denominator. The census this replaces
///     covered 8 of the 15 mount sites: `ChartGrammarPage` and all six radial
///     pages were outside its denominator, which its own arithmetic shows —
///     it reported 110 states with a verdict of which 106 were Cartesian, so
///     only 4 radial states were counted, and the six radial pages carry 50.
///  2. **The states are DISCOVERED too.** Chips are found by walking the live
///     element tree for the page's own key prefix. Nothing here transcribes a
///     preset list, so adding a preset moves the census instead of drifting
///     away from it.
///  3. **Extraction uses the PAGE'S OWN `documentOptions`.** A prior probe
///     recorded seven `ValueSummaryPage` states as unreachable after extracting
///     with defaults instead of the callback descriptor its Source pane uses.
///     Default extraction now omits that optional host notification with a
///     warning, while the page options preserve its binding identity. The
///     workbench each chart is mounted inside is located through the ELEMENT
///     TREE, so this cannot go stale the way a per-page key table would.
///  4. **Charts are counted per chart, not per page.** `ChartWorkbenchPage`
///     mounts two workbenches and more than one chart; a per-page verdict would
///     silently drop the rest.
library;

import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/bar_lab_page.dart';
import 'package:braven_charts_example/showcase/pages/candlestick_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:braven_charts_example/showcase/pages/chart_workbench_page.dart';
import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/gauge_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/heatmap_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:braven_charts_example/showcase/pages/radial_bar_page.dart';
import 'package:braven_charts_example/showcase/pages/range_area_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:braven_charts_example/showcase/pages/value_summary_page.dart';
import 'package:braven_charts_example/showcase/widgets/standard_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One page under census: how to mount it, and how its own picker names states.
class _CensusPage {
  const _CensusPage({
    required this.name,
    required this.build,
    required this.sourceFile,
    required this.mountSites,
    this.statePrefixes = const <String>[],
  });

  /// The label this page reports under.
  final String name;

  /// Mounts the page. Kept as a builder so each state starts from a fresh tree
  /// — several pages latch their first preset into controllers that a later
  /// chip cannot fully undo, and a census that reuses one tree would report the
  /// residue rather than the state.
  final Widget Function() build;

  /// The `example/lib` file this page's workbench is mounted in, and how many
  /// `BravenChartWorkbench` constructor calls that file makes. Checked against
  /// the real source by [_mountSiteGuard].
  final String sourceFile;
  final int mountSites;

  /// `ValueKey<String>` prefixes the page's own state picker uses. Every key
  /// found under one of these becomes a censused state.
  final List<String> statePrefixes;
}

enum _Family { cartesian, radial }

/// Which half of the Theme-1 claim a chart belongs to, read off the LIVE
/// series rather than declared per page.
///
/// Per-page would be wrong in both directions and the roadmap's two headline
/// numbers depend on getting it right: `SelectionShowcasePage` mounts four
/// radial families and five Cartesian ones from one picker, and
/// `ChartGrammarPage` has a radial preset among Cartesian ones.
_Family _familyOf(BravenChartPlus chart) {
  const radial = <String>{
    'PieChartSeries',
    'DonutChartSeries',
    'PolarColumnChartSeries',
    'RadialBarChartSeries',
    'GaugeChartSeries',
  };
  if (chart.series.isEmpty) return _Family.cartesian;
  final types = chart.series.map((s) => s.runtimeType.toString()).toSet();
  return types.every(radial.contains) ? _Family.radial : _Family.cartesian;
}

/// One `(page, state, chart)` tuple and what the generator said about it.
class _Verdict {
  _Verdict({
    required this.page,
    required this.state,
    required this.chart,
    required this.family,
    required this.outcome,
    required this.detail,
    this.isComplete = false,
    this.warningCount = 0,
    this.shadow,
  });

  final String page;
  final String state;
  final String chart;
  final _Family family;

  /// `emitting`, `refused`, `extract-failed`, or `no-controller`.
  final String outcome;

  /// The first blocking sentence for a refusal; the failure code otherwise.
  final String detail;
  final bool isComplete;
  final int warningCount;

  /// For a chart with no workbench ancestor on a page that mounts one
  /// elsewhere: what the generator says when handed that workbench's options.
  /// `emitting` or `refused`. Reported separately, never in the headline.
  final String? shadow;

  bool get hasVerdict => outcome == 'emitting' || outcome == 'refused';

  String get key => '$page|$state|$chart';
}

final List<_Verdict> _census = <_Verdict>[];

/// Example chips a page offers that the census does NOT walk, by page.
///
/// This is the guard on the guard. The first run of this file silently missed
/// six `Playground` chips because their keys did not match the prefix the page
/// used for its presets — the same class of miss as the census it replaces. So
/// every chip the page mounts is collected, anything outside the walked set is
/// recorded here, and the totals test pins the result: a chip that stops being
/// censused has to be declared, not discovered later.
final Map<String, Set<String>> _uncensusedChips = <String, Set<String>>{};

/// Every page in `example/lib` that mounts a [BravenChartWorkbench].
///
/// `LineChartsPage`/`AreaChartsPage`/`ScatterChartsPage` are three pages behind
/// one mount site (`cartesian_chart_type_pages.dart` builds all three from one
/// `_CartesianChartTypePage`), which is why `mountSites` is declared per FILE
/// and the guard counts files, not entries.
const List<_CensusPage> _censusPages = <_CensusPage>[
  _CensusPage(
    name: 'Line',
    build: LineChartsPage.new,
    sourceFile: 'cartesian_chart_type_pages.dart',
    mountSites: 1,
    statePrefixes: <String>['line-preset-', 'line-playground'],
  ),
  _CensusPage(
    name: 'Area',
    build: AreaChartsPage.new,
    sourceFile: 'cartesian_chart_type_pages.dart',
    mountSites: 1,
    statePrefixes: <String>['area-preset-', 'area-playground'],
  ),
  _CensusPage(
    name: 'Scatter',
    build: ScatterChartsPage.new,
    sourceFile: 'cartesian_chart_type_pages.dart',
    mountSites: 1,
    statePrefixes: <String>['scatter-preset-', 'scatter-playground'],
  ),
  _CensusPage(
    name: 'BarLab',
    build: BarLabPage.new,
    sourceFile: 'bar_lab_page.dart',
    mountSites: 1,
    statePrefixes: <String>['bar-lab-preset-', 'bar-playground'],
  ),
  _CensusPage(
    name: 'Candlestick',
    build: CandlestickChartsPage.new,
    sourceFile: 'candlestick_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['candlestick-example-', 'candlestick-playground'],
  ),
  _CensusPage(
    name: 'RangeArea',
    build: RangeAreaChartsPage.new,
    sourceFile: 'range_area_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['range-area-preset-'],
  ),
  _CensusPage(
    name: 'Heatmap',
    build: HeatmapChartsPage.new,
    sourceFile: 'heatmap_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['heatmap-preset-'],
  ),
  _CensusPage(
    name: 'ValueSummary',
    build: ValueSummaryPage.new,
    sourceFile: 'value_summary_page.dart',
    mountSites: 1,
    statePrefixes: <String>['value-summary-preset-'],
  ),
  _CensusPage(
    name: 'Selection',
    build: SelectionShowcasePage.new,
    sourceFile: 'selection_showcase_page.dart',
    mountSites: 1,
    statePrefixes: <String>['selection-family-'],
  ),
  _CensusPage(
    name: 'Workbench',
    build: ChartWorkbenchPage.new,
    sourceFile: 'chart_workbench_page.dart',
    mountSites: 3,
  ),
  _CensusPage(
    name: 'Grammar',
    build: ChartGrammarPage.new,
    sourceFile: 'chart_grammar_page.dart',
    mountSites: 1,
    statePrefixes: <String>['chart-grammar-preset-'],
  ),
  _CensusPage(
    name: 'Pie',
    build: PieChartsPage.new,
    sourceFile: 'pie_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['pie-preset-', 'pie-playground'],
  ),
  _CensusPage(
    name: 'Donut',
    build: DonutChartsPage.new,
    sourceFile: 'donut_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['donut-story-', 'donut-playground'],
  ),
  _CensusPage(
    name: 'ConcentricDonut',
    build: ConcentricDonutPage.new,
    sourceFile: 'concentric_donut_page.dart',
    mountSites: 1,
    statePrefixes: <String>['concentric-preset-', 'concentric-playground'],
  ),
  _CensusPage(
    name: 'PolarColumn',
    build: PolarColumnPage.new,
    sourceFile: 'polar_column_page.dart',
    mountSites: 1,
    statePrefixes: <String>['polar-presentation-', 'polar-playground'],
  ),
  _CensusPage(
    name: 'RadialBar',
    build: RadialBarPage.new,
    sourceFile: 'radial_bar_page.dart',
    mountSites: 1,
    statePrefixes: <String>[
      'radial-bar-presentation-',
      'radial-bar-playground',
    ],
  ),
  _CensusPage(
    name: 'Gauge',
    build: GaugeChartsPage.new,
    sourceFile: 'gauge_charts_page.dart',
    mountSites: 1,
    statePrefixes: <String>['gauge-presentation-', 'gauge-playground'],
  ),
];

void main() {
  test(
    'the census covers every BravenChartWorkbench mount site in '
    'example/lib',
    _mountSiteGuard,
  );

  for (final page in _censusPages) {
    testWidgets('census: ${page.name}', (tester) async {
      await _censusOnePage(tester, page);
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('CENSUS', () {
    _report();

    // The numbers, pinned. These are assertions, not decoration: the whole
    // point of the file is that the census cannot drift without going red.
    final withVerdict = _census.where((v) => v.hasVerdict).toList();
    final emitting = withVerdict.where((v) => v.outcome == 'emitting').toList();

    expect(_census, isNotEmpty);
    expect(
      _census.map((v) => v.key).toSet(),
      hasLength(_census.length),
      reason: 'every (page, state, chart) tuple must be unique',
    );
    // Every chip outside the walked set is DECLARED. A new secondary picker,
    // or a preset whose key stops matching its page's prefix, fails here
    // instead of quietly shrinking the denominator.
    expect(_uncensusedChips, _expectedUncensusedChips);

    // PER PAGE FIRST, so a drift says WHERE. A whole-census total that moved
    // by one is the least useful possible failure message.
    final actual = <String, List<int>>{
      for (final page in _censusPages)
        page.name: <int>[
          _census.where((v) => v.page == page.name).length,
          _census.where((v) => v.page == page.name && v.hasVerdict).length,
          _census
              .where((v) => v.page == page.name && v.outcome == 'emitting')
              .length,
        ],
    };
    expect(actual, _expectedPerPage);

    expect(withVerdict, hasLength(_expectedWithVerdict));
    expect(emitting, hasLength(_expectedEmitting));

    // The SHADOW column, pinned too. It is the whole of the difference between
    // this census's Workbench figure and the one it replaces, so leaving it
    // unpinned would leave that difference arguable.
    final shadowed = _census.where((v) => v.shadow != null).toList();
    expect(shadowed, hasLength(_expectedShadowCharts));
    expect(
      shadowed.where((v) => v.shadow == 'emitting'),
      hasLength(_expectedShadowEmitting),
    );

    // The two halves of the Theme-1 claim, which are reported separately and
    // have separate baselines: Cartesian was 0 before item 1c′, radial was
    // never counted at all.
    for (final family in _Family.values) {
      final rows = withVerdict.where((v) => v.family == family).toList();
      expect(
        <int>[rows.where((v) => v.outcome == 'emitting').length, rows.length],
        _expectedPerFamily[family],
        reason: '${family.name} emitting of ${family.name} with a verdict',
      );
    }
  });
}

/// `page -> [tuples, with a verdict, emitting]`, measured 2026-08-01 on
/// `feature/BC-0043-heatmap-histogram`, then re-measured 2026-08-02 on
/// `feature/grammar-range-area` where `RangeAreaMark` moved `Selection` from
/// 7 emitting to 8.
///
/// Re-measured again 2026-08-03 on
/// `feature/BC-0050-heatmap-live-ingestion`, where the raster Heatmap preset
/// added one non-emitting Cartesian workbench with a truthful verdict.
///
/// Re-measured again 2026-08-04 on `feature/grammar-path-fields` (BC-0054),
/// where `LineMark`, `AreaMark` and `RangeAreaMark` gained the path and marker
/// fields their series already had. **Whole repo 59 -> 75 emitting, Cartesian
/// 28 -> 44 of 129, radial unchanged at 31 of 55.** Both numbers were measured
/// the same way, one run each: the "before" by restoring `lib/src` to master
/// `b60ec846` in this worktree and running this file, the "after" by running it
/// on the branch. The composition, page by page and state by state, because a
/// +16 that cannot be decomposed is worth less than a smaller one that can:
///
///  - **RangeArea 0 -> 6** — the page this slice existed for. Its previous
///    entry read "`[7, 7, 0]` is the honest number rather than a failure: every
///    band carries a non-default `pathAnimation` and six of seven a
///    `fillGradient`". Exactly those six moved (`temperature`, `seasonal`,
///    `forecastFan`, `volatility`, `interactionStates` on the gradient,
///    `gapsAndSteps` on the animation).
///  - **Area 3 -> 8** — all FIVE states that named a slice field first:
///    `Baseline` (split baseline fill), `Motion` (path animation), `Gradient`
///    and `Composition` (fill gradient), `area-playground` (line glow).
///    `Composition` is the one the design predicted would have re-refused one
///    field later had `inlineLabel` been dropped from the slice; it did not.
///  - **Line 3 -> 6** — THREE of the six states that named a slice field
///    first: `Motion` (path animation), `Envelope` (fill gradient),
///    `Close points` (marker radius). The other three did not move, and their
///    SECOND blocker is the useful output of this census:
///      * `Spotlight` — was "a fill gradient"; now an unnamed residual loss on
///        annotation "spotlight-threshold".
///      * `Forecast` — was "a data-point marker style"; now the per-point
///        segment style on "forecast-continuous", which `LineMark` still does
///        not carry (BC-0040 refused it as inert-and-expensive).
///      * `line-playground` — was "a data-point marker radius"; now an unnamed
///        residual loss on annotation "work-stage".
///    Two of those three are annotation residuals with no named reason, which
///    is the "5 unnamed residuals" bucket the spec listed as out of scope.
///  - **ValueSummary 4 -> 5** (`pinned`, marker radius) and
///    **Workbench 1 -> 2** (`default`, marker radius).
///
/// Ceiling and result: the design measured 19 states naming a slice field as
/// their FIRST blocker and called that a ceiling, not a forecast. 16 of the 19
/// moved; the 3 that did not are the Line states named above, each with its
/// second blocker identified. Nothing outside those 19 moved, and no page went
/// down.
const Map<String, List<int>> _expectedPerPage = <String, List<int>>{
  'Line': <int>[16, 13, 6],
  'Area': <int>[9, 9, 8],
  'Scatter': <int>[29, 27, 6],
  'BarLab': <int>[31, 31, 0],
  'Candlestick': <int>[10, 8, 0],
  'RangeArea': <int>[7, 7, 6],
  'Heatmap': <int>[19, 16, 0],
  'ValueSummary': <int>[8, 6, 5],
  'Selection': <int>[10, 10, 8],
  'Workbench': <int>[5, 2, 2],
  'Grammar': <int>[12, 9, 8],
  'Pie': <int>[6, 6, 6],
  'Donut': <int>[5, 5, 5],
  'ConcentricDonut': <int>[6, 6, 6],
  'PolarColumn': <int>[9, 9, 9],
  'RadialBar': <int>[12, 12, 0],
  'Gauge': <int>[12, 12, 0],
};

/// `[emitting, with a verdict]`, classified off each chart's LIVE series.
const Map<_Family, List<int>> _expectedPerFamily = <_Family, List<int>>{
  _Family.cartesian: <int>[44, 133],
  _Family.radial: <int>[31, 55],
};

const int _expectedWithVerdict = 188;
const int _expectedEmitting = 75;

/// The three `ChartWorkbenchPage` hydration tiles — restored copies of the
/// primary chart's captured document, mounted beside the workbench rather than
/// inside it. They have no Grammar pane. The census that this file replaces
/// counted them in its headline, which is why they are pinned here instead of
/// merely excluded.
///
/// All three refused until 2026-08-04: the deterministic generated document
/// carries a marker radius, and the V1 line mark could not reproduce one. The
/// path-field slice gave `LineMark` that field, so all three now emit. They are
/// still reported separately and still outside the headline — admitting them
/// would read 187 with a verdict / 78 emitting — but a shadow column that
/// stayed at 0 through the very slice that unblocked it would be a pin gone
/// stale rather than a measurement.
const int _expectedShadowCharts = 3;
const int _expectedShadowEmitting = 3;

/// Example chips the census deliberately does not walk, and why.
///
/// These are ORTHOGONAL pickers — a second axis of choice over the same preset
/// — not states of the page's own example picker. Walking them would multiply
/// the census combinatorially against a denominator ("preset/example chips")
/// that means one axis. They are pinned rather than filtered so the decision is
/// visible and a THIRD picker cannot appear unnoticed.
const Map<String, Set<String>> _expectedUncensusedChips = <String, Set<String>>{
  // "Choose a dataset" — which numbers the chosen presentation draws.
  'Pie': <String>{
    'pie-dataset-countries',
    'pie-dataset-effort',
    'pie-dataset-revenue',
    'pie-dataset-support',
  },
};

/// Fails when `example/lib` mounts a workbench in a file the census does not
/// name, or names a count of mount sites the source does not have.
void _mountSiteGuard() {
  final root = Directory('lib/showcase');
  expect(root.existsSync(), isTrue, reason: 'run from example/');

  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final text = entity.readAsStringSync();
    // The constructor CALL, not the identifier: `chart_workbench_page.dart`
    // also prints the class name inside a source-reference string literal, and
    // counting that would invent a sixteenth mount site.
    final mounts =
        RegExp(r'BravenChartWorkbench\(').allMatches(text).length -
        RegExp(r"'BravenChartWorkbench\(").allMatches(text).length;
    if (mounts > 0) {
      found[entity.uri.pathSegments.last] = mounts;
    }
  }

  final declared = <String, int>{};
  for (final page in _censusPages) {
    declared[page.sourceFile] = page.mountSites;
  }

  expect(
    found.keys.toSet(),
    declared.keys.toSet(),
    reason:
        'every file mounting a BravenChartWorkbench must be censused.\n'
        'found: $found\ndeclared: $declared',
  );
  expect(found, declared, reason: 'mount-site counts moved');
  expect(
    found.values.fold<int>(0, (a, b) => a + b),
    17,
    reason: 'the census is sized against 17 mount sites; found $found',
  );
}

Future<void> _censusOnePage(WidgetTester tester, _CensusPage page) async {
  tester.view.physicalSize = const Size(1800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page.build())));
  await _settle(tester);

  final states = _discoverStates(tester, page.statePrefixes);
  _recordUncensusedChips(tester, page, states);
  if (states.isEmpty) {
    _censusCurrentTree(tester, page, 'default');
    return;
  }

  for (final state in states) {
    // A FRESH TREE per state. Re-tapping in place leaves per-preset controller
    // residue on several pages, and a census that reports residue is exactly
    // the failure this file exists to stop.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page.build())));
    await _settle(tester);

    final chip = find.byKey(ValueKey<String>(state));
    if (chip.evaluate().isEmpty) {
      _census.add(
        _Verdict(
          page: page.name,
          state: _stateLabel(state, page.statePrefixes),
          chart: '-',
          family: _Family.cartesian,
          outcome: 'unreachable',
          detail: 'the picker no longer offers "$state"',
        ),
      );
      continue;
    }
    try {
      await tester.ensureVisible(chip);
      await tester.pump();
    } on Object {
      // Not in a scrollable, or already visible.
    }
    await tester.tap(chip, warnIfMissed: false);
    await _settle(tester);

    _censusCurrentTree(tester, page, _stateLabel(state, page.statePrefixes));
  }
}

/// Records a verdict for every chart currently mounted inside a workbench.
void _censusCurrentTree(WidgetTester tester, _CensusPage page, String state) {
  final charts = find.byType(BravenChartPlus).evaluate().toList();
  if (charts.isEmpty) {
    _census.add(
      _Verdict(
        page: page.name,
        state: state,
        chart: '-',
        family: _Family.cartesian,
        outcome: 'no-chart',
        detail: 'this state mounts no BravenChartPlus',
      ),
    );
    return;
  }

  final seen = <String>{};
  for (final element in charts) {
    final chart = element.widget as BravenChartPlus;
    final workbench = _ancestorWorkbench(element);
    var name = _chartName(chart, charts.indexOf(element));
    while (!seen.add(name)) {
      name = '$name+';
    }

    if (workbench == null) {
      // Not under a workbench: outside the Theme-1 claim, which is about what
      // the Grammar PANE shows, and this chart has no pane. Recorded rather
      // than dropped so the denominator is auditable — and given a SHADOW
      // verdict when the page mounts a workbench elsewhere, because the census
      // this file replaces counted exactly these charts as emitting and the
      // difference has to be reproducible rather than argued.
      final elsewhere = find.byType(BravenChartWorkbench).evaluate();
      _census.add(
        _Verdict(
          page: page.name,
          state: state,
          chart: name,
          family: _familyOf(chart),
          outcome: 'not-in-workbench',
          detail: elsewhere.isEmpty
              ? 'this state mounts no workbench at all'
              : 'no BravenChartWorkbench ancestor',
          shadow: elsewhere.isEmpty
              ? null
              : _verdictFor(
                  chart,
                  (elsewhere.first.widget as BravenChartWorkbench)
                      .documentOptions,
                ),
        ),
      );
      continue;
    }

    final controller = chart.bravenChartController;
    if (controller == null) {
      _census.add(
        _Verdict(
          page: page.name,
          state: state,
          chart: name,
          family: _familyOf(chart),
          outcome: 'no-controller',
          detail: 'the chart carries no controller to read a document off',
        ),
      );
      continue;
    }

    // THE PAGE'S OWN OPTIONS. This preserves optional host binding identities
    // as well as every formatter descriptor declared by the mounted surface.
    final extracted = controller.extractSourceDocument(
      workbench.documentOptions,
    );
    if (extracted is ChartArtifactFailure<ChartDocumentSnapshot>) {
      _census.add(
        _Verdict(
          page: page.name,
          state: state,
          chart: name,
          family: _familyOf(chart),
          outcome: 'extract-failed',
          detail: '${extracted.error.code}: ${extracted.error.message}',
        ),
      );
      continue;
    }

    final generated = ChartGrammarSourceGenerator.generate(
      (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value,
      options: const ChartGrammarSourceOptions(variableName: 'chart'),
    );
    if (generated is ChartArtifactFailure<ChartGeneratedSource>) {
      _census.add(
        _Verdict(
          page: page.name,
          state: state,
          chart: name,
          family: _familyOf(chart),
          outcome: 'generate-failed',
          detail: '${generated.error.code}: ${generated.error.message}',
        ),
      );
      continue;
    }

    final source =
        (generated as ChartArtifactSuccess<ChartGeneratedSource>).value;
    final emitted = source.source.contains('= BravenChart.of(');
    _census.add(
      _Verdict(
        page: page.name,
        state: state,
        chart: name,
        family: _familyOf(chart),
        outcome: emitted ? 'emitting' : 'refused',
        detail: emitted ? '' : _firstBlocker(source.source),
        isComplete: source.isComplete,
        warningCount: source.warnings.length,
      ),
    );
  }
}

/// `emitting`, `refused`, or the failure that stopped either — for [chart]
/// read with [options].
///
/// Used only for the SHADOW column. The main path reports the same decision in
/// full detail; this one only has to say which side of the line it fell on.
String _verdictFor(BravenChartPlus chart, ChartDocumentExtractOptions options) {
  final controller = chart.bravenChartController;
  if (controller == null) return 'no-controller';
  final extracted = controller.extractSourceDocument(options);
  if (extracted is ChartArtifactFailure<ChartDocumentSnapshot>) {
    return 'extract-failed(${extracted.error.code})';
  }
  final generated = ChartGrammarSourceGenerator.generate(
    (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value,
    options: const ChartGrammarSourceOptions(variableName: 'chart'),
  );
  if (generated is ChartArtifactFailure<ChartGeneratedSource>) {
    return 'generate-failed(${generated.error.code})';
  }
  final source =
      (generated as ChartArtifactSuccess<ChartGeneratedSource>).value.source;
  return source.contains('= BravenChart.of(') ? 'emitting' : 'refused';
}

/// The workbench [element] is mounted inside, found through the ELEMENT tree so
/// no per-page key table can go stale against the page.
BravenChartWorkbench? _ancestorWorkbench(Element element) {
  BravenChartWorkbench? found;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is BravenChartWorkbench) {
      found = ancestor.widget as BravenChartWorkbench;
      return false;
    }
    return true;
  });
  return found;
}

/// The chart's own key, or its title, or its position — in that order, so a
/// report line always names something a reader can find in the page source.
String _chartName(BravenChartPlus chart, int index) {
  final key = chart.key;
  if (key is ValueKey<String>) return key.value;
  final title = chart.title;
  if (title != null && title.isNotEmpty) return '#$index "$title"';
  return 'chart#$index';
}

/// Records every example chip the page mounts that [states] does not walk.
void _recordUncensusedChips(
  WidgetTester tester,
  _CensusPage page,
  List<String> states,
) {
  final chips = <String>{};
  void visit(Element element) {
    final widget = element.widget;
    if (widget is ShowcaseExampleChoiceChip || widget is PlaygroundChoiceChip) {
      final key = widget.key;
      if (key is ValueKey<String>) chips.add(key.value);
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement!.visitChildren(visit);
  final missed = chips.difference(states.toSet());
  if (missed.isNotEmpty) _uncensusedChips[page.name] = missed;
}

/// Every `ValueKey<String>` in the live tree starting with one of [prefixes].
List<String> _discoverStates(WidgetTester tester, List<String> prefixes) {
  if (prefixes.isEmpty) return const <String>[];
  final found = <String>[];
  void visit(Element element) {
    final key = element.widget.key;
    if (key is ValueKey<String> &&
        prefixes.any(key.value.startsWith) &&
        !found.contains(key.value)) {
      found.add(key.value);
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement!.visitChildren(visit);
  // Containers named with the same prefix are not states.
  found.removeWhere(
    (value) =>
        value.endsWith('-picker') ||
        value.endsWith('-wrap') ||
        value.endsWith('-scroll') ||
        value.endsWith('-selector') ||
        value.endsWith('-grid'),
  );
  return found;
}

String _stateLabel(String key, List<String> prefixes) {
  for (final prefix in prefixes) {
    if (key.startsWith(prefix) && key.length > prefix.length) {
      return key.substring(prefix.length);
    }
  }
  return key;
}

/// The FIRST blocking sentence in a refusal, which is the gate that fired.
String _firstBlocker(String source) {
  final lines = source.split('\n');
  final buffer = StringBuffer();
  var started = false;
  for (final line in lines) {
    if (!line.startsWith('//')) continue;
    final text = line.substring(2).trim();
    if (text.startsWith('The grammar chain was not emitted')) continue;
    if (text.isEmpty) {
      if (started) break;
      continue;
    }
    if (text.startsWith('Switch this pane')) break;
    started = true;
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(text);
  }
  return buffer.toString();
}

/// The named gap a refusal sentence reports, collapsed to the bucket the
/// roadmap's blocker table is written in.
///
/// The sentence itself names the offending series, so counting raw sentences
/// splits one gap across as many buckets as there are series ids. Both forms
/// are printed: the bucket is the number the roadmap carries, the raw sentence
/// is what makes it checkable.
String _blockerBucket(String detail) {
  const named = <String, String>{
    'It carries a bar style': 'bar style',
    'one row list cannot express series whose x domains differ':
        'shared-x alignment (series with divergent x domains)',
    'It carries a fill gradient': 'fill gradient',
    'It carries a path animation': 'path animation',
    'It carries a split baseline fill': 'split baseline fill',
    'It carries a line glow': 'line glow',
    'It carries a jitter configuration': 'jitter',
    'It carries a non-default render mode': 'render mode',
    'It carries a data-point marker radius': 'data-point marker radius',
    'It carries a data-point marker style': 'data-point marker style',
    'These annotations have no chain verb':
        'annotation with no chain verb (Range/Legend)',
    'No mark measures against the axis': 'an axis no mark measures against',
    'normalizationMode: perSeries': 'normalizationMode: perSeries',
    'legendStyle': 'chart-level legendStyle',
  };
  for (final entry in named.entries) {
    if (detail.contains(entry.key)) return entry.value;
  }
  if (detail.contains('has no mark to reverse it')) {
    // No `RangeAreaChartSeries` bucket: `RangeAreaMark` reverses that family
    // now, so a band that still refuses names the FIELD it carries — a fill
    // gradient or a path animation, both roadmap 1d — through the `named` map
    // above. Keeping a bucket here that nothing can reach would read as an
    // outstanding family gap that no longer exists.
    if (detail.contains('RadialBarChartSeries')) return 'no radial-bar mark';
    if (detail.contains('GaugeChartSeries')) return 'no gauge mark';
    return 'no mark for this family';
  }
  if (detail.contains(
    'normally a series, annotation or axis option that no V1 mark carries',
  )) {
    // Unnamed residual: the proof knows the reconstruction differs but no
    // clause claims the difference. Split by SUBJECT so it stays actionable.
    final subject = RegExp(
      r'reproduce (series|annotation) "([^"]+)"',
    ).firstMatch(detail);
    return 'unnamed residual loss on ${subject?.group(1) ?? 'a value'} '
        '"${subject?.group(2) ?? '?'}"';
  }
  return detail;
}

/// Settles a page that may hold a continuous animation or a stream timer.
Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 8),
    );
  } on Object {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }
}

void _report() {
  final buffer = StringBuffer()
    ..writeln('')
    ..writeln('=' * 78)
    ..writeln('GRAMMAR EMISSION CENSUS')
    ..writeln('=' * 78);

  for (final page in _censusPages) {
    final rows = _census.where((v) => v.page == page.name).toList();
    if (rows.isEmpty) continue;
    final emitting = rows.where((v) => v.outcome == 'emitting').length;
    final verdicts = rows.where((v) => v.hasVerdict).length;
    final families =
        (rows
            .where((v) => v.hasVerdict)
            .map((v) => v.family.name)
            .toSet()
            .toList()
          ..sort());
    buffer.writeln(
      '\n## ${page.name} (${families.isEmpty ? '-' : families.join('+')}) — '
      '$emitting emitting of $verdicts with a verdict, ${rows.length} tuples',
    );
    for (final row in rows) {
      final flags = row.outcome == 'emitting'
          ? (row.isComplete ? 'complete' : '${row.warningCount} warning(s)')
          : row.detail;
      final shadow = row.shadow == null ? '' : ' [shadow: ${row.shadow}]';
      buffer.writeln(
        '  ${row.outcome.padRight(16)} ${row.family.name.padRight(9)} '
        '${row.state}|${row.chart}  $flags$shadow',
      );
    }
  }

  final verdicts = _census.where((v) => v.hasVerdict).toList();
  final emitting = verdicts.where((v) => v.outcome == 'emitting').toList();
  buffer
    ..writeln('')
    ..writeln('-' * 78)
    ..writeln('TOTAL TUPLES        ${_census.length}')
    ..writeln('WITH A VERDICT      ${verdicts.length}')
    ..writeln('EMITTING            ${emitting.length}')
    ..writeln('REFUSED             ${verdicts.length - emitting.length}');
  for (final family in _Family.values) {
    final rows = verdicts.where((v) => v.family == family).toList();
    buffer.writeln(
      '  ${family.name.padRight(18)}'
      '${rows.where((v) => v.outcome == 'emitting').length} of ${rows.length}',
    );
  }
  final other = _census.where((v) => !v.hasVerdict).toList();
  buffer.writeln('NO VERDICT          ${other.length}');
  for (final outcome in other.map((v) => v.outcome).toSet().toList()..sort()) {
    buffer.writeln(
      '  ${outcome.padRight(18)}'
      '${other.where((v) => v.outcome == outcome).length}',
    );
  }

  final shadowed = _census.where((v) => v.shadow != null).toList();
  if (shadowed.isNotEmpty) {
    final shadowEmitting = shadowed.where((v) => v.shadow == 'emitting').length;
    buffer
      ..writeln('')
      ..writeln(
        'SHADOW — charts with NO Grammar pane, read with the page\'s only '
        'workbench options',
      )
      ..writeln('  ${shadowed.length} charts, $shadowEmitting would emit')
      ..writeln(
        '  admitting them reads '
        '${verdicts.length + shadowed.length} with a verdict / '
        '${emitting.length + shadowEmitting} emitting',
      );
    for (final row in shadowed) {
      buffer.writeln(
        '    ${row.shadow!.padRight(10)} ${row.page}|${row.state}|${row.chart}',
      );
    }
  }

  if (_uncensusedChips.isNotEmpty) {
    buffer.writeln('\nCHIPS NOT WALKED (orthogonal pickers)');
    for (final entry in _uncensusedChips.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value.toList()..sort()}');
    }
  }

  final refused = verdicts.where((v) => v.outcome == 'refused').toList();
  for (final scope in <List<Object>>[
    <Object>['ALL', refused],
    <Object>[
      'CARTESIAN',
      refused.where((v) => v.family == _Family.cartesian).toList(),
    ],
    <Object>[
      'RADIAL',
      refused.where((v) => v.family == _Family.radial).toList(),
    ],
  ]) {
    final rows = scope[1] as List<_Verdict>;
    buffer.writeln(
      '\nBLOCKER DISTRIBUTION — ${scope[0]} (${rows.length} refused)',
    );
    final buckets = <String, int>{};
    for (final row in rows) {
      buckets.update(
        _blockerBucket(row.detail),
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    final ordered = buckets.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    for (final entry in ordered) {
      buffer.writeln('  ${entry.value.toString().padLeft(3)}  ${entry.key}');
    }
  }

  buffer.writeln('\nRAW REFUSAL SENTENCES');
  final raw = <String, int>{};
  for (final row in refused) {
    raw.update(row.detail, (n) => n + 1, ifAbsent: () => 1);
  }
  final rawOrdered = raw.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in rawOrdered) {
    buffer.writeln('  ${entry.value.toString().padLeft(3)}  ${entry.key}');
  }
  buffer.writeln('=' * 78);

  // ignore: avoid_print
  print(buffer);
}
