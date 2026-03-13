import 'package:braven_charts_plus_example/showcase/pages/tracking_page.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TrackingPage renders dedicated tracking verification content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TrackingPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tracking Lab'), findsOneWidget);
    expect(find.text('Interpolation Comparison'), findsOneWidget);
    expect(find.text('Bezier Tension Sweep'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsAtLeastNWidgets(2));
    expect(find.text('Forced'), findsOneWidget);
  });
}
