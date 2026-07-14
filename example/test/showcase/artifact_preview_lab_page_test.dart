import 'package:braven_charts_plus_example/showcase/pages/artifact_preview_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactPreviewLabPage());

  testWidgets('captures a real PNG and keeps document usable after failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Capture PNG preview'));
    await _settleCapture(tester);

    expect(find.bySemanticsLabel('Captured chart preview'), findsOneWidget);
    expect(find.textContaining('PNG captured'), findsOneWidget);
    expect(find.textContaining('sha256:'), findsOneWidget);

    await tester.tap(find.text('Test independent failure'));
    await _settleCapture(tester);
    expect(find.textContaining('preview_too_large returned'), findsOneWidget);
    expect(find.textContaining('remains usable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps preview capture available on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byTooltip('Capture PNG preview'), findsOneWidget);
    expect(find.text('Artifact Preview Lab'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleCapture(WidgetTester tester) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump();
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}
