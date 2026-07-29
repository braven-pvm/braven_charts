import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapColorScale scale() =>
      HeatmapColorScale.sequential(colors: const [Colors.white, Colors.blue]);

  test('retains a typed immutable cell view and resolves its domain', () {
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [
        HeatmapDataPoint(x: 0, y: 0, value: -2),
        HeatmapDataPoint(x: 1, y: 0, value: 8),
        HeatmapDataPoint.missing(x: 2, y: 0),
      ],
    );

    expect(series.style, SeriesStyle.heatmap);
    expect(series.cells, hasLength(3));
    expect(series.measuredValues, [-2, 8]);
    expect(series.resolvedMinimumValue, -2);
    expect(series.resolvedMaximumValue, 8);
    expect(
      () => series.cells.add(HeatmapDataPoint(x: 3, y: 0, value: 4)),
      throwsUnsupportedError,
    );
  });

  test('rejects duplicate coordinate identity', () {
    expect(
      () => HeatmapChartSeries(
        id: 'matrix',
        colorScale: scale(),
        points: [
          HeatmapDataPoint(x: 0, y: 0, value: 1),
          HeatmapDataPoint(x: 0, y: 0, value: 2),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('allows duplicate coordinates when stable keys differ', () {
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [
        HeatmapDataPoint(x: 0, y: 0, value: 1, pointKey: 'first'),
        HeatmapDataPoint(x: 0, y: 0, value: 2, pointKey: 'second'),
      ],
    );

    expect(series.cells, hasLength(2));
  });

  test('validates cell geometry and presentation values', () {
    HeatmapChartSeries create({
      double cellWidth = 1,
      double cellHeight = 1,
      double gapFraction = 0,
      double borderWidth = 0,
      double cornerRadius = 0,
      double cellLabelFontSize = 11,
    }) => HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      gapFraction: gapFraction,
      borderWidth: borderWidth,
      cornerRadius: cornerRadius,
      cellLabelFontSize: cellLabelFontSize,
    );

    expect(() => create(cellWidth: 0), throwsArgumentError);
    expect(() => create(cellHeight: double.nan), throwsArgumentError);
    expect(() => create(gapFraction: 1), throwsArgumentError);
    expect(() => create(borderWidth: -1), throwsArgumentError);
    expect(() => create(cornerRadius: -1), throwsArgumentError);
    expect(() => create(cellLabelFontSize: 0), throwsArgumentError);
  });

  test('validates and copies Heatmap motion settings', () {
    const animation = HeatmapAnimationStyle(
      entranceMode: HeatmapEntranceMode.scale,
      entranceOrder: HeatmapEntranceOrder.radial,
      entranceScale: 0.7,
      staggerFraction: 0.8,
      animateDataUpdates: false,
      entranceTiming: PathAnimationTiming(
        delay: Duration(milliseconds: 20),
        duration: Duration(milliseconds: 480),
      ),
    );
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
      animation: animation,
    );

    expect(series.animation, animation);
    expect(
      series.copyWith(
        animation: animation.copyWith(
          entranceOrder: HeatmapEntranceOrder.column,
        ),
      ),
      isNot(series),
    );
    expect(
      () => HeatmapChartSeries(
        id: 'invalid-scale',
        colorScale: scale(),
        points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
        animation: const HeatmapAnimationStyle(entranceScale: 1.1),
      ),
      throwsArgumentError,
    );
    expect(
      () => HeatmapChartSeries(
        id: 'invalid-stagger',
        colorScale: scale(),
        points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
        animation: const HeatmapAnimationStyle(staggerFraction: 1),
      ),
      throwsArgumentError,
    );
  });

  test('copyWith keeps the concrete family invariant', () {
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
    );

    expect(series.copyWith(showCellLabels: true).showCellLabels, isTrue);
    final hiddenPresentation = series.copyWith(
      showInLegend: false,
      showTrackingAxisLabel: false,
    );
    expect(hiddenPresentation.showInLegend, isFalse);
    expect(hiddenPresentation.showTrackingAxisLabel, isFalse);
    expect(
      () => series.copyWith(style: SeriesStyle.scatter),
      throwsArgumentError,
    );
    expect(
      () => series.copyWith(points: const [ChartDataPoint(x: 0, y: 0)]),
      throwsArgumentError,
    );
  });

  test('presentation changes participate in series equality', () {
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
    );

    expect(series.copyWith(), series);
    expect(series.copyWith().hashCode, series.hashCode);
    expect(
      series.copyWith(
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.black, Colors.orange],
        ),
      ),
      isNot(series),
    );
    expect(series.copyWith(cellWidth: 2), isNot(series));
    expect(series.copyWith(cellHeight: 2), isNot(series));
    expect(series.copyWith(gapFraction: 0.2), isNot(series));
    expect(series.copyWith(borderColor: Colors.red), isNot(series));
    expect(series.copyWith(borderWidth: 2), isNot(series));
    expect(series.copyWith(cornerRadius: 6), isNot(series));
    expect(series.copyWith(showCellLabels: true), isNot(series));
    expect(series.copyWith(cellLabelColor: Colors.green), isNot(series));
    expect(series.copyWith(cellLabelFontSize: 14), isNot(series));
    expect(
      series.copyWith(
        animation: const HeatmapAnimationStyle(
          entranceOrder: HeatmapEntranceOrder.column,
        ),
      ),
      isNot(series),
    );
  });

  test('validates integer coordinates inside categorical domains', () {
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [
        HeatmapDataPoint(x: 0, y: 0, value: 1),
        HeatmapDataPoint(x: 1, y: 1, value: 2),
      ],
    );

    expect(
      () => series.validateCategoryCoordinates(
        xAxis: const CategoryAxisConfig(categories: ['A', 'B']),
        yAxis: const CategoryAxisConfig(categories: ['North', 'South']),
      ),
      returnsNormally,
    );
  });

  test('rejects fractional and out-of-domain category coordinates', () {
    final fractional = HeatmapChartSeries(
      id: 'fractional',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0.5, y: 0, value: 1)],
    );
    final outside = HeatmapChartSeries(
      id: 'outside',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 2, value: 1)],
    );

    expect(
      () => fractional.validateCategoryCoordinates(
        xAxis: const CategoryAxisConfig(categories: ['A', 'B']),
      ),
      throwsArgumentError,
    );
    expect(
      () => outside.validateCategoryCoordinates(
        yAxis: const CategoryAxisConfig(categories: ['North', 'South']),
      ),
      throwsArgumentError,
    );
  });
}
