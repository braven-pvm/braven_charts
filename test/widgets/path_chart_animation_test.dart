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

  testWidgets('incompatible Line topology falls back to entrance reveal', (
    tester,
  ) async {
    final key = GlobalKey<_AnimatedLineHarnessState>();
    await tester.pumpWidget(_AnimatedLineHarness(key: key, theme: theme));
    await tester.pumpAndSettle();

    key.currentState!.addPoint();
    await tester.pump();
    await tester.pump();

    expect(renderedElement(tester).revealProgress, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderedElement(tester).revealProgress, closeTo(0.5, 0.01));
    expect(
      (renderedElement(tester).series as LineChartSeries).points.length,
      3,
    );
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
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(renderedElement(tester).revealProgress, 1);
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
    expect(
      (midpointSeries['power'] as LineChartSeries).points.last.y,
      closeTo(40, 0.01),
    );
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

Widget _chartHost({required ChartTheme theme, required ChartSeries series}) =>
    MaterialApp(
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
  const _AnimatedLineHarness({super.key, required this.theme});

  final ChartTheme theme;

  @override
  State<_AnimatedLineHarness> createState() => _AnimatedLineHarnessState();
}

class _AnimatedLineHarnessState extends State<_AnimatedLineHarness> {
  var pointCount = 2;

  void addPoint() => setState(() => pointCount = 3);

  @override
  Widget build(BuildContext context) => _chartHost(
    theme: widget.theme,
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
