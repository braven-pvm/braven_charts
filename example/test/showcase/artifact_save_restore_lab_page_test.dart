import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_save_restore_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() => const MaterialApp(home: ArtifactSaveRestoreLabPage());

  testWidgets('saves canonical JSON and restores independent chart copies', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Hide heart rate'));
    await tester.tap(find.text('Save canonical JSON'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Canonical JSON ready'), findsOneWidget);
    expect(find.textContaining('canonical schema-v1 JSON'), findsOneWidget);
    expect(find.textContaining('sha256:'), findsOneWidget);

    await tester.tap(find.text('Restore another copy'));
    await tester.pump();
    await tester.tap(find.text('Restore another copy'));
    await tester.pump();

    expect(find.text('2 copies'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsNWidgets(2));
    expect(find.byType(BravenChartPlus), findsNWidgets(3));

    await tester.tap(find.text('Select power').first);
    await tester.pump();
    expect(find.text('Restored copy 1 selected power.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps persistence actions usable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Save canonical JSON'), findsOneWidget);
    expect(find.text('Restore another copy'), findsOneWidget);
    expect(find.text('Hide heart rate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
