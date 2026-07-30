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
/// 1. the generated Dart parses and analyzes (`expectGeneratedSourceCompiles`
///    — `dart format --output=none` is a syntax gate, not a "already
///    formatted" assertion; see that helper's own doc),
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

import 'dart:io';
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

/// The row shape the emitter synthesises for a series carrying per-point text:
/// one non-nullable `String` slot per accessor, `''` where the captured point
/// had none. The field NAMES are the ones the emitter derives from the series
/// name ('Power' -> `powerLabel`, `powerPointKey`), so a rebuilt twin written
/// against this class is written against the emitter's own naming.
class KeyedRow {
  const KeyedRow({
    required this.x,
    required this.power,
    this.powerLabel = '',
    this.powerPointKey = '',
  });

  final double x;
  final double power;
  final String powerLabel;
  final String powerPointKey;
}

const keyedRows = <KeyedRow>[
  KeyedRow(x: 0, power: 168, powerLabel: 'Warm-up', powerPointKey: 'p0'),
  KeyedRow(x: 1, power: 204, powerLabel: 'Threshold', powerPointKey: 'p1'),
  KeyedRow(x: 2, power: 268, powerLabel: 'VO2', powerPointKey: 'p2'),
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

/// The donut-centre label / value styling the showcase page applies.
///
/// `donut_charts_page.dart` builds both from its resolved chart theme in every
/// centre preset, so a centre the grammar can carry has to carry these two —
/// they are the reason a rebuilt-from-four-fields centre diverged.
const donutCentreLabelStyle = LabelStyle(
  textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11),
  backgroundColor: Color(0x00000000),
  borderColor: Color(0x00000000),
  borderWidth: 0,
  borderRadius: 0,
  padding: EdgeInsets.zero,
);

const donutCentreValueStyle = LabelStyle(
  textStyle: TextStyle(
    color: Color(0xFF0F172A),
    fontSize: 22,
    fontWeight: FontWeight.w700,
  ),
  backgroundColor: Color(0x00000000),
  borderColor: Color(0x00000000),
  borderWidth: 0,
  borderRadius: 0,
  padding: EdgeInsets.zero,
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

/// A colour-bearing synthesised radial row: category / value / sliceColor.
///
/// The generator names the per-slice colour field `sliceColor` and types it
/// `Color?`, because a category with NO override is a real, reproducible state
/// — it rides the series colour — and `null` is how the row writes it.
class RadialColorRow {
  const RadialColorRow({
    required this.category,
    required this.value,
    required this.sliceColor,
  });

  final String category;
  final double value;
  final Color? sliceColor;
}

/// PARTIAL colouring on purpose: two of the four harvest categories carry an
/// override and two do not, so the round trip has to reproduce the ABSENCES as
/// well as the colours. A map that coloured every slice would pass even if the
/// reversal invented a colour for the uncoloured ones.
const _harvestSliceColors = <String, Color>{
  'Apple': Color(0xFF2563EB),
  'Plum': Color(0xFF0D9488),
};

final List<RadialColorRow> sliceColorGrammarRows = <RadialColorRow>[
  for (final row in harvest)
    RadialColorRow(
      category: row.fruit,
      value: row.count,
      sliceColor: _harvestSliceColors[row.fruit],
    ),
];

/// A colour AND radius bearing synthesised radial row. The generator allocates
/// `radius` before `sliceColor`, so the field order here mirrors the emitted
/// row class.
class RadialColorRadiusRow {
  const RadialColorRadiusRow({
    required this.category,
    required this.value,
    required this.radius,
    required this.sliceColor,
  });

  final String category;
  final double value;
  final double radius;
  final Color? sliceColor;
}

final List<RadialColorRadiusRow> sliceColorRadiusGrammarRows =
    <RadialColorRadiusRow>[
      for (final row in harvest)
        RadialColorRadiusRow(
          category: row.fruit,
          value: row.count,
          radius: _harvestRadii[row.fruit]!.toDouble(),
          sliceColor: _harvestSliceColors[row.fruit],
        ),
    ];

/// A ring-bearing colour row: ring / category / value / sliceColor, in the
/// generator's own allocation order (`ring` first for a concentric plan).
class ConcentricColorRow {
  const ConcentricColorRow({
    required this.ring,
    required this.category,
    required this.value,
    required this.sliceColor,
  });

  final String ring;
  final String category;
  final double value;
  final Color? sliceColor;
}

/// A CROSS-RING colour fixture: both rings carry the SAME two categories, and
/// `Apple` takes a DIFFERENT colour in each.
///
/// `harvest` cannot express this — every fruit there belongs to exactly one
/// season — and that matters, because `fromMap` reads `sliceColors[category]`
/// only for the categories present in `values`. Over a disjoint fixture a
/// colour map resolved across the WHOLE data set produces byte-identical rings,
/// so it would prove nothing about per-bucket resolution. Here it does: over
/// the whole list the map collapses to `{Apple: 0xFFDC2626, Pear: 0xFF0D9488}`
/// (last non-null wins) and the Winter ring comes back wrong on both keys.
const _concentricSliceColors = <String, Map<String, Color>>{
  'Winter': <String, Color>{'Apple': Color(0xFF2563EB)},
  'Summer': <String, Color>{
    'Apple': Color(0xFFDC2626),
    'Pear': Color(0xFF0D9488),
  },
};

const List<ConcentricColorRow> concentricColorGrammarRows =
    <ConcentricColorRow>[
      ConcentricColorRow(
        ring: 'Winter',
        category: 'Apple',
        value: 42,
        sliceColor: Color(0xFF2563EB),
      ),
      ConcentricColorRow(
        ring: 'Winter',
        category: 'Pear',
        value: 31,
        sliceColor: null,
      ),
      ConcentricColorRow(
        ring: 'Summer',
        category: 'Apple',
        value: 17,
        sliceColor: Color(0xFFDC2626),
      ),
      ConcentricColorRow(
        ring: 'Summer',
        category: 'Pear',
        value: 10,
        sliceColor: Color(0xFF0D9488),
      ),
    ];

// ---------------------------------------------------------------------------
// PER-RING LABEL fixtures. A concentric composition whose rings carry DIFFERENT
// `PieDataLabelConfig`s reverses to ONE base `dataLabels:` plus a
// `dataLabelsByRing:` override map holding only the rings that DIFFER from the
// base. The third ring is deliberately the family DEFAULT: against a
// non-default base that is a real override, and an emitter that treated
// "equals the default" as "nothing to write" would silently change the chart.
// ---------------------------------------------------------------------------

/// The base — ring 0's config, and therefore what `dataLabels:` emits.
const outerRingLabels = PieDataLabelConfig(
  position: PieDataLabelPosition.inside,
  padding: 10,
);

/// A different NON-default config: projected into the override map.
const middleRingLabels = PieDataLabelConfig(
  content: PieDataLabelContent.category,
  minimumShare: 0.2,
);

const List<RadialGrammarRow> concentricLabelGrammarRows = <RadialGrammarRow>[
  RadialGrammarRow(ring: 'Outer', category: 'Subscriptions', value: 48),
  RadialGrammarRow(ring: 'Outer', category: 'Services', value: 27),
  RadialGrammarRow(ring: 'Middle', category: 'Subscriptions', value: 41),
  RadialGrammarRow(ring: 'Middle', category: 'Services', value: 33),
  RadialGrammarRow(ring: 'Inner', category: 'Subscriptions', value: 35),
  RadialGrammarRow(ring: 'Inner', category: 'Services', value: 29),
];

/// `concentric_donut_page.dart`'s `hierarchy` label layout: the outer ring keeps
/// the family default and every inner ring moves its labels inside and drops
/// the percentage. This is the exact pair the pinned BLOCKER 3 test used.
const hierarchyOuterLabels = PieDataLabelConfig(
  position: PieDataLabelPosition.outside,
  content: PieDataLabelContent.categoryAndPercentage,
);

const hierarchyInnerLabels = PieDataLabelConfig(
  position: PieDataLabelPosition.inside,
  content: PieDataLabelContent.category,
);

const List<RadialGrammarRow> hierarchyLabelGrammarRows = <RadialGrammarRow>[
  RadialGrammarRow(
    ring: 'Current period',
    category: 'Subscriptions',
    value: 48,
  ),
  RadialGrammarRow(ring: 'Current period', category: 'Services', value: 27),
  RadialGrammarRow(
    ring: 'Previous period',
    category: 'Subscriptions',
    value: 41,
  ),
  RadialGrammarRow(ring: 'Previous period', category: 'Services', value: 33),
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
// These are a HAND TRANSCRIPTION of
// `example/lib/showcase/pages/polar_column_page.dart` (`_buildSeriesList` and
// `_buildPolarConfig`): the data maps, the palette swatches, the per-
// presentation pane/axis/composition knobs and the per-presentation styling
// each of the eight authored presentations applies. The showcase is what the
// workbench Grammar pane actually renders, so a chart built from these values
// emitting a chain IS the claim "every polar Grammar pane emits" — but ONLY
// for as long as the transcription still says what the page says.
//
// A hand copy has exactly one failure mode: the page is edited and nothing
// here notices, so the gate keeps passing about a chart the showcase no longer
// mounts. Two things close that, and it is worth being exact about which does
// what because they cover different halves of the copy:
//
//   * `group('showcase transcription sync guard')` parses the page's own
//     source and compares it to the constants below — the presentation enum,
//     every `<String, num>` value map (contents AND key order, which the
//     palette cycling depends on) and every transcribed swatch.
//   * [expectShowcaseKnobsMatchPage], which every polar acceptance case runs
//     before it asserts anything about emission, resolves that presentation's
//     KNOBS out of the page's two presentation methods and compares them to
//     the `PolarChartConfig` and `PolarColumnStyle` the case actually mounted.
//     That is the half the data guard never covered: pane geometry, the
//     angular span, axis paddings and label styling, composition, column
//     styling, gradient and shadow, the selection style, and the threshold,
//     target-marker and interval styling.
//
// Add a presentation, rename one, nudge a number in a data map or move a knob
// on the page, and one of the two goes red naming the drift; together they are
// what keeps the sentence above true rather than merely historic.
//
// What is still a bare hand copy, stated so the gate is not read as wider than
// it is: WHICH value map feeds which series and which channel (swap the page's
// `_values` and `_comparisonValues` and both guards stay green), the series
// ids, names and units, the per-series `copyWith` on `layered`'s reference
// layer, and the palette a presentation SELECTS (the swatches are held to the
// page, the per-presentation `_palette =` choice is not).
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

/// The `partial` presentation's lifecycle stages (`_partialValues`).
///
/// This is the only presentation that moves the PANE off its defaults — a 240°
/// sweep from 150° with an annular baseline — so it is the only one whose
/// acceptance depends on `PolarPaneConfig.startAngleDegrees`/`sweepAngleDegrees`
/// surviving the reversal.
const showcasePartialValues = <String, num>{
  'Discover': 84,
  'Evaluate': 62,
  'Trial': 73,
  'Adopt': 91,
  'Expand': 66,
  'Renew': 79,
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

/// The showcase's `_PolarPalette.earth` swatch.
const showcaseEarthPalette = <Color>[
  Color(0xFF386641),
  Color(0xFF6A994E),
  Color(0xFFA7C957),
  Color(0xFFBC6C25),
  Color(0xFFDDA15E),
];

/// `_categoryColors` for `_PolarPalette.theme`: the base theme's own series
/// colors, at least eight of them.
List<Color> showcaseThemePalette(ChartTheme theme, int categoryCount) =>
    List<Color>.generate(math.max(8, categoryCount), theme.seriesTheme.colorAt);

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
  // Seven of the eight presentations leave the pane's angular span alone;
  // `partial` is the one that authors it, so it rides parameters defaulted to
  // the showcase's own resting values rather than a second forked helper.
  double startAngleDegrees = -90,
  double sweepAngleDegrees = 360,
}) => PolarChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: startAngleDegrees,
    sweepAngleDegrees: sweepAngleDegrees,
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

// ---------------------------------------------------------------------------
// SYNC GUARD readers — how the transcription above is held to the page.
//
// The guard cannot import the page: `_PolarPresentation` and every `_…Values`
// map are library-private to `polar_column_page.dart`, and the example is a
// separate package this one does not depend on. So it reads the page as TEXT
// and parses the few declarations the transcription copies. That is a narrow
// contract — these readers know the page's declaration syntax, not its
// meaning — and each one fails loudly, naming the declaration it could not
// find, rather than quietly returning nothing (an empty result compared
// against an empty expectation is how a guard dies silently).
// ---------------------------------------------------------------------------

/// The path the guard reads the polar showcase page from.
///
/// `flutter test` runs with the package root as its working directory — the
/// same fact `expectGeneratedSourceCompiles` relies on when it drops a scratch
/// file next to `pubspec.yaml` so `package:braven_charts` resolves.
const showcasePolarPagePath =
    'example/lib/showcase/pages/polar_column_page.dart';

/// This file, which the guard reads to check every presentation is covered.
const grammarGeneratorTestPath =
    'test/unit/source/chart_grammar_source_generator_test.dart';

/// Reads [path] relative to the package root, failing with a directed message
/// when it is not there.
String readRepoFile(String path) {
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason:
        'the showcase sync guard cannot find "$path" (working directory '
        '"${Directory.current.path}"). If the file MOVED, move this path with '
        'it — deleting the guard instead re-opens the drift it exists to stop.',
  );
  return file.readAsStringSync();
}

/// [source] with the INTERIOR of every quoted literal blanked to spaces,
/// preserving both length and line structure.
///
/// The enum-value list ends at the first `;` after the header — but only if a
/// scan can tell code from prose. `_PolarPresentation.references` describes
/// itself as *'Amber ticks mark category targets; the dashed ring marks shared
/// capacity'*, and a naive `indexOf(';')` stops THERE, truncating the enum to
/// seven values and reporting `intervals` as deleted. (Observed: this guard's
/// first run failed exactly that way.) A guard that cries drift over its own
/// parser is worse than none, so the quotes are handled.
String blankStringLiterals(String source) {
  final out = source.split('');
  var index = 0;
  while (index < source.length) {
    final quote = source[index];
    if (quote != "'" && quote != '"') {
      index++;
      continue;
    }
    var cursor = index + 1;
    while (cursor < source.length && source[cursor] != quote) {
      final escaped = source[cursor] == r'\';
      out[cursor] = source[cursor] == '\n' ? '\n' : ' ';
      cursor++;
      if (escaped && cursor < source.length) {
        out[cursor] = source[cursor] == '\n' ? '\n' : ' ';
        cursor++;
      }
    }
    index = cursor + 1;
  }
  return out.join();
}

/// The value names of `enum [enumName]` in [source], in declaration order.
///
/// Every value sits at exactly two spaces of indent, so a value's own arguments
/// (four spaces or more) cannot be mistaken for another value. The scan runs
/// over the body from the header only — never the whole file — so an apostrophe
/// in some unrelated comment cannot confuse [blankStringLiterals].
List<String> enumValueNames(String source, String enumName) {
  final header = 'enum $enumName {';
  final start = source.indexOf(header);
  expect(start, isNonNegative, reason: 'no "$header" in the showcase page');
  final body = blankStringLiterals(source.substring(start + header.length));
  final end = body.indexOf(';');
  expect(end, isNonNegative, reason: 'unterminated "$header"');
  final names = <String>[
    for (final match in RegExp(
      r'^  ([a-z][A-Za-z0-9_]*)\s*\(',
      multiLine: true,
    ).allMatches(body.substring(0, end)))
      match.group(1)!,
  ];
  expect(names, isNotEmpty, reason: 'parsed no values out of "$header"');
  return names;
}

/// The names of every `static const _…Values = <String, num>{…}` map the
/// showcase page declares.
///
/// This is the half of the guard that notices an ADDED map — a new
/// presentation's data landing on the page with no transcription and no
/// acceptance case.
Set<String> showcaseNumMapNames(String source) => <String>{
  for (final match in RegExp(
    r'static const (_[A-Za-z0-9_]*Values) = <String, num>\{',
  ).allMatches(source))
    match.group(1)!,
};

/// The `static const [name] = <String, num>{…}` map in [source], in the page's
/// own key order (which is what the palette cycles over, so it is load-bearing).
Map<String, num> showcaseNumMap(String source, String name) {
  final header = 'static const $name = <String, num>{';
  final start = source.indexOf(header);
  expect(start, isNonNegative, reason: 'no "$header" in the showcase page');
  final end = source.indexOf('};', start);
  expect(end, isNonNegative, reason: 'unterminated "$header"');
  final entries = <String, num>{
    for (final match in RegExp(
      r"'([^']*)'\s*:\s*(-?\d+(?:\.\d+)?)",
    ).allMatches(source.substring(start + header.length, end)))
      match.group(1)!: num.parse(match.group(2)!),
  };
  expect(entries, isNotEmpty, reason: 'parsed no entries out of "$header"');
  return entries;
}

/// The `const [Color(0x…), …]` swatch `_categoryColors` returns for
/// `_PolarPalette.[name]`.
List<Color> showcasePaletteSwatch(String source, String name) {
  final header = '_PolarPalette.$name => const [';
  final start = source.indexOf(header);
  expect(start, isNonNegative, reason: 'no "$header" in the showcase page');
  final end = source.indexOf('],', start);
  expect(end, isNonNegative, reason: 'unterminated "$header"');
  final colors = <Color>[
    for (final match in RegExp(
      r'Color\(0x([0-9A-Fa-f]{8})\)',
    ).allMatches(source.substring(start + header.length, end)))
      Color(int.parse(match.group(1)!, radix: 16)),
  ];
  expect(colors, isNotEmpty, reason: 'parsed no colors out of "$header"');
  return colors;
}

// ---------------------------------------------------------------------------
// KNOB SYNC readers — how the acceptance cases' per-presentation LITERALS are
// held to the page.
//
// The readers above cover the page's DATA: its `<String, num>` maps and its
// palette swatches. They say nothing about the other half of what each
// acceptance case copies out of the page — the pane radii, the angular span,
// the axis paddings and label styling, the composition mode, the column
// styling, the selection style and (for two presentations) the threshold,
// target-marker and interval styling. Those are not declarations; they are
// plain field assignments spread across `_applyAuthoredPresentationStyle` and
// `_applyPresentation`, and a guard that stopped at the data let every one of
// them drift silently. (Verified, not assumed: with only the data guard in
// place, changing the page's `_outerRadius` for `standard` from 0.84 to 0.5
// left the whole suite green while the `standard` acceptance case went on
// mounting 0.84.)
//
// So these readers reconstruct, from the page's own source, the value a knob
// RESOLVES to for one presentation — field initialisers first, then each
// method's pre-switch statements, then that presentation's own case, in the
// order the page itself applies them. [expectShowcaseKnobsMatchPage] then
// compares the resolved values against the objects the acceptance case
// actually MOUNTED. There is deliberately no second transcription table in
// between: page source is compared to live config, so there is no third thing
// for the two to drift apart from.
//
// The contract is narrow and worth stating: these readers know the page's
// ASSIGNMENT SYNTAX, not its meaning. A knob the page computes instead of
// assigning a literal cannot be followed, and every reader fails loudly naming
// the knob it could not resolve rather than returning nothing.
// ---------------------------------------------------------------------------

/// The interior of the `{…}` block whose opening brace is at [openIndex].
///
/// Brace-matched over [blankStringLiterals] so a brace inside a string literal
/// cannot close the block early.
String blockBody(String source, int openIndex) {
  final scan = blankStringLiterals(source);
  var depth = 0;
  for (var index = openIndex; index < scan.length; index++) {
    if (scan[index] == '{') depth++;
    if (scan[index] == '}') {
      depth--;
      if (depth == 0) return source.substring(openIndex + 1, index);
    }
  }
  fail('unterminated block at offset $openIndex of the showcase page');
}

/// The body of the method whose declaration begins with [header].
///
/// The body opens at the first `) {` after the header rather than the first
/// `{`: `_applyPresentation` takes a named parameter, so its first brace opens
/// the PARAMETER group and a naive scan would return the parameter list.
String pageMethodBody(String source, String header) {
  final start = source.indexOf(header);
  expect(start, isNonNegative, reason: 'no "$header" in the showcase page');
  final open = source.indexOf(') {', start);
  expect(open, isNonNegative, reason: 'no body for "$header"');
  return blockBody(source, open + 2);
}

/// The statements [body] runs for [presentation], or its statements BEFORE the
/// `switch (presentation)` when [presentation] is null.
///
/// Both presentation methods are a shared prelude followed by one case per
/// presentation, and the prelude is load-bearing: five of the eight
/// presentations never assign `_valueLabelColor`, so its resolved value IS the
/// prelude's `null`.
String presentationSection(String body, String? presentation) {
  const header = 'switch (presentation) {';
  final switchStart = body.indexOf(header);
  expect(
    switchStart,
    isNonNegative,
    reason: 'no "$header" in a showcase presentation method',
  );
  if (presentation == null) return body.substring(0, switchStart);
  final cases = blockBody(body, switchStart + header.length - 1);
  final marker = 'case _PolarPresentation.$presentation:';
  final start = cases.indexOf(marker);
  expect(start, isNonNegative, reason: 'no "$marker" in the showcase page');
  final next = cases.indexOf('case _PolarPresentation.', start + marker.length);
  return cases.substring(start + marker.length, next < 0 ? cases.length : next);
}

/// Every `_field = <expression>;` statement in [section], later assignments
/// winning, with each expression whitespace-collapsed and `const ` stripped.
///
/// `=(?!=)` keeps a comparison (`presentation == _PolarPresentation.stacked`)
/// from being read as an assignment to its left operand.
Map<String, String> pageAssignments(String section) => <String, String>{
  for (final match in RegExp(
    r'(_[A-Za-z0-9_]+)\s*=(?!=)\s*([^;]*);',
  ).allMatches(blankStringLiterals(section)))
    match.group(1)!: normalisedExpression(match.group(2)!),
};

/// Every `<Type> _field = <expression>;` FIELD declaration in [source].
///
/// Anchored at exactly two spaces of indent, which is where a class member
/// sits and a statement inside a method body never does. These are the resting
/// values for the knobs neither presentation method assigns — the selection
/// style is entirely field initialisers.
Map<String, String> pageFieldInitialisers(String source) => <String, String>{
  for (final match in RegExp(
    r'^  [A-Za-z][^\n=;]*?\b(_[A-Za-z0-9_]+) = ([^;]*);',
    multiLine: true,
  ).allMatches(blankStringLiterals(source)))
    match.group(1)!: normalisedExpression(match.group(2)!),
};

/// [expression] on one line, with a leading `const ` removed.
String normalisedExpression(String expression) {
  final collapsed = expression.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.startsWith('const ')
      ? collapsed.substring('const '.length)
      : collapsed;
}

/// Every knob [presentation] resolves to, in the order the page applies them.
///
/// `_applyPresentation` calls `_applyAuthoredPresentationStyle` first and then
/// runs its own switch, so its assignments win — which is why the merge order
/// below is not alphabetical or arbitrary but the page's own execution order.
Map<String, String> showcaseAuthoredKnobs(String source, String presentation) {
  final styling = pageMethodBody(
    source,
    'void _applyAuthoredPresentationStyle(',
  );
  final applying = pageMethodBody(source, 'void _applyPresentation(');
  return <String, String>{
    ...pageFieldInitialisers(source),
    ...pageAssignments(presentationSection(styling, null)),
    ...pageAssignments(presentationSection(styling, presentation)),
    ...pageAssignments(presentationSection(applying, null)),
    ...pageAssignments(presentationSection(applying, presentation)),
  };
}

/// The resolved expression for [knob], failing when the page never assigns it.
String pageKnob(Map<String, String> knobs, String knob) {
  final value = knobs[knob];
  expect(
    value,
    isNotNull,
    reason:
        'the showcase page no longer assigns `$knob` anywhere the knob guard '
        'can follow — a field initialiser or one of the two presentation '
        'methods. If the knob was RENAMED, rename it here; if the page now '
        'COMPUTES it, the guard cannot follow it and the acceptance case that '
        'transcribes it needs another way to stay honest. Deleting the check '
        're-opens the drift it exists to stop.',
  );
  return value!;
}

/// [knob] as a double.
double pageDouble(Map<String, String> knobs, String knob) {
  final value = double.tryParse(pageKnob(knobs, knob));
  expect(
    value,
    isNotNull,
    reason:
        '`$knob` on the showcase page is no longer a numeric literal '
        '("${pageKnob(knobs, knob)}"), so the knob guard cannot compare it.',
  );
  return value!;
}

/// [knob] as an int.
int pageInt(Map<String, String> knobs, String knob) {
  final value = int.tryParse(pageKnob(knobs, knob));
  expect(
    value,
    isNotNull,
    reason:
        '`$knob` on the showcase page is no longer an integer literal '
        '("${pageKnob(knobs, knob)}"), so the knob guard cannot compare it.',
  );
  return value!;
}

/// [knob] as a bool.
bool pageBool(Map<String, String> knobs, String knob) {
  final value = pageKnob(knobs, knob);
  expect(
    value,
    anyOf(equals('true'), equals('false')),
    reason:
        '`$knob` on the showcase page is no longer a boolean literal, so the '
        'knob guard cannot compare it.',
  );
  return value == 'true';
}

/// [knob] as a bool, additionally resolving the page's
/// `presentation == _PolarPresentation.x` form against [presentation].
///
/// The three reference-geometry flags are switched on in the shared prelude by
/// comparing the presentation rather than by a literal, and each is then
/// re-asserted as `true` in the case that owns it. Reading only the literal
/// form would leave the guard unable to resolve them for the other six.
bool pagePresentationFlag(
  Map<String, String> knobs,
  String knob,
  String presentation,
) {
  final value = pageKnob(knobs, knob);
  if (value == 'true' || value == 'false') return value == 'true';
  final match = RegExp(
    r'^presentation == _PolarPresentation\.([A-Za-z0-9_]+)$',
  ).firstMatch(value);
  expect(
    match,
    isNotNull,
    reason:
        '`$knob` on the showcase page is neither a boolean literal nor a '
        'comparison against one presentation ("$value"), so the knob guard '
        'cannot resolve whether this presentation authors it.',
  );
  return match!.group(1) == presentation;
}

/// [knob] as a `Color`, or null where the page leaves it unset.
Color? pageColor(Map<String, String> knobs, String knob) {
  final value = pageKnob(knobs, knob);
  if (value == 'null') return null;
  final match = RegExp(r'^Color\(0x([0-9A-Fa-f]{8})\)$').firstMatch(value);
  expect(
    match,
    isNotNull,
    reason:
        '`$knob` on the showcase page is no longer a `Color(0x…)` literal '
        '("$value"), so the knob guard cannot compare it.',
  );
  return Color(int.parse(match!.group(1)!, radix: 16));
}

/// [knob] as a `Color` the page authors EXPLICITLY.
///
/// The page reads several colours through a `_effective…` getter that falls
/// back to the live theme. Those getters are outside what this guard can
/// resolve, so a knob that went null would silently compare a transcribed
/// literal against a theme colour; this refuses instead.
Color pageAuthoredColor(Map<String, String> knobs, String knob) {
  final value = pageColor(knobs, knob);
  expect(
    value,
    isNotNull,
    reason:
        'the showcase page no longer authors `$knob` for this presentation, so '
        'the chart now takes that colour from the live theme. The acceptance '
        'case still mounts a literal, which is drift the moment the theme '
        'moves.',
  );
  return value!;
}

/// [knob] as a qualified enum-ish token, e.g. `FontWeight.w500`.
///
/// Compared against the mounted value's `toString()`, which is that same text
/// for both Dart enums and `FontWeight`.
String pageToken(Map<String, String> knobs, String knob) {
  final value = pageKnob(knobs, knob);
  expect(
    value,
    matches(r'^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z0-9_]+$'),
    reason:
        '`$knob` on the showcase page is no longer a `Type.value` token '
        '("$value"), so the knob guard cannot compare it.',
  );
  return value;
}

/// The dash pattern `_PolarLinePattern.[name]` carries on the page.
List<double> pageLinePattern(String source, String name) {
  final header = '$name(';
  final enumStart = source.indexOf('enum _PolarLinePattern {');
  expect(
    enumStart,
    isNonNegative,
    reason: 'no `_PolarLinePattern` on the page',
  );
  final start = source.indexOf(header, enumStart);
  expect(start, isNonNegative, reason: 'no `_PolarLinePattern.$name` value');
  final open = source.indexOf('<double>[', start);
  final close = source.indexOf(']', open);
  expect(
    open,
    isNonNegative,
    reason: 'no pattern on `_PolarLinePattern.$name`',
  );
  return <double>[
    for (final match in RegExp(
      r'-?\d+(?:\.\d+)?',
    ).allMatches(source.substring(open + '<double>['.length, close)))
      double.parse(match.group(0)!),
  ];
}

/// Why a knob mismatch matters, said once.
String knobReason(String presentation, String knob) =>
    'the "$presentation" acceptance case mounts a different `$knob` than the '
    'showcase page authors for that presentation, so the gate is proving '
    'emission for a chart the page does not build. Re-transcribe the case from '
    'the page (or fix the page, if the case is the correct one) — do not relax '
    'this comparison.';

/// Asserts the chart just mounted for [presentation] carries the knob values
/// `polar_column_page.dart` itself authors for it.
///
/// This is the half of the sync guard that covers the acceptance cases'
/// LITERALS. It reads the page's source, resolves that presentation's knobs,
/// and compares them to the live `PolarChartConfig` and `PolarColumnStyle` in
/// the widget tree — so the only way to pass is for the case's hand copy to
/// still say what the page says.
void expectShowcaseKnobsMatchPage(WidgetTester tester, String presentation) {
  final page = readRepoFile(showcasePolarPagePath);
  final knobs = showcaseAuthoredKnobs(page, presentation);
  final chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
  final config = chart.polarChartConfig;
  final seriesList = chart.series ?? const <ChartSeries>[];
  expect(
    seriesList,
    isNotEmpty,
    reason: 'the "$presentation" acceptance case mounted no series',
  );
  // The page builds ONE `PolarColumnStyle` and one `RadialSelectionStyle` and
  // hands the same instance to every series it returns, with a single
  // exception: `layered`'s reference layer takes a `copyWith`. That copy is the
  // FIRST series there, so the LAST series carries the shared style in all
  // eight presentations.
  final series = seriesList.last as PolarColumnChartSeries;
  final style = series.polarStyle;
  final selection = series.selectionStyle;

  for (final (knob, mounted) in <(String, double)>[
    ('_startAngle', config.pane.startAngleDegrees),
    ('_sweepAngle', config.pane.sweepAngleDegrees),
    ('_innerRadius', config.pane.innerRadiusFactor),
    ('_outerRadius', config.pane.outerRadiusFactor),
    ('_innerPadding', config.angularAxis.innerPadding),
    ('_outerPadding', config.angularAxis.outerPadding),
    ('_categoryLabelOffset', config.angularAxis.labelOffset),
    ('_categoryLabelSize', config.angularAxis.labelStyle.fontSize ?? -1),
    ('_radialLabelOffset', config.radialAxis.labelOffset),
    ('_radialLabelAngleOffset', config.radialAxis.labelAngleOffsetDegrees),
    ('_radialLabelSize', config.radialAxis.labelStyle.fontSize ?? -1),
    ('_groupInnerPadding', config.composition.groupInnerPadding),
    ('_cornerRadius', style.cornerRadius),
    ('_opacity', style.opacity),
    ('_columnBorderWidth', style.borderWidth),
    ('_valueLabelRadialPosition', style.dataLabelRadialPosition),
    ('_valueLabelSize', style.dataLabelStyle.fontSize ?? -1),
    ('_selectionScale', selection.liftScale),
    ('_selectionOffset', selection.liftOffset),
    ('_selectionBackdropBlur', selection.backdropBlur),
  ]) {
    expect(
      mounted,
      pageDouble(knobs, knob),
      reason: knobReason(presentation, knob),
    );
  }

  for (final (knob, mounted) in <(String, int)>[
    ('_maximumAngularLabels', config.angularAxis.maximumVisibleLabels),
    ('_maximumAngularGridLines', config.angularAxis.maximumVisibleGridLines),
    ('_tickCount', config.radialAxis.tickCount),
    ('_maximumDataLabels', style.maximumVisibleDataLabels),
  ]) {
    expect(
      mounted,
      pageInt(knobs, knob),
      reason: knobReason(presentation, knob),
    );
  }

  for (final (knob, mounted) in <(String, bool)>[
    ('_clockwise', config.pane.clockwise),
    ('_showAngularLabels', config.angularAxis.showLabels),
    ('_showAngularGrid', config.angularAxis.showGridLines),
    ('_showRadialLabels', config.radialAxis.showLabels),
    ('_showRadialGrid', config.radialAxis.showGridLines),
    ('_showValues', style.showDataLabels),
  ]) {
    expect(
      mounted,
      pageBool(knobs, knob),
      reason: knobReason(presentation, knob),
    );
  }

  for (final (knob, mounted) in <(String, Object)>[
    ('_scaleMode', config.radialAxis.scaleMode as Object),
    ('_radialLabelPosition', config.radialAxis.labelPosition),
    ('_compositionMode', config.composition.mode),
    ('_animationMode', style.animationMode),
    ('_selectionEffect', selection.effect),
    (
      '_categoryLabelWeight',
      config.angularAxis.labelStyle.fontWeight as Object,
    ),
    ('_radialLabelWeight', config.radialAxis.labelStyle.fontWeight as Object),
    ('_valueLabelWeight', style.dataLabelStyle.fontWeight as Object),
  ]) {
    expect(
      mounted.toString(),
      pageToken(knobs, knob),
      reason: knobReason(presentation, knob),
    );
  }

  for (final (knob, mounted) in <(String, Color?)>[
    ('_categoryLabelColor', config.angularAxis.labelStyle.color),
    ('_radialLabelColor', config.radialAxis.labelStyle.color),
    ('_valueLabelColor', style.dataLabelStyle.color),
  ]) {
    expect(
      mounted,
      pageColor(knobs, knob),
      reason: knobReason(presentation, knob),
    );
  }
  expect(
    style.borderColor,
    pageAuthoredColor(knobs, '_columnBorderColor'),
    reason: knobReason(presentation, '_columnBorderColor'),
  );

  // `_cornerRadiusMode` is the one knob the page COMPUTES rather than assigns
  // per case, so the guard pins the RULE and derives the expected mode from it
  // — otherwise a rewritten rule would silently stop being what the eight
  // acceptance cases assume.
  expect(
    pageKnob(knobs, '_cornerRadiusMode'),
    'presentation == _PolarPresentation.stacked '
    '? PolarColumnCornerRadiusMode.stackExterior '
    ': PolarColumnCornerRadiusMode.outerEnd',
    reason:
        'the showcase page no longer derives `_cornerRadiusMode` from the '
        'stacked presentation alone, so the acceptance cases\' transcribed '
        'corner-radius modes are no longer what the page builds.',
  );
  expect(
    style.cornerRadiusMode,
    presentation == 'stacked'
        ? PolarColumnCornerRadiusMode.stackExterior
        : PolarColumnCornerRadiusMode.outerEnd,
    reason: knobReason(presentation, '_cornerRadiusMode'),
  );

  final showGradient = pageBool(knobs, '_showGradient');
  expect(
    style.gradient != null,
    showGradient,
    reason: knobReason(presentation, '_showGradient'),
  );
  if (style.gradient case final gradient?) {
    expect(
      gradient.startColor,
      pageColor(knobs, '_gradientStartColor'),
      reason: knobReason(presentation, '_gradientStartColor'),
    );
    expect(
      gradient.endColor,
      pageColor(knobs, '_gradientEndColor'),
      reason: knobReason(presentation, '_gradientEndColor'),
    );
    expect(
      gradient.startLightnessShift,
      pageDouble(knobs, '_gradientStartLightness'),
      reason: knobReason(presentation, '_gradientStartLightness'),
    );
    expect(
      gradient.endLightnessShift,
      pageDouble(knobs, '_gradientEndLightness'),
      reason: knobReason(presentation, '_gradientEndLightness'),
    );
  }

  final showShadow = pageBool(knobs, '_showColumnShadow');
  expect(
    style.shadow != const PolarColumnShadowStyle(),
    showShadow,
    reason: knobReason(presentation, '_showColumnShadow'),
  );
  if (showShadow) {
    expect(
      style.shadow.color,
      pageColor(knobs, '_columnShadowColor'),
      reason: knobReason(presentation, '_columnShadowColor'),
    );
    expect(
      style.shadow.blurRadius,
      pageDouble(knobs, '_columnShadowBlur'),
      reason: knobReason(presentation, '_columnShadowBlur'),
    );
    expect(
      style.shadow.spreadRadius,
      pageDouble(knobs, '_columnShadowSpread'),
      reason: knobReason(presentation, '_columnShadowSpread'),
    );
    expect(
      style.shadow.offset,
      Offset(
        pageDouble(knobs, '_columnShadowOffsetX'),
        pageDouble(knobs, '_columnShadowOffsetY'),
      ),
      reason: knobReason(presentation, '_columnShadowOffsetY'),
    );
    expect(
      style.shadow.opacity,
      pageDouble(knobs, '_columnShadowOpacity'),
      reason: knobReason(presentation, '_columnShadowOpacity'),
    );
  }

  // The two presentations that author reference geometry. Their marker and
  // threshold literals are transcribed exactly like the rest, so they are held
  // to the page exactly like the rest.
  if (pagePresentationFlag(knobs, '_showThreshold', presentation)) {
    expect(
      config.thresholds.length,
      1,
      reason: knobReason(presentation, '_showThreshold'),
    );
    final threshold = config.thresholds.single;
    expect(
      threshold.value,
      pageDouble(knobs, '_thresholdValue'),
      reason: knobReason(presentation, '_thresholdValue'),
    );
    expect(
      threshold.width,
      pageDouble(knobs, '_thresholdWidth'),
      reason: knobReason(presentation, '_thresholdWidth'),
    );
    expect(
      threshold.color,
      pageAuthoredColor(knobs, '_thresholdColor'),
      reason: knobReason(presentation, '_thresholdColor'),
    );
    expect(
      threshold.dashPattern,
      pageLinePattern(
        page,
        pageToken(knobs, '_thresholdPattern').split('.').last,
      ),
      reason: knobReason(presentation, '_thresholdPattern'),
    );
  } else {
    expect(
      config.thresholds,
      isEmpty,
      reason: knobReason(presentation, '_showThreshold'),
    );
  }
  if (pagePresentationFlag(knobs, '_showTargets', presentation)) {
    expect(
      series.targetMarkerStyle.color,
      pageAuthoredColor(knobs, '_targetColor'),
      reason: knobReason(presentation, '_targetColor'),
    );
    expect(
      series.targetMarkerStyle.width,
      pageDouble(knobs, '_targetMarkerWidth'),
      reason: knobReason(presentation, '_targetMarkerWidth'),
    );
    expect(
      series.targetMarkerStyle.lengthFactor,
      pageDouble(knobs, '_targetMarkerLength'),
      reason: knobReason(presentation, '_targetMarkerLength'),
    );
    expect(
      series.targetMarkerStyle.opacity,
      pageDouble(knobs, '_targetOpacity'),
      reason: knobReason(presentation, '_targetOpacity'),
    );
  }
  if (pagePresentationFlag(knobs, '_showIntervals', presentation)) {
    expect(
      series.intervalStyle.display.toString(),
      pageToken(knobs, '_intervalDisplay'),
      reason: knobReason(presentation, '_intervalDisplay'),
    );
    expect(
      series.intervalStyle.color,
      pageAuthoredColor(knobs, '_intervalColor'),
      reason: knobReason(presentation, '_intervalColor'),
    );
    expect(
      series.intervalStyle.width,
      pageDouble(knobs, '_intervalWidth'),
      reason: knobReason(presentation, '_intervalWidth'),
    );
    expect(
      series.intervalStyle.capLengthFactor,
      pageDouble(knobs, '_intervalCapLength'),
      reason: knobReason(presentation, '_intervalCapLength'),
    );
    expect(
      series.intervalStyle.bandLengthFactor,
      pageDouble(knobs, '_intervalBandLength'),
      reason: knobReason(presentation, '_intervalBandLength'),
    );
    expect(
      series.intervalStyle.opacity,
      pageDouble(knobs, '_intervalOpacity'),
      reason: knobReason(presentation, '_intervalOpacity'),
    );
  }
}

/// The eight `_PolarPresentation` values, in the page's declaration order, that
/// the acceptance gate below covers one `testWidgets` each.
///
/// This list is the join between the page and the gate: the guard asserts the
/// page's enum equals it, and that each name appears as an acceptance case's
/// `presentation:` label. A ninth presentation therefore cannot be added
/// without either extending this list AND writing its case, or going red.
const showcasePolarPresentations = <String>[
  'standard',
  'rose',
  'partial',
  'layered',
  'grouped',
  'stacked',
  'references',
  'intervals',
];

/// Every `<String, num>` map the page declares, against its transcription here.
const showcaseTranscribedValueMaps = <String, Map<String, num>>{
  '_standardValues': showcaseStandardValues,
  '_roseValues': showcaseRoseValues,
  '_partialValues': showcasePartialValues,
  '_layeredObservedValues': showcaseLayeredObservedValues,
  '_layeredCapacityValues': showcaseLayeredCapacityValues,
  '_groupedNorthValues': showcaseGroupedNorthValues,
  '_groupedSouthValues': showcaseGroupedSouthValues,
  '_groupedWestValues': showcaseGroupedWestValues,
  '_stackedNewValues': showcaseStackedNewValues,
  '_stackedExpansionValues': showcaseStackedExpansionValues,
  '_stackedChurnValues': showcaseStackedChurnValues,
  '_referenceActualValues': showcaseReferenceActualValues,
  '_referenceTargetValues': showcaseReferenceTargetValues,
  '_uncertaintyValues': showcaseUncertaintyValues,
  '_uncertaintyLowerValues': showcaseUncertaintyLowerValues,
  '_uncertaintyUpperValues': showcaseUncertaintyUpperValues,
};

/// The three `_PolarPalette` swatches the acceptance cases author through.
///
/// `theme` is generated from the live `ChartTheme` (transcribed as
/// [showcaseThemePalette], not a literal) and `monochrome` is not reached by
/// any authored presentation, so neither has a literal to compare.
const showcaseTranscribedPalettes = <String, List<Color>>{
  'ocean': showcaseOceanPalette,
  'sunset': showcaseSunsetPalette,
  'earth': showcaseEarthPalette,
};

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

/// [snapshotOf]'s sibling for charts that carry a LIVE callback.
///
/// `extractDocument` is the PORTABLE path and fails closed on a runtime
/// formatter it has no descriptor for; `extractSourceDocument` is the path the
/// workbench's Source pane actually calls, and represents the same callback
/// with a stable placeholder descriptor. A chart whose centre or labels are
/// formatted can therefore only be generated from the latter — which is what
/// the Grammar pane does for it.
Future<ChartDocumentSnapshot> sourceSnapshotOf(
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
  final result = controller.extractSourceDocument();
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

/// Asserts one showcase chart reaches the Grammar pane as a real, COMPILING
/// chain.
///
/// The acceptance question for this slice is not "does some polar chart emit"
/// but "does the chart the showcase page actually mounts emit", so this mounts
/// the chart and asserts on the generator's own verdict: a chain was written,
/// nothing was blocked, and [ChartGeneratedSource.isComplete] is true.
///
/// The "the showcase page actually mounts" half of that question is not free —
/// every caller's config and style literals are a hand copy of
/// `polar_column_page.dart`. So for the eight polar presentations this first
/// runs [expectShowcaseKnobsMatchPage], which resolves that presentation's
/// knobs out of the page's own source and compares them to the widget in the
/// tree. Without it a case could emit a flawless chain for a chart the page
/// stopped building, which is the one thing this gate must not do.
///
/// The generator's internal proof carries part of the fidelity question and it
/// is worth being exact about which part. It re-lowers the chain it is about to
/// write, so the PLAN and the re-lowered SERIES are proven: a channel the mark
/// fails to carry diverges and is refused. It does NOT prove the emitted CONFIG
/// LITERALS — `PlotSpec.polar` and `DonutMark.concentric` are handed to the
/// proof spec as the captured instances and lowering hands them back unchanged,
/// so that comparison is an instance against itself. Nor does the proof read a
/// character of the emitter's OUTPUT at all: a chain that names a parameter the
/// builder does not have, or drops a closing paren, would still pass it.
///
/// So this harness supplies the two things the proof does not. [fragments] are
/// the per-field assertions on the emitted TEXT — the only check that the
/// config literals say what the chart says — and every caller is expected to
/// pass the fields its presentation exercises. Then the emitted source goes
/// through the same `dart format` + `dart analyze` gate [expectRoundTrip] uses.
/// (The third guard on the literals lives outside this file: they are rendered
/// by the config emitter's own shared seams, and `test/meta/source_emitter_drift_test.dart`
/// fails on any field neither source form renders.)
///
/// What this does NOT do is [expectRoundTrip]'s rebuild step — see the group's
/// own header for why.
Future<ChartGeneratedSource> expectShowcaseEmits(
  WidgetTester tester, {
  required String presentation,
  required Widget Function(BravenChartController) chart,
  Iterable<String> fragments = const <String>[],
}) async {
  final snapshot = await snapshotOf(tester, chart);
  // Before anything is asserted about the EMISSION, assert the thing that was
  // mounted is the thing the showcase mounts. Every polar case's config and
  // style literals are a hand copy of `polar_column_page.dart`, and an
  // acceptance gate that emits beautifully for a chart the page stopped
  // building proves nothing at all.
  if (showcasePolarPresentations.contains(presentation)) {
    expectShowcaseKnobsMatchPage(tester, presentation);
  }
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
  // Real subprocesses, so the same `runAsync` escape hatch `expectRoundTrip`
  // documents applies here.
  await tester.runAsync(
    () => expectGeneratedSourceCompiles(
      generated.source,
      fixtureName: 'grammar_showcase_${fixtureSlug(presentation)}',
    ),
  );
  return generated;
}

/// [text] reduced to a filesystem-safe scratch-file stem.
///
/// Presentation names are prose ("concentric donut", "a 240 degree sweep"), and
/// [expectGeneratedSourceCompiles] turns its `fixtureName` into a real path
/// under `.dart_tool/`.
String fixtureSlug(String text) =>
    text.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');

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
/// The literal is delimited by indentation: its closing paren sits at the same
/// column as the opening token, so a nested literal's deeper one cannot end it.
/// The closing comma is OPTIONAL because a chain verb — `.geomLine(` — closes
/// on a bare `)` so the next `.verb(` can follow, while a nested config literal
/// closes on `),`. Matching the paren alone reads both; it cannot end a literal
/// early, because every line inside one is indented further than its opening.
List<String> literalArguments(String source, String opening) {
  final start = source.indexOf(opening);
  expect(start, isNonNegative, reason: 'missing "$opening" in:\n$source');
  final indent = start - (source.lastIndexOf('\n', start) + 1);
  final bodyStart = source.indexOf('\n', start) + 1;
  final end = source.indexOf('\n${' ' * indent})', start);
  expect(end, isNonNegative, reason: 'unterminated "$opening" in:\n$source');
  return <String>[
    for (final line in source.substring(bodyStart, end).split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

void main() {
  group('round trip', () {
    testWidgets('shape 1: a single line', (tester) async {
      // The twin declares the axis but does NOT bind the mark to it, because
      // that is what the emitter writes: a chart with one axis and no explicit
      // binding is mounted as the legacy single-axis chart, so its captured
      // series carries no `yAxisId` for `_planGeometry` to reverse. Binding it
      // here would mount the multi-axis shape instead and the rebuilt document
      // would differ by `series[*].axisId` plus `inlineAxis`.
      final generated = await expectRoundTrip(
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
            )
            .build(bravenChartController: controller),
      );
      // The proof never reads the emitted text, and the twin above is
      // HAND-WRITTEN — so nothing else in this test notices if the emitter
      // starts writing `yAxisId:` again. It would still compile, still
      // round-trip against the hand-written twin, and still hand a reader a
      // chain that mounts a different document from the chart they copied it
      // from. This assertion is the only thing that catches that.
      expect(generated.source, isNot(contains('yAxisId')));
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
            )
            .geomLine(
              id: 'mark-1',
              y: (row) => row.heartRate,
              name: 'Heart rate',
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            )
            .geomLine(
              id: 'mark-1',
              y: (row) => row.heartRate,
              name: 'Heart rate',
              showDataPointMarkers: true,
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
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 29: a Cartesian series unit round-trips AND is emitted', (
      tester,
    ) async {
      // `unit` is a SeriesMark field the five Cartesian families now carry, so
      // a chart that sets one must come back carrying it. The `fragments` half
      // is the load-bearing half: the generator's internal proof re-lowers the
      // reconstructed spec and never reads a CHARACTER of the emitted text (see
      // `_firstMismatch`'s doc), so a missing writer line would ship a chain
      // that silently drops the unit while the proof still passed.
      await expectRoundTrip(
        tester,
        name: 'series_unit',
        fragments: <String>["unit: 'W'", "unit: 'bpm'"],
        original: (controller) => BravenChart.of(rows)
            .x(sampleT, label: 'Elapsed')
            .y(samplePower, label: 'Power')
            .geomArea(name: 'Power', unit: 'W')
            .geomLine(y: sampleHeartRate, name: 'Heart rate', unit: 'bpm')
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
            .geomArea(
              id: 'mark-0',
              y: (row) => row.power,
              name: 'Power',
              unit: 'W',
            )
            .geomLine(
              id: 'mark-1',
              y: (row) => row.heartRate,
              name: 'Heart rate',
              unit: 'bpm',
            )
            .build(bravenChartController: controller),
      );
    });

    testWidgets('shape 29b: EVERY Cartesian family emits its unit', (
      tester,
    ) async {
      // The reversal is five separate `unit: series.unit` lines in
      // `_planGeometry`, one per family, so a family missed there is a family
      // that silently drops the unit. Each family is generated on its own and
      // its EMITTED TEXT asserted — the proof would catch a missing plan line,
      // but nothing except this assertion catches a missing writer line.
      //
      // The text assertion is scoped to the family's own geom call rather than
      // to the whole source: `unit:` is a `YAxisConfig` field too, so a bare
      // `contains("unit: 'W'")` would be satisfied by an AXIS unit that says
      // nothing about the mark. And because a text match cannot tell a real
      // parameter from an invented one, each of the three families
      // `expectRoundTrip` does not already compile (shape 29 covers area and
      // line) goes through the same `dart format` + `dart analyze` floor the
      // file's other harnesses use.
      final charts = <String, Widget Function(BravenChartController)>{
        'geomLine': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomLine(y: samplePower, unit: 'W', yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomArea': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomArea(y: samplePower, unit: 'W', yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomBar': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomBar(y: samplePower, unit: 'W', yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomPoint': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomPoint(y: samplePower, unit: 'W', yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomCandlestick': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomCandlestick(
              open: sampleOpen,
              high: sampleHigh,
              low: sampleLow,
              close: sampleClose,
              unit: 'W',
              yAxisId: 'axis-0',
            )
            .build(bravenChartController: controller),
      };
      final emitted = <String, bool>{};
      final blocked = <String, String?>{};
      final clean = <String, bool>{};
      final complete = <String, bool>{};
      final sources = <String, String>{};
      for (final entry in charts.entries) {
        final generated = generateGrammar(
          await snapshotOf(tester, entry.value),
        );
        sources[entry.key] = generated.source;
        blocked[entry.key] = blockedReason(generated);
        clean[entry.key] = generated.warnings.isEmpty;
        complete[entry.key] = generated.isComplete;
        // The map key IS the emitted verb, so the unit is read out of that
        // family's own argument list — not found anywhere in the file.
        final opening = '.${entry.key}(';
        emitted[entry.key] =
            generated.source.contains(opening) &&
            literalArguments(generated.source, opening).contains("unit: 'W',");
      }
      // Compared as WHOLE MAPS so one missing family cannot hide behind an
      // earlier failure.
      expect(blocked, <String, String?>{
        for (final verb in charts.keys) verb: null,
      });
      expect(clean, <String, bool>{for (final verb in charts.keys) verb: true});
      expect(complete, <String, bool>{
        for (final verb in charts.keys) verb: true,
      });
      expect(emitted, <String, bool>{
        for (final verb in charts.keys) verb: true,
      });
      // `dart format` + `dart analyze` on the emitted chain, for the families
      // no round-trip shape compiles. A fragment match proves a parameter NAME
      // was written; only this proves the verb actually has it. Real
      // subprocesses, so the `runAsync` escape hatch applies.
      for (final verb in const <String>[
        'geomBar',
        'geomPoint',
        'geomCandlestick',
      ]) {
        await tester.runAsync(
          () => expectGeneratedSourceCompiles(
            sources[verb]!,
            fixtureName: 'grammar_unit_$verb',
          ),
        );
      }
    });

    testWidgets('shape 29c: a unit-less Cartesian series emits NO unit '
        'argument', (tester) async {
      // The control for the two above: `unit` is optional on the mark and on
      // the verb, so a chart that sets none must stay byte-identical to what it
      // emitted before this slice — no `unit:` argument in the geom call.
      //
      // The AXIS deliberately declares a unit while the mark declares none.
      // `unit:` is a `YAxisConfig` field as well as a mark field
      // (`chart_config_dart_emitter` writes it inside the axis literal), so a
      // whole-file `isNot(contains('unit:'))` is satisfiable — and breakable —
      // by text that says nothing about the field under test. This fixture
      // makes that token present on purpose, so the control can only pass by
      // reading the geom call itself.
      //
      // And it reads the WHOLE argument list rather than searching it for one
      // token: an extra argument, a dropped one, a changed value and a
      // reordering then all fail, which is the same bar shapes 24 and 25 hold
      // their unguarded literals to.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChart.of(rows)
              .x(sampleT)
              .yAxis(
                YAxisConfig.withId(
                  id: 'axis-0',
                  position: YAxisPosition.left,
                  unit: 'W',
                ),
              )
              .geomLine(y: samplePower, yAxisId: 'axis-0')
              .build(bravenChartController: controller),
        ),
      );
      expect(emittedChain(generated), isTrue);
      expect(
        generated.source,
        contains("unit: 'W',"),
        reason:
            'the axis unit must reach the source, or this control is '
            'vacuous and a whole-file token search would have passed it',
      );
      expect(literalArguments(generated.source, '.geomLine('), <String>[
        "id: 'mark-0',",
        'y: (row) => row.mark0,',
        'strokeWidth: 2.0,',
        'dashPattern: <double>[],',
        'interpolation: LineInterpolation.linear,',
        "yAxisId: 'axis-0',",
      ]);
    });

    testWidgets('shape 29d: a CONFIG-authored series carrying a unit is no '
        'longer refused for it', (tester) async {
      // The config direction, which is what item 1c' exists for: a chart
      // authored with `LineChartSeries(unit: 'W')` rather than through the
      // chain. It binds its axis explicitly on both sides — `yAxisId` plus the
      // inline `yAxisConfig`, the shape lowering itself produces — because the
      // LEGACY single-axis binding is Slice 2's job, and this test must isolate
      // what Slice 1 changes.
      final axis = YAxisConfig.withId(
        id: 'axis-0',
        position: YAxisPosition.left,
      );
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              LineChartSeries(
                id: 'power',
                unit: 'W',
                yAxisId: 'axis-0',
                yAxisConfig: axis,
                points: const <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 1),
                  ChartDataPoint(x: 1, y: 2),
                ],
              ),
            ],
          ),
        ),
      );
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      // Read out of the geom call, not out of the file: the same `unit:` token
      // is a `YAxisConfig` field, and this fixture emits an axis literal right
      // beside the mark.
      expect(
        literalArguments(generated.source, '.geomLine('),
        contains("unit: 'W',"),
      );
    });

    testWidgets('shape 30: per-point labels and keys round-trip AND are '
        'emitted', (tester) async {
      // The config direction again: a chart authored with `ChartDataPoint`s
      // that carry a `label` and a `pointKey`. Before this slice the captured
      // and re-lowered points differed, so the whole chart was refused with the
      // generic loss sentence.
      //
      // The emitted-text assertion below is the load-bearing half. The proof
      // re-lowers the reconstructed spec and never reads a CHARACTER of the
      // emitted chain, so a missing `label:`/`pointKey:` writer line would ship
      // a chain that silently drops per-point identity while every other
      // assertion here — including the rebuilt-document comparison, whose twin
      // is hand-written rather than compiled from this text — still passed.
      final generated = await expectRoundTrip(
        tester,
        name: 'point_label_and_key',
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              name: 'Power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 168, label: 'Warm-up', pointKey: 'p0'),
                ChartDataPoint(
                  x: 1,
                  y: 204,
                  label: 'Threshold',
                  pointKey: 'p1',
                ),
                ChartDataPoint(x: 2, y: 268, label: 'VO2', pointKey: 'p2'),
              ],
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(keyedRows)
            .x((row) => row.x)
            .yAxis(
              YAxisConfig.withId(
                id: 'y',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'power',
              y: (row) => row.power,
              name: 'Power',
              label: (row) => row.powerLabel,
              pointKey: (row) => row.powerPointKey,
            )
            .build(bravenChartController: controller),
      );
      // The WHOLE argument list of the geom call, not two fragments: a dropped
      // field, an extra field, a wrong accessor and a reordering then all fail.
      // Scoped to the call because `label:` is also an axis field and this
      // chart puts one on the axis right beside the mark.
      expect(literalArguments(generated.source, '.geomLine('), <String>[
        "id: 'power',",
        'y: (row) => row.power,',
        "name: 'Power',",
        'label: (row) => row.powerLabel,',
        'pointKey: (row) => row.powerPointKey,',
        'strokeWidth: 2.0,',
        'dashPattern: <double>[],',
        'interpolation: LineInterpolation.linear,',
      ]);
      // The row class has to carry both, or the accessors above name fields
      // that do not exist. (`expectRoundTrip` compiles the emitted source, so
      // this is belt and braces — but it names WHICH field went missing.)
      expect(generated.source, contains('final String powerLabel;'));
      expect(generated.source, contains('final String powerPointKey;'));
      expect(generated.source, contains("powerLabel: 'Warm-up',"));
      expect(generated.source, contains("powerPointKey: 'p0',"));
    });

    testWidgets('shape 30b: a series with no per-point text emits neither '
        'accessor', (tester) async {
      // The control for shape 30. Both accessors are optional, so a chart that
      // sets neither must emit exactly what it emitted before this slice — no
      // `label:` and no `pointKey:` in the geom call.
      //
      // The AXIS deliberately carries a label, because `label:` is a
      // `YAxisConfig` field too: a whole-file `isNot(contains('label:'))` would
      // be satisfiable by text that says nothing about the mark. Reading the
      // geom's own argument list is the only assertion that can fail for the
      // right reason.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
            series: const <ChartSeries>[
              LineChartSeries(
                id: 'power',
                name: 'Power',
                points: <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 168),
                  ChartDataPoint(x: 1, y: 204),
                ],
              ),
            ],
          ),
        ),
      );
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      expect(
        generated.source,
        contains("label: 'Power',"),
        reason:
            'the axis label must reach the source, or this control is vacuous '
            'and a whole-file token search would have passed it',
      );
      expect(literalArguments(generated.source, '.geomLine('), <String>[
        "id: 'power',",
        'y: (row) => row.power,',
        "name: 'Power',",
        'strokeWidth: 2.0,',
        'dashPattern: <double>[],',
        'interpolation: LineInterpolation.linear,',
      ]);
    });

    testWidgets('shape 30c: a PARTIALLY labelled series round-trips', (
      tester,
    ) async {
      // Per-point text travels through a NON-NULLABLE row slot, so a point
      // that had no label is written as `''` and has to come back as null.
      // Without the empty-string normalisation in lowering this chart cannot
      // round-trip at all — and a `pointKey` would not merely differ, it would
      // trip `ChartDataPoint`'s own assert.
      final generated = await expectRoundTrip(
        tester,
        name: 'point_label_partial',
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          yAxis: YAxisConfig(position: YAxisPosition.left),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              name: 'Power',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 168, label: 'Warm-up', pointKey: 'p0'),
                ChartDataPoint(x: 1, y: 204),
                ChartDataPoint(x: 2, y: 268, label: 'VO2', pointKey: 'p2'),
              ],
            ),
          ],
        ),
        rebuilt: (controller) =>
            BravenChart.of(<KeyedRow>[
                  const KeyedRow(
                    x: 0,
                    power: 168,
                    powerLabel: 'Warm-up',
                    powerPointKey: 'p0',
                  ),
                  const KeyedRow(x: 1, power: 204),
                  const KeyedRow(
                    x: 2,
                    power: 268,
                    powerLabel: 'VO2',
                    powerPointKey: 'p2',
                  ),
                ])
                .x((row) => row.x)
                .yAxis(
                  YAxisConfig.withId(id: 'y', position: YAxisPosition.left),
                )
                .geomLine(
                  id: 'power',
                  y: (row) => row.power,
                  name: 'Power',
                  label: (row) => row.powerLabel,
                  pointKey: (row) => row.powerPointKey,
                )
                .build(bravenChartController: controller),
      );
      // The unlabelled row is written as the empty literal, which is what the
      // normalisation on the other side has to read.
      expect(generated.source, contains("powerLabel: '',"));
      expect(generated.source, contains("powerPointKey: '',"));
    });

    testWidgets('shape 30d: colliding point keys are refused by NAME', (
      tester,
    ) async {
      // A `pointKey` is the stable selection identity, so a captured chart that
      // repeats one inside a series cannot be expressed as a chain that means
      // the same thing. The grammar's own `duplicatePointKey` diagnostic fires
      // while the proof re-lowers, and the generator quotes it — a named
      // boundary rather than the generic "does not reproduce exactly".
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            yAxis: YAxisConfig(position: YAxisPosition.left),
            series: const <ChartSeries>[
              LineChartSeries(
                id: 'power',
                name: 'Power',
                points: <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 168, pointKey: 'dup'),
                  ChartDataPoint(x: 1, y: 204, pointKey: 'dup'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isFalse);
      expect(blockedReason(generated), contains('dup'));
      expect(blockedReason(generated), contains('pointKey'));
    });

    testWidgets('shape 31: isXOrdered round-trips AND is emitted', (
      tester,
    ) async {
      // `isXOrdered` is a series-level data-shape hint that changes NEAREST-
      // POINT behaviour (see `chart_selection_expression.dart`), so a chart
      // that declares it must come back declaring it. It is carried
      // EXPLICITLY: the generator never infers it from the synthesised rows,
      // which are sorted here and would read as ordered if it did.
      //
      // The emitted-text assertion below is the load-bearing half. The proof
      // re-lowers the reconstructed spec and never reads a CHARACTER of the
      // emitted chain, so a missing writer line would ship a chain that
      // silently dropped the flag while the rebuilt-document comparison — whose
      // twin is hand-written rather than compiled from this text — still
      // passed.
      final generated = await expectRoundTrip(
        tester,
        name: 'series_is_x_ordered',
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              name: 'Power',
              isXOrdered: true,
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 168),
                ChartDataPoint(x: 1, y: 204),
                ChartDataPoint(x: 2, y: 268),
              ],
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x)
            .yAxis(
              YAxisConfig.withId(
                id: 'y',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(
              id: 'power',
              y: (row) => row.power,
              name: 'Power',
              isXOrdered: true,
            )
            .build(bravenChartController: controller),
      );
      // The WHOLE argument list of the geom call, not one fragment: a dropped
      // field, an extra field, a wrong value and a reordering then all fail.
      expect(literalArguments(generated.source, '.geomLine('), <String>[
        "id: 'power',",
        'y: (row) => row.power,',
        "name: 'Power',",
        'isXOrdered: true,',
        'strokeWidth: 2.0,',
        'dashPattern: <double>[],',
        'interpolation: LineInterpolation.linear,',
      ]);
    });

    testWidgets('shape 31b: EVERY family that carries isXOrdered emits it', (
      tester,
    ) async {
      // The emission is a single switch with one arm per carrying family, and
      // the reversal is one `isXOrdered: series.isXOrdered` per family in
      // `_planGeometry`. A family missed in either place is a family that
      // silently drops the flag, and shape 31 only compiles `geomLine`.
      //
      // Each flag is read out of that family's OWN argument list rather than
      // found anywhere in the file, and the three families no round-trip shape
      // compiles go through the same `dart format` + `dart analyze` floor —
      // a text match proves a parameter NAME was written, only the floor proves
      // the verb actually has it.
      final charts = <String, Widget Function(BravenChartController)>{
        'geomLine': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomLine(y: samplePower, isXOrdered: true, yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomArea': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomArea(y: samplePower, isXOrdered: true, yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomBar': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomBar(y: samplePower, isXOrdered: true, yAxisId: 'axis-0')
            .build(bravenChartController: controller),
        'geomPoint': (controller) => BravenChart.of(rows)
            .x(sampleT)
            .yAxis(
              YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left),
            )
            .geomPoint(y: samplePower, isXOrdered: true, yAxisId: 'axis-0')
            .build(bravenChartController: controller),
      };
      final emitted = <String, bool>{};
      final blocked = <String, String?>{};
      final clean = <String, bool>{};
      final complete = <String, bool>{};
      final sources = <String, String>{};
      for (final entry in charts.entries) {
        final generated = generateGrammar(
          await snapshotOf(tester, entry.value),
        );
        sources[entry.key] = generated.source;
        blocked[entry.key] = blockedReason(generated);
        clean[entry.key] = generated.warnings.isEmpty;
        complete[entry.key] = generated.isComplete;
        final opening = '.${entry.key}(';
        emitted[entry.key] =
            generated.source.contains(opening) &&
            literalArguments(
              generated.source,
              opening,
            ).contains('isXOrdered: true,');
      }
      // Compared as WHOLE MAPS so one missing family cannot hide behind an
      // earlier failure.
      expect(blocked, <String, String?>{
        for (final verb in charts.keys) verb: null,
      });
      expect(clean, <String, bool>{for (final verb in charts.keys) verb: true});
      expect(complete, <String, bool>{
        for (final verb in charts.keys) verb: true,
      });
      expect(emitted, <String, bool>{
        for (final verb in charts.keys) verb: true,
      });
      for (final verb in const <String>['geomArea', 'geomBar', 'geomPoint']) {
        await tester.runAsync(
          () => expectGeneratedSourceCompiles(
            sources[verb]!,
            fixtureName: 'grammar_is_x_ordered_$verb',
          ),
        );
      }
    });

    testWidgets('shape 31c: a chart at the false default emits NO isXOrdered '
        'argument', (tester) async {
      // The byte-identity control for the two above. `false` is the default on
      // the mark, the verb and `ChartSeries`, so a chart that declares nothing
      // must emit exactly what it emitted before this slice.
      //
      // Asserted twice, deliberately. The whole-argument-list expectation is
      // the precise one — an `isXOrdered: false,` written unconditionally fails
      // it. The whole-file expectation is the byte-identity claim itself: the
      // grammar form writes this token nowhere else (only the CONFIG source
      // form emits an `isXOrdered` on the series literal), so its complete
      // absence is exactly what "unchanged output" means here.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
            series: const <ChartSeries>[
              LineChartSeries(
                id: 'power',
                name: 'Power',
                points: <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 168),
                  ChartDataPoint(x: 1, y: 204),
                ],
              ),
            ],
          ),
        ),
      );
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      expect(literalArguments(generated.source, '.geomLine('), <String>[
        "id: 'power',",
        'y: (row) => row.power,',
        "name: 'Power',",
        'strokeWidth: 2.0,',
        'dashPattern: <double>[],',
        'interpolation: LineInterpolation.linear,',
      ]);
      expect(generated.source, isNot(contains('isXOrdered')));
    });

    testWidgets('shape 31d: a per-point segment style is refused with a NAMED '
        'reason', (tester) async {
      // `segmentStyle` is deliberately NOT carried. Measured: carrying it
      // unblocks zero states (the one censused chart using it still refuses on
      // a marker field behind it), it would need a new row-field kind — rows
      // have slots for numbers, strings, stamps and colours only — and it
      // collides with `LineMark.colorBy`, which already bakes
      // `segmentStyle.color` per point. So it gets an honest NAMED boundary
      // instead of the generic "does not reproduce exactly" tail.
      //
      // The axis is bound explicitly on both halves, as shape 29d is, so the
      // refusal cannot be attributed to the legacy single-axis binding.
      final axis = YAxisConfig.withId(
        id: 'axis-0',
        position: YAxisPosition.left,
      );
      LineChartSeries forecast({SegmentStyle? style}) => LineChartSeries(
        id: 'forecast',
        yAxisId: 'axis-0',
        yAxisConfig: axis,
        points: <ChartDataPoint>[
          const ChartDataPoint(x: 0, y: 1),
          ChartDataPoint(x: 1, y: 2, segmentStyle: style),
        ],
      );

      final styled = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              forecast(style: const SegmentStyle(dashPattern: <double>[2, 6])),
            ],
          ),
        ),
      );
      expect(emittedChain(styled), isFalse);
      expect(blockedReason(styled), contains('segment style'));

      // The control, and it is not decoration: without it the assertions above
      // would pass for a fixture refused for some unrelated reason, and the
      // reason string would be naming a boundary this chart never reached. The
      // SAME chart with the style removed must emit.
      final plain = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[forecast()],
          ),
        ),
      );
      expect(
        emittedChain(plain),
        isTrue,
        reason: 'blocked with: ${blockedReason(plain)}',
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            .geomLine(id: 'mark-0', y: (row) => row.power, name: 'Power')
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
            .geomPie(
              category: harvestFruit,
              value: harvestCount,
              name: 'Harvest',
            )
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

    testWidgets('a pie with PARTIAL per-slice colours emits and round-trips', (
      tester,
    ) async {
      // `PieChartSeries.fromMap` turns `sliceColors` into a per-point
      // `PointStyle(color:)`, which the emitter reverses onto a `sliceColor:`
      // row channel. Only two of the four categories carry an override, so the
      // uncoloured ones must come back as `null` rows and re-lower to points
      // with NO `pointStyle` at all — an invented colour would fail the
      // round-trip proof.
      final generated = await expectRoundTrip(
        tester,
        name: 'pie_slice_colours',
        fragments: <String>[
          '.geomPie(',
          'sliceColor: (row) => row.sliceColor,',
          'sliceColor: Color(0xFF2563EB),',
          'sliceColor: Color(0xFF0D9488),',
          'sliceColor: null,',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'pie-colours',
              name: 'Revenue',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              sliceColors: _harvestSliceColors,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(sliceColorGrammarRows)
            .geomPie(
              id: 'pie-colours',
              category: (row) => row.category,
              value: (row) => row.value,
              sliceColor: (row) => row.sliceColor,
              name: 'Revenue',
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
      // Exactly two categories are uncoloured, so exactly two rows write null.
      expect('sliceColor: null,'.allMatches(generated.source).length, 2);
    });

    testWidgets('a donut whose slices carry BOTH a colour and a variable '
        'radius emits and round-trips', (tester) async {
      // The pie/donut `fromMap` builds the GENERAL `PointStyle(color:, size:)`,
      // so the two channels share one point style and both must reverse
      // together. The radius reversal reads `.size` and the colour reversal
      // reads `.color`; if either clobbered the other the re-lowered point
      // style would diverge and the chain would be refused.
      final generated = await expectRoundTrip(
        tester,
        name: 'donut_slice_colours_and_radius',
        fragments: <String>[
          '.geomDonut(',
          'radius: (row) => row.radius,',
          'sliceColor: (row) => row.sliceColor,',
          'sliceRadiusConfig: PieSliceRadiusConfig(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-colours',
              name: 'Revenue',
              values: const <String, num>{
                'Apple': 42,
                'Pear': 31,
                'Plum': 17,
                'Fig': 10,
              },
              radiusValues: _harvestRadii,
              sliceColors: _harvestSliceColors,
              sliceRadiusConfig: showcaseRadius,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(sliceColorRadiusGrammarRows)
            .geomDonut(
              id: 'donut-colours',
              category: (row) => row.category,
              value: (row) => row.value,
              radius: (row) => row.radius,
              sliceColor: (row) => row.sliceColor,
              name: 'Revenue',
              sliceRadiusConfig: showcaseRadius,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a concentric composition colours the SAME category '
        'differently per ring and round-trips', (tester) async {
      // The discriminating shape. BOTH rings carry `Apple` and `Pear`, and
      // `Apple` is blue in Winter but red in Summer, while `Pear` is
      // uncoloured in Winter and teal in Summer. The reversal writes one row
      // per (ring, category) pair, so a lowering that resolved colours across
      // the WHOLE data set instead of per ring bucket collapses to one colour
      // per category and re-lowers Winter with Summer's palette — which the
      // round-trip proof refuses. A fixture whose categories are disjoint per
      // ring cannot tell the two apart, because `fromMap` ignores a
      // `sliceColors` key that is absent from `values`.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_slice_colours',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring,',
          'sliceColor: (row) => row.sliceColor,',
          'sliceColor: Color(0xFF2563EB),',
          'sliceColor: Color(0xFFDC2626),',
          'sliceColor: Color(0xFF0D9488),',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'seasons-Winter',
              name: 'Winter',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              sliceColors: _concentricSliceColors['Winter']!,
            ),
            DonutChartSeries.fromMap(
              id: 'seasons-Summer',
              name: 'Summer',
              values: const <String, num>{'Apple': 17, 'Pear': 10},
              sliceColors: _concentricSliceColors['Summer']!,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(concentricColorGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              sliceColor: (row) => row.sliceColor,
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a concentric composition whose rings carry DIFFERENT '
        'dataLabels emits dataLabelsByRing and round-trips', (tester) async {
      // THREE rings, three label configs. Ring 0 fixes the base the mark's
      // `dataLabels:` carries; the other two are projected into the override
      // map because they differ from it.
      //
      // The Inner ring is the discriminating one: its config is EXACTLY the
      // family default. Against a non-default base that is a real override, so
      // the map has to write it. The single `dataLabels:` renderer elides a
      // default config — correctly, because there "default" means "say
      // nothing" — and reusing that behaviour inside the map would re-lower
      // Inner with the base's `inside`/`padding: 10` labels, a different chart.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_labels_by_ring',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring,',
          'dataLabels: PieDataLabelConfig(',
          'position: PieDataLabelPosition.inside,',
          'padding: 10.0,',
          'dataLabelsByRing: {',
          "'Inner': PieDataLabelConfig(",
          "'Middle': PieDataLabelConfig(",
          'content: PieDataLabelContent.category,',
          'minimumShare: 0.2,',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'revenue-Outer',
              name: 'Outer',
              values: const <String, num>{'Subscriptions': 48, 'Services': 27},
              dataLabels: outerRingLabels,
            ),
            DonutChartSeries.fromMap(
              id: 'revenue-Middle',
              name: 'Middle',
              values: const <String, num>{'Subscriptions': 41, 'Services': 33},
              dataLabels: middleRingLabels,
            ),
            DonutChartSeries.fromMap(
              id: 'revenue-Inner',
              name: 'Inner',
              values: const <String, num>{'Subscriptions': 35, 'Services': 29},
              dataLabels: const PieDataLabelConfig(),
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(concentricLabelGrammarRows)
            .geomDonut(
              id: 'revenue',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              dataLabels: outerRingLabels,
              dataLabelsByRing: const <String, PieDataLabelConfig>{
                'Middle': middleRingLabels,
                'Inner': PieDataLabelConfig(),
              },
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
      // The BASE ring is not projected — it is already carried by `dataLabels:`,
      // and repeating it would be noise the round trip cannot tell apart.
      expect(generated.source, isNot(contains("'Outer': PieDataLabelConfig(")));
      // Keys are SORTED, so the emitted text does not depend on ring order.
      expect(
        generated.source.indexOf("'Inner': PieDataLabelConfig("),
        lessThan(generated.source.indexOf("'Middle': PieDataLabelConfig(")),
      );
    });

    testWidgets('a concentric composition whose rings SHARE one dataLabels '
        'emits no dataLabelsByRing at all', (tester) async {
      // BYTE-IDENTITY GUARD for the uniform case: projecting only the rings
      // that DIFFER from the base means a uniform composition allocates no
      // override map, and an empty map must stay null rather than emit
      // `dataLabelsByRing: {}`. Without this, every existing concentric chart's
      // emitted text would change.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            concentricDonutConfig: const ConcentricDonutConfig(),
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'revenue-Outer',
                name: 'Outer',
                values: const <String, num>{
                  'Subscriptions': 48,
                  'Services': 27,
                },
                dataLabels: outerRingLabels,
              ),
              DonutChartSeries.fromMap(
                id: 'revenue-Inner',
                name: 'Inner',
                values: const <String, num>{
                  'Subscriptions': 41,
                  'Services': 33,
                },
                dataLabels: outerRingLabels,
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isTrue);
      expect(generated.warnings, isEmpty);
      expect(generated.source, contains('dataLabels: PieDataLabelConfig('));
      expect(generated.source, isNot(contains('dataLabelsByRing')));
    });

    testWidgets('a per-ring label override carrying a FORMATTER emits a '
        'placeholder and a warning that names the ring', (tester) async {
      // The override map's own runtime-omission branch. The single `dataLabels:`
      // renderer reports against a series path; inside the map there is no one
      // series to point at — every ring of the composition shares the mark — so
      // the map form names the RING instead. Nothing asserted that until now,
      // which left a live branch of the seam unpinned.
      final snapshot = await sourceSnapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'revenue-Outer',
              name: 'Outer',
              values: const <String, num>{'Subscriptions': 48, 'Services': 27},
            ),
            DonutChartSeries.fromMap(
              id: 'revenue-Inner',
              name: 'Inner',
              values: const <String, num>{'Subscriptions': 41, 'Services': 33},
              dataLabels: PieDataLabelConfig(
                valueFormatter: (value) => '${value.toStringAsFixed(0)}u',
              ),
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      // Only the Inner ring differs from the base, so only it is projected —
      // and its entry carries the honest placeholder rather than a closure.
      expect(generated.source, contains('dataLabelsByRing: {'));
      expect(generated.source, contains("'Inner': PieDataLabelConfig("));
      expect(generated.source, contains('// valueFormatter:'));
      expect(generated.isComplete, isFalse);
      final warning = generated.warnings.singleWhere(
        (item) => item.code == ChartSourceWarningCodes.runtimeValueOmitted,
      );
      expect(
        warning.message,
        'Radial label formatter callbacks were omitted for ring "Inner". '
        'Provide them from your application.',
      );
      expect(warning.path, r'$.series[*].style.dataLabels');
      // A deliberately incomplete chain can never go through `expectRoundTrip`,
      // so its text is compiled here instead — the placeholder must still be
      // valid Dart.
      await tester.runAsync(
        () => expectGeneratedSourceCompiles(
          generated.source,
          fixtureName: 'grammar_source_concentric_formatted_ring_labels',
        ),
      );
    });

    testWidgets('the showcase concentric composition that used to be BLOCKER 3 '
        'now emits and round-trips', (tester) async {
      // CONVERTED from the pinned known-gap test
      // "blocker 3: rings with DIFFERENT dataLabels are refused — one DonutMark
      // carries one label config". That test asserted the REFUSAL of exactly
      // this chart; this slice closes the gap, so the same chart is asserted to
      // emit AND round-trip instead. The chart itself is unchanged from the
      // pinned version — same ids, names, unit, values and the same `hierarchy`
      // outer/inner label pair `concentric_donut_page.dart` builds — so the two
      // are directly comparable.
      //
      // The outer ring's config IS the family default here, so it fixes a
      // DEFAULT base that emits no `dataLabels:` at all and only the inner ring
      // is projected — the mirror image of the three-ring case above, where a
      // non-default base makes a default-valued ring the thing that must be
      // written.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_hierarchy_labels',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring,',
          'dataLabelsByRing: {',
          "'Previous period': PieDataLabelConfig(",
          'position: PieDataLabelPosition.inside,',
          'content: PieDataLabelContent.category,',
          "unit: 'USD'",
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'revenue-Current period',
              name: 'Current period',
              unit: 'USD',
              values: const <String, num>{'Subscriptions': 48, 'Services': 27},
              dataLabels: hierarchyOuterLabels,
            ),
            DonutChartSeries.fromMap(
              id: 'revenue-Previous period',
              name: 'Previous period',
              unit: 'USD',
              values: const <String, num>{'Subscriptions': 41, 'Services': 33},
              dataLabels: hierarchyInnerLabels,
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(hierarchyLabelGrammarRows)
            .geomDonut(
              id: 'revenue',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              unit: 'USD',
              dataLabelsByRing: const <String, PieDataLabelConfig>{
                'Previous period': hierarchyInnerLabels,
              },
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
      // The base ring IS the family default, so nothing carries it — neither a
      // `dataLabels:` argument nor an entry of its own.
      expect(
        generated.source,
        isNot(contains('dataLabels: PieDataLabelConfig')),
      );
      expect(
        generated.source,
        isNot(contains("'Current period': PieDataLabelConfig(")),
      );

      // CONTROL, kept verbatim in intent from the converted test: the same two
      // rings sharing ONE label config still emit, so what changed is the
      // handling of rings that DISAGREE — and a uniform composition emits no
      // `dataLabelsByRing` at all.
      final uniform = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'revenue-Current period',
                name: 'Current period',
                unit: 'USD',
                values: const <String, num>{
                  'Subscriptions': 48,
                  'Services': 27,
                },
                dataLabels: hierarchyOuterLabels,
              ),
              DonutChartSeries.fromMap(
                id: 'revenue-Previous period',
                name: 'Previous period',
                unit: 'USD',
                values: const <String, num>{
                  'Subscriptions': 41,
                  'Services': 33,
                },
                dataLabels: hierarchyOuterLabels,
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(uniform), isTrue);
      expect(uniform.warnings, isEmpty);
      expect(uniform.source, contains('ring: (row) => row.ring,'));
      expect(uniform.source, isNot(contains('dataLabelsByRing')));
    });

    testWidgets('the showcase donut that used to be BLOCKER 2 now emits and '
        'round-trips; without colours it emits no sliceColor at all', (
      tester,
    ) async {
      // CONVERTED from the pinned known-gap test
      // "blocker 2: per-slice colours are refused — both donut pages pass
      // sliceColors and no pie/donut mark carries them". That test asserted the
      // REFUSAL of exactly this chart; this slice closes the gap, so the same
      // chart is asserted to emit AND round-trip instead. The chart itself is
      // unchanged from the pinned version — same id, name, unit, values and
      // slice colours — so the two are directly comparable.
      final audienceRows = const <RadialColorRow>[
        RadialColorRow(
          category: 'Apple',
          value: 42,
          sliceColor: Color(0xFF2563EB),
        ),
        RadialColorRow(
          category: 'Pear',
          value: 31,
          sliceColor: Color(0xFF0D9488),
        ),
      ];
      final generated = await expectRoundTrip(
        tester,
        name: 'donut_showcase_slice_colours',
        fragments: <String>[
          '.geomDonut(',
          'sliceColor: (row) => row.sliceColor,',
          'sliceColor: Color(0xFF2563EB),',
          'sliceColor: Color(0xFF0D9488),',
          "unit: 'USD'",
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-audience',
              name: 'Audience',
              unit: 'USD',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              sliceColors: const <String, Color>{
                'Apple': Color(0xFF2563EB),
                'Pear': Color(0xFF0D9488),
              },
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(audienceRows)
            .geomDonut(
              id: 'donut-audience',
              category: (row) => row.category,
              value: (row) => row.value,
              sliceColor: (row) => row.sliceColor,
              name: 'Audience',
              unit: 'USD',
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);

      // BYTE-IDENTITY GUARD, kept from the converted test's CONTROL arm: the
      // same donut with NO slice colours must emit exactly what it emitted
      // before this slice — no field, no argument, no row column.
      final plain = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'donut-audience',
                name: 'Audience',
                unit: 'USD',
                values: const <String, num>{'Apple': 42, 'Pear': 31},
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(plain), isTrue);
      expect(plain.warnings, isEmpty);
      expect(plain.source, isNot(contains('sliceColor')));
      expect(plain.source, isNot(contains('Color(')));
    });

    testWidgets('the showcase donut centre that used to be BLOCKER 4 now '
        'emits and round-trips', (tester) async {
      // CONVERTED from the pinned known-gap test
      // "blocker 4: a STYLED donut centre is refused — _markCenter rebuilds the
      // centre and drops its two styles and its formatter". That test asserted
      // the REFUSAL of exactly this chart; this slice closes the gap, so the
      // same chart is asserted to emit AND round-trip instead. The chart itself
      // is unchanged from the pinned version — same id, name, unit, values and
      // the very same styled centre — so the two are directly comparable.
      const styled = DonutCenterContent(
        label: 'Total',
        labelStyle: LabelStyle(
          textStyle: TextStyle(color: Color(0xFF64748B), fontSize: 10),
          backgroundColor: Color(0x00000000),
          borderColor: Color(0x00000000),
          borderWidth: 0,
          borderRadius: 0,
          padding: EdgeInsets.zero,
        ),
      );
      final generated = await expectRoundTrip(
        tester,
        name: 'donut_showcase_styled_centre',
        fragments: <String>[
          '.geomDonut(',
          'center: DonutCenterContent(',
          "label: 'Total'",
          'labelStyle: LabelStyle(',
          'fontSize: 10.0',
          "unit: 'USD'",
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-audience',
              name: 'Audience',
              unit: 'USD',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              centerContent: styled,
            ),
          ],
        ),
        rebuilt: (controller) =>
            BravenChart.of(radialGrammarRows.take(2).toList())
                .geomDonut(
                  id: 'donut-audience',
                  category: (row) => row.category,
                  value: (row) => row.value,
                  name: 'Audience',
                  unit: 'USD',
                  center: styled,
                )
                .build(bravenChartController: controller),
      );
      // A style-only centre carries no live callback, so the chain stays
      // COMPLETE: the placeholder is the formatter's cost alone, not the
      // centre's.
      expect(generated.isComplete, isTrue);
      expect(generated.warnings, isEmpty);
    });

    testWidgets('the showcase concentric composition that used to be BLOCKER 1 '
        'now emits ringIds and round-trips', (tester) async {
      // CONVERTED from the pinned known-gap test
      // "blocker 1: ring ids that are not "<markId>-<ring>" are refused —
      // ConcentricDonutPage names its rings itself". That test asserted the
      // REFUSAL of exactly this chart; this slice closes the gap, so the same
      // chart is asserted to emit AND round-trip instead. The chart itself is
      // unchanged from the pinned version — the same slug ids ('current',
      // 'previous') decoupled from the ring names, the same names, unit, values
      // and the same non-default config — so the two are directly comparable.
      //
      // The ids ride the chain as an explicit `ringIds:` map instead of being
      // recovered from the id pattern, so nothing is renamed: the document the
      // rebuilt chain produces carries the author's own ids back.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_explicit_ring_ids',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring,',
          'ringIds: {',
          "'Current period': 'current',",
          "'Previous period': 'previous',",
          'concentric: ConcentricDonutConfig(',
          'innerRadiusFactor: 0.28,',
          "unit: 'USD'",
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(
            innerRadiusFactor: 0.28,
            outerRadiusFactor: 0.94,
            ringGap: 6,
          ),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'current',
              name: 'Current period',
              unit: 'USD',
              values: const <String, num>{'Subscriptions': 48, 'Services': 27},
            ),
            DonutChartSeries.fromMap(
              id: 'previous',
              name: 'Previous period',
              unit: 'USD',
              values: const <String, num>{'Subscriptions': 41, 'Services': 33},
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(hierarchyLabelGrammarRows)
            .geomDonut(
              id: 'donut',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              unit: 'USD',
              concentric: const ConcentricDonutConfig(
                innerRadiusFactor: 0.28,
                outerRadiusFactor: 0.94,
                ringGap: 6,
              ),
              ringIds: const <String, String>{
                'Current period': 'current',
                'Previous period': 'previous',
              },
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);

      // BYTE-IDENTITY GUARD, and the reason this channel is safe to add: the
      // emitter consults `ringIds` ONLY when the '<markId>-<ring>' pattern
      // fails to recover a markId. The SAME composition with conforming ids
      // therefore takes the original path and emits no `ringIds:` at all — so
      // every concentric chart that emitted before this slice emits exactly the
      // text it emitted before.
      final conforming = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            concentricDonutConfig: const ConcentricDonutConfig(
              innerRadiusFactor: 0.28,
              outerRadiusFactor: 0.94,
              ringGap: 6,
            ),
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'revenue-Current period',
                name: 'Current period',
                unit: 'USD',
                values: const <String, num>{
                  'Subscriptions': 48,
                  'Services': 27,
                },
              ),
              DonutChartSeries.fromMap(
                id: 'revenue-Previous period',
                name: 'Previous period',
                unit: 'USD',
                values: const <String, num>{
                  'Subscriptions': 41,
                  'Services': 33,
                },
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(conforming), isTrue);
      expect(conforming.warnings, isEmpty);
      expect(conforming.source, isNot(contains('ringIds')));
      expect(conforming.source, contains("id: 'revenue',"));
    });

    testWidgets('an explicit ringIds composition keys ringWeights by the '
        'AUTHORED id, and emits both', (tester) async {
      // The one-rule claim, asserted on emitted text: `ringWeights` is keyed by
      // the RESULTING series id, so a composition whose rings are named by
      // `ringIds` weights them by those same authored ids. If the reversal had
      // renamed the rings instead, this config would name no ring and the
      // re-lowering would be refused by `invalidConcentricComposition`.
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_explicit_ring_ids_weights',
        fragments: <String>[
          'ringIds: {',
          "'Current period': 'current',",
          "'current': 1.25,",
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(
            ringWeights: <String, double>{'current': 1.25},
          ),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'current',
              name: 'Current period',
              values: const <String, num>{'Subscriptions': 48, 'Services': 27},
            ),
            DonutChartSeries.fromMap(
              id: 'previous',
              name: 'Previous period',
              values: const <String, num>{'Subscriptions': 41, 'Services': 33},
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(hierarchyLabelGrammarRows)
            .geomDonut(
              id: 'donut',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              concentric: const ConcentricDonutConfig(
                ringWeights: <String, double>{'current': 1.25},
              ),
              ringIds: const <String, String>{
                'Current period': 'current',
                'Previous period': 'previous',
              },
            )
            .build(bravenChartController: controller),
      );
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a concentric composition whose rings are unnamed stays '
        'refused, by name', (tester) async {
      // `ringIds` is keyed by the RING KEY, and the ring key is the series
      // NAME — that is the channel `ring:` reads. A composition whose rings
      // carry no name has nothing to key by and no `ring:` accessor could
      // reproduce it (every row would bucket together), so it stays an honest
      // refusal rather than being renamed into one that emits.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            concentricDonutConfig: const ConcentricDonutConfig(),
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'current',
                values: const <String, num>{
                  'Subscriptions': 48,
                  'Services': 27,
                },
              ),
              DonutChartSeries.fromMap(
                id: 'previous',
                values: const <String, num>{
                  'Subscriptions': 41,
                  'Services': 33,
                },
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isFalse);
      expect(generated.isComplete, isFalse);
      expect(blockedReason(generated), contains('distinct, non-empty name'));
    });

    testWidgets('a donut with a STYLED, FORMATTED centre emits with the '
        'centre carried whole and an honest formatter placeholder', (
      tester,
    ) async {
      // `DonutChartsPage` builds its centre with `labelStyle`, `valueStyle` and
      // a live `valueFormatter` in EVERY knob state. The centre is carried onto
      // the mark VERBATIM, so all three survive the round-trip proof, and the
      // emitted `center:` is written by the config emitter's own centre
      // renderer — the same one `concentric:` uses — so the two forms cannot
      // disagree about a field. The formatter alone has no literal form and
      // degrades to a named placeholder, which is why the chain is emitted but
      // deliberately NOT complete.
      final snapshot = await sourceSnapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-centre',
              name: 'Audience',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              centerContent: DonutCenterContent(
                label: 'Total',
                valueMode: DonutCenterValueMode.total,
                labelStyle: donutCentreLabelStyle,
                valueStyle: donutCentreValueStyle,
                valueFormatter: (value) => value.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      expect(generated.source, contains('center: DonutCenterContent('));
      expect(generated.source, contains("label: 'Total'"));
      expect(generated.source, contains('labelStyle: LabelStyle('));
      expect(generated.source, contains('valueStyle: LabelStyle('));
      expect(generated.source, contains('// valueFormatter:'));
      expect(generated.isComplete, isFalse);
      // The warning must NAME THE SITE it is reporting, not merely carry the
      // right code. A plain donut's centre really does live on the series, so
      // the series-form path and message are the correct ones here — and
      // pinning them is what makes the concentric case below (whose centre
      // lives on the plot config, not on any series) a detectable mis-path
      // rather than an invisible one.
      final warning = generated.warnings.single;
      expect(warning.code, ChartSourceWarningCodes.runtimeValueOmitted);
      expect(
        warning.path,
        r'$.series[0].style.centerContent.valueFormatter',
        reason:
            'the omitted-formatter warning must point at the document location '
            'the formatter was captured from',
      );
      expect(
        warning.message,
        'A Donut center formatter callback was omitted. Provide it from your '
        'application.',
      );
      // The two source forms must report the SAME omission at the SAME place
      // for the same object — asked of the other form directly rather than
      // assumed from a shared constant.
      final configForm =
          ChartDartSourceGenerator.generate(snapshot)
              as ChartArtifactSuccess<ChartGeneratedSource>;
      final configWarning = configForm.value.warnings.singleWhere(
        (item) => item.code == ChartSourceWarningCodes.runtimeValueOmitted,
      );
      expect(configWarning.path, warning.path);
      expect(configWarning.message, warning.message);
      // The formatted chain cannot ROUND-TRIP by contract — the formatter has
      // no literal form — but it is the exact text `DonutChartsPage` ships, so
      // it must still parse and analyze. `expectRoundTrip` is the only other
      // harness that runs this gate, and a deliberately incomplete chain can
      // never go through it.
      await tester.runAsync(
        () => expectGeneratedSourceCompiles(
          generated.source,
          fixtureName: 'grammar_source_donut_formatted_centre',
        ),
      );
    });

    testWidgets('a concentric composition whose SHARED centre is styled emits '
        'center: instead of concentric: and round-trips', (tester) async {
      // The shape this slice MOVED, and the one piece of the centre carry that
      // had no test on either side of the `carriesConfig` branch. Before the
      // verbatim carry, a styled centre could not be rebuilt from four fields,
      // so `fromCenter != captured` and the whole `ConcentricDonutConfig` rode
      // the mark as `concentric:`. Now the centre survives intact, the
      // reconstruction matches, and the composition emits the SHORTHAND.
      //
      // Shape 28 pins the other half (a config customised beyond its centre
      // still emits `concentric:`); together they fix the branch in both
      // directions, so a later edit cannot silently flip either way.
      const styled = DonutCenterContent(
        label: 'Harvest',
        labelStyle: donutCentreLabelStyle,
        valueStyle: donutCentreValueStyle,
      );
      final generated = await expectRoundTrip(
        tester,
        name: 'concentric_styled_centre',
        fragments: <String>[
          '.geomDonut(',
          'ring: (row) => row.ring',
          'center: DonutCenterContent(',
          "label: 'Harvest'",
          'labelStyle: LabelStyle(',
          'valueStyle: LabelStyle(',
          'fontSize: 22.0',
        ],
        original: (controller) => BravenChart.of(harvest)
            .geomDonut(
              id: 'seasons',
              category: harvestFruit,
              value: harvestCount,
              ring: harvestSeason,
              concentric: const ConcentricDonutConfig(centerContent: styled),
            )
            .build(bravenChartController: controller),
        rebuilt: (controller) => BravenChart.of(concentricGrammarRows)
            .geomDonut(
              id: 'seasons',
              category: (row) => row.category,
              value: (row) => row.value,
              ring: (row) => row.ring,
              center: styled,
            )
            .build(bravenChartController: controller),
      );
      // The centre alone expresses the whole composition, so the config
      // literal must NOT also be written — lowering refuses a mark that sets
      // both, and the shorthand is what a reader should see.
      expect(
        generated.source,
        isNot(contains('concentric: ConcentricDonutConfig(')),
      );
      expect(generated.isComplete, isTrue);
      expect(generated.warnings, isEmpty);
    });

    testWidgets('a concentric composition\'s FORMATTED shared centre reports '
        'the omission at the concentric config, not at a series', (
      tester,
    ) async {
      // The centre a MULTI-RING composition carries comes from
      // `configuration.concentricDonut.centerContent` — no series owns it. The
      // captured document's `series[0].style.centerContent` here is the ring's
      // own HIDDEN centre with no formatter at all, so a warning pathed there
      // names a field that does not exist, and the config form reports the very
      // same object as "Concentric Donut". Both forms must agree.
      final snapshot = await sourceSnapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: ConcentricDonutConfig(
            centerContent: DonutCenterContent(
              label: 'Total',
              labelStyle: donutCentreLabelStyle,
              valueFormatter: (value) => value.toStringAsFixed(1),
            ),
          ),
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
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      expect(generated.source, contains('center: DonutCenterContent('));
      expect(generated.source, contains('// valueFormatter:'));
      expect(generated.isComplete, isFalse);

      // The captured document really does carry NO formatter on series[0] —
      // asserted, not assumed, so the path check below is anchored in the
      // document rather than in a belief about it.
      final seriesJson =
          (snapshot.document.toJson()['series']! as List<Object?>)[0]!
              as Map<String, Object?>;
      final centre =
          ((seriesJson['style'] as Map<String, Object?>?)?['centerContent']
              as Map<String, Object?>?) ??
          const <String, Object?>{};
      expect(centre.containsKey('valueFormatter'), isFalse);

      final warning = generated.warnings.single;
      expect(warning.code, ChartSourceWarningCodes.runtimeValueOmitted);
      expect(
        warning.path,
        r'$.configuration.concentricDonut.centerContent.valueFormatter',
        reason:
            'the shared centre lives on the concentric config, so the grammar '
            'form must report the omission where the config form does',
      );
      expect(
        warning.message,
        'A Concentric Donut center formatter callback was omitted. Provide it '
        'from your application.',
      );

      // And the claim the slice actually makes — that the two source forms
      // "cannot disagree about a centre's styles or its formatter" — is only
      // proven by asking the OTHER form the same question about the SAME
      // document. Comparing the two warnings, rather than re-transcribing a
      // path string, is what leaves nowhere for them to drift apart.
      final configForm =
          ChartDartSourceGenerator.generate(snapshot)
              as ChartArtifactSuccess<ChartGeneratedSource>;
      final configWarning = configForm.value.warnings.singleWhere(
        (item) => item.code == ChartSourceWarningCodes.runtimeValueOmitted,
      );
      expect(configWarning.path, warning.path);
      expect(configWarning.message, warning.message);
    });

    testWidgets('a DEFAULT donut centre still emits nothing at all', (
      tester,
    ) async {
      // The byte-identity guard for the centre carry. A plain donut restores
      // `DonutCenterContent.hidden`, so the mark must carry NO centre and the
      // chain must be exactly the text it was before the centre was carried
      // whole — no `center:` argument, no styles, no warning.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'donut-plain',
                name: 'Audience',
                values: const <String, num>{'Apple': 42, 'Pear': 31},
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isTrue);
      expect(generated.warnings, isEmpty);
      expect(generated.isComplete, isTrue);
      expect(generated.source, isNot(contains('center:')));
      expect(generated.source, isNot(contains('DonutCenterContent')));
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
  // SYNC GUARD (DECLARATIONS) — the acceptance gate's fixtures are a HAND
  // TRANSCRIPTION.
  //
  // Everything the gate below claims is a claim about the SHOWCASE, and it is
  // made through constants copied out of `polar_column_page.dart` by hand.
  // Nothing in the gate itself would notice the page changing underneath it:
  // add a ninth presentation, rename `references`, or edit a data map, and
  // eight green tests keep asserting about a page that no longer exists.
  //
  // This group covers the page's DECLARATIONS — its presentation enum, its
  // `<String, num>` maps and its palette swatches. It does NOT cover the
  // per-presentation knob values, which are not declarations but assignments
  // inside two switch statements; those are held to the page by
  // [expectShowcaseKnobsMatchPage], which runs inside every acceptance case
  // below. Read the two together: neither alone makes the gate honest, and an
  // earlier revision of this group claimed the whole job while enforcing only
  // this half.
  //
  // It is a TEXT parse, not an import: the page's declarations are all
  // library-private and the example is a separate package. That buys less than
  // an import would (it knows the page's syntax, not its behaviour), and it is
  // sufficient for the one job here — noticing that a copied constant stopped
  // matching its original.
  // =========================================================================

  group('showcase transcription sync guard', () {
    test('the page declares exactly the eight presentations the acceptance '
        'gate covers, in order', () {
      expect(
        enumValueNames(
          readRepoFile(showcasePolarPagePath),
          '_PolarPresentation',
        ),
        showcasePolarPresentations,
        reason:
            'the showcase page\'s `_PolarPresentation` no longer matches the '
            'presentations the acceptance gate below covers. A value was '
            'ADDED, REMOVED, RENAMED or REORDERED. The gate claims EVERY polar '
            'presentation emits, so restore the parity: add (or delete) the '
            'matching `testWidgets` case in "showcase acceptance", update '
            '`showcasePolarPresentations`, and transcribe its authored values '
            'into the fixtures above. Do NOT edit this expectation on its own '
            '— that is exactly the silent drift this test exists to catch.',
      );
    });

    test('every presentation has an acceptance case', () {
      final tests = readRepoFile(grammarGeneratorTestPath);
      for (final presentation in showcasePolarPresentations) {
        // Asserted on the BOOLEAN, not with `contains` on the file: a failed
        // string matcher prints the whole haystack, and the haystack here is
        // this file.
        expect(
          tests.contains("presentation: '$presentation',"),
          isTrue,
          reason:
              'no acceptance case passes `presentation: \'$presentation\'`, so '
              'the gate does not actually cover it. Naming a presentation in '
              '`showcasePolarPresentations` is not the same as testing it.',
        );
      }
    });

    test('every value map the page declares is transcribed, contents and key '
        'order', () {
      final page = readRepoFile(showcasePolarPagePath);
      expect(
        showcaseNumMapNames(page),
        showcaseTranscribedValueMaps.keys.toSet(),
        reason:
            'the showcase page gained or lost a `<String, num>` value map. An '
            'ADDED one is data no acceptance case mounts; a REMOVED one leaves '
            'a fixture above describing a chart the page no longer builds.',
      );
      for (final entry in showcaseTranscribedValueMaps.entries) {
        final authored = showcaseNumMap(page, entry.key);
        expect(
          authored,
          entry.value,
          reason:
              '`${entry.key}` on the showcase page no longer matches its '
              'transcription above, so the acceptance gate mounts different '
              'numbers than the page does.',
        );
        // Key ORDER as well as contents: `showcaseColumnColors` cycles the
        // palette over the map's key order, so a reordering repaints every
        // column while leaving the map "equal".
        expect(
          authored.keys,
          orderedEquals(entry.value.keys),
          reason:
              '`${entry.key}` still holds the same entries but in a different '
              'ORDER, which re-assigns every per-category column color.',
        );
      }
    });

    test('every palette swatch the acceptance cases author through is the '
        'page\'s own', () {
      final page = readRepoFile(showcasePolarPagePath);
      expect(
        enumValueNames(page, '_PolarPalette'),
        <String>['theme', 'ocean', 'sunset', 'earth', 'monochrome'],
        reason:
            'the showcase page\'s `_PolarPalette` changed. `theme` is generated '
            'from the live ChartTheme and `monochrome` is unreached by the '
            'authored presentations, but a rename or removal of any of these '
            'still invalidates the swatch transcriptions below.',
      );
      for (final entry in showcaseTranscribedPalettes.entries) {
        expect(
          showcasePaletteSwatch(page, entry.key),
          entry.value,
          reason:
              'the `_PolarPalette.${entry.key}` swatch on the showcase page no '
              'longer matches its transcription above, so the acceptance cases '
              'color their columns differently than the page does.',
        );
      }
    });
  });

  // =========================================================================
  // ACCEPTANCE GATE — every RADIAL workbench Grammar pane emits: polar 8/8,
  // pie, donut and concentric.
  //
  // The claim is now whole-family, but it is proven in two different places and
  // only one of them is this file. Read the split literally, because the two
  // halves buy different things:
  //
  //   * POLAR — all eight `_PolarPresentation` values, HERE. Each case is
  //     `polar_column_page.dart`'s own construction (`_buildSeriesList` for the
  //     series, `_buildPolarConfig` for the plot config) at that presentation's
  //     authored knob values, TRANSCRIBED into this file and held to the page
  //     by the two drift guards described below. It is NOT the mounted page:
  //     the package's tests cannot import the example package.
  //   * PIE, DONUT and CONCENTRIC — against the MOUNTED page, in
  //     `example/test/showcase/`: `pie_charts_page_grammar_test.dart`,
  //     `donut_charts_page_grammar_test.dart`,
  //     `concentric_donut_page_grammar_test.dart` and
  //     `selection_showcase_concentric_grammar_test.dart`. Each pumps the real
  //     page, reads the live document off the chart's OWN controller and runs
  //     the generator on it, so there is no fixture to drift. Pie and donut
  //     emit with `isComplete == false` — each carries a live formatter
  //     callback, which has no literal form — while the concentric page and the
  //     selection lab's concentric family emit COMPLETE, warning-free chains.
  //   * The CONCENTRIC case in THIS group is still NOT the showcase page. It is
  //     a non-default `ConcentricDonutConfig` authored the way the grammar's
  //     own concentric lowering produces one — a claim about the CONFIG
  //     PASSTHROUGH mechanism, which is why it stays here while the claim about
  //     `concentric_donut_page.dart` is made where it can be honest, against
  //     the mounted page.
  //
  // The unit tests above each isolate ONE mechanism (a config field, a channel,
  // a composition). This group asks the question the slice exists to answer:
  // does the chart the showcase page ACTUALLY AUTHORS reach the Grammar pane as
  // a real chain? Each polar case is `polar_column_page.dart`'s own construction
  // — `_buildSeriesList` for the series and `_buildPolarConfig` for the plot
  // config, at that presentation's authored knob values — so a regression that
  // only shows up on a real showcase chart fails here.
  //
  // Those values are a hand transcription, kept honest by two guards with
  // different reach. `group('showcase transcription sync guard')` above holds
  // the page's DECLARATIONS — the presentation enum, the data maps, the
  // palette swatches. [expectShowcaseKnobsMatchPage], which each case below
  // runs before it looks at any emitted text, holds the KNOBS: it resolves the
  // presentation's pane, axis, composition, column-style, selection, threshold,
  // target-marker and interval values out of the page's own two presentation
  // methods and compares them to the objects the case just mounted. What
  // remains a bare hand copy is listed at the fixtures above — chiefly which
  // data map feeds which series and channel, and the series ids, names and
  // units.
  //
  // Emission plus COMPILATION plus the per-case literal assertions is the
  // assertion set, and each covers a different thing. The generator re-lowers
  // the chain it is about to write and compares the result to the hydrated
  // document, so "a chain was emitted" carries "this chain's SERIES rebuild
  // this chart" — but NOT "this chain's config literals are right": the
  // captured `PolarChartConfig` / `ConcentricDonutConfig` ride the proof spec
  // verbatim and lowering hands the same instances back, so that comparison is
  // an instance against itself. `expectShowcaseEmits` therefore runs the
  // emitted TEXT through `dart format` + `dart analyze` (the proof inspects the
  // reconstructed spec object and never reads a character of what the emitter
  // writes), and every case below pins the config fields it exercises with
  // whole-literal `fragments` — which is what would actually fail if the
  // `.polarConfig(...)` emission regressed.
  //
  // What this group deliberately does NOT do is `expectRoundTrip`'s rebuild.
  // A Flutter test cannot execute generated Dart — `dart analyze` runs over a
  // scratch file and never loads it — so "rebuilt" always means a SECOND,
  // hand-transcribed chain in this file. That transcription is worth writing
  // once per SHAPE, and it already is: shapes 20-28 above hand-rebuild a
  // styled polar, a multi-series polar, a customised `PolarChartConfig`, every
  // config field, per-category column colors and targets, intervals, the rose
  // preset, two series with independent advanced fields, and a customised
  // `ConcentricDonutConfig` — the complete mechanism set these presentations
  // are assembled from. Re-transcribing it per PRESENTATION would add ~9 more
  // copies of chains whose only new content is the showcase's literal knob
  // values, and those values are what the whole-literal assertions below pin
  // directly. So the compile gate is the floor here, and the per-case
  // `literalArguments` blocks — not a ninth transcription — are what stop an
  // emitted literal from drifting.
  // =========================================================================

  group('showcase acceptance: every polar presentation emits, plus a '
      'non-default ConcentricDonutConfig', () {
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

    testWidgets('partial: a 240 degree sweep from 150 degrees over an open '
        'center', (tester) async {
      // The eighth presentation. Every other one leaves the pane's angular
      // span at the class defaults, so this is the ONLY acceptance case in
      // which a reversal that rebuilt the pane from its defaults — a full 360
      // starting at -90 — would draw a visibly different chart while still
      // reproducing every series. The pane literals below are therefore the
      // load-bearing part of this test, not decoration.
      final colors = showcaseColumnColors(
        showcasePartialValues,
        showcaseEarthPalette,
      );
      final generated = await expectShowcaseEmits(
        tester,
        presentation: 'partial',
        fragments: <String>[
          '.geomPolar(',
          'columnColor: (row) => row.columnColor,',
          '.polarConfig(',
          'pane: PolarPaneConfig(',
          'startAngleDegrees: 150.0,',
          'sweepAngleDegrees: 240.0,',
          'innerRadiusFactor: 0.28,',
          'outerRadiusFactor: 0.9,',
          'innerPadding: 0.14,',
          'outerPadding: 0.08,',
        ],
        chart: (controller) => BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: showcasePolarConfig(
            startAngleDegrees: 150,
            sweepAngleDegrees: 240,
            innerRadiusFactor: 0.28,
            outerRadiusFactor: 0.9,
            innerPadding: 0.14,
            outerPadding: 0.08,
            categoryLabelColor: const Color(0xFF7C2D12),
            radialLabelColor: const Color(0xFF9A3412),
            compositionMode: PolarColumnCompositionMode.layered,
          ),
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'showcase-polar-column',
              name: 'Category volume',
              values: showcasePartialValues,
              columnColors: colors,
              unit: 'requests',
              polarStyle: showcasePolarStyle(
                cornerRadius: 8,
                opacity: 0.86,
                borderColor: const Color(0xFF7C2D12),
                valueLabelColor: const Color(0xFF431407),
                animationMode: PolarColumnAnimationMode.fade,
                gradient: const PolarColumnGradientStyle(
                  startLightnessShift: 0.28,
                  endLightnessShift: -0.08,
                ),
                shadow: const PolarColumnShadowStyle(
                  color: Color(0xFF9A3412),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                  opacity: 0.18,
                ),
              ),
              selectionStyle: showcasePolarSelection,
            ),
          ],
        ),
      );
      expect('.geomPolar('.allMatches(generated.source).length, 1);
      // Asserted WHOLE: a fragment list can only notice the pane fields it
      // happens to name, and the whole point of this presentation is the pane.
      // `clockwise` and `clipMarks` are the showcase's own resting values, so
      // they are correctly elided.
      expect(
        literalArguments(generated.source, 'pane: PolarPaneConfig('),
        <String>[
          'startAngleDegrees: 150.0,',
          'sweepAngleDegrees: 240.0,',
          'innerRadiusFactor: 0.28,',
          'outerRadiusFactor: 0.9,',
        ],
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
      final generated = await expectShowcaseEmits(
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
          // The plot-level config: the fragment list above named only
          // per-SERIES text, so the whole `.polarConfig(...)` verb could be
          // dropped from the chain and this case would still have passed.
          // (The round-trip proof cannot see it either — it re-lowers the
          // captured `PolarChartConfig` OBJECT, not the emitted literal.)
          '.polarConfig(',
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
                  if (showcaseUncertaintyLowerValues[category]
                      case final lower?)
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
      // The plot-level config asserted WHOLE. Before this, `intervals` named
      // only per-series text, so deleting the entire `.polarConfig(...)` verb
      // from `_emitPolarChartBody` left this acceptance case green while the
      // emitted chain rebuilt a DEFAULT pane, default paddings and default
      // label styling — a visibly different chart. Every line below is a knob
      // the showcase authors away from its class default; the ones it leaves
      // alone (`outerRadiusFactor`, `outerPadding`, the visible-label caps,
      // the radial `labelOffset`, the layered composition) are correctly
      // elided, and this list fails if any of that flips.
      expect(literalArguments(generated.source, 'PolarChartConfig('), <String>[
        'pane: PolarPaneConfig(',
        'innerRadiusFactor: 0.12,',
        '),',
        'angularAxis: PolarCategoryAxisConfig(',
        'innerPadding: 0.16,',
        'labelOffset: 4.0,',
        'labelStyle: PolarLabelStyle(',
        'color: Color(0xFF334155),',
        'fontSize: 12.0,',
        'fontWeight: FontWeight.w500,',
        '),',
        '),',
        'radialAxis: PolarNumericAxisConfig(',
        'scaleMode: PolarRadialScaleMode.linear,',
        'labelStyle: PolarLabelStyle(',
        'color: Color(0xFF475569),',
        'fontSize: 10.0,',
        'fontWeight: FontWeight.w500,',
        '),',
        '),',
      ]);
    });

    testWidgets('a non-default ConcentricDonutConfig authored through the '
        'grammar emits — NOT the ConcentricDonutPage', (tester) async {
      // SCOPE, stated exactly, because the name of the group around this test
      // would otherwise over-claim it.
      //
      // What this proves: a customised `ConcentricDonutConfig` — radii, a ring
      // gap, an order, a legend mode, per-ring weights and a center — survives
      // to `geomDonut(concentric:)`. Every one of those was refused before the
      // mark carried the whole config, because lowering rebuilt the
      // composition from the center alone. That is the CONFIG PASSTHROUGH.
      //
      // What it does NOT prove: that `concentric_donut_page.dart` emits. This
      // chart is authored the way the grammar's own concentric lowering emits
      // one — no per-slice colours, one `dataLabels` for the whole composition
      // — and the page does neither. That claim is a MOUNTED-PAGE one and is
      // made where it can be honest, in
      // `example/test/showcase/concentric_donut_page_grammar_test.dart`, which
      // mounts `ConcentricDonutPage`, reads the live document off the chart's
      // own controller and asserts a complete chain; its sibling does the same
      // for the selection lab's concentric family. (A hand copy of a page
      // cannot make that claim, which is why it is not made here.)
      await expectShowcaseEmits(
        tester,
        presentation: 'grammar-authored concentric config',
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

  // =========================================================================
  // RETIRED — "KNOWN GAP: the donut showcase pages do not emit".
  //
  // This file used to carry a group of PINNED REFUSALS standing in for the
  // radial workbench panes that showed a diagnostic instead of a chain, plus a
  // banner claiming THREE independent blockers and that `donut_charts_page.dart`
  // hit only blocker 2. Both counts were wrong: there were FOUR, and the fourth
  // — the donut centre, which `_markCenter` rebuilt from four of its fields and
  // which `donut_charts_page.dart` tripped in EVERY knob state through its live
  // `valueFormatter` — was unrecorded, so that page was refused independently of
  // its `sliceColors`.
  //
  // All four are now closed, and every pin was CONVERTED into a stronger
  // round-trip acceptance test rather than deleted. The converted tests live in
  // the `showcase-representative radial series config emits` group and name
  // their origin, each keeping the original refusal chart AND a byte-identity
  // control that the un-overridden shape emits no new argument:
  //
  //   * ring ids       → "…that used to be BLOCKER 1 now emits ringIds and
  //                       round-trips" (control: conforming ids emit no
  //                       `ringIds`). Still refused: rings unnamed or sharing a
  //                       name — the ring key IS the series name, so a `ring:`
  //                       channel has nothing to bucket by. Its own test.
  //   * per-slice      → "…that used to be BLOCKER 2 now emits and round-trips"
  //     colours          (control: a colourless donut emits no `sliceColor`).
  //   * per-ring       → "…that used to be BLOCKER 3 now emits and round-trips"
  //     data labels      (control: a uniform composition emits no
  //                       `dataLabelsByRing`).
  //   * the donut      → "…that used to be BLOCKER 4 now emits and round-trips"
  //     centre           (control: a default centre emits no `center:`).
  //
  // The live gates are no longer here at all: they are the MOUNTED-page tests
  // in `example/test/showcase/` — `pie_charts_page_grammar_test.dart`,
  // `donut_charts_page_grammar_test.dart`,
  // `concentric_donut_page_grammar_test.dart` and
  // `selection_showcase_concentric_grammar_test.dart` — which is why no group
  // stands here. See the acceptance-gate banner above for the split.
  // =========================================================================

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

    // =======================================================================
    // THE CONCENTRIC RING PRECONDITIONS.
    //
    // `doc/chart_grammar.md` used to claim the ONE remaining precondition on a
    // concentric composition was that no ring carry a centre of its own. That
    // was false, and nothing failed when it went stale. `DonutMark` holds ONE
    // `style`, `selectionStyle`, `unit`, `sliceRadiusConfig` and
    // `sliceGroupingConfig` for the WHOLE composition, and
    // `_lowerConcentricRings` (`plot_lowering.dart:1524`) stamps each of them
    // onto every ring — and, unlike the single-donut `_lowerDonut` beside it,
    // never passes `mark.color` at all. So SIX further preconditions exist,
    // every one of them reachable by an author writing ordinary config-form
    // Dart.
    //
    // These tests are the gate on that list. They assert the BOUNDARY, not the
    // implementation: the fix for any of them would be a mark field, which is
    // a feature, not a doc correction.
    // =======================================================================

    testWidgets('rings SHARING one non-default donutStyle emit — it is '
        'DIVERGENCE that is refused, not a non-default value', (tester) async {
      // The control that gives the refusal below its meaning. Without it, a
      // regression that refused every non-default ring style would leave the
      // refusal test passing while the family quietly stopped emitting.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mix-Inner',
              name: 'Inner',
              values: const <String, num>{'Apple': 40, 'Pear': 60},
              donutStyle: const DonutChartStyle(innerRadiusFactor: 0.4),
            ),
            DonutChartSeries.fromMap(
              id: 'mix-Outer',
              name: 'Outer',
              values: const <String, num>{'Apple': 30, 'Pear': 70},
              donutStyle: const DonutChartStyle(innerRadiusFactor: 0.4),
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(
        emittedChain(generated),
        isTrue,
        reason: 'blocked with: ${blockedReason(generated)}',
      );
      expect(generated.isComplete, isTrue);
      // The shared value is not merely tolerated, it is CARRIED.
      expect(generated.source, contains('innerRadiusFactor: 0.4'));
    });

    testWidgets('a concentric composition whose rings DIVERGE in donutStyle is '
        'refused', (tester) async {
      // The headline case. Conforming ids, distinct non-empty names, no ring
      // centre — every precondition the docs used to name is satisfied — and
      // it is still refused, because the mark has one `style` to give.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mix-Inner',
              name: 'Inner',
              values: const <String, num>{'Apple': 40, 'Pear': 60},
              donutStyle: const DonutChartStyle(innerRadiusFactor: 0.4),
            ),
            DonutChartSeries.fromMap(
              id: 'mix-Outer',
              name: 'Outer',
              values: const <String, num>{'Apple': 30, 'Pear': 70},
              donutStyle: const DonutChartStyle(innerRadiusFactor: 0.7),
            ),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(generated.isComplete, isFalse);
      expect(blockedReason(generated), contains('mix-Outer'));
      // The refusal is HONEST but UNNAMED: it arrives through the round-trip
      // proof's catch-all sentence, whose own round-trip list names "series
      // style" among the things that DO round-trip. Asserting the catch-all
      // here is deliberate — it records that this precondition has no reason
      // of its own, so giving it one (which it deserves) fails this test and
      // forces the four doc sites to be updated in the same change.
      expect(
        blockedReason(generated),
        contains('It carries a series option the radial marks do not carry'),
      );
    });

    testWidgets('every other per-ring divergence — selectionStyle, unit, '
        'sliceRadiusConfig, sliceGroupingConfig — is refused too', (
      tester,
    ) async {
      Future<void> expectRefused(String label, List<ChartSeries> series) async {
        final snapshot = await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            concentricDonutConfig: const ConcentricDonutConfig(),
            series: series,
          ),
        );
        final generated = generateGrammar(snapshot);
        expect(
          emittedChain(generated),
          isFalse,
          reason: '$label must be refused, but a chain was emitted',
        );
        expect(generated.isComplete, isFalse, reason: label);
      }

      await expectRefused('a divergent selectionStyle', <ChartSeries>[
        DonutChartSeries.fromMap(
          id: 'mix-Inner',
          name: 'Inner',
          values: const <String, num>{'Apple': 40, 'Pear': 60},
          selectionStyle: const RadialSelectionStyle(
            effect: RadialSelectionEffect.lift,
          ),
        ),
        DonutChartSeries.fromMap(
          id: 'mix-Outer',
          name: 'Outer',
          values: const <String, num>{'Apple': 30, 'Pear': 70},
        ),
      ]);

      await expectRefused('a divergent unit', <ChartSeries>[
        DonutChartSeries.fromMap(
          id: 'mix-Inner',
          name: 'Inner',
          unit: 'USD',
          values: const <String, num>{'Apple': 40, 'Pear': 60},
        ),
        DonutChartSeries.fromMap(
          id: 'mix-Outer',
          name: 'Outer',
          unit: 'EUR',
          values: const <String, num>{'Apple': 30, 'Pear': 70},
        ),
      ]);

      await expectRefused('a divergent sliceRadiusConfig', <ChartSeries>[
        DonutChartSeries.fromMap(
          id: 'mix-Inner',
          name: 'Inner',
          values: const <String, num>{'Apple': 40, 'Pear': 60},
          radiusValues: const <String, num>{'Apple': 1, 'Pear': 2},
          sliceRadiusConfig: const RadialSliceRadiusConfig(minimumFactor: 0.3),
        ),
        DonutChartSeries.fromMap(
          id: 'mix-Outer',
          name: 'Outer',
          values: const <String, num>{'Apple': 30, 'Pear': 70},
          radiusValues: const <String, num>{'Apple': 1, 'Pear': 2},
          sliceRadiusConfig: const RadialSliceRadiusConfig(minimumFactor: 0.6),
        ),
      ]);

      await expectRefused('a divergent sliceGroupingConfig', <ChartSeries>[
        DonutChartSeries.fromMap(
          id: 'mix-Inner',
          name: 'Inner',
          values: const <String, num>{'Apple': 40, 'Pear': 58, 'Fig': 2},
          sliceGroupingConfig: const RadialSliceGroupingConfig(
            minimumShare: 0.1,
          ),
        ),
        DonutChartSeries.fromMap(
          id: 'mix-Outer',
          name: 'Outer',
          values: const <String, num>{'Apple': 30, 'Pear': 68, 'Fig': 2},
        ),
      ]);
    });

    testWidgets('ANY per-ring series colour is refused — even when every ring '
        'carries the SAME one', (tester) async {
      // Not a divergence at all: `_lowerConcentricRings` never passes
      // `mark.color`, so no concentric ring can carry a series colour. The
      // single-donut path beside it DOES (`_lowerDonut` passes
      // `color: mark.color`), which is why this is a ring precondition and not
      // a donut one — the control below proves the difference rather than
      // asserting it.
      final rings = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          concentricDonutConfig: const ConcentricDonutConfig(),
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mix-Inner',
              name: 'Inner',
              color: const Color(0xFF2563EB),
              values: const <String, num>{'Apple': 40, 'Pear': 60},
            ),
            DonutChartSeries.fromMap(
              id: 'mix-Outer',
              name: 'Outer',
              color: const Color(0xFF2563EB),
              values: const <String, num>{'Apple': 30, 'Pear': 70},
            ),
          ],
        ),
      );
      final ringsGenerated = generateGrammar(rings);
      expect(emittedChain(ringsGenerated), isFalse);
      expect(ringsGenerated.isComplete, isFalse);

      final single = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mix',
              name: 'Mix',
              color: const Color(0xFF2563EB),
              values: const <String, num>{'Apple': 40, 'Pear': 60},
            ),
          ],
        ),
      );
      final singleGenerated = generateGrammar(single);
      expect(
        emittedChain(singleGenerated),
        isTrue,
        reason:
            'a NON-concentric donut carries its series colour; only the ring '
            'path drops it. Blocked with: ${blockedReason(singleGenerated)}',
      );
      expect(singleGenerated.isComplete, isTrue);
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
      final error =
          (result as ChartArtifactFailure<ChartGeneratedSource>).error;
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
      // RE-POINTED, not weakened. This used to use `unit: 'W'` as its example
      // of an uncarried option; the five Cartesian marks now CARRY unit, so
      // keeping it here would pin a behaviour this slice deliberately removed.
      // The carried case is asserted positively instead — see round trip
      // "shape 29" / "29b" / "29d", which require the unit to survive AND to
      // appear in the emitted text. `tension` is still genuinely uncarried
      // (LineMark has no curve tension), so the claim in the test's name is
      // unchanged, and the assertion is now on the diagnostic's full PHRASE
      // rather than on the bare option word.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              tension: 0.6,
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
          contains('curve tension'),
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

    testWidgets('a single-axis config chart emits and round-trips', (
      tester,
    ) async {
      // CONVERTED, not deleted, from "a single-axis config chart explains the
      // axis binding". That test pinned the REFUSAL of a chart authored through
      // the single-axis path (`BravenChartPlus` with a widget-level yAxis and
      // no per-series binding) — the behaviour this slice deliberately removes.
      // So it becomes the stronger claim: the same chart now emits AND the
      // chain it emits reproduces the captured DOCUMENT, gated by
      // `expectRoundTrip`'s document equality rather than by a message.
      final generated = await expectRoundTrip(
        tester,
        name: 'legacy_single_axis',
        fragments: <String>[
          'BravenChart.of(rows)',
          'YAxisConfig.withId(',
          '.geomLine(',
        ],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
          ),
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              name: 'Power',
              unit: 'W',
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 168),
                ChartDataPoint(x: 1, y: 204),
                ChartDataPoint(x: 2, y: 268),
              ],
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x)
            .yAxis(
              YAxisConfig.withId(
                id: 'y',
                position: YAxisPosition.left,
                label: 'Power',
                unit: 'W',
              ),
            )
            .geomLine(
              id: 'power',
              y: (row) => row.power,
              name: 'Power',
              unit: 'W',
            )
            .build(bravenChartController: controller),
      );
      // The proof NEVER READS THE EMITTED TEXT, so the one thing that makes
      // this chain the legacy shape has to be asserted here: a `yAxisId:` on
      // the geom would bind the mark, `BravenPlot` would mount the multi-axis
      // shape, and the chain would hand back a DIFFERENT document from the
      // chart it was reversed from — while every other assertion above still
      // passed, because the rebuilt twin is hand-written, not compiled from
      // this text.
      expect(generated.source, isNot(contains('yAxisId')));
      // The AXIS is asserted as a whole literal, not as fragments. `unit:` is a
      // field of both `YAxisConfig` and the geom verb, and this chart carries
      // 'W' on both, so a bare `contains("unit: 'W'")` is satisfied by the geom
      // alone and says nothing about the axis — proven by mutation: emitting
      // `null` for `axis.unit` left that fragment green. The complete argument
      // list fails on a dropped field, an extra field, a wrong value and a
      // reordering alike.
      expect(
        literalArguments(generated.source, 'YAxisConfig.withId('),
        <String>[
          "id: 'y',",
          'position: YAxisPosition.left,',
          "label: 'Power',",
          "unit: 'W',",
        ],
      );
    });

    testWidgets(
      'a MIXED binding is still refused — only the LOWERED side is normalised',
      (tester) async {
        // One series bound through an inline axis config, one left unbound. The
        // captured document keeps that difference — `getEffectiveYAxes` returns
        // only the inline axis, and `getEffectiveBindings` sends the unbound
        // series to a synthetic 'primary_axis' rather than to the inline one — so
        // treating the unbound series as bound to the other's axis renders a
        // DIFFERENT chart (measured: 4265 of 960000 pixels differ under
        // normalizationMode.perSeries). This shape must therefore stay refused.
        //
        // What this pins is the ASYMMETRY of `_firstMismatch`'s comparison, not
        // the gate in front of it. Measured by mutation: normalising BOTH sides
        // — the "a null yAxisId means axes.first" shape — fails this test,
        // while widening the gate, up to deleting it outright, leaves it green,
        // because the captured side is never stripped and its binding always
        // has to be met. The gate's own coupling is stated by "a single-axis
        // chart with an EXPLICIT binding still emits" below.
        final snapshot = await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              LineChartSeries(
                id: 'a',
                yAxisConfig: YAxisConfig.withId(
                  id: 'a-axis',
                  position: YAxisPosition.left,
                  min: 0,
                  max: 1000,
                ),
                points: const <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 1),
                  ChartDataPoint(x: 1, y: 2),
                ],
              ),
              const LineChartSeries(
                id: 'b',
                points: <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 900),
                  ChartDataPoint(x: 1, y: 950),
                ],
              ),
            ],
          ),
        );
        final generated = generateGrammar(snapshot);
        expect(emittedChain(generated), isFalse);
        expect(
          blockedReason(generated),
          allOf(contains('does not reproduce'), contains('yAxisId')),
        );
      },
    );

    testWidgets('a single-axis chart with an EXPLICIT binding still emits', (
      tester,
    ) async {
      // The gate's positive half, stated by name so the coupling is visible
      // instead of incidental. ONE declared axis, and the captured series is
      // bound to it — the multi-axis mount, which `BravenPlot` keeps whenever a
      // mark names its axis.
      //
      // This chart emits ONLY because the gate carries its all-unbound clause.
      // Drop that clause and `legacySingleAxis` is true here too, the LOWERED
      // series is stripped of the binding the CAPTURED one still carries, the
      // comparison can never be met, and this reproducible chart is refused
      // with the axis sentence. Measured: that mutation fails this test and
      // round-trip shapes 5, 29b, 29c and 29d, and NOTHING else.
      final generated = await expectRoundTrip(
        tester,
        name: 'explicitly_bound_single_axis',
        fragments: <String>['BravenChart.of(rows)', '.geomLine('],
        original: (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            LineChartSeries(
              id: 'power',
              yAxisId: 'power-axis',
              yAxisConfig: YAxisConfig.withId(
                id: 'power-axis',
                position: YAxisPosition.left,
                label: 'Power',
              ),
              points: const <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 168),
                ChartDataPoint(x: 1, y: 204),
                ChartDataPoint(x: 2, y: 268),
              ],
            ),
          ],
        ),
        rebuilt: (controller) => BravenChart.of(grammarRows)
            .x((row) => row.x)
            .yAxis(
              YAxisConfig.withId(
                id: 'power-axis',
                position: YAxisPosition.left,
                label: 'Power',
              ),
            )
            .geomLine(id: 'power', y: (row) => row.power, yAxisId: 'power-axis')
            .build(bravenChartController: controller),
      );
      // The proof never reads the emitted text, and the twin above is
      // hand-written, so the binding that makes this the multi-axis shape has
      // to be asserted on the text itself: without it the emitted chain would
      // mount the LEGACY shape and hand back a document with no `axisId` and no
      // `inlineAxis`, while every assertion above still passed.
      expect(generated.source, contains("yAxisId: 'power-axis'"));
    });

    testWidgets('TWO declared axes with every series unbound is still refused', (
      tester,
    ) async {
      // The boundary the `axes.length == 1` half of the gate describes, stated
      // as an outcome. `BravenPlot` mounts the legacy shape only when the chain
      // declares EXACTLY ONE axis, so a document that declares two while
      // binding no series must not be normalised into an unbound chain: that
      // chain would take the multi-axis mount and hand back `series[*].axisId`
      // plus `inlineAxis` the captured document does not have.
      //
      // This test does NOT guard that clause, and the assertion says so rather
      // than pretending otherwise: the refusal comes a layer EARLIER, because
      // lowering binds every unbound mark to `axes.first`, which leaves the
      // second axis with nothing measuring against it, and the grammar layer's
      // own unboundAxis diagnostic rejects the reconstructed spec before
      // `_firstMismatch` runs. Measured by mutation: dropping the
      // `axes.length == 1` clause leaves this test — and every other test in
      // this file — green. That clause is defence in depth; the outcome below
      // is what actually has to hold.
      //
      // The render pipeline never builds this shape — `getEffectiveYAxes`
      // returns the widget-level axis alone while no series carries an inline
      // config — but a ChartDocument is a PERSISTED artifact that can arrive
      // from disk or from a host, so the generator still has to meet it.
      // `patchedSnapshot` is how this file states rows the renderer will not
      // produce.
      final single = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
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
      final twoAxes = patchedSnapshot(single, (json) {
        final axes = json['axes']! as List<Object?>;
        axes.add(
          Map<String, Object?>.of(axes.first! as Map<String, Object?>)
            ..['id'] = 'second'
            ..['position'] = 'right',
        );
      });
      final generated = generateGrammar(twoAxes);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('rejected by the grammar layer'),
          contains('No mark measures against the axis "second"'),
        ),
      );
    });

    testWidgets('grid and legend never trip the chart-option gate', (
      tester,
    ) async {
      // Grid and legend are carried by PlotSpec, so they must NOT appear in any
      // chart-option block reason.
      //
      // This used to mount a single-axis chart and assert only that the reason
      // named neither. That chart now EMITS, so `blockedReason` is null and
      // `isNot(contains(...))` passes on nothing at all — the test would have
      // gone on reporting success with the whole chart-option gate deleted. It
      // now makes both halves real: the carrying chart must EMIT with its
      // non-default grid and legend in the text, and a chart that still blocks
      // for an unrelated reason must produce a reason that is genuinely there
      // and still names neither.
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
        emittedChain(gridResult),
        isTrue,
        reason: 'blocked with: ${blockedReason(gridResult)}',
      );
      expect(gridResult.source, contains('.grid('));
      expect(gridResult.source, contains('.legend(false)'));

      // The same chart plus one option no V1 mark carries. It blocks — so
      // `blockedReason` is a real sentence — and that sentence must still name
      // the tension and neither the grid nor the legend.
      final blockedForOtherReasons = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          grid: const GridConfig(horizontal: false),
          showLegend: false,
          series: const <ChartSeries>[
            LineChartSeries(
              id: 'power',
              tension: 0.6,
              points: <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 1),
                ChartDataPoint(x: 1, y: 2),
              ],
            ),
          ],
        ),
      );
      final blockedResult = generateGrammar(blockedForOtherReasons);
      expect(emittedChain(blockedResult), isFalse);
      expect(
        blockedReason(blockedResult),
        allOf(
          isNotNull,
          contains('curve tension'),
          isNot(contains('grid')),
          isNot(contains('legend')),
        ),
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

  // =========================================================================
  // THE RADIAL ROUND-TRIP PROOF — the guard that makes "emitted == faithful"
  // true for pie, donut, concentric and polar.
  //
  // Every emitted radial chain rests on ONE claim: before writing anything the
  // generator re-lowers the chain it is about to write and compares the
  // re-lowered series to the captured ones, refusing by name anything they do
  // not reproduce (`_firstRadialMismatch`). Nothing else stands between a
  // series option no radial mark carries and a chain that silently drops it —
  // the family gates let these shapes through, and the emitters happily write
  // them. So DELETING that comparison must break something here.
  //
  // Each test is therefore a PAIR: a shape carrying an option the marks do not
  // carry, which must be refused with no chain and a named reason, and a
  // near-identical CONTROL differing only in that option, which must emit a
  // clean chain. The control is what makes the refusal attributable to the
  // option rather than to the family, and what stops the refusal assertions
  // from being satisfiable by a generator that has simply stopped emitting.
  //
  // Both call sites are covered: `_tryEmitPolarChain` (the polar cases) and
  // `_tryEmitRadialChain` (the concentric and pie cases).
  // =========================================================================
  group('the radial round-trip proof refuses what the marks do not carry', () {
    testWidgets('a polar series carrying metadata is refused, naming the '
        'series and the metadata; without it the same chart emits', (
      tester,
    ) async {
      Future<ChartGeneratedSource> generateFor(
        Map<String, dynamic>? metadata,
      ) async => generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              PolarColumnChartSeries.fromMap(
                id: 'capacity',
                values: const <String, num>{'A': 3, 'B': 5, 'C': 8},
                metadata: metadata,
              ),
            ],
          ),
        ),
      );

      // `PolarMark` has no metadata channel, so the re-lowered series comes
      // back without it. Emitting anyway would hand back a chart whose series
      // has lost its metadata, with nothing said about it.
      final refused = await generateFor(const <String, dynamic>{
        'sport': 'cycling',
      });
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomPolar(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "capacity" exactly'),
          contains('would hand back a different chart'),
          contains('series metadata'),
        ),
      );

      // CONTROL: the SAME chart with the metadata removed emits a clean chain,
      // so the refusal above is attributable to the metadata — not to polar.
      final emitted = await generateFor(null);
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(emitted.isComplete, isTrue);
      expect(emitted.source, contains('.geomPolar('));
    });

    testWidgets('a polar interval pair that is all-null is refused; the same '
        'series with one real interval emits it as a row channel', (
      tester,
    ) async {
      Future<ChartGeneratedSource> generateFor(
        List<double?> lower,
        List<double?> upper,
      ) async => generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              PolarColumnChartSeries(
                id: 'capacity',
                points: const <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 3, label: 'A'),
                  ChartDataPoint(x: 1, y: 5, label: 'B'),
                  ChartDataPoint(x: 2, y: 8, label: 'C'),
                ],
                intervalLowerValues: lower,
                intervalUpperValues: upper,
              ),
            ],
          ),
        ),
      );

      // A present-but-all-null pair is NOT the same series as no pair at all:
      // `PolarMark.intervalLow/High` reverse an all-null column to EMPTY lists,
      // so the re-lowered series differs from the captured one in a way no
      // rendered pixel shows and no other check notices.
      final refused = await generateFor(
        const <double?>[null, null, null],
        const <double?>[null, null, null],
      );
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomPolar(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "capacity" exactly'),
          contains('all-null polar interval list'),
        ),
      );

      // CONTROL: one real interval in the SAME lists emits, and the nulls ride
      // the row channel — so an all-null pair is refused for being all-null,
      // not for containing nulls.
      final emitted = await generateFor(
        const <double?>[2, null, null],
        const <double?>[4, null, null],
      );
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(
        emitted.source,
        contains('intervalLow: (row) => row.intervalLow,'),
      );
      expect(emitted.source, contains('intervalLow: 2.0,'));
      expect('intervalLow: null,'.allMatches(emitted.source).length, 2);
    });

    testWidgets('a polar point whose pointStyle goes beyond a colour override '
        'is refused; the colour-only override emits as a row channel', (
      tester,
    ) async {
      Future<ChartGeneratedSource> generateFor(PointStyle style) async =>
          generateGrammar(
            await snapshotOf(
              tester,
              (controller) => BravenChartPlus(
                bravenChartController: controller,
                series: <ChartSeries>[
                  PolarColumnChartSeries(
                    id: 'capacity',
                    points: <ChartDataPoint>[
                      const ChartDataPoint(x: 0, y: 3, label: 'A'),
                      ChartDataPoint(x: 1, y: 5, label: 'B', pointStyle: style),
                      const ChartDataPoint(x: 2, y: 8, label: 'C'),
                    ],
                  ),
                ],
              ),
            ),
          );

      // The ONLY per-point channel a polar mark carries is the column colour
      // (`columnColor`), which lowering writes back as `PointStyle.color(...)`.
      // A point that also sets `size` re-lowers to a colour-only style, so the
      // size is gone — silently, because a polar column ignores it when it
      // paints.
      final refused = await generateFor(
        const PointStyle(color: Color(0xFF16A34A), size: 4),
      );
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomPolar(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "capacity" exactly'),
          contains('a per-point style beyond a colour override'),
          // The polar half of the round-trip list, pinned so the polar-facing
          // text is asserted rather than merely inherited.
          contains(
            '(polar) the preset, per-category column colours, targets and '
            'intervals round-trip',
          ),
        ),
      );
      // The family split, asserted from the POLAR side too: a polar column
      // ignores `size` when it paints and `PolarColumnChartSeries._fromMap`
      // writes the narrowing `PointStyle.color(...)`, so telling a polar author
      // that `size` round-trips would be false.
      expect(
        blockedReason(refused),
        isNot(contains('a colour and size override')),
      );
      // ACCEPTED DELTA, pinned. `_radialSeriesLossDetail` is SHARED by both
      // radial families, so this slice's new `(pie/donut) the per-slice colours`
      // clause also appears in a REFUSED POLAR chart's blocked header. It is
      // the one place polar output is not byte-identical to the pre-slice
      // generator — diagnostic prose only, never an emitted chain
      // (`_radialSliceColorField` is called from `_planPie` / `_planDonut` /
      // `_planConcentric` and from nowhere else). The plan prescribes exactly
      // this shared sentence (Task 1.3 Step 7); pinning it here means a later
      // edit to the polar-facing text turns a test red instead of passing
      // unnoticed.
      expect(
        blockedReason(refused),
        contains('(pie/donut) the per-slice colours'),
      );

      // CONTROL: drop the `size` and the very same point emits as a column
      // colour, so the refusal is attributable to the extra override alone.
      final emitted = await generateFor(
        const PointStyle.color(Color(0xFF16A34A)),
      );
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(
        emitted.source,
        contains('columnColor: (row) => row.columnColor,'),
      );
    });

    testWidgets('a concentric composition whose ring centers disagree is '
        'refused, naming the OFFENDING ring; matching rings emit', (
      tester,
    ) async {
      Future<ChartGeneratedSource> generateFor(
        DonutCenterContent summerCenter,
      ) async => generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            concentricDonutConfig: const ConcentricDonutConfig(),
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
                centerContent: summerCenter,
              ),
            ],
          ),
        ),
      );

      // ONE `geomDonut(ring:)` mark lowers to EVERY ring, so the rings of an
      // emittable composition all carry the same center. Here only the second
      // ring carries one, which the mark cannot express: it would re-lower to
      // two centre-less rings. Naming "seasons-Summer" — the second series —
      // is the part that proves the check walks the whole ring list and
      // reports the ring that actually diverges, not simply the first one.
      final refused = await generateFor(
        const DonutCenterContent(label: 'Summer'),
      );
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomDonut(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "seasons-Summer" exactly'),
          contains('would hand back a different chart'),
          // And the reason NAMES the centre, rather than falling through to the
          // catch-all list of series options. The ring's centre is the only
          // thing that diverges here; a reason that named "series metadata" or
          // "a per-point style" would be a misdiagnosis.
          contains('carries ONE shared donut center'),
          contains('re-lowers every ring with a hidden center'),
        ),
      );
      expect(blockedReason(refused), isNot(contains('seasons-Winter')));
      expect(
        blockedReason(refused),
        isNot(contains('a per-point style beyond')),
      );

      // CONTROL: give the second ring the same hidden center as the first and
      // the composition emits, so the refusal is attributable to the ring whose
      // center diverges — not to concentric donuts.
      final emitted = await generateFor(DonutCenterContent.hidden);
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(emitted.isComplete, isTrue);
      expect(emitted.source, contains('.geomDonut('));
      expect(emitted.source, contains('ring: (row) => row.ring'));
    });

    testWidgets('a donut point whose pointStyle sets a scatter marker is '
        'refused; the colour-only override emits as a row channel', (
      tester,
    ) async {
      // `PointStyle` carries four fields. Pie/donut now reverse TWO of them
      // (`color` as `sliceColor:`, `size` as `radius:`); the scatter-marker
      // pair has no radial mark channel at all, so a point that sets one stays
      // an honest refusal rather than emitting a chain that silently drops it.
      // BOTH halves of that pair are exercised below — `PointStyle.==` compares
      // all four fields, so covering only `scatterMarkerShape` would leave the
      // claim about the pair half-proven.
      Future<ChartGeneratedSource> generateFor(PointStyle style) async =>
          generateGrammar(
            await snapshotOf(
              tester,
              (controller) => BravenChartPlus(
                bravenChartController: controller,
                series: <ChartSeries>[
                  DonutChartSeries(
                    id: 'donut',
                    points: <ChartDataPoint>[
                      const ChartDataPoint(
                        x: 0,
                        y: 3,
                        label: 'A',
                        pointStyle: PointStyle(color: Color(0xFF112233)),
                      ),
                      ChartDataPoint(x: 1, y: 5, label: 'B', pointStyle: style),
                    ],
                  ),
                ],
              ),
            ),
          );

      final refused = await generateFor(
        const PointStyle(
          color: Color(0xFF445566),
          scatterMarkerShape: SeriesMarkerShape.square,
        ),
      );
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomDonut(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "donut" exactly'),
          contains('a per-point style beyond a colour and size override'),
        ),
      );

      // The OTHER half of the scatter-marker pair. Same mechanism, same named
      // reason — asserted rather than assumed.
      final refusedStyle = await generateFor(
        const PointStyle(
          color: Color(0xFF445566),
          scatterMarkerStyle: ScatterMarkerStyle(
            fillColor: Color(0xFF778899),
            strokeWidth: 2,
          ),
        ),
      );
      expect(emittedChain(refusedStyle), isFalse);
      expect(refusedStyle.isComplete, isFalse);
      expect(refusedStyle.source, isNot(contains('.geomDonut(')));
      expect(
        blockedReason(refusedStyle),
        allOf(
          contains('does not reproduce series "donut" exactly'),
          contains('a per-point style beyond a colour and size override'),
        ),
      );

      // CONTROL: drop the marker shape and the very same point emits as a
      // slice colour, so the refusal is attributable to the extra override
      // alone — not to per-point styling on a donut.
      final emitted = await generateFor(
        const PointStyle(color: Color(0xFF445566)),
      );
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(emitted.source, contains('sliceColor: (row) => row.sliceColor,'));
    });

    testWidgets('a donut point carrying a BARE const PointStyle() is refused', (
      tester,
    ) async {
      // The document codec writes an override-less style as `pointStyle: {}`
      // and decodes it back to a NON-NULL `const PointStyle()`, while the
      // grammar reversal allocates no field for it and yields `null`. The
      // asymmetry is real — the two series are not equal — so it stays an
      // honest refusal rather than a chain that quietly changes the document.
      //
      // The reason gets its OWN clause. `const PointStyle()` has no overrides
      // at all (`PointStyle.hasOverrides` is false), so the catch-all sentence
      // — "a per-point style beyond a colour and size override" — would state
      // the exact opposite of the input. A refusal pinned to a reason that
      // describes the wrong thing sends a Workbench reader hunting for an
      // override that is not there.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              DonutChartSeries(
                id: 'donut',
                points: const <ChartDataPoint>[
                  ChartDataPoint(
                    x: 0,
                    y: 3,
                    label: 'A',
                    pointStyle: PointStyle(),
                  ),
                  ChartDataPoint(x: 1, y: 5, label: 'B'),
                ],
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isFalse);
      expect(generated.isComplete, isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('does not reproduce series "donut" exactly'),
          contains('a point whose PointStyle sets NO override at all'),
          contains('an override-less style reverses to no style'),
        ),
      );
      expect(
        blockedReason(generated),
        isNot(contains('a per-point style beyond')),
      );
    });

    testWidgets('a donut MIXING colour-only and size-only points never reaches '
        'the emitter — the series itself refuses it', (tester) async {
      // This slice's design predicted an EMITTER-level surprise here: the
      // radius field is allocated on ANY point that has a size and the row fill
      // synthesises 0 for the sizeless ones, so a colour-only point would
      // re-lower with `size: 0.0` where the capture had null and be refused by
      // the round-trip proof.
      //
      // Probing it showed the shape is UNREACHABLE.
      // `validateRadialConfiguration` requires all-or-nothing sizing — one
      // sized point obliges a `sliceRadiusConfig` AND a finite size on EVERY
      // point — so the mixture is rejected a layer lower, and more strictly.
      // Pinned at the layer that actually enforces it, with both doors tried,
      // so a later relaxation of the series guard surfaces here rather than as
      // a `size: 0.0` chart the emitter quietly hands back.
      const mixed = <ChartDataPoint>[
        ChartDataPoint(
          x: 0,
          y: 3,
          label: 'A',
          pointStyle: PointStyle(size: 10),
        ),
        ChartDataPoint(
          x: 1,
          y: 5,
          label: 'B',
          pointStyle: PointStyle(color: Color(0xFF112233)),
        ),
      ];
      expect(
        () => DonutChartSeries(id: 'donut', points: mixed),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('one PointStyle.size value for every point'),
          ),
        ),
      );
      expect(
        () => DonutChartSeries(
          id: 'donut',
          points: mixed,
          sliceRadiusConfig: const RadialSliceRadiusConfig(),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('must be finite and non-negative'),
          ),
        ),
      );

      // The REACHABLE neighbour: every point sized, only SOME coloured. Both
      // channels reverse onto their own row field, and the uncoloured slice
      // writes a null colour beside a real radius — the mixed state that IS
      // expressible.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              DonutChartSeries.fromMap(
                id: 'donut',
                values: const <String, num>{'A': 3, 'B': 5},
                radiusValues: const <String, num>{'A': 10, 'B': 4},
                sliceColors: const <String, Color>{'B': Color(0xFF112233)},
              ),
            ],
          ),
        ),
      );
      expect(emittedChain(generated), isTrue);
      expect(generated.source, contains('radius: (row) => row.radius,'));
      expect(
        generated.source,
        contains('sliceColor: (row) => row.sliceColor,'),
      );
      expect('sliceColor: null,'.allMatches(generated.source).length, 1);
    });

    testWidgets('a pie series carrying metadata is refused too — the proof '
        'guards the non-polar radial path as well', (tester) async {
      // The polar cases above reach the proof through `_tryEmitPolarChain`;
      // pie reaches it through `_tryEmitRadialChain`. Both call sites must
      // refuse, or half the radial families keep an unguarded emitter.
      Future<ChartGeneratedSource> generateFor(
        Map<String, dynamic>? metadata,
      ) async => generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChartPlus(
            bravenChartController: controller,
            series: <ChartSeries>[
              PieChartSeries.fromMap(
                id: 'harvest',
                values: const <String, num>{'Apple': 42, 'Pear': 31},
                metadata: metadata,
              ),
            ],
          ),
        ),
      );

      final refused = await generateFor(const <String, dynamic>{
        'sport': 'cycling',
      });
      expect(emittedChain(refused), isFalse);
      expect(refused.isComplete, isFalse);
      expect(refused.source, isNot(contains('.geomPie(')));
      expect(
        refused.warnings.single.code,
        ChartGrammarSourceWarningCodes.unsupportedShape,
      );
      expect(
        blockedReason(refused),
        allOf(
          contains('does not reproduce series "harvest" exactly'),
          contains('series metadata'),
        ),
      );

      // CONTROL: the same pie without metadata emits.
      final emitted = await generateFor(null);
      expect(emittedChain(emitted), isTrue);
      expect(emitted.warnings, isEmpty);
      expect(emitted.source, contains('.geomPie('));
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

    testWidgets('includeDefaultValues spells the donut centre out in full, and '
        'the default OFF state writes only what differs', (tester) async {
      // The centre argument is now written by the config emitter's own renderer,
      // so it honours `includeDefaultValues` the way every other config literal
      // does — where the grammar's old private renderer ignored the flag and
      // wrote the visibility/value-mode pair only when they differed. That is
      // the intended consequence of sharing one renderer, so it is pinned
      // rather than left to be rediscovered as a surprise, together with the
      // OFF state that every other test in this file relies on.
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'donut-verbose',
              values: const <String, num>{'Apple': 42, 'Pear': 31},
              centerContent: const DonutCenterContent(label: 'Total'),
            ),
          ],
        ),
      );

      final terse = generateGrammar(snapshot);
      expect(terse.source, contains('center: DonutCenterContent('));
      expect(terse.source, isNot(contains('isVisible:')));
      expect(terse.source, isNot(contains('valueMode:')));

      final verbose = generateGrammar(
        snapshot,
        options: const ChartGrammarSourceOptions(
          variableName: 'grammarChart',
          includeDefaultValues: true,
        ),
      );
      expect(verbose.source, contains('isVisible: true,'));
      expect(
        verbose.source,
        contains('valueMode: DonutCenterValueMode.total,'),
      );
      // `includeDefaultValues` changes the `center:` literal, and no round-trip
      // harness covers this option — so the widened centre is put through the
      // same `dart format` + `dart analyze` gate `expectRoundTrip` uses, in
      // both states.
      await tester.runAsync(() async {
        await expectGeneratedSourceCompiles(
          terse.source,
          fixtureName: 'grammar_source_donut_centre_terse',
        );
        await expectGeneratedSourceCompiles(
          verbose.source,
          fixtureName: 'grammar_source_donut_centre_verbose',
        );
      });
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
