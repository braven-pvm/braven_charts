import 'package:braven_charts_example/showcase/pages/bar_lab_page.dart';
import 'package:braven_charts_example/showcase/pages/candlestick_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:braven_charts_example/showcase/widgets/showcase_randomizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases =
      <
        ({
          String name,
          String prefix,
          Key playgroundKey,
          Key selectorKey,
          String lastAuthoredLabel,
          String authoredLabel,
          String authoredChartText,
          String? playgroundChartText,
          Widget page,
        })
      >[
        (
          name: 'Line',
          prefix: 'line-randomizer',
          playgroundKey: const ValueKey('line-playground'),
          selectorKey: const ValueKey('line-preset-picker'),
          lastAuthoredLabel: 'Synchronized',
          authoredLabel: 'Workhorse',
          authoredChartText: 'Workhorse',
          playgroundChartText: 'Line playground',
          page: const LineChartsPage(),
        ),
        (
          name: 'Area',
          prefix: 'area-randomizer',
          playgroundKey: const ValueKey('area-playground'),
          selectorKey: const ValueKey('area-preset-picker'),
          lastAuthoredLabel: 'Pulse',
          authoredLabel: 'Layered',
          authoredChartText: 'Layered',
          playgroundChartText: 'Area playground',
          page: const AreaChartsPage(),
        ),
        (
          name: 'Scatter',
          prefix: 'scatter-randomizer',
          playgroundKey: const ValueKey('scatter-playground'),
          selectorKey: const ValueKey('scatter-preset-picker'),
          lastAuthoredLabel: 'Marginals',
          authoredLabel: 'Cohorts',
          authoredChartText: 'Olympic athlete profiles',
          playgroundChartText: 'Scatter playground',
          page: const ScatterChartsPage(),
        ),
        (
          name: 'Bar',
          prefix: 'bar-randomizer',
          playgroundKey: const ValueKey('bar-playground'),
          selectorKey: const ValueKey('bar-lab-preset-wrap'),
          lastAuthoredLabel: '100%',
          authoredLabel: 'Capacity',
          authoredChartText: 'Progress against capacity',
          playgroundChartText: 'Bar playground',
          page: const BarLabPage(),
        ),
        (
          name: 'Candlestick',
          prefix: 'candlestick-randomizer',
          playgroundKey: const ValueKey('candlestick-playground'),
          selectorKey: const ValueKey('candlestick-surface-selector'),
          lastAuthoredLabel: 'Stock composition',
          authoredLabel: 'Price action',
          authoredChartText: 'Balanced price action',
          playgroundChartText: 'Candlestick playground',
          page: const CandlestickChartsPage(),
        ),
        (
          name: 'Pie',
          prefix: 'pie-randomizer',
          playgroundKey: const ValueKey('pie-playground'),
          selectorKey: const ValueKey('pie-presentation-selector'),
          lastAuthoredLabel: 'High contrast',
          authoredLabel: 'Editorial labels',
          authoredChartText: 'Revenue by product',
          playgroundChartText: 'Pie playground',
          page: const PieChartsPage(),
        ),
        (
          name: 'Donut',
          prefix: 'donut-randomizer',
          playgroundKey: const ValueKey('donut-playground'),
          selectorKey: const ValueKey('donut-story-selector'),
          lastAuthoredLabel: 'Grouped sources',
          authoredLabel: 'Contribution ring',
          authoredChartText: 'Revenue by product',
          playgroundChartText: 'Donut playground',
          page: const DonutChartsPage(),
        ),
        (
          name: 'Concentric Donut',
          prefix: 'concentric-randomizer',
          playgroundKey: const ValueKey('concentric-playground'),
          selectorKey: const ValueKey('concentric-presentation-selector'),
          lastAuthoredLabel: 'High contrast',
          authoredLabel: 'Period comparison',
          authoredChartText: 'Current period',
          playgroundChartText: null,
          page: const ConcentricDonutPage(),
        ),
        (
          name: 'Polar Column',
          prefix: 'polar-randomizer',
          playgroundKey: const ValueKey('polar-playground'),
          selectorKey: const ValueKey('polar-presentation-selector'),
          lastAuthoredLabel: 'Ranges & uncertainty',
          authoredLabel: 'Standard columns',
          authoredChartText: 'Channel volume',
          playgroundChartText: 'Polar Column playground',
          page: const PolarColumnPage(),
        ),
      ];

  for (final chartCase in cases) {
    testWidgets(
      '${chartCase.name} isolates the shared randomizer in Playground',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: chartCase.page)),
        );
        await tester.pump(const Duration(milliseconds: 250));

        final randomize = find.byKey(ValueKey('${chartCase.prefix}-next'));
        expect(randomize, findsNothing);
        expect(find.text(chartCase.authoredChartText), findsWidgets);
        expect(find.byKey(chartCase.playgroundKey), findsOneWidget);

        final selector = find.byKey(chartCase.selectorKey);
        expect(selector, findsOneWidget);
        final selectorElements = find
            .descendant(
              of: selector,
              matching: find.byWidgetPredicate((_) => true),
            )
            .evaluate()
            .toList();
        final playgroundIndex = selectorElements.indexWhere(
          (element) => element.widget.key == chartCase.playgroundKey,
        );
        final lastAuthoredIndex = selectorElements.lastIndexWhere(
          (element) =>
              element.widget is Text &&
              (element.widget as Text).data == chartCase.lastAuthoredLabel,
        );
        expect(lastAuthoredIndex, greaterThanOrEqualTo(0));
        expect(
          playgroundIndex,
          greaterThan(lastAuthoredIndex),
          reason:
              '${chartCase.name} Playground must follow every authored example',
        );

        final playground = find.byKey(chartCase.playgroundKey);
        await tester.ensureVisible(playground);
        await tester.pumpAndSettle();
        await tester.tap(playground);
        await tester.pump(const Duration(milliseconds: 350));

        expect(randomize, findsOneWidget);
        if (chartCase.playgroundChartText case final playgroundText?) {
          expect(find.text(playgroundText), findsOneWidget);
        }
        expect(
          find.byKey(ValueKey('${chartCase.prefix}-playback-header')),
          findsOneWidget,
        );
        await tester.tap(randomize);
        await tester.pump(const Duration(milliseconds: 350));

        final randomizer =
            (tester
                        .widget<OptionsPanel>(find.byType(OptionsPanel))
                        .headerEditor!
                    as PropertyRandomizerSection)
                .controller;
        for (final seed in const <int>[0, 1, 2, 7, 31, 127, 511, 997]) {
          randomizer.seed = seed;
          randomizer.generateCurrent();
          await tester.pump(const Duration(milliseconds: 120));
          expect(
            tester.takeException(),
            isNull,
            reason: '${chartCase.name} randomizer seed $seed',
          );
        }

        await tester.tap(find.byKey(ValueKey('${chartCase.prefix}-editor')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('${chartCase.prefix}-status')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.widgetWithText(TextButton, 'Close').last);
        await tester.pumpAndSettle();
        final authoredExample = find.text(chartCase.authoredLabel).first;
        await tester.ensureVisible(authoredExample);
        await tester.pumpAndSettle();
        await tester.tap(authoredExample);
        await tester.pump(const Duration(milliseconds: 350));
        expect(randomize, findsNothing);
        expect(find.text(chartCase.authoredChartText), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
