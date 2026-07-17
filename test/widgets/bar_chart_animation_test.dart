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
                points: [ChartDataPoint(x: 0, y: 100)],
                barWidthPercent: 0.7,
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
    expect(series.points.single.y, 100);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _AnimatedBarHarness extends StatefulWidget {
  const _AnimatedBarHarness({super.key, required this.theme});

  final ChartTheme theme;

  @override
  State<_AnimatedBarHarness> createState() => _AnimatedBarHarnessState();
}

class _AnimatedBarHarnessState extends State<_AnimatedBarHarness> {
  double value = 100;

  void setValue(double next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) {
    return BravenChartPlus(
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
