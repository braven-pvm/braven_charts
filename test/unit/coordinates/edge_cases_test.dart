// Test: Edge cases for coordinate transformations
// Feature: 003-coordinate-system
// Task: T037 - Edge case validation
//
// Tests:
// - NaN coordinates (both x and y)
// - Infinite coordinates (both positive and negative infinity)
// - Zero widget dimensions (widgetSize.width or height == 0)
// - Zero chart area dimensions
// - Empty data range (min == max)
// - Inverted data range (min > max)
// - Negative zoom factor
// - Animation progress out of range (<0 or >1)

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:test/test.dart';

void main() {
  group('Edge Cases -', () {
    late UniversalCoordinateTransformer transformer;

    setUp(() {
      transformer = UniversalCoordinateTransformer();
    });

    group('NaN coordinates', () {
      test('should detect NaN in x coordinate', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
        );

        final result = transformer.validate(
          const Point(double.nan, 25.0),
          CoordinateSystem.data,
          context,
        );

        expect(result.isValid, isFalse);
        expect(result.errorType, ValidationErrorType.invalidValue);
        expect(result.errorMessage, contains('NaN'));
      });

      test('should detect NaN in y coordinate', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
        );

        final result = transformer.validate(
          const Point(50.0, double.nan),
          CoordinateSystem.data,
          context,
        );

        expect(result.isValid, isFalse);
        expect(result.errorType, ValidationErrorType.invalidValue);
        expect(result.errorMessage, contains('NaN'));
      });

      test('should detect NaN in both coordinates', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
        );

        final result = transformer.validate(
          const Point(double.nan, double.nan),
          CoordinateSystem.data,
          context,
        );

        expect(result.isValid, isFalse);
        expect(result.errorType, ValidationErrorType.invalidValue);
      });
    });

    group('Infinite coordinates', () {
      test('should detect positive infinity in x', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
        );

        final result = transformer.validate(
          const Point(double.infinity, 25.0),
          CoordinateSystem.data,
          context,
        );

        expect(result.isValid, isFalse);
        expect(result.errorType, ValidationErrorType.invalidValue);
        expect(result.errorMessage, contains('infinite'));
      });

      test('should detect negative infinity in y', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
        );

        final result = transformer.validate(
          const Point(50.0, double.negativeInfinity),
          CoordinateSystem.data,
          context,
        );

        expect(result.isValid, isFalse);
        expect(result.errorType, ValidationErrorType.invalidValue);
        expect(result.errorMessage, contains('infinite'));
      });
    });

    group('Zero dimensions', () {
      test('should handle zero widget width', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(0, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should handle zero widget height', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 0),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should handle zero chart area width', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 0, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should handle zero chart area height', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 0),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Invalid data ranges', () {
      test('should reject empty x data range (min == max)', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 50, max: 50),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should reject empty y data range (min == max)', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 25, max: 25),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should reject inverted x data range (min > max)', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: DataRange(min: 100, max: 0),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should reject inverted y data range (min > max)', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: DataRange(min: 50, max: 0),
            viewport: ViewportState.identity(),
            series: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Invalid viewport state', () {
      test('should reject negative zoom factor', () {
        expect(
          () => ViewportState(
            xRange: const DataRange(min: 0, max: 100),
            yRange: const DataRange(min: 0, max: 50),
            zoomFactor: -1.0,
            panOffset: const Point(0, 0),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should reject zero zoom factor', () {
        expect(
          () => ViewportState(
            xRange: const DataRange(min: 0, max: 100),
            yRange: const DataRange(min: 0, max: 50),
            zoomFactor: 0.0,
            panOffset: const Point(0, 0),
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Invalid animation progress', () {
      test('should reject animation progress < 0', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
            animationProgress: -0.1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should reject animation progress > 1', () {
        expect(
          () => TransformContext(
            widgetSize: const Size(800, 600),
            chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
            xDataRange: const DataRange(min: 0, max: 100),
            yDataRange: const DataRange(min: 0, max: 50),
            viewport: ViewportState.identity(),
            series: const [],
            animationProgress: 1.1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should accept animation progress = 0', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
          animationProgress: 0.0,
        );

        expect(context.animationProgress, 0.0);
      });

      test('should accept animation progress = 1', () {
        final context = TransformContext(
          widgetSize: const Size(800, 600),
          chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
          xDataRange: const DataRange(min: 0, max: 100),
          yDataRange: const DataRange(min: 0, max: 50),
          viewport: ViewportState.identity(),
          series: const [],
          animationProgress: 1.0,
        );

        expect(context.animationProgress, 1.0);
      });
    });
  });
}
