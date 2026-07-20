import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('automatic axes include asymmetric X and Y error extents', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      annotations: [
        ErrorBarAnnotation(
          seriesId: 'assay',
          values: const [
            ErrorBarDatum(
              pointIndex: 1,
              xNegative: 1,
              xPositive: 4,
              yNegative: 2,
              yPositive: 7,
            ),
          ],
        ),
      ],
    );

    final transform = _renderBox(tester).transform!;
    expect(transform.dataXMax, greaterThan(14));
    expect(transform.dataYMax, greaterThan(17));
  });

  testWidgets('explicit axis bounds remain authoritative over error extents', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      xAxis: const XAxisConfig(min: -2, max: 12),
      yAxis: YAxisConfig(position: YAxisPosition.left, min: -3, max: 13),
      annotations: [
        ErrorBarAnnotation(
          seriesId: 'assay',
          values: const [ErrorBarDatum.symmetric(pointIndex: 1, x: 8, y: 8)],
        ),
      ],
    );

    final transform = _renderBox(tester).transform!;
    expect(transform.dataXMin, -2);
    expect(transform.dataXMax, 12);
    expect(transform.dataYMin, -3);
    expect(transform.dataYMax, 13);
  });
}

Future<void> _pumpChart(
  WidgetTester tester, {
  required List<ChartAnnotation> annotations,
  XAxisConfig? xAxis,
  YAxisConfig? yAxis,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 640,
          height: 360,
          child: BravenChartPlus(
            showLegend: false,
            xAxisConfig: xAxis,
            yAxis: yAxis,
            annotations: annotations,
            series: const [
              ScatterChartSeries(
                id: 'assay',
                points: [
                  ChartDataPoint(x: 0, y: 0),
                  ChartDataPoint(x: 10, y: 10),
                ],
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
