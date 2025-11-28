/// Unit Test: Coordinate Validation
///
/// Tests the validation system for detecting invalid coordinates
/// and providing actionable error messages. Validation catches:
/// - NaN values
/// - Infinity values
/// - Out-of-range coordinates
/// - Missing context
/// - Unsupported transformation paths
///
/// Expected: FAIL until T027-T029 implement validation logic
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinate validation', () {
    late TransformContext context;
    late UniversalCoordinateTransformer transformer;

    setUp(() {
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

    test('should detect NaN coordinates', () {
      final nanPoint = const Point<double>(double.nan, 50.0);

      final validation = transformer.validate(
        nanPoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isFalse, reason: 'NaN should fail validation');
      expect(validation.errorType, equals(ValidationErrorType.invalidValue),
          reason: 'Error type should be invalidValue');
      expect(validation.errorMessage, contains('NaN'),
          reason: 'Error message should mention NaN');
    });

    test('should detect infinity coordinates', () {
      final infPoint = const Point<double>(50.0, double.infinity);

      final validation = transformer.validate(
        infPoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isFalse,
          reason: 'Infinity should fail validation');
      expect(validation.errorType, equals(ValidationErrorType.invalidValue),
          reason: 'Error type should be invalidValue');
      expect(validation.errorMessage, contains('infinite'),
          reason: 'Error message should mention infinity');
    });

    test('should detect negative infinity', () {
      final negInfPoint = const Point<double>(double.negativeInfinity, 0.0);

      final validation = transformer.validate(
        negInfPoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isFalse,
          reason: 'Negative infinity should fail validation');
      expect(validation.errorType, equals(ValidationErrorType.invalidValue));
    });

    test('should detect out-of-range data coordinates', () {
      final outOfRangePoint =
          const Point<double>(150.0, 75.0); // Beyond data range

      final validation = transformer.validate(
        outOfRangePoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isFalse,
          reason: 'Out-of-range should fail validation');
      expect(validation.errorType, equals(ValidationErrorType.outOfRange),
          reason: 'Error type should be outOfRange');
      expect(validation.errorMessage, contains('150'),
          reason: 'Error message should include actual value');
      expect(validation.errorMessage, contains('100'),
          reason: 'Error message should include max range');
    });

    test('should detect out-of-range screen coordinates', () {
      final outOfScreenPoint =
          const Point<double>(1000.0, 50.0); // Beyond widget bounds

      final validation = transformer.validate(
        outOfScreenPoint,
        CoordinateSystem.screen,
        context,
      );

      expect(validation.isValid, isFalse,
          reason: 'Out-of-screen should fail validation');
      expect(validation.errorType, equals(ValidationErrorType.outOfRange));
    });

    test('should detect out-of-range normalized coordinates', () {
      final outOfNormalizedPoint = const Point<double>(1.5, -0.2);

      final validation = transformer.validate(
        outOfNormalizedPoint,
        CoordinateSystem.normalized,
        context,
      );

      expect(validation.isValid, isFalse,
          reason: 'Normalized coords outside [0,1] should fail');
      expect(validation.errorType, equals(ValidationErrorType.outOfRange));
    });

    test('should provide actionable error messages', () {
      final invalidPoint = const Point<double>(120.0, -60.0);

      final validation = transformer.validate(
        invalidPoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isFalse);
      // Error message should include:
      // - Actual value
      // - Expected range
      // - Suggestion for fixing
      expect(validation.errorMessage, contains('120'),
          reason: 'Include actual X value');
      expect(validation.errorMessage, contains('-60'),
          reason: 'Include actual Y value');
      expect(validation.errorMessage, isNot(isEmpty),
          reason: 'Error message should not be empty');
    });

    test('should validate correct coordinates as valid', () {
      final validPoint = const Point<double>(50.0, 0.0);

      final validation = transformer.validate(
        validPoint,
        CoordinateSystem.data,
        context,
      );

      expect(validation.isValid, isTrue,
          reason: 'Valid point should pass validation');
      expect(validation.errorMessage, isEmpty,
          reason: 'Valid point should have no error message');
    });

    test('should validate edge case coordinates', () {
      // Data range min
      final minPoint = const Point<double>(0.0, -50.0);
      var validation =
          transformer.validate(minPoint, CoordinateSystem.data, context);
      expect(validation.isValid, isTrue,
          reason: 'Data range min should be valid');

      // Data range max
      final maxPoint = const Point<double>(100.0, 50.0);
      validation =
          transformer.validate(maxPoint, CoordinateSystem.data, context);
      expect(validation.isValid, isTrue,
          reason: 'Data range max should be valid');

      // Normalized 0.0
      final normalizedZero = const Point<double>(0.0, 0.0);
      validation = transformer.validate(
          normalizedZero, CoordinateSystem.normalized, context);
      expect(validation.isValid, isTrue,
          reason: 'Normalized 0.0 should be valid');

      // Normalized 1.0
      final normalizedOne = const Point<double>(1.0, 1.0);
      validation = transformer.validate(
          normalizedOne, CoordinateSystem.normalized, context);
      expect(validation.isValid, isTrue,
          reason: 'Normalized 1.0 should be valid');
    });

    test('should handle getValidRange for all coordinate systems', () {
      // Data range
      final dataRange =
          transformer.getValidRange(CoordinateSystem.data, context);
      expect(dataRange.left, closeTo(0.0, 0.01), reason: 'Data range min X');
      expect(dataRange.top, closeTo(-50.0, 0.01), reason: 'Data range min Y');
      expect(dataRange.right, closeTo(100.0, 0.01), reason: 'Data range max X');
      expect(dataRange.bottom, closeTo(50.0, 0.01), reason: 'Data range max Y');

      // Screen range
      final screenRange =
          transformer.getValidRange(CoordinateSystem.screen, context);
      expect(screenRange.right, closeTo(800.0, 0.01), reason: 'Screen width');
      expect(screenRange.bottom, closeTo(600.0, 0.01), reason: 'Screen height');

      // Normalized range
      final normalizedRange =
          transformer.getValidRange(CoordinateSystem.normalized, context);
      expect(normalizedRange.left, closeTo(0.0, 0.01));
      expect(normalizedRange.top, closeTo(0.0, 0.01));
      expect(normalizedRange.right, closeTo(1.0, 0.01));
      expect(normalizedRange.bottom, closeTo(1.0, 0.01));
    });
  });
}
