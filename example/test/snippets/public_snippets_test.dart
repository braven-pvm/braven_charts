import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/snippets/basic_grammar_chart.dart';
import 'package:braven_charts_example/snippets/basic_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('direct README snippet mounts the public chart widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BasicLineChart())),
    );
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grammar README snippet lowers to the public chart widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SizedBox(height: 280, child: basicGrammarChart)),
      ),
    );
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
