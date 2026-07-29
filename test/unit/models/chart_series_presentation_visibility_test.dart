import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSeries presentation visibility', () {
    test('defaults both opt-out controls to visible', () {
      const series = LineChartSeries(id: 'observed', points: []);

      expect(series.showInLegend, isTrue);
      expect(series.showTrackingAxisLabel, isTrue);
    });

    test('copyWith preserves and can replace both controls', () {
      final series = RangeAreaChartSeries(
        id: 'forecast',
        points: [RangeAreaDataPoint(x: 0, low: 10, high: 20)],
        showInLegend: false,
        showTrackingAxisLabel: false,
      );

      final preserved = series.copyWith(name: 'Forecast interval');
      final restored = series.copyWith(
        showInLegend: true,
        showTrackingAxisLabel: true,
      );

      expect(preserved.showInLegend, isFalse);
      expect(preserved.showTrackingAxisLabel, isFalse);
      expect(restored.showInLegend, isTrue);
      expect(restored.showTrackingAxisLabel, isTrue);
    });

    test('equality and hash code include both controls', () {
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

      expect(visible, isNot(hiddenFromLegend));
      expect(visible, isNot(hiddenTrackingLabel));
      expect(visible.hashCode, isNot(hiddenFromLegend.hashCode));
      expect(visible.hashCode, isNot(hiddenTrackingLabel.hashCode));
    });
  });
}
