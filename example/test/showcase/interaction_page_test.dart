import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/interaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('interaction ribbon selects the configurable main pattern', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InteractionPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose an interaction pattern'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('interaction-mode-ribbon')),
      findsOneWidget,
    );
    for (final mode in [
      'explore',
      'track',
      'normalize',
      'curves',
      'stress',
      'navigator',
    ]) {
      expect(find.byKey(ValueKey('interaction-preview-$mode')), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('selected-interaction-explore')),
      findsOneWidget,
    );
    expect(find.text('Explore and select'), findsOneWidget);
    expect(find.text('Enable Crosshair'), findsOneWidget);
    expect(find.text('Enable Tooltips'), findsOneWidget);
    expect(find.byType(BravenChartPlus), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('interaction-preview-track')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-interaction-track')),
      findsOneWidget,
    );
    expect(find.text('Multi-series tracking boundaries'), findsOneWidget);
    expect(find.text('Tracking Overlay'), findsOneWidget);
    expect(find.text('Show Tracking Tooltip'), findsOneWidget);
    expect(find.text('Show Intersection Markers'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('interaction-preview-normalize')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-interaction-normalize')),
      findsOneWidget,
    );
    expect(find.text('Tracking with automatic normalization'), findsOneWidget);
    expect(find.text('Use Constrained Split Pane'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('interaction-preview-curves')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-interaction-curves')),
      findsOneWidget,
    );
    expect(find.text('Interpolation-aware tracking'), findsOneWidget);
    expect(find.text('Curve Study'), findsOneWidget);
    expect(find.text('Comparison'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('interaction-preview-stress')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('selected-interaction-stress')),
      findsOneWidget,
    );
    expect(find.text('Sharp-reversal tracking'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('interaction-preview-navigator')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-interaction-navigator')),
      findsOneWidget,
    );
    expect(find.text('Navigator and viewport controller'), findsOneWidget);
    expect(find.text('Navigator Data'), findsOneWidget);
    expect(find.text('Viewport Controller'), findsOneWidget);
  });

  testWidgets(
    'navigator pattern links controllable points, gestures, and controller commands',
    (tester) async {
      final pixelRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InteractionPage())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const ValueKey('interaction-preview-navigator')),
      );
      await tester.pumpAndSettle();

      final chartFinder = find.byKey(
        const ValueKey('interaction-navigator-chart'),
      );
      final navigatorFinder = find.byKey(
        const ValueKey('interaction-cartesian-navigator'),
      );
      var chart = tester.widget<BravenChartPlus>(chartFinder);
      var navigator = tester.widget<CartesianNavigator>(navigatorFinder);
      expect(chart.series.single.points, hasLength(160));
      expect(navigator.fullDomain, const ChartXViewport(min: 0, max: 159));
      expect(
        identical(
          chart.interactionGroupController,
          navigator.interactionGroupController,
        ),
        isTrue,
      );

      final viewportBeforeDrag = navigator.interactionGroupController.viewport;
      await tester.drag(
        find.byKey(const ValueKey('cartesian-navigator-window')),
        const Offset(48, 0),
      );
      await tester.pump();
      expect(
        navigator.interactionGroupController.viewport,
        isNot(viewportBeforeDrag),
      );

      final pointCountSlider = tester
          .widgetList<Slider>(find.byType(Slider))
          .singleWhere((slider) => slider.min == 24 && slider.max == 400);
      pointCountSlider.onChanged?.call(240);
      await tester.pumpAndSettle();

      chart = tester.widget<BravenChartPlus>(chartFinder);
      navigator = tester.widget<CartesianNavigator>(navigatorFinder);
      expect(chart.series.single.points, hasLength(240));
      expect(navigator.fullDomain, const ChartXViewport(min: 0, max: 239));

      await tester.tap(find.text('Show latest'));
      await tester.pump();
      expect(
        navigator.interactionGroupController.viewport,
        const ChartXViewport(min: 167, max: 239),
      );

      await tester.tap(find.text('Show all'));
      await tester.pump();
      expect(
        navigator.interactionGroupController.viewport,
        const ChartXViewport(min: 0, max: 239),
      );
      expect(find.text('Visible samples 0–239 of 239'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('interaction-defining controls precede generic chart options', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InteractionPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final interactionTop = tester.getTopLeft(find.text('Interaction Mode')).dy;
    final chartOptionsTop = tester.getTopLeft(find.text('Chart Options')).dy;

    expect(interactionTop, lessThan(chartOptionsTop));
    expect(find.text('Pattern'), findsOneWidget);
  });

  testWidgets('navigator pattern remains usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InteractionPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(
      find.byKey(const ValueKey('interaction-mode-ribbon')),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    final navigatorPreview = find.byKey(
      const ValueKey('interaction-preview-navigator'),
    );
    await tester.tap(navigatorPreview);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('interaction-navigator-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('interaction-cartesian-navigator')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
