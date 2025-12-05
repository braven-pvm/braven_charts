// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for AnnotationDragHandler module.

import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:braven_charts/src/interaction/core/hit_test_strategy.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/rendering/modules/annotation_drag_handler.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// Test Delegate Implementation
// =============================================================================

class TestAnnotationDragDelegate implements AnnotationDragDelegate {
  TestAnnotationDragDelegate({
    this.transform,
    List<ChartElement>? elements,
    List<ChartSeries>? series,
  })  : elements = elements ?? [],
        series = series ?? [];

  @override
  ChartTransform? transform;

  @override
  List<ChartElement> elements;

  @override
  List<ChartSeries> series;

  int rebuildSpatialIndexCount = 0;
  int markNeedsPaintCount = 0;
  List<(String, ChartAnnotation)> annotationChanges = [];

  @override
  void rebuildSpatialIndex() {
    rebuildSpatialIndexCount++;
  }

  @override
  void markNeedsPaint() {
    markNeedsPaintCount++;
  }

  @override
  void notifyAnnotationChanged(String annotationId, ChartAnnotation updatedAnnotation) {
    annotationChanges.add((annotationId, updatedAnnotation));
  }

  void reset() {
    rebuildSpatialIndexCount = 0;
    markNeedsPaintCount = 0;
    annotationChanges.clear();
  }
}

// =============================================================================
// Test Helpers
// =============================================================================

ChartTransform createTestTransform({
  double dataXMin = 0,
  double dataXMax = 100,
  double dataYMin = 0,
  double dataYMax = 100,
  double plotWidth = 400,
  double plotHeight = 300,
}) {
  return ChartTransform(
    dataXMin: dataXMin,
    dataXMax: dataXMax,
    dataYMin: dataYMin,
    dataYMax: dataYMax,
    plotWidth: plotWidth,
    plotHeight: plotHeight,
  );
}

RangeAnnotation createRangeAnnotation({
  String id = 'range-1',
  double? startX = 10,
  double? endX = 50,
  double? startY = 20,
  double? endY = 80,
  bool allowDragging = true,
}) {
  return RangeAnnotation(
    id: id,
    startX: startX,
    endX: endX,
    startY: startY,
    endY: endY,
    allowDragging: allowDragging,
  );
}

RangeAnnotationElement createRangeElement(
  ChartTransform transform, {
  String id = 'range-1',
  double? startX = 10,
  double? endX = 50,
  double? startY = 20,
  double? endY = 80,
}) {
  return RangeAnnotationElement(
    annotation: createRangeAnnotation(
      id: id,
      startX: startX,
      endX: endX,
      startY: startY,
      endY: endY,
    ),
    transform: transform,
    chartSize: Size(transform.plotWidth, transform.plotHeight),
  );
}

TextAnnotation createTextAnnotation({
  String id = 'text-1',
  Offset position = const Offset(100, 100),
  bool allowDragging = true,
}) {
  return TextAnnotation(
    id: id,
    text: 'Test',
    position: position,
    allowDragging: allowDragging,
  );
}

TextAnnotationElement createTextElement(
  ChartTransform transform, {
  String id = 'text-1',
  Offset position = const Offset(100, 100),
}) {
  return TextAnnotationElement(
    annotation: createTextAnnotation(id: id, position: position),
  );
}

ThresholdAnnotation createThresholdAnnotation({
  String id = 'threshold-1',
  double value = 50,
  AnnotationAxis axis = AnnotationAxis.y,
  bool allowDragging = true,
}) {
  return ThresholdAnnotation(
    id: id,
    value: value,
    axis: axis,
    allowDragging: allowDragging,
  );
}

ThresholdAnnotationElement createThresholdElement(
  ChartTransform transform, {
  String id = 'threshold-1',
  double value = 50,
  AnnotationAxis axis = AnnotationAxis.y,
}) {
  return ThresholdAnnotationElement(
    annotation: createThresholdAnnotation(id: id, value: value, axis: axis),
    transform: transform,
  );
}

PinAnnotation createPinAnnotation({
  String id = 'pin-1',
  double x = 50,
  double y = 50,
  bool allowDragging = true,
}) {
  return PinAnnotation(
    id: id,
    x: x,
    y: y,
    allowDragging: allowDragging,
  );
}

PinAnnotationElement createPinElement(
  ChartTransform transform, {
  String id = 'pin-1',
  double x = 50,
  double y = 50,
}) {
  return PinAnnotationElement(
    annotation: createPinAnnotation(id: id, x: x, y: y),
    transform: transform,
  );
}

ChartSeries createTestSeries({
  String id = 'series-1',
  List<ChartDataPoint>? points,
}) {
  return ChartSeries(
    id: id,
    name: 'Test Series',
    color: const Color(0xFF0000FF),
    points: points ??
        [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 25, y: 50),
          const ChartDataPoint(x: 50, y: 100),
          const ChartDataPoint(x: 75, y: 50),
          const ChartDataPoint(x: 100, y: 0),
        ],
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('AnnotationDragHandler', () {
    late TestAnnotationDragDelegate delegate;
    late AnnotationDragHandler handler;
    late ChartTransform transform;

    setUp(() {
      transform = createTestTransform();
      delegate = TestAnnotationDragDelegate(transform: transform);
      handler = AnnotationDragHandler(delegate: delegate);
    });

    group('initialization', () {
      test('starts with no active operations', () {
        expect(handler.isResizing, isFalse);
        expect(handler.isMoving, isFalse);
        expect(handler.hasPotentialDrag, isFalse);
        expect(handler.resizingAnnotation, isNull);
        expect(handler.activeResizeDirection, isNull);
        expect(handler.movingPointAnnotation, isNull);
        expect(handler.candidateDataPointIndex, isNull);
      });

      test('dragThresholdPixels is 5.0', () {
        expect(AnnotationDragHandler.dragThresholdPixels, equals(5.0));
      });
    });

    group('resize operations', () {
      late RangeAnnotationElement element;

      setUp(() {
        element = createRangeElement(transform);
        // Add a series element for transform access
        delegate.elements = [
          SeriesElement(
            series: createTestSeries(),
            transform: transform,
          ),
        ];
      });

      test('startResize sets up resize state', () {
        handler.startResize(element, ResizeDirection.right);

        expect(handler.isResizing, isTrue);
        expect(handler.resizingAnnotation, equals(element));
        expect(handler.activeResizeDirection, equals(ResizeDirection.right));
      });

      test('performResize updates annotation bounds', () {
        handler.startResize(element, ResizeDirection.right);
        final startBounds = element.bounds;
        final startPosition = Offset(startBounds.right, startBounds.center.dy);

        handler.performResize(
          startPosition + const Offset(50, 0),
          startPosition,
        );

        expect(element.bounds.right, greaterThan(startBounds.right));
      });

      test('performResize with no active resize does nothing', () {
        final boundsBeforeAttempt = element.bounds;
        handler.performResize(const Offset(100, 100), const Offset(50, 50));
        expect(element.bounds, equals(boundsBeforeAttempt));
      });

      test('performResize respects minimum size constraint', () {
        handler.startResize(element, ResizeDirection.right);
        final startPosition = Offset(element.bounds.right, element.bounds.center.dy);

        // Try to shrink way below minimum
        handler.performResize(
          startPosition - Offset(element.bounds.width, 0),
          startPosition,
        );

        // Bounds should not shrink below minimum
        expect(element.bounds.width, greaterThanOrEqualTo(40));
      });

      test('cancelResize clears state and temp values', () {
        handler.startResize(element, ResizeDirection.right);
        expect(handler.isResizing, isTrue);

        handler.cancelResize();

        expect(handler.isResizing, isFalse);
        expect(handler.resizingAnnotation, isNull);
        expect(handler.activeResizeDirection, isNull);
      });

      test('finalizeResize returns updated annotation', () {
        handler.startResize(element, ResizeDirection.right);
        final startPosition = Offset(element.bounds.right, element.bounds.center.dy);
        handler.performResize(startPosition + const Offset(50, 0), startPosition);

        final result = handler.finalizeResize();

        expect(result, isNotNull);
        expect(result!.endX, isNotNull);
        expect(delegate.rebuildSpatialIndexCount, equals(1));
        expect(delegate.markNeedsPaintCount, equals(1));
      });

      test('finalizeResize with no active resize returns null', () {
        final result = handler.finalizeResize();
        expect(result, isNull);
      });
    });

    group('RangeAnnotation move operations', () {
      late RangeAnnotationElement element;

      setUp(() {
        element = createRangeElement(transform);
        delegate.elements = [
          SeriesElement(
            series: createTestSeries(),
            transform: transform,
          ),
        ];
      });

      test('startRangeMove sets up move state', () {
        handler.startRangeMove(element, const Offset(100, 100));
        expect(handler.isMoving, isTrue);
      });

      test('performRangeMove updates annotation position', () {
        handler.startRangeMove(element, const Offset(100, 100));
        final startBounds = element.bounds;

        handler.performRangeMove(const Offset(150, 120));

        expect(element.bounds.left, closeTo(startBounds.left + 50, 1));
        expect(element.bounds.top, closeTo(startBounds.top + 20, 1));
      });

      test('cancelRangeMove clears state', () {
        handler.startRangeMove(element, const Offset(100, 100));
        handler.cancelRangeMove();
        expect(handler.isMoving, isFalse);
      });

      test('finalizeRangeMove returns updated annotation', () {
        handler.startRangeMove(element, const Offset(100, 100));
        handler.performRangeMove(const Offset(150, 120));

        final result = handler.finalizeRangeMove();

        expect(result, isNotNull);
        expect(delegate.rebuildSpatialIndexCount, equals(1));
      });
    });

    group('TextAnnotation move operations', () {
      late TextAnnotationElement element;

      setUp(() {
        element = createTextElement(transform);
      });

      test('startTextMove sets up move state', () {
        handler.startTextMove(element, const Offset(100, 100));
        expect(handler.isMoving, isTrue);
      });

      test('performTextMove updates temp position', () {
        handler.startTextMove(element, const Offset(100, 100));
        handler.performTextMove(const Offset(150, 120));

        expect(element.tempPosition, isNotNull);
      });

      test('finalizeTextMove returns updated annotation', () {
        handler.startTextMove(element, const Offset(100, 100));
        handler.performTextMove(const Offset(150, 120));

        final result = handler.finalizeTextMove();

        expect(result, isNotNull);
        expect(result!.position, isNot(equals(const Offset(100, 100))));
        expect(delegate.rebuildSpatialIndexCount, equals(1));
      });

      test('finalizeTextMove with no movement returns null', () {
        handler.startTextMove(element, const Offset(100, 100));
        // No move performed, so temp position should be null

        final result = handler.finalizeTextMove();

        expect(result, isNull);
      });
    });

    group('ThresholdAnnotation move operations', () {
      late ThresholdAnnotationElement element;

      setUp(() {
        element = createThresholdElement(transform);
        delegate.transform = transform;
      });

      test('startThresholdMove sets up move state', () {
        handler.startThresholdMove(element, const Offset(100, 100));
        expect(handler.isMoving, isTrue);
      });

      test('performThresholdMove updates temp value for Y-axis', () {
        handler.startThresholdMove(element, const Offset(100, 150));
        handler.performThresholdMove(const Offset(100, 100)); // Move up

        expect(element.tempValue, isNotNull);
        expect(element.tempValue!, greaterThan(50)); // Moving up increases Y value
      });

      test('finalizeThresholdMove returns updated annotation', () {
        handler.startThresholdMove(element, const Offset(100, 150));
        handler.performThresholdMove(const Offset(100, 100));

        final result = handler.finalizeThresholdMove();

        expect(result, isNotNull);
        expect(result!.value, isNot(equals(50)));
        expect(delegate.rebuildSpatialIndexCount, equals(1));
      });
    });

    group('PinAnnotation move operations', () {
      late PinAnnotationElement element;

      setUp(() {
        element = createPinElement(transform);
        delegate.transform = transform;
      });

      test('startPinMove sets up move state', () {
        handler.startPinMove(element, const Offset(200, 150));
        expect(handler.isMoving, isTrue);
      });

      test('performPinMove updates temp position', () {
        handler.startPinMove(element, const Offset(200, 150));
        handler.performPinMove(const Offset(250, 100));

        expect(element.tempPosition, isNotNull);
      });

      test('finalizePinMove returns updated annotation', () {
        handler.startPinMove(element, const Offset(200, 150));
        handler.performPinMove(const Offset(250, 100));

        final result = handler.finalizePinMove();

        expect(result, isNotNull);
        expect(delegate.rebuildSpatialIndexCount, equals(1));
      });
    });

    group('potential drag state', () {
      test('setPotentialPointDrag and getter work', () {
        final element = PointAnnotationElement(
          annotation: PointAnnotation(
            id: 'point-1',
            seriesId: 'series-1',
            dataPointIndex: 2,
          ),
          series: createTestSeries(),
          transform: transform,
        );

        handler.setPotentialPointDrag(element, const Offset(100, 100));
        expect(handler.hasPotentialDrag, isTrue);

        final (elem, pos) = handler.potentialPointDrag;
        expect(elem, equals(element));
        expect(pos, equals(const Offset(100, 100)));
      });

      test('clearPotentialPointDrag clears state', () {
        final element = PointAnnotationElement(
          annotation: PointAnnotation(
            id: 'point-1',
            seriesId: 'series-1',
            dataPointIndex: 2,
          ),
          series: createTestSeries(),
          transform: transform,
        );

        handler.setPotentialPointDrag(element, const Offset(100, 100));
        handler.clearPotentialPointDrag();

        expect(handler.hasPotentialDrag, isFalse);
        final (elem, pos) = handler.potentialPointDrag;
        expect(elem, isNull);
        expect(pos, isNull);
      });

      test('setPotentialRangeDrag and getter work', () {
        final element = createRangeElement(transform);

        handler.setPotentialRangeDrag(element, const Offset(100, 100));
        expect(handler.hasPotentialDrag, isTrue);

        final (elem, pos, bounds) = handler.potentialRangeDrag;
        expect(elem, equals(element));
        expect(pos, equals(const Offset(100, 100)));
        expect(bounds, isNotNull);
      });

      test('setPotentialTextDrag and getter work', () {
        final element = createTextElement(transform);

        handler.setPotentialTextDrag(element, const Offset(100, 100));
        expect(handler.hasPotentialDrag, isTrue);

        final (elem, pos) = handler.potentialTextDrag;
        expect(elem, equals(element));
        expect(pos, equals(const Offset(100, 100)));
      });

      test('setPotentialThresholdDrag and getter work', () {
        final element = createThresholdElement(transform);

        handler.setPotentialThresholdDrag(element, const Offset(100, 100));
        expect(handler.hasPotentialDrag, isTrue);

        final (elem, pos) = handler.potentialThresholdDrag;
        expect(elem, equals(element));
        expect(pos, equals(const Offset(100, 100)));
      });

      test('setPotentialPinDrag and getter work', () {
        final element = createPinElement(transform);

        handler.setPotentialPinDrag(element, const Offset(100, 100));
        expect(handler.hasPotentialDrag, isTrue);

        final (elem, pos) = handler.potentialPinDrag;
        expect(elem, equals(element));
        expect(pos, equals(const Offset(100, 100)));
      });
    });

    group('exceedsDragThreshold', () {
      test('returns false for small movement', () {
        expect(
          handler.exceedsDragThreshold(
            const Offset(100, 100),
            const Offset(103, 102),
          ),
          isFalse,
        );
      });

      test('returns true for movement exceeding threshold', () {
        expect(
          handler.exceedsDragThreshold(
            const Offset(100, 100),
            const Offset(106, 100),
          ),
          isTrue,
        );
      });

      test('returns true for diagonal movement exceeding threshold', () {
        expect(
          handler.exceedsDragThreshold(
            const Offset(100, 100),
            const Offset(104, 104), // distance ≈ 5.66
          ),
          isTrue,
        );
      });
    });

    group('clearAllState', () {
      test('clears all active operations', () {
        // Start various operations
        final rangeElement = createRangeElement(transform);
        final textElement = createTextElement(transform);

        handler.startResize(rangeElement, ResizeDirection.right);
        handler.setPotentialTextDrag(textElement, const Offset(100, 100));

        expect(handler.isResizing, isTrue);
        expect(handler.hasPotentialDrag, isTrue);

        handler.clearAllState();

        expect(handler.isResizing, isFalse);
        expect(handler.isMoving, isFalse);
        expect(handler.hasPotentialDrag, isFalse);
      });
    });

    group('dispose', () {
      test('clears all state', () {
        final element = createRangeElement(transform);
        handler.startResize(element, ResizeDirection.right);

        handler.dispose();

        expect(handler.isResizing, isFalse);
        expect(handler.isMoving, isFalse);
        expect(handler.hasPotentialDrag, isFalse);
      });
    });
  });
}
