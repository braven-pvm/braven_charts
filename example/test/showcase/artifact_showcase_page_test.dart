import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_showcase_page.dart';
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

    expect(find.text('One chart, every portable surface'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsNWidgets(2));
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('Schema + canonical JSON'), findsOneWidget);
    expect(find.text('Revision-bound preview'), findsOneWidget);
    expect(find.text('Payload strategies'), findsOneWidget);
    expect(find.text('Identity + compatibility'), findsOneWidget);
    expect(find.text('Effective extraction'), findsOneWidget);
    expect(find.text('Native data table'), findsOneWidget);
    expect(find.text('Large-data payloads'), findsOneWidget);
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
    expect(find.text('Chart, data, and restored runtime'), findsOneWidget);
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
