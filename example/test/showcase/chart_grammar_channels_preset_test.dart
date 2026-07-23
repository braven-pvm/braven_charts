// Copyright 2026 Braven Charts - Chart Grammar channels preset test
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Bar / Line / Area colour the corresponding family; Width drives bar width.
  const families = <String>['Bar', 'Line', 'Area', 'Width'];

  BravenPlot<GrammarSample> plot(WidgetTester tester) =>
      tester.widget<BravenPlot<GrammarSample>>(
        find.byType(BravenPlot<GrammarSample>),
      );

  void expectMarkFor(String family, Mark<GrammarSample> mark) {
    switch (family) {
      case 'Line':
        expect(mark, isA<LineMark<GrammarSample>>());
      case 'Area':
        expect(mark, isA<AreaMark<GrammarSample>>());
      default:
        expect(mark, isA<BarMark<GrammarSample>>());
    }
  }

  testWidgets(
    'the scale-driven channels preset renders every family through the facade',
    (tester) async {
      // Showcase pages lay out for a desktop workbench: the default 800x600
      // test surface collapses the chart pane and pushes the wrapped preset
      // chips off-screen, so every showcase page test sizes to 1440x1000.
      final pixelRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ChartGrammarPage())),
      );
      await tester.pumpAndSettle();

      // Select the scale-driven-channels preset.
      await tester.tap(
        find.byKey(const ValueKey('chart-grammar-preset-channels')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Colour and width driven by a data field'),
        findsOneWidget,
      );

      // The facade side: each family lowers to the expected mark, and the
      // BravenPlot renders without throwing.
      for (final family in families) {
        await tester.tap(find.text(family).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'facade $family');
        expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);
        expectMarkFor(family, plot(tester).spec.marks.single);
      }

      // The hand-built side: the same families render as the hand-written
      // BravenChartPlus the spec lowers to — the parity proof.
      final toggle = find.byKey(const ValueKey('chart-grammar-compare'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      for (final family in families) {
        await tester.tap(find.text(family).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'hand-built $family');
        expect(find.byType(BravenPlot<GrammarSample>), findsNothing);
        expect(find.byType(BravenChartPlus), findsOneWidget);
      }
    },
  );
}
