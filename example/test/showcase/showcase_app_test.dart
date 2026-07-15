import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:braven_charts_example/showcase/widgets/braven_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('narrow showcase uses a drawer for the complete feature list', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(390 * pixelRatio, 844 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Gallery'), findsWidgets);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(BravenBrand), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Loading States'),
      300,
      scrollable: find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Loading States'), findsOneWidget);
  });

  testWidgets('wide showcase uses the persistent feature rail', (tester) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BravenBrand), findsOneWidget);
    expect(find.text('Tracking Lab'), findsNothing);
    expect(find.text('Interaction'), findsOneWidget);
    expect(find.text('Power + Lactate'), findsNothing);
    expect(find.text('Lactate Threshold'), findsNothing);
    expect(find.text('Multi-Axis'), findsOneWidget);
    expect(find.text('Axes'), findsOneWidget);
    expect(find.text('Minor Ticks'), findsNothing);
    expect(find.text('Render Range'), findsNothing);
    expect(find.text('Axis Slots'), findsNothing);
    expect(find.text('Segment Styling'), findsNothing);
    expect(find.text('Point Labels'), findsNothing);
    expect(find.text('Series Styling'), findsOneWidget);

    await tester.tap(find.text('Performance'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Performance Lab'), findsOneWidget);
    expect(find.text('Needs review'), findsNothing);
  });

  testWidgets('streaming is consolidated into the live stream destination', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Streaming'), findsNothing);
    expect(find.text('Live Stream'), findsOneWidget);

    await tester.tap(find.text('Live Stream'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Live Streaming'), findsOneWidget);
    expect(find.text('Live Data Stream'), findsOneWidget);
  });
}
