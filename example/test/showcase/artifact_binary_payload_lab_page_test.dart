import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_binary_payload_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactBinaryPayloadLabPage());

  testWidgets('runs a verified binary round trip into chart and table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Run binary round trip'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Verified binary payload'), findsOneWidget);
    expect(find.text('Space saved'), findsOneWidget);
    expect(find.text('xor-significant-bytes-v1'), findsOneWidget);
    expect(find.text('Hydrated chart'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks a corrupted binary blob before hydration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Test corrupt bytes'));
    await tester.pumpAndSettle();

    expect(find.text('data_payload_integrity_mismatch'), findsOneWidget);
    expect(find.text('Hydration blocked safely'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsNothing);
    expect(find.byType(ChartDataTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps dataset and action controls usable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('250'), findsOneWidget);
    expect(find.text('2.5K'), findsOneWidget);
    expect(find.text('25K'), findsOneWidget);
    expect(find.text('Run binary round trip'), findsOneWidget);
    expect(find.text('Test corrupt bytes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
