import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps legacy legend construction and default formatting compatible',
    () {
      const point = ChartDataPoint(x: 0, y: 42, label: 'Subscriptions');
      final item = RadialLegendItemData(
        seriesId: 'revenue',
        seriesName: 'Revenue',
        unit: 'USD',
        visibleIndex: 0,
        pointIndex: 0,
        sourcePointIndices: const [0],
        sourcePoints: const [point],
        point: point,
        category: 'Subscriptions',
        value: 42,
        share: .42,
        color: Colors.blue,
        selectionColor: Colors.indigo,
        defaultTextStyle: const TextStyle(),
        selected: false,
        animationDuration: Duration.zero,
      );

      expect(item.valueLabel, '42.00 USD');
      expect(item.shareLabel, '42.0%');
    },
  );
}
