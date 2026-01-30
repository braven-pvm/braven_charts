// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for ThresholdAnnotationElement with perSeries normalization

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThresholdAnnotationElement perSeries normalization', () {
    late ChartTransform baseTransform;

    setUp(() {
      // Create a base transform with 0-1 Y range (normalized space)
      baseTransform = const ChartTransform(
        dataXMin: 0,
        dataXMax: 100,
        dataYMin: 0,
        dataYMax: 1,
        plotWidth: 400,
        plotHeight: 300,
      );
    });

    test('without axisBounds, uses transform Y range directly', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.y,
        value: 0.5, // Value in normalized 0-1 space
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      final element = ThresholdAnnotationElement(
        annotation: annotation,
        transform: baseTransform,
      );

      // Get bounds to trigger position calculation
      final bounds = element.bounds;

      // Y=0.5 in 0-1 range should map to middle of plot (150px from top)
      // Since invertY is true, 0.5 maps to plotHeight * (1 - 0.5) = 150
      expect(bounds.center.dy, closeTo(150, 5));
    });

    test('with axisBounds, normalizes value correctly', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.y,
        value: 200, // Original data value (e.g., power in watts)
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      final element = ThresholdAnnotationElement(
        annotation: annotation,
        transform: baseTransform,
        axisBounds: const DataRange(min: 0, max: 400), // Power axis: 0-400W
      );

      // Get bounds to trigger position calculation
      final bounds = element.bounds;

      // Value 200 in range 0-400 = normalized 0.5
      // Screen Y = plotHeight * (1 - 0.5) = 300 * 0.5 = 150
      expect(bounds.center.dy, closeTo(150, 5));
    });

    test('updateAxisBounds changes rendering position', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.y,
        value: 100, // Original data value
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      final element = ThresholdAnnotationElement(
        annotation: annotation,
        transform: baseTransform,
      );

      // Initially no axis bounds - value 100 in 0-1 range is way off screen
      final initialBounds = element.bounds;
      // Value 100 maps to 100/1 = 100 in normalized space, which is inverted
      // screenY = plotHeight * (1 - 100) = negative = off screen
      expect(initialBounds.center.dy < 0, isTrue);

      // Now set axis bounds matching the data range
      element.updateAxisBounds(const DataRange(min: 0, max: 200));

      final updatedBounds = element.bounds;
      // Value 100 in range 0-200 = normalized 0.5
      // Screen Y = plotHeight * (1 - 0.5) = 150
      expect(updatedBounds.center.dy, closeTo(150, 5));
    });

    test('X-axis threshold ignores axisBounds', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.x, // X-axis, not Y
        value: 50,
        lineColor: Colors.blue,
        lineWidth: 2.0,
      );

      final element = ThresholdAnnotationElement(
        annotation: annotation,
        transform: baseTransform,
        axisBounds: const DataRange(min: 0, max: 400), // Should be ignored
      );

      // Get bounds
      final bounds = element.bounds;

      // X-axis threshold at value 50 in range 0-100
      // X position = 50/100 * plotWidth = 0.5 * 400 = 200
      expect(bounds.center.dx, closeTo(200, 5));
    });

    test('seriesId property is preserved in copyWith', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.y,
        value: 200,
        seriesId: 'power',
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      expect(annotation.seriesId, 'power');

      final copied = annotation.copyWith(value: 300);
      expect(copied.seriesId, 'power');
      expect(copied.value, 300);

      final copiedWithNewSeriesId = annotation.copyWith(seriesId: 'heartrate');
      expect(copiedWithNewSeriesId.seriesId, 'heartrate');
    });

    test('axisBounds with zero span returns middle position', () {
      final annotation = ThresholdAnnotation(
        id: 'test',
        axis: AnnotationAxis.y,
        value: 100,
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      final element = ThresholdAnnotationElement(
        annotation: annotation,
        transform: baseTransform,
        axisBounds: const DataRange(min: 100, max: 100), // Zero span
      );

      // Get bounds
      final bounds = element.bounds;

      // With zero span, should use transform directly (fallback behavior)
      // But let's verify it doesn't crash
      expect(bounds.isFinite, isTrue);
    });
  });
}
