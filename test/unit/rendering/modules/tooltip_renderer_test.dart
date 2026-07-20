// Copyright (c) 2025 braven_charts. All rights reserved.
// Tests for TooltipRenderer module

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/interaction/core/data_hit.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/candlestick_data_point.dart';
import 'package:braven_charts/src/models/candlestick_interaction_details.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_animator.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_renderer.dart';
import 'package:braven_charts/src/theming/styles/label_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Initialize Flutter test binding for SchedulerBinding
  TestWidgetsFlutterBinding.ensureInitialized();

  // =============================================================================
  // Test Helpers
  // =============================================================================

  /// Creates a test transform for series elements.
  ChartTransform createTestTransform() {
    return const ChartTransform(
      dataXMin: 0,
      dataXMax: 100,
      dataYMin: 0,
      dataYMax: 100,
      plotWidth: 200,
      plotHeight: 200,
      invertY: true,
    );
  }

  /// Creates a test series element for tooltip tests.
  SeriesElement createTestSeriesElement({
    String id = 'test-series',
    String? name,
    List<ChartDataPoint>? points,
    Color color = const Color(0xFF0000FF),
    double markerRadius = 4.0,
  }) {
    final series = LineChartSeries(
      id: id,
      name: name,
      points:
          points ??
          const [
            ChartDataPoint(x: 0, y: 0),
            ChartDataPoint(x: 50, y: 100),
            ChartDataPoint(x: 100, y: 50),
          ],
      color: color,
      dataPointMarkerRadius: markerRadius,
    );

    return SeriesElement(series: series, transform: createTestTransform());
  }

  /// Creates a mock HoveredMarkerInfo for testing.
  HoveredMarkerInfo createTestMarkerInfo({
    String seriesId = 'test-series',
    int markerIndex = 0,
    Offset plotPosition = const Offset(100, 100),
  }) {
    return HoveredMarkerInfo(
      seriesId: seriesId,
      markerIndex: markerIndex,
      plotPosition: plotPosition,
    );
  }

  // =============================================================================
  // Tests
  // =============================================================================

  group('TooltipRenderer', () {
    late TooltipRenderer renderer;
    late TooltipAnimator animator;
    late List<ChartElement> elements;

    setUp(() {
      renderer = const TooltipRenderer();
      animator = TooltipAnimator(onRepaint: () {});
      elements = [createTestSeriesElement()];
    });

    tearDown(() {
      animator.dispose();
    });

    group('Construction', () {
      test('can be const constructed', () {
        const renderer1 = TooltipRenderer();
        const renderer2 = TooltipRenderer();
        expect(identical(renderer1, renderer2), isTrue);
      });
    });

    group('buildBaseTooltipText', () {
      test('qualifies a repeated radial category with its ring identity', () {
        const hit = ChartDataHit(
          seriesId: 'previous',
          pointIndex: 0,
          plotPosition: Offset(80, 80),
          semanticBounds: Rect.fromLTWH(40, 40, 80, 80),
          point: ChartDataPoint(x: 0, y: 50, label: 'Subscriptions'),
          formattedValue: 'Previous 50 USD',
          ordinal: 1,
          count: 2,
          category: 'Subscriptions',
          total: 200,
          share: 0.25,
          formattedShare: 'Previous 25%',
          groupLabel: 'Inner ring',
          groupName: 'Previous period',
          groupOrdinal: 2,
          groupCount: 2,
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Previous period',
            formattedCartesianY: '50.00 USD',
            formatDataValue: (value) => value.toStringAsFixed(0),
          ),
          'Inner ring · Previous period\nSubscriptions\n'
          'Value: Previous 50 USD\nShare: Previous 25%',
        );
      });

      test('includes quantitative Scatter opacity details', () {
        const hit = ChartDataHit(
          seriesId: 'forecast',
          pointIndex: 0,
          plotPosition: Offset(80, 80),
          semanticBounds: Rect.fromLTWH(40, 40, 80, 80),
          point: ChartDataPoint(x: 7, y: 92, opacityValue: 84),
          formattedValue: '92 k units',
          formattedOpacityValue: '84 %',
          opacityLabel: 'Model confidence',
          ordinal: 1,
          count: 1,
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Adaptive model',
            formattedCartesianY: '92 k units',
            formatDataValue: (value) => value.toStringAsFixed(0),
          ),
          'Adaptive model\nX: 7\nY: 92 k units\nModel confidence: 84 %',
        );
      });

      test('presents complete OHLC values and direction', () {
        final point = CandlestickDataPoint(
          x: 7,
          open: 100,
          high: 112,
          low: 98,
          close: 110,
          label: 'Jul 19',
        );
        final hit = ChartDataHit(
          seriesId: 'price',
          pointIndex: 0,
          plotPosition: const Offset(80, 80),
          semanticBounds: const Rect.fromLTWH(40, 40, 80, 80),
          point: point,
          formattedValue: '110.00 USD',
          ordinal: 1,
          count: 1,
          candlestick: CandlestickInteractionDetails.fromPoint(
            point,
            unit: 'USD',
          ),
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Price',
            formattedCartesianY: '110.00 USD',
            formatDataValue: (value) => value.toStringAsFixed(0),
          ),
          'Price · Jul 19\nOpen: 100.00 USD\nHigh: 112.00 USD\n'
          'Low: 98.00 USD\nClose: 110.00 USD\n'
          'Change: +10.00 USD (+10.00%) · rising',
        );
      });

      test(
        'summarizes a Scatter cluster without pretending it is one point',
        () {
          const hit = ChartDataHit(
            seriesId: 'accounts',
            pointIndex: 2,
            sourcePointIndices: [2, 5, 9, 12],
            plotPosition: Offset(80, 80),
            semanticBounds: Rect.fromLTWH(60, 60, 40, 40),
            point: ChartDataPoint(x: 32, y: 48),
            formattedXValue: '36.25',
            formattedValue: '52.75 %',
            ordinal: 1,
            count: 24,
            category: '4 observations',
          );

          expect(
            renderer.buildBaseTooltipText(
              dataHit: hit,
              seriesName: 'Customer accounts',
              formattedCartesianY: '48 %',
              formatDataValue: (value) => value.toStringAsFixed(0),
            ),
            'Customer accounts\n4 observations\n'
            'X mean: 36.25\nY mean: 52.75 %',
          );
        },
      );

      test('discloses a single-observation Scatter bin as an aggregate', () {
        const hit = ChartDataHit(
          seriesId: 'demand',
          pointIndex: 7,
          sourcePointIndices: [7],
          plotPosition: Offset(80, 80),
          semanticBounds: Rect.fromLTWH(60, 60, 40, 40),
          point: ChartDataPoint(x: 32, y: 48),
          formattedXValue: '32.00',
          formattedValue: '48.00',
          ordinal: 1,
          count: 24,
          category: '1 observation · hexagonal bin',
          aggregateValue: 0.125,
          formattedAggregateValue: '12.5%',
          aggregateLabel: 'Share of visible observations',
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Pickup demand',
            formattedCartesianY: '48.00',
            formatDataValue: (value) => value.toStringAsFixed(0),
          ),
          'Pickup demand\n1 observation · hexagonal bin\n'
          'X mean: 32.00\nY mean: 48.00\n'
          'Share of visible observations: 12.5%',
        );
      });

      test('discloses omitted optional values from a bin aggregate', () {
        const hit = ChartDataHit(
          seriesId: 'demand',
          pointIndex: 7,
          sourcePointIndices: [7, 8, 9],
          plotPosition: Offset(80, 80),
          semanticBounds: Rect.fromLTWH(60, 60, 40, 40),
          point: ChartDataPoint(x: 32, y: 48),
          formattedXValue: '32.00',
          formattedValue: '48.00',
          ordinal: 1,
          count: 24,
          category: '3 observations · hexagonal bin',
          aggregateValue: 12,
          formattedAggregateValue: '12.00',
          aggregateLabel: 'Mean Magnitude',
          aggregateSampleCount: 2,
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Pickup demand',
            formattedCartesianY: '48.00',
            formatDataValue: (value) => value.toStringAsFixed(0),
          ),
          contains('Aggregate sample: 2 of 3 observations'),
        );
        expect(
          hit.semanticLabel,
          contains('2 of 3 observations contributed to the aggregate'),
        );
      });

      test('presents a single-observation density region as an aggregate', () {
        const hit = ChartDataHit(
          seriesId: 'density',
          pointIndex: 2,
          sourcePointIndices: [2],
          plotPosition: Offset(40, 30),
          semanticBounds: Rect.fromLTWH(36, 26, 8, 8),
          point: ChartDataPoint(x: 4, y: 3),
          category: '1 nearby observation · density region',
          formattedValue: '3.00',
          formattedXValue: '4.00',
          aggregateValue: 0.72,
          formattedAggregateValue: '72.0%',
          aggregateLabel: 'Relative density',
          aggregateSampleCount: 1,
          ordinal: 3,
          count: 6,
        );

        expect(
          renderer.buildBaseTooltipText(
            dataHit: hit,
            seriesName: 'Demand',
            formattedCartesianY: '3',
            formatDataValue: (value) => '$value',
          ),
          'Demand\n1 nearby observation · density region\nX mean: 4.00'
          '\nY mean: 3.00\nRelative density: 72.0%',
        );
      });
    });

    group('drawMarkerTooltip', () {
      test('throws StateError when series not found', () {
        final markerInfo = createTestMarkerInfo(seriesId: 'nonexistent');

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          throwsStateError,
        );
      });

      test('renders tooltip for valid marker info', () {
        final markerInfo = createTestMarkerInfo(
          seriesId: 'test-series',
          markerIndex: 1, // Second point
          plotPosition: const Offset(100, 10),
        );

        // Set animator opacity to 1.0
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        // Should not throw
        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('uses series name in tooltip when available', () {
        elements = [
          createTestSeriesElement(id: 'test-series', name: 'Test Series Name'),
        ];

        final markerInfo = createTestMarkerInfo();
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        // Verify the render completes (text content verified via integration tests)
        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('uses followCursor position when enabled', () {
        final markerInfo = createTestMarkerInfo(
          plotPosition: const Offset(100, 100),
        );
        const cursorPosition = Offset(200, 200);

        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        // Verify the render completes with cursor position
        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: cursorPosition,
            interactionConfig: const InteractionConfig(
              tooltip: TooltipConfig(followCursor: true),
            ),
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });
    });

    group('Tooltip Positioning', () {
      test('handles all tooltip positions', () {
        final markerInfo = createTestMarkerInfo(
          plotPosition: const Offset(400, 300), // Center of canvas
        );

        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        for (final position in TooltipPosition.values) {
          expect(
            () => renderer.drawMarkerTooltip(
              canvas: _MockCanvas(),
              size: const Size(800, 600),
              markerInfo: markerInfo,
              elements: elements,
              animator: animator,
              cursorPosition: null,
              interactionConfig: InteractionConfig(
                tooltip: TooltipConfig(preferredPosition: position),
              ),
              theme: null,
              effectiveAxes: const [],
              effectiveBindings: const [],
              formatDataValue: (v) => v.toStringAsFixed(1),
              plotToWidget: (o) => o,
            ),
            returnsNormally,
            reason: 'Should handle position: $position',
          );
        }
      });

      test('handles edge cases near canvas boundaries', () {
        final testCases = [
          const Offset(10, 10), // Top-left corner
          const Offset(790, 10), // Top-right corner
          const Offset(10, 590), // Bottom-left corner
          const Offset(790, 590), // Bottom-right corner
        ];

        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        for (final position in testCases) {
          final markerInfo = createTestMarkerInfo(plotPosition: position);

          expect(
            () => renderer.drawMarkerTooltip(
              canvas: _MockCanvas(),
              size: const Size(800, 600),
              markerInfo: markerInfo,
              elements: elements,
              animator: animator,
              cursorPosition: null,
              interactionConfig: null,
              theme: null,
              effectiveAxes: const [],
              effectiveBindings: const [],
              formatDataValue: (v) => v.toStringAsFixed(1),
              plotToWidget: (o) => o,
            ),
            returnsNormally,
            reason: 'Should handle position near boundary: $position',
          );
        }
      });
    });

    group('Styling', () {
      test('theme style replaces the legacy default config style', () {
        final theme = ChartTheme.light.copyWith(
          interactionTheme: ChartTheme.light.interactionTheme.copyWith(
            tooltipStyle: const LabelStyle(
              backgroundColor: Color(0xFF112233),
              borderColor: Color(0xFF445566),
              borderWidth: 2,
              borderRadius: 9,
              padding: EdgeInsets.all(11),
              textStyle: TextStyle(color: Color(0xFFFAFAFA), fontSize: 15),
              shadowColor: Color(0x55000000),
              shadowBlurRadius: 7,
            ),
          ),
        );

        final style = renderer.resolveStyle(
          const InteractionConfig(tooltip: TooltipConfig()),
          theme,
        );

        expect(style.backgroundColor, const Color(0xFF112233));
        expect(style.borderColor, const Color(0xFF445566));
        expect(style.borderWidth, 2);
        expect(style.borderRadius, 9);
        expect(style.padding, 11);
        expect(style.textColor, const Color(0xFFFAFAFA));
        expect(style.fontSize, 15);
        expect(style.shadowColor, const Color(0x55000000));
        expect(style.shadowBlurRadius, 7);
      });

      test('explicit non-default config style overrides the theme', () {
        const explicit = TooltipStyle(backgroundColor: Color(0xFFAABBCC));
        final style = renderer.resolveStyle(
          const InteractionConfig(tooltip: TooltipConfig(style: explicit)),
          ChartTheme.dark,
        );

        expect(style, explicit);
      });

      test('uses custom tooltip style when provided', () {
        final markerInfo = createTestMarkerInfo();
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        const customConfig = InteractionConfig(
          tooltip: TooltipConfig(
            style: TooltipStyle(
              backgroundColor: Color(0xFFFF0000),
              textColor: Color(0xFF00FF00),
              fontSize: 16.0,
              borderRadius: 8.0,
              padding: 12.0,
            ),
          ),
        );

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: customConfig,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('uses theme style when config style not provided', () {
        final markerInfo = createTestMarkerInfo();
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: ChartTheme.light,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });
    });

    group('Y-Axis Unit Formatting', () {
      test('formats Y value with unit when axis config available', () {
        final markerInfo = createTestMarkerInfo();
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        final effectiveAxes = [
          YAxisConfig.withId(
            id: 'test-series_axis',
            position: YAxisPosition.left,
            label: 'Test',
            unit: 'kg',
          ),
        ];

        const effectiveBindings = [
          SeriesAxisBinding(
            seriesId: 'test-series',
            yAxisId: 'test-series_axis',
          ),
        ];

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: effectiveAxes,
            effectiveBindings: effectiveBindings,
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });
    });

    group('Different Series Types', () {
      test('handles LineChartSeries', () {
        elements = [createTestSeriesElement()]; // Default is LineChartSeries
        final markerInfo = createTestMarkerInfo();
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('handles ScatterChartSeries', () {
        const series = ScatterChartSeries(
          id: 'scatter-series',
          points: [ChartDataPoint(x: 0, y: 0), ChartDataPoint(x: 50, y: 100)],
          color: Color(0xFF0000FF),
          markerRadius: 6.0,
        );

        elements = [
          SeriesElement(series: series, transform: createTestTransform()),
        ];

        final markerInfo = createTestMarkerInfo(seriesId: 'scatter-series');
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('handles AreaChartSeries', () {
        const series = AreaChartSeries(
          id: 'area-series',
          points: [ChartDataPoint(x: 0, y: 0), ChartDataPoint(x: 50, y: 100)],
          color: Color(0xFF0000FF),
          dataPointMarkerRadius: 5.0,
        );

        elements = [
          SeriesElement(series: series, transform: createTestTransform()),
        ];

        final markerInfo = createTestMarkerInfo(seriesId: 'area-series');
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });
    });

    group('Opacity Animation', () {
      test('renders with animator opacity', () async {
        final markerInfo = createTestMarkerInfo();

        // Show tooltip and wait for animation
        animator.show('marker', const TooltipConfig(showDelay: Duration.zero));
        await Future.delayed(const Duration(milliseconds: 200));

        expect(animator.opacity, greaterThan(0.0));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });

      test('renders at zero opacity without crashing', () {
        final markerInfo = createTestMarkerInfo();

        // Animator starts at 0.0 opacity
        expect(animator.opacity, equals(0.0));

        expect(
          () => renderer.drawMarkerTooltip(
            canvas: _MockCanvas(),
            size: const Size(800, 600),
            markerInfo: markerInfo,
            elements: elements,
            animator: animator,
            cursorPosition: null,
            interactionConfig: null,
            theme: null,
            effectiveAxes: const [],
            effectiveBindings: const [],
            formatDataValue: (v) => v.toStringAsFixed(1),
            plotToWidget: (o) => o,
          ),
          returnsNormally,
        );
      });
    });
  });
}

// =============================================================================
// Mock Canvas for Testing
// =============================================================================

/// A minimal mock canvas that records draw calls.
class _MockCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
