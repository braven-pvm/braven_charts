import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/snippets/basic_grammar_chart.dart';
import 'package:braven_charts_example/snippets/basic_line_chart.dart';
import 'package:braven_charts_example/snippets/persistent_selection_brush_chart.dart';
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

  testWidgets(
    'persistent brush snippet mounts and supports controller commands',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: persistentSelectionBrushChart(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(controller.selectionBrushState?.visible, isTrue);
      expect(controller.selectionBrushState?.range.minimum, 1.5);
      expect(controller.selectionBrushState?.range.maximum, 3.5);

      expect(showLatestWindow(controller), isA<ChartArtifactSuccess<void>>());
      await tester.pump();
      expect(controller.selectionBrushState?.range.minimum, 3);
      expect(controller.selectionBrushState?.range.maximum, 5);

      expect(
        controller.hideSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState?.visible, isFalse);

      expect(
        controller.showSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState?.visible, isTrue);

      expect(
        controller.clearSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
