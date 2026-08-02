import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entrance reveal advances cells in deterministic row order', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_series(value: 12)));

    expect(_element(tester).revealProgress, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_element(tester).revealProgress, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_element(tester).revealProgress, 1);
  });

  testWidgets('reduced motion renders the complete matrix immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(_series(value: 12)),
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(_element(tester).revealProgress, 1);
  });

  testWidgets('stable cell revisions interpolate measured values', (
    tester,
  ) async {
    final key = GlobalKey<_RevisionHarnessState>();
    await tester.pumpWidget(_RevisionHarness(key: key));
    await tester.pumpAndSettle();

    key.currentState!.revise();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    final value =
        (_element(tester).series as HeatmapChartSeries).cells.first.value!;
    expect(value, greaterThan(12));
    expect(value, lessThan(40));

    await tester.pumpAndSettle();
    expect(
      (_element(tester).series as HeatmapChartSeries).cells.first.value,
      40,
    );
  });
}

Widget _host(HeatmapChartSeries series) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 500,
      height: 320,
      child: BravenChartPlus(showLegend: false, series: [series]),
    ),
  ),
);

HeatmapChartSeries _series({required double value}) => HeatmapChartSeries(
  id: 'matrix',
  name: 'Activity',
  points: [
    HeatmapDataPoint(x: 0, y: 0, value: value, pointKey: 'a'),
    HeatmapDataPoint(x: 1, y: 0, value: 20, pointKey: 'b'),
    HeatmapDataPoint(x: 0, y: 1, value: 30, pointKey: 'c'),
    HeatmapDataPoint(x: 1, y: 1, value: 40, pointKey: 'd'),
  ],
  colorScale: HeatmapColorScale.sequential(
    colors: const [Colors.white, Colors.blue],
  ),
  animation: const HeatmapAnimationStyle(
    entranceMode: HeatmapEntranceMode.scale,
    entranceOrder: HeatmapEntranceOrder.row,
    staggerFraction: 0.75,
  ),
);

SeriesElement _element(WidgetTester tester) {
  final renderBox = tester.renderObject<ChartRenderBox>(
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
    ),
  );
  return renderBox.debugElements
      .whereType<SeriesElement>()
      .where((element) => element.series is HeatmapChartSeries)
      .single;
}

class _RevisionHarness extends StatefulWidget {
  const _RevisionHarness({super.key});

  @override
  State<_RevisionHarness> createState() => _RevisionHarnessState();
}

class _RevisionHarnessState extends State<_RevisionHarness> {
  double _value = 12;

  void revise() => setState(() => _value = 40);

  @override
  Widget build(BuildContext context) => _host(_series(value: _value));
}
