import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactShowcasePage());

  testWidgets('presents the complete artifact workflow on one page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await _settleCapture(tester);

    expect(find.text('Save, share, and restore charts'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsNWidgets(2));
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('One capture. Three useful outcomes.'), findsOneWidget);
    expect(find.text('Capture the effective chart'), findsOneWidget);
    expect(find.text('Show the data behind it'), findsOneWidget);
    expect(find.text('Scale for larger data'), findsOneWidget);
    expect(find.text('A small API surface for a durable chart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the single page usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Capture artifact'), findsOneWidget);
    expect(find.text('Split'), findsNothing);
    expect(find.text('Explore the same chart three ways'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.pump();
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
