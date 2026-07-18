import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bars grow on entry and interpolate data updates', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedBarHarnessState>();
    final base = ChartTheme.light;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: _AnimatedBarHarness(key: key, theme: theme),
        ),
      ),
    );
    await tester.pump();

    BarChartSeries renderedSeries() {
      final renderBox = tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single;
      return renderBox.debugElements.whereType<SeriesElement>().single.series
          as BarChartSeries;
    }

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedSeries().points.single.y, closeTo(50, 0.01));
    await tester.pumpAndSettle();
    expect(renderedSeries().points.single.y, 100);

    key.currentState!.setValue(60);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedSeries().points.single.y, closeTo(80, 0.01));
    await tester.pumpAndSettle();
    expect(renderedSeries().points.single.y, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new transition key starts destination bars fresh', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedBarHarnessState>();
    final base = ChartTheme.light;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: _AnimatedBarHarness(key: key, theme: theme),
        ),
      ),
    );
    await tester.pumpAndSettle();

    key.currentState!.startFresh(60);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final rendered = _renderedBarSeries(tester)['actual']!;
    expect(rendered.points.single.y, closeTo(30, 0.01));
    await tester.pumpAndSettle();
    expect(_renderedBarSeries(tester)['actual']!.points.single.y, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion renders final bar geometry immediately', (
    tester,
  ) async {
    final base = ChartTheme.light;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SizedBox(
          width: 520,
          height: 360,
          child: BravenChartPlus(
            showLegend: false,
            theme: base.copyWith(
              animationTheme: base.animationTheme.copyWith(
                dataUpdateDuration: const Duration(milliseconds: 400),
              ),
            ),
            series: const [
              BarChartSeries(
                id: 'actual',
                points: [
                  ChartDataPoint(x: 0, y: 100),
                  ChartDataPoint(x: 1, y: 80),
                  ChartDataPoint(x: 2, y: 60),
                ],
                barWidthPercent: 0.7,
                barStyle: BarChartStyle(
                  motion: BarMotionStyle(
                    order: BarAnimationOrder.reverse,
                    staggerFraction: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final series =
        renderBox.debugElements.whereType<SeriesElement>().single.series
            as BarChartSeries;
    expect(series.points.map((point) => point.y), [100, 80, 60]);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removed points collapse before leaving canonical geometry', (
    tester,
  ) async {
    final key = GlobalKey<_LifecycleBarHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: _LifecycleBarHarness(key: key),
        ),
      ),
    );
    await tester.pumpAndSettle();

    key.currentState!.removeLastPoint();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    var actual = _renderedBarSeries(tester)['actual']!;
    expect(actual.points.length, 2);
    expect(actual.points.last.x, 1);
    expect(actual.points.last.y, closeTo(40, 0.01));

    await tester.pumpAndSettle();
    actual = _renderedBarSeries(tester)['actual']!;
    expect(actual.points.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removed series collapse in their previous render order', (
    tester,
  ) async {
    final key = GlobalKey<_LifecycleBarHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: _LifecycleBarHarness(key: key),
        ),
      ),
    );
    await tester.pumpAndSettle();

    key.currentState!.removePlanSeries();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    var rendered = _renderedBarSeries(tester);
    expect(rendered.keys, const ['actual', 'plan']);
    expect(rendered['plan']!.points.single.y, closeTo(30, 0.01));

    await tester.pumpAndSettle();
    rendered = _renderedBarSeries(tester);
    expect(rendered.keys, const ['actual']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion removes points immediately', (tester) async {
    final key = GlobalKey<_LifecycleBarHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SizedBox(
          width: 520,
          height: 360,
          child: _LifecycleBarHarness(key: key),
        ),
      ),
    );
    await tester.pump();

    key.currentState!.removeLastPoint();
    await tester.pump();

    expect(_renderedBarSeries(tester)['actual']!.points.length, 1);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}

Map<String, BarChartSeries> _renderedBarSeries(WidgetTester tester) => {
  for (final element
      in tester.allRenderObjects
          .whereType<ChartRenderBox>()
          .single
          .debugElements
          .whereType<SeriesElement>())
    if (element.series is BarChartSeries)
      element.series.id: element.series as BarChartSeries,
};

class _AnimatedBarHarness extends StatefulWidget {
  const _AnimatedBarHarness({super.key, required this.theme});

  final ChartTheme theme;

  @override
  State<_AnimatedBarHarness> createState() => _AnimatedBarHarnessState();
}

class _AnimatedBarHarnessState extends State<_AnimatedBarHarness> {
  double value = 100;
  Object transitionKey = 'initial';

  void setValue(double next) => setState(() => value = next);

  void startFresh(double next) => setState(() {
    value = next;
    transitionKey = Object();
  });

  @override
  Widget build(BuildContext context) {
    return BravenChartPlus(
      transitionKey: transitionKey,
      showLegend: false,
      theme: widget.theme,
      yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 120),
      series: [
        BarChartSeries(
          id: 'actual',
          points: [ChartDataPoint(x: 0, y: value)],
          barWidthPercent: 0.7,
        ),
      ],
    );
  }
}

class _LifecycleBarHarness extends StatefulWidget {
  const _LifecycleBarHarness({super.key});

  @override
  State<_LifecycleBarHarness> createState() => _LifecycleBarHarnessState();
}

class _LifecycleBarHarnessState extends State<_LifecycleBarHarness> {
  bool includeLastPoint = true;
  bool includePlan = true;

  void removeLastPoint() => setState(() => includeLastPoint = false);

  void removePlanSeries() => setState(() => includePlan = false);

  @override
  Widget build(BuildContext context) {
    final base = ChartTheme.light;
    return BravenChartPlus(
      showLegend: false,
      theme: base.copyWith(
        animationTheme: base.animationTheme.copyWith(
          dataUpdateDuration: const Duration(milliseconds: 400),
          dataUpdateCurve: Curves.linear,
        ),
      ),
      yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 120),
      series: [
        BarChartSeries(
          id: 'actual',
          points: [
            const ChartDataPoint(x: 0, y: 100),
            if (includeLastPoint) const ChartDataPoint(x: 1, y: 80),
          ],
          barWidthPercent: 0.7,
        ),
        if (includePlan)
          const BarChartSeries(
            id: 'plan',
            points: [ChartDataPoint(x: 0, y: 60)],
            barWidthPercent: 0.7,
          ),
      ],
    );
  }
}
