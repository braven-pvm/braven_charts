import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSeries presentation visibility', () {
    test('defaults all presentation controls to visible', () {
      const series = LineChartSeries(id: 'observed', points: []);

      expect(series.showInLegend, isTrue);
      expect(series.showTrackingAxisLabel, isTrue);
      expect(series.showInTrackingTooltip, isTrue);
    });

    test('copyWith preserves and can replace every control', () {
      final series = RangeAreaChartSeries(
        id: 'forecast',
        points: [RangeAreaDataPoint(x: 0, low: 10, high: 20)],
        showInLegend: false,
        showTrackingAxisLabel: false,
        showInTrackingTooltip: false,
      );

      final preserved = series.copyWith(name: 'Forecast interval');
      final restored = series.copyWith(
        showInLegend: true,
        showTrackingAxisLabel: true,
        showInTrackingTooltip: true,
      );

      expect(preserved.showInLegend, isFalse);
      expect(preserved.showTrackingAxisLabel, isFalse);
      expect(preserved.showInTrackingTooltip, isFalse);
      expect(restored.showInLegend, isTrue);
      expect(restored.showTrackingAxisLabel, isTrue);
      expect(restored.showInTrackingTooltip, isTrue);
    });

    test('equality and hash code include every control', () {
      const visible = LineChartSeries(id: 'observed', points: []);
      const hiddenFromLegend = LineChartSeries(
        id: 'observed',
        points: [],
        showInLegend: false,
      );
      const hiddenTrackingLabel = LineChartSeries(
        id: 'observed',
        points: [],
        showTrackingAxisLabel: false,
      );
      const hiddenTrackingTooltip = LineChartSeries(
        id: 'observed',
        points: [],
        showInTrackingTooltip: false,
      );

      expect(visible, isNot(hiddenFromLegend));
      expect(visible, isNot(hiddenTrackingLabel));
      expect(visible, isNot(hiddenTrackingTooltip));
      expect(visible.hashCode, isNot(hiddenFromLegend.hashCode));
      expect(visible.hashCode, isNot(hiddenTrackingLabel.hashCode));
      expect(visible.hashCode, isNot(hiddenTrackingTooltip.hashCode));
    });
  });
}
