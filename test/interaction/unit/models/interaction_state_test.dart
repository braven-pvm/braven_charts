// Unit Test: InteractionState Model
// Feature: Layer 7 Interaction System
// Task: T008
// Status: Implementation complete, tests aligned

import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/src/interaction/models/gesture_details.dart';
import 'package:braven_charts/src/interaction/models/interaction_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to convert ChartDataPoint to Map<String, dynamic>
Map<String, dynamic> pointToMap(ChartDataPoint point) {
  return {
    'x': point.x,
    'y': point.y,
    if (point.timestamp != null)
      'timestamp': point.timestamp!.toIso8601String(),
    if (point.label != null) 'label': point.label,
    if (point.metadata != null) ...point.metadata!,
  };
}

void main() {
  group('InteractionState Model Tests', () {
    test('InteractionState.initial() creates default state', () {
      final state = InteractionState.initial();

      expect(state.hoveredPoint, isNull);
      expect(state.hoveredSeriesId, isNull);
      expect(state.focusedPoint, isNull);
      expect(state.focusedPointIndex, equals(-1));
      expect(state.selectedPoints, isEmpty);
      expect(state.crosshairPosition, isNull);
      expect(state.snapPoints, isEmpty);
      expect(state.isCrosshairVisible, isFalse);
      expect(state.isTooltipVisible, isFalse);
      expect(state.tooltipPosition, isNull);
      expect(state.tooltipDataPoint, isNull);
      expect(state.activeGesture, isNull);
      expect(state.lastUpdated, isNotNull);
    });

    test('copyWith() creates new instance with updated fields', () {
      final initial = InteractionState.initial();
      final updated = initial.copyWith(
        isCrosshairVisible: true,
        crosshairPosition: const Offset(100, 200),
      );

      expect(updated.isCrosshairVisible, isTrue);
      expect(updated.crosshairPosition, equals(const Offset(100, 200)));

      // Other fields should remain unchanged
      expect(updated.hoveredPoint, equals(initial.hoveredPoint));
      expect(updated.isTooltipVisible, equals(initial.isTooltipVisible));
    });

    test('hasHoveredPoint returns true when hoveredPoint is not null', () {
      final mockPoint = const ChartDataPoint(x: 1.0, y: 10.0);
      final state = InteractionState.initial().copyWith(
        hoveredPoint: pointToMap(mockPoint),
      );

      expect(state.hasHoveredPoint, isTrue);
    });

    test('hasHoveredPoint returns false when hoveredPoint is null', () {
      final state = InteractionState.initial();

      expect(state.hasHoveredPoint, isFalse);
    });

    test('hasFocusedPoint returns true when focusedPoint is not null', () {
      final mockPoint = const ChartDataPoint(x: 2.0, y: 20.0);
      final state = InteractionState.initial().copyWith(
        focusedPoint: pointToMap(mockPoint),
      );

      expect(state.hasFocusedPoint, isTrue);
    });

    test('activeGesture can be set and retrieved', () {
      final mockGesture = GestureDetails.tap(
        position: const Offset(100, 100),
        timestamp: DateTime.now(),
      );
      final state = InteractionState.initial().copyWith(
        activeGesture: mockGesture,
      );

      expect(state.activeGesture, isNotNull);
      expect(state.activeGesture, equals(mockGesture));
    });

    test('validation: isCrosshairVisible=true can have null crosshairPosition',
        () {
      // Note: InteractionState doesn't validate this - it's allowed
      final state = InteractionState.initial().copyWith(
        isCrosshairVisible: true,
        crosshairPosition: null,
      );
      expect(state.isCrosshairVisible, isTrue);
      expect(state.crosshairPosition, isNull);
    });

    test('validation: isTooltipVisible=true can have null tooltip data', () {
      // Note: InteractionState doesn't validate this - it's allowed
      final state = InteractionState.initial().copyWith(
        isTooltipVisible: true,
        tooltipPosition: null,
        tooltipDataPoint: null,
      );
      expect(state.isTooltipVisible, isTrue);
      expect(state.tooltipPosition, isNull);
      expect(state.tooltipDataPoint, isNull);
    });

    test('validation: focusedPoint can be set with focusedPointIndex', () {
      final mockPoint = const ChartDataPoint(x: 1.0, y: 10.0);

      final state = InteractionState.initial().copyWith(
        focusedPoint: pointToMap(mockPoint),
        focusedPointIndex: 0,
      );

      expect(state.focusedPoint, isNotNull);
      expect(state.focusedPointIndex, equals(0));
    });

    test('toJson() serializes state correctly', () {
      final state = InteractionState.initial().copyWith(
        isCrosshairVisible: true,
        crosshairPosition: const Offset(100, 200),
      );

      final json = state.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['isCrosshairVisible'], isTrue);
      expect(json['crosshairPosition'], isNotNull);
    });

    test('fromJson() deserializes state correctly', () {
      final json = {
        'isCrosshairVisible': true,
        'isTooltipVisible': false,
        'crosshairPosition': {'dx': 100.0, 'dy': 200.0},
        'snapPoints': [],
        'selectedPoints': [],
        'focusedPointIndex': -1,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final state = InteractionState.fromJson(json);

      expect(state.isCrosshairVisible, isTrue);
      expect(state.isTooltipVisible, isFalse);
      expect(state.crosshairPosition, equals(const Offset(100, 200)));
    });

    test('equality: two states with same values are equal', () {
      final state1 = InteractionState.initial();
      final state2 = InteractionState.initial();

      expect(state1, equals(state2));
    });

    test('equality: two states with different values are not equal', () {
      final state1 = InteractionState.initial();
      final state2 = state1.copyWith(isCrosshairVisible: true);

      expect(state1, isNot(equals(state2)));
    });

    test('hashCode: equal states have same hashCode', () {
      final state1 = InteractionState.initial();
      final state2 = InteractionState.initial();

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('immutability: copyWith returns new instance', () {
      final state1 = InteractionState.initial();
      final state2 = state1.copyWith(isCrosshairVisible: true);

      expect(identical(state1, state2), isFalse);
      expect(state1.isCrosshairVisible, isFalse);
      expect(state2.isCrosshairVisible, isTrue);
    });

    test('complex state: multiple selections and active gesture', () {
      final point1 = const ChartDataPoint(x: 1.0, y: 10.0);
      final point2 = const ChartDataPoint(x: 2.0, y: 20.0);
      final gesture = GestureDetails.pan(
        startPosition: const Offset(0, 0),
        currentPosition: const Offset(50, 50),
        delta: const Offset(50, 50),
        totalDelta: const Offset(50, 50),
        startTime: DateTime.now(),
      );

      final state = InteractionState.initial().copyWith(
        selectedPoints: [pointToMap(point1), pointToMap(point2)],
        activeGesture: gesture,
        hoveredPoint: pointToMap(point1),
      );

      expect(state.selectedPoints.length, equals(2));
      expect(state.activeGesture, isNotNull);
      expect(state.hasHoveredPoint, isTrue);
    });
  });
}
