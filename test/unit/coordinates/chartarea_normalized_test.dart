/// Unit Test: ChartArea ↔ Normalized Transformation
///
/// Tests transformations between chart area pixels and normalized
/// coordinates (0.0-1.0). Normalized coords are useful for percentage-
/// based positioning (e.g., "place legend at 80% of chart width").
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartArea ↔ Normalized transformation', () {
    late TransformContext context;
    late CoordinateTransformer transformer;

    setUp(() {
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540), // 700x540
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 1.0,
      );

      transformer = UniversalCoordinateTransformer();
    });

    test('should scale chartArea to 0.0-1.0 range', () {
      // Chart area origin (0, 0) → normalized (0.0, 0.0)
      final chartOrigin = const Point<double>(0.0, 0.0);

      final normalized = transformer.transform(
        chartOrigin,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.normalized,
        context: context,
      );

      expect(normalized.x, closeTo(0.0, 0.001), reason: 'Chart origin X → normalized 0.0');
      expect(normalized.y, closeTo(0.0, 0.001), reason: 'Chart origin Y → normalized 0.0');
    });

    test('should handle corner case (1.0, 1.0)', () {
      // Chart area max (700, 540) → normalized (1.0, 1.0)
      final chartMax = const Point<double>(700.0, 540.0);

      final normalized = transformer.transform(
        chartMax,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.normalized,
        context: context,
      );

      expect(normalized.x, closeTo(1.0, 0.001), reason: 'Chart max X → normalized 1.0');
      expect(normalized.y, closeTo(1.0, 0.001), reason: 'Chart max Y → normalized 1.0');
    });

    test('should map mid-point (0.5, 0.5) to chart area center', () {
      // Normalized (0.5, 0.5) → chart area center (350, 270)
      final normalizedMid = const Point<double>(0.5, 0.5);

      final chartPoint = transformer.transform(
        normalizedMid,
        from: CoordinateSystem.normalized,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(chartPoint.x, closeTo(350.0, 0.01), reason: 'Normalized 0.5 X → chart center X');
      expect(chartPoint.y, closeTo(270.0, 0.01), reason: 'Normalized 0.5 Y → chart center Y');
    });

    test('should have round-trip accuracy', () {
      final originalChart = const Point<double>(175.0, 135.0); // Quarter point

      // ChartArea → Normalized → ChartArea
      final normalized = transformer.transform(
        originalChart,
        from: CoordinateSystem.chartArea,
        to: CoordinateSystem.normalized,
        context: context,
      );

      final roundTripChart = transformer.transform(
        normalized,
        from: CoordinateSystem.normalized,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(roundTripChart.x, closeTo(originalChart.x, 0.01), reason: 'Round-trip X accuracy');
      expect(roundTripChart.y, closeTo(originalChart.y, 0.01), reason: 'Round-trip Y accuracy');
    });

    test('should handle percentage-based positioning', () {
      // 80% width, 20% height → (560, 108)
      final normalized80x20 = const Point<double>(0.8, 0.2);

      final chartPoint = transformer.transform(
        normalized80x20,
        from: CoordinateSystem.normalized,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(chartPoint.x, closeTo(560.0, 0.01), reason: '80% of width = 0.8 * 700');
      expect(chartPoint.y, closeTo(108.0, 0.01), reason: '20% of height = 0.2 * 540');
    });

    test('should validate out-of-range normalized coordinates', () {
      // Normalized values outside [0.0, 1.0] should still transform
      // but validation should catch them
      final outOfRange = const Point<double>(1.5, -0.3);

      // Transformation should work (extrapolate)
      final chartPoint = transformer.transform(
        outOfRange,
        from: CoordinateSystem.normalized,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      expect(chartPoint.x, closeTo(1050.0, 0.01), reason: '1.5 * 700 = 1050');
      expect(chartPoint.y, closeTo(-162.0, 0.01), reason: '-0.3 * 540 = -162');

      // But validation should report it as out of range
      final validation = transformer.validate(
        outOfRange,
        CoordinateSystem.normalized,
        context,
      );

      expect(validation.isValid, isFalse, reason: 'Out-of-range normalized coords should fail validation');
    });
  });
}
