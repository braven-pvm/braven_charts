import 'package:braven_charts/braven_charts_fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gauge fluent modifiers preserve the typed series contract', () {
    final gauge =
        GaugeChartSeries.needle(
              id: 'cpu',
              metric: 'CPU load',
              value: 62,
              minimum: 0,
              maximum: 100,
            )
            .withValue(78)
            .withIndicatorStyle(
              const SolidGaugeStyle()
                  .withTrackColor(Colors.black12)
                  .withCornerRadius(12),
            )
            .withTarget(
              const GaugeTarget(value: 80).withLabel('Budget').withWidth(4),
            )
            .withZones([
              const GaugeZone(from: 0, to: 70, status: 'Healthy'),
              const GaugeZone(
                from: 70,
                to: 100,
                status: 'Elevated',
              ).withColor(Colors.orange),
            ]);

    expect(gauge.value, 78);
    expect(gauge.indicatorStyle, isA<SolidGaugeStyle>());
    expect((gauge.indicatorStyle as SolidGaugeStyle).cornerRadius, 12);
    expect(
      gauge.target,
      const GaugeTarget(value: 80, label: 'Budget', width: 4),
    );
    expect(gauge.status, 'Elevated');
  });

  test('Gauge config fluent modifiers rebuild nested center content', () {
    final config = const GaugeChartConfig()
        .withTickCount(8)
        .withShowZones(false)
        .updateCenter(
          (center) => center
              .withShowTarget(true)
              .withShowStatus(false)
              .updateValueStyle((style) => style.copyWith(fontSize: 28)),
        );

    expect(config.tickCount, 8);
    expect(config.showZones, isFalse);
    expect(config.center.showTarget, isTrue);
    expect(config.center.showStatus, isFalse);
    expect(config.center.valueStyle.fontSize, 28);
  });
}
