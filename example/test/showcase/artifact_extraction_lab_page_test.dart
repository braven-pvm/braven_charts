import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_plus_example/showcase/pages/artifact_extraction_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject() => const MaterialApp(home: ArtifactExtractionLabPage());

  testWidgets('captures controller, live, and visibility state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.tap(find.text('Add controller point'));
    await tester.tap(find.text('Add live point'));
    await tester.tap(find.text('Hide heart rate'));
    await tester.tap(find.text('Capture document'));
    await tester.pump();

    expect(find.byType(BravenChartPlus), findsOneWidget);
    expect(find.text('Revision  0'), findsOneWidget);
    expect(find.text('Series  2'), findsOneWidget);
    expect(find.text('Points  14'), findsOneWidget);
    expect(find.text('Annotations  1'), findsOneWidget);
    expect(find.textContaining('showcase-live-capture'), findsOneWidget);
    expect(find.textContaining('hiddenSeriesIds'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps capture available on a compact viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byTooltip('Capture document'));
    await tester.pump();

    expect(find.text('Artifact Extraction Lab'), findsOneWidget);
    expect(find.byTooltip('Capture document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
