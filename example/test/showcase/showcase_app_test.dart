import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:braven_charts_example/showcase/widgets/braven_brand.dart';
import 'package:braven_charts/braven_charts.dart';
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
    expect(tester.takeException(), isNull);

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
    expect(tester.takeException(), isNull);

    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(BravenBrand), findsOneWidget);
    expect(find.text('Tracking Lab'), findsNothing);
    expect(find.text('Interaction'), findsOneWidget);
    expect(find.text('Line Charts'), findsOneWidget);
    expect(find.text('Area Charts'), findsOneWidget);
    expect(find.text('Bar Charts'), findsOneWidget);
    expect(find.text('Scatter Charts'), findsOneWidget);
    expect(find.text('Candlestick Charts'), findsOneWidget);
    expect(find.text('Pie Charts'), findsOneWidget);
    expect(find.text('Donut Charts'), findsOneWidget);
    expect(find.text('Concentric Donut Charts'), findsOneWidget);
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
    expect(
      tester.getRect(find.byKey(const ValueKey('chart-type-card-donut'))).right,
      lessThanOrEqualTo(1440),
    );

    await tester.tap(find.text('Line Charts'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Choose a line chart example'), findsOneWidget);
    expect(find.text('Workhorse'), findsWidgets);
    final selectedRailItem = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Line Charts'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final selectedDecoration = selectedRailItem.decoration! as BoxDecoration;
    expect(selectedDecoration.borderRadius, isNull);
    expect(selectedDecoration.boxShadow, isNull);
    expect(selectedDecoration.color, Colors.transparent);

    await tester.tap(find.text('Candlestick Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('candlestick-reference-chart')),
      findsOneWidget,
    );

    await tester.tap(find.text('Pie Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Choose a category story'), findsOneWidget);
    expect(find.byKey(const ValueKey('pie-showcase-chart')), findsOneWidget);

    await tester.tap(find.text('Donut Charts'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    expect(find.text('Contribution ring'), findsOneWidget);

    await tester.tap(find.text('Performance'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

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

    expect(find.text('Choose a streaming strategy'), findsOneWidget);
    expect(find.text('Follow latest'), findsWidgets);
  });

  testWidgets('Workbench presentation follows chart-family navigation', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 900 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ShowcaseApp());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Line Charts'));
    await tester.pump(const Duration(milliseconds: 300));

    final lineSwitcher = tester.widget<SegmentedButton<ChartDisplayMode>>(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
    );
    lineSwitcher.onSelectionChanged?.call({ChartDisplayMode.split});
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.tap(find.text('Area Charts'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.tap(find.text('Pie Charts'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SegmentedButton<ChartDisplayMode>>(
            find.byKey(const ValueKey('chart-workbench-mode-switcher')),
          )
          .selected,
      {ChartDisplayMode.split},
    );

    await tester.ensureVisible(find.text('Chart Workbench'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chart Workbench'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Show view selector'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );

    await tester.ensureVisible(find.text('Line Charts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Line Charts'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a line chart example'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chart-workbench-mode-switcher')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
