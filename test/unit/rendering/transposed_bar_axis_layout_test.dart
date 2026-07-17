import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/transposed_bar_axis_layout.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransposedBarAxisLayout', () {
    const labelStyle = TextStyle(fontSize: 12);

    test('maps left axes below and right axes above the plot', () {
      final revenue = YAxisConfig.withId(
        id: 'revenue',
        position: YAxisPosition.left,
        label: 'Revenue',
        unit: r'$k',
      );
      final margin = YAxisConfig.withId(
        id: 'margin',
        position: YAxisPosition.left,
        label: 'Margin',
        unit: '%',
      );
      final orders = YAxisConfig.withId(
        id: 'orders',
        position: YAxisPosition.right,
        label: 'Orders',
      );
      final conversion = YAxisConfig.withId(
        id: 'conversion',
        position: YAxisPosition.right,
        label: 'Conversion',
        unit: '%',
      );
      final layout = TransposedBarAxisLayout(
        axes: [revenue, orders, conversion, margin],
        labelStyle: labelStyle,
      );
      const plot = Rect.fromLTWH(80, 100, 600, 400);
      final rects = layout.axisRects(plot);

      expect(layout.bottomAxes.map((axis) => axis.id), ['revenue', 'margin']);
      expect(layout.topAxes.map((axis) => axis.id), ['orders', 'conversion']);
      expect(rects['revenue']!.top, plot.bottom);
      expect(rects['margin']!.top, rects['revenue']!.bottom);
      expect(rects['orders']!.bottom, plot.top);
      expect(rects['conversion']!.bottom, rects['orders']!.top);
      expect(layout.bottomExtent, greaterThan(80));
      expect(layout.topExtent, greaterThan(80));
    });

    test('hidden axes consume no transposed layout space', () {
      final visible = YAxisConfig.withId(
        id: 'visible',
        position: YAxisPosition.left,
        label: 'Visible',
      );
      final hidden = YAxisConfig.withId(
        id: 'hidden',
        position: YAxisPosition.hidden,
        label: 'Hidden',
      );
      final layout = TransposedBarAxisLayout(
        axes: [visible, hidden],
        labelStyle: labelStyle,
      );

      expect(layout.bottomAxes, [visible]);
      expect(layout.topAxes, isEmpty);
      expect(
        layout.axisRects(const Rect.fromLTWH(0, 0, 100, 100)),
        isNot(contains('hidden')),
      );
    });
  });
}
