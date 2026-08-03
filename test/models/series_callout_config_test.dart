import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('global participation can be overridden per stable series id', () {
    const config = SeriesCalloutConfig(
      enabled: true,
      showByDefault: true,
      series: {
        'hidden': SeriesCalloutSpec(show: false),
        'renamed': SeriesCalloutSpec(label: 'Current plan', priority: 4),
      },
    );

    expect(config.showsSeries('default'), isTrue);
    expect(config.showsSeries('hidden'), isFalse);
    expect(config.specFor('renamed').label, 'Current plan');
    expect(config.specFor('renamed').priority, 4);
  });

  test('disabled global policy suppresses explicit series opt-in', () {
    const config = SeriesCalloutConfig(
      series: {'power': SeriesCalloutSpec(show: true)},
    );

    expect(config.showsSeries('power'), isFalse);
  });

  test('equal override maps have stable order-independent hash codes', () {
    const first = SeriesCalloutConfig(
      enabled: true,
      series: {
        'power': SeriesCalloutSpec(label: 'Power'),
        'heart-rate': SeriesCalloutSpec(show: false),
      },
    );
    const second = SeriesCalloutConfig(
      enabled: true,
      series: {
        'heart-rate': SeriesCalloutSpec(show: false),
        'power': SeriesCalloutSpec(label: 'Power'),
      },
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('copyWith clear flags restore nullable global and series defaults', () {
    const config = SeriesCalloutConfig(
      anchorX: 42,
      connectorColor: Color(0xFF102030),
      backgroundColor: Color(0xFFFFFFFF),
      panelBackgroundColor: Color(0xFFEFF6FF),
      panelBorderColor: Color(0xFF60A5FA),
    );
    const spec = SeriesCalloutSpec(
      label: 'Plan',
      show: false,
      anchorX: 21,
      connectorWidth: 2,
      connectorOpacity: 0.7,
      connectorGlow: 5,
      backgroundOpacity: 0.8,
      borderWidth: 1.5,
      borderRadius: 7,
    );

    expect(
      config.copyWith(
        clearAnchorX: true,
        clearConnectorColor: true,
        clearBackgroundColor: true,
        clearPanelBackgroundColor: true,
        clearPanelBorderColor: true,
      ),
      const SeriesCalloutConfig(),
    );
    expect(
      spec.copyWith(
        clearLabel: true,
        clearShow: true,
        clearAnchorX: true,
        clearConnectorWidth: true,
        clearConnectorOpacity: true,
        clearConnectorGlow: true,
        clearBackgroundOpacity: true,
        clearBorderWidth: true,
        clearBorderRadius: true,
      ),
      const SeriesCalloutSpec(),
    );
  });

  test('style assertions reject invalid opacity and dimensions', () {
    expect(
      () => SeriesCalloutConfig(connectorOpacity: 1.1),
      throwsAssertionError,
    );
    expect(
      () => SeriesCalloutConfig(panelBorderWidth: -1),
      throwsAssertionError,
    );
    expect(() => SeriesCalloutConfig(connectorGlow: -1), throwsAssertionError);
    expect(() => SeriesCalloutSpec(connectorGlow: -1), throwsAssertionError);
    expect(
      () => SeriesCalloutSpec(backgroundOpacity: -0.1),
      throwsAssertionError,
    );
  });
}
