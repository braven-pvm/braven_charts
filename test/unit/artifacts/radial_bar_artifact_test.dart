import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Radial Bar series and plot configuration round-trip without loss', () {
    final source = RadialBarChartSeries.fromMap(
      id: 'delivery',
      name: 'Delivery',
      unit: '%',
      values: const {'Discover': 72, 'Build': 54, 'Launch': 31},
      barColors: const {'Build': Color(0xFF00A878)},
      minimum: -20,
      maximum: 120,
      baseline: 10,
      radialBarStyle: const RadialBarStyle(
        cornerRadius: 5,
        opacity: 0.8,
        borderColor: Color(0xFF112233),
        borderWidth: 2,
        trackColor: Color(0xFF445566),
        trackOpacity: 0.2,
        gradient: RadialBarGradientStyle(
          type: RadialBarGradientType.radial,
          startColor: Color(0xFF22D3EE),
          endColor: Color(0xFF1D4ED8),
          startLightnessShift: 0.2,
          endLightnessShift: -0.18,
        ),
        showDataLabels: false,
        dataLabels: RadialBarDataLabelConfig(
          position: RadialBarDataLabelPosition.outsideCallout,
          content: RadialBarDataLabelContent.categoryAndValue,
          colorMode: RadialBarDataLabelColorMode.fixed,
          textStyle: PolarLabelStyle(
            color: Color(0xFF778899),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          offset: 6,
          showPanel: true,
          panelStyle: LabelStyle(
            textStyle: TextStyle(),
            backgroundColor: Color(0xFFF8FAFC),
            borderColor: Color(0xFFCBD5E1),
            borderWidth: 1,
            borderRadius: 5,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
          connectorLength: 18,
          connectorWidth: 1.5,
          connectorColor: Color(0xFFAA5500),
        ),
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
      ),
    );
    const config = RadialBarChartConfig(
      pane: PolarPaneConfig(
        startAngleDegrees: -120,
        sweepAngleDegrees: 280,
        clockwise: false,
        innerRadiusFactor: 0.18,
        outerRadiusFactor: 0.9,
      ),
      trackGap: 9,
      trackOrder: RadialBarTrackOrder.innerToOuter,
      showCategoryLabels: false,
      categoryLabels: RadialBarCategoryLabelConfig(
        position: RadialBarCategoryLabelPosition.startGap,
        orientation: RadialBarCategoryLabelOrientation.horizontal,
        offset: 9,
        textStyle: PolarLabelStyle(
          color: Color(0xFF223344),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        showPanel: true,
        panelStyle: LabelStyle(
          textStyle: TextStyle(),
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFCBD5E1),
          borderWidth: 1,
          borderRadius: 6,
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        ),
        connectorLength: 20,
        connectorWidth: 2,
        connectorColor: Color(0xFF556677),
      ),
      showScaleLabels: false,
      showGridLines: false,
      tickCount: 7,
      thresholds: [
        RadialBarThreshold(
          value: 80,
          label: 'Target',
          color: Color(0xFFAA2200),
          width: 2,
          dashPattern: [3, 2],
        ),
      ],
    );

    final encodedSeries = _success(
      ChartSeriesDocumentCodec.encode(source),
    ).value;
    expect(encodedSeries.type, 'radialBar');
    expect(
      encodedSeries.requiredCapabilities,
      contains('series.radial.bar.v1'),
    );
    expect(
      _success(ChartSeriesDocumentCodec.decode(encodedSeries)).value,
      source,
    );

    final encodedConfig = _success(
      ChartConfigurationDocumentCodec.encodeRadialBarChart(config),
    ).value;
    expect(
      _success(
        ChartConfigurationDocumentCodec.decodeRadialBarChart(encodedConfig),
      ).value,
      config,
    );
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
