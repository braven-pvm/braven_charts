import 'package:braven_charts/src/layout/chart_layout_kind.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/gauge_chart_config.dart';
import 'package:braven_charts/src/models/gauge_chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GaugeChartSeries', () {
    test('preserves one canonical measurement and explicit domain', () {
      final series = GaugeChartSeries.needle(
        id: 'cpu',
        metric: 'CPU utilization',
        value: 72,
        minimum: 0,
        maximum: 100,
        unit: '%',
        target: const GaugeTarget(value: 70, label: 'SLO'),
        zones: const [
          GaugeZone(from: 0, to: 60, status: 'Healthy', color: Colors.green),
          GaugeZone(from: 60, to: 85, status: 'Elevated', color: Colors.orange),
          GaugeZone(from: 85, to: 100, status: 'Critical', color: Colors.red),
        ],
      );

      expect(series.style, SeriesStyle.gauge);
      expect(series.isXOrdered, isTrue);
      expect(series.points, hasLength(1));
      expect(series.points.single.x, 0);
      expect(series.points.single.y, 72);
      expect(series.points.single.label, 'CPU utilization');
      expect(series.normalizedProgress, 0.72);
      expect(series.activeZone?.status, 'Elevated');
      expect(series.status, 'Elevated');
      expect(series.indicatorStyle, isA<NeedleGaugeStyle>());
    });

    test('uses half-open zones and includes the final domain endpoint', () {
      GaugeChartSeries build(double value) => GaugeChartSeries.solid(
        id: 'temperature',
        metric: 'Temperature',
        value: value,
        minimum: -20,
        maximum: 20,
        zones: const [
          GaugeZone(from: -20, to: 0, status: 'Cold'),
          GaugeZone(from: 0, to: 10, status: 'Nominal'),
          GaugeZone(from: 10, to: 20, status: 'Hot'),
        ],
      );

      expect(build(-20).status, 'Cold');
      expect(build(0).status, 'Nominal');
      expect(build(10).status, 'Hot');
      expect(build(20).status, 'Hot');
      expect(build(0).normalizedProgress, 0.5);
    });

    test('allows zone gaps without inventing a status', () {
      final series = GaugeChartSeries.needle(
        id: 'latency',
        metric: 'Latency',
        value: 75,
        minimum: 0,
        maximum: 100,
        zones: const [
          GaugeZone(from: 0, to: 60, status: 'Healthy'),
          GaugeZone(from: 80, to: 100, status: 'Critical'),
        ],
      );

      expect(series.activeZone, isNull);
      expect(series.status, isNull);
    });

    test(
      'copyWith preserves subtype, revalidates, and clears optional state',
      () {
        final series = GaugeChartSeries.needle(
          id: 'cpu',
          metric: 'CPU',
          value: 72,
          minimum: 0,
          maximum: 100,
          name: 'Compute health',
          color: Colors.blue,
          metadata: const {'source': 'agent'},
          unit: '%',
          target: const GaugeTarget(value: 70),
          thresholds: const [GaugeThreshold(value: 90)],
        );

        final copied = series.copyWith(
          value: 54,
          indicatorStyle: const SolidGaugeStyle(),
          clearName: true,
          clearColor: true,
          clearMetadata: true,
          clearUnit: true,
          clearTarget: true,
          clearThresholds: true,
        );

        expect(copied, isA<GaugeChartSeries>());
        expect(copied.value, 54);
        expect(copied.points.single.y, 54);
        expect(copied.indicatorStyle, isA<SolidGaugeStyle>());
        expect(copied.name, isNull);
        expect(copied.color, isNull);
        expect(copied.metadata, isNull);
        expect(copied.unit, isNull);
        expect(copied.target, isNull);
        expect(copied.thresholds, isEmpty);
      },
    );

    test('owns immutable zone and threshold collections', () {
      final zones = [const GaugeZone(from: 0, to: 100, status: 'Available')];
      final thresholds = [const GaugeThreshold(value: 50)];
      final series = GaugeChartSeries.solid(
        id: 'availability',
        metric: 'Availability',
        value: 99,
        minimum: 0,
        maximum: 100,
        zones: zones,
        thresholds: thresholds,
      );

      zones.clear();
      thresholds.clear();

      expect(series.zones, hasLength(1));
      expect(series.thresholds, hasLength(1));
      expect(() => series.zones.clear(), throwsUnsupportedError);
      expect(() => series.thresholds.clear(), throwsUnsupportedError);
    });

    test('rejects invalid measurement, zones, and references', () {
      GaugeChartSeries build({
        String id = 'cpu',
        String metric = 'CPU',
        double value = 50,
        double minimum = 0,
        double maximum = 100,
        GaugeTarget? target,
        List<GaugeZone> zones = const [],
        List<GaugeThreshold> thresholds = const [],
      }) => GaugeChartSeries.needle(
        id: id,
        metric: metric,
        value: value,
        minimum: minimum,
        maximum: maximum,
        target: target,
        zones: zones,
        thresholds: thresholds,
      );

      expect(() => build(id: ' '), throwsArgumentError);
      expect(() => build(metric: ' '), throwsArgumentError);
      expect(() => build(value: double.nan), throwsArgumentError);
      expect(() => build(value: 101), throwsArgumentError);
      expect(() => build(minimum: 100, maximum: 100), throwsArgumentError);
      expect(
        () => build(target: const GaugeTarget(value: 101)),
        throwsArgumentError,
      );
      expect(
        () => build(
          zones: const [
            GaugeZone(from: 0, to: 60, status: 'Healthy'),
            GaugeZone(from: 50, to: 100, status: 'Critical'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => build(
          zones: const [
            GaugeZone(from: 60, to: 100, status: 'Critical'),
            GaugeZone(from: 0, to: 60, status: 'Healthy'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => build(thresholds: const [GaugeThreshold(value: -1)]),
        throwsArgumentError,
      );
    });

    test('rejects Cartesian mutation and arbitrary point replacement', () {
      final series = GaugeChartSeries.needle(
        id: 'cpu',
        metric: 'CPU',
        value: 50,
        minimum: 0,
        maximum: 100,
      );

      expect(
        () => series.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => series.copyWith(isXOrdered: false), throwsArgumentError);
      expect(() => series.copyWith(yAxisId: 'cartesian'), throwsArgumentError);
      expect(() => series.copyWith(points: const []), throwsArgumentError);
    });
  });

  group('Gauge presentation configuration', () {
    test('validates style and plot configuration', () {
      const needle = NeedleGaugeStyle(
        needleLengthFactor: 0.8,
        needleWidth: 18,
        needleTipWidth: 3,
        pivotBorderColor: Colors.black,
        pivotBorderWidth: 2,
        axisThickness: 14,
      );
      const gradient = GaugeGradientStyle(
        type: GaugeGradientType.radial,
        startColor: Colors.cyan,
        endColor: Colors.blue,
      );
      const solid = SolidGaugeStyle(
        trackOpacity: 0.2,
        cornerRadius: 10,
        gradient: gradient,
      );
      const config = GaugeChartConfig(
        tickCount: 7,
        minorTicksPerInterval: 4,
        scale: GaugeScaleStyle(
          tickWidth: 2,
          tickLength: 14,
          tickPosition: GaugeTickPosition.inside,
          tickGap: 8,
          minorTickWidth: 1.5,
          minorTickLength: 6,
          labelPosition: GaugeScaleLabelPosition.outside,
        ),
        zones: GaugeZoneStyle(
          gap: 3,
          cornerRadius: 2,
          opacity: 0.9,
          borderWidth: 1,
        ),
        references: GaugeReferenceStyle(labelOffset: 12, showLabelPanel: true),
        center: GaugeCenterConfig(
          showTarget: true,
          horizontalOffset: 4,
          verticalOffset: -3,
          lineSpacing: 5,
        ),
      );

      expect(needle.validate, returnsNormally);
      expect(solid.validate, returnsNormally);
      expect(solid.copyWith(opacity: 0.8).gradient, gradient);
      expect(solid.copyWith(clearGradient: true).gradient, isNull);
      expect(config.validate, returnsNormally);
      expect(config.copyWith(showZones: false).showZones, isFalse);
      expect(config.copyWith().scale.tickLength, 14);
      expect(config.minorTicksPerInterval, 4);
      expect(config.scale.tickGap, 8);
      expect(config.zones.gap, 3);
      expect(config.references.showLabelPanel, isTrue);
    });

    test('rejects invalid style and plot values', () {
      expect(
        const NeedleGaugeStyle(needleLengthFactor: 1.1).validate,
        throwsArgumentError,
      );
      expect(
        const NeedleGaugeStyle(axisOpacity: -0.1).validate,
        throwsArgumentError,
      );
      expect(
        const NeedleGaugeStyle(needleWidth: 4, needleTipWidth: 5).validate,
        throwsArgumentError,
      );
      expect(
        const NeedleGaugeStyle(pivotBorderWidth: -1).validate,
        throwsArgumentError,
      );
      expect(
        const SolidGaugeStyle(trackOpacity: 1.1).validate,
        throwsArgumentError,
      );
      expect(
        const SolidGaugeStyle(borderWidth: -1).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeGradientStyle(startLightnessShift: 1.1).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(tickCount: 1).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(minorTicksPerInterval: 21).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(zones: GaugeZoneStyle(gap: -1)).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(
          scale: GaugeScaleStyle(labelOffset: -1),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(
          scale: GaugeScaleStyle(tickGap: -1),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(
          references: GaugeReferenceStyle(panelPadding: -1),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const GaugeChartConfig(
          center: GaugeCenterConfig(lineSpacing: -1),
        ).validate,
        throwsArgumentError,
      );
    });
  });

  group('Gauge composition', () {
    test('resolves exactly one Gauge series to the dedicated layout', () {
      final gauge = GaugeChartSeries.needle(
        id: 'cpu',
        metric: 'CPU',
        value: 50,
        minimum: 0,
        maximum: 100,
      );

      expect(ChartLayoutResolver.resolve([gauge]), ChartLayoutKind.gauge);
      expect(
        () => ChartLayoutResolver.resolve([gauge, gauge.copyWith(id: 'ram')]),
        throwsArgumentError,
      );
      expect(
        () => ChartLayoutResolver.resolve([
          gauge,
          const ChartSeries(id: 'line', points: []),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects a base series carrying the Gauge style hint', () {
      expect(
        () => ChartLayoutResolver.resolve([
          const ChartSeries(id: 'fake', points: [], style: SeriesStyle.gauge),
        ]),
        throwsArgumentError,
      );
    });
  });
}
