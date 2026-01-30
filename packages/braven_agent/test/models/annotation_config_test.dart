// @orchestra-task: 2
@Tags(['tdd-red'])
library;

import 'package:braven_agent/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// T008: TDD Red Phase - Agent AnnotationConfig.id field tests.
///
/// According to FR-004, annotations must have an id field that is
/// system-generated and read-only. This test verifies that AnnotationConfig
/// in the braven_agent package has an id field.
///
/// These tests use JSON serialization to verify the id field exists and
/// works correctly. They FAIL because the field doesn't exist yet.
void main() {
  group('AnnotationConfig.id field', () {
    group('id field in JSON serialization', () {
      test('toJson() should include id field when present', () {
        // Arrange: Create an annotation
        const annotation = AnnotationConfig(
          type: AnnotationType.referenceLine,
          orientation: Orientation.horizontal,
          value: 100.0,
          label: 'Target',
        );

        // Act: Serialize to JSON
        final json = annotation.toJson();

        // Assert: id field should exist in the output
        // This test FAILS because AnnotationConfig doesn't have id field
        expect(json.containsKey('id'), isTrue,
            reason: 'FR-004: annotation id must be serialized');
      });

      test('fromJson() should parse and preserve id field', () {
        // Arrange: JSON with id field
        final json = {
          'id': 'zone-001',
          'type': 'zone',
          'minValue': 50.0,
          'maxValue': 100.0,
          'color': '#00FF00',
        };

        // Act: Parse from JSON and serialize back
        final annotation = AnnotationConfig.fromJson(json);
        final outputJson = annotation.toJson();

        // Assert: id should be preserved in output
        // This test FAILS because id field is not parsed/preserved
        expect(outputJson['id'], equals('zone-001'),
            reason: 'FR-004: id must be preserved through fromJson/toJson');
      });

      test('round-trip should preserve id field', () {
        // Arrange: JSON with id
        final inputJson = {
          'id': 'marker-001',
          'type': 'marker',
          'x': 25.0,
          'y': 75.0,
          'label': 'Peak',
        };

        // Act: Round-trip through fromJson/toJson
        final annotation = AnnotationConfig.fromJson(inputJson);
        final outputJson = annotation.toJson();

        // Assert: id should be preserved
        // This test FAILS because id is not tracked
        expect(outputJson['id'], equals('marker-001'),
            reason: 'FR-004: id must survive round-trip');
      });
    });

    group('id field in copyWith', () {
      test('copyWith result should include id in serialization', () {
        // Arrange
        const original = AnnotationConfig(
          type: AnnotationType.referenceLine,
          value: 100.0,
        );

        // Act: copyWith and check serialization
        final copy = original.copyWith();
        final copyJson = copy.toJson();

        // Assert: after FR-004 implementation, id should be in output
        // This test FAILS because id field doesn't exist
        expect(copyJson.containsKey('id'), isTrue,
            reason:
                'FR-004: copyWith should preserve/allow id - id must exist');
      });
    });

    group('id field in Equatable props', () {
      test(
          'annotations from JSON with different ids should differ in serialization',
          () {
        // Arrange: Two annotations created from JSON with different ids
        final json1 = {
          'id': 'id-001',
          'type': 'referenceLine',
          'orientation': 'horizontal',
          'value': 100.0,
        };
        final json2 = {
          'id': 'id-002',
          'type': 'referenceLine',
          'orientation': 'horizontal',
          'value': 100.0,
        };

        final annotation1 = AnnotationConfig.fromJson(json1);
        final annotation2 = AnnotationConfig.fromJson(json2);

        // Assert: Their serialized output should have different ids
        // This test FAILS because id is not preserved
        final out1 = annotation1.toJson();
        final out2 = annotation2.toJson();
        expect(out1['id'], equals('id-001'),
            reason: 'FR-004: id must be preserved');
        expect(out2['id'], equals('id-002'),
            reason: 'FR-004: id must be preserved');
        expect(out1['id'], isNot(equals(out2['id'])),
            reason: 'FR-004: Different ids should be preserved');
      });
    });
  });
}
