import 'package:braven_charts_example/showcase/pages/bar_lab_page.dart';
import 'package:braven_charts_example/showcase/pages/candlestick_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/cartesian_chart_type_pages.dart';
import 'package:braven_charts_example/showcase/pages/concentric_donut_page.dart';
import 'package:braven_charts_example/showcase/pages/donut_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/pie_charts_page.dart';
import 'package:braven_charts_example/showcase/pages/polar_column_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases =
      <({String name, Key playgroundKey, Widget page, Set<String> properties})>[
        (
          name: 'Line',
          playgroundKey: const ValueKey('line-playground'),
          page: const LineChartsPage(),
          properties: {
            'Interpolation',
            'Stroke width',
            'Line glow',
            'Marker style',
            'Marker radius',
            'Show second series',
            'Show point labels',
            'Duration',
            'Synchronize viewport',
          },
        ),
        (
          name: 'Area',
          playgroundKey: const ValueKey('area-playground'),
          page: const AreaChartsPage(),
          properties: {
            'Interpolation',
            'Stroke width',
            'Fill opacity',
            'Use baseline fills',
            'Gradient fill',
            'Show second series',
            'Duration',
          },
        ),
        (
          name: 'Scatter',
          playgroundKey: const ValueKey('scatter-playground'),
          page: const ScatterChartsPage(),
          properties: {
            'Marker radius',
            'Marker shape',
            'Marker width',
            'Points per series',
            'Small bubble',
            'Color ramp',
            'Band palette',
            'Low-confidence opacity',
            'Category palette',
            'Horizontal spread',
            'Label anchor',
            'Neighborhood',
            'Error magnitude',
            'Selection operation',
            'Aggregation cell',
            'Cell size',
            'Smoothing radius',
            'Display',
          },
        ),
        (
          name: 'Bar',
          playgroundKey: const ValueKey('bar-playground'),
          page: const BarLabPage(),
          properties: {
            'Series count',
            'Layout',
            'Cumulative labels',
            'Bin count',
            'Pattern opacity',
            'Qualitative bands',
            'Center line',
            'Error bars',
            'Inactive opacity',
            'Stagger',
          },
        ),
        (
          name: 'Candlestick',
          playgroundKey: const ValueKey('candlestick-playground'),
          page: const CandlestickChartsPage(),
          properties: {
            'Show market context',
            'Show pinned OHLC summary',
            'Entrance animation',
            'Override tracking colours',
            'Group dense candles',
            'Override direction colours',
            'Show body borders',
            'Show close average',
          },
        ),
        (
          name: 'Pie',
          playgroundKey: const ValueKey('pie-playground'),
          page: const PieChartsPage(),
          properties: {
            'Show labels',
            'Smallest slice radius',
            'Slice fill',
            'Border width',
            'Selected slice glow',
            'Group small slices',
            'Show slice legend',
            'Show tooltips',
          },
        ),
        (
          name: 'Donut',
          playgroundKey: const ValueKey('donut-playground'),
          page: const DonutChartsPage(),
          properties: {
            'Inner radius',
            'Slice fill',
            'Border width',
            'Show center content',
            'Group small slices',
            'Show slice labels',
            'Show legend',
            'Show tooltips',
          },
        ),
        (
          name: 'Concentric Donut',
          playgroundKey: const ValueKey('concentric-playground'),
          page: const ConcentricDonutPage(),
          properties: {
            'Active rings',
            'Center opening',
            'Slice fill',
            'Border width',
            'Show slice labels',
            'Show composition center',
            'Group small categories',
            'Show legend',
            'Show tooltips',
          },
        ),
        (
          name: 'Polar Column',
          playgroundKey: const ValueKey('polar-playground'),
          page: const PolarColumnPage(),
          properties: {
            'Category count',
            'Maximum category labels',
            'Maximum grid spokes',
            'Show category targets',
            'Show capacity threshold',
            'Show intervals',
            'Selected column effect',
            'Show tooltips',
          },
        ),
      ];

  for (final chartCase in cases) {
    testWidgets('${chartCase.name} Playground exposes its family inventory', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: chartCase.page)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final authoredPanel = tester.widget<OptionsPanel>(
        find.byType(OptionsPanel),
      );
      expect(authoredPanel.headerEditor, isNull);

      final playground = find.byKey(chartCase.playgroundKey);
      expect(playground, findsOneWidget);
      await tester.ensureVisible(playground);
      await tester.pumpAndSettle();
      await tester.tap(playground);
      await tester.pump(const Duration(milliseconds: 350));

      final playgroundPanel = tester.widget<OptionsPanel>(
        find.byType(OptionsPanel),
      );
      expect(playgroundPanel.headerEditor, isNotNull);
      final labels = _propertyLabels(playgroundPanel.children);
      expect(
        labels,
        containsAll(chartCase.properties),
        reason:
            '${chartCase.name} must expose properties from every feature '
            'slice, not only the generated baseline currently on screen.',
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Set<String> _propertyLabels(Iterable<Widget> widgets) => {
  for (final widget in widgets)
    if (widget case OptionSection(:final children))
      for (final child in children)
        if (child case ShowcaseInspectorEntry(:final inspectorMetadata))
          inspectorMetadata.label,
};
