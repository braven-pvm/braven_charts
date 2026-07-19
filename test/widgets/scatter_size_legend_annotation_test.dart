import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const encoding = ScatterSizeEncoding(
    minimumRadius: 4,
    maximumRadius: 24,
    minimumValue: 95,
    maximumValue: 600,
    label: 'Active accounts',
  );

  List<ChartSeries> series() => const [
    ScatterChartSeries(
      id: 'enterprise',
      name: 'Enterprise',
      color: Color(0xFF0F9F8F),
      sizeEncoding: encoding,
      points: [ChartDataPoint(x: 4, y: 93, magnitude: 600)],
    ),
    ScatterChartSeries(
      id: 'growth',
      name: 'Growth',
      color: Color(0xFFF97360),
      sizeEncoding: encoding,
      points: [ChartDataPoint(x: 8, y: 75, magnitude: 95)],
    ),
  ];

  testWidgets('bubble scale is a second native legend annotation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 420,
          child: BravenChartPlus(series: series()),
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
      (legend) => legend.annotation.sizeScale == null,
    );
    final quantitative = legends.singleWhere(
      (legend) => legend.annotation.sizeScale != null,
    );
    expect(categorical.annotation.series, hasLength(2));
    expect(quantitative.annotation.series, isEmpty);
    expect(quantitative.annotation.sizeScale?.label, 'Active accounts');
    expect(
      quantitative.annotation.sizeScale?.samples.map((sample) => sample.label),
      ['95', '347.5', '600'],
    );
    expect(categorical.bounds.overlaps(quantitative.bounds), isFalse);
  });

  testWidgets('showLegend controls both native legend annotations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 420,
          child: BravenChartPlus(series: series(), showLegend: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    expect(
      renderBox.debugElements.whereType<LegendAnnotationElement>(),
      isEmpty,
    );
  });
}
