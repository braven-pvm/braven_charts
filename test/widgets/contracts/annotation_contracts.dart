/// API Contract: Annotation Classes
/// TDD red phase - tests written before implementation
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextAnnotation Contract', () {
    test('MUST accept position and label', () {
      final annotation = TextAnnotation(
        position: const Offset(100, 50),
        text: 'Test',
      );
      expect(annotation.position, equals(const Offset(100, 50)));
      expect(annotation.text, equals('Test'));
    });
  });

  group('PointAnnotation Contract', () {
    test('MUST accept seriesId and dataPointIndex', () {
      final annotation = PointAnnotation(
        seriesId: 's1',
        dataPointIndex: 42,
        label: 'Peak',
      );
      expect(annotation.seriesId, equals('s1'));
      expect(annotation.dataPointIndex, equals(42));
    });
  });

  group('RangeAnnotation Contract', () {
    test('MUST accept startX and endX', () {
      final annotation = RangeAnnotation(
        startX: 0,
        endX: 100,
        label: 'Period',
      );
      expect(annotation.startX, equals(0));
      expect(annotation.endX, equals(100));
    });

    test('MUST validate startX < endX', () {
      expect(
        () => RangeAnnotation(startX: 100, endX: 0),
        throwsAssertionError,
      );
    });
  });

  group('ThresholdAnnotation Contract', () {
    test('MUST accept axis and value', () {
      final annotation = ThresholdAnnotation(
        axis: AnnotationAxis.y,
        value: 100,
        label: 'Target',
      );
      expect(annotation.axis, equals(AnnotationAxis.y));
      expect(annotation.value, equals(100));
    });
  });

  group('TrendAnnotation Contract', () {
    test('MUST accept seriesId and trendType', () {
      final annotation = TrendAnnotation(
        seriesId: 's1',
        trendType: TrendType.linear,
        label: 'Trend',
      );
      expect(annotation.seriesId, equals('s1'));
      expect(annotation.trendType, equals(TrendType.linear));
    });

    test('MUST require windowSize for movingAverage', () {
      expect(
        () => TrendAnnotation(
          seriesId: 's1',
          trendType: TrendType.movingAverage,
          // Missing windowSize!
        ),
        throwsAssertionError,
      );
    });
  });
}
