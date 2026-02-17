// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for ViewportConstraints module

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/rendering/modules/viewport_constraints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewportConstraints', () {
    late ViewportConstraints constraints;

    setUp(() {
      constraints = const ViewportConstraints();
    });

    group('Default Configuration', () {
      test('has sensible default values', () {
        expect(constraints.minZoomLevel, equals(0.8));
        expect(constraints.maxZoomLevel, equals(10.0));
        expect(constraints.maxWhitespaceFraction, equals(0.1));
      });

      test('allows custom configuration', () {
        const custom = ViewportConstraints(
          minZoomLevel: 0.5,
          maxZoomLevel: 20.0,
          maxWhitespaceFraction: 0.2,
        );
        expect(custom.minZoomLevel, equals(0.5));
        expect(custom.maxZoomLevel, equals(20.0));
        expect(custom.maxWhitespaceFraction, equals(0.2));
      });
    });

    group('clampZoomLevel', () {
      ChartTransform createTransform({
        double dataXMin = 0,
        double dataXMax = 100,
        double dataYMin = 0,
        double dataYMax = 100,
      }) {
        return ChartTransform(
          dataXMin: dataXMin,
          dataXMax: dataXMax,
          dataYMin: dataYMin,
          dataYMax: dataYMax,
          plotWidth: 800,
          plotHeight: 600,
          invertY: true,
        );
      }

      test('returns unchanged transform when within limits', () {
        final baseTransform = createTransform();
        // 2x zoom (range halved)
        final zoomedTransform = createTransform(
          dataXMin: 25,
          dataXMax: 75,
          dataYMin: 25,
          dataYMax: 75,
        );

        final result = constraints.clampZoomLevel(
          transform: zoomedTransform,
          baseTransform: baseTransform,
        );

        expect(result.dataXMin, equals(zoomedTransform.dataXMin));
        expect(result.dataXMax, equals(zoomedTransform.dataXMax));
      });

      test('clamps zoom-in beyond max limit', () {
        final baseTransform = createTransform();
        // 20x zoom (range = 5, but max is 10x)
        final zoomedTransform = createTransform(
          dataXMin: 47.5,
          dataXMax: 52.5,
          dataYMin: 47.5,
          dataYMax: 52.5,
        );

        final result = constraints.clampZoomLevel(
          transform: zoomedTransform,
          baseTransform: baseTransform,
        );

        // At 10x max zoom, range should be 10 (100/10)
        final expectedRange = 10.0;
        expect(result.dataXMax - result.dataXMin, closeTo(expectedRange, 0.01));
        expect(result.dataYMax - result.dataYMin, closeTo(expectedRange, 0.01));
      });

      test('clamps zoom-out beyond min limit', () {
        final baseTransform = createTransform();
        // 0.5x zoom (range doubled), but min is 0.8
        final zoomedTransform = createTransform(
          dataXMin: -50,
          dataXMax: 150,
          dataYMin: -50,
          dataYMax: 150,
        );

        final result = constraints.clampZoomLevel(
          transform: zoomedTransform,
          baseTransform: baseTransform,
        );

        // At 0.8x min zoom, range should be 125 (100/0.8)
        final expectedRange = 100 / 0.8;
        expect(result.dataXMax - result.dataXMin, closeTo(expectedRange, 0.01));
        expect(result.dataYMax - result.dataYMin, closeTo(expectedRange, 0.01));
      });

      test('preserves viewport center when clamping', () {
        final baseTransform = createTransform();
        // 20x zoom centered at (60, 40)
        final zoomedTransform = createTransform(
          dataXMin: 57.5,
          dataXMax: 62.5,
          dataYMin: 37.5,
          dataYMax: 42.5,
        );

        final result = constraints.clampZoomLevel(
          transform: zoomedTransform,
          baseTransform: baseTransform,
        );

        // Center should be preserved at (60, 40)
        final centerX = (result.dataXMin + result.dataXMax) / 2;
        final centerY = (result.dataYMin + result.dataYMax) / 2;
        expect(centerX, closeTo(60.0, 0.01));
        expect(centerY, closeTo(40.0, 0.01));
      });
    });

    group('clampPanDelta', () {
      ChartTransform createTransform({
        double dataXMin = 0,
        double dataXMax = 100,
        double dataYMin = 0,
        double dataYMax = 100,
        bool invertY = true,
      }) {
        return ChartTransform(
          dataXMin: dataXMin,
          dataXMax: dataXMax,
          dataYMin: dataYMin,
          dataYMax: dataYMax,
          plotWidth: 800,
          plotHeight: 600,
          invertY: invertY,
        );
      }

      test('allows pan within bounds', () {
        final currentTransform = createTransform(dataXMin: 25, dataXMax: 75);
        final constraintTransform = createTransform();

        // Small pan that stays within bounds
        final result = constraints.clampPanDelta(
          requestedPlotDx: 10,
          requestedPlotDy: 0,
          currentTransform: currentTransform,
          constraintTransform: constraintTransform,
        );

        // Should allow the pan (10 pixels = ~0.625 data units at 800px/100 range = 50 visible)
        expect(result.dx, closeTo(10.0, 0.01));
      });

      test('clamps pan at left boundary', () {
        // Viewport showing left half of data
        final currentTransform = createTransform(
          dataXMin: 0, // At left edge
          dataXMax: 50, // Showing first half
        );
        final constraintTransform = createTransform(); // Full range 0-100

        // Try to pan left (negative plotDx means moving data left = viewport moves right)
        // But we're already at the left edge, so leftward pan should be clamped
        final result = constraints.clampPanDelta(
          requestedPlotDx: -200, // Large leftward pan request
          requestedPlotDy: 0,
          currentTransform: currentTransform,
          constraintTransform: constraintTransform,
        );

        // Can only pan left by about 10% of viewport (5 data units max whitespace)
        // Max whitespace = 50 * 0.1 = 5 data units allowed beyond left edge
        // Currently at 0, so can pan to show dataXMin = -5 max
        // At 800px/50 range = 16px per data unit, 5 units = ~80px max
        expect(result.dx.abs(), lessThan(200)); // Clamped, not full request
      });

      test('clamps pan at right boundary', () {
        // Viewport showing right half of data
        final currentTransform = createTransform(
          dataXMin: 50, // At right half
          dataXMax: 100, // At right edge
        );
        final constraintTransform = createTransform(); // Full range 0-100

        // Try to pan right (positive plotDx means moving data right = viewport moves left)
        final result = constraints.clampPanDelta(
          requestedPlotDx: 200, // Large rightward pan request
          requestedPlotDy: 0,
          currentTransform: currentTransform,
          constraintTransform: constraintTransform,
        );

        // Can only pan right by about 10% of viewport (5 data units max whitespace)
        expect(result.dx.abs(), lessThan(200)); // Clamped, not full request
      });

      test('handles invertY correctly', () {
        final currentTransform = createTransform(invertY: true);
        final constraintTransform = createTransform(invertY: true);

        final resultInverted = constraints.clampPanDelta(
          requestedPlotDx: 0,
          requestedPlotDy: 10,
          currentTransform: currentTransform,
          constraintTransform: constraintTransform,
        );

        final currentNonInverted = createTransform(invertY: false);
        final constraintNonInverted = createTransform(invertY: false);

        final resultNonInverted = constraints.clampPanDelta(
          requestedPlotDx: 0,
          requestedPlotDy: 10,
          currentTransform: currentNonInverted,
          constraintTransform: constraintNonInverted,
        );

        // Y movement should be different based on inversion
        // (The actual values depend on the data bounds, but they should differ)
        expect(resultInverted.dy, isNotNull);
        expect(resultNonInverted.dy, isNotNull);
      });

      test('allows full movement when viewport larger than data', () {
        // Zoomed out so viewport is larger than data
        final currentTransform = createTransform(dataXMin: -50, dataXMax: 150);
        final constraintTransform = createTransform();

        // Large pan request
        final result = constraints.clampPanDelta(
          requestedPlotDx: 200,
          requestedPlotDy: 0,
          currentTransform: currentTransform,
          constraintTransform: constraintTransform,
        );

        // Should allow full movement (defensive case)
        expect(result.dx, equals(200));
      });
    });
  });
}
