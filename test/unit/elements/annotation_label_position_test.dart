import 'dart:ui';

import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnotationLabelPosition', () {
    test('exposes the complete 3 by 3 position spectrum', () {
      expect(
        AnnotationLabelPosition.values.map((position) => position.name),
        const [
          'topLeft',
          'topCenter',
          'topRight',
          'centerLeft',
          'center',
          'centerRight',
          'bottomLeft',
          'bottomCenter',
          'bottomRight',
        ],
      );
    });
  });

  group('resolveRangeAnnotationLabelRect', () {
    const rangeRect = Rect.fromLTWH(10, 20, 300, 180);
    const labelSize = Size(60, 24);
    const margin = 8.0;

    final expected = <AnnotationLabelPosition, Offset>{
      AnnotationLabelPosition.topLeft: const Offset(18, 28),
      AnnotationLabelPosition.topCenter: const Offset(130, 28),
      AnnotationLabelPosition.topRight: const Offset(242, 28),
      AnnotationLabelPosition.centerLeft: const Offset(18, 98),
      AnnotationLabelPosition.center: const Offset(130, 98),
      AnnotationLabelPosition.centerRight: const Offset(242, 98),
      AnnotationLabelPosition.bottomLeft: const Offset(18, 168),
      AnnotationLabelPosition.bottomCenter: const Offset(130, 168),
      AnnotationLabelPosition.bottomRight: const Offset(242, 168),
    };

    for (final entry in expected.entries) {
      test('positions ${entry.key.name}', () {
        final rect = resolveRangeAnnotationLabelRect(
          rangeRect: rangeRect,
          labelSize: labelSize,
          labelMargin: margin,
          position: entry.key,
        );

        expect(rect.topLeft, entry.value);
        expect(rect.size, labelSize);
      });
    }
  });

  group('resolveThresholdAnnotationLabelRect', () {
    const labelSize = Size(60, 24);

    test('supports new anchors on a horizontal threshold', () {
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(10, 100),
          end: const Offset(310, 100),
          axis: AnnotationAxis.y,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.topCenter,
        ).topLeft,
        const Offset(130, 68),
      );
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(10, 100),
          end: const Offset(310, 100),
          axis: AnnotationAxis.y,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.centerRight,
        ).topLeft,
        const Offset(242, 88),
      );
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(10, 100),
          end: const Offset(310, 100),
          axis: AnnotationAxis.y,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.bottomCenter,
        ).topLeft,
        const Offset(130, 108),
      );
    });

    test('supports new anchors on a vertical threshold', () {
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(160, 20),
          end: const Offset(160, 200),
          axis: AnnotationAxis.x,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.topCenter,
        ).topLeft,
        const Offset(130, 28),
      );
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(160, 20),
          end: const Offset(160, 200),
          axis: AnnotationAxis.x,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.centerLeft,
        ).topLeft,
        const Offset(92, 98),
      );
      expect(
        resolveThresholdAnnotationLabelRect(
          start: const Offset(160, 20),
          end: const Offset(160, 200),
          axis: AnnotationAxis.x,
          labelSize: labelSize,
          labelMargin: 8,
          position: AnnotationLabelPosition.bottomRight,
        ).topLeft,
        const Offset(168, 168),
      );
    });
  });
}
