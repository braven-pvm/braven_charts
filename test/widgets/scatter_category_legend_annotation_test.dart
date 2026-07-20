import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('categorical encoding uses a native legend annotation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 860,
          height: 480,
          child: BravenChartPlus(
            series: [
              ScatterChartSeries(
                id: 'vehicles',
                name: 'Models',
                points: [
                  ChartDataPoint(x: 1, y: 2, categoryValue: 'electric'),
                  ChartDataPoint(x: 2, y: 3, categoryValue: 'hybrid'),
                ],
                categoryEncoding: ScatterCategoryEncoding(
                  label: 'Powertrain',
                  categories: [
                    ScatterCategoryStyle(
                      key: 'electric',
                      label: 'Electric',
                      color: Color(0xFF2563EB),
                      shape: SeriesMarkerShape.circle,
                    ),
                    ScatterCategoryStyle(
                      key: 'hybrid',
                      label: 'Hybrid',
                      color: Color(0xFF16A34A),
                      shape: SeriesMarkerShape.diamond,
                    ),
                    ScatterCategoryStyle(
                      key: 'unused',
                      color: Color(0xFF999999),
                    ),
                  ],
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
    final categoryLegend = legends.singleWhere(
      (legend) => legend.annotation.categoryScale != null,
    );

    expect(legends, hasLength(2));
    expect(categoryLegend.annotation.categoryScale?.label, 'Powertrain');
    expect(
      categoryLegend.annotation.categoryScale?.items.map((item) => item.label),
      ['Electric', 'Hybrid'],
    );
    expect(tester.takeException(), isNull);
  });
}
