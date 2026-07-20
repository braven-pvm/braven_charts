import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'one navigator controls Line Area Bar Scatter and Candlestick charts',
    (tester) async {
      final group = ChartInteractionGroupController();
      final cartesianPoints = <ChartDataPoint>[
        for (var x = 0; x <= 10; x += 2)
          ChartDataPoint(x: x.toDouble(), y: 20 + x.toDouble()),
      ];
      final candles = <CandlestickDataPoint>[
        for (var x = 0; x <= 10; x += 2)
          CandlestickDataPoint(
            x: x.toDouble(),
            open: 20 + x.toDouble(),
            high: 23 + x.toDouble(),
            low: 18 + x.toDouble(),
            close: 21 + x.toDouble(),
          ),
      ];

      Widget controlled(String id, ChartSeries series) => SizedBox(
        height: 90,
        child: BravenChartPlus(
          key: ValueKey('controlled-$id'),
          interactionGroupController: group,
          series: <ChartSeries>[series],
          showLegend: false,
          xAxisConfig: const XAxisConfig(visible: false),
          yAxis: YAxisConfig(position: YAxisPosition.hidden, visible: false),
          interactionConfig: const InteractionConfig(
            enableZoom: true,
            enablePan: true,
            crosshair: CrosshairConfig(enabled: false),
            tooltip: TooltipConfig(enabled: false),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                controlled(
                  'line',
                  LineChartSeries(id: 'line', points: cartesianPoints),
                ),
                controlled(
                  'area',
                  AreaChartSeries(id: 'area', points: cartesianPoints),
                ),
                controlled(
                  'bar',
                  BarChartSeries(
                    id: 'bar',
                    points: cartesianPoints,
                    barWidthPercent: .7,
                  ),
                ),
                controlled(
                  'scatter',
                  ScatterChartSeries(id: 'scatter', points: cartesianPoints),
                ),
                controlled(
                  'candlestick',
                  CandlestickChartSeries(id: 'candlestick', points: candles),
                ),
                SizedBox(
                  height: 96,
                  child: CartesianNavigator(
                    interactionGroupController: group,
                    fullDomain: const ChartXViewport(min: 0, max: 10),
                    initialViewport: const ChartXViewport(min: 2, max: 8),
                    snapPolicy: CartesianNavigatorSnapPolicy.interval(2),
                    overviewSeries: AreaChartSeries(
                      id: 'overview',
                      points: cartesianPoints,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      ChartRenderBox renderBox(String id) =>
          tester.renderObject<ChartRenderBox>(
            find.descendant(
              of: find.byKey(ValueKey('controlled-$id')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget.runtimeType.toString() == '_ChartRenderWidget',
              ),
            ),
          );

      for (final id in <String>[
        'line',
        'area',
        'bar',
        'scatter',
        'candlestick',
      ]) {
        expect(renderBox(id).transform!.dataXMin, 2, reason: id);
        expect(renderBox(id).transform!.dataXMax, 8, reason: id);
      }

      group.setViewport(const ChartXViewport(min: 4, max: 6));
      await tester.pump();

      for (final id in <String>[
        'line',
        'area',
        'bar',
        'scatter',
        'candlestick',
      ]) {
        expect(renderBox(id).transform!.dataXMin, 4, reason: id);
        expect(renderBox(id).transform!.dataXMax, 6, reason: id);
      }
      expect(group.cursorX, isNull);
      expect(tester.takeException(), isNull);
      group.dispose();
    },
  );

  testWidgets(
    'external navigator viewport remains authoritative during live ingestion',
    (tester) async {
      final group = ChartInteractionGroupController();
      final live = LiveStreamController(
        seriesId: 'live',
        maxPoints: 100,
        autoScroll: true,
        viewportDataPoints: 6,
        manageViewport: false,
      );
      addTearDown(group.dispose);
      addTearDown(live.dispose);
      for (var x = 0; x <= 10; x++) {
        live.addPoint(ChartDataPoint(x: x.toDouble(), y: 20 + x.toDouble()));
      }
      group.setViewport(const ChartXViewport(min: 2, max: 8));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: BravenChartPlus(
                    key: const ValueKey('live-controlled-chart'),
                    interactionGroupController: group,
                    liveStreamController: live,
                    series: const [
                      LineChartSeries(
                        id: 'live',
                        points: const [],
                        interpolation: LineInterpolation.monotone,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 96,
                  child: CartesianNavigator(
                    interactionGroupController: group,
                    fullDomain: const ChartXViewport(min: 0, max: 20),
                    initialViewport: const ChartXViewport(min: 2, max: 8),
                    overviewSeries: AreaChartSeries(
                      id: 'live-overview',
                      points: [
                        for (var x = 0; x <= 20; x++)
                          ChartDataPoint(x: x.toDouble(), y: 20 + x.toDouble()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      group.setViewport(const ChartXViewport(min: 1, max: 5));
      await tester.pump();
      live.addPoint(const ChartDataPoint(x: 20, y: 40));
      await tester.pump();
      await tester.pump();

      final renderBox = tester.renderObject<ChartRenderBox>(
        find.descendant(
          of: find.byKey(const ValueKey('live-controlled-chart')),
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        ),
      );
      expect(live.latestPoint!.x, 20);
      expect(group.viewport, const ChartXViewport(min: 1, max: 5));
      expect(renderBox.transform!.dataXMin, 1);
      expect(renderBox.transform!.dataXMax, 5);
      expect(tester.takeException(), isNull);
    },
  );
}
