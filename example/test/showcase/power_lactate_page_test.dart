import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/power_lactate_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PowerLactatePage renders the mixed streaming scenario', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PowerLactatePage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Power + Lactate'), findsOneWidget);
    expect(find.text('Cyclist Power vs Lactate'), findsOneWidget);
    expect(find.text('1 Hz'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('VIEW LIVE'), findsOneWidget);
  });
}
