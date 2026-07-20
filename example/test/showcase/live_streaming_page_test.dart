import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/live_streaming_page.dart';
import 'package:braven_charts_example/showcase/widgets/options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('live stream compares strategies around one controller stage', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LiveStreamingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Live Stream'), findsOneWidget);
    expect(find.text('Choose a streaming strategy'), findsNothing);
    expect(
      find.byKey(const ValueKey('streaming-scenario-ribbon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('streaming-strategy-guide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('live-stream-telemetry')), findsOneWidget);
    expect(
      tester
          .getBottomRight(find.byKey(const ValueKey('live-stream-main-chart')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('streaming-strategy-guide')))
            .dy,
      ),
    );
    expect(find.text('Follow latest'), findsWidgets);
    expect(find.text('Paused buffer'), findsOneWidget);
    expect(find.text('Expand then slide'), findsOneWidget);
    expect(find.text('High frequency'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('streaming-scenario-ribbon')),
      const Offset(-500, 0),
    );
    await tester.pump();
    expect(find.text('Live navigator'), findsOneWidget);

    final chart = _mainChart(tester);
    expect(chart.liveStreamController, isNotNull);
    expect(chart.liveStreamController!.autoScroll, isTrue);
    expect(chart.liveStreamController!.viewportDataPoints, 100);
    expect(chart.liveStreamController!.isStreaming, isTrue);

    expect(find.text('Streaming Strategy'), findsOneWidget);
    expect(find.text('Data Flow'), findsOneWidget);
    expect(find.text('Viewport Mode'), findsOneWidget);
    expect(find.text('Buffer Settings'), findsOneWidget);
    expect(find.text('Live diagnostics'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('live-performance-followLatest')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('live-presented-fps')), findsOneWidget);
    expect(find.byKey(const ValueKey('live-frame-gap-p95')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('streaming presets configure pause, expand, and rate behavior', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LiveStreamingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-pausedBuffer')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    var controller = _mainChart(tester).liveStreamController!;
    expect(
      find.byKey(const ValueKey('live-performance-pausedBuffer')),
      findsOneWidget,
    );
    expect(controller.isStreaming, isFalse);
    expect(controller.pauseBufferSize, 5000);
    expect(find.textContaining('resume() flushes'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-expandThenSlide')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    controller = _mainChart(tester).liveStreamController!;
    expect(
      find.byKey(const ValueKey('live-performance-expandThenSlide')),
      findsOneWidget,
    );
    expect(controller.autoScroll, isFalse);
    expect(controller.maxVisiblePoints, 500);
    expect(find.text('Max Visible Points'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-highFrequency')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    controller = _mainChart(tester).liveStreamController!;
    expect(
      find.byKey(const ValueKey('live-performance-highFrequency')),
      findsOneWidget,
    );
    expect(controller.autoScroll, isTrue);
    expect(controller.maxPoints, 2000);
    expect(controller.viewportDataPoints, 250);
    expect(find.textContaining('120 Hz'), findsWidgets);

    final options = find.descendant(
      of: find.byType(OptionsPanel),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Data Generation'),
      300,
      scrollable: options,
    );
    expect(find.text('Data Generation'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'live navigator keeps ingest active while inspecting history and can return live',
    (tester) async {
      final pixelRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(1440 * pixelRatio, 1000 * pixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LiveStreamingPage())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final scenario = find.byKey(
        const ValueKey('streaming-scenario-navigator'),
      );
      await tester.drag(
        find.byKey(const ValueKey('streaming-scenario-ribbon')),
        const Offset(-500, 0),
      );
      await tester.pump();
      await tester.tap(scenario);
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byKey(const ValueKey('live-stream-cartesian-navigator')),
        findsOneWidget,
      );
      expect(find.text('Following live viewport'), findsOneWidget);
      expect(find.text('Navigator Viewport'), findsOneWidget);
      expect(find.text('Live diagnostics'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('live-performance-navigator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-navigator-frame-p95')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-navigator-snapshot-p95')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-navigator-update-hz')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-navigator-gap-p95')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('live-navigator-domain-lag')),
        findsOneWidget,
      );
      expect(_intOption(tester, 'Retained History').value, 1200);
      expect(_intOption(tester, 'Detail Window').value, 300);
      expect(find.text('Window Size'), findsNothing);

      var chart = _mainChart(tester);
      final stream = chart.liveStreamController!;
      final group = chart.interactionGroupController!;
      expect(stream.manageViewport, isFalse);
      expect(stream.isStreaming, isTrue);
      expect(group.viewport, isNotNull);

      // Live detail following and its bounded navigator snapshot are both
      // frame-coalesced. Neither may fall back to a low-frequency timer.
      final liveLatestBefore = stream.latestPoint!.x;
      final navigatorDomainBefore = tester
          .widget<CartesianNavigator>(
            find.byKey(const ValueKey('live-stream-cartesian-navigator')),
          )
          .fullDomain;
      stream.addPoint(ChartDataPoint(x: liveLatestBefore + 1, y: 52));
      await tester.pump();
      expect(group.viewport!.max, closeTo(liveLatestBefore + 1, 0.001));
      expect(
        tester
            .widget<CartesianNavigator>(
              find.byKey(const ValueKey('live-stream-cartesian-navigator')),
            )
            .fullDomain
            .max,
        greaterThan(navigatorDomainBefore.max),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('Following live viewport'),
        findsOneWidget,
        reason: 'Programmatic live following must not enter history mode.',
      );

      expect(stream.points.length, greaterThan(40));
      _intOption(tester, 'Detail Window').onChanged(40);
      await tester.pump(const Duration(milliseconds: 250));
      expect(group.viewport!.max - group.viewport!.min, closeTo(39, 0.001));
      final liveViewport = group.viewport!;

      await tester.drag(
        find.byKey(const ValueKey('cartesian-navigator-window')),
        const Offset(-100, 0),
      );
      await tester.pump();

      expect(find.text('Inspecting history'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('live-navigator-return-to-live')),
        findsOneWidget,
      );
      expect(_intOption(tester, 'Detail Window').value, 40);
      expect(
        group.viewport!.max,
        lessThan(liveViewport.max),
        reason: 'Dragging the navigator left must move detail history left.',
      );
      final resizedHistoricalViewport = group.viewport;

      final mountedMainChartBeforeRefresh = _mainChart(tester);
      final navigatorBeforeRefresh = tester.widget<CartesianNavigator>(
        find.byKey(const ValueKey('live-stream-cartesian-navigator')),
      );
      final latestBefore = stream.latestPoint!.x;
      stream.addPoint(ChartDataPoint(x: latestBefore + 100, y: 52));
      await tester.pump(const Duration(milliseconds: 250));

      expect(group.viewport, resizedHistoricalViewport);
      final navigator = tester.widget<CartesianNavigator>(
        find.byKey(const ValueKey('live-stream-cartesian-navigator')),
      );
      expect(
        identical(mountedMainChartBeforeRefresh, _mainChart(tester)),
        isTrue,
        reason: 'Navigator refreshes must not rebuild the main live chart.',
      );
      expect(
        identical(navigatorBeforeRefresh, navigator),
        isFalse,
        reason: 'The navigator subtree should receive the new overview data.',
      );
      expect(navigator.fullDomain.max, greaterThan(latestBefore));

      await tester.tap(
        find.byKey(const ValueKey('reset-live-navigator-performance')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('live-navigator-return-to-live')),
      );
      await tester.pump(const Duration(milliseconds: 250));

      chart = _mainChart(tester);
      expect(find.text('Following live viewport'), findsOneWidget);
      expect(
        chart.interactionGroupController!.viewport!.max,
        closeTo(chart.liveStreamController!.latestPoint!.x, 0.001),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('live navigator remains usable in a compact showcase viewport', (
    tester,
  ) async {
    final pixelRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = Size(900 * pixelRatio, 760 * pixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LiveStreamingPage())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(
      find.byKey(const ValueKey('streaming-scenario-ribbon')),
      const Offset(-700, 0),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-navigator')),
    );
    await tester.pump(const Duration(milliseconds: 350));

    final followLatest = tester.widget<BoolOption>(
      find.byWidgetPredicate(
        (widget) => widget is BoolOption && widget.label == 'Follow Latest',
      ),
    );
    followLatest.onChanged(false);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('live-stream-cartesian-navigator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('live-navigator-return-to-live')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

BravenChartPlus _mainChart(WidgetTester tester) {
  return tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('live-stream-main-chart')),
  );
}

IntSliderOption _intOption(WidgetTester tester, String label) {
  return tester.widget<IntSliderOption>(
    find.byWidgetPredicate(
      (widget) => widget is IntSliderOption && widget.label == label,
    ),
  );
}
