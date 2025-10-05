/// Unit Test: ChartArea ↔ Data Transformation
///
/// Tests scaling transformations between pixel-based chart area coordinates
/// and logical data space coordinates. This transformation handles:
/// - Scale from pixels to data units
/// - Y-axis flip (canvas Y increases downward, data Y increases upward)
/// - Data range mapping (min/max → chart area bounds)
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartArea ↔ Data transformation', () {
    late TransformContext context;
    late CoordinateTransformer transformer;

    setUp(() {
      // Chart area: 700x540 pixels
      // Data range: X [0, 100], Y [-50, 50]
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 1.0,
      );

      transformer = UniversalCoordinateTransformer();
    });

    test('should scale from chartArea pixels to data units', () {
      // Chart area origin (0, 0) should map to data min values
      final chartOrigin = const Point<double>(0.0, 0.0);

      final dataPoint = transformer.transform(
        chartOrigin,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(dataPoint.x, closeTo(0.0, 0.01), reason: 'Chart origin X should map to xDataRange.min');
      // Y-axis flip: chart area top (Y=0) maps to data max (Y=50)
      expect(dataPoint.y, closeTo(50.0, 0.01), reason: 'Chart origin Y should map to yDataRange.max (Y-flip)');
    });

    test('should handle Y-axis flip correctly', () {
      // Chart area bottom-left (0, 540) should map to data min Y
      final chartBottomLeft = const Point<double>(0.0, 540.0);

      final dataPoint = transformer.transform(
        chartBottomLeft,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(dataPoint.x, closeTo(0.0, 0.01), reason: 'X should be at min');
      expect(dataPoint.y, closeTo(-50.0, 0.01), reason: 'Chart bottom should map to data min Y');
    });

    test('should map data range min/max to chart area bounds', () {
      // Data point at (50, 0) - middle of data range
      final dataMid = const Point<double>(50.0, 0.0);

      final chartPoint = transformer.transform(
        dataMid,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      // 50 is halfway in [0, 100], so should be at X = 350 (half of 700)
      expect(chartPoint.x, closeTo(350.0, 0.01), reason: 'Data mid-X should map to chart mid-X');
      // Y=0 is center of [-50, 50], chart area Y should be at middle (270)
      expect(chartPoint.y, closeTo(270.0, 0.01), reason: 'Data mid-Y should map to chart mid-Y');
    });

    test('should have round-trip accuracy within 0.01 pixels', () {
      final originalData = const Point<double>(25.0, -10.0);

      // Data → ChartArea → Data
      final chartPoint = transformer.transform(
        originalData,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      final roundTripData = transformer.transform(
        chartPoint,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(roundTripData.x, closeTo(originalData.x, 0.01), reason: 'Round-trip X accuracy');
      expect(roundTripData.y, closeTo(originalData.y, 0.01), reason: 'Round-trip Y accuracy');
    });

    test('should handle data range corners correctly', () {
      // Data min corner (0, -50)
      final dataMin = const Point<double>(0.0, -50.0);
      final chartMin = transformer.transform(
        dataMin,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(chartMin.x, closeTo(0.0, 0.01), reason: 'Data min X → chart origin X');
      expect(chartMin.y, closeTo(540.0, 0.01), reason: 'Data min Y → chart bottom Y (Y-flip)');

      // Data max corner (100, 50)
      final dataMax = const Point<double>(100.0, 50.0);
      final chartMax = transformer.transform(
        dataMax,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(chartMax.x, closeTo(700.0, 0.01), reason: 'Data max X → chart right X');
      expect(chartMax.y, closeTo(0.0, 0.01), reason: 'Data max Y → chart top Y (Y-flip)');
    });

    test('should handle negative data ranges', () {
      // Test with all-negative data range
      final negativeContext = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: -100, max: -20),
        yDataRange: const DataRange(min: -80, max: -10),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(-60.0, -45.0);
      final chartPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: negativeContext,
      );

      // -60 is halfway in [-100, -20], should map to middle of chart
      expect(chartPoint.x, closeTo(350.0, 0.01), reason: 'Negative data X maps correctly');
      expect(chartPoint.y, closeTo(270.0, 0.01), reason: 'Negative data Y maps correctly');
    });
  });
}
