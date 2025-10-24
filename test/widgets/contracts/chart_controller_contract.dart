/// API Contract: ChartController
///
/// This contract defines the expected behavior of the ChartController class.
/// Tests should be written BEFORE implementation (TDD red phase).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('ChartController Contract', () {
    group('Construction', () {
      test('MUST extend ChangeNotifier', () {
        final controller = ChartController();
        expect(controller, isA<ChangeNotifier>());
      });

      test('MUST initialize with empty data', () {
        final controller = ChartController();
        expect(controller.getAllSeries(), isEmpty);
        expect(controller.getAllAnnotations(), isEmpty);
      });
    });

    group('Data Management - addPoint', () {
      test('MUST add point to new series', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));

        final series = controller.getAllSeries();
        expect(series['s1'], isNotNull);
        expect(series['s1']!.length, equals(1));
        expect(series['s1']![0].x, equals(0));
        expect(series['s1']![0].y, equals(1));
      });

      test('MUST add point to existing series', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));
        controller.addPoint('s1', const ChartDataPoint(1, 2));

        final series = controller.getAllSeries();
        expect(series['s1']!.length, equals(2));
      });

      test('MUST notify listeners when point added', () {
        final controller = ChartController();
        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.addPoint('s1', const ChartDataPoint(0, 1));
        expect(notified, isTrue);
      });

      test('MUST reject NaN coordinates', () {
        final controller = ChartController();
        expect(
          () => controller.addPoint('s1', const ChartDataPoint(double.nan, 1)),
          throwsA(isA<AssertionError>()),
        );
      });

      test('MUST reject Infinity coordinates', () {
        final controller = ChartController();
        expect(
          () => controller.addPoint(
              's1', const ChartDataPoint(double.infinity, 1)),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Data Management - removeOldestPoint', () {
      test('MUST remove oldest point from series', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));
        controller.addPoint('s1', const ChartDataPoint(1, 2));

        controller.removeOldestPoint('s1');

        final series = controller.getAllSeries();
        expect(series['s1']!.length, equals(1));
        expect(series['s1']![0].x, equals(1)); // Second point remains
      });

      test('MUST notify listeners when point removed', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.removeOldestPoint('s1');
        expect(notified, isTrue);
      });

      test('MUST handle empty series gracefully', () {
        final controller = ChartController();
        expect(() => controller.removeOldestPoint('s1'), returnsNormally);
      });
    });

    group('Data Management - clearSeries', () {
      test('MUST remove all points from series', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));
        controller.addPoint('s1', const ChartDataPoint(1, 2));

        controller.clearSeries('s1');

        final series = controller.getAllSeries();
        expect(series['s1'], isEmpty);
      });

      test('MUST notify listeners when series cleared', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.clearSeries('s1');
        expect(notified, isTrue);
      });
    });

    group('Data Management - getAllSeries', () {
      test('MUST return copy of series data', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));

        final series1 = controller.getAllSeries();
        final series2 = controller.getAllSeries();

        expect(identical(series1, series2), isFalse); // Different instances
        expect(series1, equals(series2)); // Same content
      });

      test('MUST return multiple series', () {
        final controller = ChartController();
        controller.addPoint('s1', const ChartDataPoint(0, 1));
        controller.addPoint('s2', const ChartDataPoint(0, 2));

        final series = controller.getAllSeries();
        expect(series.length, equals(2));
        expect(series.containsKey('s1'), isTrue);
        expect(series.containsKey('s2'), isTrue);
      });
    });

    group('Annotation Management - addAnnotation', () {
      test('MUST return auto-generated ID', () {
        final controller = ChartController();
        final annotation = TextAnnotation(
          position: const Offset(100, 50),
          label: 'Test',
        );

        final id = controller.addAnnotation(annotation);
        expect(id, isNotNull);
        expect(id, isNotEmpty);
      });

      test('MUST store annotation with ID', () {
        final controller = ChartController();
        final annotation = TextAnnotation(
          position: const Offset(100, 50),
          label: 'Test',
        );

        final id = controller.addAnnotation(annotation);
        final retrieved = controller.getAnnotation(id);

        expect(retrieved, equals(annotation));
      });

      test('MUST notify listeners when annotation added', () {
        final controller = ChartController();
        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );
        expect(notified, isTrue);
      });

      test('MUST preserve custom ID if provided', () {
        final controller = ChartController();
        final annotation = TextAnnotation(
          id: 'custom-id',
          position: const Offset(100, 50),
          label: 'Test',
        );

        final id = controller.addAnnotation(annotation);
        expect(id, equals('custom-id'));
      });
    });

    group('Annotation Management - removeAnnotation', () {
      test('MUST remove annotation by ID', () {
        final controller = ChartController();
        final id = controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        controller.removeAnnotation(id);

        expect(controller.getAnnotation(id), isNull);
      });

      test('MUST notify listeners when annotation removed', () {
        final controller = ChartController();
        final id = controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.removeAnnotation(id);
        expect(notified, isTrue);
      });

      test('MUST handle non-existent ID gracefully', () {
        final controller = ChartController();
        expect(
            () => controller.removeAnnotation('nonexistent'), returnsNormally);
      });
    });

    group('Annotation Management - updateAnnotation', () {
      test('MUST update existing annotation', () {
        final controller = ChartController();
        final id = controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Old'),
        );

        final newAnnotation = TextAnnotation(
          position: const Offset(200, 100),
          label: 'New',
        );
        controller.updateAnnotation(id, newAnnotation);

        final retrieved = controller.getAnnotation(id);
        expect(retrieved, equals(newAnnotation));
      });

      test('MUST notify listeners when annotation updated', () {
        final controller = ChartController();
        final id = controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.updateAnnotation(
          id,
          TextAnnotation(position: const Offset(200, 100), label: 'Updated'),
        );
        expect(notified, isTrue);
      });

      test('MUST throw for non-existent ID', () {
        final controller = ChartController();
        expect(
          () => controller.updateAnnotation(
            'nonexistent',
            TextAnnotation(position: const Offset(100, 50), label: 'Test'),
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Annotation Management - getAnnotation', () {
      test('MUST return annotation by ID', () {
        final controller = ChartController();
        final annotation = TextAnnotation(
          position: const Offset(100, 50),
          label: 'Test',
        );
        final id = controller.addAnnotation(annotation);

        final retrieved = controller.getAnnotation(id);
        expect(retrieved, equals(annotation));
      });

      test('MUST return null for non-existent ID', () {
        final controller = ChartController();
        expect(controller.getAnnotation('nonexistent'), isNull);
      });
    });

    group('Annotation Management - getAllAnnotations', () {
      test('MUST return list of all annotations', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'A'),
        );
        controller.addAnnotation(
          TextAnnotation(position: const Offset(200, 100), label: 'B'),
        );

        final annotations = controller.getAllAnnotations();
        expect(annotations.length, equals(2));
      });

      test('MUST return copy of annotations list', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        final list1 = controller.getAllAnnotations();
        final list2 = controller.getAllAnnotations();

        expect(identical(list1, list2), isFalse); // Different instances
        expect(list1, equals(list2)); // Same content
      });
    });

    group('Annotation Management - clearAnnotations', () {
      test('MUST remove all annotations', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'A'),
        );
        controller.addAnnotation(
          TextAnnotation(position: const Offset(200, 100), label: 'B'),
        );

        controller.clearAnnotations();

        expect(controller.getAllAnnotations(), isEmpty);
      });

      test('MUST notify listeners when annotations cleared', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.clearAnnotations();
        expect(notified, isTrue);
      });
    });

    group('Annotation Management - findAnnotationsAt', () {
      test('MUST return annotations at position', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'Test'),
        );

        final found = controller.findAnnotationsAt(const Offset(105, 55));
        expect(found, isNotEmpty);
      });

      test('MUST return empty list if none found', () {
        final controller = ChartController();
        final found = controller.findAnnotationsAt(const Offset(500, 500));
        expect(found, isEmpty);
      });

      test('MUST return multiple overlapping annotations', () {
        final controller = ChartController();
        controller.addAnnotation(
          TextAnnotation(position: const Offset(100, 50), label: 'A'),
        );
        controller.addAnnotation(
          TextAnnotation(position: const Offset(105, 55), label: 'B'),
        );

        final found = controller.findAnnotationsAt(const Offset(103, 53));
        expect(found.length, greaterThanOrEqualTo(1));
      });
    });

    group('Disposal', () {
      test('MUST be disposable', () {
        final controller = ChartController();
        expect(() => controller.dispose(), returnsNormally);
      });

      test('MUST not notify after disposal', () {
        final controller = ChartController();
        var notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.dispose();
        expect(() => controller.addPoint('s1', const ChartDataPoint(0, 1)),
            throwsA(isA<FlutterError>()));
      });
    });
  });
}
