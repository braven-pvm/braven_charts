import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const low = Color(0xFF2563EB);
  const middle = Color(0xFFF8FAFC);
  const high = Color(0xFFDC2626);

  HeatmapChartSeries series(String id, List<HeatmapDataPoint> points) =>
      HeatmapChartSeries(
        id: id,
        points: points,
        colorScale: HeatmapColorScale.sequential(colors: const [low, high]),
      );

  group('HeatmapSharedColorDomain', () {
    test('derives one padded domain and stable provenance across series', () {
      final domain = HeatmapSharedColorDomain.fromSeries([
        series('morning', [
          HeatmapDataPoint(x: 0, y: 0, value: 10),
          HeatmapDataPoint.missing(x: 1, y: 0),
        ]),
        series('evening', [
          HeatmapDataPoint(x: 0, y: 0, value: 20),
          HeatmapDataPoint(x: 1, y: 0, value: 30),
        ]),
      ], paddingFraction: 0.1);

      expect(domain.minimumValue, 8);
      expect(domain.maximumValue, 32);
      expect(domain.span, 24);
      expect(domain.sourceSeriesIds, ['morning', 'evening']);
      expect(() => domain.sourceSeriesIds.add('night'), throwsUnsupportedError);
    });

    test('preserves finite zero and expands a constant domain', () {
      final domain = HeatmapSharedColorDomain.fromSeries([
        series('constant', [
          HeatmapDataPoint(x: 0, y: 0, value: 0),
          HeatmapDataPoint(x: 1, y: 0, value: 0),
        ]),
      ]);

      expect(domain.minimumValue, lessThan(0));
      expect(domain.maximumValue, greaterThan(0));
      expect(domain.span, closeTo(0.000002, 1e-12));
    });

    test('round-trips through JSON', () {
      final domain = HeatmapSharedColorDomain(
        minimumValue: -4,
        maximumValue: 12,
        sourceSeriesIds: const ['alpha', 'beta'],
      );

      expect(HeatmapSharedColorDomain.fromJson(domain.toJson()), domain);
    });

    test('applies one domain while preserving sequential presentation', () {
      final domain = HeatmapSharedColorDomain(
        minimumValue: 0,
        maximumValue: 100,
      );
      final source = HeatmapColorScale.sequential(
        colors: const [low, middle, high],
        reverse: true,
        clamp: false,
        missingColor: const Color(0xFF94A3B8),
        label: 'Load',
        unit: '%',
      );

      final applied = domain.scaleFor(source, showLegend: false);

      expect(applied.minimumValue, 0);
      expect(applied.maximumValue, 100);
      expect(applied.colors, source.colors);
      expect(applied.reverse, isTrue);
      expect(applied.clamp, isFalse);
      expect(applied.missingColor, source.missingColor);
      expect(applied.label, 'Load');
      expect(applied.unit, '%');
      expect(applied.showLegend, isFalse);
    });

    test(
      'applies a valid diverging domain and rejects incompatible scales',
      () {
        final domain = HeatmapSharedColorDomain(
          minimumValue: -10,
          maximumValue: 20,
        );
        final diverging = HeatmapColorScale.diverging(
          lowColor: low,
          midpointColor: middle,
          highColor: high,
          midpoint: 0,
        );

        expect(domain.scaleFor(diverging).midpoint, 0);
        expect(
          () => HeatmapSharedColorDomain(
            minimumValue: 1,
            maximumValue: 20,
          ).scaleFor(diverging),
          throwsArgumentError,
        );
        expect(
          () => domain.scaleFor(
            HeatmapColorScale.threshold(
              thresholds: const [5],
              colors: const [low, high],
            ),
          ),
          throwsUnsupportedError,
        );
      },
    );

    test('rejects invalid derivation and decoded payloads', () {
      expect(
        () => HeatmapSharedColorDomain.fromSeries([
          series('missing', [HeatmapDataPoint.missing(x: 0, y: 0)]),
        ]),
        throwsArgumentError,
      );
      expect(
        () => HeatmapSharedColorDomain.fromSeries([
          series('value', [HeatmapDataPoint(x: 0, y: 0, value: 1)]),
        ], paddingFraction: -0.1),
        throwsArgumentError,
      );
      expect(
        () => HeatmapSharedColorDomain.fromJson({
          'minimumValue': 0,
          'maximumValue': 1,
          'sourceSeriesIds': [7],
        }),
        throwsFormatException,
      );
    });
  });
}
