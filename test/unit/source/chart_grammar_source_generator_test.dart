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
  });

  group('fidelity matrix diagnostics', () {
    testWidgets('a non-Cartesian family is named, and no chain is emitted', (
      tester,
    ) async {
      final snapshot = await snapshotOf(
        tester,
        (controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            PieChartSeries(
              id: 'split',
              points: const <ChartDataPoint>[
                ChartDataPoint(x: 0, y: 3, label: 'A'),
                ChartDataPoint(x: 1, y: 5, label: 'B'),
              ],
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
          contains('Cartesian-only in V1'),
          contains('PieChartSeries'),
          contains('split'),
        ),
      );
      expect(generated.source, contains('Cartesian-only in V1'));
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
            ThresholdAnnotation(id: 'ftp', value: 1.5, axis: AnnotationAxis.y),
          ],
        ),
      );
      final generated = generateGrammar(snapshot);
      expect(emittedChain(generated), isFalse);
      expect(
        blockedReason(generated),
        allOf(
          contains('TrendAnnotation only'),
          contains('ThresholdAnnotation'),
          contains('ftp'),
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
      expect(
        blockedReason(generated),
        allOf(contains('does not reproduce'), contains('power')),
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
