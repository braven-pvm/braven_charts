import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('continuous color scale uses a native legend annotation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 760,
          height: 460,
          child: BravenChartPlus(
            series: [
              ScatterChartSeries(
                id: 'readiness',
                name: 'Athletes',
                points: [
                  ChartDataPoint(x: 1, y: 2, colorValue: 40),
                  ChartDataPoint(x: 2, y: 3, colorValue: 100),
                ],
                colorEncoding: ScatterColorEncoding(
                  colors: [
                    Color(0xFFDC2626),
                    Color(0xFFF59E0B),
                    Color(0xFF16A34A),
                  ],
                  label: 'Readiness',
                  unit: '%',
                ),
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
    final legends = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .toList();

    expect(legends, hasLength(2));
    final categorical = legends.singleWhere(
      (legend) => legend.annotation.colorScale == null,
    );
    final quantitative = legends.singleWhere(
      (legend) => legend.annotation.colorScale != null,
    );
    expect(quantitative.annotation.colorScale?.label, 'Readiness');
    expect(quantitative.annotation.colorScale?.minimumLabel, '40 %');
    expect(quantitative.annotation.colorScale?.midpointLabel, '70 %');
    expect(quantitative.annotation.colorScale?.maximumLabel, '100 %');
    expect(categorical.bounds.overlaps(quantitative.bounds), isFalse);
  });

  testWidgets('piecewise color scale uses a segmented native legend', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 900,
          height: 520,
          child: BravenChartPlus(
            series: [
              ScatterChartSeries(
                id: 'risk',
                name: 'Assets',
                points: [
                  ChartDataPoint(x: 1, y: 2, colorValue: 20),
                  ChartDataPoint(x: 2, y: 3, colorValue: 85),
                ],
                colorEncoding: ScatterColorEncoding(
                  colors: [
                    Color(0xFF16A34A),
                    Color(0xFFFACC15),
                    Color(0xFFF97316),
                    Color(0xFFDC2626),
                  ],
                  scaleType: ScatterColorScaleType.piecewise,
                  thresholds: [35, 60, 80],
                  bandLabels: ['Normal', 'Monitor', 'Warning', 'Critical'],
                  label: 'Risk score',
                ),
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
    final quantitative = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .singleWhere((legend) => legend.annotation.colorScale != null);

    expect(
      quantitative.annotation.colorScale?.type,
      LegendColorScaleType.piecewise,
    );
    expect(quantitative.annotation.colorScale?.segmentLabels, const [
      'Normal',
      'Monitor',
      'Warning',
      'Critical',
    ]);
    expect(tester.takeException(), isNull);
  });
}
