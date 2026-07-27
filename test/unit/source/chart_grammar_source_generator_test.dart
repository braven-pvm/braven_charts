// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// ROUND TRIP for grammar-chain source generation.
///
/// The claim under test is not "the generator produced some text". It is:
///
/// > a chart document, put through [ChartGrammarSourceGenerator], yields a
/// > grammar chain that COMPILES and that REBUILDS THE SAME CHART.
///
/// So every supported shape runs three assertions:
///
/// 1. the generated Dart formats and analyzes (`expectGeneratedSourceCompiles`),
/// 2. the generated Dart contains the synthesised row type and the chain verbs
///    the shape calls for, and
/// 3. the equivalent chain, written out in this file over a synthesised row
///    type with the field names the generator chose, extracts a chart document
///    EQUAL to the original one.
///
/// (3) is the semantic half: the generator's own internal proof lowers the
/// reconstructed spec and compares config objects, and this file closes the
/// loop at the document level, through the ordinary mount-and-extract path.
///
/// The diagnostics group is the other half of the contract: every row of the
/// fidelity matrix must produce a NAMED diagnostic and NO code, because a
/// chain that would render a different chart is worse than no chain at all.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/generated_source_compile.dart';

// ===========================================================================
// The chart-side row type — the AUTHOR'S own class, which the generator never
// sees and cannot recover.
// ===========================================================================

class Sample {
  const Sample({
    required this.t,
    this.power = 0,
    this.heartRate = 0,
    this.effort = 0,
    this.zone = '',
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
  });

  final double t;
  final double power;
  final double heartRate;
  final double effort;
  final String zone;
  final double open;
  final double high;
  final double low;
  final double close;
}

double sampleT(Sample row) => row.t;
double samplePower(Sample row) => row.power;
double sampleHeartRate(Sample row) => row.heartRate;
double sampleEffort(Sample row) => row.effort;
Object sampleZone(Sample row) => row.zone;
double sampleOpen(Sample row) => row.open;
double sampleHigh(Sample row) => row.high;
double sampleLow(Sample row) => row.low;
double sampleClose(Sample row) => row.close;

const rows = <Sample>[
  Sample(
    t: 0,
    power: 168,
    heartRate: 112,
    effort: 2,
    zone: 'Endurance',
    open: 118,
    high: 124,
    low: 116,
    close: 122,
  ),
  Sample(
    t: 1,
    power: 204,
    heartRate: 133,
    effort: 4,
    zone: 'Endurance',
    open: 122,
    high: 129,
    low: 121,
    close: 127,
  ),
  Sample(
    t: 2,
    power: 268,
    heartRate: 162,
    effort: 7,
    zone: 'Tempo',
    open: 127,
    high: 133,
    low: 119,
    close: 131,
  ),
];

const List<ScatterCategoryStyle> zoneStyles = <ScatterCategoryStyle>[
  ScatterCategoryStyle(key: 'Endurance', color: Color(0xFF16A34A)),
  ScatterCategoryStyle(key: 'Tempo', color: Color(0xFFF59E0B)),
];

// ===========================================================================
// The SYNTHESISED row type — what the generator emits, written out here so the
// rebuilt chain is the one a reader would copy out of the Source pane.
// ===========================================================================

class GrammarRow {
  const GrammarRow({
    required this.x,
    this.power = 0,
    this.heartRate = 0,
    this.efforts = 0,
    this.effortsCategory = '',
    this.priceOpen = 0,
    this.priceHigh = 0,
    this.priceLow = 0,
    this.priceClose = 0,
    this.timeInZone = 0,
  });

  final double x;
  final double power;
  final double heartRate;
  final double efforts;
  final String effortsCategory;
  final double priceOpen;
  final double priceHigh;
  final double priceLow;
  final double priceClose;
  final double timeInZone;
}

final List<GrammarRow> grammarRows = <GrammarRow>[
  for (final row in rows)
    GrammarRow(
      x: row.t,
      power: row.power,
      heartRate: row.heartRate,
      efforts: row.effort,
      effortsCategory: row.zone,
      priceOpen: row.open,
      priceHigh: row.high,
      priceLow: row.low,
      priceClose: row.close,
      timeInZone: row.power,
    ),
];

/// Scatter rows are keyed on power, so the synthesised x is power there.
final List<GrammarRow> scatterRows = <GrammarRow>[
  for (final row in rows)
    GrammarRow(
      x: row.power,
      heartRate: row.heartRate,
      efforts: row.effort,
      effortsCategory: row.zone,
    ),
];

// ===========================================================================
// RADIAL fixtures — the author's row type, its accessors, and the synthesised
// radial row the generator emits (category/value[/ring]).
// ===========================================================================

class Harvest {
  const Harvest({required this.fruit, required this.count, this.season = ''});

  final String fruit;
  final double count;
  final String season;
}

Object harvestFruit(Harvest row) => row.fruit;
double harvestCount(Harvest row) => row.count;
Object harvestSeason(Harvest row) => row.season;

const harvest = <Harvest>[
  Harvest(fruit: 'Apple', count: 42, season: 'Winter'),
  Harvest(fruit: 'Pear', count: 31, season: 'Winter'),
  Harvest(fruit: 'Plum', count: 17, season: 'Summer'),
  Harvest(fruit: 'Fig', count: 10, season: 'Summer'),
];

/// The SYNTHESISED radial row: the generator names the string category field
/// `category`, the number value field `value`, and — for a concentric donut —
/// the string ring field `ring`.
class RadialGrammarRow {
  const RadialGrammarRow({
    required this.category,
    required this.value,
    this.ring = '',
  });

  final String category;
  final double value;
  final String ring;
}

final List<RadialGrammarRow> radialGrammarRows = <RadialGrammarRow>[
  for (final row in harvest)
    RadialGrammarRow(category: row.fruit, value: row.count),
];

/// The concentric rows are concatenated in first-seen ring order (Winter, then
/// Summer), each carrying its ring key.
final List<RadialGrammarRow> concentricGrammarRows = <RadialGrammarRow>[
  for (final row in harvest)
    RadialGrammarRow(category: row.fruit, value: row.count, ring: row.season),
];

// ---------------------------------------------------------------------------
// STYLED radial fixtures. These are the series-level styling every showcase
// radial chart carries (pieStyle / donutStyle / polarStyle + dataLabels); the
// mark carries them through to the geom* verb's `style:` / `dataLabels:` args.
// Each value is validly constructible INSIDE its series (pie radiusFactor in
// (0, 1]; donut innerRadiusFactor in (0, 1)).
// ---------------------------------------------------------------------------

const styledPieStyle = PieChartStyle(
  startAngleDegrees: 30,
  clockwise: false,
  radiusFactor: 0.8,
  sliceGap: 4,
  borderWidth: 2,
);

const styledPieLabels = PieDataLabelConfig(
  position: PieDataLabelPosition.inside,
  minimumShare: 0.05,
  padding: 10,
);

const styledDonutStyle = DonutChartStyle(
  innerRadiusFactor: 0.4,
  sliceGap: 3,
  borderWidth: 2,
);

const styledPolarStyle = PolarColumnStyle(
  cornerRadius: 6,
  opacity: 0.9,
  borderWidth: 2,
);

// ---------------------------------------------------------------------------
// SERIES-CONFIG radial fixtures. Beyond the style/dataLabels the marks already
// carried, the real showcase charts set reproducible SERIES config — a unit, a
// durable-selection style, small-slice grouping and (pie/donut) a variable
// slice-radius encoding. The marks now carry these too, so a chart that sets
// them EMITS instead of being refused by the round-trip proof.
// ---------------------------------------------------------------------------

const showcaseSelection = RadialSelectionStyle(
  effect: RadialSelectionEffect.lift,
  liftScale: 1.12,
  liftOffset: 8,
  backdropBlur: 1.5,
);

const showcaseGrouping = RadialSliceGroupingConfig(
  minimumShare: 0.08,
  label: 'Other',
);

/// A slice-radius encoding with NO formatter — every field is a Dart literal,
/// so it emits a complete `sliceRadiusConfig:` argument.
const showcaseRadius = PieSliceRadiusConfig(
  minimumFactor: 0.4,
  scale: PieSliceRadiusScale.linear,
  label: 'Area',
  unit: 'km2',
);

/// A radius-bearing synthesised radial row: category / value / radius.
class RadialRadiusRow {
  const RadialRadiusRow({
    required this.category,
    required this.value,
    required this.radius,
  });

  final String category;
  final double value;
  final double radius;
}

const _harvestRadii = <String, num>{
  'Apple': 12,
  'Pear': 9,
  'Plum': 6,
  'Fig': 3,
};

final List<RadialRadiusRow> radiusGrammarRows = <RadialRadiusRow>[
  for (final row in harvest)
    RadialRadiusRow(
      category: row.fruit,
      value: row.count,
      radius: _harvestRadii[row.fruit]!.toDouble(),
    ),
];

// ===========================================================================
// Harness
// ===========================================================================

Future<ChartDocumentSnapshot> snapshotOf(
  WidgetTester tester,
  Widget Function(BravenChartController controller) child,
) async {
  final controller = BravenChartController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 600, height: 400, child: child(controller)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final result = controller.extractDocument();
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

ChartGeneratedSource generateGrammar(
  ChartDocumentSnapshot snapshot, {
  ChartGrammarSourceOptions options = const ChartGrammarSourceOptions(
    variableName: 'grammarChart',
  ),
}) {
  final result = ChartGrammarSourceGenerator.generate(
    snapshot,
    options: options,
  );
  expect(
    result,
    isA<ChartArtifactSuccess<ChartGeneratedSource>>(),
    reason: 'grammar generation failed outright',
  );
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

/// Runs the full round trip for one shape.
Future<ChartGeneratedSource> expectRoundTrip(
  WidgetTester tester, {
  required String name,
  required Widget Function(BravenChartController) original,
  required Widget Function(BravenChartController) rebuilt,
  Iterable<String> fragments = const <String>[],
}) async {
  final snapshot = await snapshotOf(tester, original);
  final generated = generateGrammar(snapshot);

  expect(
    generated.warnings,
    isEmpty,
    reason:
        'a supported shape must emit a clean chain:\n'
        '${generated.warnings.map((w) => w.message).join('\n')}',
  );
  expect(generated.isComplete, isTrue);
  for (final fragment in fragments) {
    expect(
      generated.source,
      contains(fragment),
      reason: 'missing "$fragment" in:\n${generated.source}',
    );
  }
  // `dart format` / `dart analyze` are REAL subprocesses, and a widget test
  // runs inside a fake-async zone where real I/O never completes. runAsync is
  // the documented escape hatch.
  await tester.runAsync(
    () => expectGeneratedSourceCompiles(
      generated.source,
      fixtureName: 'grammar_source_$name',
    ),
  );

  final rebuiltSnapshot = await snapshotOf(tester, rebuilt);
  expect(
    rebuiltSnapshot.document.toJson(),
    snapshot.document.toJson(),
    reason: 'the rebuilt chain produced a different chart document',
  );
  return generated;
}

/// Re-reads [snapshot]'s document with [patch] applied to its JSON.
///
/// A few fidelity-matrix rows describe charts the RENDER pipeline itself
/// rejects — mixed bar orientations throw, and an un-descriptored interaction
/// callback fails extraction — so they cannot be produced by mounting one.
/// Patching a real extracted document keeps the input honest without asking
/// the package to render something it refuses to.
ChartDocumentSnapshot patchedSnapshot(
  ChartDocumentSnapshot snapshot,
  void Function(Map<String, Object?> json) patch,
) {
  final json = snapshot.document.toJson();
  patch(json);
  return ChartDocumentSnapshot(
    document: ChartDocument.fromJson(json),
    viewState: snapshot.viewState,
  );
}

/// Whether a chain was actually emitted.
///
/// Matched on the ASSIGNMENT, not on `BravenChart.of(` alone: several
/// diagnostics quote the chain's own entry point while explaining why it does
/// not fit, and a comment that mentions the API is not code that calls it.
bool emittedChain(ChartGeneratedSource generated) =>
    generated.source.contains('= BravenChart.of(');

/// The first blocking diagnostic message, or null when the chain was emitted.
String? blockedReason(ChartGeneratedSource generated) {
  if (emittedChain(generated)) return null;
  return generated.warnings.isEmpty ? '' : generated.warnings.first.message;
}

void main() {
  group('round trip', () {
    testWidgets('shape 1: a single line', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'single_line',
        fragments: <String>[
          'class GrammarRow {',
          'final double x;',
          'final double power;',
          'BravenChart.of(rows)',
          '.geomLine(',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power', strokeWidth: 2.4)
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              strokeWidth: 2.4,
              yAxisId: 'axis-0',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 2: multi-series on a shared x', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'shared_x',
        fragments: <String>[
          'final double power;',
          'final double heartRate;',
          '.geomArea(',
          '.geomLine(',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Watts')
            .geomArea(name: 'Power', fillOpacity: 0.18)
            .geomLine(y: sampleHeartRate, name: 'Heart rate')
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Watts',
              ),
            )
            .geomArea(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              fillOpacity: 0.18,
              yAxisId: 'axis-0',
            )
            .geomLine(
              id: 'mark-1',
              y: (row) => row.heartRate,
              name: 'Heart rate',
              yAxisId: 'axis-0',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 3: multi-axis', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'multi_axis',
        fragments: <String>[
          "YAxisConfig.withId(",
          "id: 'watts'",
          "id: 'bpm'",
          "yAxisId: 'watts'",
          "yAxisId: 'bpm'",
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'watts',
                position: YAxisPosition.left,
                label: 'Power',
                unit: 'W',
              ),
            )
            .yAxis(
              YAxisConfig.withId(
                id: 'bpm',
                position: YAxisPosition.right,
                label: 'Heart rate',
                unit: 'bpm',
              ),
            )
            .geomArea(
              id: 'power',
              y: samplePower,
              name: 'Power',
              yAxisId: 'watts',
              color: const Color(0xFF2563EB),
              fillOpacity: 0.18,
            )
            .geomLine(
              id: 'hr',
              y: sampleHeartRate,
              name: 'Heart rate',
              yAxisId: 'bpm',
              color: const Color(0xFFDC2626),
              strokeWidth: 2.2,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'watts',
                position: YAxisPosition.left,
                label: 'Power',
                unit: 'W',
              ),
            )
            .yAxis(
              YAxisConfig.withId(
                id: 'bpm',
                position: YAxisPosition.right,
                label: 'Heart rate',
                unit: 'bpm',
              ),
            )
            .geomArea(
              id: 'power',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'watts',
              color: const Color(0xFF2563EB),
              fillOpacity: 0.18,
            )
            .geomLine(
              id: 'hr',
              y: (row) => row.heartRate,
              name: 'Heart rate',
              yAxisId: 'bpm',
              color: const Color(0xFFDC2626),
              strokeWidth: 2.2,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 4: scatter with channels', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'scatter_channels',
        fragments: <String>[
          '.geomPoint(',
          'size: Channel(',
          'categoryBy: CategoryChannel(',
          'sizeEncoding: ScatterSizeEncoding(',
          'categories: [',
          'final String effortsCategory;',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(samplePower, label: 'Power')
            .y(sampleHeartRate, label: 'Heart rate')
            .geomPoint(
              name: 'Efforts',
              size: const Channel<Sample>(sampleEffort),
              sizeEncoding: const ScatterSizeEncoding(
                minimumRadius: 4,
                maximumRadius: 14,
                label: 'Effort',
              ),
              categoryBy: const CategoryChannel<Sample>(
                sampleZone,
                label: 'Zone',
              ),
              categories: zoneStyles,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(scatterRows)
            .x((row) => row.x, label: 'Power')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Heart rate',
              ),
            )
            .geomPoint(
              id: 'mark-0',
              y: (row) => row.heartRate,
              name: 'Efforts',
              yAxisId: 'axis-0',
              size: Channel<GrammarRow>((row) => row.efforts),
              sizeEncoding: const ScatterSizeEncoding(
                minimumRadius: 4,
                maximumRadius: 14,
                label: 'Effort',
              ),
              categoryBy: CategoryChannel<GrammarRow>(
                (row) => row.effortsCategory,
                label: 'Zone',
              ),
              categories: zoneStyles,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 5: candlestick', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'candlestick',
        fragments: <String>[
          '.geomCandlestick(',
          'final double priceOpen;',
          'final double priceClose;',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Session')
            .yAxis(
              YAxisConfig.withId(
                id: 'price',
                position: YAxisPosition.right,
                label: 'Price',
                unit: 'USD',
              ),
            )
            .geomCandlestick(
              open: sampleOpen,
              high: sampleHigh,
              low: sampleLow,
              close: sampleClose,
              name: 'Price',
              yAxisId: 'price',
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Session')
            .yAxis(
              YAxisConfig.withId(
                id: 'price',
                position: YAxisPosition.right,
                label: 'Price',
                unit: 'USD',
              ),
            )
            .geomCandlestick(
              id: 'mark-0',
              open: (row) => row.priceOpen,
              high: (row) => row.priceHigh,
              low: (row) => row.priceLow,
              close: (row) => row.priceClose,
              name: 'Price',
              yAxisId: 'price',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 6: transposed bars', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'transposed_bars',
        fragments: <String>['.geomBar(', '.transposed()'],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Zone')
            .y(samplePower, label: 'Minutes')
            .geomBar(
              name: 'Time in zone',
              color: const Color(0xFF7C3AED),
              barWidthPercent: 0.7,
            )
            .transposed()
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Zone')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Minutes',
              ),
            )
            .geomBar(
              id: 'mark-0',
              y: (row) => row.timeInZone,
              name: 'Time in zone',
              color: const Color(0xFF7C3AED),
              barWidthPercent: 0.7,
              yAxisId: 'axis-0',
            )
            .transposed()
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 8: a non-default interaction round-trips', (
      tester,
    ) async {
      // xAxis, theme and interaction are carried verbatim through lowering, so
      // the round-trip proof must ALSO compare them (not just series /
      // annotations / Y-axes). This shape sets a non-default interaction so the
      // chain emits `.interaction(...)` and the emitted-source round trip is
      // what guards its fidelity.
      await expectRoundTrip(
        tester,
        name: 'interaction',
        fragments: <String>[
          '.interaction(',
          'InteractionConfig(',
          'CrosshairDisplayMode.tracking',
          'persistOnPointerExit: true',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .interaction(
              const InteractionConfig(
                crosshair: CrosshairConfig(
                  displayMode: CrosshairDisplayMode.tracking,
                  persistOnPointerExit: true,
                ),
              ),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .interaction(
              const InteractionConfig(
                crosshair: CrosshairConfig(
                  displayMode: CrosshairDisplayMode.tracking,
                  persistOnPointerExit: true,
                ),
              ),
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 9: per-mark data-point markers and labels round-trip', (
      tester,
    ) async {
      // The headline V2.0 fix: line and area marks now carry
      // showDataPointMarkers and a dataPointLabels configuration, so a chart
      // using them round-trips through the emitted chain instead of blocking.
      await expectRoundTrip(
        tester,
        name: 'data_point_markers',
        fragments: <String>[
          'showDataPointMarkers: true',
          'dataPointLabels: DataPointLabelConfig(',
          'position: DataPointLabelPosition.below',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Watts')
            .geomArea(
              name: 'Power',
              showDataPointMarkers: true,
              dataPointLabels: const DataPointLabelConfig(
                show: true,
                position: DataPointLabelPosition.below,
              ),
            )
            .geomLine(
              y: sampleHeartRate,
              name: 'Heart rate',
              showDataPointMarkers: true,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Watts',
              ),
            )
            .geomArea(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              showDataPointMarkers: true,
              dataPointLabels: const DataPointLabelConfig(
                show: true,
                position: DataPointLabelPosition.below,
              ),
              yAxisId: 'axis-0',
            )
            .geomLine(
              id: 'mark-1',
              y: (row) => row.heartRate,
              name: 'Heart rate',
              showDataPointMarkers: true,
              yAxisId: 'axis-0',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 10: a bar label style round-trips', (tester) async {
      // Bars have no per-point marker toggle; their inline-label field is
      // `labelStyle` (BarLabelStyle). BarMark now carries it, so a bar chart
      // with a non-default label style round-trips instead of blocking.
      await expectRoundTrip(
        tester,
        name: 'bar_label_style',
        fragments: <String>[
          'labelStyle: BarLabelStyle(',
          'show: true',
          'showUnit: true',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Zone')
            .y(samplePower, label: 'Minutes')
            .geomBar(
              name: 'Time in zone',
              barWidthPercent: 0.7,
              labelStyle: const BarLabelStyle(show: true, showUnit: true),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Zone')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Minutes',
              ),
            )
            .geomBar(
              id: 'mark-0',
              y: (row) => row.timeInZone,
              name: 'Time in zone',
              barWidthPercent: 0.7,
              labelStyle: const BarLabelStyle(show: true, showUnit: true),
              yAxisId: 'axis-0',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 7: a trend annotation becomes .trend(of:)', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'trend',
        fragments: <String>[".trend(", "of: 'mark-0'"],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .trend(method: TrendType.linear, name: 'Trend')
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .trend(
              id: 'mark-1',
              of: 'mark-0',
              method: TrendType.linear,
              name: 'Trend',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 8: a threshold annotation becomes .threshold(', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'threshold',
        fragments: <String>[
          '.threshold(',
          'value: 250',
          'axis: AnnotationAxis.y',
          "label: 'FTP'",
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .threshold(
              value: 250,
              axis: AnnotationAxis.y,
              label: 'FTP',
              color: const Color(0xFF16A34A),
              strokeWidth: 2,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .threshold(
              id: 'mark-1',
              value: 250,
              axis: AnnotationAxis.y,
              label: 'FTP',
              color: const Color(0xFF16A34A),
              strokeWidth: 2,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 9: a range annotation becomes .band(', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'band',
        fragments: <String>[
          '.band(',
          'start: 200',
          'end: 260',
          'axis: AnnotationAxis.y',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .band(
              start: 200,
              end: 260,
              axis: AnnotationAxis.y,
              label: 'Zone',
              color: const Color(0x332563EB),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .band(
              id: 'mark-1',
              start: 200,
              end: 260,
              axis: AnnotationAxis.y,
              label: 'Zone',
              color: const Color(0x332563EB),
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 10: a point annotation becomes .pointAt(', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'point',
        fragments: <String>[
          '.pointAt(',
          "seriesId: 'mark-0'",
          'dataPointIndex: 1',
          'markerShape: MarkerShape.star',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .pointAt(
              seriesId: 'mark-0',
              dataPointIndex: 1,
              label: 'Peak',
              color: const Color(0xFFDC2626),
              markerSize: 12,
              markerShape: MarkerShape.star,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .pointAt(
              id: 'mark-1',
              seriesId: 'mark-0',
              dataPointIndex: 1,
              label: 'Peak',
              color: const Color(0xFFDC2626),
              markerSize: 12,
              markerShape: MarkerShape.star,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 11: chart-level grid, title and legend are emitted', (
      tester,
    ) async {
      // The "Bar" diagnostic the owner saw was "chart-level options would be
      // lost: grid". A non-default grid — with a title, a subtitle and a hidden
      // legend — must now EMIT `.grid(` / `.title(` / `.legend(false)` and
      // round-trip to the same document, not block.
      await expectRoundTrip(
        tester,
        name: 'chart_options',
        fragments: <String>[
          '.grid(',
          'GridConfig(',
          'horizontal: false',
          '.title(',
          "'Session'",
          "subtitle: 'Power over time'",
          '.legend(false)',
        ],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .grid(const GridConfig(horizontal: false, verticalStrokeWidth: 1.5))
            .title('Session', subtitle: 'Power over time')
            .legend(false)
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x, label: 'Elapsed')
            .yAxis(
              YAxisConfig.withId(
                id: 'axis-0',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              yAxisId: 'axis-0',
            )
            .grid(const GridConfig(horizontal: false, verticalStrokeWidth: 1.5))
            .title('Session', subtitle: 'Power over time')
            .legend(false)
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 12: a pie emits geomPie and round-trips', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'pie',
        fragments: <String>[
          'final String category;',
          'final double value;',
          '.geomPie(',
          'category: (row) => row.category',
          'value: (row) => row.value',
          "name: 'Harvest'",
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomPie(category: harvestFruit, value: harvestCount, name: 'Harvest')
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPie(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 13: a donut round-trips with its center preserved', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'donut',
        fragments: <String>[
          '.geomDonut(',
          'center: DonutCenterContent(',
          "label: 'Total'",
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
              center: const DonutCenterContent(label: 'Total'),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomDonut(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              center: const DonutCenterContent(label: 'Total'),
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 14: a concentric donut emits geomDonut(ring:) and '
        'round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'concentric_donut',
        fragments: <String>[
          'final String ring;',
          '.geomDonut(',
          'ring: (row) => row.ring',
          "id: 'seasons'",
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 15: a single-distinct-ring donut is captured as a plain '
        'donut', (tester) async {
      // Every row shares one ring value, so the forward path COLLAPSES to a
      // single DonutChartSeries. The render source only stamps a
      // concentricDonutConfig when MORE THAN ONE donut series is present
      // (braven_chart_plus.dart: `whereType<DonutChartSeries>().length > 1`),
      // so a captured single-ring chart carries a NULL config — indistinguishable
      // from a plain donut — and faithfully emits a plain geomDonut (no ring:)
      // that round-trips. The concentricDonutConfig discriminator is
      // authoritative, but the render rule means it is never non-null with one
      // donut.
      const oneSeason = <Harvest>[
        Harvest(fruit: 'Apple', count: 42, season: 'All year'),
        Harvest(fruit: 'Pear', count: 31, season: 'All year'),
      ];
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_single_ring',
        fragments: <String>['.geomDonut('],
        original: (controller) => BravenChart.of(oneSeason)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) =>
            BravenChart.of(radialGrammarRows.take(2).toList())
                .geomDonut(
                  id: 'seasons-All year',
                  category: (row) => row.category,
                  value: (row) => row.value,
                  name: 'All year',
                )
                .build(bravenChartController: controller),
      );
      expect(generated.source, isNot(contains('ring:')));
    });

    testWidgets('shape 16: a default-config polar column round-trips', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'polar_column',
        fragments: <String>[
          '.geomPolar(',
          'category: (row) => row.category',
          'value: (row) => row.value',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomPolar(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPolar(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 17: a STYLED pie emits style + dataLabels and '
        'round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'pie_styled',
        fragments: <String>[
          '.geomPie(',
          'style: PieChartStyle(',
          'startAngleDegrees: 30',
          'clockwise: false',
          'sliceGap: 4',
          'dataLabels: PieDataLabelConfig(',
          'position: PieDataLabelPosition.inside',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomPie(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
              style: styledPieStyle,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPie(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledPieStyle,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 18: a STYLED donut emits style + center + dataLabels '
        'and round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'donut_styled',
        fragments: <String>[
          '.geomDonut(',
          'style: DonutChartStyle(',
          'innerRadiusFactor: 0.4',
          'sliceGap: 3',
          'center: DonutCenterContent(',
          "label: 'Total'",
          'dataLabels: PieDataLabelConfig(',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
              style: styledDonutStyle,
              center: const DonutCenterContent(label: 'Total'),
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomDonut(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledDonutStyle,
              center: const DonutCenterContent(label: 'Total'),
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 19: a STYLED concentric donut emits style + '
        'dataLabels and round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'concentric_styled',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          'style: DonutChartStyle(',
          'innerRadiusFactor: 0.4',
          'dataLabels: PieDataLabelConfig(',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
              style: styledDonutStyle,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              style: styledDonutStyle,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 20: a STYLED polar column emits style and round-trips', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'polar_styled',
        fragments: <String>[
          '.geomPolar(',
          'style: PolarColumnStyle(',
          'cornerRadius: 6',
          'opacity: 0.9',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomPolar(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
              style: styledPolarStyle,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPolar(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledPolarStyle,
            )
            .build(bravenChartController: controller),
      );
    });
  });

  // =========================================================================
  // SHOWCASE-REPRESENTATIVE: every showcase radial chart is built the way the
  // showcase pages build them — `<Family>ChartSeries.fromMap(..., <family>Style:
  // <Family>ChartStyle(...))` inside a `BravenChartPlus`. Before the styling was
  // carried onto the marks these were REFUSED by the round-trip proof; they must
  // now emit a real chain whose `style:`/`dataLabels:` reproduce the series.
  // =========================================================================
  group('showcase-representative styled radial charts emit', () {
    testWidgets('a fromMap pie with a pieStyle + dataLabels emits and '
        'round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'pie_fromMap_styled',
        fragments: <String>['.geomPie(', 'style: PieChartStyle('],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'harvest',
              name: 'Harvest',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              pieStyle: styledPieStyle,
              dataLabels: styledPieLabels,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPie(
              id: 'harvest',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledPieStyle,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('a fromMap donut with a donutStyle emits and round-trips', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'donut_fromMap_styled',
        fragments: <String>['.geomDonut(', 'style: DonutChartStyle('],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'harvest',
              name: 'Harvest',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              donutStyle: styledDonutStyle,
              centerContent: const DonutCenterContent(label: 'Total'),
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomDonut(
              id: 'harvest',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledDonutStyle,
              center: const DonutCenterContent(label: 'Total'),
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('a fromMap concentric composition with a donutStyle emits and '
        'round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'concentric_fromMap_styled',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          'style: DonutChartStyle(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'seasons-Winter',
              name: 'Winter',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              donutStyle: styledDonutStyle,
            ),
            DonutChartSeries.fromMap(
              id: 'seasons-Summer',
              name: 'Summer',
              values: const <String, num>{'Plum': 17, 'Fig': 10},
              donutStyle: styledDonutStyle,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              style: styledDonutStyle,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('a fromMap polar column with a polarStyle emits and '
        'round-trips', (tester) async {
      await expectRoundTrip(
        tester,
        name: 'polar_fromMap_styled',
        fragments: <String>['.geomPolar(', 'style: PolarColumnStyle('],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'harvest',
              name: 'Harvest',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              polarStyle: styledPolarStyle,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPolar(
              id: 'harvest',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
              style: styledPolarStyle,
            )
            .build(bravenChartController: controller),
      );
    });
  });

  // =========================================================================
  // The real showcase radial charts set MORE reproducible series config than
  // style/dataLabels: a unit, a durable-selection style, small-slice grouping
  // and a variable slice-radius encoding. The marks now carry these, so the
  // showcase-representative pie/donut/concentric/polar charts EMIT + round-trip
  // instead of being refused. See pie_charts_page.dart / donut_charts_page.dart
  // / concentric_donut_page.dart / polar_column_page.dart.
  // =========================================================================
  group('showcase-representative radial series config emits', () {
    testWidgets('a pie with unit + selectionStyle + sliceGroupingConfig + '
        'pieStyle emits and round-trips', (tester) async {
      final generated = await expectRoundTrip(
        tester,
        name: 'pie_series_config',
        fragments: <String>[
          '.geomPie(',
          "unit: 'USD'",
          'selectionStyle: RadialSelectionStyle(',
          'sliceGroupingConfig: RadialSliceGroupingConfig(',
          'style: PieChartStyle(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'pie-showcase',
              name: 'Revenue',
              unit: 'USD',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              pieStyle: styledPieStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
              dataLabels: styledPieLabels,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPie(
              id: 'pie-showcase',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Revenue',
              unit: 'USD',
              style: styledPieStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
              dataLabels: styledPieLabels,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a pie with a variable sliceRadiusConfig (no formatter) emits '
        'and round-trips', (tester) async {
      final generated = await expectRoundTrip(
        tester,
        name: 'pie_slice_radius',
        fragments: <String>[
          '.geomPie(',
          'radius: (row) => row.radius',
          'sliceRadiusConfig: PieSliceRadiusConfig(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'pie-radius',
              name: 'Revenue',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              radiusValues: _harvestRadii,
              sliceRadiusConfig: showcaseRadius,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radiusGrammarRows)
            .geomPie(
              id: 'pie-radius',
              category: (row) => row.category,
              value: (row) => row.value,
              radius: (row) => row.radius,
              name: 'Revenue',
              sliceRadiusConfig: showcaseRadius,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a pie sliceRadiusConfig FORMATTER stays an honest refusal '
        '(placeholder + omitted warning), the chart still emits', (
      tester,
    ) async {
      // A formatter is a live callback, not a literal. The source-only document
      // path (`extractSourceDocument`) represents it as a placeholder, and — via
      // the SAME seam the config form uses — the grammar emitter writes a
      // placeholder comment with a runtime-value-omitted warning. The chain
      // still EMITS (the config objects round-trip by identity), it is just not
      // byte-complete: the formatter is the one field that cannot be a literal.
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 400,
                child: BravenChartPlus(
                  bravenChartController: controller,
                  series: <ChartSeries>[
                    PieChartSeries.fromMap(
                      id: 'pie-fmt',
                      name: 'Revenue',
                      values: const <String, num>{
                        'Apple': 42,
                        'Pear': 31,
                        'Plum': 17,
                        'Fig': 10,
                      },
                      radiusValues: _harvestRadii,
                      sliceRadiusConfig: PieSliceRadiusConfig(
                        minimumFactor: 0.4,
                        label: 'Area',
                        formatter: (value) => '${value}u',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The source-only path describes the runtime formatter with a placeholder,
      // where the portable `extractDocument` path fails closed without a
      // descriptor — proving the formatter never travels as a literal.
      final result = controller.extractSourceDocument();
      expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
      final snapshot =
          (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;

      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isTrue);
      expect(
        generated.source,
        contains('sliceRadiusConfig: PieSliceRadiusConfig('),
      );
      expect(generated.source, contains('// formatter:'));
      expect(generated.isComplete, isFalse);
      expect(
        generated.warnings.map((w) => w.message).join('\n'),
        contains('formatter'),
      );
      // The honest refusal is at the FIELD level, not a whole-chart block.
      expect(blockedReason(generated), isNull);
    });

    testWidgets('a donut with unit + selectionStyle + sliceGroupingConfig + '
        'donutStyle + center emits and round-trips', (tester) async {
      final generated = await expectRoundTrip(
        tester,
        name: 'donut_series_config',
        fragments: <String>[
          '.geomDonut(',
          "unit: 'USD'",
          'selectionStyle: RadialSelectionStyle(',
          'sliceGroupingConfig: RadialSliceGroupingConfig(',
          'style: DonutChartStyle(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-showcase',
              name: 'Revenue',
              unit: 'USD',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              donutStyle: styledDonutStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
              centerContent: const DonutCenterContent(label: 'Total'),
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomDonut(
              id: 'donut-showcase',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Revenue',
              unit: 'USD',
              style: styledDonutStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
              center: const DonutCenterContent(label: 'Total'),
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a concentric composition with unit + selectionStyle + '
        'sliceGroupingConfig + donutStyle emits and round-trips', (
      tester,
    ) async {
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_series_config',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          "unit: 'USD'",
          'selectionStyle: RadialSelectionStyle(',
          'sliceGroupingConfig: RadialSliceGroupingConfig(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'seasons-Winter',
              name: 'Winter',
              unit: 'USD',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              donutStyle: styledDonutStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
            ),
            DonutChartSeries.fromMap(
              id: 'seasons-Summer',
              name: 'Summer',
              unit: 'USD',
              values: const <String, num>{'Plum': 17, 'Fig': 10},
              donutStyle: styledDonutStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              unit: 'USD',
              style: styledDonutStyle,
              selectionStyle: showcaseSelection,
              sliceGroupingConfig: showcaseGrouping,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a polar column with unit + selectionStyle + polarStyle emits '
        'and round-trips', (tester) async {
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_series_config',
        fragments: <String>[
          '.geomPolar(',
          "unit: 'orders'",
          'selectionStyle: RadialSelectionStyle(',
          'style: PolarColumnStyle(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'polar-showcase',
              name: 'Orders',
              unit: 'orders',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              polarStyle: styledPolarStyle,
              selectionStyle: showcaseSelection,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPolar(
              id: 'polar-showcase',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Orders',
              unit: 'orders',
              style: styledPolarStyle,
              selectionStyle: showcaseSelection,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });
  });

  group('fidelity matrix diagnostics', () {
    testWidgets('a family with no grammar mark (radial-bar) is named, and no '
        'chain is emitted', (tester) async {
      // Radial-bar and gauge have neither a RadialMark subtype nor a geom* verb,
      // so they stay refused — but with an ACCURATE reason naming the missing
      // geometry, NOT the stale "Cartesian-only in V1" copy (pie/donut/polar now
      // emit).
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            RadialBarChartSeries.fromMap(
              id: 'rings',
              values: const <String, num>{'A': 3, 'B': 5},
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(generated.isComplete, isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('radial-bar, gauge or range-area'),
          contains('RadialBarChartSeries'),
          contains('rings'),
        ),
      );
      expect(blockedReason(generated), isNot(contains('Cartesian-only in V1')));
      expect(generated.source, isNot(contains('Cartesian-only in V1')));
    });

    testWidgets('a customised ConcentricDonutConfig is refused with a named '
        'reason, not the stale copy', (tester) async {
      // The grammar carries only a concentric donut's shared center, so a
      // custom ringGap cannot round-trip. The proof must refuse it with an
      // accurate reason, NOT emit a chain that silently drops the config.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(ringGap: 12),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'seasons-Winter',
              name: 'Winter',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
            ),
            DonutChartSeries.fromMap(
              id: 'seasons-Summer',
              name: 'Summer',
              values: const <String, num>{'Plum': 17, 'Fig': 10},
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('concentric-donut composition'),
          contains('ConcentricDonutConfig'),
        ),
      );
      expect(blockedReason(generated), isNot(contains('Cartesian-only')));
    });

    testWidgets('a customised PolarChartConfig is refused with a named reason', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: const PolarChartConfig(
            pane: PolarPaneConfig(startAngleDegrees: 45),
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'polar',
              values: const <String, num>{'A': 3, 'B': 5, 'C': 8},
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('polar chart configuration'),
          contains('PolarChartConfig'),
        ),
      );
      expect(blockedReason(generated), isNot(contains('Cartesian-only')));
    });

    testWidgets('misaligned x domains name the offending series', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
            LineChartSeries(
              id: 'cadence',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 3, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('one row list cannot express'),
          contains('cadence'),
          contains('power'),
        ),
      );
    });

    testWidgets('an annotation the chain cannot express is listed', (
      tester,
    ) async {
      // PinAnnotation is an arbitrary-coordinate marker with no chain verb (its
      // series-bound cousin, PointAnnotation, is what .pointAt() expresses), so
      // it stays gated after Grammar V2.0 mapped trend/threshold/band/point.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
          annotations: <ChartAnnotation>[
            PinAnnotation(id: 'here', x: 0.5, y: 1.5),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('trend, threshold, band and point'),
          contains('PinAnnotation'),
          contains('here'),
        ),
      );
    });

    testWidgets('a partially populated scatter channel is rejected', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            ScatterChartSeries(
              id: 'efforts',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1, magnitude: 4),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(contains('efforts'), contains('magnitude'), contains('total')),
      );
    });

    testWidgets('a partial candlestick timestamp is diagnosed, not crashed', (
      tester,
    ) async {
      // A candlestick series that carries a timestamp on SOME candles but not
      // all cannot be expressed: a Channel/accessor is total, so it either
      // reads a timestamp for every row or none. Before the gate this crashed
      // the generator with an opaque null-check TypeError during the round-trip
      // proof; it must instead block with a NAMED diagnostic, exactly like a
      // partial scatter channel.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            CandlestickChartSeries(
              id: 'price',
              points: <CandlestickDataPoint>[
                CandlestickDataPoint(
                  x: 0,
                  open: 10,
                  high: 14,
                  low: 9,
                  close: 12,
                  timestamp: DateTime.utc(2026, 1, 1),
                ),
                CandlestickDataPoint(
                  x: 1,
                  open: 12,
                  high: 16,
                  low: 11,
                  close: 15,
                ),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(contains('price'), contains('timestamp'), contains('1 of 2')),
      );
    });

    testWidgets('mixed bar orientations are rejected', (tester) async {
      final vertical = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            BarChartSeries(
              id: 'planned',
              barWidthPercent: 0.8,
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
            BarChartSeries(
              id: 'actual',
              barWidthPercent: 0.8,
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 3),
                ChartDataPoint(x: 1, y: 4),
              ],
            ),
          ],
        ),
      );
      final snapshot = patchedSnapshot(vertical, (json) {
        final series = json['series']! as List<Object?>;
        final style =
            (series[1]! as Map<String, Object?>)['style']!
                as Map<String, Object?>;
        style['barOrientation'] = 'horizontal';
      });
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(contains('whole-chart operation'), contains('actual')),
      );
    });

    testWidgets('a series option no V1 mark carries is refused, not dropped', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              unit: 'W',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      // The diagnostic NAMES the specific option that no V1 mark carries,
      // instead of only saying the chart "does not reproduce" exactly.
      expect(
        blockedReason(generated),
        allOf(
          contains('does not reproduce'),
          contains('power'),
          contains('unit'),
        ),
      );
    });

    testWidgets(
      'the Layered case (area+line data-point markers) now emits, not blocks',
      (tester) async {
        // The exact "Layered" case the owner saw: an area+line chart with
        // data-point markers on the area. AreaMark/LineMark now CARRY
        // showDataPointMarkers, so the round trip reproduces it and the chain
        // is emitted with the flag set, instead of being blocked by a "does
        // not reproduce ... showDataPointMarkers" diagnostic.
        final snapshot = await snapshotOf(
          tester,
          (controller) => BravenChart.of(rows)
              .x(sampleT, label: 'Elapsed')
              .y(samplePower, label: 'Power')
              .geomArea(name: 'Sessions', showDataPointMarkers: true)
              .geomLine(y: sampleHeartRate, name: 'Heart rate')
              .build(bravenChartController: controller),
        );
        final generated = generateGrammar(snapshot);
        expect(emittedChain(generated), isTrue);
        expect(blockedReason(generated), isNull);
        expect(generated.isComplete, isTrue);
        expect(generated.warnings, isEmpty);
        expect(generated.source, contains('showDataPointMarkers: true'));
      },
    );

    testWidgets('a single-axis config chart explains the axis binding', (
      tester,
    ) async {
      // A chart authored through the single-axis path (`BravenChartPlus` with
      // no per-series yAxisId) cannot be reproduced by the grammar, which
      // always binds each series to an explicit axis. The diagnostic explains
      // that rather than leaving the reader guessing.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('does not reproduce'),
          contains('power'),
          contains('single-axis'),
          contains('yAxisId'),
        ),
      );
    });

    testWidgets('grid and legend never trip the chart-option gate', (
      tester,
    ) async {
      // Grid and legend are now carried by PlotSpec, so they must NOT appear in
      // any chart-option block reason. These single-axis charts still block —
      // on the single-axis path — but never for `grid` or `legend`.
      final nonDefaultGrid = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          grid: const GridConfig(horizontal: false),
          showLegend: false,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final gridResult = generateGrammar(nonDefaultGrid);
      expect(
        blockedReason(gridResult),
        allOf(isNot(contains('grid')), isNot(contains('legend'))),
      );
    });

    testWidgets('a subtitle with no title stays gated', (tester) async {
      // The chain's .title(String, {String? subtitle}) verb can only carry a
      // subtitle alongside a title, so a subtitle with no title is the one
      // carried-but-inexpressible corner and must be named, not dropped.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          subtitle: 'Orphan subtitle',
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(contains('would be lost'), contains('subtitle with no title')),
      );
    });

    testWidgets('a genuinely-uncarried chart option still blocks and is named', (
      tester,
    ) async {
      // The gate still fires for options no V1 chain verb expresses — here, the
      // toolbar — even though grid, title, subtitle and legend now pass.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          showToolbar: true,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(contains('would be lost'), contains('showToolbar')),
      );
    });

    testWidgets('a runtime interaction binding is reported like Config does', (
      tester,
    ) async {
      final plain = await snapshotOf(
        tester,
        (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomLine(name: 'Power')
            .build(bravenChartController: controller),
      );
      final snapshot = patchedSnapshot(plain, (json) {
        final interaction = json['interaction']! as Map<String, Object?>;
        interaction['requiredBindings'] = <String>['onDataPointTap'];
      });
      final generated = generateGrammar(snapshot);
      // A runtime binding does not block the chain — it annotates it, exactly
      // as the config emitter does.
      expect(emittedChain(generated), isTrue);
      expect(generated.isComplete, isFalse);
      expect(
        generated.warnings.map((warning) => warning.message).join(' | '),
        contains('Runtime interaction bindings omitted'),
      );
      expect(generated.source, contains('// Runtime interaction bindings'));
    });
  });

  group('options', () {
    testWidgets('the row class and variable names are configurable', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChart.of(rows)
            .x(sampleT)
            .y(samplePower)
            .geomLine(name: 'Power')
            .build(bravenChartController: controller),
      );
      final generated = generateGrammar(
        snapshot,
        options: const ChartGrammarSourceOptions(
          variableName: 'ride',
          rowClassName: 'RideRow',
          rowsVariableName: 'rideRows',
        ),
      );
      expect(generated.source, contains('class RideRow {'));
      expect(generated.source, contains('final List<RideRow> rideRows'));
      expect(
        generated.source,
        contains('final ride = BravenChart.of(rideRows)'),
      );
    });

    testWidgets('an invalid identifier fails the generation outright', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChart.of(rows)
            .x(sampleT)
            .y(samplePower)
            .geomLine(name: 'Power')
            .build(bravenChartController: controller),
      );
      final result = ChartGrammarSourceGenerator.generate(
        snapshot,
        options: const ChartGrammarSourceOptions(rowClassName: 'class'),
      );
      expect(result, isA<ChartArtifactFailure<ChartGeneratedSource>>());
    });
  });
}
