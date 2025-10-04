import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Web testing utilities for braven_charts
class WebTestUtils {
  /// Common web viewport sizes for testing
  static const Map<String, Size> webViewports = {
    'mobile': Size(375, 667),
    'mobileLandscape': Size(667, 375),
    'tablet': Size(768, 1024),
    'tabletLandscape': Size(1024, 768),
    'desktop': Size(1366, 768),
    'desktopHD': Size(1920, 1080),
    'desktopQHD': Size(2560, 1440),
    'ultrawide': Size(3440, 1440),
  };

  /// Creates a test app widget for web testing
  static Widget createWebTestApp({
    required Widget child,
    String title = 'Braven Charts Web Test',
  }) {
    return MaterialApp(
      title: title,
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  /// Creates a chart container widget with standard test setup
  static Widget createChartContainer({
    required Widget chart,
    Size? size,
    Key? key,
  }) {
    return SizedBox(
      key: key ?? const Key('chart_container'),
      width: size?.width ?? 800,
      height: size?.height ?? 600,
      child: chart,
    );
  }

  /// Simulates mouse hover at a specific position
  static Future<void> hoverAt(
    WidgetTester tester,
    Offset position,
  ) async {
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(position);
    await tester.pumpAndSettle();
  }

  /// Simulates mouse click at a specific position
  static Future<void> clickAt(
    WidgetTester tester,
    Offset position,
  ) async {
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(position);
    await gesture.down(position);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Waits for a loading state to complete
  static Future<void> waitForLoadingComplete(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));

      if (tester.widgetList(find.byType(CircularProgressIndicator)).isEmpty) {
        return;
      }
    }

    throw TimeoutException('Loading did not complete within $timeout');
  }
}

/// Web performance metrics for testing
class WebPerformanceMetrics {
  final Duration renderTime;
  final Duration interactionTime;
  final int frameCount;

  const WebPerformanceMetrics({
    required this.renderTime,
    required this.interactionTime,
    required this.frameCount,
  });

  /// Checks if render performance meets threshold (50ms for web)
  bool meetsRenderThreshold() => renderTime.inMilliseconds <= 50;

  /// Checks if interaction is responsive (16ms for 60fps)
  bool meetsInteractionThreshold() => interactionTime.inMilliseconds <= 16;

  @override
  String toString() {
    return 'WebPerformanceMetrics(render: ${renderTime.inMilliseconds}ms, '
        'interaction: ${interactionTime.inMilliseconds}ms, frames: $frameCount)';
  }
}
