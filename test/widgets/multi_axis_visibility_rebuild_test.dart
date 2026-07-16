import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _powerColor = Color(0xFFFF00FF);

void main() {
  testWidgets(
    'visible multi-axis path survives hide, keyed reorder, and restore',
    (tester) async {
      final controller = BravenChartController();
      final hostKey = GlobalKey<_ReorderHostState>();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _ReorderHost(key: hostKey, controller: controller),
      );
      await tester.pump();

      expect(
        _hitSeries(
          tester,
          seriesId: 'power',
          minY: 120,
          maxY: 210,
          point: const ChartDataPoint(x: 1, y: 180),
        ),
        isTrue,
      );

      controller.setSeriesVisible('heart-rate', false);
      await tester.pump();
      hostKey.currentState!.reorder();
      await tester.pump();

      final hiddenSnapshot = _success(controller.extractDocument());
      final visibleSnapshot = _success(
        controller.extractDocument(
          const ChartDocumentExtractOptions(
            dataScope: ChartDataScope.visibleSeries,
          ),
        ),
      );

      expect(controller.hiddenSeriesIds, {'heart-rate'});
      expect(controller.visibleAxisIds, ['power_axis']);
      expect(hiddenSnapshot.document.series.map((series) => series.id), [
        'power',
        'heart-rate',
      ]);
      expect(hiddenSnapshot.viewState?.hiddenSeriesIds, {'heart-rate'});
      expect(hiddenSnapshot.viewState?.visibleAxisIds, ['power_axis']);
      expect(visibleSnapshot.document.series.map((series) => series.id), [
        'power',
      ]);
      expect(
        _hitSeries(
          tester,
          seriesId: 'power',
          minY: 120,
          maxY: 210,
          point: const ChartDataPoint(x: 1, y: 180),
        ),
        isTrue,
        reason: 'The remaining Power path must retain its per-axis transform.',
      );

      controller.setSeriesVisible('heart-rate', true);
      await tester.pump();
      hostKey.currentState!.reorder();
      await tester.pump();

      expect(controller.hiddenSeriesIds, isEmpty);
      expect(controller.visibleAxisIds, ['power_axis', 'heart-rate_axis']);
      expect(
        _hitSeries(
          tester,
          seriesId: 'power',
          minY: 120,
          maxY: 210,
          point: const ChartDataPoint(x: 1, y: 180),
        ),
        isTrue,
      );

      controller.setSeriesVisible('power', false);
      await tester.pump();
      hostKey.currentState!.reorder();
      await tester.pump();

      final inverseSnapshot = _success(controller.extractDocument());
      expect(controller.hiddenSeriesIds, {'power'});
      expect(controller.visibleAxisIds, ['heart-rate_axis']);
      expect(inverseSnapshot.viewState?.visibleAxisIds, ['heart-rate_axis']);
      expect(
        _hitSeries(
          tester,
          seriesId: 'heart-rate',
          minY: 110,
          maxY: 165,
          point: const ChartDataPoint(x: 2, y: 150),
        ),
        isTrue,
        reason: 'Visibility must remain independent in either direction.',
      );
    },
  );
}

class _ReorderHost extends StatefulWidget {
  const _ReorderHost({super.key, required this.controller});

  final BravenChartController controller;

  @override
  State<_ReorderHost> createState() => _ReorderHostState();
}

class _ReorderHostState extends State<_ReorderHost> {
  bool _reordered = false;

  void reorder() => setState(() => _reordered = !_reordered);

  @override
  Widget build(BuildContext context) {
    final chart = SizedBox(
      key: const ValueKey<String>('chart-tile'),
      width: 640,
      height: 360,
      child: BravenChartPlus(
        bravenChartController: widget.controller,
        normalizationMode: NormalizationMode.perSeries,
        showLegend: false,
        series: [
          LineChartSeries(
            id: 'power',
            name: 'Power',
            color: _powerColor,
            strokeWidth: 6,
            points: const [
              ChartDataPoint(x: 0, y: 120),
              ChartDataPoint(x: 1, y: 180),
              ChartDataPoint(x: 2, y: 140),
              ChartDataPoint(x: 3, y: 210),
            ],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              color: Colors.grey,
              label: 'Power',
              unit: 'W',
            ),
          ),
          LineChartSeries(
            id: 'heart-rate',
            name: 'Heart rate',
            color: const Color(0xFF00AAFF),
            strokeWidth: 6,
            points: const [
              ChartDataPoint(x: 0, y: 110),
              ChartDataPoint(x: 1, y: 125),
              ChartDataPoint(x: 2, y: 150),
              ChartDataPoint(x: 3, y: 165),
            ],
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              color: Colors.grey,
              label: 'Heart rate',
              unit: 'bpm',
            ),
          ),
        ],
      ),
    );
    const spacer = SizedBox(key: ValueKey<String>('neighbor-tile'), height: 20);

    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reordered ? [spacer, chart] : [chart, spacer],
        ),
      ),
    );
  }
}

ChartDocumentSnapshot _success(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) => (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;

bool _hitSeries(
  WidgetTester tester, {
  required String seriesId,
  required double minY,
  required double maxY,
  required ChartDataPoint point,
}) {
  final renderBox = tester.firstRenderObject<ChartRenderBox>(
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
    ),
  );
  final globalTransform = renderBox.transform!;
  final padding = (maxY - minY) * 0.05;
  final seriesTransform = globalTransform.copyWith(
    dataYMin: minY - padding,
    dataYMax: maxY + padding,
  );
  final plotPosition = seriesTransform.dataToPlot(point.x, point.y);
  final hit = renderBox.hitTestElements(renderBox.plotToWidget(plotPosition));
  return hit is SeriesElement && hit.series.id == seriesId;
}
