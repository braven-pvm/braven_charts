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
    expect(find.text('Choose a streaming strategy'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('streaming-scenario-ribbon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('streaming-strategy-guide')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('live-stream-telemetry')), findsOneWidget);
    expect(find.text('Follow latest'), findsWidgets);
    expect(find.text('Paused buffer'), findsOneWidget);
    expect(find.text('Expand then slide'), findsOneWidget);
    expect(find.text('High frequency'), findsOneWidget);

    final chart = _mainChart(tester);
    expect(chart.liveStreamController, isNotNull);
    expect(chart.liveStreamController!.autoScroll, isTrue);
    expect(chart.liveStreamController!.viewportDataPoints, 100);
    expect(chart.liveStreamController!.isStreaming, isTrue);

    expect(find.text('Streaming Strategy'), findsOneWidget);
    expect(find.text('Data Flow'), findsOneWidget);
    expect(find.text('Viewport Mode'), findsOneWidget);
    expect(find.text('Buffer Settings'), findsOneWidget);

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
    expect(controller.isStreaming, isFalse);
    expect(controller.pauseBufferSize, 5000);
    expect(find.textContaining('resume() flushes'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-expandThenSlide')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    controller = _mainChart(tester).liveStreamController!;
    expect(controller.autoScroll, isFalse);
    expect(controller.maxVisiblePoints, 500);
    expect(find.text('Max Visible Points'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('streaming-scenario-highFrequency')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    controller = _mainChart(tester).liveStreamController!;
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
}

BravenChartPlus _mainChart(WidgetTester tester) {
  return tester.widget<BravenChartPlus>(
    find.byKey(const ValueKey('live-stream-main-chart')),
  );
}
