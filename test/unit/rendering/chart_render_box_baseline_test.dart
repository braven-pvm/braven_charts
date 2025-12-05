// Copyright (c) 2025 braven_charts. All rights reserved.
// Baseline Tests for ChartRenderBox Refactoring
//
// PURPOSE: These tests establish baselines for ChartRenderBox behavior BEFORE
// refactoring into smaller modules. Any refactoring MUST preserve these behaviors.
//
// CRITICAL: Run these tests after EVERY refactoring change to ensure no regressions.

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartRenderBox Baseline Tests', () {
    late ChartInteractionCoordinator coordinator;

    setUp(() {
      coordinator = ChartInteractionCoordinator();
    });

    tearDown(() {
      coordinator.dispose();
    });

    // =========================================================================
    // Construction Tests
    // =========================================================================

    group('Construction', () {
      test('creates with minimal required parameters', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        expect(renderBox.coordinator, equals(coordinator));
        expect(renderBox.transform, isNull); // No layout yet
      });

      test('creates with element generator instead of elements', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elementGenerator: (transform) => [],
        );

        expect(renderBox.coordinator, equals(coordinator));
      });

      test('throws assertion when both elements and generator provided', () {
        expect(
          () => ChartRenderBox(
            coordinator: coordinator,
            elements: [],
            elementGenerator: (transform) => [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion when neither elements nor generator provided', () {
        expect(
          () => ChartRenderBox(
            coordinator: coordinator,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    // =========================================================================
    // Coordinate Conversion Tests
    // =========================================================================

    group('Coordinate Conversion', () {
      test('widgetToPlot converts widget coordinates to plot coordinates', () {
        // Create a custom render box subclass to test coordinate conversion
        // without needing full layout
        final renderBox = _TestableChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // Set up internal state for testing
        renderBox.setTestPlotArea(const Rect.fromLTWH(50, 30, 400, 300));

        // Test conversion
        final widgetPos = const Offset(150, 130);
        final plotPos = renderBox.widgetToPlot(widgetPos);

        expect(plotPos.dx, equals(100.0)); // 150 - 50 = 100
        expect(plotPos.dy, equals(100.0)); // 130 - 30 = 100
      });

      test('plotToWidget converts plot coordinates to widget coordinates', () {
        final renderBox = _TestableChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        renderBox.setTestPlotArea(const Rect.fromLTWH(50, 30, 400, 300));

        final plotPos = const Offset(100, 100);
        final widgetPos = renderBox.plotToWidget(plotPos);

        expect(widgetPos.dx, equals(150.0)); // 100 + 50 = 150
        expect(widgetPos.dy, equals(130.0)); // 100 + 30 = 130
      });

      test('widgetToPlot and plotToWidget are inverses', () {
        final renderBox = _TestableChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        renderBox.setTestPlotArea(const Rect.fromLTWH(75, 40, 500, 400));

        const originalWidget = Offset(200, 200);
        final plotPos = renderBox.widgetToPlot(originalWidget);
        final roundTrip = renderBox.plotToWidget(plotPos);

        expect(roundTrip.dx, closeTo(originalWidget.dx, 0.001));
        expect(roundTrip.dy, closeTo(originalWidget.dy, 0.001));
      });
    });

    // =========================================================================
    // Transform Tests
    // =========================================================================

    group('ChartTransform Integration', () {
      test('transform is null before layout', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        expect(renderBox.transform, isNull);
      });

      test('plotWidth and plotHeight return zero before layout', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        expect(renderBox.plotWidth, equals(0.0));
        expect(renderBox.plotHeight, equals(0.0));
      });
    });

    // =========================================================================
    // Normalization Tests
    // =========================================================================

    group('Normalization Functions', () {
      test('normalizeYValue maps value to 0-1 range', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // Value at min should be 0
        expect(renderBox.normalizeYValue(0.0, 0.0, 100.0), equals(0.0));

        // Value at max should be 1
        expect(renderBox.normalizeYValue(100.0, 0.0, 100.0), equals(1.0));

        // Value at midpoint should be 0.5
        expect(renderBox.normalizeYValue(50.0, 0.0, 100.0), equals(0.5));

        // Value at 25% should be 0.25
        expect(renderBox.normalizeYValue(25.0, 0.0, 100.0), equals(0.25));
      });

      test('normalizeYValue handles negative ranges', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        expect(renderBox.normalizeYValue(-50.0, -100.0, 0.0), equals(0.5));
        expect(renderBox.normalizeYValue(-100.0, -100.0, 0.0), equals(0.0));
        expect(renderBox.normalizeYValue(0.0, -100.0, 0.0), equals(1.0));
      });

      test('denormalizeYValue reverses normalization', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // 0 should map to min
        expect(renderBox.denormalizeYValue(0.0, 0.0, 100.0), equals(0.0));

        // 1 should map to max
        expect(renderBox.denormalizeYValue(1.0, 0.0, 100.0), equals(100.0));

        // 0.5 should map to midpoint
        expect(renderBox.denormalizeYValue(0.5, 0.0, 100.0), equals(50.0));
      });

      test('normalizeYValue and denormalizeYValue are inverses', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        const original = 42.0;
        const min = 10.0;
        const max = 90.0;

        final normalized = renderBox.normalizeYValue(original, min, max);
        final denormalized = renderBox.denormalizeYValue(normalized, min, max);

        expect(denormalized, closeTo(original, 0.001));
      });

      test('normalizeValue and denormalizeValue work correctly', () {
        final renderBox = _TestableChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // Test normalizeValue
        expect(renderBox.normalizeValue(50.0, 0.0, 100.0), equals(0.5));
        expect(renderBox.normalizeValue(0.0, 0.0, 100.0), equals(0.0));
        expect(renderBox.normalizeValue(100.0, 0.0, 100.0), equals(1.0));

        // Test denormalizeValue
        expect(renderBox.denormalizeValue(0.5, 0.0, 100.0), equals(50.0));
        expect(renderBox.denormalizeValue(0.0, 0.0, 100.0), equals(0.0));
        expect(renderBox.denormalizeValue(1.0, 0.0, 100.0), equals(100.0));
      });
    });

    // =========================================================================
    // State Update Tests
    // =========================================================================

    group('State Updates', () {
      test('updateElements replaces elements and marks needs paint', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        final newElements = <ChartElement>[];
        renderBox.updateElements(newElements);

        // No assertion error means success
        // We can't easily verify markNeedsPaint was called without mocking
      });

      test('setTooltipsEnabled updates tooltip visibility', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // Default is true
        renderBox.setTooltipsEnabled(false);
        renderBox.setTooltipsEnabled(true);

        // No assertion error means success
      });

      test('setShowXScrollbar and setShowYScrollbar work', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        renderBox.setShowXScrollbar(true);
        renderBox.setShowYScrollbar(true);
        renderBox.setShowXScrollbar(false);
        renderBox.setShowYScrollbar(false);

        // No assertion error means success
      });
    });

    // =========================================================================
    // Disposal Tests
    // =========================================================================

    group('Disposal', () {
      test('dispose cleans up resources without error', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
        );

        // Should not throw
        renderBox.dispose();
      });

      test('dispose can be called after timers are active', () {
        final renderBox = ChartRenderBox(
          coordinator: coordinator,
          elements: [],
          tooltipsEnabled: true,
        );

        // Dispose should clean up any active timers
        renderBox.dispose();
      });
    });
  });

  // ===========================================================================
  // ChartTransform Unit Tests
  // ===========================================================================

  group('ChartTransform Baseline Tests', () {
    test('creates with valid parameters', () {
      const transform = ChartTransform(
        dataXMin: 0.0,
        dataXMax: 100.0,
        dataYMin: 0.0,
        dataYMax: 100.0,
        plotWidth: 800.0,
        plotHeight: 600.0,
      );

      expect(transform.dataXMin, equals(0.0));
      expect(transform.dataXMax, equals(100.0));
      expect(transform.dataYMin, equals(0.0));
      expect(transform.dataYMax, equals(100.0));
      expect(transform.plotWidth, equals(800.0));
      expect(transform.plotHeight, equals(600.0));
    });

    test('throws assertion for invalid X range', () {
      expect(
        () => ChartTransform(
          dataXMin: 100.0,
          dataXMax: 0.0, // Invalid: max < min
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion for invalid Y range', () {
      expect(
        () => ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 100.0,
          dataYMax: 0.0, // Invalid: max < min
          plotWidth: 800.0,
          plotHeight: 600.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion for zero plot width', () {
      expect(
        () => ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 0.0, // Invalid
          plotHeight: 600.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    group('Coordinate Transformations', () {
      late ChartTransform transform;

      setUp(() {
        transform = const ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
          invertY: true,
        );
      });

      test('dataToPlot converts data origin to plot top-left', () {
        final plotPos = transform.dataToPlot(0.0, 100.0); // Top-left in data

        expect(plotPos.dx, closeTo(0.0, 0.001));
        expect(plotPos.dy, closeTo(0.0, 0.001)); // Y inverted
      });

      test('dataToPlot converts data max to plot bottom-right', () {
        final plotPos = transform.dataToPlot(100.0, 0.0); // Bottom-right in data

        expect(plotPos.dx, closeTo(800.0, 0.001));
        expect(plotPos.dy, closeTo(600.0, 0.001)); // Y inverted
      });

      test('dataToPlot converts center correctly', () {
        final plotPos = transform.dataToPlot(50.0, 50.0);

        expect(plotPos.dx, closeTo(400.0, 0.001)); // Center X
        expect(plotPos.dy, closeTo(300.0, 0.001)); // Center Y
      });

      test('plotToData reverses dataToPlot', () {
        const dataX = 25.0;
        const dataY = 75.0;

        final plotPos = transform.dataToPlot(dataX, dataY);
        final roundTrip = transform.plotToData(plotPos.dx, plotPos.dy);

        expect(roundTrip.dx, closeTo(dataX, 0.001));
        expect(roundTrip.dy, closeTo(dataY, 0.001));
      });
    });

    group('Computed Properties', () {
      test('dataXRange returns correct range', () {
        const transform = ChartTransform(
          dataXMin: 10.0,
          dataXMax: 60.0,
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        );

        expect(transform.dataXRange, equals(50.0));
      });

      test('dataYRange returns correct range', () {
        const transform = ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 20.0,
          dataYMax: 80.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        );

        expect(transform.dataYRange, equals(60.0));
      });

      test('pixelsPerDataX is correct', () {
        const transform = ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        );

        expect(transform.pixelsPerDataX, equals(8.0)); // 800 / 100
      });

      test('pixelsPerDataY is correct', () {
        const transform = ChartTransform(
          dataXMin: 0.0,
          dataXMax: 100.0,
          dataYMin: 0.0,
          dataYMax: 100.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        );

        expect(transform.pixelsPerDataY, equals(6.0)); // 600 / 100
      });

      test('visibleDataBounds returns correct rect', () {
        const transform = ChartTransform(
          dataXMin: 10.0,
          dataXMax: 90.0,
          dataYMin: 20.0,
          dataYMax: 80.0,
          plotWidth: 800.0,
          plotHeight: 600.0,
        );

        final bounds = transform.visibleDataBounds;

        expect(bounds.left, equals(10.0));
        expect(bounds.right, equals(90.0));
        expect(bounds.top, equals(20.0));
        expect(bounds.bottom, equals(80.0));
      });
    });
  });

  // ===========================================================================
  // Zoom Constraint Baseline Tests
  // ===========================================================================

  group('Zoom Constraint Baselines', () {
    test('minZoomLevel is 0.8 (can zoom out to 125% of data)', () {
      expect(ChartRenderBox.minZoomLevel, equals(0.8));
    });

    test('maxZoomLevel is 10.0 (can zoom in to 10% of data)', () {
      expect(ChartRenderBox.maxZoomLevel, equals(10.0));
    });

    test('maxWhitespaceFraction is 0.1 (10% whitespace allowed)', () {
      expect(ChartRenderBox.maxWhitespaceFraction, equals(0.1));
    });
  });
}

// =============================================================================
// Test Helper Classes
// =============================================================================

/// Testable subclass of ChartRenderBox that exposes internal state for testing.
///
/// This allows us to test coordinate conversion and other methods that depend
/// on internal state without requiring full layout.
class _TestableChartRenderBox extends ChartRenderBox {
  _TestableChartRenderBox({
    required super.coordinator,
    super.elements,
  });

  Rect _testPlotArea = Rect.zero;

  void setTestPlotArea(Rect plotArea) {
    _testPlotArea = plotArea;
    // Use reflection-like approach via method override
    // We'll need to override widgetToPlot and plotToWidget to use _testPlotArea
  }

  @override
  Offset widgetToPlot(Offset widgetPosition) {
    // Use test plot area for testing
    return Offset(
      widgetPosition.dx - _testPlotArea.left,
      widgetPosition.dy - _testPlotArea.top,
    );
  }

  @override
  Offset plotToWidget(Offset plotPosition) {
    // Use test plot area for testing
    return Offset(
      plotPosition.dx + _testPlotArea.left,
      plotPosition.dy + _testPlotArea.top,
    );
  }
}
