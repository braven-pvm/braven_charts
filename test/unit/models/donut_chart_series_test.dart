import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DonutChartSeries', () {
    test(
      'fromMap preserves stable categories and first-class Donut identity',
      () {
        final series = DonutChartSeries.fromMap(
          id: 'registrations',
          unit: 'vehicles',
          values: const {'EV': 24, 'Hybrid': 13, 'Diesel': 37, 'Petrol': 26},
          sliceColors: const {'EV': Color(0xFF2196F3)},
          donutStyle: const DonutChartStyle(
            innerRadiusFactor: 0.62,
            sweepAngleDegrees: 270,
          ),
          selectionStyle: const RadialSelectionStyle(
            effect: RadialSelectionEffect.lift,
            liftScale: 1.12,
            liftOffset: 8,
            backdropBlur: 1.5,
          ),
          centerContent: const DonutCenterContent(
            label: 'Total',
            valueMode: DonutCenterValueMode.selectedOrTotal,
          ),
        );

        expect(series, isA<RadialCategorySeries>());
        expect(series.style, SeriesStyle.donut);
        expect(series.points.map((point) => point.label), [
          'EV',
          'Hybrid',
          'Diesel',
          'Petrol',
        ]);
        expect(series.points.map((point) => point.x), [0, 1, 2, 3]);
        expect(series.points.first.pointStyle?.color, const Color(0xFF2196F3));
        expect(series.total, 100);
        expect(series.innerRadiusFactor, 0.62);
        expect(series.sweepAngleDegrees, 270);
        expect(series.selectionStyle.effect, RadialSelectionEffect.lift);
        expect(series.selectionStyle.liftScale, 1.12);
        expect(series.unit, 'vehicles');
        expect(series.centerContent.label, 'Total');
        expect(
          series.centerContent.valueMode,
          DonutCenterValueMode.selectedOrTotal,
        );
      },
    );

    test('supports variable outer radii through the shared radial config', () {
      final series = DonutChartSeries.fromMap(
        id: 'countries',
        values: const {'Germany': 233, 'Spain': 96, 'France': 119},
        radiusValues: const {
          'Germany': 357022,
          'Spain': 505990,
          'France': 551695,
        },
        sliceRadiusConfig: const RadialSliceRadiusConfig(
          minimumFactor: 0.4,
          label: 'Total area',
          unit: 'km²',
        ),
      );

      expect(series.hasVariableSliceRadius, isTrue);
      expect(series.points.map((point) => point.pointStyle?.size), [
        357022,
        505990,
        551695,
      ]);
      expect(series.sliceRadiusConfig?.label, 'Total area');
    });

    for (final innerRadius in <double>[0, 1, -0.1, double.nan]) {
      test('rejects invalid inner radius $innerRadius', () {
        expect(
          () => DonutChartSeries.fromMap(
            id: 'invalid-inner',
            values: const {'A': 1},
            donutStyle: DonutChartStyle(innerRadiusFactor: innerRadius),
          ),
          throwsArgumentError,
        );
      });
    }

    for (final sweep in <double>[0, -1, 361, double.infinity]) {
      test('rejects invalid sweep $sweep', () {
        expect(
          () => DonutChartSeries.fromMap(
            id: 'invalid-sweep',
            values: const {'A': 1},
            donutStyle: DonutChartStyle(sweepAngleDegrees: sweep),
          ),
          throwsArgumentError,
        );
      });
    }

    test('variable Donut radii cannot collapse into the shared hole', () {
      expect(
        () => DonutChartSeries.fromMap(
          id: 'collapsed-radius',
          values: const {'A': 1, 'B': 2},
          radiusValues: const {'A': 1, 'B': 2},
          sliceRadiusConfig: const RadialSliceRadiusConfig(minimumFactor: 0),
        ),
        throwsArgumentError,
      );
    });

    test('copyWith preserves type and validates fixed radial invariants', () {
      final source = DonutChartSeries.fromMap(
        id: 'source',
        values: const {'A': 1, 'B': 2},
      );
      final copied = source.copyWith(
        id: 'copy',
        donutStyle: source.donutStyle.copyWith(
          innerRadiusFactor: 0.7,
          sweepAngleDegrees: 180,
        ),
        centerContent: const DonutCenterContent(
          valueMode: DonutCenterValueMode.custom,
          customValue: 'Ready',
        ),
        selectionStyle: const RadialSelectionStyle(
          effect: RadialSelectionEffect.lift,
        ),
      );

      expect(copied, isA<DonutChartSeries>());
      expect(copied.id, 'copy');
      expect(copied.innerRadiusFactor, 0.7);
      expect(copied.sweepAngleDegrees, 180);
      expect(copied.centerContent.customValue, 'Ready');
      expect(copied.selectionStyle.effect, RadialSelectionEffect.lift);
      expect(
        () => source.copyWith(style: SeriesStyle.pie),
        throwsArgumentError,
      );
      expect(() => source.copyWith(isXOrdered: false), throwsArgumentError);
    });

    test('validates shared radial selection bounds', () {
      expect(
        () => DonutChartSeries.fromMap(
          id: 'invalid-selection-scale',
          values: const {'A': 1},
          selectionStyle: const RadialSelectionStyle(liftScale: 1.51),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'invalid-selection-offset',
          values: const {'A': 1},
          selectionStyle: const RadialSelectionStyle(liftOffset: 40.1),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'invalid-selection-blur',
          values: const {'A': 1},
          selectionStyle: const RadialSelectionStyle(backdropBlur: 20.1),
        ),
        throwsArgumentError,
      );
    });

    test('validates portable center labels and custom values', () {
      expect(
        () => DonutChartSeries.fromMap(
          id: 'blank-label',
          values: const {'A': 1},
          centerContent: const DonutCenterContent(label: '   '),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'missing-custom',
          values: const {'A': 1},
          centerContent: const DonutCenterContent(
            valueMode: DonutCenterValueMode.custom,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        DonutChartSeries.fromMap(
          id: 'hidden-default',
          values: const {'A': 1},
        ).centerContent,
        DonutCenterContent.hidden,
      );
    });

    test('BravenChartPlus map and JSON factories create Donut series', () {
      final fromMap = BravenChartPlus.fromMap(
        chartType: ChartType.donut,
        seriesId: 'map-donut',
        data: const {'North': 3, 'South': 2},
      );
      final fromJson = BravenChartPlus.fromJson(
        chartType: ChartType.donut,
        seriesId: 'json-donut',
        json: '[{"x":0,"y":4,"label":"A"}]',
      );

      expect(fromMap.series.single, isA<DonutChartSeries>());
      expect(fromJson.series.single, isA<DonutChartSeries>());
      expect(
        () => BravenChartPlus.fromValues(
          chartType: ChartType.donut,
          seriesId: 'invalid',
          yValues: const [1, 2],
        ),
        throwsArgumentError,
      );
    });
  });
}
