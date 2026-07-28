import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/models/gauge_chart_config.dart';
import 'package:braven_charts/src/models/gauge_chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gauge series and plot configuration round-trip without loss', () {
    final variants = <GaugeChartSeries>[
      GaugeChartSeries.needle(
        id: 'cpu',
        name: 'CPU',
        metric: 'CPU utilization',
        value: 72,
        minimum: 0,
        maximum: 100,
        unit: '%',
        color: const Color(0xFF0B7285),
        target: const GaugeTarget(
          value: 70,
          label: 'SLO',
          color: Color(0xFF4C6EF5),
          width: 4,
        ),
        zones: const [
          GaugeZone(
            from: 0,
            to: 60,
            status: 'Healthy',
            color: Color(0xFF2F9E44),
          ),
          GaugeZone(
            from: 60,
            to: 100,
            status: 'Elevated',
            color: Color(0xFFF08C00),
          ),
        ],
        thresholds: const [
          GaugeThreshold(
            value: 85,
            label: 'Critical',
            color: Color(0xFFE03131),
            width: 2,
            dashPattern: [3, 2],
          ),
        ],
        style: const NeedleGaugeStyle(
          needleLengthFactor: 0.8,
          needleWidth: 18,
          needleTipWidth: 3,
          pivotRadius: 7,
          pivotBorderColor: Color(0xFF111827),
          pivotBorderWidth: 2,
          axisThickness: 14,
          axisOpacity: 0.22,
        ),
      ),
      GaugeChartSeries.solid(
        id: 'availability',
        metric: 'Availability',
        value: 99.93,
        minimum: 99,
        maximum: 100,
        unit: '%',
        style: const SolidGaugeStyle(
          trackOpacity: 0.2,
          cornerRadius: 10,
          borderColor: Color(0xFF112233),
          borderWidth: 1.5,
          opacity: 0.9,
          gradient: GaugeGradientStyle(
            type: GaugeGradientType.radial,
            startColor: Color(0xFF22D3EE),
            endColor: Color(0xFF4F46E5),
          ),
        ),
      ),
    ];
    for (final source in variants) {
      final encoded = _success(ChartSeriesDocumentCodec.encode(source)).value;
      expect(encoded.type, 'gauge');
      expect(encoded.requiredCapabilities, contains('series.gauge.v1'));
      expect(_success(ChartSeriesDocumentCodec.decode(encoded)).value, source);
    }

    const config = GaugeChartConfig(
      pane: PolarPaneConfig(
        startAngleDegrees: -120,
        sweepAngleDegrees: 240,
        clockwise: false,
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.9,
      ),
      tickCount: 7,
      minorTicksPerInterval: 4,
      showAxis: false,
      showTicks: false,
      showTickLabels: false,
      showZones: false,
      colorIndicatorByActiveZone: false,
      scale: GaugeScaleStyle(
        tickColor: Color(0xFF224466),
        tickWidth: 2.5,
        tickLength: 18,
        tickPosition: GaugeTickPosition.inside,
        tickGap: 9,
        minorTickColor: Color(0xFF64748B),
        minorTickWidth: 1.25,
        minorTickLength: 6,
        labelStyle: PolarLabelStyle(
          color: Color(0xFF112233),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelPosition: GaugeScaleLabelPosition.outside,
        labelOffset: 14,
        labelMaxWidth: 96,
      ),
      zones: GaugeZoneStyle(
        gap: 4,
        cornerRadius: 3,
        opacity: 0.86,
        borderColor: Color(0xFF334155),
        borderWidth: 1,
      ),
      references: GaugeReferenceStyle(
        innerLineOffset: 8,
        outerLineOffset: 12,
        labelStyle: PolarLabelStyle(color: Color(0xFF334455), fontSize: 11),
        labelOffset: 15,
        labelMaxWidth: 120,
        showLabelPanel: true,
        panelColor: Color(0xFFF8FAFC),
        panelBorderColor: Color(0xFFCBD5E1),
        panelBorderWidth: 1.5,
        panelBorderRadius: 7,
        panelPadding: 6,
      ),
      center: GaugeCenterConfig(
        showMetric: false,
        showTarget: true,
        statusStyle: PolarLabelStyle(
          color: Color(0xFFAA2200),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        horizontalOffset: 5,
        verticalOffset: -7,
        lineSpacing: 6,
      ),
    );
    final encodedConfig = _success(
      ChartConfigurationDocumentCodec.encodeGaugeChart(config),
    ).value;
    expect(
      _success(
        ChartConfigurationDocumentCodec.decodeGaugeChart(encodedConfig),
      ).value,
      config,
    );
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  if (result case ChartArtifactFailure<T> failure) {
    fail(
      '${failure.error.code}: ${failure.error.message} '
      'at ${failure.error.path}',
    );
  }
  return result as ChartArtifactSuccess<T>;
}
