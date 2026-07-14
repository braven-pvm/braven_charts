import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_hydration_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() => const MaterialApp(home: ArtifactHydrationLabPage());

  testWidgets(
    'captures, hydrates, restores view state, and rebinds callbacks',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.text('Hide heart rate'));
      await tester.tap(find.text('Capture + hydrate'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(BravenChartPlus), findsNWidgets(2));
      expect(find.text('Revision 0'), findsOneWidget);
      expect(find.text('Warnings 0'), findsOneWidget);

      await tester.tap(find.text('Select hydrated power'));
      await tester.pump();
      expect(find.text('Hydrated callback: selected power'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps hydration action usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byTooltip('Capture and hydrate'));
    await tester.pump();

    expect(find.text('Artifact Hydration Lab'), findsOneWidget);
    expect(find.byTooltip('Capture and hydrate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
