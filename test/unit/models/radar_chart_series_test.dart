import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarChartSeries', () {
    test(
      'fromMap preserves authored categories without closure duplication',
      () {
        final series = RadarChartSeries.fromMap(
          id: 'budget',
          name: 'Allocated budget',
          values: const {'Sales': 43, 'Marketing': 19, 'Development': 60},
          unit: 'USD',
        );

        expect(series.style, SeriesStyle.radar);
        expect(series.isXOrdered, isTrue);
        expect(series.categories, ['Sales', 'Marketing', 'Development']);
        expect(series.points.map((point) => point.x), [0, 1, 2]);
        expect(series.points.map((point) => point.y), [43, 19, 60]);
        expect(series.points, hasLength(3));
        expect(series.unit, 'USD');
      },
    );

    test('rejects incomplete and ambiguous V1 profiles', () {
      expect(
        () => RadarChartSeries.fromMap(
          id: 'short',
          values: const {'A': 1, 'B': 2},
        ),
        throwsArgumentError,
      );
      expect(
        () => RadarChartSeries(
          id: 'negative',
          points: const [
            ChartDataPoint(x: 0, y: 1, label: 'A'),
            ChartDataPoint(x: 1, y: -1, label: 'B'),
            ChartDataPoint(x: 2, y: 2, label: 'C'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => RadarChartSeries(
          id: 'duplicate',
          points: const [
            ChartDataPoint(x: 0, y: 1, label: 'A'),
            ChartDataPoint(x: 1, y: 2, label: 'A'),
            ChartDataPoint(x: 2, y: 3, label: 'C'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => RadarChartSeries(
          id: 'ordinal',
          points: const [
            ChartDataPoint(x: 0, y: 1, label: 'A'),
            ChartDataPoint(x: 3, y: 2, label: 'B'),
            ChartDataPoint(x: 2, y: 3, label: 'C'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('copyWith preserves fixed family and ordered profile contract', () {
      final series = RadarChartSeries.fromMap(
        id: 'profile',
        values: const {'A': 1, 'B': 2, 'C': 3},
      );

      expect(series.copyWith(name: 'Profile').name, 'Profile');
      expect(
        () => series.copyWith(style: SeriesStyle.line),
        throwsArgumentError,
      );
      expect(() => series.copyWith(isXOrdered: false), throwsArgumentError);
    });
  });

  group('RadarChartConfig', () {
    test('accepts a full-circle zero-centre linear Radar pane', () {
      const config = RadarChartConfig();
      expect(config.validate, returnsNormally);
      expect(config.radialAxis.gridShape, RadarGridShape.polygon);
    });

    test('rejects partial sweeps, holes, negative domains, and bad styles', () {
      expect(
        const RadarChartConfig(
          pane: PolarPaneConfig(sweepAngleDegrees: 270),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const RadarChartConfig(
          pane: PolarPaneConfig(innerRadiusFactor: 0.2),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const RadarChartConfig(
          radialAxis: RadarNumericAxisConfig(minimum: -1),
        ).validate,
        throwsArgumentError,
      );
      expect(
        const RadarSeriesStyle(fillOpacity: 1.1).validate,
        throwsArgumentError,
      );
      expect(
        const RadarGradientStyle(startLightnessShift: 1.1).validate,
        throwsArgumentError,
      );
      expect(
        const RadarShadowStyle(blurRadius: -1).validate,
        throwsArgumentError,
      );
      expect(
        const RadarWebStyle(ringDashPattern: <double>[4]).validate,
        throwsArgumentError,
      );
    });

    test('preserves independent profile and web appearance overrides', () {
      const style = RadarSeriesStyle(
        gradient: RadarGradientStyle(
          type: RadarGradientType.linear,
          angleDegrees: 35,
        ),
        shadow: RadarShadowStyle(
          blurRadius: 8,
          spreadRadius: 2,
          offset: Offset(2, 3),
        ),
        markerShape: SeriesMarkerShape.diamond,
        markerRadius: 5,
        markerFillColor: Color(0xFF38BDF8),
        markerBorderColor: Color(0xFF0F172A),
        markerBorderWidth: 1.5,
        showDataLabels: true,
        maximumVisibleDataLabels: 8,
        dataLabelOffset: 12,
        dataLabelStyle: PolarLabelStyle(
          color: Color(0xFF1E293B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
      const config = RadarChartConfig(
        webStyle: RadarWebStyle(
          ringColor: Color(0xFF334155),
          ringWidth: 1.5,
          ringDashPattern: <double>[5, 3],
          spokeColor: Color(0xFF64748B),
          spokeWidth: 0.75,
          spokeDashPattern: <double>[],
          boundaryColor: Color(0xFF0F172A),
          boundaryWidth: 2,
          boundaryDashPattern: <double>[8, 2],
        ),
      );

      expect(style.validate, returnsNormally);
      expect(config.validate, returnsNormally);
      expect(style.copyWith(), style);
      expect(config.copyWith(), config);
    });

    test('rejects invalid marker and direct-value presentation', () {
      expect(
        const RadarSeriesStyle(markerBorderWidth: -1).validate,
        throwsArgumentError,
      );
      expect(
        const RadarSeriesStyle(maximumVisibleDataLabels: 0).validate,
        throwsArgumentError,
      );
      expect(
        const RadarSeriesStyle(dataLabelOffset: double.infinity).validate,
        throwsArgumentError,
      );
    });
  });
}
