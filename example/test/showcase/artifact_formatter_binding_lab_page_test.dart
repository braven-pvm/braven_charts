import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/artifact_formatter_binding_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() =>
      const MaterialApp(home: ArtifactFormatterBindingLabPage());

  testWidgets('uses safe fallback when the host formatter is absent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Restore with fallback'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('250.0 W (fallback)'), findsOneWidget);
    expect(find.text('unregistered_formatter'), findsOneWidget);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebinds a custom formatter by stable ID', (tester) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Restore with host binding'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('250 W · host'), findsOneWidget);
    expect(find.textContaining('warnings 0'), findsOneWidget);
    expect(find.text('unregistered_formatter'), findsNothing);
    expect(find.byType(HydratedBravenChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps both restore paths usable on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Restore with fallback'), findsOneWidget);
    expect(find.text('Restore with host binding'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
