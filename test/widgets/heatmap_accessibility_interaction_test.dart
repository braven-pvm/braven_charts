import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keyboard traverses the matrix in two dimensions and selects typed cells',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      ChartDataPoint? activated;
      String? activatedSeries;

      await tester.pumpWidget(
        _host(
          controller: controller,
          onPointTap: (point, seriesId) {
            activated = point;
            activatedSeries = seriesId;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BravenChartPlus));
      controller.clearPointSelection();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(controller.focusedPointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
      });
      var semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Interactive heatmap chart',
        ),
      );
      expect(
        semantics.properties.value,
        contains('Activity, Bottom right, column Tue, row North, 20.00 jobs'),
      );
      expect(semantics.properties.value, endsWith('not selected'));
      expect(semantics.properties.onIncrease, isNotNull);
      expect(semantics.properties.onDecrease, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(activated, isA<HeatmapDataPoint>());
      expect((activated! as HeatmapDataPoint).pointKey, 'bottom-right');
      expect(activatedSeries, 'matrix');
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 1),
      });
      semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Interactive heatmap chart',
        ),
      );
      expect(semantics.properties.value, endsWith('selected'));
      expect(semantics.properties.selected, isTrue);
    },
  );

  testWidgets('large matrices keep a bounded semantic surface', (tester) async {
    final semantics = tester.ensureSemantics();
    final points = <HeatmapDataPoint>[
      for (var row = 0; row < 30; row++)
        for (var column = 0; column < 30; column++)
          HeatmapDataPoint(
            x: column.toDouble(),
            y: row.toDouble(),
            value: (row * 30 + column).toDouble(),
            pointKey: '$row:$column',
          ),
    ];

    await tester.pumpWidget(
      _host(points: points, xCategories: null, yCategories: null),
    );
    await tester.pumpAndSettle();

    final cellNodes = tester
        .widgetList<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label?.contains('cell') ?? false),
          ),
        )
        .length;
    expect(cellNodes, lessThanOrEqualTo(200));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'viewport-backed resident snapshots replace accessible cell identity',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          points: [
            HeatmapDataPoint(
              x: 10,
              y: 0,
              value: 12,
              label: 'Resident column 10',
              pointKey: 'resident-10',
            ),
          ],
          xCategories: null,
          yCategories: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel(RegExp('Resident column 10')), findsOne);

      await tester.pumpWidget(
        _host(
          points: [
            HeatmapDataPoint(
              x: 900000,
              y: 0,
              value: 84,
              label: 'Resident column 900000',
              pointKey: 'resident-900000',
            ),
          ],
          xCategories: null,
          yCategories: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.semantics.byLabel(RegExp('Resident column 900000')),
        findsOne,
      );
      expect(
        find.semantics.byLabel(RegExp('Resident column 10')),
        findsNothing,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'selection composes with annotations, zoom, pan, and both scrollbars',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          annotations: [
            RangeAnnotation(
              id: 'focus-band',
              startX: 0,
              endX: 1,
              startY: 0,
              endY: 1,
              label: 'Focus area',
            ),
          ],
          interactionConfig: const InteractionConfig(
            tooltip: TooltipConfig(enabled: true),
            enableZoom: true,
            enablePan: true,
          ),
          showXScrollbar: true,
          showYScrollbar: true,
        ),
      );
      await tester.pumpAndSettle();

      controller.selectPoint(
        const ChartPointRef(seriesId: 'matrix', pointIndex: 2),
        revision: controller.effectiveDocumentRevision.value!,
      );
      await tester.pump();

      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'matrix', pointIndex: 2),
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard traversal preserves identity across multiple Heatmap series',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      String? activatedSeries;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 560,
              height: 380,
              child: BravenChartPlus(
                bravenChartController: controller,
                onPointTap: (_, seriesId) => activatedSeries = seriesId,
                series: [
                  HeatmapChartSeries(
                    id: 'latency',
                    name: 'Latency',
                    unit: 'ms',
                    points: [
                      HeatmapDataPoint(
                        x: 0,
                        y: 1,
                        value: 42,
                        label: 'Latency at midnight',
                      ),
                    ],
                    colorScale: HeatmapColorScale.sequential(
                      colors: const [Colors.white, Colors.blue],
                    ),
                  ),
                  HeatmapChartSeries(
                    id: 'errors',
                    name: 'Errors',
                    unit: '%',
                    points: [
                      HeatmapDataPoint(
                        x: 0,
                        y: 0,
                        value: 2,
                        label: 'Errors at midnight',
                      ),
                    ],
                    colorScale: HeatmapColorScale.sequential(
                      colors: const [Colors.white, Colors.red],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BravenChartPlus));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(controller.focusedPointRefs, {
        const ChartPointRef(seriesId: 'errors', pointIndex: 0),
      });
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Interactive heatmap chart',
        ),
      );
      expect(semantics.properties.value, contains('Errors'));
      expect(semantics.properties.value, contains('2.00 %'));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activatedSeries, 'errors');
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'errors', pointIndex: 0),
      });
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({
  BravenChartController? controller,
  List<HeatmapDataPoint>? points,
  List<String>? xCategories = const ['Mon', 'Tue'],
  List<String>? yCategories = const ['North', 'South'],
  void Function(ChartDataPoint point, String seriesId)? onPointTap,
  List<ChartAnnotation> annotations = const [],
  InteractionConfig? interactionConfig,
  bool showXScrollbar = false,
  bool showYScrollbar = false,
}) {
  final cells =
      points ??
      [
        HeatmapDataPoint(
          x: 0,
          y: 0,
          value: 10,
          label: 'Bottom left',
          pointKey: 'bottom-left',
        ),
        HeatmapDataPoint(
          x: 1,
          y: 0,
          value: 20,
          label: 'Bottom right',
          pointKey: 'bottom-right',
        ),
        HeatmapDataPoint(
          x: 0,
          y: 1,
          value: 30,
          label: 'Top left',
          pointKey: 'top-left',
        ),
        HeatmapDataPoint(
          x: 1,
          y: 1,
          value: 40,
          label: 'Top right',
          pointKey: 'top-right',
        ),
      ];
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 560,
        height: 380,
        child: BravenChartPlus(
          bravenChartController: controller,
          onPointTap: onPointTap,
          annotations: annotations,
          interactiveAnnotations: true,
          showXScrollbar: showXScrollbar,
          showYScrollbar: showYScrollbar,
          interactionConfig: interactionConfig,
          xAxisConfig: xCategories == null
              ? const XAxisConfig()
              : XAxisConfig(
                  categoryAxis: CategoryAxisConfig(categories: xCategories),
                ),
          yAxis: yCategories == null
              ? YAxisConfig(position: YAxisPosition.left)
              : YAxisConfig(
                  position: YAxisPosition.left,
                  categoryAxis: CategoryAxisConfig(categories: yCategories),
                ),
          series: [
            HeatmapChartSeries(
              id: 'matrix',
              name: 'Activity',
              unit: 'jobs',
              points: cells,
              colorScale: HeatmapColorScale.sequential(
                colors: const [Colors.white, Colors.blue],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
