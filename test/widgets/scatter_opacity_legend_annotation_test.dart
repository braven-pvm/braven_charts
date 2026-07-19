import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opacity encoding uses a native independent legend annotation', (
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
                id: 'confidence',
                name: 'Forecasts',
                color: Color(0xFF2563EB),
                points: [
                  ChartDataPoint(x: 1, y: 2, opacityValue: 40),
                  ChartDataPoint(x: 2, y: 3, opacityValue: 100),
                ],
                opacityEncoding: ScatterOpacityEncoding(
                  minimumOpacity: 0.15,
                  maximumOpacity: 0.95,
                  label: 'Confidence',
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
      (legend) => legend.annotation.opacityScale == null,
    );
    final quantitative = legends.singleWhere(
      (legend) => legend.annotation.opacityScale != null,
    );
    final scale = quantitative.annotation.opacityScale!;
    expect(scale.label, 'Confidence');
    expect(scale.minimumOpacity, 0.15);
    expect(scale.maximumOpacity, 0.95);
    expect(scale.minimumLabel, '40 %');
    expect(scale.midpointLabel, '70 %');
    expect(scale.maximumLabel, '100 %');
    expect(categorical.bounds.overlaps(quantitative.bounds), isFalse);
    expect(tester.takeException(), isNull);
  });
}
