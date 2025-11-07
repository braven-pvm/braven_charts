// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for ChartTransform

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interaction_prototype/transforms/chart_transform.dart';

void main() {
  group('ChartTransform - Construction', () {
    test('creates with valid parameters', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.dataXMin, 0);
      expect(transform.dataXMax, 100);
      expect(transform.dataYMin, 0);
      expect(transform.dataYMax, 50);
      expect(transform.plotWidth, 800);
      expect(transform.plotHeight, 600);
      expect(transform.invertY, true); // default
    });

    test('creates with invertY false', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: false,
      );

      expect(transform.invertY, false);
    });

    test('computes data ranges correctly', () {
      final transform = ChartTransform(
        dataXMin: 10,
        dataXMax: 110,
        dataYMin: -20,
        dataYMax: 30,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.dataXRange, 100);
      expect(transform.dataYRange, 50);
    });

    test('computes pixels per data unit correctly', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.pixelsPerDataX, 8.0); // 800 / 100
      expect(transform.pixelsPerDataY, 12.0); // 600 / 50
    });

    test('computes data per pixel correctly', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.dataPerPixelX, 0.125); // 100 / 800
      expect(transform.dataPerPixelY, closeTo(0.0833, 0.0001)); // 50 / 600
    });
  });

  group('ChartTransform - Data to Plot Conversion', () {
    test('converts data min to plot origin', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(0, 0);
      expect(result.dx, 0);
      expect(result.dy, 600); // inverted Y, so dataYMin → plotHeight
    });

    test('converts data max to plot bounds', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(100, 50);
      expect(result.dx, 800);
      expect(result.dy, 0); // inverted Y, so dataYMax → 0
    });

    test('converts data center point correctly', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(50, 25);
      expect(result.dx, 400);
      expect(result.dy, 300); // inverted Y
    });

    test('handles non-zero data ranges', () {
      final transform = ChartTransform(
        dataXMin: 100,
        dataXMax: 200,
        dataYMin: -50,
        dataYMax: 50,
        plotWidth: 1000,
        plotHeight: 500,
      );

      final result = transform.dataToPlot(150, 0);
      expect(result.dx, 500); // midpoint
      expect(result.dy, 250); // midpoint with inversion
    });

    test('respects invertY false', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: false,
      );

      final resultMin = transform.dataToPlot(0, 0);
      expect(resultMin.dx, 0);
      expect(resultMin.dy, 0); // NOT inverted

      final resultMax = transform.dataToPlot(100, 50);
      expect(resultMax.dx, 800);
      expect(resultMax.dy, 600); // NOT inverted
    });

    test('handles negative data values', () {
      final transform = ChartTransform(
        dataXMin: -50,
        dataXMax: 50,
        dataYMin: -100,
        dataYMax: 100,
        plotWidth: 1000,
        plotHeight: 800,
      );

      final result = transform.dataToPlot(0, 0);
      expect(result.dx, 500); // center
      expect(result.dy, 400); // center with inversion
    });

    test('converts list of data points', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final dataPoints = [
        const Offset(0, 0),
        const Offset(50, 25),
        const Offset(100, 50),
      ];

      final plotPoints = transform.dataPointsToPlot(dataPoints);

      expect(plotPoints.length, 3);
      expect(plotPoints[0], const Offset(0, 600));
      expect(plotPoints[1], const Offset(400, 300));
      expect(plotPoints[2], const Offset(800, 0));
    });
  });

  group('ChartTransform - Plot to Data Conversion', () {
    test('converts plot origin to data min', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.plotToData(0, 600);
      expect(result.dx, 0);
      expect(result.dy, 0);
    });

    test('converts plot bounds to data max', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.plotToData(800, 0);
      expect(result.dx, 100);
      expect(result.dy, 50);
    });

    test('is inverse of dataToPlot', () {
      final transform = ChartTransform(
        dataXMin: 10,
        dataXMax: 110,
        dataYMin: -20,
        dataYMax: 30,
        plotWidth: 1000,
        plotHeight: 800,
      );

      const testDataX = 45.5;
      const testDataY = 12.3;

      final plotPoint = transform.dataToPlot(testDataX, testDataY);
      final dataPoint = transform.plotToData(plotPoint.dx, plotPoint.dy);

      expect(dataPoint.dx, closeTo(testDataX, 0.0001));
      expect(dataPoint.dy, closeTo(testDataY, 0.0001));
    });

    test('respects invertY false', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: false,
      );

      final result = transform.plotToData(400, 300);
      expect(result.dx, 50);
      expect(result.dy, 25); // NOT inverted
    });

    test('converts list of plot points', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final plotPoints = [
        const Offset(0, 600),
        const Offset(400, 300),
        const Offset(800, 0),
      ];

      final dataPoints = transform.plotPointsToData(plotPoints);

      expect(dataPoints.length, 3);
      expect(dataPoints[0], const Offset(0, 0));
      expect(dataPoints[1], const Offset(50, 25));
      expect(dataPoints[2], const Offset(100, 50));
    });
  });

  group('ChartTransform - Rect Conversions', () {
    test('converts data rect to plot rect', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      const dataRect = Rect.fromLTWH(25, 10, 50, 20);
      final plotRect = transform.dataRectToPlot(dataRect);

      // Left: 25 → 200, Top: 30 (10+20) → 240 (inverted)
      // Width: 50 → 400, Height: 20 → 240
      expect(plotRect.left, 200);
      expect(plotRect.top, 240);
      expect(plotRect.width, 400);
      expect(plotRect.height, 240);
    });

    test('converts plot rect to data rect', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      const plotRect = Rect.fromLTWH(200, 240, 400, 240);
      final dataRect = transform.plotRectToData(plotRect);

      expect(dataRect.left, closeTo(25, 0.0001));
      expect(dataRect.top, closeTo(10, 0.0001));
      expect(dataRect.width, closeTo(50, 0.0001));
      expect(dataRect.height, closeTo(20, 0.0001));
    });

    test('rect conversions are inverse operations', () {
      final transform = ChartTransform(
        dataXMin: 10,
        dataXMax: 110,
        dataYMin: -20,
        dataYMax: 30,
        plotWidth: 1000,
        plotHeight: 800,
      );

      const originalRect = Rect.fromLTWH(35.5, -5.2, 25.8, 18.3);

      final plotRect = transform.dataRectToPlot(originalRect);
      final dataRect = transform.plotRectToData(plotRect);

      expect(dataRect.left, closeTo(originalRect.left, 0.0001));
      expect(dataRect.top, closeTo(originalRect.top, 0.0001));
      expect(dataRect.width, closeTo(originalRect.width, 0.0001));
      expect(dataRect.height, closeTo(originalRect.height, 0.0001));
    });
  });

  group('ChartTransform - Zoom Operations', () {
    test('zoom in by 2x preserves center point', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      const plotCenter = Offset(400, 300); // plot center
      final zoomed = transform.zoom(2.0, plotCenter);

      // Data center was (50, 25), should remain at same plot position
      final centerAfterZoom = zoomed.dataToPlot(50, 25);
      expect(centerAfterZoom.dx, closeTo(400, 0.1));
      expect(centerAfterZoom.dy, closeTo(300, 0.1));

      // Data range should halve
      expect(zoomed.dataXRange, closeTo(50, 0.0001));
      expect(zoomed.dataYRange, closeTo(25, 0.0001));
    });

    test('zoom out by 0.5x preserves center point', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      const plotCenter = Offset(400, 300);
      final zoomed = transform.zoom(0.5, plotCenter);

      // Data center should remain at same plot position
      final centerAfterZoom = zoomed.dataToPlot(50, 25);
      expect(centerAfterZoom.dx, closeTo(400, 0.1));
      expect(centerAfterZoom.dy, closeTo(300, 0.1));

      // Data range should double
      expect(zoomed.dataXRange, closeTo(200, 0.0001));
      expect(zoomed.dataYRange, closeTo(100, 0.0001));
    });

    test('zoom at off-center point preserves that point', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Zoom at 75% right, 25% down
      const plotPoint = Offset(600, 150);
      final dataPoint = transform.plotToData(600, 150); // (75, 37.5)

      final zoomed = transform.zoom(2.0, plotPoint);

      // That data point should remain at same plot position
      final pointAfterZoom = zoomed.dataToPlot(dataPoint.dx, dataPoint.dy);
      expect(pointAfterZoom.dx, closeTo(600, 0.1));
      expect(pointAfterZoom.dy, closeTo(150, 0.1));
    });

    test('zoom factor of 1.0 produces identical transform', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final zoomed = transform.zoom(1.0, const Offset(400, 300));

      expect(zoomed.dataXMin, closeTo(transform.dataXMin, 0.0001));
      expect(zoomed.dataXMax, closeTo(transform.dataXMax, 0.0001));
      expect(zoomed.dataYMin, closeTo(transform.dataYMin, 0.0001));
      expect(zoomed.dataYMax, closeTo(transform.dataYMax, 0.0001));
    });
  });

  group('ChartTransform - Pan Operations', () {
    test('pan right shifts data window left', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Pan 100 pixels right (12.5 data units right at 0.125 data/pixel)
      final panned = transform.pan(100, 0);

      expect(panned.dataXMin, closeTo(12.5, 0.0001));
      expect(panned.dataXMax, closeTo(112.5, 0.0001));
      expect(panned.dataYMin, 0); // unchanged
      expect(panned.dataYMax, 50); // unchanged
    });

    test('pan down shifts data window up (with Y inversion)', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Pan 120 pixels down (10 data units down at ~0.0833 data/pixel, inverted)
      final panned = transform.pan(0, 120);

      expect(panned.dataXMin, 0); // unchanged
      expect(panned.dataXMax, 100); // unchanged
      expect(panned.dataYMin, closeTo(-10, 0.0001)); // shifted down
      expect(panned.dataYMax, closeTo(40, 0.0001)); // shifted down
    });

    test('pan respects invertY false', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: false,
      );

      final panned = transform.pan(0, 120);

      expect(panned.dataYMin, closeTo(10, 0.0001)); // shifted up (no inversion)
      expect(panned.dataYMax, closeTo(60, 0.0001));
    });

    test('pan diagonal shifts both axes', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final panned = transform.pan(200, 60);

      expect(panned.dataXMin, closeTo(25, 0.0001));
      expect(panned.dataXMax, closeTo(125, 0.0001));
      expect(panned.dataYMin, closeTo(-5, 0.0001));
      expect(panned.dataYMax, closeTo(45, 0.0001));
    });

    test('pan by zero produces identical transform', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final panned = transform.pan(0, 0);

      expect(panned.dataXMin, transform.dataXMin);
      expect(panned.dataXMax, transform.dataXMax);
      expect(panned.dataYMin, transform.dataYMin);
      expect(panned.dataYMax, transform.dataYMax);
    });
  });

  group('ChartTransform - Visibility Queries', () {
    test('identifies visible data point', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.isDataPointVisible(50, 25), true);
      expect(transform.isDataPointVisible(0, 0), true);
      expect(transform.isDataPointVisible(100, 50), true);
    });

    test('identifies invisible data point', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform.isDataPointVisible(-10, 25), false);
      expect(transform.isDataPointVisible(110, 25), false);
      expect(transform.isDataPointVisible(50, -10), false);
      expect(transform.isDataPointVisible(50, 60), false);
    });

    test('identifies visible data rect', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Fully inside
      expect(transform.isDataRectVisible(const Rect.fromLTWH(25, 10, 50, 30)), true);

      // Partially overlapping
      expect(transform.isDataRectVisible(const Rect.fromLTWH(-10, 20, 30, 20)), true);
      expect(transform.isDataRectVisible(const Rect.fromLTWH(80, 40, 40, 20)), true);
    });

    test('identifies invisible data rect', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Completely outside
      expect(transform.isDataRectVisible(const Rect.fromLTWH(-50, 20, 30, 20)), false);
      expect(transform.isDataRectVisible(const Rect.fromLTWH(120, 20, 30, 20)), false);
      expect(transform.isDataRectVisible(const Rect.fromLTWH(50, -30, 30, 20)), false);
      expect(transform.isDataRectVisible(const Rect.fromLTWH(50, 60, 30, 20)), false);
    });

    test('computes visible data bounds', () {
      final transform = ChartTransform(
        dataXMin: 10,
        dataXMax: 110,
        dataYMin: -20,
        dataYMax: 30,
        plotWidth: 1000,
        plotHeight: 800,
      );

      final bounds = transform.visibleDataBounds;

      expect(bounds.left, 10);
      expect(bounds.right, 110);
      expect(bounds.top, -20);
      expect(bounds.bottom, 30);
    });
  });

  group('ChartTransform - copyWith', () {
    test('creates new instance with updated data ranges', () {
      final original = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final modified = original.copyWith(
        dataXMin: 10,
        dataXMax: 90,
      );

      expect(modified.dataXMin, 10);
      expect(modified.dataXMax, 90);
      expect(modified.dataYMin, 0); // unchanged
      expect(modified.dataYMax, 50); // unchanged
      expect(modified.plotWidth, 800); // unchanged
      expect(modified.plotHeight, 600); // unchanged
    });

    test('creates new instance with updated plot dimensions', () {
      final original = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final modified = original.copyWith(
        plotWidth: 1000,
        plotHeight: 800,
      );

      expect(modified.plotWidth, 1000);
      expect(modified.plotHeight, 800);
      expect(modified.dataXMin, 0); // unchanged
      expect(modified.dataYMin, 0); // unchanged
    });

    test('creates new instance with inverted Y', () {
      final original = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: true,
      );

      final modified = original.copyWith(invertY: false);

      expect(modified.invertY, false);
    });

    test('with no parameters returns equal instance', () {
      final original = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final copy = original.copyWith();

      expect(copy, original);
    });
  });

  group('ChartTransform - Equality and HashCode', () {
    test('equal transforms have same hashCode', () {
      final transform1 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final transform2 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      expect(transform1, transform2);
      expect(transform1.hashCode, transform2.hashCode);
    });

    test('different transforms are not equal', () {
      final transform1 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final transform2 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 1000, // different
        plotHeight: 600,
      );

      expect(transform1, isNot(transform2));
    });

    test('different invertY values are not equal', () {
      final transform1 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: true,
      );

      final transform2 = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
        invertY: false,
      );

      expect(transform1, isNot(transform2));
    });
  });

  group('ChartTransform - Edge Cases', () {
    test('handles very small data ranges', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 0.1,
        dataYMin: 0,
        dataYMax: 0.05,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(0.05, 0.025);
      expect(result.dx, 400);
      expect(result.dy, 300);
    });

    test('handles very large data ranges', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 1000000,
        dataYMin: 0,
        dataYMax: 500000,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(500000, 250000);
      expect(result.dx, 400);
      expect(result.dy, 300);
    });

    test('handles negative to positive data ranges', () {
      final transform = ChartTransform(
        dataXMin: -100,
        dataXMax: 100,
        dataYMin: -50,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final result = transform.dataToPlot(0, 0);
      expect(result.dx, 400); // center
      expect(result.dy, 300); // center
    });

    test('handles timestamp-like large numbers', () {
      // Unix timestamp range (1 day in milliseconds)
      final transform = ChartTransform(
        dataXMin: 1704067200000, // Jan 1, 2024 00:00:00
        dataXMax: 1704153600000, // Jan 2, 2024 00:00:00
        dataYMin: 100,
        dataYMax: 200,
        plotWidth: 800,
        plotHeight: 600,
      );

      // Midpoint timestamp
      final midTimestamp = 1704110400000.0; // Jan 1, 2024 12:00:00
      final result = transform.dataToPlot(midTimestamp, 150);

      expect(result.dx, closeTo(400, 0.1));
      expect(result.dy, closeTo(300, 0.1));
    });

    test('maintains precision with fractional coordinates', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      const dataX = 33.333333;
      const dataY = 16.666666;

      final plotPoint = transform.dataToPlot(dataX, dataY);
      final backToData = transform.plotToData(plotPoint.dx, plotPoint.dy);

      expect(backToData.dx, closeTo(dataX, 0.0001));
      expect(backToData.dy, closeTo(dataY, 0.0001));
    });
  });

  group('ChartTransform - toString', () {
    test('produces readable string representation', () {
      final transform = ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 50,
        plotWidth: 800,
        plotHeight: 600,
      );

      final str = transform.toString();

      expect(str, contains('ChartTransform'));
      expect(str, contains('dataX: [0.0, 100.0]'));
      expect(str, contains('dataY: [0.0, 50.0]'));
      expect(str, contains('plot: 800.0×600.0'));
      expect(str, contains('invertY: true'));
    });
  });
}
