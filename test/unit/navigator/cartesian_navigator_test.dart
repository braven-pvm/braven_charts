import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fullDomain = ChartXViewport(min: 0, max: 100);

  LineChartSeries overview({String id = 'overview'}) => LineChartSeries(
    id: id,
    name: 'Overview',
    points: const <ChartDataPoint>[
      ChartDataPoint(x: 0, y: 4),
      ChartDataPoint(x: 25, y: 9),
      ChartDataPoint(x: 50, y: 6),
      ChartDataPoint(x: 75, y: 12),
      ChartDataPoint(x: 100, y: 8),
    ],
  );

  Widget host({
    required ChartInteractionGroupController controller,
    ChartSeries? series,
    ChartXViewport domain = fullDomain,
    ChartXViewport? initialViewport = const ChartXViewport(min: 20, max: 40),
    CartesianNavigatorBehavior behavior = const CartesianNavigatorBehavior(),
    CartesianNavigatorSnapPolicy snapPolicy =
        const CartesianNavigatorSnapPolicy.none(),
    bool enabled = true,
    ValueChanged<ChartXViewport>? onPreview,
    ValueChanged<ChartXViewport>? onChanged,
  }) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: CartesianNavigator(
            interactionGroupController: controller,
            overviewSeries: series ?? overview(),
            fullDomain: domain,
            initialViewport: initialViewport,
            behavior: behavior,
            snapPolicy: snapPolicy,
            enabled: enabled,
            onViewportPreview: onPreview,
            onViewportChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  testWidgets('publishes initialization precedence through the group', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    controller.setViewport(const ChartXViewport(min: 60, max: 80));

    await tester.pumpWidget(host(controller: controller));

    expect(controller.viewport, const ChartXViewport(min: 60, max: 80));
    final chart = tester.widget<BravenChartPlus>(
      find.byKey(const ValueKey('cartesian-navigator-overview')),
    );
    expect(chart.xAxisConfig!.min, 0);
    expect(chart.xAxisConfig!.max, 100);
    expect(chart.interactionGroupOptions.synchronizeCursor, isFalse);
    expect(chart.interactionGroupOptions.synchronizeViewport, isFalse);

    controller.dispose();
  });

  testWidgets('rebuilds preserve the current selected viewport', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(host(controller: controller));
    controller.setViewport(const ChartXViewport(min: 50, max: 70));
    await tester.pump();

    await tester.pumpWidget(
      host(
        controller: controller,
        initialViewport: const ChartXViewport(min: 5, max: 15),
        series: overview(id: 'replacement'),
      ),
    );

    expect(controller.viewport, const ChartXViewport(min: 50, max: 70));
    controller.dispose();
  });

  testWidgets(
    'dynamic domain keeps an ahead-of-snapshot external viewport authoritative',
    (tester) async {
      final controller = ChartInteractionGroupController();
      await tester.pumpWidget(
        host(
          controller: controller,
          behavior: const CartesianNavigatorBehavior(
            allowExternalDomainGrowth: true,
          ),
        ),
      );

      const liveViewport = ChartXViewport(min: 90, max: 110);
      controller.setViewport(liveViewport);
      await tester.pump();

      expect(
        controller.viewport,
        liveViewport,
        reason: 'A stale overview must not clamp the live chart backward.',
      );

      await tester.pumpWidget(
        host(
          controller: controller,
          domain: const ChartXViewport(min: 0, max: 120),
          behavior: const CartesianNavigatorBehavior(
            allowExternalDomainGrowth: true,
          ),
        ),
      );
      await tester.pump();

      expect(controller.viewport, liveViewport);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('cartesian-navigator-window')),
            )
            .value,
        contains('90'),
      );
      controller.dispose();
    },
  );

  testWidgets('body pan previews live and preserves the selected span', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    final previews = <ChartXViewport>[];
    final commits = <ChartXViewport>[];
    await tester.pumpWidget(
      host(
        controller: controller,
        onPreview: previews.add,
        onChanged: commits.add,
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('cartesian-navigator-window')),
      const Offset(38, 0),
    );
    await tester.pump();

    expect(controller.viewport!.min, closeTo(30, .01));
    expect(controller.viewport!.max, closeTo(50, .01));
    expect(previews, isNotEmpty);
    expect(commits, hasLength(1));
    expect(controller.cursorX, isNull);
    controller.dispose();
  });

  testWidgets('edge drag resizes only the active edge', (tester) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(host(controller: controller));

    await tester.drag(
      find.byKey(const ValueKey('cartesian-navigator-end-handle')),
      const Offset(38, 0),
    );
    await tester.pump();

    expect(controller.viewport!.min, closeTo(20, .01));
    expect(controller.viewport!.max, closeTo(50, .01));
    controller.dispose();
  });

  testWidgets('non-live interactions publish only when committed', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(
      host(
        controller: controller,
        behavior: const CartesianNavigatorBehavior(livePreview: false),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('cartesian-navigator-window')),
      ),
    );
    await gesture.moveBy(const Offset(19, 0));
    await gesture.moveBy(const Offset(19, 0));
    await tester.pump();

    expect(controller.viewport, const ChartXViewport(min: 20, max: 40));

    await gesture.up();
    await tester.pump();
    expect(controller.viewport!.min, closeTo(30, .01));
    expect(controller.viewport!.max, closeTo(50, .01));
    controller.dispose();
  });

  testWidgets('external writes during a gesture win after local commit', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(host(controller: controller));
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('cartesian-navigator-window')),
      ),
    );
    await gesture.moveBy(const Offset(19, 0));
    await tester.pump();

    controller.setViewport(const ChartXViewport(min: 60, max: 80));
    await gesture.moveBy(const Offset(19, 0));
    await gesture.up();
    await tester.pump();

    expect(controller.viewport, const ChartXViewport(min: 60, max: 80));
    controller.dispose();
  });

  testWidgets('pointer cancellation restores the gesture start viewport', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(host(controller: controller));
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('cartesian-navigator-window')),
      ),
    );
    await gesture.moveBy(const Offset(38, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(controller.viewport, const ChartXViewport(min: 20, max: 40));
    controller.dispose();
  });

  testWidgets('keyboard and semantics expose three ordered range targets', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(
      host(
        controller: controller,
        snapPolicy: CartesianNavigatorSnapPolicy.interval(5),
      ),
    );
    final semantics = tester.ensureSemantics();

    await tester.tap(find.byKey(const ValueKey('cartesian-navigator-window')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.viewport, const ChartXViewport(min: 25, max: 45));
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('cartesian-navigator-start-handle')),
          )
          .label,
      contains('Range start'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('cartesian-navigator-window')),
          )
          .label,
      contains('Selected range'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('cartesian-navigator-end-handle')),
          )
          .label,
      contains('Range end'),
    );

    semantics.dispose();
    controller.dispose();
  });

  testWidgets('disabled navigators ignore pointer and keyboard movement', (
    tester,
  ) async {
    final controller = ChartInteractionGroupController();
    await tester.pumpWidget(host(controller: controller, enabled: false));

    await tester.drag(
      find.byKey(const ValueKey('cartesian-navigator-window')),
      const Offset(38, 0),
    );
    await tester.pump();

    expect(controller.viewport, const ChartXViewport(min: 20, max: 40));
    controller.dispose();
  });

  testWidgets('rejects non-Line and non-Area overview series', (tester) async {
    final controller = ChartInteractionGroupController();
    const invalid = BarChartSeries(
      id: 'bar-overview',
      barWidthPercent: .7,
      points: <ChartDataPoint>[
        ChartDataPoint(x: 0, y: 1),
        ChartDataPoint(x: 1, y: 2),
      ],
    );

    await tester.pumpWidget(host(controller: controller, series: invalid));
    expect(tester.takeException(), isArgumentError);
    controller.dispose();
  });
}
