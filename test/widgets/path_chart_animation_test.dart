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
