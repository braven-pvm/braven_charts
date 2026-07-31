import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts/src/widgets/pie_chart_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('automatic legend omits opted-out series only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 420,
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'observed',
                name: 'Observed',
                points: [ChartDataPoint(x: 0, y: 42)],
              ),
              RangeAreaChartSeries(
                id: 'interval',
                name: 'Forecast interval',
                points: [RangeAreaDataPoint(x: 0, low: 35, high: 48)],
                showInLegend: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legend = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .single;

    expect(legend.annotation.series.map((series) => series.id), ['observed']);
  });

  testWidgets('radial legend omits an opted-out pie series', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 420,
          child: BravenChartPlus(
            showLegend: true,
            series: [
              PieChartSeries.fromMap(
                id: 'private-breakdown',
                values: const {'A': 4, 'B': 3, 'C': 2},
                showInLegend: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PieChartLegend), findsNothing);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct ChartLegend omits opted-out series completely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartLegend(
            series: [
              LineChartSeries(
                id: 'observed',
                name: 'Observed',
                points: [ChartDataPoint(x: 0, y: 42)],
              ),
              RangeAreaChartSeries(
                id: 'interval',
                name: 'Forecast interval',
                points: [RangeAreaDataPoint(x: 0, low: 35, high: 48)],
                showInLegend: false,
              ),
            ],
            hiddenSeriesIds: const {},
            onSeriesToggle: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Observed'), findsOneWidget);
    expect(find.text('Forecast interval'), findsNothing);
  });

  testWidgets('explicit canvas legend omits opted-out series completely', (
    tester,
  ) async {
    final observed = LineChartSeries(
      id: 'observed',
      name: 'Observed',
      points: [ChartDataPoint(x: 0, y: 42)],
    );
    final interval = RangeAreaChartSeries(
      id: 'interval',
      name: 'Forecast interval',
      points: [RangeAreaDataPoint(x: 0, low: 35, high: 48)],
      showInLegend: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 420,
          child: BravenChartPlus(
            showLegend: false,
            series: [observed, interval],
            annotations: [
              LegendAnnotation(series: [observed, interval]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legend = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .single;

    expect(legend.debugSeriesIds, ['observed']);
  });

  testWidgets('legend renders bar and path-aware series swatches', (
    tester,
  ) async {
    String? toggledId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartLegend(
            series: [
              BarChartSeries(
                id: 'forecast',
                name: 'Forecast',
                points: [ChartDataPoint(x: 0, y: 42)],
                color: Color(0xFF386A78),
                barWidthPercent: 0.7,
                barStyle: BarChartStyle(
                  pattern: BarPatternStyle(pattern: BarFillPattern.crosshatch),
                ),
              ),
              LineChartSeries(
                id: 'trend',
                name: 'Trend',
                points: [ChartDataPoint(x: 0, y: 42)],
                color: Color(0xFF386A78),
                dashPattern: [2, 6],
              ),
              AreaChartSeries(
                id: 'range',
                name: 'Range',
                points: [ChartDataPoint(x: 0, y: 38)],
                color: Color(0xFF805AD5),
              ),
              CandlestickChartSeries(
                id: 'price',
                name: 'Price',
                points: [
                  CandlestickDataPoint(
                    x: 0,
                    open: 40,
                    high: 45,
                    low: 38,
                    close: 43,
                  ),
                ],
                color: Color(0xFF0F766E),
              ),
            ],
            hiddenSeriesIds: const {},
            onSeriesToggle: (id) => toggledId = id,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size == const Size(18, 12),
      ),
      findsNWidgets(3),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size == const Size(18, 16),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
      findsNothing,
    );

    await tester.tap(find.text('Forecast'));
    expect(toggledId, 'forecast');
  });
}
