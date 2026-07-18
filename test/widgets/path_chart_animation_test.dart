import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseTheme = ChartTheme.light;
  late ChartTheme theme;

  setUp(() {
    theme = baseTheme.copyWith(
      animationTheme: baseTheme.animationTheme.copyWith(
        dataUpdateDuration: const Duration(milliseconds: 400),
        dataUpdateCurve: Curves.linear,
      ),
    );
  });

  SeriesElement renderedElement(WidgetTester tester) {
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    return renderBox.debugElements.whereType<SeriesElement>().single;
  }

  List<SeriesElement> renderedElements(WidgetTester tester) {
    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    return renderBox.debugElements.whereType<SeriesElement>().toList();
  }

  testWidgets('Line entrance reveals through the standard SeriesElement', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chartHost(
        theme: theme,
        series: const LineChartSeries(
          id: 'line',
          points: [ChartDataPoint(x: 0, y: 10), ChartDataPoint(x: 1, y: 20)],
          pathAnimation: PathAnimationStyle(
            entranceMode: PathEntranceAnimationMode.reveal,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(renderedElement(tester).revealProgress, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedElement(tester).revealProgress, closeTo(0.5, 0.01));
    await tester.pumpAndSettle();
    expect(renderedElement(tester).revealProgress, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance reveal is interpolation agnostic', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: BravenChartPlus(
            showLegend: false,
            theme: theme,
            xAxisConfig: const XAxisConfig(min: 0, max: 2),
            yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 60),
            series: [
              for (
                var index = 0;
                index < LineInterpolation.values.length;
                index++
              )
                LineChartSeries(
                  id: LineInterpolation.values[index].name,
                  interpolation: LineInterpolation.values[index],
                  points: [
                    ChartDataPoint(x: 0, y: 10 + (index * 10)),
                    ChartDataPoint(x: 1, y: 20 + (index * 10)),
                  ],
                  pathAnimation: const PathAnimationStyle(
                    entranceMode: PathEntranceAnimationMode.reveal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      renderedElements(tester),
      hasLength(LineInterpolation.values.length),
    );
    expect(
      renderedElements(tester).map((element) => element.revealProgress),
      everyElement(0),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      renderedElements(tester).map((element) => element.revealProgress),
      everyElement(closeTo(0.5, 0.01)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrance reveal uses independent per-series timing windows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: BravenChartPlus(
            showLegend: false,
            theme: theme,
            series: const [
              LineChartSeries(
                id: 'observed',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                ],
                pathAnimation: PathAnimationStyle(
                  entranceMode: PathEntranceAnimationMode.reveal,
                  entranceTiming: PathAnimationTiming(
                    duration: Duration(milliseconds: 200),
                  ),
                ),
              ),
              LineChartSeries(
                id: 'plan',
                points: [
                  ChartDataPoint(x: 0, y: 30),
                  ChartDataPoint(x: 1, y: 40),
                ],
                pathAnimation: PathAnimationStyle(
                  entranceMode: PathEntranceAnimationMode.reveal,
                  entranceTiming: PathAnimationTiming(
                    delay: Duration(milliseconds: 200),
                    duration: Duration(milliseconds: 400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    Map<String, double> progress() => {
      for (final element in renderedElements(tester))
        element.series.id: element.revealProgress,
    };

    expect(progress(), {'observed': 0, 'plan': 0});
    await tester.pump(const Duration(milliseconds: 100));
    expect(progress()['observed'], closeTo(0.5, 0.01));
    expect(progress()['plan'], 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(progress(), {'observed': 1, 'plan': 0});
    await tester.pump(const Duration(milliseconds: 200));
    expect(progress()['observed'], 1);
    expect(progress()['plan'], closeTo(0.5, 0.01));
    await tester.pumpAndSettle();
    expect(progress(), {'observed': 1, 'plan': 1});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Area data updates use interpolated in-flight geometry', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedAreaHarnessState>();
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _AnimatedAreaHarness(key: key, theme: theme, controller: controller),
    );
    await tester.pumpAndSettle();

    key.currentState!.setValues([30, 50]);
    await tester.pump();
    await tester.pump();

    final snapshot =
        (controller.extractDocument()
                as ChartArtifactSuccess<ChartDocumentSnapshot>)
            .value;
    final decoded =
        (ChartSeriesDocumentCodec.decode(snapshot.document.series.single)
                    as ChartArtifactSuccess<ChartSeries>)
                .value
            as AreaChartSeries;
    expect(decoded.points.map((point) => point.y), [30, 50]);

    await tester.pump(const Duration(milliseconds: 200));

    final midSeries = renderedElement(tester).series as AreaChartSeries;
    expect(midSeries.points.map((point) => point.y), [20, 35]);
    await tester.pumpAndSettle();
    final finalSeries = renderedElement(tester).series as AreaChartSeries;
    expect(finalSeries.points.map((point) => point.y), [30, 50]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Line and Area updates complete on independent timing windows', (
    tester,
  ) async {
    final key = GlobalKey<_StaggeredPathHarnessState>();
    await tester.pumpWidget(_StaggeredPathHarness(key: key, theme: theme));
    await tester.pumpAndSettle();

    key.currentState!.useTargetValues();
    await tester.pump();
    await tester.pump();

    Map<String, ChartSeries> series() => {
      for (final element in renderedElements(tester))
        element.series.id: element.series,
    };

    await tester.pump(const Duration(milliseconds: 100));
    expect(series()['observed']!.points.map((point) => point.y), [20, 30]);
    expect(series()['plan']!.points.map((point) => point.y), [20, 30]);

    await tester.pump(const Duration(milliseconds: 100));
    expect(series()['observed']!.points.map((point) => point.y), [30, 40]);
    expect(series()['plan']!.points.map((point) => point.y), [20, 30]);

    await tester.pump(const Duration(milliseconds: 200));
    expect(series()['observed']!.points.map((point) => point.y), [30, 40]);
    expect(series()['plan']!.points.map((point) => point.y), [30, 40]);

    await tester.pumpAndSettle();
    expect(series()['observed']!.points.map((point) => point.y), [30, 40]);
    expect(series()['plan']!.points.map((point) => point.y), [40, 50]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Line append grows from the rendered tail without reveal', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedLineHarnessState>();
    await tester.pumpWidget(_AnimatedLineHarness(key: key, theme: theme));
    await tester.pumpAndSettle();

    key.currentState!.addPoint();
    await tester.pump();
    await tester.pump();

    expect(renderedElement(tester).revealProgress, 1);
    expect(
      (renderedElement(tester).series as LineChartSeries).points.map(
        (point) => point.x,
      ),
      [0, 1, 1],
    );
    await tester.pump(const Duration(milliseconds: 200));
    final midpoint = renderedElement(tester).series as LineChartSeries;
    expect(renderedElement(tester).revealProgress, 1);
    expect(midpoint.points.map((point) => point.x), [0, 1, 1.5]);
    expect(midpoint.points.map((point) => point.y), [10, 20, 25]);
    await tester.pumpAndSettle();
    expect(
      (renderedElement(tester).series as LineChartSeries).points.map(
        (point) => point.x,
      ),
      [0, 1, 2],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Area rolling window shares one in-flight render geometry', (
    tester,
  ) async {
    final key = GlobalKey<_RollingAreaHarnessState>();
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _RollingAreaHarness(key: key, theme: theme, controller: controller),
    );
    await tester.pumpAndSettle();

    const retainedB = ChartPointRef(seriesId: 'area', pointIndex: 1);
    final revision = controller.effectiveDocumentRevision.value!;
    controller.selectPoint(retainedB, revision: revision);
    controller.focusPoint(retainedB, revision: revision);
    await tester.pump();

    key.currentState!.rollWindow();
    await tester.pump();
    await tester.pump();

    const remappedB = ChartPointRef(seriesId: 'area', pointIndex: 0);
    expect(controller.selectedPointRefs, {remappedB});
    expect(controller.focusedPointRefs, {remappedB});

    final targetSnapshot =
        (controller.extractDocument()
                as ChartArtifactSuccess<ChartDocumentSnapshot>)
            .value;
    final target =
        (ChartSeriesDocumentCodec.decode(targetSnapshot.document.series.single)
                    as ChartArtifactSuccess<ChartSeries>)
                .value
            as AreaChartSeries;
    expect(target.points.map((point) => point.label), ['B', 'C', 'D']);

    await tester.pump(const Duration(milliseconds: 200));
    final midpoint = renderedElement(tester).series as AreaChartSeries;
    expect(midpoint.points.map((point) => point.label), ['A', 'B', 'C', 'D']);
    expect(midpoint.points.map((point) => point.x), [0.5, 1, 2, 2.5]);
    expect(midpoint.points.map((point) => point.y), [17, 22, 32, 37]);
    final element = renderedElement(tester);
    final retainedHit = element.dataHitForPointIndex(0)!;
    expect(retainedHit.point.label, 'B');
    expect(retainedHit.pointIndex, 0);
    expect(retainedHit.count, 3);
    expect(retainedHit.isSelected, isTrue);
    expect(retainedHit.isFocused, isTrue);
    expect(
      element.dataHitAt(
        element.transform.dataToPlot(
          midpoint.points.first.x,
          midpoint.points.first.y,
        ),
        maxDistance: 1,
      ),
      isNull,
    );
    final enteringHit = element.dataHitForPointIndex(2)!;
    expect(enteringHit.point, midpoint.points.last);
    expect(enteringHit.pointIndex, 2);
    expect(
      enteringHit.plotPosition,
      element.transform.dataToPlot(
        midpoint.points.last.x,
        midpoint.points.last.y,
      ),
    );

    await tester.pumpAndSettle();
    final completed = renderedElement(tester).series as AreaChartSeries;
    expect(completed.points.map((point) => point.label), ['B', 'C', 'D']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid rolling updates preserve geometry and point identity', (
    tester,
  ) async {
    final key = GlobalKey<_RollingAreaHarnessState>();
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _RollingAreaHarness(key: key, theme: theme, controller: controller),
    );
    await tester.pumpAndSettle();

    const initialC = ChartPointRef(seriesId: 'area', pointIndex: 2);
    final revision = controller.effectiveDocumentRevision.value!;
    controller.selectPoint(initialC, revision: revision);
    controller.focusPoint(initialC, revision: revision);
    await tester.pump();

    key.currentState!.rollWindow();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    const firstRemap = ChartPointRef(seriesId: 'area', pointIndex: 1);
    expect(controller.selectedPointRefs, {firstRemap});
    expect(controller.focusedPointRefs, {firstRemap});
    final interrupted = renderedElement(tester).series as AreaChartSeries;
    final interruptedByLabel = {
      for (final point in interrupted.points) point.label!: (point.x, point.y),
    };

    key.currentState!.rollWindow();
    await tester.pump();
    await tester.pump();

    const secondRemap = ChartPointRef(seriesId: 'area', pointIndex: 0);
    expect(controller.selectedPointRefs, {secondRemap});
    expect(controller.focusedPointRefs, {secondRemap});
    final restartedElement = renderedElement(tester);
    final restarted = restartedElement.series as AreaChartSeries;
    final restartedByLabel = {
      for (final point in restarted.points) point.label!: (point.x, point.y),
    };
    for (final label in const ['A', 'B', 'C', 'D']) {
      expect(restartedByLabel[label], interruptedByLabel[label]);
    }
    final retainedHit = restartedElement.dataHitForPointIndex(0)!;
    expect(retainedHit.point.label, 'C');
    expect(retainedHit.isSelected, isTrue);
    expect(retainedHit.isFocused, isTrue);
    final exitingA = restarted.points.firstWhere((point) => point.label == 'A');
    expect(
      restartedElement.dataHitAt(
        restartedElement.transform.dataToPlot(exitingA.x, exitingA.y),
        maxDistance: 1,
      ),
      isNull,
    );

    await tester.pumpAndSettle();
    final completed = renderedElement(tester).series as AreaChartSeries;
    expect(completed.points.map((point) => point.label), ['C', 'D', 'E']);
    expect(controller.selectedPointRefs, {secondRemap});
    expect(controller.focusedPointRefs, {secondRemap});
    expect(tester.takeException(), isNull);
  });

  testWidgets('rolling removes focus and selection for an exiting identity', (
    tester,
  ) async {
    final key = GlobalKey<_RollingAreaHarnessState>();
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _RollingAreaHarness(key: key, theme: theme, controller: controller),
    );
    await tester.pumpAndSettle();

    const exitingA = ChartPointRef(seriesId: 'area', pointIndex: 0);
    final revision = controller.effectiveDocumentRevision.value!;
    controller.selectPoint(exitingA, revision: revision);
    controller.focusPoint(exitingA, revision: revision);
    await tester.pump();

    key.currentState!.rollWindow();
    await tester.pump();
    await tester.pump();

    expect(controller.selectedPointRefs, isEmpty);
    expect(controller.focusedPointRefs, isEmpty);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller replays path entrance and honors reduced motion', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);

    Widget build({required bool disableAnimations}) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: SizedBox(
        width: 520,
        height: 360,
        child: BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          theme: theme,
          series: const [
            LineChartSeries(
              id: 'line',
              points: [
                ChartDataPoint(x: 0, y: 10),
                ChartDataPoint(x: 1, y: 20),
              ],
              pathAnimation: PathAnimationStyle(
                entranceMode: PathEntranceAnimationMode.reveal,
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(build(disableAnimations: false));
    await tester.pumpAndSettle();
    controller.replaySeriesEntrance();
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await tester.pumpWidget(build(disableAnimations: true));
    await tester.pump();
    controller.replaySeriesEntrance();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(renderedElement(tester).revealProgress, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero-duration motion renders its final frame immediately', (
    tester,
  ) async {
    final zeroTheme = baseTheme.copyWith(
      animationTheme: baseTheme.animationTheme.copyWith(
        dataUpdateDuration: Duration.zero,
      ),
    );
    await tester.pumpWidget(
      _chartHost(
        theme: zeroTheme,
        series: const LineChartSeries(
          id: 'line',
          points: [ChartDataPoint(x: 0, y: 10), ChartDataPoint(x: 1, y: 20)],
          pathAnimation: PathAnimationStyle(
            entranceMode: PathEntranceAnimationMode.reveal,
            dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
            entranceTiming: PathAnimationTiming(
              delay: Duration(seconds: 1),
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(renderedElement(tester).revealProgress, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero-duration theme completes an active staggered phase', (
    tester,
  ) async {
    final key = GlobalKey<_StaggeredPathHarnessState>();
    await tester.pumpWidget(_StaggeredPathHarness(key: key, theme: theme));
    await tester.pumpAndSettle();

    key.currentState!.useTargetValues();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);

    final zeroTheme = theme.copyWith(
      animationTheme: theme.animationTheme.copyWith(
        dataUpdateDuration: Duration.zero,
      ),
    );
    await tester.pumpWidget(_StaggeredPathHarness(key: key, theme: zeroTheme));
    await tester.pump();

    final seriesById = {
      for (final element in renderedElements(tester))
        element.series.id: element.series,
    };
    expect(
      (seriesById['observed']! as LineChartSeries).points.map(
        (point) => point.y,
      ),
      [30, 40],
    );
    expect(
      (seriesById['plan']! as AreaChartSeries).points.map((point) => point.y),
      [40, 50],
    );
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies topology targets immediately', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedLineHarnessState>();
    await tester.pumpWidget(
      _AnimatedLineHarness(key: key, theme: theme, disableAnimations: true),
    );
    await tester.pump();

    key.currentState!.addPoint();
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(
      (renderedElement(tester).series as LineChartSeries).points.map(
        (point) => point.x,
      ),
      [0, 1, 2],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-axis target bounds stay stable during path updates', (
    tester,
  ) async {
    final key = GlobalKey<_MultiAxisPathHarnessState>();
    await tester.pumpWidget(_MultiAxisPathHarness(key: key, theme: theme));
    await tester.pumpAndSettle();

    key.currentState!.useTargetValues();
    await tester.pump();
    await tester.pump();

    Map<String, (double, double)> bounds() => {
      for (final element in renderedElements(tester))
        element.series.id: (
          element.transform.dataYMin,
          element.transform.dataYMax,
        ),
    };

    final startBounds = bounds();
    await tester.pump(const Duration(milliseconds: 200));
    final midpointBounds = bounds();
    final midpointSeries = {
      for (final element in renderedElements(tester))
        element.series.id: element.series,
    };
    final midpointPower = midpointSeries['power'] as LineChartSeries;
    expect(midpointPower.points, hasLength(3));
    expect(midpointPower.points.last.y, closeTo(55, 0.01));
    expect(midpointBounds, startBounds);

    await tester.pumpAndSettle();
    expect(bounds(), startBounds);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller-fed tails do not trigger a second path animation', (
    tester,
  ) async {
    final dataController = ChartController();
    addTearDown(dataController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 520,
          height: 360,
          child: BravenChartPlus(
            controller: dataController,
            showLegend: false,
            theme: theme,
            autoScrollConfig: const AutoScrollConfig(
              enabled: true,
              animateIncomingData: true,
              incomingDataAnimationDuration: Duration(milliseconds: 400),
            ),
            xAxisConfig: const XAxisConfig(min: 0, max: 3),
            yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 60),
            series: const [
              LineChartSeries(
                id: 'line',
                points: [
                  ChartDataPoint(x: 0, y: 10),
                  ChartDataPoint(x: 1, y: 20),
                ],
                pathAnimation: PathAnimationStyle(
                  entranceMode: PathEntranceAnimationMode.reveal,
                  dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    dataController.addPoint('line', const ChartDataPoint(x: 2, y: 40));
    await tester.pump();
    expect(renderedElement(tester).revealProgress, 1);
    expect(renderedElement(tester).series.points.last.y, 20);

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedElement(tester).revealProgress, 1);
    expect(renderedElement(tester).series.points.last.y, closeTo(30, 0.01));
    await tester.pumpAndSettle();
    expect(renderedElement(tester).series.points.last.y, 40);
    expect(tester.takeException(), isNull);
  });
}

Widget _chartHost({
  required ChartTheme theme,
  required ChartSeries series,
  bool disableAnimations = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: child!,
  ),
  home: SizedBox(
    width: 520,
    height: 360,
    child: BravenChartPlus(
      bravenChartController: null,
      showLegend: false,
      theme: theme,
      xAxisConfig: const XAxisConfig(min: 0, max: 2),
      yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 60),
      series: [series],
    ),
  ),
);

class _AnimatedAreaHarness extends StatefulWidget {
  const _AnimatedAreaHarness({
    super.key,
    required this.theme,
    required this.controller,
  });

  final ChartTheme theme;
  final BravenChartController controller;

  @override
  State<_AnimatedAreaHarness> createState() => _AnimatedAreaHarnessState();
}

class _StaggeredPathHarness extends StatefulWidget {
  const _StaggeredPathHarness({super.key, required this.theme});

  final ChartTheme theme;

  @override
  State<_StaggeredPathHarness> createState() => _StaggeredPathHarnessState();
}

class _StaggeredPathHarnessState extends State<_StaggeredPathHarness> {
  var target = false;

  void useTargetValues() => setState(() => target = true);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: SizedBox(
      width: 520,
      height: 360,
      child: BravenChartPlus(
        showLegend: false,
        theme: widget.theme,
        xAxisConfig: const XAxisConfig(min: 0, max: 1),
        yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 60),
        series: [
          LineChartSeries(
            id: 'observed',
            points: target
                ? const [
                    ChartDataPoint(x: 0, y: 30),
                    ChartDataPoint(x: 1, y: 40),
                  ]
                : const [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 20),
                  ],
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
              dataUpdateTiming: PathAnimationTiming(
                duration: Duration(milliseconds: 200),
              ),
            ),
          ),
          AreaChartSeries(
            id: 'plan',
            points: target
                ? const [
                    ChartDataPoint(x: 0, y: 40),
                    ChartDataPoint(x: 1, y: 50),
                  ]
                : const [
                    ChartDataPoint(x: 0, y: 20),
                    ChartDataPoint(x: 1, y: 30),
                  ],
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
              dataUpdateTiming: PathAnimationTiming(
                delay: Duration(milliseconds: 200),
                duration: Duration(milliseconds: 400),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AnimatedAreaHarnessState extends State<_AnimatedAreaHarness> {
  List<double> values = const [10, 20];

  void setValues(List<double> next) => setState(() => values = next);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: SizedBox(
      width: 520,
      height: 360,
      child: BravenChartPlus(
        bravenChartController: widget.controller,
        showLegend: false,
        theme: widget.theme,
        xAxisConfig: const XAxisConfig(min: 0, max: 2),
        yAxis: YAxisConfig(position: YAxisPosition.left, min: 0, max: 60),
        series: [
          AreaChartSeries(
            id: 'area',
            points: [
              ChartDataPoint(x: 0, y: values[0]),
              ChartDataPoint(x: 1, y: values[1]),
            ],
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AnimatedLineHarness extends StatefulWidget {
  const _AnimatedLineHarness({
    super.key,
    required this.theme,
    this.disableAnimations = false,
  });

  final ChartTheme theme;
  final bool disableAnimations;

  @override
  State<_AnimatedLineHarness> createState() => _AnimatedLineHarnessState();
}

class _AnimatedLineHarnessState extends State<_AnimatedLineHarness> {
  var pointCount = 2;

  void addPoint() => setState(() => pointCount = 3);

  @override
  Widget build(BuildContext context) => _chartHost(
    theme: widget.theme,
    disableAnimations: widget.disableAnimations,
    series: LineChartSeries(
      id: 'line',
      points: [
        const ChartDataPoint(x: 0, y: 10),
        const ChartDataPoint(x: 1, y: 20),
        if (pointCount == 3) const ChartDataPoint(x: 2, y: 30),
      ],
      pathAnimation: const PathAnimationStyle(
        entranceMode: PathEntranceAnimationMode.reveal,
        dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
      ),
    ),
  );
}

class _RollingAreaHarness extends StatefulWidget {
  const _RollingAreaHarness({
    super.key,
    required this.theme,
    required this.controller,
  });

  final ChartTheme theme;
  final BravenChartController controller;

  @override
  State<_RollingAreaHarness> createState() => _RollingAreaHarnessState();
}

class _RollingAreaHarnessState extends State<_RollingAreaHarness> {
  var windowOffset = 0;

  void rollWindow() => setState(() => windowOffset++);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: SizedBox(
      width: 520,
      height: 360,
      child: BravenChartPlus(
        bravenChartController: widget.controller,
        showLegend: false,
        theme: widget.theme,
        series: [
          AreaChartSeries(
            id: 'area',
            points: switch (windowOffset) {
              0 => const [
                ChartDataPoint(x: 0, y: 10, label: 'A'),
                ChartDataPoint(x: 1, y: 20, label: 'B'),
                ChartDataPoint(x: 2, y: 30, label: 'C'),
              ],
              1 => const [
                ChartDataPoint(x: 1, y: 24, label: 'B'),
                ChartDataPoint(x: 2, y: 34, label: 'C'),
                ChartDataPoint(x: 3, y: 44, label: 'D'),
              ],
              _ => const [
                ChartDataPoint(x: 2, y: 38, label: 'C'),
                ChartDataPoint(x: 3, y: 48, label: 'D'),
                ChartDataPoint(x: 4, y: 58, label: 'E'),
              ],
            },
            showDataPointMarkers: true,
            dataPointLabels: const DataPointLabelConfig(show: true),
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MultiAxisPathHarness extends StatefulWidget {
  const _MultiAxisPathHarness({super.key, required this.theme});

  final ChartTheme theme;

  @override
  State<_MultiAxisPathHarness> createState() => _MultiAxisPathHarnessState();
}

class _MultiAxisPathHarnessState extends State<_MultiAxisPathHarness> {
  var target = false;

  void useTargetValues() => setState(() => target = true);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: SizedBox(
      width: 520,
      height: 360,
      child: BravenChartPlus(
        showLegend: false,
        theme: widget.theme,
        normalizationMode: NormalizationMode.perSeries,
        xAxisConfig: const XAxisConfig(min: 0, max: 2),
        series: [
          LineChartSeries(
            id: 'power',
            points: target
                ? const [
                    ChartDataPoint(x: 0, y: 30),
                    ChartDataPoint(x: 1, y: 60),
                    ChartDataPoint(x: 2, y: 90),
                  ]
                : const [
                    ChartDataPoint(x: 0, y: 10),
                    ChartDataPoint(x: 1, y: 20),
                  ],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
            ),
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
            ),
          ),
          LineChartSeries(
            id: 'heart-rate',
            points: target
                ? const [
                    ChartDataPoint(x: 0, y: 300),
                    ChartDataPoint(x: 1, y: 600),
                    ChartDataPoint(x: 2, y: 900),
                  ]
                : const [
                    ChartDataPoint(x: 0, y: 100),
                    ChartDataPoint(x: 1, y: 200),
                  ],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              label: 'Heart rate',
              unit: 'bpm',
            ),
            pathAnimation: const PathAnimationStyle(
              dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
            ),
          ),
        ],
      ),
    ),
  );
}
