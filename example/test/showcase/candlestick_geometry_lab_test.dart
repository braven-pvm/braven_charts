import 'package:braven_charts_example/showcase/pages/candlestick_geometry_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(390, 844), Size(1400, 1000)]) {
    testWidgets('geometry lab remains usable at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: CandlestickGeometryLabPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Candlestick geometry foundation'), findsOneWidget);
      expect(find.text('Direction and irregular time'), findsOneWidget);
      expect(find.text('Viewport culling'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final titleRect = tester.getRect(
        find.text('Candlestick geometry foundation'),
      );
      final panelRect = tester.getRect(
        find.text('Direction and irregular time'),
      );
      expect(titleRect.right, lessThanOrEqualTo(size.width));
      expect(panelRect.right, lessThanOrEqualTo(size.width));
    });
  }
}
