/// Contract Test: CoordinateSystem Enum
///
/// Verifies that the CoordinateSystem enum matches the contract specification:
/// - Exactly 8 enum values
/// - All expected values present
/// - Exhaustive switch compiles
///
/// Expected: FAIL until T020 implements the enum
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateSystem enum contract', () {
    test('should have exactly 8 coordinate systems', () {
      // Contract requirement: 8 coordinate systems
      expect(CoordinateSystem.values.length, equals(8), reason: 'Must have exactly 8 coordinate systems as per spec');
    });

    test('should contain all required coordinate systems', () {
      // Contract requirement: Specific named systems
      final values = CoordinateSystem.values;

      expect(values, contains(CoordinateSystem.mouse), reason: 'mouse system required for event coordinates');
      expect(values, contains(CoordinateSystem.screen), reason: 'screen system required for widget pixels');
      expect(values, contains(CoordinateSystem.chartArea), reason: 'chartArea system required for plot area');
      expect(values, contains(CoordinateSystem.data), reason: 'data system required for logical data space');
      expect(values, contains(CoordinateSystem.dataPoint), reason: 'dataPoint system required for series indices');
      expect(values, contains(CoordinateSystem.marker), reason: 'marker system required for annotations');
      expect(values, contains(CoordinateSystem.viewport), reason: 'viewport system required for zoom/pan');
      expect(values, contains(CoordinateSystem.normalized), reason: 'normalized system required for percentage layout');
    });

    test('should support exhaustive switch', () {
      // Contract requirement: Exhaustive switch must compile
      // This tests that all enum values can be handled in a switch

      String getDescription(CoordinateSystem system) {
        switch (system) {
          case CoordinateSystem.mouse:
            return 'Raw event coordinates';
          case CoordinateSystem.screen:
            return 'Screen pixels';
          case CoordinateSystem.chartArea:
            return 'Chart drawing area';
          case CoordinateSystem.data:
            return 'Logical data space';
          case CoordinateSystem.dataPoint:
            return 'Series indices';
          case CoordinateSystem.marker:
            return 'Annotation positioning';
          case CoordinateSystem.viewport:
            return 'Zoom/pan adjusted';
          case CoordinateSystem.normalized:
            return 'Percentage layout';
        }
      }

      // Verify all systems have descriptions
      for (final system in CoordinateSystem.values) {
        expect(getDescription(system), isNotEmpty, reason: 'All coordinate systems must be handled in switch');
      }
    });

    test('should have stable enum values', () {
      // Contract requirement: Enum values should be stable
      // Order matters for serialization and backward compatibility

      final expectedOrder = [
        CoordinateSystem.mouse,
        CoordinateSystem.screen,
        CoordinateSystem.chartArea,
        CoordinateSystem.data,
        CoordinateSystem.dataPoint,
        CoordinateSystem.marker,
        CoordinateSystem.viewport,
        CoordinateSystem.normalized,
      ];

      expect(CoordinateSystem.values, equals(expectedOrder), reason: 'Enum order must be stable for backward compatibility');
    });

    test('should have meaningful toString representations', () {
      // Contract requirement: Useful debugging strings

      expect(CoordinateSystem.mouse.toString(), contains('mouse'));
      expect(CoordinateSystem.screen.toString(), contains('screen'));
      expect(CoordinateSystem.chartArea.toString(), contains('chartArea'));
      expect(CoordinateSystem.data.toString(), contains('data'));
      expect(CoordinateSystem.dataPoint.toString(), contains('dataPoint'));
      expect(CoordinateSystem.marker.toString(), contains('marker'));
      expect(CoordinateSystem.viewport.toString(), contains('viewport'));
      expect(CoordinateSystem.normalized.toString(), contains('normalized'));
    });
  });
}
