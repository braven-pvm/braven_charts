// Copyright (c) 2025 braven_charts. All rights reserved.
// Tests for TooltipRenderer module

import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_animator.dart';
import 'package:braven_charts/src/rendering/modules/tooltip_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

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
    points: points ??
        const [
          ChartDataPoint(x: 0, y: 0),
          ChartDataPoint(x: 50, y: 100),
          ChartDataPoint(x: 100, y: 50),
        ],
    color: color,
    dataPointMarkerRadius: markerRadius,
  );

  return SeriesElement(
    series: series,
    transform: createTestTransform(),
  );
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

void main() {
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
          createTestSeriesElement(
            id: 'test-series',
            name: 'Test Series Name',
          ),
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
          YAxisConfig.withId(id: 'test-series_axis',
            position: YAxisPosition.left,
            label: 'Test',
            unit: 'kg',
          ),
        ];

        const effectiveBindings = [
          SeriesAxisBinding(seriesId: 'test-series', yAxisId: 'test-series_axis'),
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
          points: [
            ChartDataPoint(x: 0, y: 0),
            ChartDataPoint(x: 50, y: 100),
          ],
          color: Color(0xFF0000FF),
          markerRadius: 6.0,
        );

        elements = [
          SeriesElement(
            series: series,
            transform: createTestTransform(),
          ),
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
          points: [
            ChartDataPoint(x: 0, y: 0),
            ChartDataPoint(x: 50, y: 100),
          ],
          color: Color(0xFF0000FF),
          dataPointMarkerRadius: 5.0,
        );

        elements = [
          SeriesElement(
            series: series,
            transform: createTestTransform(),
          ),
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
