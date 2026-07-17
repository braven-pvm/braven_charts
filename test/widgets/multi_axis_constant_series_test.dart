import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'one-point per-series normalized chart paints without exception',
    (tester) async {
      await _pumpConstantChart(
        tester,
        points: const [ChartDataPoint(x: 0, y: 180)],
      );

      expect(tester.takeException(), isNull);
      expect(_renderBox(tester).transform, isNotNull);
    },
  );

  for (final testCase in <({String name, double value})>[
    (name: 'positive', value: 180),
    (name: 'zero', value: 0),
    (name: 'negative', value: -40),
  ]) {
    testWidgets(
      'constant ${testCase.name} series paints and remains hit-testable',
      (tester) async {
        await _pumpConstantChart(
          tester,
          points: [
            ChartDataPoint(x: 0, y: testCase.value),
            ChartDataPoint(x: 1, y: testCase.value),
            ChartDataPoint(x: 2, y: testCase.value),
          ],
        );

        expect(tester.takeException(), isNull);

        final renderBox = _renderBox(tester);
        final transform = renderBox.transform!;
        final plotPosition = Offset(
          transform.dataToPlot(1, transform.dataYMin).dx,
          transform.plotHeight / 2,
        );
        final hit = renderBox.hitTestElements(
          renderBox.plotToWidget(plotPosition),
        );

        expect(hit, isA<SeriesElement>());
        expect((hit! as SeriesElement).series.id, 'constant');
      },
    );
  }
}

Future<void> _pumpConstantChart(
  WidgetTester tester, {
  required List<ChartDataPoint> points,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 640,
          height: 360,
          child: BravenChartPlus(
            normalizationMode: NormalizationMode.perSeries,
            showLegend: false,
            series: [
              LineChartSeries(
                id: 'constant',
                name: 'Constant',
                color: Colors.orange,
                strokeWidth: 6,
                showDataPointMarkers: true,
                points: points,
                yAxisConfig: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ChartRenderBox _renderBox(WidgetTester tester) =>
    tester.firstRenderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
