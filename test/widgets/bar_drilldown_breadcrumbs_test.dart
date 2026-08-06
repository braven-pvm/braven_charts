import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BarDrillNode node(String id, {List<BarDrillNode> children = const []}) =>
      BarDrillNode(
        id: id,
        label: id,
        series: [
          BarChartSeries(
            id: '$id-series',
            name: id,
            points: const [ChartDataPoint(x: 0, y: 1)],
            barWidthPercent: 0.7,
          ),
        ],
        children: children,
      );

  testWidgets('breadcrumb buttons navigate to an ancestor', (tester) async {
    final leaf = node('Leaf');
    final child = node('Child', children: [leaf]);
    final controller = BarDrilldownController(
      config: BarDrilldownConfig(root: node('Root', children: [child])),
    );
    await controller.drillTo('Child');
    await controller.drillTo('Leaf');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BarDrilldownBreadcrumbs(controller: controller)),
      ),
    );

    expect(find.byKey(const ValueKey('bar-drill-back')), findsOneWidget);
    await tester.tap(find.text('Root'));
    await tester.pump();
    expect(controller.current.id, 'Root');
    expect(find.byKey(const ValueKey('bar-drill-back')), findsNothing);
  });
}
