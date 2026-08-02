import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HeatmapColorScale scale() =>
      HeatmapColorScale.sequential(colors: const [Colors.white, Colors.blue]);

  test('validates and retains explicit Cartesian cell bounds', () {
    final bounds = HeatmapCellBounds(
      xMinimum: 1,
      xMaximum: 4,
      yMinimum: 10,
      yMaximum: 14,
    );
    final point = HeatmapDataPoint(x: 2, y: 12, value: 7, bounds: bounds);
    final missing = HeatmapDataPoint.missing(x: 3, y: 11, bounds: bounds);

    expect(point.bounds, bounds);
    expect(point.isValid, isTrue);
    expect(missing.bounds, bounds);
    expect(point.copyWith(value: 8).bounds, bounds);
    expect(point.copyWith(clearBounds: true).bounds, isNull);
    expect(point, point.copyWith());
  });

  test('rejects invalid or non-containing explicit cell bounds', () {
    expect(
      () =>
          HeatmapCellBounds(xMinimum: 2, xMaximum: 2, yMinimum: 0, yMaximum: 1),
      throwsArgumentError,
    );
    expect(
      () => HeatmapCellBounds(
        xMinimum: double.nan,
        xMaximum: 2,
        yMinimum: 0,
        yMaximum: 1,
      ),
      throwsArgumentError,
    );
    final bounds = HeatmapCellBounds(
      xMinimum: 0,
      xMaximum: 1,
      yMinimum: 0,
      yMaximum: 1,
    );
    expect(
      () => HeatmapDataPoint(x: 2, y: 0.5, value: 1, bounds: bounds),
      throwsArgumentError,
    );
    expect(
      () => HeatmapDataPoint.missing(x: 0.5, y: 2, bounds: bounds),
      throwsArgumentError,
    );
  });

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

  test('empty-value presentation stays distinct from missing cells', () {
    const emptyStyle = HeatmapEmptyValueStyle(
      fillColor: Color(0xFFE5E7EB),
      borderColor: Color(0xFFD1D5DB),
      borderWidth: 1,
      showLabel: true,
      legendLabel: 'No contributions',
    );
    final zero = HeatmapDataPoint(x: 0, y: 0, value: 0);
    final missing = HeatmapDataPoint.missing(x: 1, y: 0);
    final series = HeatmapChartSeries(
      id: 'contributions',
      colorScale: scale(),
      points: [zero, missing, HeatmapDataPoint(x: 2, y: 0, value: 3)],
      emptyValueStyle: emptyStyle,
    );

    expect(series.emptyValueStyle, emptyStyle);
    expect(emptyStyle.matches(zero), isTrue);
    expect(emptyStyle.matches(missing), isFalse);
    expect(emptyStyle.matches(series.cells.last), isFalse);
    expect(series.measuredValues, [0, 3]);
    expect(series.copyWith(clearEmptyValueStyle: true).emptyValueStyle, isNull);
  });

  test('validates empty-value presentation', () {
    HeatmapChartSeries create(HeatmapEmptyValueStyle style) =>
        HeatmapChartSeries(
          id: 'matrix',
          colorScale: scale(),
          points: [HeatmapDataPoint(x: 0, y: 0, value: 0)],
          emptyValueStyle: style,
        );

    expect(
      () => create(const HeatmapEmptyValueStyle(value: double.nan)),
      throwsArgumentError,
    );
    expect(
      () => create(const HeatmapEmptyValueStyle(borderWidth: -1)),
      throwsArgumentError,
    );
    expect(
      () => create(const HeatmapEmptyValueStyle(legendLabel: '  ')),
      throwsArgumentError,
    );
  });

  test('value filter is inclusive and preserves missing cells', () {
    const filter = HeatmapValueFilter(
      minimumValue: 2,
      maximumValue: 4,
      mode: HeatmapValueFilterMode.hide,
    );

    expect(filter.includes(HeatmapDataPoint(x: 0, y: 0, value: 2)), isTrue);
    expect(filter.includes(HeatmapDataPoint(x: 1, y: 0, value: 4)), isTrue);
    expect(filter.includes(HeatmapDataPoint(x: 2, y: 0, value: 1)), isFalse);
    expect(filter.includes(HeatmapDataPoint.missing(x: 3, y: 0)), isTrue);
  });

  test('validates and copies value-filter presentation', () {
    const filter = HeatmapValueFilter(
      minimumValue: 2,
      maximumValue: 4,
      excludedOpacity: 0.2,
    );
    final series = HeatmapChartSeries(
      id: 'matrix',
      colorScale: scale(),
      points: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
      valueFilter: filter,
    );

    expect(series.valueFilter, filter);
    expect(
      series.copyWith(
        valueFilter: filter.copyWith(mode: HeatmapValueFilterMode.hide),
      ),
      isNot(series),
    );
    expect(series.copyWith(clearValueFilter: true).valueFilter, isNull);
    expect(
      () => HeatmapValueFilter(
        minimumValue: double.nan,
        maximumValue: 4,
      ).validate(),
      throwsArgumentError,
    );
    expect(
      () => HeatmapValueFilter(minimumValue: 5, maximumValue: 4).validate(),
      throwsArgumentError,
    );
    expect(
      () => HeatmapValueFilter(
        minimumValue: 2,
        maximumValue: 4,
        excludedOpacity: 1.1,
      ).validate(),
      throwsArgumentError,
    );
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
        emptyValueStyle: const HeatmapEmptyValueStyle(
          legendLabel: 'No activity',
        ),
      ),
      isNot(series),
    );
    expect(
      series.copyWith(
        valueFilter: const HeatmapValueFilter(minimumValue: 0, maximumValue: 1),
      ),
      isNot(series),
    );
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
