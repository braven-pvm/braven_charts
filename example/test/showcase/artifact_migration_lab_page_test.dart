import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_migration_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactMigrationLabPage());

  testWidgets('migrates legacy JSON before chart and table hydration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Migrate legacy artifact'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Migration applied'), findsOneWidget);
    expect(find.text('v0->v1'), findsOneWidget);
    expect(find.text('Migrated chart'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(find.byType(ChartDataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks hydration when the migration path is missing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Test missing migration'));
    await tester.pumpAndSettle();

    expect(find.text('unsupported_schema_version'), findsOneWidget);
    expect(find.text('Hydration blocked safely'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsNothing);
    expect(find.byType(ChartDataTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps migration actions available on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Migrate legacy artifact'), findsOneWidget);
    expect(find.text('Test missing migration'), findsOneWidget);
    expect(find.text('Adjacent only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
