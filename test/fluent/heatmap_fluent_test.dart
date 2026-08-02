import 'package:braven_charts/braven_charts_fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Heatmap fluent modifiers preserve typed cell and scale contracts', () {
    final scale = HeatmapColorScale.sequential(
      colors: const [Colors.blue, Colors.yellow, Colors.red],
      label: 'Temperature',
      unit: '°C',
    );
    final original = HeatmapChartSeries(
      id: 'temperature',
      points: [HeatmapDataPoint(x: 0, y: 0, value: 18)],
      colorScale: scale,
    );

    final updated = original
        .withName('Hourly temperature')
        .withCellWidth(0.9)
        .withCellHeight(0.8)
        .withGapFraction(0.1)
        .withBorderColor(Colors.black12)
        .withBorderWidth(1)
        .withCornerRadius(4)
        .withShowCellLabels(true)
        .withCellLabelColor(Colors.black)
        .withCellLabelFontSize(12);

    expect(updated, isA<HeatmapChartSeries>());
    expect(updated.id, 'temperature');
    expect(updated.cells, hasLength(1));
    expect(updated.colorScale, same(scale));
    expect(updated.name, 'Hourly temperature');
    expect(updated.cellWidth, 0.9);
    expect(updated.cellHeight, 0.8);
    expect(updated.gapFraction, 0.1);
    expect(updated.borderColor, Colors.black12);
    expect(updated.borderWidth, 1);
    expect(updated.cornerRadius, 4);
    expect(updated.showCellLabels, isTrue);
    expect(updated.cellLabelColor, Colors.black);
    expect(updated.cellLabelFontSize, 12);
  });

  test('Heatmap cell fluent modifiers retain explicit missing semantics', () {
    final populated = HeatmapDataPoint(
      x: 1,
      y: 2,
      value: 3,
      pointKey: 'cell',
      label: 'Original',
    );
    final updated = populated
        .withX(4)
        .withY(5)
        .withValue(6)
        .withLabel('Updated');

    expect(updated, isA<HeatmapDataPoint>());
    expect(updated.x, 4);
    expect(updated.y, 5);
    expect(updated.value, 6);
    expect(updated.pointKey, 'cell');
    expect(updated.label, 'Updated');
    expect(updated.isMissing, isFalse);

    final restored = HeatmapDataPoint.missing(
      x: 4,
      y: 5,
      pointKey: 'cell',
    ).withValue(7);
    expect(restored.value, 7);
    expect(restored.isMissing, isFalse);
  });

  test('Heatmap fluent modifiers keep runtime validation boundaries', () {
    final cell = HeatmapDataPoint(x: 1, y: 2, value: 3);
    final series = HeatmapChartSeries(
      id: 'heatmap',
      points: [cell],
      colorScale: HeatmapColorScale.sequential(
        colors: const [Colors.blue, Colors.red],
      ),
    );

    expect(() => cell.withValue(double.nan), throwsArgumentError);
    expect(() => cell.withPointKey(''), throwsArgumentError);
    expect(() => series.withGapFraction(1), throwsArgumentError);
    expect(() => series.withCellWidth(0), throwsArgumentError);
  });
}
