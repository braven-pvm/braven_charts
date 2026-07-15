import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_resolver_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactResolverLabPage());

  testWidgets('resolves verified blobs into a hydrated chart and table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Resolve payload'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('2 referenced payloads resolved'),
      findsOneWidget,
    );
    expect(find.text('Hydrated chart'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(find.text('Resolver calls'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks tampered bytes before hydration', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Test checksum failure'));
    await tester.pumpAndSettle();

    expect(find.text('data_payload_integrity_mismatch'), findsOneWidget);
    expect(find.text('Hydration blocked safely'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsNothing);
    expect(find.byType(ChartDataTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps both resolver actions available on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Resolve payload'), findsOneWidget);
    expect(find.text('Test checksum failure'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
