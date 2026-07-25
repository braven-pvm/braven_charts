// Copyright 2026 Braven Charts - Chart Grammar scales preset test
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Log Y folds a log scale onto the synthesized axis; Time X binds a DateTime
  // field to a time axis. Both families are a single line mark.
  const families = <String>['Log Y', 'Time X'];

  BravenPlot<GrammarSample> plot(WidgetTester tester) =>
      tester.widget<BravenPlot<GrammarSample>>(
        find.byType(BravenPlot<GrammarSample>),
      );

  testWidgets(
    'the log / time scales preset renders both families through the facade',
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

      // Select the log / time scales preset.
      await tester.tap(
        find.byKey(const ValueKey('chart-grammar-preset-scales')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Logarithmic and time axis scales'),
        findsOneWidget,
      );

      // The facade side: each family lowers to a single line mark and the
      // BravenPlot renders without throwing.
      for (final family in families) {
        await tester.tap(find.text(family).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'facade $family');
        expect(find.byType(BravenPlot<GrammarSample>), findsOneWidget);
        expect(plot(tester).spec.marks.single, isA<LineMark<GrammarSample>>());
      }

      // The facade time-X axis is a time scale; the log-Y axis is a log scale.
      expect(plot(tester).spec.xAxis?.scaleType, AxisScaleType.time);

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
