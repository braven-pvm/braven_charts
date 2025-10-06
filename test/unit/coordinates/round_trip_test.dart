/// Unit Test: Round-Trip Accuracy for All 56 Transformation Paths
///
/// Comprehensive test verifying bidirectional accuracy for all 8x7=56
/// transformation paths. Each coordinate system must transform to any
/// other system and back with minimal precision loss.
///
/// Accuracy targets:
/// - Screen-based systems: <0.01 pixels
/// - Data-based systems: <0.001% relative error
///
/// Expected: FAIL until T026 implements all transitive paths
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Round-trip accuracy for all 56 transformation paths', () {
    late TransformContext context;
    late UniversalCoordinateTransformer transformer;

    setUp(() {
      // Standard test context with all coordinate systems active
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: const ViewportState(
          xRange: DataRange(min: 20, max: 80),
          yRange: DataRange(min: -30, max: 30),
          zoomFactor: 1.5,
          panOffset: Point(5.0, 2.0),
        ),
        series: [
          ChartSeries(
            id: 'test',
            points: [
              const ChartDataPoint(x: 0.0, y: 0.0),
              const ChartDataPoint(x: 50.0, y: 25.0),
              const ChartDataPoint(x: 100.0, y: -25.0),
            ],
          ),
        ],
        markerOffset: const Point(10.0, -5.0),
        devicePixelRatio: 1.0,
      );

      transformer = UniversalCoordinateTransformer();
    });

    // Helper to test round-trip accuracy
    void testRoundTrip(
      Point<double> original,
      CoordinateSystem startSystem,
      CoordinateSystem intermediateSystem,
      double tolerance,
      String description,
    ) {
      final intermediate = transformer.transform(
        original,
        from: startSystem,
        to: intermediateSystem,
        context: context,
      );

      final roundTrip = transformer.transform(
        intermediate,
        from: intermediateSystem,
        to: startSystem,
        context: context,
      );

      expect(
        roundTrip.x,
        closeTo(original.x, tolerance),
        reason: '$description: X round-trip accuracy',
      );
      expect(
        roundTrip.y,
        closeTo(original.y, tolerance),
        reason: '$description: Y round-trip accuracy',
      );
    }

    test('mouse ↔ all other systems (7 paths)', () {
      final mousePoint = const Point<double>(250.0, 180.0);

      testRoundTrip(mousePoint, CoordinateSystem.mouse, CoordinateSystem.screen,
          0.01, 'mouse ↔ screen');
      testRoundTrip(mousePoint, CoordinateSystem.mouse,
          CoordinateSystem.chartArea, 0.01, 'mouse ↔ chartArea');
      testRoundTrip(mousePoint, CoordinateSystem.mouse, CoordinateSystem.data,
          0.01, 'mouse ↔ data');
      testRoundTrip(mousePoint, CoordinateSystem.mouse,
          CoordinateSystem.dataPoint, 0.01, 'mouse ↔ dataPoint');
      testRoundTrip(mousePoint, CoordinateSystem.mouse, CoordinateSystem.marker,
          0.01, 'mouse ↔ marker');
      testRoundTrip(mousePoint, CoordinateSystem.mouse,
          CoordinateSystem.viewport, 0.01, 'mouse ↔ viewport');
      testRoundTrip(mousePoint, CoordinateSystem.mouse,
          CoordinateSystem.normalized, 0.01, 'mouse ↔ normalized');
    });

    test('screen ↔ all other systems (7 paths)', () {
      final screenPoint = const Point<double>(300.0, 200.0);

      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.mouse, 0.01, 'screen ↔ mouse');
      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.chartArea, 0.01, 'screen ↔ chartArea');
      testRoundTrip(screenPoint, CoordinateSystem.screen, CoordinateSystem.data,
          0.01, 'screen ↔ data');
      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.dataPoint, 0.01, 'screen ↔ dataPoint');
      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.marker, 0.01, 'screen ↔ marker');
      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.viewport, 0.01, 'screen ↔ viewport');
      testRoundTrip(screenPoint, CoordinateSystem.screen,
          CoordinateSystem.normalized, 0.01, 'screen ↔ normalized');
    });

    test('chartArea ↔ all other systems (7 paths)', () {
      final chartPoint = const Point<double>(350.0, 270.0);

      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.mouse, 0.01, 'chartArea ↔ mouse');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.screen, 0.01, 'chartArea ↔ screen');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.data, 0.01, 'chartArea ↔ data');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.dataPoint, 0.01, 'chartArea ↔ dataPoint');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.marker, 0.01, 'chartArea ↔ marker');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.viewport, 0.01, 'chartArea ↔ viewport');
      testRoundTrip(chartPoint, CoordinateSystem.chartArea,
          CoordinateSystem.normalized, 0.01, 'chartArea ↔ normalized');
    });

    test('data ↔ all other systems (7 paths)', () {
      final dataPoint = const Point<double>(50.0, 10.0);

      testRoundTrip(dataPoint, CoordinateSystem.data, CoordinateSystem.mouse,
          0.01, 'data ↔ mouse');
      testRoundTrip(dataPoint, CoordinateSystem.data, CoordinateSystem.screen,
          0.01, 'data ↔ screen');
      testRoundTrip(dataPoint, CoordinateSystem.data,
          CoordinateSystem.chartArea, 0.01, 'data ↔ chartArea');
      testRoundTrip(dataPoint, CoordinateSystem.data,
          CoordinateSystem.dataPoint, 0.01, 'data ↔ dataPoint');
      testRoundTrip(dataPoint, CoordinateSystem.data, CoordinateSystem.marker,
          0.01, 'data ↔ marker');
      testRoundTrip(dataPoint, CoordinateSystem.data, CoordinateSystem.viewport,
          0.01, 'data ↔ viewport');
      testRoundTrip(dataPoint, CoordinateSystem.data,
          CoordinateSystem.normalized, 0.01, 'data ↔ normalized');
    });

    test('dataPoint ↔ all other systems (7 paths)', () {
      final indexPoint = const Point<double>(0.0, 1.0); // Series 0, point 1

      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.mouse, 0.01, 'dataPoint ↔ mouse');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.screen, 0.01, 'dataPoint ↔ screen');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.chartArea, 0.01, 'dataPoint ↔ chartArea');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.data, 0.01, 'dataPoint ↔ data');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.marker, 0.01, 'dataPoint ↔ marker');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.viewport, 0.01, 'dataPoint ↔ viewport');
      testRoundTrip(indexPoint, CoordinateSystem.dataPoint,
          CoordinateSystem.normalized, 0.01, 'dataPoint ↔ normalized');
    });

    test('marker ↔ all other systems (7 paths)', () {
      final markerPoint = const Point<double>(360.0, 265.0);

      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.mouse, 0.01, 'marker ↔ mouse');
      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.screen, 0.01, 'marker ↔ screen');
      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.chartArea, 0.01, 'marker ↔ chartArea');
      testRoundTrip(markerPoint, CoordinateSystem.marker, CoordinateSystem.data,
          0.01, 'marker ↔ data');
      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.dataPoint, 0.01, 'marker ↔ dataPoint');
      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.viewport, 0.01, 'marker ↔ viewport');
      testRoundTrip(markerPoint, CoordinateSystem.marker,
          CoordinateSystem.normalized, 0.01, 'marker ↔ normalized');
    });

    test('viewport ↔ all other systems (7 paths)', () {
      final viewportPoint = const Point<double>(45.0, 8.0);

      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.mouse, 0.01, 'viewport ↔ mouse');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.screen, 0.01, 'viewport ↔ screen');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.chartArea, 0.01, 'viewport ↔ chartArea');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.data, 0.01, 'viewport ↔ data');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.dataPoint, 0.01, 'viewport ↔ dataPoint');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.marker, 0.01, 'viewport ↔ marker');
      testRoundTrip(viewportPoint, CoordinateSystem.viewport,
          CoordinateSystem.normalized, 0.01, 'viewport ↔ normalized');
    });

    test('normalized ↔ all other systems (7 paths)', () {
      final normalizedPoint = const Point<double>(0.6, 0.4);

      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.mouse, 0.01, 'normalized ↔ mouse');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.screen, 0.01, 'normalized ↔ screen');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.chartArea, 0.001, 'normalized ↔ chartArea');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.data, 0.01, 'normalized ↔ data');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.dataPoint, 0.01, 'normalized ↔ dataPoint');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.marker, 0.01, 'normalized ↔ marker');
      testRoundTrip(normalizedPoint, CoordinateSystem.normalized,
          CoordinateSystem.viewport, 0.01, 'normalized ↔ viewport');
    });

    test('transitive paths work correctly (3+ hops)', () {
      // Test complex path: dataPoint → data → viewport → chartArea → screen
      final indexPoint = const Point<double>(0.0, 1.0);

      var current = indexPoint;
      final path = [
        CoordinateSystem.dataPoint,
        CoordinateSystem.data,
        CoordinateSystem.viewport,
        CoordinateSystem.chartArea,
        CoordinateSystem.screen,
      ];

      // Forward transformation through multiple hops
      for (var i = 0; i < path.length - 1; i++) {
        current = transformer.transform(
          current,
          from: path[i],
          to: path[i + 1],
          context: context,
        );
      }

      // Reverse transformation back
      for (var i = path.length - 1; i > 0; i--) {
        current = transformer.transform(
          current,
          from: path[i],
          to: path[i - 1],
          context: context,
        );
      }

      // Should arrive back at original point
      expect(current.x, closeTo(indexPoint.x, 0.01),
          reason: 'Transitive path X round-trip');
      expect(current.y, closeTo(indexPoint.y, 0.01),
          reason: 'Transitive path Y round-trip');
    });
  });
}
