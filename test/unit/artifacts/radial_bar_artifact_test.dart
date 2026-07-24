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
        showDataLabels: false,
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
