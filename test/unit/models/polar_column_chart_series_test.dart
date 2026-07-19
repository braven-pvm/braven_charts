import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarColumnChartSeries', () {
    test('fromMap preserves category order, values, colors, and units', () {
      final series = PolarColumnChartSeries.fromMap(
        id: 'requests',
        name: 'Requests',
        values: const {'Search': 42, 'Social': 18.5, 'Partners': 27},
        columnColors: const {'Social': Colors.orange},
        unit: 'tickets',
      );

      expect(series.style, SeriesStyle.polarColumn);
      expect(series.isXOrdered, isTrue);
      expect(series.categories, ['Search', 'Social', 'Partners']);
      expect(series.points.map((point) => point.x), [0, 1, 2]);
      expect(series.points.map((point) => point.y), [42, 18.5, 27]);
      expect(series.points[1].pointStyle?.color, Colors.orange);
      expect(series.unit, 'tickets');
      expect(series.preset, PolarColumnPreset.standard);
    });

    test('rose selects its named preset without changing source values', () {
      final series = PolarColumnChartSeries.rose(
        id: 'rose',
        values: const {'A': 25, 'B': 100},
      );

      expect(series.preset, PolarColumnPreset.rose);
      expect(series.points.map((point) => point.y), [25, 100]);
    });

    test('validates category identity, ordinals, values, and style', () {
      PolarColumnChartSeries build(List<ChartDataPoint> points) =>
          PolarColumnChartSeries(id: 'polar', points: points);

      expect(() => build(const []), throwsArgumentError);
      expect(
        () => build(const [ChartDataPoint(x: 1, y: 1, label: 'A')]),
        throwsArgumentError,
      );
      expect(
        () => build(const [ChartDataPoint(x: 0, y: -1, label: 'A')]),
        throwsArgumentError,
      );
      expect(
        () => build(const [ChartDataPoint(x: 0, y: 1, label: ' ')]),
        throwsArgumentError,
      );
      expect(
        () => build(const [
          ChartDataPoint(x: 0, y: 1, label: 'A'),
          ChartDataPoint(x: 1, y: 2, label: 'A'),
        ]),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnChartSeries.fromMap(
          id: 'polar',
          values: const {'A': 1},
          polarStyle: const PolarColumnStyle(opacity: 1.1),
        ),
        throwsArgumentError,
      );
    });

    test('copyWith preserves the polar contract', () {
      final original = PolarColumnChartSeries.rose(
        id: 'polar',
        values: const {'A': 1, 'B': 2},
      );
      final copy = original.copyWith(name: 'Rose', unit: 'requests');

      expect(copy.name, 'Rose');
      expect(copy.unit, 'requests');
      expect(copy.preset, PolarColumnPreset.rose);
      expect(copy.categories, original.categories);
      expect(
        () => original.copyWith(style: SeriesStyle.bar),
        throwsArgumentError,
      );
      expect(() => original.copyWith(isXOrdered: false), throwsArgumentError);
      expect(
        () => original.copyWith(yAxisId: 'cartesian'),
        throwsArgumentError,
      );
    });
  });

  group('PolarChartConfig', () {
    test('accepts a partial counter-clockwise pane and explicit domain', () {
      const config = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: 180,
          sweepAngleDegrees: 240,
          clockwise: false,
          innerRadiusFactor: 0.2,
          outerRadiusFactor: 0.9,
        ),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.2,
          outerPadding: 0.1,
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: 10,
          maximum: 100,
          scaleMode: PolarRadialScaleMode.areaCorrect,
          tickCount: 6,
        ),
      );

      expect(config.validate, returnsNormally);
    });

    test('rejects invalid pane, padding, domain, and tick counts', () {
      expect(
        const PolarChartConfig(
          pane: PolarPaneConfig(sweepAngleDegrees: 0),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const PolarChartConfig(
          pane: PolarPaneConfig(innerRadiusFactor: 0.8, outerRadiusFactor: 0.8),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const PolarChartConfig(
          angularAxis: PolarCategoryAxisConfig(innerPadding: 1),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const PolarChartConfig(
          radialAxis: PolarNumericAxisConfig(minimum: 10, maximum: 5),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const PolarChartConfig(
          radialAxis: PolarNumericAxisConfig(tickCount: 1),
        ).validate,
        throwsArgumentError,
      );
    });
  });
}
