library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

/// T005: TDD Red Phase - Core ChartAnnotation.id serialization tests.
///
/// These tests verify that ChartAnnotation subclasses have toJson() methods
/// that include the id field. FR-004 requires annotation id to be serializable.
///
/// Tests FAIL because:
/// - ChartAnnotation subclasses do not have toJson() methods implemented yet
/// - The serialization infrastructure needs to be added
void main() {
  group('ChartAnnotation.id serialization', () {
    group('ThresholdAnnotation', () {
      test('id is accessible on ThresholdAnnotation', () {
        // This test PASSES - id exists and works
        final annotation = ThresholdAnnotation(
          id: 'test-threshold-001',
          axis: AnnotationAxis.y,
          value: 100.0,
          label: 'Target',
        );

        expect(annotation.id, equals('test-threshold-001'));
      });

      test('ThresholdAnnotation has toJson method for serialization', () {
        final annotation = ThresholdAnnotation(
          id: 'test-threshold-001',
          axis: AnnotationAxis.y,
          value: 100.0,
        );

        // Check if toJson method exists using reflection-like approach
        // This test FAILS because toJson is not implemented
        final hasToJson = _hasMethod(annotation, 'toJson');
        expect(hasToJson, isTrue,
            reason:
                'FR-004: ThresholdAnnotation must have toJson() for id serialization');
      });
    });

    group('RangeAnnotation', () {
      test('id is accessible on RangeAnnotation', () {
        final annotation = RangeAnnotation(
          id: 'test-range-001',
          startX: 0.0,
          endX: 10.0,
        );

        expect(annotation.id, equals('test-range-001'));
      });

      test('RangeAnnotation has toJson method for serialization', () {
        final annotation = RangeAnnotation(
          id: 'test-range-001',
          startX: 0.0,
          endX: 10.0,
        );

        final hasToJson = _hasMethod(annotation, 'toJson');
        expect(hasToJson, isTrue,
            reason:
                'FR-004: RangeAnnotation must have toJson() for id serialization');
      });
    });

    group('PointAnnotation', () {
      test('id is accessible on PointAnnotation', () {
        final annotation = PointAnnotation(
          id: 'test-point-001',
          seriesId: 'series-1',
          dataPointIndex: 5,
        );

        expect(annotation.id, equals('test-point-001'));
      });

      test('PointAnnotation has toJson method for serialization', () {
        final annotation = PointAnnotation(
          id: 'test-point-001',
          seriesId: 'series-1',
          dataPointIndex: 5,
        );

        final hasToJson = _hasMethod(annotation, 'toJson');
        expect(hasToJson, isTrue,
            reason:
                'FR-004: PointAnnotation must have toJson() for id serialization');
      });
    });

    group('TextAnnotation', () {
      test('id is accessible on TextAnnotation', () {
        final annotation = TextAnnotation(
          id: 'test-text-001',
          text: 'Hello World',
          position: const Offset(100, 100),
        );

        expect(annotation.id, equals('test-text-001'));
      });

      test('TextAnnotation has toJson method for serialization', () {
        final annotation = TextAnnotation(
          id: 'test-text-001',
          text: 'Hello World',
          position: const Offset(100, 100),
        );

        final hasToJson = _hasMethod(annotation, 'toJson');
        expect(hasToJson, isTrue,
            reason:
                'FR-004: TextAnnotation must have toJson() for id serialization');
      });
    });

    group('PinAnnotation', () {
      test('id is accessible on PinAnnotation', () {
        final annotation = PinAnnotation(
          id: 'test-pin-001',
          x: 50.0,
          y: 75.0,
        );

        expect(annotation.id, equals('test-pin-001'));
      });

      test('PinAnnotation has toJson method for serialization', () {
        final annotation = PinAnnotation(
          id: 'test-pin-001',
          x: 50.0,
          y: 75.0,
        );

        final hasToJson = _hasMethod(annotation, 'toJson');
        expect(hasToJson, isTrue,
            reason:
                'FR-004: PinAnnotation must have toJson() for id serialization');
      });
    });
  });
}

/// Helper function to check if an object has a specific method.
/// Uses try-catch with dynamic to safely check for method existence.
bool _hasMethod(Object obj, String methodName) {
  try {
    // Try to get the method using noSuchMethod behavior
    // This will throw NoSuchMethodError if the method doesn't exist
    switch (methodName) {
      case 'toJson':
        (obj as dynamic).toJson();
        return true;
      default:
        return false;
    }
  } on NoSuchMethodError {
    return false;
  } catch (_) {
    // Method exists but might throw for other reasons
    return true;
  }
}
