import 'package:braven_charts_example/showcase/pages/artifact_export_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactExportLabPage());

  testWidgets('extracts a matching preview and preserves fallback artifact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Extract artifact'));
    await _settleCapture(tester);

    expect(find.text('Hash match'), findsOneWidget);
    expect(find.bySemanticsLabel('Artifact preview'), findsOneWidget);
    expect(
      find.textContaining('hash-matched preview captured'),
      findsOneWidget,
    );
    expect(find.textContaining('sha256:'), findsOneWidget);

    await tester.tap(find.text('Test preview fallback'));
    await _settleCapture(tester);

    expect(find.text('Document only'), findsOneWidget);
    expect(find.textContaining('Native artifact preserved'), findsOneWidget);
    expect(find.textContaining('preview_too_large:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps extraction available on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Extract artifact'), findsOneWidget);
    expect(find.text('Artifact Export Lab'), findsOneWidget);
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
