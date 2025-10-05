/// Unit Test: Screen ↔ ChartArea Transformation
///
/// Tests translation transformation from screen coordinates to chart area.
/// ChartArea is offset from screen by the chartAreaBounds position.
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('Screen ↔ ChartArea transformation', () {
    late TransformContext context;
    late CoordinateTransformer transformer;

    setUp(() {
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540), // Offset from screen
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
      );

      transformer = UniversalCoordinateTransformer();
    });

    test('should transform screen to chartArea with translation', () {
      // Screen point at (100, 80) should be (50, 50) in chartArea
      final screenPoint = const Point<double>(100.0, 80.0);
      
      final chartPoint = transformer.transform(
        screenPoint,
        from: CoordinateSystem.screen,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      // chartArea = screen - chartAreaBounds.topLeft
      expect(chartPoint.x, closeTo(50.0, 0.01)); // 100 - 50
      expect(chartPoint.y, closeTo(50.0, 0.01)); // 80 - 30
    });

    test('should transform chartArea to screen with translation', () {
      // ChartArea point at (0, 0) should be (50, 30) in screen
      final chartPoint = const Point<double>(0.0, 0.0);
      
      final screenPoint = transformer.transform(
        chartPoint,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.screen,
        context: context,
      );

      // screen = chartArea + chartAreaBounds.topLeft
      expect(screenPoint.x, closeTo(50.0, 0.01));
      expect(screenPoint.y, closeTo(30.0, 0.01));
    });

    test('should have perfect round-trip accuracy', () {
      final originalPoint = const Point<double>(350.0, 275.0);
      
      final chartPoint = transformer.transform(
        originalPoint,
        from: CoordinateSystem.screen,
        to: CoordinateSystem.chartArea,
        context: context,
      );
      
      final roundTripPoint = transformer.transform(
        chartPoint,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.screen,
        context: context,
      );

      expect(roundTripPoint.x, closeTo(originalPoint.x, 0.01));
      expect(roundTripPoint.y, closeTo(originalPoint.y, 0.01));
    });

    test('should handle chartArea corners', () {
      // Test all four corners of chartArea
      final corners = [
        const Point<double>(0.0, 0.0),                        // Top-left
        const Point<double>(700.0, 0.0),                      // Top-right
        const Point<double>(0.0, 540.0),                      // Bottom-left
        const Point<double>(700.0, 540.0),                    // Bottom-right
      ];

      final expectedScreen = [
        const Point<double>(50.0, 30.0),                      // (0,0) + offset
        const Point<double>(750.0, 30.0),                     // (700,0) + offset
        const Point<double>(50.0, 570.0),                     // (0,540) + offset
        const Point<double>(750.0, 570.0),                    // (700,540) + offset
      ];

      for (int i = 0; i < corners.length; i++) {
        final screenPoint = transformer.transform(
          corners[i],
          from: CoordinateSystem.chartArea,
          to: CoordinateSystem.screen,
          context: context,
        );

        expect(screenPoint.x, closeTo(expectedScreen[i].x, 0.01),
            reason: 'Corner $i X coordinate');
        expect(screenPoint.y, closeTo(expectedScreen[i].y, 0.01),
            reason: 'Corner $i Y coordinate');
      }
    });

    test('should clip to chartArea bounds', () {
      // Points outside chartArea should still transform
      // (clipping is responsibility of validation, not transformation)
      final outsidePoint = const Point<double>(-10.0, -10.0);
      
      final screenPoint = transformer.transform(
        outsidePoint,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.screen,
        context: context,
      );

      expect(screenPoint.x, closeTo(40.0, 0.01)); // -10 + 50
      expect(screenPoint.y, closeTo(20.0, 0.01)); // -10 + 30
    });
  });
}
