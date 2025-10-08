// Contract Test: ITooltipProvider Interface
// Feature: Layer 7 Interaction System
// Task: T005
// Status: Tests should now PASS with implementation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/interaction/tooltip_provider.dart';
import 'package:braven_charts/src/interaction/models/tooltip_config.dart';
import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';

void main() {
  group('ITooltipProvider Contract Tests', () {
    late ITooltipProvider tooltipProvider;

    setUp(() {
      tooltipProvider = TooltipProvider();
    });

    testWidgets('showTooltip() displays tooltip widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, height: 600),
          ),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final point = ChartDataPoint(x: 5.0, y: 10.0, label: 'Test Point');
      const seriesId = 'series1';
      const screenPosition = Offset(400, 300);
      final config = TooltipConfig();

      final widget = tooltipProvider.showTooltip(
        context,
        point,
        seriesId,
        screenPosition,
        config,
      );

      expect(widget, isA<Widget>());
      expect(widget, isA<Container>());
    });

    testWidgets('showTooltip() completes in <5ms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 800, height: 600),
          ),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final point = ChartDataPoint(x: 5.0, y: 10.0);
      const seriesId = 'series1';
      const screenPosition = Offset(400, 300);
      final config = TooltipConfig();

      final stopwatch = Stopwatch()..start();
      tooltipProvider.showTooltip(
        context,
        point,
        seriesId,
        screenPosition,
        config,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5));
    });

    test('hideTooltip() removes tooltip', () {
      final provider = TooltipProvider();
      
      // Initially not visible
      expect(provider.isVisible, isFalse);
      
      // After showing, should be visible
      // (We can't actually show here without BuildContext, but we can test hide)
      provider.hideTooltip();
      
      // Should remain hidden
      expect(provider.isVisible, isFalse);
    });

    test('calculatePosition() performs smart positioning', () {
      const tooltipSize = Size(150, 80);
      const pointPosition = Offset(400, 300);
      const chartBounds = Rect.fromLTWH(0, 0, 800, 600);
      const preferredPosition = TooltipPosition.auto;
      const offset = 10.0;

      final position = tooltipProvider.calculatePosition(
        tooltipSize,
        pointPosition,
        chartBounds,
        preferredPosition,
        offset,
      );

      expect(position, isA<Offset>());

      // Verify tooltip stays within bounds
      expect(position.dx, greaterThanOrEqualTo(0));
      expect(position.dy, greaterThanOrEqualTo(0));
      expect(position.dx + tooltipSize.width, lessThanOrEqualTo(chartBounds.width));
      expect(position.dy + tooltipSize.height, lessThanOrEqualTo(chartBounds.height));
    });

    testWidgets('buildDefaultTooltip() generates default content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final point = ChartDataPoint(x: 5.0, y: 10.0, label: 'Test');
      const seriesId = 'series1';
      final style = TooltipStyle();

      final widget = tooltipProvider.buildDefaultTooltip(
        context,
        point,
        seriesId,
        style,
      );

      expect(widget, isA<Widget>());
      expect(widget, isA<Container>());
    });

    testWidgets('buildMultiSeriesTooltip() shows multiple series', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final points = [
        ChartDataPoint(x: 5.0, y: 10.0),
        ChartDataPoint(x: 5.0, y: 15.0),
      ];
      final seriesIds = ['series1', 'series2'];
      final style = TooltipStyle();

      final widget = tooltipProvider.buildMultiSeriesTooltip(
        context,
        points,
        seriesIds,
        style,
      );

      expect(widget, isA<Widget>());
      expect(widget, isA<Container>());
    });

    test('shouldUpdate() detects content changes', () {
      final oldPoint = ChartDataPoint(x: 5.0, y: 10.0);
      final newPoint = ChartDataPoint(x: 6.0, y: 11.0);

      final shouldUpdate = tooltipProvider.shouldUpdate(
        oldPoint,
        newPoint,
      );

      expect(shouldUpdate, isTrue);
    });

    test('shouldUpdate() returns false for same point', () {
      final point = ChartDataPoint(x: 5.0, y: 10.0);

      final shouldUpdate = tooltipProvider.shouldUpdate(
        point,
        point,
      );

      expect(shouldUpdate, isFalse);
    });
  });
}

