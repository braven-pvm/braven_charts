import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('elastic sweep replay never retreats after revealing geometry', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final base = ChartTheme.vibrant;
    final theme = base.copyWith(
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 600),
        dataUpdateCurve: Curves.elasticOut,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 480,
          height: 360,
          child: BravenChartPlus(
            bravenChartController: controller,
            showLegend: false,
            theme: theme,
            series: [
              PieChartSeries.fromMap(
                id: 'elastic-sweep',
                values: const {'A': 42, 'B': 28, 'C': 16, 'D': 9, 'E': 5},
                pieStyle: const PieChartStyle(
                  animationMode: PieAnimationMode.sweep,
                ),
                dataLabels: const PieDataLabelConfig(isVisible: false),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    PieSeriesElement currentElement() => tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<PieSeriesElement>()
        .single;

    controller.replayRadialEntrance();
    await tester.pump();
    final samples = <double>[currentElement().animationProgress];
    for (var elapsed = 50; elapsed <= 600; elapsed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
      samples.add(currentElement().animationProgress);
    }

    for (var index = 1; index < samples.length; index++) {
      expect(
        samples[index],
        greaterThanOrEqualTo(samples[index - 1]),
        reason: 'Sweep reveal retreated in $samples',
      );
    }
    expect(samples.first, 0);
    await tester.pumpAndSettle();
    expect(currentElement().animationProgress, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radial data updates morph without replaying entrance', (
    tester,
  ) async {
    final key = GlobalKey<_RadialAnimationHarnessState>();
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
          width: 480,
          height: 360,
          child: _RadialAnimationHarness(key: key, theme: theme),
        ),
      ),
    );
    await tester.pump();

    PieChartSeries renderedSeries() =>
        tester.allRenderObjects
                .whereType<ChartRenderBox>()
                .single
                .debugElements
                .whereType<PieSeriesElement>()
                .single
                .series
            as PieChartSeries;

    expect(tester.hasRunningAnimations, isFalse);
    key.currentState!.setValues(const {'A': 60, 'B': 40});
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedSeries().points.first.y, closeTo(40, .01));
    expect(renderedSeries().points.last.y, closeTo(60, .01));
    await tester.pumpAndSettle();
    expect(renderedSeries().points.map((point) => point.y), [60, 40]);
  });

  testWidgets('a new transition key cancels an active radial data morph', (
    tester,
  ) async {
    final key = GlobalKey<_RadialAnimationHarnessState>();
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
          width: 480,
          height: 360,
          child: _RadialAnimationHarness(key: key, theme: theme),
        ),
      ),
    );
    await tester.pump();

    key.currentState!.setValues(const {'A': 60, 'B': 40});
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    key.currentState!.startFresh(const {'A': 90, 'B': 10});
    await tester.pump();
    await tester.pump();

    final rendered = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<PieSeriesElement>()
        .single
        .series;
    expect(rendered.points.map((point) => point.y), [90, 10]);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reordered radial data preserves selected category identity', (
    tester,
  ) async {
    final key = GlobalKey<_RadialAnimationHarnessState>();
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 480,
          height: 360,
          child: _RadialAnimationHarness(
            key: key,
            theme: ChartTheme.light,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();
    controller.selectPoints(const [
      ChartPointRef(seriesId: 'animated-pie', pointIndex: 1),
    ], revision: controller.effectiveDocumentRevision.value!);
    await tester.pump();

    key.currentState!.setValues(const {'B': 80, 'A': 20, 'C': 10});
    await tester.pump();

    expect(controller.selectedPointRefs, {
      const ChartPointRef(seriesId: 'animated-pie', pointIndex: 0),
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies final radial data immediately', (
    tester,
  ) async {
    final key = GlobalKey<_RadialAnimationHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SizedBox(
          width: 480,
          height: 360,
          child: _RadialAnimationHarness(key: key, theme: ChartTheme.light),
        ),
      ),
    );
    await tester.pump();
    key.currentState!.setValues(const {'A': 90, 'B': 10});
    await tester.pump();

    final series = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<PieSeriesElement>()
        .single
        .series;
    expect(series.points.map((point) => point.y), [90, 10]);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('disabled radial transitions apply final data immediately', (
    tester,
  ) async {
    final key = GlobalKey<_RadialAnimationHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 480,
          height: 360,
          child: _RadialAnimationHarness(
            key: key,
            theme: ChartTheme.light,
            transitionMode: RadialDataTransitionMode.none,
          ),
        ),
      ),
    );
    await tester.pump();
    key.currentState!.setValues(const {'A': 90, 'B': 10});
    await tester.pump();

    final series = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single
        .debugElements
        .whereType<PieSeriesElement>()
        .single
        .series;
    expect(series.points.map((point) => point.y), [90, 10]);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

class _RadialAnimationHarness extends StatefulWidget {
  const _RadialAnimationHarness({
    super.key,
    required this.theme,
    this.controller,
    this.transitionMode = RadialDataTransitionMode.automatic,
  });

  final ChartTheme theme;
  final BravenChartController? controller;
  final RadialDataTransitionMode transitionMode;

  @override
  State<_RadialAnimationHarness> createState() =>
      _RadialAnimationHarnessState();
}

class _RadialAnimationHarnessState extends State<_RadialAnimationHarness> {
  Map<String, num> values = const {'A': 20, 'B': 80};
  Object transitionKey = 'initial';

  void setValues(Map<String, num> next) => setState(() => values = next);

  void startFresh(Map<String, num> next) => setState(() {
    values = next;
    transitionKey = Object();
  });

  @override
  Widget build(BuildContext context) => BravenChartPlus(
    transitionKey: transitionKey,
    bravenChartController: widget.controller,
    showLegend: false,
    theme: widget.theme,
    series: [
      PieChartSeries.fromMap(
        id: 'animated-pie',
        values: values,
        pieStyle: PieChartStyle(
          animationMode: PieAnimationMode.none,
          dataTransitionMode: widget.transitionMode,
        ),
        dataLabels: const PieDataLabelConfig(isVisible: false),
      ),
    ],
  );
}
