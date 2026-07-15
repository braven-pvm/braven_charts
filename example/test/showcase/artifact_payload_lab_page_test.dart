import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_payload_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactPayloadLabPage());

  testWidgets('compares payloads and renders the decoded columnar table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Compare payloads'));
    await tester.pump();

    expect(find.textContaining('inlineColumns decoded'), findsOneWidget);
    expect(find.text('Hydrated points'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.textContaining('Power'), findsWidgets);
    expect(find.textContaining('Heart rate'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the comparison action available on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Compare payloads'), findsOneWidget);
    expect(find.text('Artifact Payload Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
