// Copyright 2026 Braven Charts - Chart Grammar faceting preset tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
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

  Future<void> selectFaceted(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('chart-grammar-preset-faceted')));
    await tester.pumpAndSettle();
  }

  testWidgets('the faceting preset renders a BravenFacetPlot of panels', (
    tester,
  ) async {
    await pumpPage(tester);
    await selectFaceted(tester);

    expect(find.byType(BravenFacetPlot<GrammarSample>), findsOneWidget);
    // rideRows carry three zones — Endurance, Tempo, Threshold.
    expect(
      find.byType(BravenPlot<GrammarSample>),
      findsNWidgets(3),
    );
    expect(find.text('Zone: Endurance'), findsOneWidget);
    expect(find.text('Zone: Tempo'), findsOneWidget);
    expect(find.text('Zone: Threshold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the scales control drives the facet spec', (tester) async {
    await pumpPage(tester);
    await selectFaceted(tester);

    BravenFacetPlot<GrammarSample> facetPlot() =>
        tester.widget<BravenFacetPlot<GrammarSample>>(
          find.byType(BravenFacetPlot<GrammarSample>),
        );

    expect(facetPlot().spec.facet!.scales, FacetScales.fixed);

    final scales = find.byKey(const ValueKey('chart-grammar-facet-scales'));
    await tester.tap(find.descendant(of: scales, matching: find.text('free')));
    await tester.pumpAndSettle();

    expect(facetPlot().spec.facet!.scales, FacetScales.free);
    expect(tester.takeException(), isNull);
  });
}
