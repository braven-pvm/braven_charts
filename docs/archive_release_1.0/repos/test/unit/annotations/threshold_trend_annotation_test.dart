// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for ThresholdAnnotation and TrendAnnotation

import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThresholdAnnotation', () {
    test('creates horizontal threshold with all properties', () {
      final annotation = ThresholdAnnotation(
        id: 'test_threshold',
        axis: AnnotationAxis.y,
        value: 75.0,
        lineColor: Colors.green,
        lineWidth: 2.0,
        dashPattern: const [5, 3],
        label: 'Target',
        labelPosition: AnnotationLabelPosition.topRight,
      );

      expect(annotation.id, 'test_threshold');
      expect(annotation.axis, AnnotationAxis.y);
      expect(annotation.value, 75.0);
      expect(annotation.lineColor, Colors.green);
      expect(annotation.lineWidth, 2.0);
      expect(annotation.dashPattern, [5, 3]);
      expect(annotation.label, 'Target');
      expect(annotation.labelPosition, AnnotationLabelPosition.topRight);
    });

    test('creates vertical threshold', () {
      final annotation = ThresholdAnnotation(
        id: 'vertical_line',
        axis: AnnotationAxis.x,
        value: 50.0,
        lineColor: Colors.red,
        lineWidth: 1.5,
      );

      expect(annotation.axis, AnnotationAxis.x);
      expect(annotation.value, 50.0);
      expect(annotation.label, isNull);
      expect(annotation.dashPattern, isNull);
    });

    test('copyWith creates modified copy', () {
      final original = ThresholdAnnotation(
        id: 'original',
        axis: AnnotationAxis.y,
        value: 60.0,
        lineColor: Colors.blue,
        lineWidth: 2.0,
      );

      final modified = original.copyWith(
        value: 80.0,
        lineColor: Colors.purple,
      );

      expect(modified.id, 'original'); // unchanged
      expect(modified.axis, AnnotationAxis.y); // unchanged
      expect(modified.value, 80.0); // changed
      expect(modified.lineColor, Colors.purple); // changed
      expect(modified.lineWidth, 2.0); // unchanged
    });

    test('throws assertion error for infinite value', () {
      expect(
        () => ThresholdAnnotation(
          id: 'invalid',
          axis: AnnotationAxis.y,
          value: double.infinity,
          lineColor: Colors.red,
          lineWidth: 1.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error for NaN value', () {
      expect(
        () => ThresholdAnnotation(
          id: 'invalid',
          axis: AnnotationAxis.y,
          value: double.nan,
          lineColor: Colors.red,
          lineWidth: 1.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('TrendAnnotation', () {
    test('creates linear trend with all properties', () {
      final annotation = TrendAnnotation(
        id: 'linear_trend',
        seriesId: 'series1',
        trendType: TrendType.linear,
        lineColor: Colors.purple,
        lineWidth: 2.5,
        dashPattern: const [10, 5],
        label: 'Trend',
      );

      expect(annotation.id, 'linear_trend');
      expect(annotation.seriesId, 'series1');
      expect(annotation.trendType, TrendType.linear);
      expect(annotation.lineColor, Colors.purple);
      expect(annotation.lineWidth, 2.5);
      expect(annotation.dashPattern, [10, 5]);
      expect(annotation.label, 'Trend');
      expect(annotation.windowSize, isNull);
      expect(annotation.degree, 2); // default
    });

    test('creates moving average trend with window size', () {
      final annotation = TrendAnnotation(
        id: 'ma_trend',
        seriesId: 'series1',
        trendType: TrendType.movingAverage,
        windowSize: 5,
        lineColor: Colors.orange,
        lineWidth: 2.0,
      );

      expect(annotation.trendType, TrendType.movingAverage);
      expect(annotation.windowSize, 5);
    });

    test('creates exponential moving average trend', () {
      final annotation = TrendAnnotation(
        id: 'ema_trend',
        seriesId: 'series1',
        trendType: TrendType.exponentialMovingAverage,
        windowSize: 10,
        lineColor: Colors.teal,
        lineWidth: 2.0,
      );

      expect(annotation.trendType, TrendType.exponentialMovingAverage);
      expect(annotation.windowSize, 10);
    });

    test('creates polynomial trend with custom degree', () {
      final annotation = TrendAnnotation(
        id: 'poly_trend',
        seriesId: 'series1',
        trendType: TrendType.polynomial,
        degree: 3,
        lineColor: Colors.indigo,
        lineWidth: 2.0,
      );

      expect(annotation.trendType, TrendType.polynomial);
      expect(annotation.degree, 3);
    });

    test('copyWith creates modified copy', () {
      final original = TrendAnnotation(
        id: 'original',
        seriesId: 'series1',
        trendType: TrendType.linear,
        lineColor: Colors.blue,
        lineWidth: 2.0,
      );

      final modified = original.copyWith(
        trendType: TrendType.movingAverage,
        windowSize: 7,
        lineColor: Colors.green,
      );

      expect(modified.id, 'original'); // unchanged
      expect(modified.seriesId, 'series1'); // unchanged
      expect(modified.trendType, TrendType.movingAverage); // changed
      expect(modified.windowSize, 7); // changed
      expect(modified.lineColor, Colors.green); // changed
      expect(modified.lineWidth, 2.0); // unchanged
    });

    test('throws assertion error when MA without window size', () {
      expect(
        () => TrendAnnotation(
          id: 'invalid',
          seriesId: 'series1',
          trendType: TrendType.movingAverage,
          lineColor: Colors.red,
          lineWidth: 1.0,
          // Missing windowSize!
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error for negative degree', () {
      expect(
        () => TrendAnnotation(
          id: 'invalid',
          seriesId: 'series1',
          trendType: TrendType.polynomial,
          degree: -1,
          lineColor: Colors.red,
          lineWidth: 1.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AnnotationAxis enum', () {
    test('has correct values', () {
      expect(AnnotationAxis.values.length, 2);
      expect(AnnotationAxis.values, contains(AnnotationAxis.y));
      expect(AnnotationAxis.values, contains(AnnotationAxis.x));
    });
  });

  group('TrendType enum', () {
    test('has correct values', () {
      expect(TrendType.values.length, 4);
      expect(TrendType.values, contains(TrendType.linear));
      expect(TrendType.values, contains(TrendType.polynomial));
      expect(TrendType.values, contains(TrendType.movingAverage));
      expect(TrendType.values, contains(TrendType.exponentialMovingAverage));
    });
  });
}
