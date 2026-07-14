import 'package:braven_charts_plus_example/showcase/pages/artifact_schema_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() =>
      const MaterialApp(home: Scaffold(body: ArtifactSchemaLabPage()));

  testWidgets('round-trips the schema sample and updates its summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Round-trip JSON'));
    await tester.pump();

    expect(find.text('Round trip passed'), findsOneWidget);
    expect(find.text('Schema'), findsOneWidget);
    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('Config codecs'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows a structured error for a future schema', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Load invalid schema'));
    await tester.pump();
    await tester.tap(find.text('Round-trip JSON'));
    await tester.pump();

    expect(find.text('unsupported_schema_version'), findsOneWidget);
    expect(find.textContaining(r'$.schemaVersion'), findsOneWidget);
  });

  testWidgets('keeps the codec controls usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.ensureVisible(find.text('Round-trip JSON'));

    expect(find.text('Artifact schema lab'), findsOneWidget);
    expect(find.text('Round-trip JSON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
