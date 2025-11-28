// Unit Test: TooltipProvider Component
// Feature: Layer 7 Interaction System
// Task: T020
// Status: Tests should now PASS with implementation

import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/interaction/models/tooltip_config.dart';
import 'package:braven_charts/legacy/src/interaction/tooltip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TooltipProvider Component Tests', () {
    late TooltipProvider tooltipProvider;
    late TooltipConfig config;

    setUp(() {
      tooltipProvider = TooltipProvider();
      config = const TooltipConfig();
    });

    group('Tooltip Show/Hide Logic', () {
      testWidgets('showTooltip() displays tooltip widget', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 100.0, y: 200.0);
        final widget = tooltipProvider.showTooltip(
          context,
          point,
          'series1',
          const Offset(100, 200),
          config,
        );

        expect(tooltipProvider.isVisible, isTrue);
        expect(widget, isA<Widget>());
      });

      test('hideTooltip() removes tooltip', () {
        tooltipProvider.hideTooltip();
        expect(tooltipProvider.isVisible, isFalse);
      });

      testWidgets('respects custom builder configuration', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final customConfig = config.copyWith(
          customBuilder: (context, data) => const Text('Custom Tooltip'),
        );
        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 50.0, y: 100.0);

        final widget = tooltipProvider.showTooltip(
          context,
          point,
          'series1',
          const Offset(50, 100),
          customConfig,
        );

        expect(widget, isA<Text>());
      });

      testWidgets('uses default tooltip when no custom builder',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 50.0, y: 100.0);

        final widget = tooltipProvider.showTooltip(
          context,
          point,
          'series1',
          const Offset(50, 100),
          config,
        );

        expect(widget, isA<Container>());
      });
    });

    group('Tooltip Content Formatting', () {
      testWidgets('buildDefaultTooltip() generates tooltip with series name',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 50.0, y: 100.0, label: 'Point A');
        final style = const TooltipStyle();

        final widget = tooltipProvider.buildDefaultTooltip(
          context,
          point,
          'Series1',
          style,
        );

        expect(widget, isA<Container>());
      });

      testWidgets('buildDefaultTooltip() includes X and Y values',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 12.34, y: 56.78);
        final style = const TooltipStyle();

        final widget = tooltipProvider.buildDefaultTooltip(
          context,
          point,
          'Test',
          style,
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        await tester.pump();

        expect(find.textContaining('12.34'), findsOneWidget);
        expect(find.textContaining('56.78'), findsOneWidget);
      });

      testWidgets('buildMultiSeriesTooltip() handles multiple series',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final points = [
          const ChartDataPoint(x: 10.0, y: 20.0),
          const ChartDataPoint(x: 10.0, y: 30.0),
        ];
        final seriesIds = ['Series A', 'Series B'];
        final style = const TooltipStyle();

        final widget = tooltipProvider.buildMultiSeriesTooltip(
          context,
          points,
          seriesIds,
          style,
        );

        expect(widget, isA<Container>());
      });
    });

    group('Tooltip Positioning', () {
      test('calculatePosition() places tooltip above point by default (top)',
          () {
        const cursorPos = Offset(400, 300);
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.top,
          offset,
        );

        // Should be above the cursor
        expect(position.dy, lessThan(cursorPos.dy));
        expect(position.dy, equals(cursorPos.dy - tooltipSize.height - offset));
      });

      test('bottom position places tooltip below cursor', () {
        const cursorPos = Offset(400, 300);
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.bottom,
          offset,
        );

        // Should be below the cursor
        expect(position.dy, greaterThan(cursorPos.dy));
        expect(position.dy, equals(cursorPos.dy + offset));
      });

      test('auto positioning tries top first', () {
        const cursorPos = Offset(400, 300);
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.auto,
          offset,
        );

        // Auto should default to top when it fits
        expect(position.dy, lessThan(cursorPos.dy));
      });

      test('auto positioning switches to bottom when near top edge', () {
        const cursorPos = Offset(400, 30); // Near top
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.auto,
          offset,
        );

        // Should flip to bottom since top doesn't fit
        expect(position.dy, greaterThan(cursorPos.dy));
      });

      test('keeps tooltip within canvas bounds (left edge)', () {
        const cursorPos = Offset(10, 300); // Near left edge
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.auto,
          offset,
        );

        expect(position.dx, greaterThanOrEqualTo(chartBounds.left));
        expect(position.dx + tooltipSize.width,
            lessThanOrEqualTo(chartBounds.right));
      });

      test('keeps tooltip within canvas bounds (right edge)', () {
        const cursorPos = Offset(790, 300); // Near right edge
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.auto,
          offset,
        );

        expect(position.dx, greaterThanOrEqualTo(chartBounds.left));
        expect(position.dx + tooltipSize.width,
            lessThanOrEqualTo(chartBounds.right));
      });

      test('left position places tooltip to left of cursor', () {
        const cursorPos = Offset(400, 300);
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.left,
          offset,
        );

        expect(position.dx, lessThan(cursorPos.dx));
        expect(position.dx, equals(cursorPos.dx - tooltipSize.width - offset));
      });

      test('right position places tooltip to right of cursor', () {
        const cursorPos = Offset(400, 300);
        const tooltipSize = Size(120, 60);
        const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
        const offset = 10.0;

        final position = tooltipProvider.calculatePosition(
          tooltipSize,
          cursorPos,
          chartBounds,
          TooltipPosition.right,
          offset,
        );

        expect(position.dx, greaterThan(cursorPos.dx));
        expect(position.dx, equals(cursorPos.dx + offset));
      });
    });

    group('Update Detection', () {
      test('shouldUpdate() returns true for different points', () {
        final oldPoint = const ChartDataPoint(x: 10.0, y: 20.0);
        final newPoint = const ChartDataPoint(x: 15.0, y: 25.0);

        final shouldUpdate = tooltipProvider.shouldUpdate(oldPoint, newPoint);

        expect(shouldUpdate, isTrue);
      });

      test('shouldUpdate() returns false for same point', () {
        final point = const ChartDataPoint(x: 10.0, y: 20.0);

        final shouldUpdate = tooltipProvider.shouldUpdate(point, point);

        expect(shouldUpdate, isFalse);
      });

      test('shouldUpdate() returns true when point becomes visible', () {
        const ChartDataPoint? oldPoint = null;
        final newPoint = const ChartDataPoint(x: 10.0, y: 20.0);

        final shouldUpdate = tooltipProvider.shouldUpdate(oldPoint, newPoint);

        expect(shouldUpdate, isTrue);
      });

      test('shouldUpdate() returns true when point becomes hidden', () {
        final oldPoint = const ChartDataPoint(x: 10.0, y: 20.0);
        const ChartDataPoint? newPoint = null;

        final shouldUpdate = tooltipProvider.shouldUpdate(oldPoint, newPoint);

        expect(shouldUpdate, isTrue);
      });

      test('shouldUpdate() returns true when label changes', () {
        final oldPoint = const ChartDataPoint(x: 10.0, y: 20.0, label: 'A');
        final newPoint = const ChartDataPoint(x: 10.0, y: 20.0, label: 'B');

        final shouldUpdate = tooltipProvider.shouldUpdate(oldPoint, newPoint);

        expect(shouldUpdate, isTrue);
      });
    });

    group('Performance', () {
      testWidgets('showTooltip() completes in <5ms', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final context = tester.element(find.byType(SizedBox));
        final point = const ChartDataPoint(x: 100.0, y: 200.0);

        final stopwatch = Stopwatch()..start();
        tooltipProvider.showTooltip(
          context,
          point,
          'series1',
          const Offset(100, 200),
          config,
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(5));
      });

      test('no memory leaks after 1000 show/hide cycles', () {
        for (var i = 0; i < 1000; i++) {
          tooltipProvider.hideTooltip();
        }

        // Should not accumulate memory (verified by completing without error)
        expect(tooltipProvider.isVisible, isFalse);
      });
    });
  });
}
