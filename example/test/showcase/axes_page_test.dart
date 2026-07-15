import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/axes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('axes groups ticks, render windows, and slot allocation', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Axes examples'), findsOneWidget);
    expect(find.text('Ticks & grid'), findsOneWidget);
    expect(find.text('Render windows'), findsOneWidget);
    expect(find.text('Axis slots'), findsOneWidget);
    expect(find.text('Ticks & Grid'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Render windows'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Axis Render Windows'), findsOneWidget);
    expect(find.text('Y-Axis Render Range'), findsOneWidget);

    await tester.tap(find.text('Axis slots'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Axis Slots'), findsWidgets);
    expect(find.text('Axis Slot Demo'), findsOneWidget);
  });

  testWidgets('axes selector remains usable on narrow layouts', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AxesPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('axes-example-picker')), findsOneWidget);
    expect(find.text('Ticks & Grid'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);

    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Chart options'), findsOneWidget);
    expect(find.text('Show minor ticks'), findsOneWidget);
    Navigator.of(tester.element(find.text('Chart options'))).pop();
    await tester.pumpAndSettle();

    final selectorScroll = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Render windows'),
      120,
      scrollable: selectorScroll,
    );
    await tester.tap(find.text('Render windows'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Axis Render Windows'), findsOneWidget);
  });
}
