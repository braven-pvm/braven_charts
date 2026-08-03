// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The Workbench Source pane's Config / Grammar toggle.
///
/// The contract:
///
/// * both forms are offered on EVERY chart, by the package rather than by a
///   host page;
/// * switching form re-emits from the snapshot already held — it never
///   re-extracts the chart, so staleness keeps meaning "the chart moved on";
/// * the config form is byte-for-byte what it always was, keys included;
/// * a chart the chain cannot express shows its named diagnostic in the
///   Grammar form instead of code.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.t, required this.power});

  final double t;
  final double power;
}

double sampleT(Sample row) => row.t;
double samplePower(Sample row) => row.power;

const rows = <Sample>[
  Sample(t: 0, power: 168),
  Sample(t: 1, power: 204),
  Sample(t: 2, power: 268),
];

Widget host({
  required ChartWorkbenchController workbenchController,
  ChartSourceForm initialSourceForm = ChartSourceForm.config,
  BravenChartBuilder? chartBuilder,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 1000,
        height: 560,
        child: BravenChartWorkbench(
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          initialSourceForm: initialSourceForm,
          sourceOptions: const ChartDartSourceOptions(
            variableName: 'grammarChart',
          ),
          grammarSourceOptions: const ChartGrammarSourceOptions(
            variableName: 'grammarChart',
          ),
          chartBuilder:
              chartBuilder ??
              (context, controller) => BravenChart.of(rows)
                  .x(sampleT, label: 'Elapsed')
                  .y(samplePower, label: 'Power')
                  .geomLine(name: 'Power')
                  .build(bravenChartController: controller),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the pane opens on Config with the original keys', (
    tester,
  ) async {
    final workbench = ChartWorkbenchController();
    addTearDown(workbench.dispose);

    await tester.pumpWidget(host(workbenchController: workbench));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chart-source-form-toggle')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-source-dark-window')),
      findsOneWidget,
    );
    expect(workbench.sourceForm, ChartSourceForm.config);
    expect(workbench.sourceState.form, ChartSourceForm.config);
    expect(workbench.generatedSource?.source, contains('BravenChartPlus('));
  });

  testWidgets('Grammar emits the chain and keeps the same snapshot', (
    tester,
  ) async {
    final workbench = ChartWorkbenchController();
    addTearDown(workbench.dispose);

    await tester.pumpWidget(host(workbenchController: workbench));
    await tester.pumpAndSettle();

    final configSource = workbench.generatedSource!.source;
    final snapshot = workbench.sourceState.snapshot;
    expect(snapshot, isNotNull);

    await tester.tap(find.text('Grammar'));
    await tester.pumpAndSettle();

    expect(workbench.sourceForm, ChartSourceForm.grammar);
    expect(workbench.sourceState.form, ChartSourceForm.grammar);
    // The same captured document, read a second way — not a second extraction.
    expect(workbench.sourceState.snapshot, same(snapshot));
    expect(
      workbench.generatedSource?.source,
      contains('= BravenChart.of(rows)'),
    );
    expect(workbench.generatedSource?.source, contains('class GrammarRow {'));
    expect(
      find.byKey(const ValueKey('chart-grammar-source-code')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chart-source-code')), findsNothing);

    await tester.tap(find.text('Config'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chart-source-code')), findsOneWidget);
    // The config form is untouched by the round trip through Grammar.
    expect(workbench.generatedSource?.source, configSource);
  });

  testWidgets('the pane can open directly on the Grammar form', (tester) async {
    final workbench = ChartWorkbenchController();
    addTearDown(workbench.dispose);

    await tester.pumpWidget(
      host(
        workbenchController: workbench,
        initialSourceForm: ChartSourceForm.grammar,
      ),
    );
    await tester.pumpAndSettle();

    expect(workbench.sourceState.form, ChartSourceForm.grammar);
    expect(
      find.byKey(const ValueKey('chart-grammar-source-code')),
      findsOneWidget,
    );
  });

  testWidgets('a chart the chain cannot express shows its diagnostic', (
    tester,
  ) async {
    final workbench = ChartWorkbenchController();
    addTearDown(workbench.dispose);

    await tester.pumpWidget(
      host(
        workbenchController: workbench,
        // Radial-bar has no grammar geometry (pie/donut/polar now DO emit), so
        // it is the family that still shows the "not emitted" diagnostic — with
        // an accurate reason, not the stale "Cartesian-only V1" copy.
        chartBuilder: (context, controller) => BravenChartPlus(
          bravenChartController: controller,
          series: <ChartSeries>[
            RadialBarChartSeries.fromMap(
              id: 'split',
              values: const <String, num>{'A': 3, 'B': 5},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grammar'));
    await tester.pumpAndSettle();

    final source = workbench.generatedSource!.source;
    expect(source, isNot(contains('= BravenChart.of(')));
    expect(source, isNot(contains('Cartesian-only in V1')));
    // Range area LEFT this list with `geomRangeArea`, so a reason that still
    // named it would be the same stale copy the line above guards against.
    expect(source, contains('radial-bar or gauge'));
    expect(source, isNot(contains('or range-area family has no mark')));
    expect(source, contains('RadialBarChartSeries'));
    expect(
      workbench.generatedSource!.completeness,
      ChartGeneratedSourceCompleteness.portableWithPlaceholders,
    );
  });
}
