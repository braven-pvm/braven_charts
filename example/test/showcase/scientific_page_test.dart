import 'package:braven_charts_example/showcase/pages/scientific_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scientific hub includes signals and physiology examples', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScientificPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Scientific examples'), findsOneWidget);
    expect(find.text('Signals & Distributions'), findsOneWidget);

    await tester.tap(find.text('Power + Lactate'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cyclist Power vs Lactate'), findsOneWidget);
    var options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Scenario Guide'),
      300,
      scrollable: options,
    );
    expect(find.text('Scenario Guide'), findsOneWidget);

    await tester.tap(find.text('Lactate Threshold').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lactate Threshold Detection'), findsOneWidget);
    options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Section Chord'),
      300,
      scrollable: options,
    );
    expect(find.text('Section Chord'), findsOneWidget);
    expect(find.text('Ramp Chord'), findsOneWidget);
  });
}
