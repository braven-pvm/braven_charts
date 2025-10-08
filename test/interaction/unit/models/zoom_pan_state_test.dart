// Unit Test: ZoomPanState Model
// Feature: Layer 7 Interaction System
// Task: T009
// Status: Implementation complete, tests aligned

import 'package:braven_charts/src/interaction/models/zoom_pan_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoomPanState Model Tests', () {
    const testDataBounds = Rect.fromLTWH(0, 0, 100, 100);

    test('ZoomPanState.initial() creates default state with 1.0 zoom', () {
      final state = ZoomPanState.initial(testDataBounds);

      expect(state.zoomLevelX, equals(1.0));
      expect(state.zoomLevelY, equals(1.0));
      expect(state.panOffset, equals(Offset.zero));
      expect(state.originalDataBounds, equals(testDataBounds));
      expect(state.visibleDataBounds, equals(testDataBounds));
      expect(state.isAnimating, isFalse);
      expect(state.minZoomLevel, equals(0.5));
      expect(state.maxZoomLevel, equals(10.0));
    });

    test('ZoomPanState.initial() with no bounds defaults to Rect.zero', () {
      final state = ZoomPanState.initial();

      expect(state.originalDataBounds, equals(Rect.zero));
      expect(state.visibleDataBounds, equals(Rect.zero));
    });

    test('copyWith() creates new instance with updated fields', () {
      final initial = ZoomPanState.initial(testDataBounds);
      final updated = initial.copyWith(
        zoomLevelX: 1.5,
        panOffset: const Offset(10, 20),
      );

      expect(updated.zoomLevelX, equals(1.5));
      expect(updated.panOffset, equals(const Offset(10, 20)));
      expect(updated.zoomLevelY, equals(initial.zoomLevelY));
      expect(updated.originalDataBounds, equals(initial.originalDataBounds));
    });

    test('copyWith() updates zoom levels independently', () {
      final initial = ZoomPanState.initial(testDataBounds);
      final updatedX = initial.copyWith(zoomLevelX: 2.0);
      final updatedY = initial.copyWith(zoomLevelY: 2.0);

      expect(updatedX.zoomLevelX, equals(2.0));
      expect(updatedX.zoomLevelY, equals(1.0));
      
      expect(updatedY.zoomLevelX, equals(1.0));
      expect(updatedY.zoomLevelY, equals(2.0));
    });

    test('copyWith() updates visible bounds', () {
      final initial = ZoomPanState.initial(testDataBounds);
      const newBounds = Rect.fromLTWH(0, 0, 50, 50);
      final updated = initial.copyWith(visibleDataBounds: newBounds);

      expect(updated.visibleDataBounds, equals(newBounds));
      expect(updated.originalDataBounds, equals(testDataBounds)); // Unchanged
    });

    test('isAnimating can be set via copyWith', () {
      final initial = ZoomPanState.initial(testDataBounds);
      final animating = initial.copyWith(isAnimating: true);

      expect(initial.isAnimating, isFalse);
      expect(animating.isAnimating, isTrue);
    });

    test('animationDuration can be customized', () {
      final state = ZoomPanState.initial(testDataBounds).copyWith(
        animationDuration: const Duration(milliseconds: 500),
      );

      expect(state.animationDuration, equals(const Duration(milliseconds: 500)));
    });

    test('allowOverscroll can be configured', () {
      final state = ZoomPanState.initial(testDataBounds).copyWith(
        allowOverscroll: true,
      );

      expect(state.allowOverscroll, isTrue);
    });

    test('min/max zoom levels can be customized', () {
      final state = ZoomPanState.initial(testDataBounds).copyWith(
        minZoomLevel: 0.25,
        maxZoomLevel: 20.0,
      );

      expect(state.minZoomLevel, equals(0.25));
      expect(state.maxZoomLevel, equals(20.0));
    });

    test('toJson() serializes state correctly', () {
      final state = ZoomPanState.initial(testDataBounds).copyWith(
        zoomLevelX: 2.0,
        panOffset: const Offset(10, 20),
      );

      final json = state.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['zoomLevelX'], equals(2.0));
      expect(json['panOffset'], isNotNull);
      expect(json['panOffset']['dx'], equals(10.0));
      expect(json['panOffset']['dy'], equals(20.0));
    });

    test('fromJson() deserializes state correctly', () {
      final json = {
        'zoomLevelX': 2.0,
        'zoomLevelY': 1.5,
        'panOffset': {'dx': 10.0, 'dy': 20.0},
        'visibleDataBounds': {
          'left': 0.0,
          'top': 0.0,
          'right': 100.0,
          'bottom': 100.0,
        },
        'originalDataBounds': {
          'left': 0.0,
          'top': 0.0,
          'right': 100.0,
          'bottom': 100.0,
        },
        'minZoomLevel': 0.5,
        'maxZoomLevel': 10.0,
        'allowOverscroll': false,
        'isAnimating': false,
        'animationDuration': 300,
      };

      final state = ZoomPanState.fromJson(json);

      expect(state.zoomLevelX, equals(2.0));
      expect(state.zoomLevelY, equals(1.5));
      expect(state.panOffset, equals(const Offset(10, 20)));
      expect(state.visibleDataBounds, equals(testDataBounds));
    });

    test('equality: two states with same values are equal', () {
      final state1 = ZoomPanState.initial(testDataBounds);
      final state2 = ZoomPanState.initial(testDataBounds);

      expect(state1, equals(state2));
    });

    test('equality: two states with different values are not equal', () {
      final state1 = ZoomPanState.initial(testDataBounds);
      final state2 = state1.copyWith(zoomLevelX: 2.0);

      expect(state1, isNot(equals(state2)));
    });

    test('hashCode: equal states have same hashCode', () {
      final state1 = ZoomPanState.initial(testDataBounds);
      final state2 = ZoomPanState.initial(testDataBounds);

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('immutability: copyWith returns new instance', () {
      final state1 = ZoomPanState.initial(testDataBounds);
      final state2 = state1.copyWith(zoomLevelX: 2.0);

      expect(identical(state1, state2), isFalse);
      expect(state1.zoomLevelX, equals(1.0));
      expect(state2.zoomLevelX, equals(2.0));
    });

    test('complex scenario: zoomed and panned state', () {
      final state = ZoomPanState.initial(testDataBounds).copyWith(
        zoomLevelX: 2.0,
        zoomLevelY: 2.0,
        panOffset: const Offset(10, 10),
        visibleDataBounds: const Rect.fromLTWH(10, 10, 50, 50),
        isAnimating: false,
      );

      expect(state.zoomLevelX, equals(2.0));
      expect(state.zoomLevelY, equals(2.0));
      expect(state.panOffset, equals(const Offset(10, 10)));
      expect(state.visibleDataBounds.width, equals(50.0));
      expect(state.visibleDataBounds.height, equals(50.0));
    });
  });
}
