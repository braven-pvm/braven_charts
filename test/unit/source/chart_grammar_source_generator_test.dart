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

import 'dart:math' as math;

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

// ---------------------------------------------------------------------------
// MULTI-SERIES POLAR fixtures. A layered/grouped/stacked polar composition is
// N `PolarColumnChartSeries` over ONE category domain plus a plot-level
// `PolarChartConfig`; the chain reverses it to N `geomPolar` marks reading one
// shared category field and one value field each (`value`, `value2`, …) plus
// `.polarConfig(...)`.
// ---------------------------------------------------------------------------

/// The SYNTHESISED multi-series polar row: the shared string `category` field
/// and one number field per polar series, named the way the generator's
/// de-duplication names them.
class PolarGrammarRow {
  const PolarGrammarRow({
    required this.category,
    required this.value,
    this.value2 = 0,
  });

  final String category;
  final double value;
  final double value2;
}

const polarCapacity = <String, num>{
  'Apple': 60,
  'Pear': 50,
  'Plum': 40,
  'Fig': 30,
};

const polarObserved = <String, num>{
  'Apple': 42,
  'Pear': 31,
  'Plum': 17,
  'Fig': 10,
};

final List<PolarGrammarRow> polarGrammarRows = <PolarGrammarRow>[
  for (final row in harvest)
    PolarGrammarRow(
      category: row.fruit,
      value: polarCapacity[row.fruit]!.toDouble(),
      value2: polarObserved[row.fruit]!.toDouble(),
    ),
];

/// A NON-DEFAULT plot-level polar configuration. Every value differs from the
/// class default, so a chain that dropped the config could not pass the
/// round-trip proof by accident.
const groupedPolarConfig = PolarChartConfig(
  pane: PolarPaneConfig(startAngleDegrees: -45, innerRadiusFactor: 0.15),
  composition: PolarColumnCompositionConfig(
    mode: PolarColumnCompositionMode.grouped,
    groupInnerPadding: 0.2,
  ),
);

/// A non-default plot-level polar configuration that leaves the COMPOSITION
/// alone, so a single-series polar chart can carry it (grouped and stacked
/// compositions require at least two series).
const customPolarPaneConfig = PolarChartConfig(
  pane: PolarPaneConfig(startAngleDegrees: -45, innerRadiusFactor: 0.15),
  radialAxis: PolarNumericAxisConfig(tickCount: 7),
);

/// An EXHAUSTIVE plot-level polar configuration: every field of every nested
/// config differs from its class default, and every value is distinct, so the
/// per-field assertions over the emitted `.polarConfig(...)` literal cannot pass
/// by coincidence.
///
/// The round-trip proof compares the config object the proof spec CARRIES, which
/// is the captured instance itself — so it can only prove that lowering keeps
/// hold of it, never that the emitted TEXT reproduces it. This fixture is what
/// covers the text.
const exhaustivePolarConfig = PolarChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: -45,
    sweepAngleDegrees: 300,
    clockwise: false,
    innerRadiusFactor: 0.15,
    outerRadiusFactor: 0.8,
    clipMarks: false,
  ),
  angularAxis: PolarCategoryAxisConfig(
    innerPadding: 0.2,
    outerPadding: 0.08,
    showLabels: false,
    showGridLines: false,
    maximumVisibleLabels: 12,
    maximumVisibleGridLines: 36,
    labelOffset: 6,
    labelStyle: PolarLabelStyle(
      color: Color(0xFF102030),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  ),
  radialAxis: PolarNumericAxisConfig(
    minimum: 5,
    maximum: 80,
    scaleMode: PolarRadialScaleMode.areaCorrect,
    tickCount: 7,
    showLabels: false,
    showGridLines: false,
    labelPosition: PolarRadialLabelPosition.end,
    labelAngleOffsetDegrees: 12,
    labelOffset: 9,
    labelStyle: PolarLabelStyle(
      color: Color(0xFF405060),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  ),
  composition: PolarColumnCompositionConfig(
    mode: PolarColumnCompositionMode.grouped,
    groupInnerPadding: 0.2,
  ),
  thresholds: <PolarThreshold>[
    PolarThreshold(
      value: 55,
      label: 'Target',
      color: Color(0xFF708090),
      width: 2.5,
      dashPattern: <double>[3, 2],
    ),
  ],
);

/// Every value [exhaustivePolarConfig] sets, as the fragment the emitted
/// `.polarConfig(...)` literal must contain for it.
const exhaustivePolarConfigFragments = <String>[
  'pane: PolarPaneConfig(',
  'startAngleDegrees: -45.0,',
  'sweepAngleDegrees: 300.0,',
  'clockwise: false,',
  'innerRadiusFactor: 0.15,',
  'outerRadiusFactor: 0.8,',
  'clipMarks: false,',
  'angularAxis: PolarCategoryAxisConfig(',
  'innerPadding: 0.2,',
  'outerPadding: 0.08,',
  'showLabels: false,',
  'showGridLines: false,',
  'maximumVisibleLabels: 12,',
  'maximumVisibleGridLines: 36,',
  'labelOffset: 6.0,',
  'labelStyle: PolarLabelStyle(',
  'color: Color(0xFF102030),',
  'fontSize: 11.0,',
  'fontWeight: FontWeight.w600,',
  'radialAxis: PolarNumericAxisConfig(',
  'minimum: 5.0,',
  'maximum: 80.0,',
  'scaleMode: PolarRadialScaleMode.areaCorrect,',
  'tickCount: 7,',
  'labelPosition: PolarRadialLabelPosition.end,',
  'labelAngleOffsetDegrees: 12.0,',
  'labelOffset: 9.0,',
  'color: Color(0xFF405060),',
  'fontSize: 13.0,',
  'fontWeight: FontWeight.w700,',
  'composition: PolarColumnCompositionConfig(',
  'mode: PolarColumnCompositionMode.grouped,',
  'groupInnerPadding: 0.2,',
  'thresholds: [',
  'PolarThreshold(',
  'value: 55.0,',
  "label: 'Target',",
  'color: Color(0xFF708090),',
  'width: 2.5,',
  'dashPattern: <double>[3.0, 2.0],',
];

// ---------------------------------------------------------------------------
// ADVANCED PER-SERIES POLAR fixtures. The `standard`, `rose`, `references` and
// `intervals` showcase presentations carry per-CATEGORY data beyond the value:
// a column color, an absolute target, and an interval's two bounds. Each of
// those becomes its own synthesised row field, so the reversed chain reads
// them exactly the way it reads the value.
//
// Every one of the three is NULLABLE per category on purpose. A category
// without a target must stay null: a synthesised 0 is a real value on the
// radial scale and would draw a marker at the origin instead of drawing none.
// ---------------------------------------------------------------------------

/// The SYNTHESISED advanced-polar row: the shared category, this series' value,
/// and the nullable per-category channels the generator adds only for a series
/// that carries them.
class PolarAdvancedRow {
  const PolarAdvancedRow({
    required this.category,
    required this.value,
    this.columnColor,
    this.target,
    this.intervalLow,
    this.intervalHigh,
  });

  final String category;
  final double value;
  final Color? columnColor;
  final double? target;
  final double? intervalLow;
  final double? intervalHigh;
}

/// Per-category column colors for TWO of the four categories, so the reversal
/// must keep the other two on the series color rather than inventing one.
const polarColumnColors = <String, Color>{
  'Apple': Color(0xFF16A34A),
  'Plum': Color(0xFF7C3AED),
};

/// Targets for three of the four categories; 'Fig' stays null.
const polarTargets = <String, num?>{
  'Apple': 50,
  'Pear': 36,
  'Plum': 20,
  'Fig': null,
};

/// Intervals for three of the four categories; 'Fig' has none.
const polarIntervals = <String, PolarColumnInterval>{
  'Apple': PolarColumnInterval(lower: 38, upper: 46),
  'Pear': PolarColumnInterval(lower: 27, upper: 34),
  'Plum': PolarColumnInterval(lower: 14, upper: 20),
};

/// Every field differs from the class default, so a dropped style cannot pass.
const styledTargetMarker = PolarColumnTargetMarkerStyle(
  color: Color(0xFF0F172A),
  width: 3,
  lengthFactor: 0.8,
  opacity: 0.9,
);

/// Every field differs from the class default.
const styledIntervalStyle = PolarColumnIntervalStyle(
  display: PolarColumnIntervalDisplay.band,
  color: Color(0xFF334155),
  width: 2,
  capLengthFactor: 0.5,
  bandLengthFactor: 0.7,
  opacity: 0.8,
);

/// The `references` presentation's rows: value + column color + target.
final List<PolarAdvancedRow> polarReferenceRows = <PolarAdvancedRow>[
  for (final row in harvest)
    PolarAdvancedRow(
      category: row.fruit,
      value: polarObserved[row.fruit]!.toDouble(),
      columnColor: polarColumnColors[row.fruit],
      target: polarTargets[row.fruit]?.toDouble(),
    ),
];

/// The `intervals` presentation's rows: value + both interval bounds.
final List<PolarAdvancedRow> polarIntervalRows = <PolarAdvancedRow>[
  for (final row in harvest)
    PolarAdvancedRow(
      category: row.fruit,
      value: polarObserved[row.fruit]!.toDouble(),
      intervalLow: polarIntervals[row.fruit]?.lower,
      intervalHigh: polarIntervals[row.fruit]?.upper,
    ),
];

/// The `rose` presentation's rows: value + column color.
final List<PolarAdvancedRow> polarRoseRows = <PolarAdvancedRow>[
  for (final row in harvest)
    PolarAdvancedRow(
      category: row.fruit,
      value: polarObserved[row.fruit]!.toDouble(),
      columnColor: polarColumnColors[row.fruit],
    ),
];

// ---------------------------------------------------------------------------
// MULTI-SERIES ADVANCED POLAR fixtures. The advanced per-category channels are
// allocated INTERLEAVED with each series' value field, so a second series that
// carries the same channel gets its OWN `columnColor2` / `target2` slot right
// after its own `value2`. With one series every index is 0 and nothing
// interleaves; these fixtures are what make the allocation observable.
//
// Every map below picks a DIFFERENT subset of the four categories from its
// series-1 counterpart, so a reversal that read the wrong series' list, or
// compacted the nulls, lands a value on the wrong category and fails.
// ---------------------------------------------------------------------------

/// The SYNTHESISED two-series advanced-polar row, field for field in the order
/// the generator allocates them.
class PolarPairRow {
  const PolarPairRow({
    required this.category,
    required this.value,
    required this.value2,
    this.columnColor,
    this.target,
    this.columnColor2,
    this.target2,
    this.intervalLow,
    this.intervalHigh,
  });

  final String category;
  final double value;
  final Color? columnColor;
  final double? target;
  final double value2;
  final Color? columnColor2;
  final double? target2;
  final double? intervalLow;
  final double? intervalHigh;
}

/// Series 2's column colors: 'Pear' and 'Fig', DISJOINT from series 1's
/// 'Apple'/'Plum'.
const polarForecastColumnColors = <String, Color>{
  'Pear': Color(0xFFB91C1C),
  'Fig': Color(0xFF0EA5E9),
};

/// Series 2's targets, absent for 'Apple' — series 1's are absent for 'Fig', so
/// the two null positions cannot be confused.
const polarForecastTargets = <String, num?>{
  'Apple': null,
  'Pear': 55,
  'Plum': 45,
  'Fig': 35,
};

/// Series 2's intervals, absent for 'Plum'.
const polarForecastIntervals = <String, PolarColumnInterval>{
  'Apple': PolarColumnInterval(lower: 54, upper: 66),
  'Pear': PolarColumnInterval(lower: 44, upper: 56),
  'Fig': PolarColumnInterval(lower: 26, upper: 34),
};

/// The two-series advanced rows: series 1's value + column color + target, then
/// series 2's value + column color + target + both interval bounds.
final List<PolarPairRow> polarPairRows = <PolarPairRow>[
  for (final row in harvest)
    PolarPairRow(
      category: row.fruit,
      value: polarObserved[row.fruit]!.toDouble(),
      columnColor: polarColumnColors[row.fruit],
      target: polarTargets[row.fruit]?.toDouble(),
      value2: polarCapacity[row.fruit]!.toDouble(),
      columnColor2: polarForecastColumnColors[row.fruit],
      target2: polarForecastTargets[row.fruit]?.toDouble(),
      intervalLow: polarForecastIntervals[row.fruit]?.lower,
      intervalHigh: polarForecastIntervals[row.fruit]?.upper,
    ),
];

// ---------------------------------------------------------------------------
// SHOWCASE POLAR fixtures — the ACCEPTANCE GATE for this slice.
//
// These are copied from `example/lib/showcase/pages/polar_column_page.dart`
// (`_buildSeriesList` and `_buildPolarConfig`): the data maps, the per-
// presentation pane/axis/composition knobs and the per-presentation styling
// each of the seven authored presentations applies. The showcase is what the
// workbench Grammar pane actually renders, so a chart built from these values
// emitting a chain IS the claim "every polar Grammar pane emits".
// ---------------------------------------------------------------------------

const showcaseStandardValues = <String, num>{
  'Search': 86,
  'Social': 58,
  'Partners': 72,
  'Email': 44,
  'Events': 65,
  'Direct': 92,
  'Referral': 54,
  'Other': 36,
};

const showcaseRoseValues = <String, num>{
  'Jan': 42,
  'Feb': 58,
  'Mar': 76,
  'Apr': 63,
  'May': 88,
  'Jun': 54,
  'Jul': 97,
  'Aug': 82,
  'Sep': 69,
  'Oct': 74,
  'Nov': 49,
  'Dec': 61,
};

const showcaseLayeredObservedValues = <String, num>{
  'Search': 72,
  'Social': 48,
  'Partners': 68,
  'Email': 39,
  'Events': 61,
  'Direct': 83,
};

const showcaseLayeredCapacityValues = <String, num>{
  'Search': 92,
  'Social': 70,
  'Partners': 84,
  'Email': 62,
  'Events': 78,
  'Direct': 96,
};

const showcaseGroupedNorthValues = <String, num>{
  'Search': 78,
  'Social': 46,
  'Partners': 64,
  'Email': 52,
  'Events': 70,
  'Direct': 58,
};

const showcaseGroupedSouthValues = <String, num>{
  'Search': 62,
  'Social': 69,
  'Partners': 51,
  'Email': 73,
  'Events': 55,
  'Direct': 82,
};

const showcaseGroupedWestValues = <String, num>{
  'Search': 54,
  'Social': 57,
  'Partners': 76,
  'Email': 61,
  'Events': 84,
  'Direct': 67,
};

const showcaseStackedNewValues = <String, num>{
  'Search': 34,
  'Social': 26,
  'Partners': 31,
  'Email': 19,
  'Events': 28,
  'Direct': 37,
};

const showcaseStackedExpansionValues = <String, num>{
  'Search': 16,
  'Social': 12,
  'Partners': 18,
  'Email': 11,
  'Events': 15,
  'Direct': 20,
};

/// The stacked composition's third series is NEGATIVE at every category, which
/// is what makes it worth its own acceptance case: a reversal that synthesised
/// a zero, or clamped, would move every column.
const showcaseStackedChurnValues = <String, num>{
  'Search': -13,
  'Social': -21,
  'Partners': -12,
  'Email': -17,
  'Events': -10,
  'Direct': -15,
};

const showcaseReferenceActualValues = <String, num>{
  'Search': 74,
  'Social': 56,
  'Partners': 83,
  'Email': 48,
  'Events': 69,
  'Direct': 91,
};

const showcaseReferenceTargetValues = <String, num>{
  'Search': 78,
  'Social': 62,
  'Partners': 80,
  'Email': 55,
  'Events': 72,
  'Direct': 88,
};

const showcaseUncertaintyValues = <String, num>{
  'Search': 72,
  'Social': 58,
  'Partners': 81,
  'Email': 46,
  'Events': 67,
  'Direct': 88,
};

const showcaseUncertaintyLowerValues = <String, num>{
  'Search': 63,
  'Social': 49,
  'Partners': 70,
  'Email': 38,
  'Events': 57,
  'Direct': 76,
};

const showcaseUncertaintyUpperValues = <String, num>{
  'Search': 84,
  'Social': 69,
  'Partners': 94,
  'Email': 56,
  'Events': 79,
  'Direct': 103,
};

/// The showcase's `_PolarPalette.ocean` swatch.
const showcaseOceanPalette = <Color>[
  Color(0xFF2563EB),
  Color(0xFF0D9488),
  Color(0xFF06B6D4),
  Color(0xFF7C3AED),
  Color(0xFF64748B),
];

/// The showcase's `_PolarPalette.sunset` swatch.
const showcaseSunsetPalette = <Color>[
  Color(0xFFE63946),
  Color(0xFFF77F00),
  Color(0xFFFCBF49),
  Color(0xFF9D4EDD),
  Color(0xFF5A189A),
];

/// `_categoryColors` for `_PolarPalette.theme`: the base theme's own series
/// colors, at least eight of them.
List<Color> showcaseThemePalette(ChartTheme theme, int categoryCount) =>
    List<Color>.generate(
      math.max(8, categoryCount),
      theme.seriesTheme.colorAt,
    );

/// The showcase's per-category color map: the palette cycled over the value
/// map's key order (`_buildSeriesList`).
Map<String, Color> showcaseColumnColors(
  Map<String, num> values,
  List<Color> palette,
) => <String, Color>{
  for (final (index, category) in values.keys.indexed)
    category: palette[index % palette.length],
};

/// `_buildSeriesList`'s shared `PolarColumnStyle`, with the knobs each
/// presentation varies as parameters and the rest at the showcase's authored
/// values.
PolarColumnStyle showcasePolarStyle({
  required double cornerRadius,
  required double opacity,
  required Color borderColor,
  required PolarColumnAnimationMode animationMode,
  PolarColumnCornerRadiusMode cornerRadiusMode =
      PolarColumnCornerRadiusMode.outerEnd,
  Color? valueLabelColor,
  PolarColumnGradientStyle? gradient,
  PolarColumnShadowStyle shadow = const PolarColumnShadowStyle(),
}) => PolarColumnStyle(
  cornerRadius: cornerRadius,
  cornerRadiusMode: cornerRadiusMode,
  opacity: opacity,
  borderColor: borderColor,
  borderWidth: 0.75,
  maximumVisibleDataLabels: 24,
  dataLabelRadialPosition: 0.56,
  dataLabelStyle: PolarLabelStyle(
    color: valueLabelColor,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  ),
  gradient: gradient,
  shadow: shadow,
  animationMode: animationMode,
);

/// `_buildSeriesList`'s shared `RadialSelectionStyle` at the showcase defaults.
const showcasePolarSelection = RadialSelectionStyle(
  liftScale: 1.08,
  liftOffset: 6,
  backdropBlur: 1.25,
);

/// `_buildPolarConfig`, with the knobs each presentation varies as parameters.
PolarChartConfig showcasePolarConfig({
  required double innerRadiusFactor,
  required double outerRadiusFactor,
  required double innerPadding,
  required double outerPadding,
  required Color categoryLabelColor,
  required Color radialLabelColor,
  required PolarColumnCompositionMode compositionMode,
  PolarRadialScaleMode scaleMode = PolarRadialScaleMode.linear,
  List<PolarThreshold> thresholds = const <PolarThreshold>[],
}) => PolarChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: -90,
    innerRadiusFactor: innerRadiusFactor,
    outerRadiusFactor: outerRadiusFactor,
  ),
  angularAxis: PolarCategoryAxisConfig(
    innerPadding: innerPadding,
    outerPadding: outerPadding,
    maximumVisibleLabels: 24,
    maximumVisibleGridLines: 72,
    labelOffset: 4,
    labelStyle: PolarLabelStyle(
      color: categoryLabelColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  radialAxis: PolarNumericAxisConfig(
    scaleMode: scaleMode,
    labelOffset: 4,
    labelStyle: PolarLabelStyle(
      color: radialLabelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
  ),
  composition: PolarColumnCompositionConfig(mode: compositionMode),
  thresholds: thresholds,
);

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

/// Asserts one showcase chart reaches the Grammar pane as a real chain.
///
/// The acceptance question for this slice is not "does some polar chart emit"
/// but "does the chart the showcase page actually mounts emit", so this mounts
/// the chart and asserts on the generator's own verdict: a chain was written,
/// nothing was blocked, and [ChartGeneratedSource.isComplete] is true. The
/// generator proves FIDELITY internally — it re-lowers the chain it is about to
/// write and refuses anything that would render a different chart — so an
/// emitted chain already means a faithful one.
Future<ChartGeneratedSource> expectShowcaseEmits(
  WidgetTester tester, {
  required String presentation,
  required Widget Function(BravenChartController) chart,
  Iterable<String> fragments = const <String>[],
}) async {
  final snapshot = await snapshotOf(tester, chart);
  final generated = generateGrammar(snapshot);
  expect(
    emittedChain(generated),
    isTrue,
    reason:
        'the "$presentation" showcase presentation must emit a grammar chain, '
        'but it was blocked with: ${blockedReason(generated)}',
  );
  expect(
    generated.warnings,
    isEmpty,
    reason:
        'the "$presentation" showcase presentation must emit a CLEAN chain:\n'
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
  return generated;
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

/// Every argument line INSIDE the literal that opens with [opening] in [source],
/// trimmed and in emitted order.
///
/// A `contains('width: 3.0,')` per field can only notice the fields the list
/// happens to name — a field DROPPED from the renderer is invisible to a
/// fragment list that never mentioned it, which is exactly how an emitted-text
/// seam rots. Returning the literal's complete argument list makes the
/// expectation the whole block, so a dropped field, an extra field, a wrong
/// value and a reordering all fail.
///
/// The literal is delimited by indentation: its closing `),` sits at the same
/// column as the opening token, so a nested literal's deeper `),` cannot end it.
List<String> literalArguments(String source, String opening) {
  final start = source.indexOf(opening);
  expect(start, isNonNegative, reason: 'missing "$opening" in:\n$source');
  final indent = start - (source.lastIndexOf('\n', start) + 1);
  final bodyStart = source.indexOf('\n', start) + 1;
  final end = source.indexOf('\n${' ' * indent}),', start);
  expect(end, isNonNegative, reason: 'unterminated "$opening" in:\n$source');
  return <String>[
    for (final line in source.substring(bodyStart, end).split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
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
      final generated = await expectRoundTrip(
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
      // The BYTE-IDENTICAL half of the concentric passthrough: a DEFAULT
      // composition must still write neither argument, exactly as it did before
      // `concentric:` existed. `expectRoundTrip` cannot see this — it only
      // proves the emitted text analyzes and that a HAND-WRITTEN equivalent
      // rebuilds the same document — so a spurious `concentric:` would sail
      // through every other assertion in this file.
      expect(generated.source, isNot(contains('concentric:')));
      expect(generated.source, isNot(contains('center: DonutCenterContent(')));
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

    testWidgets('shape 15b: a single-distinct-ring donut drops a NON-DEFAULT '
        'concentric config with it', (tester) async {
      // Whether `concentric:` survives depends on the DATA: two ring values
      // stamp a concentricDonutConfig into the captured document (shape 28
      // emits it), one ring value does not, because the render source only
      // stamps it for MORE THAN ONE donut series. The emitted chain is still
      // document-faithful — it rebuilds the captured chart exactly, which the
      // round trip below proves — but it is NOT the chain the author wrote, so
      // the drop is pinned here rather than left accidental.
      const oneSeason = <Harvest>[
        Harvest(fruit: 'Apple', count: 42, season: 'All year'),
        Harvest(fruit: 'Pear', count: 31, season: 'All year'),
      ];
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_single_ring_custom',
        fragments: <String>['.geomDonut('],
        original: (controller) => BravenChart.of(oneSeason)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
              concentric: const ConcentricDonutConfig(ringGap: 12),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) =>
            BravenChart.of(radialGrammarRows.take(2).toList())
                .geomDonut(
                  id: 'seasons-All year',
                  category: (row) => row.category,
                  value: (row) => row.value,
                  name: 'All year',
                  center: const DonutCenterContent(),
                )
                .build(bravenChartController: controller),
      );
      expect(generated.source, isNot(contains('ring:')));
      expect(generated.source, isNot(contains('concentric:')));
      // What DOES survive: the collapsed ring carries the config's center on
      // itself, so the center summary is reproduced.
      expect(generated.source, contains('center: DonutCenterContent('));
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
      final generated = await expectRoundTrip(
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
      // Per-RING styling is not a COMPOSITION: the config stays default, so it
      // must not be written (see shape 14).
      expect(generated.source, isNot(contains('concentric:')));
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

    testWidgets('shape 21: a MULTI-SERIES polar emits one geomPolar per '
        'series plus .polarConfig and round-trips', (tester) async {
      // The polar family is the one radial family that may carry several geoms
      // in a plot: a layered/grouped/stacked composition is N series over ONE
      // category domain. Each series becomes its own geomPolar reading its own
      // value field; the plot-level PolarChartConfig becomes .polarConfig(...).
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_multi_series',
        fragments: <String>[
          '.geomPolar(',
          'value: (row) => row.value,',
          'value: (row) => row.value2,',
          '.polarConfig(',
          'PolarChartConfig(',
          'composition: PolarColumnCompositionConfig(',
          'mode: PolarColumnCompositionMode.grouped',
          'groupInnerPadding: 0.2',
          'startAngleDegrees: -45',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: groupedPolarConfig,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'capacity',
              name: 'Capacity',
              values: polarCapacity,
              polarStyle: styledPolarStyle,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarGrammarRows)
            .geomPolar(
              id: 'capacity',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Capacity',
              style: styledPolarStyle,
            )
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value2,
              name: 'Observed',
            )
            .polarConfig(groupedPolarConfig)
            .build(bravenChartController: controller),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 2);
    });

    testWidgets('shape 22: a SINGLE polar with a customised PolarChartConfig '
        'emits .polarConfig and round-trips', (tester) async {
      // Before the spec carried the config this was an honest refusal: lowering
      // always produced `const PolarChartConfig()`, so the proof could not
      // reproduce a customised pane/composition. `.polarConfig(...)` closes it.
      await expectRoundTrip(
        tester,
        name: 'polar_single_config',
        fragments: <String>[
          '.geomPolar(',
          '.polarConfig(',
          'startAngleDegrees: -45',
          'tickCount: 7',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomPolar(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
            )
            .polarConfig(customPolarPaneConfig)
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(radialGrammarRows)
            .geomPolar(
              id: 'mark-0',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Harvest',
            )
            .polarConfig(customPolarPaneConfig)
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 23: EVERY PolarChartConfig field reaches the emitted '
        '.polarConfig literal', (tester) async {
      // The round-trip proof threads the CAPTURED PolarChartConfig onto the
      // proof spec and lowering hands the same instance back, so that comparison
      // can only prove lowering kept hold of the object — never that the emitted
      // TEXT reproduces it. `_emitPolarChartConfigArgument` is the only thing
      // between the config and the generated Dart, and
      // `test/meta/source_emitter_drift_test.dart` catches a NEW field by name;
      // this catches the other half — a field emitted against the wrong default,
      // or dropped outright.
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_exhaustive_config',
        fragments: <String>['.polarConfig(', ...exhaustivePolarConfigFragments],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: exhaustivePolarConfig,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'capacity',
              name: 'Capacity',
              values: polarCapacity,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarGrammarRows)
            .geomPolar(
              id: 'capacity',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Capacity',
            )
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value2,
              name: 'Observed',
            )
            .polarConfig(exhaustivePolarConfig)
            .build(bravenChartController: controller),
      );
      expect(generated.source, contains('.polarConfig(\n'));
      // Three fragments are shared by the angular and radial axes, so a plain
      // `contains` would still pass if ONE of the pair were dropped. Count them.
      for (final (fragment, count) in <(String, int)>[
        ('showLabels: false,', 2),
        ('showGridLines: false,', 2),
        ('labelStyle: PolarLabelStyle(', 2),
      ]) {
        expect(
          fragment.allMatches(generated.source).length,
          count,
          reason: 'expected $count × "$fragment" in:\n${generated.source}',
        );
      }
    });

    testWidgets('shape 24: a polar carrying per-category COLUMN COLORS and '
        'TARGETS emits both channels and round-trips', (tester) async {
      // The `references` presentation. Two of the four categories carry a
      // column color and three of the four carry a target, so the synthesised
      // fields must be NULLABLE: a category left at null keeps the series color
      // / draws no marker, while a synthesised 0 would be a real radius.
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_targets',
        fragments: <String>[
          '.geomPolar(',
          'final Color? columnColor;',
          'final double? target;',
          'columnColor: (row) => row.columnColor,',
          'target: (row) => row.target,',
          'targetMarkerStyle: PolarColumnTargetMarkerStyle(',
          'color: Color(0xFF0F172A),',
          'lengthFactor: 0.8,',
          'columnColor: Color(0xFF16A34A),',
          'columnColor: null,',
          'target: null,',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
              columnColors: polarColumnColors,
              targets: polarTargets,
              targetMarkerStyle: styledTargetMarker,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarReferenceRows)
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Observed',
              columnColor: (row) => row.columnColor,
              target: (row) => row.target,
              targetMarkerStyle: styledTargetMarker,
            )
            .build(bravenChartController: controller),
      );
      // Exactly one target is absent, and it is the LAST category — proof the
      // reversal reproduces `_fromMap`'s category-ordered target list rather
      // than a compacted one.
      expect('target: null,'.allMatches(generated.source).length, 1);
      expect('columnColor: null,'.allMatches(generated.source).length, 2);
      // The round-trip proof is OBJECT-level: it hands the captured
      // `PolarColumnTargetMarkerStyle` to the proof spec and lowering hands the
      // same instance back, so it cannot see the emitted text at all. The
      // drift gate only asks whether the emitter file knows each field's NAME,
      // and every name here appears in a dozen other renderers. So this literal
      // — asserted whole, not field by field — is the only thing standing
      // between a dropped `width:` and an emitted chain that silently draws
      // 2.5-wide default markers instead of the captured 3.0.
      expect(
        literalArguments(
          generated.source,
          'targetMarkerStyle: PolarColumnTargetMarkerStyle(',
        ),
        <String>[
          'color: Color(0xFF0F172A),',
          'width: 3.0,',
          'lengthFactor: 0.8,',
          'opacity: 0.9,',
        ],
      );
    });

    testWidgets('shape 25: a polar carrying per-category INTERVALS emits both '
        'bounds and round-trips', (tester) async {
      // The `intervals` presentation. Both bounds ride their own nullable
      // field; 'Fig' has neither, so the pair stays null for that row.
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_intervals',
        fragments: <String>[
          '.geomPolar(',
          'final double? intervalLow;',
          'final double? intervalHigh;',
          'intervalLow: (row) => row.intervalLow,',
          'intervalHigh: (row) => row.intervalHigh,',
          'intervalStyle: PolarColumnIntervalStyle(',
          'display: PolarColumnIntervalDisplay.band,',
          'capLengthFactor: 0.5,',
          'bandLengthFactor: 0.7,',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
              intervals: polarIntervals,
              intervalStyle: styledIntervalStyle,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarIntervalRows)
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Observed',
              intervalLow: (row) => row.intervalLow,
              intervalHigh: (row) => row.intervalHigh,
              intervalStyle: styledIntervalStyle,
            )
            .build(bravenChartController: controller),
      );
      expect('intervalLow: null,'.allMatches(generated.source).length, 1);
      expect('intervalHigh: null,'.allMatches(generated.source).length, 1);
      // The same unguarded seam as shape 24's target marker: asserted whole so
      // a field dropped from `_emitPolarIntervalStyleArgument` cannot hide
      // behind a fragment list that never named it.
      expect(
        literalArguments(
          generated.source,
          'intervalStyle: PolarColumnIntervalStyle(',
        ),
        <String>[
          'display: PolarColumnIntervalDisplay.band,',
          'color: Color(0xFF334155),',
          'width: 2.0,',
          'capLengthFactor: 0.5,',
          'bandLengthFactor: 0.7,',
          'opacity: 0.8,',
        ],
      );
    });

    testWidgets('shape 26: a ROSE polar emits rose: true and round-trips', (
      tester,
    ) async {
      await expectRoundTrip(
        tester,
        name: 'polar_rose',
        fragments: <String>[
          '.geomPolar(',
          'rose: true,',
          'columnColor: (row) => row.columnColor,',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.rose(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
              columnColors: polarColumnColors,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarRoseRows)
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Observed',
              rose: true,
              columnColor: (row) => row.columnColor,
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 27: TWO polar series each carrying their OWN advanced '
        'channels interleave their fields and round-trip', (tester) async {
      // Shapes 24-26 are all SINGLE-series, so `seriesIndex` is always 0 there
      // and nothing interleaves: `columnColors[seriesIndex]` and
      // `columnColors[0]` are the same expression, and hoisting every advanced
      // `_addField` into a second pass after all the value fields would not
      // move a single slot. This is the shape that can tell those apart.
      //
      // Both series carry column colors AND targets — over DIFFERENT category
      // subsets — and the second also carries intervals, so the reversal must
      // allocate `columnColor2`/`target2` for the second series and bind each
      // geom to its own fields.
      final generated = await expectRoundTrip(
        tester,
        name: 'polar_pair_advanced',
        fragments: <String>[
          'final Color? columnColor;',
          'final double? target;',
          'final double value2;',
          'final Color? columnColor2;',
          'final double? target2;',
          'final double? intervalLow;',
          'final double? intervalHigh;',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              name: 'Observed',
              values: polarObserved,
              columnColors: polarColumnColors,
              targets: polarTargets,
              targetMarkerStyle: styledTargetMarker,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'forecast',
              name: 'Forecast',
              values: polarCapacity,
              columnColors: polarForecastColumnColors,
              targets: polarForecastTargets,
              intervals: polarForecastIntervals,
              intervalStyle: styledIntervalStyle,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(polarPairRows)
            .geomPolar(
              id: 'observed',
              category: (row) => row.category,
              value: (row) => row.value,
              name: 'Observed',
              columnColor: (row) => row.columnColor,
              target: (row) => row.target,
              targetMarkerStyle: styledTargetMarker,
            )
            .geomPolar(
              id: 'forecast',
              category: (row) => row.category,
              value: (row) => row.value2,
              name: 'Forecast',
              columnColor: (row) => row.columnColor2,
              target: (row) => row.target2,
              intervalLow: (row) => row.intervalLow,
              intervalHigh: (row) => row.intervalHigh,
              intervalStyle: styledIntervalStyle,
            )
            .build(bravenChartController: controller),
      );

      // The row class's field ORDER is the interleaving, observable: series 1's
      // advanced fields sit BETWEEN the two value fields. A second pass that
      // allocated every advanced field after both values would emit the same
      // set of names in a different order and pass a `contains` per name.
      var cursor = 0;
      for (final declaration in <String>[
        'final String category;',
        'final double value;',
        'final Color? columnColor;',
        'final double? target;',
        'final double value2;',
        'final Color? columnColor2;',
        'final double? target2;',
        'final double? intervalLow;',
        'final double? intervalHigh;',
      ]) {
        final at = generated.source.indexOf(declaration, cursor);
        expect(
          at,
          isNonNegative,
          reason:
              'expected "$declaration" after offset $cursor in:\n'
              '${generated.source}',
        );
        cursor = at + declaration.length;
      }

      // And each geom reads ITS OWN slots. Split on the verb so an accessor
      // cannot satisfy the assertion from the other mark's argument list.
      final geoms = generated.source.split('.geomPolar(');
      expect(geoms, hasLength(3));
      expect(geoms[1], contains("id: 'observed',"));
      expect(geoms[1], contains('value: (row) => row.value,'));
      expect(geoms[1], contains('columnColor: (row) => row.columnColor,'));
      expect(geoms[1], contains('target: (row) => row.target,'));
      expect(geoms[1], contains('targetMarkerStyle: '));
      expect(geoms[1], isNot(contains('intervalLow')));
      expect(geoms[1], isNot(contains('intervalStyle')));
      expect(geoms[2], contains("id: 'forecast',"));
      expect(geoms[2], contains('value: (row) => row.value2,'));
      expect(geoms[2], contains('columnColor: (row) => row.columnColor2,'));
      expect(geoms[2], contains('target: (row) => row.target2,'));
      expect(geoms[2], contains('intervalLow: (row) => row.intervalLow,'));
      expect(geoms[2], contains('intervalHigh: (row) => row.intervalHigh,'));
      // The second series left its target marker at the default, so the shared
      // renderer must write nothing for it — proof the two marks' styles are
      // read per series and not hoisted off the first.
      expect(geoms[2], isNot(contains('targetMarkerStyle')));

      // The two series' nulls land on DIFFERENT categories ('Fig' has no
      // target on series 1, 'Apple' has none on series 2; 'Plum' has no
      // interval), so a reversal that read one series' parallel array for both
      // would misplace them. Four rows × the emitted `target:`/`target2:` slots.
      expect('target: null,'.allMatches(generated.source).length, 1);
      expect('target2: null,'.allMatches(generated.source).length, 1);
      expect('columnColor: null,'.allMatches(generated.source).length, 2);
      expect('columnColor2: null,'.allMatches(generated.source).length, 2);
      expect('intervalLow: null,'.allMatches(generated.source).length, 1);
      expect('intervalHigh: null,'.allMatches(generated.source).length, 1);
    });

    testWidgets('shape 28: a CUSTOMISED ConcentricDonutConfig emits '
        'concentric: and round-trips', (tester) async {
      // Before this slice the composition config was reconstructed from the
      // mark's `center` alone, so a customised ring gap / order / weights /
      // radii was honestly REFUSED. `geomDonut(concentric:)` now carries the
      // whole config, and the emitter reverses it through the config emitter's
      // own `ConcentricDonutConfig` renderer.
      // EVERY field differs from its default, so a passthrough that quietly
      // drops one cannot masquerade as success. `_firstRadialMismatch` cannot
      // catch that for this family — the planner hands the captured config to
      // `DonutMark.concentric` and lowering hands the same object back, so the
      // comparison is tautological — which puts the whole guarantee on the
      // emitted literal asserted below.
      const custom = ConcentricDonutConfig(
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.85,
        ringGap: 12,
        order: ConcentricRingOrder.innerToOuter,
        // A ring weight is keyed by the SERIES id, which the concentric
        // lowering names `<markId>-<ringKey>`.
        ringWeights: <String, double>{'seasons-Winter': 2},
        legendMode: ConcentricDonutLegendMode.flat,
        centerContent: DonutCenterContent(label: 'Harvest'),
      );
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_custom_config',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          'concentric: ConcentricDonutConfig(',
          'innerRadiusFactor: 0.2',
          'outerRadiusFactor: 0.85',
          'ringGap: 12',
          'order: ConcentricRingOrder.innerToOuter',
          "'seasons-Winter': 2",
          'legendMode: ConcentricDonutLegendMode.flat',
          "label: 'Harvest'",
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
              concentric: custom,
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              concentric: custom,
            )
            .build(bravenChartController: controller),
      );
      // The config owns the center, so the shorthand must NOT also be emitted:
      // lowering refuses a mark that sets both.
      expect(generated.source, isNot(contains('center: DonutCenterContent(')));
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
      final generated = await expectRoundTrip(
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
      // An explicit `const ConcentricDonutConfig()` is the DEFAULT composition,
      // so the passthrough must write nothing (see shape 14).
      expect(generated.source, isNot(contains('concentric:')));
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
      // Per-RING series options are not a COMPOSITION: the config stays
      // default, so it must not be written (see shape 14).
      expect(generated.source, isNot(contains('concentric:')));
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

  // =========================================================================
  // ACCEPTANCE GATE — every polar + concentric workbench Grammar pane emits.
  //
  // The unit tests above each isolate ONE mechanism (a config field, a channel,
  // a composition). This group asks the question the slice exists to answer:
  // does the chart the showcase page ACTUALLY MOUNTS reach the Grammar pane as
  // a real chain? Each case is `polar_column_page.dart`'s own construction —
  // `_buildSeriesList` for the series and `_buildPolarConfig` for the plot
  // config, at that presentation's authored knob values — so a regression that
  // only shows up on a real showcase chart fails here.
  //
  // Emission is the whole assertion because the generator refuses anything it
  // cannot reproduce: it re-lowers the chain it is about to write and compares
  // the result to the hydrated document, so "a chain was emitted" already
  // carries "this chain rebuilds this chart".
  // =========================================================================

  group('showcase acceptance: every polar presentation emits', () {
    testWidgets('standard: per-category column colors over eight categories', (
      tester,
    ) async {
      final colors = showcaseColumnColors(
        showcaseStandardValues,
        showcaseOceanPalette,
      );
      final generated = await expectShowcaseEmits(
        tester,
        presentation: 'standard',
        fragments: <String>[
          '.geomPolar(',
          'columnColor: (row) => row.columnColor,',
          '.polarConfig(',
          'outerRadiusFactor: 0.84,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0,
            outerRadiusFactor: 0.84,
            innerPadding: 0.12,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFF1E293B),
            radialLabelColor: const Color(0xFF475569),
            compositionMode: PolarColumnCompositionMode.layered,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-column',
              name: 'Category volume',
              values: showcaseStandardValues,
              columnColors: colors,
              unit: 'requests',
              polarStyle: showcasePolarStyle(
                cornerRadius: 4,
                opacity: 0.97,
                borderColor: const Color(0xFF1E3A5F),
                animationMode: PolarColumnAnimationMode.grow,
              ),
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 1);
    });

    testWidgets('rose: the area-correct preset with a gradient and a shadow', (
      tester,
    ) async {
      final colors = showcaseColumnColors(
        showcaseRoseValues,
        showcaseSunsetPalette,
      );
      await expectShowcaseEmits(
        tester,
        presentation: 'rose',
        fragments: <String>[
          '.geomPolar(',
          'rose: true,',
          'scaleMode: PolarRadialScaleMode.areaCorrect,',
          'gradient: PolarColumnGradientStyle(',
          'shadow: PolarColumnShadowStyle(',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.08,
            outerRadiusFactor: 0.86,
            innerPadding: 0.08,
            outerPadding: 0,
            categoryLabelColor: const Color(0xFFF8FAFC),
            radialLabelColor: const Color(0xFFFDE68A),
            scaleMode: PolarRadialScaleMode.areaCorrect,
            compositionMode: PolarColumnCompositionMode.layered,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.rose(
              id: 'showcase-polar-column',
              name: 'Monthly volume',
              values: showcaseRoseValues,
              columnColors: colors,
              unit: 'requests',
              polarStyle: showcasePolarStyle(
                cornerRadius: 6,
                opacity: 0.98,
                borderColor: const Color(0xFFF59E0B),
                valueLabelColor: const Color(0xFFFFF7ED),
                animationMode: PolarColumnAnimationMode.sweep,
                gradient: const PolarColumnGradientStyle(
                  startLightnessShift: 0.24,
                  endLightnessShift: -0.18,
                ),
                shadow: const PolarColumnShadowStyle(
                  color: Color(0xFF000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                  opacity: 0.38,
                ),
              ),
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
    });

    testWidgets('layered: two series whose per-series styles DIFFER', (
      tester,
    ) async {
      // The reference layer is the same style at a third of the opacity with
      // its data labels off — the case that forced one mark PER SERIES rather
      // than one mark with N value channels.
      final style = showcasePolarStyle(
        cornerRadius: 5,
        opacity: 0.92,
        borderColor: const Color(0xFF1E40AF),
        animationMode: PolarColumnAnimationMode.grow,
      );
      final generated = await expectShowcaseEmits(
        tester,
        presentation: 'layered',
        fragments: <String>[
          '.geomPolar(',
          'value: (row) => row.value,',
          'value: (row) => row.value2,',
          'opacity: 0.32,',
          'showDataLabels: false,',
          // `layered` IS the composition default, so the mode itself is
          // correctly elided; the pane/axis knobs are what prove the plot
          // config reached the chain.
          '.polarConfig(',
          'innerPadding: 0.16,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.12,
            outerRadiusFactor: 0.86,
            innerPadding: 0.16,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFF1E3A8A),
            radialLabelColor: const Color(0xFF1D4ED8),
            compositionMode: PolarColumnCompositionMode.layered,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-capacity',
              name: 'Capacity',
              values: showcaseLayeredCapacityValues,
              color: showcaseOceanPalette[1],
              unit: 'orders',
              polarStyle: style.copyWith(
                opacity: math.min(0.92, 0.32),
                showDataLabels: false,
              ),
              selectionStyle: showcasePolarSelection,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-observed',
              name: 'Observed',
              values: showcaseLayeredObservedValues,
              color: showcaseOceanPalette.first,
              unit: 'orders',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 2);
    });

    testWidgets('grouped: three series and a grouped composition', (
      tester,
    ) async {
      final style = showcasePolarStyle(
        cornerRadius: 4,
        opacity: 0.92,
        borderColor: const Color(0xFF7C2D12),
        animationMode: PolarColumnAnimationMode.grow,
        gradient: const PolarColumnGradientStyle(
          startLightnessShift: 0.18,
          endLightnessShift: -0.16,
        ),
        shadow: const PolarColumnShadowStyle(
          color: Color(0xFF92400E),
          blurRadius: 7,
          offset: Offset(0, 2),
          opacity: 0.16,
        ),
      );
      final generated = await expectShowcaseEmits(
        tester,
        presentation: 'grouped',
        fragments: <String>[
          'value: (row) => row.value,',
          'value: (row) => row.value2,',
          'value: (row) => row.value3,',
          'mode: PolarColumnCompositionMode.grouped,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.1,
            outerRadiusFactor: 0.88,
            innerPadding: 0.12,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFF78350F),
            radialLabelColor: const Color(0xFF92400E),
            compositionMode: PolarColumnCompositionMode.grouped,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-north',
              name: 'North',
              values: showcaseGroupedNorthValues,
              color: showcaseSunsetPalette[0],
              unit: 'orders',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-south',
              name: 'South',
              values: showcaseGroupedSouthValues,
              color: showcaseSunsetPalette[1],
              unit: 'orders',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-west',
              name: 'West',
              values: showcaseGroupedWestValues,
              color: showcaseSunsetPalette[2],
              unit: 'orders',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 3);
    });

    testWidgets('stacked: three series, one of them negative at every '
        'category', (tester) async {
      final style = showcasePolarStyle(
        cornerRadius: 4,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
        opacity: 0.97,
        borderColor: const Color(0xFF7DD3FC),
        valueLabelColor: const Color(0xFFF8FAFC),
        animationMode: PolarColumnAnimationMode.sweep,
        gradient: const PolarColumnGradientStyle(
          startLightnessShift: 0.2,
          endLightnessShift: -0.2,
        ),
        shadow: const PolarColumnShadowStyle(
          color: Color(0xFF000000),
          blurRadius: 10,
          offset: Offset(0, 4),
          opacity: 0.42,
        ),
      );
      final generated = await expectShowcaseEmits(
        tester,
        presentation: 'stacked',
        fragments: <String>[
          'mode: PolarColumnCompositionMode.stacked,',
          'cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,',
          // The third series' own value field, negative and unclamped.
          'value3: -13.0,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.14,
            outerRadiusFactor: 0.9,
            innerPadding: 0.12,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFFE0F2FE),
            radialLabelColor: const Color(0xFFBAE6FD),
            compositionMode: PolarColumnCompositionMode.stacked,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-new',
              name: 'New accounts',
              values: showcaseStackedNewValues,
              color: showcaseOceanPalette[0],
              unit: 'accounts',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-expansion',
              name: 'Expansion',
              values: showcaseStackedExpansionValues,
              color: showcaseOceanPalette[1],
              unit: 'accounts',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-churn',
              name: 'Churn',
              values: showcaseStackedChurnValues,
              color: showcaseOceanPalette[2],
              unit: 'accounts',
              polarStyle: style,
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 3);
    });

    testWidgets('references: targets, a target marker style and a threshold', (
      tester,
    ) async {
      final colors = showcaseColumnColors(
        showcaseReferenceActualValues,
        showcaseThemePalette(
          ChartTheme.colorblindFriendly,
          showcaseReferenceActualValues.length,
        ),
      );
      await expectShowcaseEmits(
        tester,
        presentation: 'references',
        fragments: <String>[
          'target: (row) => row.target,',
          'targetMarkerStyle: PolarColumnTargetMarkerStyle(',
          'lengthFactor: 0.68,',
          'thresholds: [',
          "label: 'Capacity',",
          'dashPattern: <double>[7.0, 4.0],',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.12,
            outerRadiusFactor: 0.88,
            innerPadding: 0.14,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFF1F2937),
            radialLabelColor: const Color(0xFF475569),
            compositionMode: PolarColumnCompositionMode.layered,
            thresholds: const <PolarThreshold>[
              PolarThreshold(
                value: 80,
                label: 'Capacity',
                color: Color(0xFFDC2626),
                width: 2,
                dashPattern: <double>[7, 4],
              ),
            ],
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-actual-targets',
              name: 'Actual versus plan',
              values: showcaseReferenceActualValues,
              targets: showcaseReferenceTargetValues,
              columnColors: colors,
              unit: 'orders',
              polarStyle: showcasePolarStyle(
                cornerRadius: 5,
                opacity: 0.9,
                borderColor: const Color(0xFF334155),
                animationMode: PolarColumnAnimationMode.grow,
              ),
              selectionStyle: showcasePolarSelection,
              targetMarkerStyle: const PolarColumnTargetMarkerStyle(
                color: Color(0xFFF59E0B),
                width: 3,
                lengthFactor: 0.68,
              ),
            ),
          ],
        ),
      );
    });

    testWidgets('intervals: both interval bounds and an interval style', (
      tester,
    ) async {
      final colors = showcaseColumnColors(
        showcaseUncertaintyValues,
        showcaseOceanPalette,
      );
      await expectShowcaseEmits(
        tester,
        presentation: 'intervals',
        fragments: <String>[
          'intervalLow: (row) => row.intervalLow,',
          'intervalHigh: (row) => row.intervalHigh,',
          // The showcase's authored interval knobs are the class defaults
          // apart from the color and the width, so those two are what prove
          // the style reached the chain.
          'intervalStyle: PolarColumnIntervalStyle(',
          'color: Color(0xFF0F172A),',
          'width: 2.0,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            innerRadiusFactor: 0.12,
            outerRadiusFactor: 0.88,
            innerPadding: 0.16,
            outerPadding: 0.04,
            categoryLabelColor: const Color(0xFF334155),
            radialLabelColor: const Color(0xFF475569),
            compositionMode: PolarColumnCompositionMode.layered,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-forecast-intervals',
              name: 'Forecast',
              values: showcaseUncertaintyValues,
              intervals: <String, PolarColumnInterval>{
                for (final category in showcaseUncertaintyValues.keys)
                  if (showcaseUncertaintyLowerValues[category] case final lower?)
                    if (showcaseUncertaintyUpperValues[category]
                        case final upper?)
                      category: PolarColumnInterval(
                        lower: lower.toDouble(),
                        upper: upper.toDouble(),
                      ),
              },
              columnColors: colors,
              unit: 'orders',
              polarStyle: showcasePolarStyle(
                cornerRadius: 5,
                opacity: 0.78,
                borderColor: const Color(0xFF1E3A8A),
                animationMode: PolarColumnAnimationMode.fade,
                gradient: const PolarColumnGradientStyle(
                  startLightnessShift: 0.22,
                  endLightnessShift: -0.14,
                ),
              ),
              selectionStyle: showcasePolarSelection,
              intervalStyle: const PolarColumnIntervalStyle(
                color: Color(0xFF0F172A),
                width: 2,
                capLengthFactor: 0.62,
                bandLengthFactor: 0.58,
                opacity: 0.92,
              ),
            ),
          ],
        ),
      );
    });

    testWidgets('a concentric donut at the showcase\'s non-default ring '
        'geometry emits', (tester) async {
      // `concentric_donut_page.dart` mounts its rings with a customised
      // `ConcentricDonutConfig` — radii, a ring gap, an order, a legend mode,
      // per-ring weights and a center. Every one of those was refused before
      // `geomDonut(concentric:)` carried the whole config, because lowering
      // rebuilt the composition from the center alone.
      //
      // The ring SERIES ids follow the `<markId>-<ring>` pattern the grammar's
      // own concentric lowering produces, which is what lets the composition be
      // reversed to a single ring-channel mark.
      await expectShowcaseEmits(
        tester,
        presentation: 'concentric donut',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring,',
          'concentric: ConcentricDonutConfig(',
          'innerRadiusFactor: 0.28,',
          'outerRadiusFactor: 0.94,',
          'ringGap: 6.0,',
          // `outerToInner` and `groupedByRing` are the class defaults the
          // showcase leaves alone, so they are correctly elided.
          "'revenue-Current period': 1.25,",
          "label: 'Revenue mix',",
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(
            innerRadiusFactor: 0.28,
            outerRadiusFactor: 0.94,
            ringGap: 6,
            order: ConcentricRingOrder.outerToInner,
            legendMode: ConcentricDonutLegendMode.groupedByRing,
            ringWeights: <String, double>{'revenue-Current period': 1.25},
            centerContent: DonutCenterContent(label: 'Revenue mix'),
          ),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'revenue-Current period',
              name: 'Current period',
              unit: 'USD',
              values: const <String, num>{
                'Subscriptions': 48,
                'Services': 27,
                'Hardware': 25,
              },
            ),
            DonutChartSeries.fromMap(
              id: 'revenue-Previous period',
              name: 'Previous period',
              unit: 'USD',
              values: const <String, num>{
                'Subscriptions': 41,
                'Services': 33,
                'Hardware': 26,
              },
            ),
          ],
        ),
      );
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

    testWidgets('a customised ConcentricDonutConfig EMITS, and the reason it '
        'used to be refused is gone', (tester) async {
      // This row of the matrix flipped: the grammar used to carry only a
      // concentric donut's shared center, so a custom ringGap could not
      // round-trip and was honestly refused. `geomDonut(concentric: ...)` now
      // carries the whole composition, so the same CONFIG-FORM chart emits a
      // chain — and the round trip below proves the emitted chain rebuilds the
      // captured chart rather than silently dropping the config.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_config_form_custom',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          'concentric: ConcentricDonutConfig(',
          'ringGap: 12',
        ],
        original: (controller) => BravenChartPlus(
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
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              concentric: const ConcentricDonutConfig(ringGap: 12),
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
      expect(generated.source, isNot(contains('Cartesian-only')));
    });

    testWidgets('polar series whose category domains differ are refused by '
        'HYDRATION, before the emitter runs', (tester) async {
      // N geomPolar marks share ONE row list, so every polar series must have a
      // value at every category of the shared domain, in the same order — which
      // is exactly the contract `PolarColumnComposition.validate` already
      // enforces at mount, at hydration AND (since the composition diagnostics
      // landed) at grammar lowering. `ChartGrammarSourceGenerator.generate`
      // hydrates first and returns that failure, so this shape never reaches the
      // planner: the assertions below deliberately pin the HYDRATOR's diagnostic
      // (its code, its path and its wording), not the planner's, which reads
      // '"<id>" sets the domain; these series do not match it'. The planner's
      // own `misaligned` guard is unreachable defence in depth and is documented
      // as such at `_planPolarChart`; nothing here claims to cover it.
      final plain = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'capacity',
              values: const <String, num>{'A': 3, 'B': 5},
            ),
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              values: const <String, num>{'A': 4, 'B': 8},
            ),
          ],
        ),
      );
      // The mounted chart is a legal composition; break the SECOND series'
      // second category in the document so the domains no longer align.
      final snapshot = patchedSnapshot(plain, (json) {
        final series = json['series']! as List<Object?>;
        final data =
            (series[1]! as Map<String, Object?>)['data']!
                as Map<String, Object?>;
        final points = data['points']! as List<Object?>;
        (points[1]! as Map<String, Object?>)['label'] = 'C';
      });
      final result = ChartGrammarSourceGenerator.generate(snapshot);
      expect(result, isA<ChartArtifactFailure<ChartGeneratedSource>>());
      final error = (result as ChartArtifactFailure<ChartGeneratedSource>).error;
      expect(error.code, ChartArtifactDiagnosticCodes.invalidArtifact);
      expect(error.path, r'$.document.configuration.polarChart');
      expect(
        error.message,
        allOf(
          contains('Invalid Polar Column composition'),
          contains('same categories in the same order'),
        ),
      );
    });

    testWidgets('a multi-series polar composition emits when the domains do '
        'align', (tester) async {
      // The positive control for the test above: the SAME two series, unpatched,
      // reverse to two geomPolar marks over one shared category field.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'capacity',
              values: const <String, num>{'A': 3, 'B': 5},
            ),
            PolarColumnChartSeries.fromMap(
              id: 'observed',
              values: const <String, num>{'A': 4, 'B': 8},
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isTrue);
      expect('.geomPolar('.allMatches(generated.source).length, 2);
      // A DEFAULT plot config stays implicit — the chain emits no .polarConfig.
      expect(generated.source, isNot(contains('.polarConfig(')));
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
