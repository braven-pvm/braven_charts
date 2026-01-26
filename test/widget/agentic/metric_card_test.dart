import 'package:braven_charts/src/agentic/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetricCard', () {
    testWidgets('renders metric name, value, and unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              name: 'NP',
              value: 250,
              unit: 'watts',
            ),
          ),
        ),
      );

      expect(find.text('NP'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('watts'), findsOneWidget);
    });

    testWidgets('formats values based on metric type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MetricCard(
                  name: 'IF',
                  value: 0.85,
                  unit: '',
                ),
                MetricCard(
                  name: 'TSS',
                  value: 150.0,
                  unit: '',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('0.85'), findsOneWidget,
          reason: 'IF should be formatted to 2 decimal places');
      expect(find.text('150'), findsOneWidget,
          reason: 'TSS should be formatted to 0 decimal places');
    });
  });
}
