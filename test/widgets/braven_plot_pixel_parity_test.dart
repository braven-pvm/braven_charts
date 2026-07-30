// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// PIXEL parity for the grammar layer — the gate `braven_plot_artifact_parity_test.dart`
/// cannot be.
///
/// That file compares chart DOCUMENTS, and document equality turned out to be
/// necessary but not sufficient: two charts with byte-identical documents were
/// found rendering different pixels, because the document does not carry every
/// input the render path reads. So the claim this file makes is the one the
/// Source pane actually sells:
///
/// > mount a chart the way a config author writes it, reverse it with
/// > [ChartGrammarSourceGenerator], and the chain that comes back DRAWS THE
/// > SAME IMAGE.
///
/// Each shape runs four steps, and the order matters:
///
/// 1. the config chart is mounted and reversed, and the generator must emit a
///    clean, complete chain — otherwise there is no fidelity claim to test;
/// 2. the emitted TEXT must contain the axis literal the rebuilt chain below
///    spells out, so the chain in this file is provably the chain the emitter
///    writes and not a convenient hand-tuning of it;
/// 3. the rebuilt chain must extract an EQUAL document (the old gate, kept); and
/// 4. the two must rasterise to IDENTICAL bytes at a fixed 600x400 host.
///
/// Two controls keep step 4 honest. The determinism control renders one widget
/// twice and requires 0 differing pixels, so a non-zero count anywhere else is
/// a real difference and not renderer noise. And the `inline mount` control
/// requires the OTHER mount to differ, so the zeroes are not vacuous — the
/// mounts genuinely draw different charts and the chain has to pick the right
/// one.
///
/// ## Why every config fixture spells its theme out
///
/// Every fixture below passes `theme: ChartTheme.light` because the emitter
/// always writes `.theme(ChartTheme.light)`, and a chart that left its theme
/// UNSET does not render like one that set it to light: `BravenChartPlus`
/// resolves `widget.theme ?? ChartTheme.light` nearly everywhere, but the
/// legend reads `widget.legendStyle ?? widget.theme?.legendStyle ?? const
/// LegendStyle()` (`braven_chart_plus.dart`), so a null theme silently takes a
/// different legend style. That is a real divergence, it is NOT this file's
/// subject — it is a config-widget defect that reaches grammar and config
/// charts alike — and it is pinned by name in the last test so it cannot rot
/// unnoticed. Spelling the theme out keeps the five shapes measuring the axis
/// MOUNT, which is what they are for.
///
/// A golden cannot do this job: every grammar golden runs at a 3.5%
/// cross-platform antialiasing tolerance, and both defects this file pins sat
/// under it — the axis recolour measures 1.5% to 2.2% of the frame and is
/// confined to the Y-label gutter. Two images produced in the same test at the same size are
/// exactly comparable, so equality is asserted on the bytes.
library;

import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

// ===========================================================================
// Fixture
// ===========================================================================

class Row {
  const Row({required this.t, required this.power, required this.heartRate});

  final double t;
  final double power;
  final double heartRate;
}

double rowT(Row row) => row.t;
double rowPower(Row row) => row.power;
double rowHeartRate(Row row) => row.heartRate;

const rows = <Row>[
  Row(t: 0, power: 180, heartRate: 120),
  Row(t: 1, power: 220, heartRate: 140),
  Row(t: 2, power: 260, heartRate: 165),
];

const powerPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 180),
  ChartDataPoint(x: 1, y: 220),
  ChartDataPoint(x: 2, y: 260),
];

const heartRatePoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 120),
  ChartDataPoint(x: 1, y: 140),
  ChartDataPoint(x: 2, y: 165),
];

const powerColor = Color(0xFF2563EB);
const heartRateColor = Color(0xFFDC2626);

/// The host every image in this file is captured at.
const hostWidth = 600.0;
const hostHeight = 400.0;

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: hostWidth, height: hostHeight, child: child),
    ),
  ),
);

// ===========================================================================
// Instrument
// ===========================================================================

/// The raw RGBA of [chart] rendered at the fixed host size.
Future<Uint8List> renderBytes(
  WidgetTester tester,
  String probe,
  Widget chart,
) async {
  final key = ValueKey<String>(probe);
  await tester.pumpWidget(host(RepaintBoundary(key: key, child: chart)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  // `toImage` is REAL async — it never completes inside a widget test's
  // fake-async zone — so it has to run through `runAsync`, the same escape
  // hatch `matchesGoldenFile` uses.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

/// Differing-pixel counts between two frames of the same size.
///
/// [gutter] counts the differing pixels in the left 80 logical columns — the
/// Y-axis label gutter — because the two defects this file pins are told apart
/// by WHERE they land: an axis recolour is gutter-only, while a moved Y domain
/// spills across the plot area.
({int total, int gutter}) pixelDiff(Uint8List a, Uint8List b) {
  expect(a.length, b.length, reason: 'frames must be the same size');
  const gutterColumns = 80;
  var total = 0;
  var gutter = 0;
  for (var i = 0; i + 3 < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      total++;
      if ((i ~/ 4) % hostWidth.toInt() < gutterColumns) gutter++;
    }
  }
  return (total: total, gutter: gutter);
}

String describeDiff(({int total, int gutter}) diff, int frameBytes) =>
    '${diff.total} of ${frameBytes ~/ 4} pixels differ '
    '(${diff.gutter} in the Y-label gutter, '
    '${diff.total - diff.gutter} outside it)';

// ===========================================================================
// Harness
// ===========================================================================

Future<ChartDocumentSnapshot> snapshotOf(
  WidgetTester tester,
  Widget Function(BravenChartController controller) child,
) async {
  final controller = BravenChartController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(host(child(controller)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final result = controller.extractDocument();
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

ChartGeneratedSource generateGrammar(ChartDocumentSnapshot snapshot) {
  final result = ChartGrammarSourceGenerator.generate(
    snapshot,
    options: const ChartGrammarSourceOptions(variableName: 'grammarChart'),
  );
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

/// Runs one shape: reverse [config], prove [chain] is what the emitter wrote,
/// and require the two to draw the same image.
Future<void> expectPixelParity(
  WidgetTester tester, {
  required String name,
  required Widget Function(BravenChartController?) config,
  required Widget Function(BravenChartController?) chain,
  required Iterable<String> fragments,
}) async {
  final snapshot = await snapshotOf(tester, config);
  final generated = generateGrammar(snapshot);
  expect(
    generated.warnings,
    isEmpty,
    reason:
        'shape "$name" must emit a clean chain, otherwise there is no '
        'fidelity claim to test:\n'
        '${generated.warnings.map((warning) => warning.message).join('\n')}',
  );
  expect(generated.isComplete, isTrue);
  for (final fragment in fragments) {
    expect(
      generated.source,
      contains(fragment),
      reason:
          'the chain rebuilt below is meant to BE the emitted chain, but the '
          'emitter did not write "$fragment":\n${generated.source}',
    );
  }

  final rebuilt = await snapshotOf(tester, chain);
  expect(
    rebuilt.document.toJson(),
    snapshot.document.toJson(),
    reason: 'shape "$name": the rebuilt chain produced a different document',
  );

  final configBytes = await renderBytes(tester, '$name-config', config(null));
  final chainBytes = await renderBytes(tester, '$name-chain', chain(null));
  final diff = pixelDiff(configBytes, chainBytes);
  expect(
    diff.total,
    0,
    reason:
        'shape "$name": the emitted chain renders a DIFFERENT chart from the '
        'one it was reversed from — ${describeDiff(diff, configBytes.length)}',
  );
}

/// Runs one AUTHORED shape: a hand-written spec against the config chart it
/// claims to be. No emitter is involved, so there is no chain to prove and no
/// document to compare — the claim is the image.
Future<void> expectAuthoredParity(
  WidgetTester tester, {
  required String name,
  required Widget Function(BravenChartController?) authored,
  required Widget Function(BravenChartController?) config,
}) async {
  final authoredBytes = await renderBytes(
    tester,
    '$name-authored',
    authored(null),
  );
  final configBytes = await renderBytes(tester, '$name-config', config(null));
  final diff = pixelDiff(authoredBytes, configBytes);
  expect(
    diff.total,
    0,
    reason:
        'shape "$name": the authored spec draws a DIFFERENT chart from the '
        'config chart it lowers to — '
        '${describeDiff(diff, configBytes.length)}',
  );
}

// ===========================================================================
// Shapes
// ===========================================================================

/// (a) One series, no widget-level `yAxis` at all.
Widget shapeAConfig(BravenChartController? controller) => BravenChartPlus(
  bravenChartController: controller,
  theme: ChartTheme.light,
  series: const <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerPoints,
      color: powerColor,
    ),
  ],
);

Widget shapeAChain(BravenChartController? controller) => BravenChart.of(rows)
    .x(rowT)
    .yAxis(YAxisConfig.withId(id: 'y', position: YAxisPosition.left))
    .geomLine(
      id: 'power',
      y: rowPower,
      name: 'Power',
      color: powerColor,
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .theme(ChartTheme.light)
    .build(bravenChartController: controller);

/// (b) A widget-level axis carrying a LABEL but no min/max.
Widget shapeBConfig(BravenChartController? controller) => BravenChartPlus(
  bravenChartController: controller,
  theme: ChartTheme.light,
  yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
  series: const <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerPoints,
      color: powerColor,
    ),
  ],
);

Widget shapeBChain(BravenChartController? controller) => BravenChart.of(rows)
    .x(rowT)
    .yAxis(
      YAxisConfig.withId(id: 'y', position: YAxisPosition.left, label: 'Power'),
    )
    .geomLine(
      id: 'power',
      y: rowPower,
      name: 'Power',
      color: powerColor,
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .theme(ChartTheme.light)
    .build(bravenChartController: controller);

/// (c) A widget-level axis declaring min AND max.
Widget shapeCConfig(BravenChartController? controller) => BravenChartPlus(
  bravenChartController: controller,
  theme: ChartTheme.light,
  yAxis: YAxisConfig(
    position: YAxisPosition.left,
    label: 'Power',
    min: 100,
    max: 300,
  ),
  series: const <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerPoints,
      color: powerColor,
    ),
  ],
);

Widget shapeCChain(BravenChartController? controller) => BravenChart.of(rows)
    .x(rowT)
    .yAxis(
      YAxisConfig.withId(
        id: 'y',
        position: YAxisPosition.left,
        label: 'Power',
        min: 100.0,
        max: 300.0,
      ),
    )
    .geomLine(
      id: 'power',
      y: rowPower,
      name: 'Power',
      color: powerColor,
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .theme(ChartTheme.light)
    .build(bravenChartController: controller);

/// (d) Two marks on two axes — the mount this slice must not touch.
List<ChartSeries> multiAxisSeries() => <ChartSeries>[
  LineChartSeries(
    id: 'power',
    name: 'Power',
    points: powerPoints,
    color: powerColor,
    yAxisId: 'watts',
    yAxisConfig: YAxisConfig.withId(
      id: 'watts',
      position: YAxisPosition.left,
      label: 'W',
    ),
  ),
  LineChartSeries(
    id: 'hr',
    name: 'Heart rate',
    points: heartRatePoints,
    color: heartRateColor,
    yAxisId: 'bpm',
    yAxisConfig: YAxisConfig.withId(
      id: 'bpm',
      position: YAxisPosition.right,
      label: 'bpm',
    ),
  ),
];

Widget shapeDConfig(BravenChartController? controller) => BravenChartPlus(
  bravenChartController: controller,
  theme: ChartTheme.light,
  series: multiAxisSeries(),
);

Widget shapeDChain(BravenChartController? controller) => BravenChart.of(rows)
    .x(rowT)
    .yAxis(
      YAxisConfig.withId(id: 'watts', position: YAxisPosition.left, label: 'W'),
    )
    .yAxis(
      YAxisConfig.withId(
        id: 'bpm',
        position: YAxisPosition.right,
        label: 'bpm',
      ),
    )
    .geomLine(
      id: 'power',
      y: rowPower,
      name: 'Power',
      color: powerColor,
      yAxisId: 'watts',
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .geomLine(
      id: 'hr',
      y: rowHeartRate,
      name: 'Heart rate',
      color: heartRateColor,
      yAxisId: 'bpm',
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .theme(ChartTheme.light)
    .build(bravenChartController: controller);

/// (e) A widget-level axis the author NAMED. The name survives the round trip,
/// so this is the case the `id: 'y'` fallback must not swallow.
Widget shapeEConfig(BravenChartController? controller) => BravenChartPlus(
  bravenChartController: controller,
  theme: ChartTheme.light,
  yAxis: YAxisConfig.withId(
    id: 'watts',
    position: YAxisPosition.left,
    label: 'Power',
  ),
  series: const <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerPoints,
      color: powerColor,
    ),
  ],
);

// ---------------------------------------------------------------------------
// The AUTHORED shapes: the plot a human writes, not one the emitter wrote.
//
// Shapes (a)-(e) all enter through the emitter, so every axis they mount
// carries the id EXTRACTION stamps (`'y'`) or one the author named. A hand-
// written `PlotSpec` carries neither: `PlotSpecLowering` stamps `'axis-$index'`
// on an axis that declares no id — including the axis it invents for a spec
// with no `yAxes` at all, which is what almost every grammar chart is. That id
// is the third value the mount can see, and no round-trip fixture can produce
// it.
// ---------------------------------------------------------------------------

/// (f) The plainest grammar chart there is: one mark, no axis declared.
Widget authoredNoAxis(BravenChartController? controller) => BravenPlot<Row>(
  PlotSpec<Row>(
    data: rows,
    theme: ChartTheme.light,
    marks: <Mark<Row>>[
      LineMark<Row>(
        x: rowT,
        y: rowPower,
        id: 'power',
        name: 'Power',
        color: powerColor,
      ),
    ],
  ),
  bravenChartController: controller,
);

/// (g) The same chart with an ordinary `YAxisConfig` — the constructor that
/// takes no id, which is what a spec author actually writes.
Widget authoredOrdinaryAxis(BravenChartController? controller) =>
    BravenPlot<Row>(
      PlotSpec<Row>(
        data: rows,
        theme: ChartTheme.light,
        yAxes: <YAxisConfig>[
          YAxisConfig(position: YAxisPosition.left, label: 'Power'),
        ],
        marks: <Mark<Row>>[
          LineMark<Row>(
            x: rowT,
            y: rowPower,
            id: 'power',
            name: 'Power',
            color: powerColor,
          ),
        ],
      ),
      bravenChartController: controller,
    );

/// (h) The same chart with an axis the author NAMED.
Widget authoredNamedAxis(BravenChartController? controller) => BravenPlot<Row>(
  PlotSpec<Row>(
    data: rows,
    theme: ChartTheme.light,
    yAxes: <YAxisConfig>[
      YAxisConfig.withId(
        id: 'watts',
        position: YAxisPosition.left,
        label: 'Power',
      ),
    ],
    marks: <Mark<Row>>[
      LineMark<Row>(
        x: rowT,
        y: rowPower,
        id: 'power',
        name: 'Power',
        color: powerColor,
      ),
    ],
  ),
  bravenChartController: controller,
);

Widget shapeEChain(BravenChartController? controller) => BravenChart.of(rows)
    .x(rowT)
    .yAxis(
      YAxisConfig.withId(
        id: 'watts',
        position: YAxisPosition.left,
        label: 'Power',
      ),
    )
    .geomLine(
      id: 'power',
      y: rowPower,
      name: 'Power',
      color: powerColor,
      strokeWidth: 2.0,
      dashPattern: const <double>[],
      interpolation: LineInterpolation.linear,
    )
    .theme(ChartTheme.light)
    .build(bravenChartController: controller);

void main() {
  testWidgets('control: the instrument reads 0 on the same widget twice', (
    tester,
  ) async {
    // Without this every zero below is unfalsifiable — a comparison that
    // always returns 0 would look exactly like perfect fidelity.
    final first = await renderBytes(
      tester,
      'determinism-1',
      shapeBConfig(null),
    );
    final second = await renderBytes(
      tester,
      'determinism-2',
      shapeBConfig(null),
    );
    final diff = pixelDiff(first, second);
    expect(
      diff.total,
      0,
      reason:
          'the renderer is not deterministic across two pumps, so no pixel '
          'count in this file can be trusted: '
          '${describeDiff(diff, first.length)}',
    );
  });

  testWidgets('control: the OTHER mount really does draw a different chart', (
    tester,
  ) async {
    // The zeroes below are only meaningful if the mount decision is
    // observable. Same axis, same series, delivered as an INLINE
    // `yAxisConfig` instead of a widget-level `yAxis`: the inline path never
    // applies `min`/`max` to the Y domain, so the whole plot area moves.
    // Measured at 25,885 of 240,000 pixels, 20,770 of them OUTSIDE the label
    // gutter — the divergence a mount that guessed wrong would ship silently,
    // and the exact cost of declining the legacy mount for a min/max axis
    // (see `_legacySingleAxisSeries`).
    final widgetLevel = await renderBytes(
      tester,
      'mount-widget-level',
      shapeCConfig(null),
    );
    final inline = await renderBytes(
      tester,
      'mount-inline',
      BravenChartPlus(
        series: <ChartSeries>[
          LineChartSeries(
            id: 'power',
            name: 'Power',
            points: powerPoints,
            color: powerColor,
            yAxisId: 'y',
            yAxisConfig: YAxisConfig.withId(
              id: 'y',
              position: YAxisPosition.left,
              label: 'Power',
              min: 100,
              max: 300,
            ),
          ),
        ],
      ),
    );
    final diff = pixelDiff(widgetLevel, inline);
    expect(
      diff.total,
      greaterThan(20000),
      reason:
          'the two mounts are supposed to render different charts; if they '
          'no longer do, every parity assertion in this file has stopped '
          'discriminating: ${describeDiff(diff, widgetLevel.length)}',
    );
    expect(
      diff.total - diff.gutter,
      greaterThan(15000),
      reason:
          'the min/max divergence must land in the PLOT AREA, not just the '
          'label gutter: ${describeDiff(diff, widgetLevel.length)}',
    );
  });

  testWidgets('(a) one series, no widget-level yAxis', (tester) async {
    await expectPixelParity(
      tester,
      name: 'a',
      config: shapeAConfig,
      chain: shapeAChain,
      fragments: const <String>["id: 'y',", 'position: YAxisPosition.left,'],
    );
  });

  testWidgets('(b) a widget-level yAxis with a label, no min/max', (
    tester,
  ) async {
    await expectPixelParity(
      tester,
      name: 'b',
      config: shapeBConfig,
      chain: shapeBChain,
      fragments: const <String>["id: 'y',", "label: 'Power',"],
    );
  });

  testWidgets('(c) a widget-level yAxis declaring min AND max', (tester) async {
    await expectPixelParity(
      tester,
      name: 'c',
      config: shapeCConfig,
      chain: shapeCChain,
      fragments: const <String>["id: 'y',", 'min: 100.0,', 'max: 300.0,'],
    );
  });

  testWidgets(
    '(d) two marks on two axes — unchanged by the single-axis mount',
    (tester) async {
      await expectPixelParity(
        tester,
        name: 'd',
        config: shapeDConfig,
        chain: shapeDChain,
        fragments: const <String>[
          "id: 'watts',",
          "id: 'bpm',",
          "yAxisId: 'watts',",
          "yAxisId: 'bpm',",
        ],
      );
    },
  );

  testWidgets('(e) a widget-level yAxis the author NAMED', (tester) async {
    await expectPixelParity(
      tester,
      name: 'e',
      config: shapeEConfig,
      chain: shapeEChain,
      fragments: const <String>["id: 'watts',", "label: 'Power',"],
    );
  });

  // =========================================================================
  // The authored path
  //
  // Same instrument, different claim: a hand-written `PlotSpec` must draw the
  // chart a config author would have written by hand. Nothing above tests it —
  // every chain in (a)-(e) came back from the emitter carrying the id
  // extraction stamps, while lowering stamps `'axis-$index'` on a spec that
  // names no axis, which is the shape almost every grammar chart really is.
  //
  // The pixels here are the axis TINT. The dangling binding also sent
  // `computeAxisBounds` to its `0..100` no-data fallback for the chart's only
  // axis, and that does NOT show up in these frames — at paint time the render
  // box passes a non-null transform, whose Y range wins over the per-axis
  // computation. That half is gated where it is observable, in
  // `multi_axis_manager_test.dart`.
  // =========================================================================

  testWidgets('(f) an authored plot that declares no axis at all', (
    tester,
  ) async {
    await expectAuthoredParity(
      tester,
      name: 'f',
      authored: authoredNoAxis,
      config: shapeAConfig,
    );
  });

  testWidgets('(g) an authored plot with an ordinary YAxisConfig', (
    tester,
  ) async {
    await expectAuthoredParity(
      tester,
      name: 'g',
      authored: authoredOrdinaryAxis,
      config: shapeBConfig,
    );
  });

  testWidgets('(h) an authored plot with an axis the author NAMED', (
    tester,
  ) async {
    await expectAuthoredParity(
      tester,
      name: 'h',
      authored: authoredNamedAxis,
      config: shapeEConfig,
    );
  });

  testWidgets('control: an axis with NOTHING bound to it still draws grey', (
    tester,
  ) async {
    // The three zeroes above are only meaningful if a dangling binding is
    // visible at all. Same axis, same series, but the series names an axis
    // that does not exist — so nothing is bound to the chart's only axis and
    // `AxisColorResolver` falls back to its `#333333` grey instead of the
    // series colour. This is the recolour shapes (f) and (g) used to exhibit,
    // and it is still reachable: binding an unbound series to the widget-level
    // axis does not rehome a series that named a different one.
    final bound = await renderBytes(tester, 'bound-axis', shapeBConfig(null));
    final dangling = await renderBytes(
      tester,
      'dangling-axis',
      BravenChartPlus(
        theme: ChartTheme.light,
        yAxis: YAxisConfig(position: YAxisPosition.left, label: 'Power'),
        series: const <ChartSeries>[
          LineChartSeries(
            id: 'power',
            name: 'Power',
            points: powerPoints,
            color: powerColor,
            yAxisId: 'an-axis-this-chart-does-not-have',
          ),
        ],
      ),
    );
    final diff = pixelDiff(bound, dangling);
    expect(
      diff.total,
      greaterThan(4000),
      reason:
          'a dangling binding is supposed to be visible; if it is not, the '
          'authored-path zeroes above have stopped discriminating: '
          '${describeDiff(diff, bound.length)}',
    );
  });

  testWidgets('KNOWN GAP: an UNSET theme does not render like ChartTheme.light', (
    tester,
  ) async {
    // Not an axis-mount defect and not fixed here — but it is the reason every
    // fixture above spells its theme out, so it is pinned rather than left as
    // a sentence in a doc comment.
    //
    // `BravenChartPlus` resolves `widget.theme ?? ChartTheme.light` almost
    // everywhere, but the legend takes `widget.legendStyle ??
    // widget.theme?.legendStyle ?? const LegendStyle()`, so a null theme falls
    // through to a DIFFERENT legend style. Measured at 4,660 of 240,000
    // pixels on the two-series chart below, concentrated in the legend.
    //
    // Why it matters beyond this file: extraction records the resolved theme
    // (`widget.theme ?? ChartTheme.light`), so a chart that never set a theme
    // reverses to a chain that says `.theme(ChartTheme.light)` — and that
    // chain draws the legend differently from the chart it came from. Both
    // source forms are affected; the config emitter names the same theme.
    //
    // WHEN THIS TEST GOES RED because the counts hit zero: the gap has been
    // closed. Delete this test and drop the explicit `theme:` from the
    // fixtures above.
    final unset = await renderBytes(
      tester,
      'theme-unset',
      BravenChartPlus(series: multiAxisSeries()),
    );
    final light = await renderBytes(
      tester,
      'theme-light',
      BravenChartPlus(theme: ChartTheme.light, series: multiAxisSeries()),
    );
    final diff = pixelDiff(unset, light);
    expect(
      diff.total,
      greaterThan(0),
      reason:
          'an unset theme now renders exactly like ChartTheme.light — the '
          'known gap is closed, so retire this test and the explicit themes '
          'in the fixtures above: ${describeDiff(diff, unset.length)}',
    );
  });
}
