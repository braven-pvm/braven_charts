import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:braven_charts_example/showcase/pages/financial_viewport_lab_page.dart';
import 'package:braven_charts_example/showcase/showcase_app.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile horizontal pan does not snap the fitted Y viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FinancialViewportLabPage())),
    );
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('financial-viewport-price'));
    await tester.ensureVisible(price);
    await tester.pumpAndSettle();
    ChartRenderBox box() =>
        find
                .byWidgetPredicate(
                  (widget) =>
                      widget.runtimeType.toString() == '_ChartRenderWidget',
                )
                .evaluate()
                .first
                .renderObject!
            as ChartRenderBox;
    final gesture = await tester.startGesture(
      tester.getTopLeft(price) + const Offset(60, 150),
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    for (var step = 0; step < 80; step++) {
      await gesture.moveBy(const Offset(1.5, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final config = tester.widget<BravenChartPlus>(price).yAxis!;
      expect(box().transform!.dataXRange, closeTo(100, 1e-7));
      expect(
        box().transform!.dataYMin,
        closeTo(config.min!, 1e-7),
        reason: 'A horizontal delta must not move Y at step $step',
      );
      expect(box().transform!.dataYMax, closeTo(config.max!, 1e-7));
    }
    expect(box().transform!.dataXMin, lessThan(280));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mobile diagonal pan never amplifies either finger delta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FinancialViewportLabPage())),
    );
    await tester.pumpAndSettle();
    for (var pane = 0; pane < 2; pane++) {
      final chart = find.byType(BravenChartPlus).at(pane);
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      ChartRenderBox box(int index) =>
          find
                  .byWidgetPredicate(
                    (widget) =>
                        widget.runtimeType.toString() == '_ChartRenderWidget',
                  )
                  .evaluate()
                  .elementAt(index)
                  .renderObject!
              as ChartRenderBox;
      final gesture = await tester.startGesture(
        tester.getTopLeft(chart) + const Offset(60, 90),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      final initialX = box(pane).transform!.dataXMin;
      for (var step = 0; step < 80; step++) {
        final previous = box(pane).transform!;
        await gesture.moveBy(Offset(1.5, step.isEven ? 1.5 : -1.5));
        // Inspect the gesture update before the host applies its next Y fit.
        final moved = box(pane).transform!;
        expect(
          (moved.dataXMin - previous.dataXMin).abs(),
          lessThanOrEqualTo(1.5 * previous.dataPerPixelX + 1e-7),
        );
        expect(
          (moved.dataYMin - previous.dataYMin).abs(),
          lessThanOrEqualTo(1.5 * previous.dataPerPixelY + 1e-7),
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(box(pane).transform!.dataXRange, closeTo(100, 1e-7));
        expect(
          box(1 - pane).transform!.dataXMin,
          closeTo(box(pane).transform!.dataXMin, 1e-7),
        );
      }
      expect(box(pane).transform!.dataXMin, lessThan(initialX - 20));
      await gesture.up();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'financial viewport lab retains the window through refresh at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FinancialViewportLabPage())),
        );
        await tester.pumpAndSettle();

        ChartRenderBox priceBox() =>
            find
                    .byWidgetPredicate(
                      (widget) =>
                          widget.runtimeType.toString() == '_ChartRenderWidget',
                    )
                    .evaluate()
                    .first
                    .renderObject!
                as ChartRenderBox;

        expect(priceBox().transform!.dataXMin, closeTo(304, 1e-7));
        expect(priceBox().transform!.dataXMax, closeTo(404, 1e-7));
        await tester.tap(find.text('First 100 bars'));
        await tester.pumpAndSettle();
        expect(priceBox().transform!.dataXMin, closeTo(-0.5, 1e-7));
        expect(priceBox().transform!.dataXMax, closeTo(99.5, 1e-7));
        expect(priceBox().transform!.dataYMax, lessThan(170));
        await tester.tap(find.text('Refresh candles'));
        await tester.pumpAndSettle();
        expect(priceBox().transform!.dataXMin, closeTo(-0.5, 1e-7));
        expect(priceBox().transform!.dataXMax, closeTo(99.5, 1e-7));
        expect(find.byType(BravenChartPlus), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('explicit financial lab route is reachable on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ShowcaseHome(requestedPageOverride: 'financial-viewport-lab'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FinancialViewportLabPage), findsOneWidget);
    expect(find.text('Last 100 bars'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
