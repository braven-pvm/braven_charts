// Copyright 2026 Braven Charts - Chart Grammar Page tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() =>
      const MaterialApp(home: Scaffold(body: ChartGrammarPage()));

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
  }

  Future<void> revealOption(
    WidgetTester tester,
    Finder target, {
    double delta = 120,
  }) async {
    final optionsScrollable = find
        .descendant(
          of: find.byType(OptionsPanel),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      target,
      delta,
      scrollable: optionsScrollable,
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectPreset(WidgetTester tester, String preset) async {
    await tester.tap(find.byKey(ValueKey('chart-grammar-preset-$preset')));
    await tester.pumpAndSettle();
  }

  // Order matches the enum: barTransposed stays LAST so the sweep never
  // animates out of a horizontal-bar chart into a Cartesian one (the chart's
  // retained-bar-exit bounds check requires an all-horizontal transition set).
  const presets = <String>[
    'lineTrend',
    'multiAxis',
    'scatterChannels',
    'candlestick',
    'referenceLines',
    'barTransposed',
  ];

  BravenPlot<GrammarSample> plot(WidgetTester tester) =>
      tester.widget<BravenPlot<GrammarSample>>(
        find.byType(BravenPlot<GrammarSample>),
      );

  testWidgets('builds with the line-and-trend preset authored by the facade', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Chart Grammar'), findsOneWidget);
    for (final preset in presets) {
      expect(
        find.byKey(ValueKey('chart-grammar-preset-$preset')),
        findsOneWidget,
      );
    }
    expect(find.text('A line with a fitted trend'), findsOneWidget);

    // The spec side is a BravenPlot — there is no hand-written chart mounted
    // until the compare toggle asks for one.
    expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);
    final spec = plot(tester).spec;
    expect(spec.marks, hasLength(2));
    expect(spec.marks.first, isA<LineMark<GrammarSample>>());
    expect(spec.marks.last, isA<TrendMark<GrammarSample>>());
    expect(
      (spec.marks.last as TrendMark<GrammarSample>).sourceMarkId,
      'mark-0',
      reason: 'trend() defaults its source to the preceding geometry',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('every preset switch rebuilds the spec from the facade chain', (
    tester,
  ) async {
    await pumpPage(tester);

    // Multi-axis: two declared axis slots, each geometry bound by id.
    await selectPreset(tester, 'multiAxis');
    expect(find.text('Two measures, two declared axes'), findsOneWidget);
    var spec = plot(tester).spec;
    expect(spec.yAxes.map((axis) => axis.id), <String>['watts', 'bpm']);
    expect(spec.marks.map((mark) => mark.yAxisId), <String>['watts', 'bpm']);
    expect(spec.marks.first, isA<AreaMark<GrammarSample>>());
    expect(spec.marks.last, isA<LineMark<GrammarSample>>());

    // Scatter: the size and category channels with their templates.
    await selectPreset(tester, 'scatterChannels');
    expect(find.text('Scale-driven scatter channels'), findsOneWidget);
    final scatter =
        plot(tester).spec.marks.single as ScatterMark<GrammarSample>;
    expect(scatter.size, isNotNull);
    expect(scatter.size!.label, 'Effort');
    expect(scatter.categoryBy, isNotNull);
    expect(scatter.categories, hasLength(3));

    // Candlestick: one mark carrying all four OHLC accessors.
    await selectPreset(tester, 'candlestick');
    expect(find.text('Open, high, low, close as one mark'), findsOneWidget);
    spec = plot(tester).spec;
    expect(spec.marks.single, isA<CandlestickMark<GrammarSample>>());
    expect(spec.yAxes.single.id, 'price');

    // Bar: transposition is a whole-chart property of the spec.
    await selectPreset(tester, 'barTransposed');
    expect(find.text('Bars with the plane transposed'), findsOneWidget);
    spec = plot(tester).spec;
    expect(spec.transposed, isTrue);
    expect(spec.marks.single, isA<BarMark<GrammarSample>>());

    // Back to the first preset: the page returns to the line chain.
    await selectPreset(tester, 'lineTrend');
    expect(plot(tester).spec.marks, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the compare toggle swaps BravenPlot for the hand-built BravenChartPlus '
    'on every preset',
    (tester) async {
      await pumpPage(tester);

      final toggle = find.byKey(const ValueKey('chart-grammar-compare'));
      await revealOption(tester, toggle);

      for (final preset in presets) {
        await selectPreset(tester, preset);

        // Spec side.
        expect(
          find.byType(BravenPlot<GrammarSample>),
          findsOneWidget,
          reason: '$preset should mount a BravenPlot by default',
        );

        await revealOption(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();

        // Hand-built side: the raw config chart, no BravenPlot anywhere.
        expect(
          find.byType(BravenPlot<GrammarSample>),
          findsNothing,
          reason: '$preset should mount only the hand-built chart',
        );
        expect(find.byType(BravenChartPlus), findsOneWidget);
        expect(
          find.text(
            'Hand-built BravenChartPlus — the config the spec lowers to',
          ),
          findsOneWidget,
        );

        await revealOption(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the hand-built equivalent carries the ids, axes and annotations the '
    'lowering assigns',
    (tester) async {
      await pumpPage(tester);

      final toggle = find.byKey(const ValueKey('chart-grammar-compare'));
      await revealOption(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Line + trend: the default axis id, the mark-<index> series id, and
      // the trend lowered to an annotation bound to the source series.
      //
      // CONVERTED (item 1c', task 2.1): this used to pin
      // `series.yAxisId == 'axis-0'` + an inline `yAxisConfig`. A chain that
      // declares one axis and binds no mark to it now mounts the LEGACY
      // single-axis shape, so the hand-built twin does too. The assertions
      // below are strictly stronger than the ones they replace: they pin the
      // axis reaching the chart AND its label AND the absence of the per-series
      // binding, where the old pair pinned only the binding.
      var chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      expect(chart.series.single.id, 'mark-0');
      expect(chart.yAxis?.id, 'axis-0');
      expect(chart.yAxis?.label, 'Power');
      expect(chart.series.single.yAxisId, isNull);
      expect(chart.series.single.yAxisConfig, isNull);
      expect(chart.annotations, hasLength(1));
      expect((chart.annotations.single as TrendAnnotation).seriesId, 'mark-0');

      // Multi-axis: explicit ids on both slots, one series each.
      await selectPreset(tester, 'multiAxis');
      chart = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
      expect(chart.series.map((series) => series.id), <String>['power', 'hr']);
      expect(chart.series.map((series) => series.yAxisId), <String>[
        'watts',
        'bpm',
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('per-preset controls hide where they cannot apply', (
    tester,
  ) async {
    await pumpPage(tester);

    // Line + trend: the window slider is shown only for a moving average,
    // because a linear fit never reads windowSize.
    final window = find.byKey(const ValueKey('chart-grammar-trend-window'));
    await revealOption(tester, window);
    expect(window, findsOneWidget);

    final methodSegments = find.byKey(
      const ValueKey('chart-grammar-trend-method'),
    );
    await revealOption(tester, methodSegments);
    await tester.tap(
      find.descendant(of: methodSegments, matching: find.text('Linear')),
    );
    await tester.pumpAndSettle();
    expect(window, findsNothing);
    expect(
      (plot(tester).spec.marks.last as TrendMark<GrammarSample>).trendType,
      TrendType.linear,
    );

    // Candlestick: a candle is a unit, so the preset owns no control at all
    // and the whole section is absent rather than shown inert.
    await selectPreset(tester, 'candlestick');
    expect(find.text('Preset Controls'), findsNothing);
    expect(
      find.byKey(const ValueKey('chart-grammar-transposed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('chart-grammar-category-channel')),
      findsNothing,
    );

    // Bar: its own two controls appear and no other preset's do.
    await selectPreset(tester, 'barTransposed');
    final transposed = find.byKey(const ValueKey('chart-grammar-transposed'));
    await revealOption(tester, transposed);
    expect(transposed, findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-grammar-trend-window')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('chart-grammar-marker-radius')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preset controls drive the spec the facade builds', (
    tester,
  ) async {
    await pumpPage(tester);

    // Trend: the confidence band reaches the TrendMark.
    final band = find.byKey(const ValueKey('chart-grammar-confidence-band'));
    await revealOption(tester, band);
    await tester.tap(band);
    await tester.pumpAndSettle();
    expect(
      (plot(tester).spec.marks.last as TrendMark<GrammarSample>)
          .showConfidenceBand,
      isTrue,
    );

    // Multi-axis: the axis side reaches the declared slot.
    await selectPreset(tester, 'multiAxis');
    expect(plot(tester).spec.yAxes.last.position, YAxisPosition.right);
    final side = find.byKey(const ValueKey('chart-grammar-hr-axis-side'));
    await revealOption(tester, side);
    await tester.tap(find.descendant(of: side, matching: find.text('Left')));
    await tester.pumpAndSettle();
    expect(plot(tester).spec.yAxes.last.position, YAxisPosition.left);

    // Scatter: turning the category channel off drops the channel AND its
    // palette together — a channel without its template is rejected.
    await selectPreset(tester, 'scatterChannels');
    final category = find.byKey(
      const ValueKey('chart-grammar-category-channel'),
    );
    await revealOption(tester, category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    final scatter =
        plot(tester).spec.marks.single as ScatterMark<GrammarSample>;
    expect(scatter.categoryBy, isNull);
    expect(scatter.categories, isEmpty);
    expect(scatter.size, isNotNull);

    // Bar: transposition is a chain verb, so the toggle changes the spec.
    await selectPreset(tester, 'barTransposed');
    expect(plot(tester).spec.transposed, isTrue);
    final transposed = find.byKey(const ValueKey('chart-grammar-transposed'));
    await revealOption(tester, transposed);
    await tester.tap(transposed);
    await tester.pumpAndSettle();
    expect(plot(tester).spec.transposed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the theme and interaction options reach the spec', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(plot(tester).spec.interaction?.enableZoom, isTrue);
    final zoom = find.text('Enable Zoom');
    await revealOption(tester, zoom);
    await tester.tap(zoom);
    await tester.pumpAndSettle();
    expect(plot(tester).spec.interaction?.enableZoom, isFalse);

    // The controls a PlotSpec cannot express are hidden, not inert.
    await revealOption(tester, find.text('Enable Pan'));
    expect(find.text('Show Grid'), findsNothing);
    expect(find.text('Show Legend'), findsNothing);
    expect(find.text('Show X Scrollbar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every preset renders inside the workbench and the Source tab reaches '
    'ready with ordinary config Dart',
    (tester) async {
      await pumpPage(tester);

      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      for (final preset in presets) {
        await selectPreset(tester, preset);
        expect(
          find.byKey(const ValueKey('chart-grammar-workbench')),
          findsOneWidget,
          reason: '$preset should render inside the workbench',
        );
        for (final mode in ['Chart', 'Data', 'Split', 'Source']) {
          expect(
            find.descendant(of: switcher, matching: find.text(mode)),
            findsOneWidget,
            reason: '$preset should offer the $mode chip',
          );
        }
      }

      // Data mode models the spec-built chart with no extra options.
      await selectPreset(tester, 'lineTrend');
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Data')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChartDataTable), findsOneWidget);
      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      expect(workbench.workbenchController!.tableModel?.rowCount, 13);

      // Source last: the generated Dart is an ordinary BravenChartPlus with a
      // real series type — the whole point of the lowering.
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Chart')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChartSourceView), findsOneWidget);
      expect(
        workbench.workbenchController!.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      final source = workbench.workbenchController!.generatedSource!.source;
      expect(source, contains('final grammarChart = BravenChartPlus('));
      expect(source, contains('LineChartSeries('));
      expect(source, isNot(contains('BravenChart.of(')));
      expect(source, isNot(contains('PlotSpec')));
      expect(tester.takeException(), isNull);

      // The Source pane's second reading: the same chart, written back as the
      // chain. It is emitted over a SYNTHESISED row type — a chart document
      // keeps the numbers a chart was built from, never the GrammarSample
      // objects the chain was authored over, so the generated chain reads a
      // synthesised GrammarRow rather than the author's own type.
      // The options panel also has a section titled "Grammar", so the tap is
      // scoped to the Source pane's own toggle key.
      final formToggle = find.byKey(const ValueKey('chart-source-form-toggle'));
      await tester.tap(
        find.descendant(of: formToggle, matching: find.text('Grammar')),
      );
      await tester.pumpAndSettle();
      final chain = workbench.workbenchController!.generatedSource!.source;
      expect(chain, contains('final grammarChart = BravenChart.of(rows)'));
      expect(chain, contains('class GrammarRow {'));
      expect(chain, contains('.geomLine('));
      expect(chain, contains('.trend('));
      expect(chain, isNot(contains('BravenChartPlus(')));
      expect(
        find.byKey(const ValueKey('chart-grammar-source-code')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: formToggle, matching: find.text('Config')),
      );
      await tester.pumpAndSettle();
      expect(workbench.workbenchController!.generatedSource!.source, source);
      expect(tester.takeException(), isNull);

      // Changing the chart with the Source pane already holding a snapshot
      // invalidates it and remounts the chart. The pane must re-emit for the
      // new preset without ever notifying its listeners mid-build.
      await selectPreset(tester, 'candlestick');
      await tester.pumpAndSettle();
      expect(
        workbench.workbenchController!.generatedSource!.source,
        contains('CandlestickChartSeries('),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the Grammar form emits a chain for every preset', (
    tester,
  ) async {
    const verbs = <String, String>{
      'lineTrend': '.geomLine(',
      'multiAxis': '.geomArea(',
      'scatterChannels': '.geomPoint(',
      'candlestick': '.geomCandlestick(',
      'barTransposed': '.geomBar(',
      'referenceLines': '.threshold(',
    };

    // ONE page for the whole sweep: the Source pane stays open and the preset
    // changes underneath it, which is exactly how the page is used.
    await pumpPage(tester);
    final switcher = find.byKey(
      const ValueKey('chart-workbench-mode-switcher'),
    );
    await tester.tap(
      find.descendant(of: switcher, matching: find.text('Source')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chart-source-form-toggle')),
        matching: find.text('Grammar'),
      ),
    );
    await tester.pumpAndSettle();

    for (final preset in presets) {
      await selectPreset(tester, preset);
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      final chain = workbench.workbenchController!.generatedSource!.source;
      expect(
        chain,
        contains('final grammarChart = BravenChart.of(rows)'),
        reason: '$preset should emit a chain, not a diagnostic: $chain',
      );
      expect(chain, contains(verbs[preset]!), reason: preset);
      expect(chain, contains('class GrammarRow {'), reason: preset);
      expect(tester.takeException(), isNull);
    }
  });

  // ==========================================================================
  // The V2.0 preset: the emission gaps closed, demonstrated end to end
  // ==========================================================================
  //
  // The Reference lines preset is authored entirely through the facade and
  // exercises all three V2.0 additions — a threshold reference mark, the
  // chart-level grid/title options, and a per-mark data-point-marker flag.
  // Every one of them round-trips, so its Grammar Source tab reaches ready
  // with a real chain, NOT the "not emitted" diagnostic these shapes drew in
  // V1.
  testWidgets(
    'the Reference lines preset is a facade chain, and its Grammar Source tab '
    'emits .threshold( / .grid( / showDataPointMarkers with no diagnostic',
    (tester) async {
      await pumpPage(tester);

      await selectPreset(tester, 'referenceLines');
      expect(
        find.text('Reference marks and chart-level options'),
        findsOneWidget,
      );

      // The spec is built by the facade only: area + line geometries, a
      // threshold reference mark, and the V2.0 chart-level options.
      final spec = plot(tester).spec;
      expect(spec.marks, hasLength(3));
      expect(spec.marks[0], isA<AreaMark<GrammarSample>>());
      expect(spec.marks[1], isA<LineMark<GrammarSample>>());
      expect(spec.marks[2], isA<ThresholdMark<GrammarSample>>());
      expect(
        (spec.marks[1] as LineMark<GrammarSample>).showDataPointMarkers,
        isTrue,
        reason: 'the per-mark marker flag is a V2.0 addition',
      );
      expect(
        spec.grid,
        isNotNull,
        reason: '.grid() is a V2.0 chart-level verb',
      );
      expect(spec.title, 'Ride power');

      // The compare toggle swaps the BravenPlot for the hand-built
      // BravenChartPlus (in Chart mode, before the Source pane mounts).
      final toggle = find.byKey(const ValueKey('chart-grammar-compare'));
      await revealOption(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(BravenPlot<GrammarSample>), findsNothing);
      expect(find.byType(BravenChartPlus), findsOneWidget);
      await revealOption(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);

      // Grammar Source tab: reaches ready and CONTAINS the chain, with every
      // V2.0 verb, and NO "not emitted" diagnostic.
      final switcher = find.byKey(
        const ValueKey('chart-workbench-mode-switcher'),
      );
      await tester.tap(
        find.descendant(of: switcher, matching: find.text('Source')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('chart-source-form-toggle')),
          matching: find.text('Grammar'),
        ),
      );
      await tester.pumpAndSettle();

      final workbench = tester.widget<BravenChartWorkbench>(
        find.byType(BravenChartWorkbench),
      );
      expect(
        workbench.workbenchController!.sourceState.phase,
        ChartWorkbenchSourcePhase.ready,
      );
      final chain = workbench.workbenchController!.generatedSource!.source;
      expect(chain, contains('final grammarChart = BravenChart.of(rows)'));
      expect(chain, contains('.threshold('), reason: chain);
      expect(chain, contains('.grid('), reason: chain);
      expect(chain, contains('showDataPointMarkers'), reason: chain);
      expect(chain, contains('.title('), reason: chain);
      // The headline of the whole lane: these shapes EMIT now, never diagnose.
      expect(chain, isNot(contains('was not emitted')));
      expect(chain, isNot(contains('BravenChartPlus(')));
      expect(tester.takeException(), isNull);
    },
  );

  // ==========================================================================
  // Per-preset fidelity: the page's central claim, asserted
  // ==========================================================================
  //
  // The page claims the spec-built chart and the hand-built chart are
  // INDISTINGUISHABLE. This asserts it on both halves of what a
  // `BravenChartPlus` render is made of:
  //
  //  1. The chart DOCUMENT — series, points, annotations and axis configs —
  //     compared as `toJson()` deep equality, exactly the way the package's
  //     `test/widgets/braven_plot_artifact_parity_test.dart` does it.
  //  2. The widget-level inputs a document does NOT carry: `theme`,
  //     `xAxisConfig` and `interactionConfig`. A null theme resolves to a
  //     DIFFERENT axis label style than `ChartTheme.light` (the fallback
  //     `TextStyle` names no font family), which measures to a different
  //     Y-axis strip width — the visible "the axis moves when I toggle"
  //     defect. Nothing in the document would have caught it.
  //
  // Both sides mount under the same `ValueKey('chart-grammar-stage-chart')`
  // and share the page's chart controller, so configuration is the only thing
  // that can differ.
  //
  // The hand-built side is deliberately hand-written config, NOT built from
  // `LoweredPlot` — deriving it from the lowering would make this comparison
  // tautological and destroy the demo's claim that a human could type it.
  testWidgets(
    'every preset is indistinguishable from its hand-built equivalent',
    (tester) async {
      await pumpPage(tester);

      final toggle = find.byKey(const ValueKey('chart-grammar-compare'));

      ({
        Map<String, Object?> document,
        ChartTheme? theme,
        XAxisConfig? xAxis,
        InteractionConfig? interaction,
      })
      stage() {
        expect(
          find.byKey(const ValueKey('chart-grammar-stage-chart')),
          findsOneWidget,
        );
        final chart = tester.widget<BravenChartPlus>(
          find.byType(BravenChartPlus),
        );
        final workbench = tester.widget<BravenChartWorkbench>(
          find.byType(BravenChartWorkbench),
        );
        final result = workbench.chartController!.extractDocument();
        expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
        return (
          document: (result as ChartArtifactSuccess<ChartDocumentSnapshot>)
              .value
              .document
              .toJson(),
          theme: chart.theme,
          xAxis: chart.xAxisConfig,
          interaction: chart.interactionConfig,
        );
      }

      for (final preset in presets) {
        await selectPreset(tester, preset);
        await tester.pumpAndSettle();

        final fromSpec = stage();

        await revealOption(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(BravenPlot<GrammarSample>), findsNothing);

        final fromHand = stage();

        expect(
          fromHand.document,
          fromSpec.document,
          reason:
              '$preset: the hand-built chart document must equal the '
              'spec-built one',
        );
        expect(
          fromHand.theme,
          fromSpec.theme,
          reason:
              '$preset: a differing theme changes the axis label style and '
              'therefore the Y-axis strip width',
        );
        expect(
          fromHand.xAxis,
          fromSpec.xAxis,
          reason: '$preset: the X-axis config must match',
        );
        expect(
          fromHand.interaction,
          fromSpec.interaction,
          reason: '$preset: the interaction config must match',
        );

        await revealOption(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
}
