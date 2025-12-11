// Copyright (c) 2025 braven_charts. All rights reserved.
// Module: Annotation Drag Handler
//
// Manages all annotation drag/resize/move operations with click-vs-drag detection.
// Extracted from ChartRenderBox to improve maintainability.

import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../../coordinates/chart_transform.dart';
import '../../elements/annotation_elements.dart';
import '../../elements/series_element.dart';
import '../../interaction/core/chart_element.dart';
import '../../interaction/core/hit_test_strategy.dart';
import '../../models/chart_annotation.dart';
import '../../models/chart_series.dart';

// =============================================================================
// Delegate Interface
// =============================================================================

/// Delegate interface for AnnotationDragHandler to interact with ChartRenderBox.
///
/// This abstraction allows the handler to:
/// - Access coordinate transforms
/// - Access chart elements and series
/// - Trigger repaints and spatial index rebuilds
/// - Notify about annotation changes
abstract interface class AnnotationDragDelegate {
  /// Current coordinate transform for data/plot conversion.
  ChartTransform? get transform;

  /// All chart elements (for finding series and annotation data).
  List<ChartElement> get elements;

  /// Series data (for point annotation snapping).
  List<ChartSeries> get series;

  /// Rebuild the spatial index after annotation bounds change.
  void rebuildSpatialIndex();

  /// Request a repaint.
  void markNeedsPaint();

  /// Notify that an annotation was changed (for external callbacks).
  void notifyAnnotationChanged(
      String annotationId, ChartAnnotation updatedAnnotation);
}

// =============================================================================
// Annotation Drag Handler
// =============================================================================

/// Manages all annotation drag, resize, and move operations.
///
/// This module encapsulates:
/// - Click-vs-drag detection (potential drag states)
/// - Resize operations for RangeAnnotation
/// - Move operations for all annotation types (Range, Point, Text, Threshold, Pin)
/// - Coordinate conversion between screen/plot/data spaces
///
/// The handler uses a delegate pattern to interact with ChartRenderBox,
/// maintaining clean separation while enabling coordinate access.
///
/// ## Usage Flow:
/// 1. On pointer down, call `startPotentialDrag*()` to track click start
/// 2. On pointer move, call `checkDragThreshold()` to detect actual drag
/// 3. If drag detected, call `perform*()` methods to update annotations
/// 4. On pointer up, call `finalize*()` to commit changes or handle click
///
/// ## Click vs Drag Detection:
/// When user clicks on an annotation, we don't immediately start dragging.
/// Instead, we track "potential drag" state and wait for pointer movement
/// exceeding [dragThresholdPixels] to distinguish click from drag.
class AnnotationDragHandler {
  AnnotationDragHandler({
    required AnnotationDragDelegate delegate,
  }) : _delegate = delegate;

  // ==========================================================================
  // Dependencies
  // ==========================================================================

  final AnnotationDragDelegate _delegate;

  // ==========================================================================
  // Configuration
  // ==========================================================================

  /// Minimum pointer movement (in pixels) to trigger drag mode.
  static const double dragThresholdPixels = 5.0;

  // ==========================================================================
  // Resize State
  // ==========================================================================

  /// Current resize direction (if resizing annotation).
  ResizeDirection? _activeResizeDirection;

  /// Annotation currently being resized.
  RangeAnnotationElement? _resizingAnnotation;

  /// Original bounds at resize start.
  Rect? _resizeStartBounds;

  // ==========================================================================
  // Move State - RangeAnnotation
  // ==========================================================================

  /// RangeAnnotation currently being moved.
  RangeAnnotationElement? _movingAnnotation;

  /// Position at move start.
  Offset? _moveStartPosition;

  /// Original bounds at move start.
  Rect? _moveStartBounds;

  // ==========================================================================
  // Move State - TextAnnotation
  // ==========================================================================

  /// TextAnnotation currently being moved.
  TextAnnotationElement? _movingTextAnnotation;

  /// Position at move start.
  Offset? _moveTextStartPosition;

  // ==========================================================================
  // Move State - PointAnnotation
  // ==========================================================================

  /// PointAnnotation currently being moved.
  PointAnnotationElement? _movingPointAnnotation;

  /// Original data point index at move start.
  int? _originalDataPointIndex;

  /// Candidate data point index during drag preview.
  int? _candidateDataPointIndex;

  // ==========================================================================
  // Move State - ThresholdAnnotation
  // ==========================================================================

  /// ThresholdAnnotation currently being moved.
  ThresholdAnnotationElement? _movingThresholdAnnotation;

  /// Position at move start.
  Offset? _moveThresholdStartPosition;

  /// Original threshold value at move start.
  double? _moveThresholdStartValue;

  // ==========================================================================
  // Move State - PinAnnotation
  // ==========================================================================

  /// PinAnnotation currently being moved.
  PinAnnotationElement? _movingPinAnnotation;

  /// Position at move start.
  Offset? _movePinStartPosition;

  /// Original X in data coordinates.
  double? _movePinStartX;

  /// Original Y in data coordinates.
  double? _movePinStartY;

  // ==========================================================================
  // Move State - LegendAnnotation
  // ==========================================================================

  /// LegendAnnotation currently being moved.
  LegendAnnotationElement? _movingLegendAnnotation;

  /// Position at move start.
  Offset? _moveLegendStartPosition;

  // ==========================================================================
  // Potential Drag State - Click vs Drag Detection
  // ==========================================================================

  /// Potential drag state for PointAnnotation.
  PointAnnotationElement? _potentialDragPointAnnotation;
  Offset? _potentialDragPointStartPosition;

  /// Potential drag state for RangeAnnotation.
  RangeAnnotationElement? _potentialDragRangeAnnotation;
  Offset? _potentialDragRangeStartPosition;
  Rect? _potentialDragRangeStartBounds;

  /// Potential drag state for TextAnnotation.
  TextAnnotationElement? _potentialDragTextAnnotation;
  Offset? _potentialDragTextStartPosition;

  /// Potential drag state for ThresholdAnnotation.
  ThresholdAnnotationElement? _potentialDragThresholdAnnotation;
  Offset? _potentialDragThresholdStartPosition;

  /// Potential drag state for PinAnnotation.
  PinAnnotationElement? _potentialDragPinAnnotation;
  Offset? _potentialDragPinStartPosition;

  /// Potential drag state for LegendAnnotation.
  LegendAnnotationElement? _potentialDragLegendAnnotation;
  Offset? _potentialDragLegendStartPosition;

  // ==========================================================================
  // State Queries
  // ==========================================================================

  /// Whether any annotation is currently being resized.
  bool get isResizing => _resizingAnnotation != null;

  /// Whether any annotation is currently being moved.
  bool get isMoving =>
      _movingAnnotation != null ||
      _movingTextAnnotation != null ||
      _movingPointAnnotation != null ||
      _movingThresholdAnnotation != null ||
      _movingPinAnnotation != null ||
      _movingLegendAnnotation != null;

  /// Whether any potential drag is pending (click started, waiting for movement).
  bool get hasPotentialDrag =>
      _potentialDragPointAnnotation != null ||
      _potentialDragRangeAnnotation != null ||
      _potentialDragTextAnnotation != null ||
      _potentialDragThresholdAnnotation != null ||
      _potentialDragPinAnnotation != null ||
      _potentialDragLegendAnnotation != null;

  /// The resizing annotation element (if any).
  RangeAnnotationElement? get resizingAnnotation => _resizingAnnotation;

  /// The active resize direction (if resizing).
  ResizeDirection? get activeResizeDirection => _activeResizeDirection;

  /// The currently moving PointAnnotation (if any).
  PointAnnotationElement? get movingPointAnnotation => _movingPointAnnotation;

  /// Candidate data point index during PointAnnotation drag.
  int? get candidateDataPointIndex => _candidateDataPointIndex;

  // ==========================================================================
  // Resize Operations
  // ==========================================================================

  /// Starts a resize operation on a RangeAnnotation.
  void startResize(
      RangeAnnotationElement annotation, ResizeDirection direction) {
    _resizingAnnotation = annotation;
    _activeResizeDirection = direction;
    _resizeStartBounds = annotation.bounds;
  }

  /// Performs resize operation during drag.
  ///
  /// Updates the annotation bounds based on delta from start position.
  /// Also updates temporary edge values for value label display.
  void performResize(Offset currentPosition, Offset startPosition) {
    if (_resizingAnnotation == null ||
        _activeResizeDirection == null ||
        _resizeStartBounds == null) {
      return;
    }

    final delta = currentPosition - startPosition;
    final oldBounds = _resizeStartBounds!;
    Rect newBounds;

    // Calculate new bounds based on resize direction
    switch (_activeResizeDirection!) {
      case ResizeDirection.topLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx,
            oldBounds.top + delta.dy, oldBounds.right, oldBounds.bottom);
      case ResizeDirection.topRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy,
            oldBounds.right + delta.dx, oldBounds.bottom);
      case ResizeDirection.bottomLeft:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top,
            oldBounds.right, oldBounds.bottom + delta.dy);
      case ResizeDirection.bottomRight:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top,
            oldBounds.right + delta.dx, oldBounds.bottom + delta.dy);
      case ResizeDirection.top:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top + delta.dy,
            oldBounds.right, oldBounds.bottom);
      case ResizeDirection.right:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top,
            oldBounds.right + delta.dx, oldBounds.bottom);
      case ResizeDirection.bottom:
        newBounds = Rect.fromLTRB(oldBounds.left, oldBounds.top,
            oldBounds.right, oldBounds.bottom + delta.dy);
      case ResizeDirection.left:
        newBounds = Rect.fromLTRB(oldBounds.left + delta.dx, oldBounds.top,
            oldBounds.right, oldBounds.bottom);
    }

    // Apply minimum size constraints (40x40 minimum)
    const minSize = 40.0;
    if (newBounds.width < minSize || newBounds.height < minSize) {
      return; // Don't allow resize below minimum
    }

    // Update annotation bounds
    _resizingAnnotation!.updateBounds(newBounds);

    // Update temporary edge values for value label display
    _updateResizeTempValues(newBounds);
  }

  /// Updates temporary edge values during resize for label display.
  void _updateResizeTempValues(Rect newBounds) {
    final elements = _delegate.elements;
    final seriesElements = elements.whereType<SeriesElement>();
    if (seriesElements.isEmpty) return;

    final seriesElement = seriesElements.first;
    final transform = seriesElement.transform;
    final annotation = _resizingAnnotation!.annotation;

    // Convert pixel bounds to data coordinates
    final leftData = transform.plotToData(newBounds.left, newBounds.top);
    final rightData = transform.plotToData(newBounds.right, newBounds.bottom);

    // Determine which edges are being resized
    double? tempStartX;
    double? tempEndX;
    double? tempStartY;
    double? tempEndY;

    // Only set temp values for edges that are being resized AND are bound
    if ((_activeResizeDirection == ResizeDirection.left ||
            _activeResizeDirection == ResizeDirection.topLeft ||
            _activeResizeDirection == ResizeDirection.bottomLeft) &&
        annotation.startX != null) {
      tempStartX = leftData.dx;
    }

    if ((_activeResizeDirection == ResizeDirection.right ||
            _activeResizeDirection == ResizeDirection.topRight ||
            _activeResizeDirection == ResizeDirection.bottomRight) &&
        annotation.endX != null) {
      tempEndX = rightData.dx;
    }

    if ((_activeResizeDirection == ResizeDirection.bottom ||
            _activeResizeDirection == ResizeDirection.bottomLeft ||
            _activeResizeDirection == ResizeDirection.bottomRight) &&
        annotation.startY != null) {
      tempStartY = rightData.dy; // Bottom pixel → lower Y data
    }

    if ((_activeResizeDirection == ResizeDirection.top ||
            _activeResizeDirection == ResizeDirection.topLeft ||
            _activeResizeDirection == ResizeDirection.topRight) &&
        annotation.endY != null) {
      tempEndY = leftData.dy; // Top pixel → higher Y data
    }

    // Update element with temporary values for label display
    _resizingAnnotation!.updateTempValues(
      startX: tempStartX,
      endX: tempEndX,
      startY: tempStartY,
      endY: tempEndY,
    );
  }

  /// Finalizes resize operation and commits the change.
  ///
  /// Returns the updated annotation for callback notification.
  RangeAnnotation? finalizeResize() {
    if (_resizingAnnotation == null) return null;

    final element = _resizingAnnotation!;
    final seriesElements = _delegate.elements.whereType<SeriesElement>();
    if (seriesElements.isEmpty) {
      cancelResize();
      return null;
    }

    final seriesElement = seriesElements.first;
    final transform = seriesElement.transform;
    final newBounds = element.bounds;
    final annotation = element.annotation;

    // Convert final bounds to data coordinates
    final topLeft = transform.plotToData(newBounds.left, newBounds.top);
    final bottomRight = transform.plotToData(newBounds.right, newBounds.bottom);

    // Create updated annotation with new data values
    final updatedAnnotation = annotation.copyWith(
      startX: annotation.startX != null ? topLeft.dx : null,
      endX: annotation.endX != null ? bottomRight.dx : null,
      startY: annotation.startY != null ? bottomRight.dy : null,
      endY: annotation.endY != null ? topLeft.dy : null,
    );

    // Clear temp values
    element.clearTempBounds();

    // Clear resize state
    cancelResize();

    // Rebuild spatial index
    _delegate.rebuildSpatialIndex();
    _delegate.markNeedsPaint();

    return updatedAnnotation;
  }

  /// Cancels resize operation without committing changes.
  void cancelResize() {
    _resizingAnnotation?.clearTempBounds();
    _resizingAnnotation = null;
    _activeResizeDirection = null;
    _resizeStartBounds = null;
  }

  // ==========================================================================
  // Move Operations - RangeAnnotation
  // ==========================================================================

  /// Starts a move operation on a RangeAnnotation.
  void startRangeMove(RangeAnnotationElement annotation, Offset position) {
    _movingAnnotation = annotation;
    _moveStartPosition = position;
    _moveStartBounds = annotation.bounds;
  }

  /// Performs move operation for RangeAnnotation during drag.
  void performRangeMove(Offset currentPosition) {
    if (_movingAnnotation == null ||
        _moveStartPosition == null ||
        _moveStartBounds == null) {
      return;
    }

    final delta = currentPosition - _moveStartPosition!;
    final oldBounds = _moveStartBounds!;

    // Calculate new bounds by shifting entire region
    final newBounds = Rect.fromLTRB(
      oldBounds.left + delta.dx,
      oldBounds.top + delta.dy,
      oldBounds.right + delta.dx,
      oldBounds.bottom + delta.dy,
    );

    _movingAnnotation!.updateBounds(newBounds);
  }

  /// Finalizes RangeAnnotation move and commits the change.
  RangeAnnotation? finalizeRangeMove() {
    if (_movingAnnotation == null) return null;

    final element = _movingAnnotation!;
    final seriesElements = _delegate.elements.whereType<SeriesElement>();
    if (seriesElements.isEmpty) {
      cancelRangeMove();
      return null;
    }

    final seriesElement = seriesElements.first;
    final transform = seriesElement.transform;
    final newBounds = element.bounds;
    final annotation = element.annotation;

    // Convert final bounds to data coordinates
    final topLeft = transform.plotToData(newBounds.left, newBounds.top);
    final bottomRight = transform.plotToData(newBounds.right, newBounds.bottom);

    // Create updated annotation with new data values
    final updatedAnnotation = annotation.copyWith(
      startX: annotation.startX != null ? topLeft.dx : null,
      endX: annotation.endX != null ? bottomRight.dx : null,
      startY: annotation.startY != null ? bottomRight.dy : null,
      endY: annotation.endY != null ? topLeft.dy : null,
    );

    // Clear move state
    cancelRangeMove();

    // Rebuild spatial index
    _delegate.rebuildSpatialIndex();
    _delegate.markNeedsPaint();

    return updatedAnnotation;
  }

  /// Cancels RangeAnnotation move without committing changes.
  void cancelRangeMove() {
    _movingAnnotation = null;
    _moveStartPosition = null;
    _moveStartBounds = null;
  }

  // ==========================================================================
  // Move Operations - PointAnnotation
  // ==========================================================================

  /// Starts a move operation on a PointAnnotation.
  void startPointMove(PointAnnotationElement annotation) {
    _movingPointAnnotation = annotation;
    _originalDataPointIndex = annotation.annotation.dataPointIndex;
    _candidateDataPointIndex = _originalDataPointIndex;
  }

  /// Performs move operation for PointAnnotation during drag.
  ///
  /// Finds the nearest data point in the same series and updates the candidate index.
  void performPointMove(
      Offset currentPosition, Offset Function(Offset) widgetToPlot) {
    if (_movingPointAnnotation == null) return;

    final annotation = _movingPointAnnotation!.annotation;
    final seriesId = annotation.seriesId;
    final transform = _delegate.transform;
    if (transform == null) return;

    // Convert current position to plot then data
    final plotPos = widgetToPlot(currentPosition);
    final dataPos = transform.plotToData(plotPos.dx, plotPos.dy);

    // Find series element
    SeriesElement? seriesElement;
    for (final element in _delegate.elements.whereType<SeriesElement>()) {
      if (element.id == seriesId) {
        seriesElement = element;
        break;
      }
    }

    if (seriesElement == null) return;

    // Find nearest data point by X distance
    final points = seriesElement.series.points;
    double nearestDistance = double.infinity;
    int? nearestIndex;

    for (int i = 0; i < points.length; i++) {
      final distance = (points[i].x - dataPos.dx).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    if (nearestIndex != null && nearestIndex != _candidateDataPointIndex) {
      _candidateDataPointIndex = nearestIndex;
      _movingPointAnnotation!.updateCandidateIndex(nearestIndex);
    } else if (nearestIndex == null) {
      _movingPointAnnotation!.updateCandidateIndex(_candidateDataPointIndex);
    }
  }

  /// Finalizes PointAnnotation move and commits the change.
  PointAnnotation? finalizePointMove() {
    if (_movingPointAnnotation == null) return null;

    final element = _movingPointAnnotation!;
    final annotation = element.annotation;

    // Only update if candidate differs from original
    if (_candidateDataPointIndex != _originalDataPointIndex &&
        _candidateDataPointIndex != null) {
      final updatedAnnotation = annotation.copyWith(
        dataPointIndex: _candidateDataPointIndex,
      );

      // Clear state
      element.clearCandidateIndex();
      cancelPointMove();

      _delegate.rebuildSpatialIndex();
      _delegate.markNeedsPaint();

      return updatedAnnotation;
    }

    // No change - just cancel
    element.clearCandidateIndex();
    cancelPointMove();
    _delegate.markNeedsPaint();
    return null;
  }

  /// Cancels PointAnnotation move without committing changes.
  void cancelPointMove() {
    _movingPointAnnotation?.clearCandidateIndex();
    _movingPointAnnotation = null;
    _originalDataPointIndex = null;
    _candidateDataPointIndex = null;
  }

  // ==========================================================================
  // Move Operations - TextAnnotation
  // ==========================================================================

  /// Starts a move operation on a TextAnnotation.
  void startTextMove(TextAnnotationElement annotation, Offset position) {
    _movingTextAnnotation = annotation;
    _moveTextStartPosition = position;
  }

  /// Performs move operation for TextAnnotation during drag.
  void performTextMove(Offset currentPosition) {
    if (_movingTextAnnotation == null || _moveTextStartPosition == null) return;

    final delta = currentPosition - _moveTextStartPosition!;
    final originalPosition = _movingTextAnnotation!.annotation.position;
    final newPosition =
        Offset(originalPosition.dx + delta.dx, originalPosition.dy + delta.dy);

    _movingTextAnnotation!.updateTempPosition(newPosition);
  }

  /// Finalizes TextAnnotation move and commits the change.
  TextAnnotation? finalizeTextMove() {
    if (_movingTextAnnotation == null) return null;

    final element = _movingTextAnnotation!;
    final tempPosition = element.tempPosition;

    if (tempPosition != null) {
      final updatedAnnotation = element.annotation.copyWith(
        position: tempPosition,
      );

      element.clearTempPosition();
      cancelTextMove();

      _delegate.rebuildSpatialIndex();
      _delegate.markNeedsPaint();

      return updatedAnnotation;
    }

    element.clearTempPosition();
    cancelTextMove();
    _delegate.markNeedsPaint();
    return null;
  }

  /// Cancels TextAnnotation move without committing changes.
  void cancelTextMove() {
    _movingTextAnnotation?.clearTempPosition();
    _movingTextAnnotation = null;
    _moveTextStartPosition = null;
  }

  // ==========================================================================
  // Move Operations - ThresholdAnnotation
  // ==========================================================================

  /// Starts a move operation on a ThresholdAnnotation.
  void startThresholdMove(
      ThresholdAnnotationElement annotation, Offset position) {
    _movingThresholdAnnotation = annotation;
    _moveThresholdStartPosition = position;
    _moveThresholdStartValue = annotation.annotation.value;
  }

  /// Performs move operation for ThresholdAnnotation during drag.
  void performThresholdMove(Offset currentPosition) {
    if (_movingThresholdAnnotation == null ||
        _moveThresholdStartPosition == null ||
        _moveThresholdStartValue == null) {
      return;
    }

    final element = _movingThresholdAnnotation!;
    final annotation = element.annotation;
    final transform = _delegate.transform;
    if (transform == null) return;

    // Calculate delta in plot pixels
    final delta = currentPosition - _moveThresholdStartPosition!;

    // Convert delta to data units based on axis
    final double newValue;
    if (annotation.axis == AnnotationAxis.y) {
      // Horizontal line: Y-axis constraint
      final plotHeight = transform.plotHeight;
      final dataRange = transform.dataYMax - transform.dataYMin;
      final dataPerPixel = dataRange / plotHeight;
      // Subtract delta.dy because screen Y increases downward
      newValue = _moveThresholdStartValue! - delta.dy * dataPerPixel;
    } else {
      // Vertical line: X-axis constraint
      final plotWidth = transform.plotWidth;
      final dataRange = transform.dataXMax - transform.dataXMin;
      final dataPerPixel = dataRange / plotWidth;
      newValue = _moveThresholdStartValue! + delta.dx * dataPerPixel;
    }

    element.updateTempValue(newValue);
  }

  /// Finalizes ThresholdAnnotation move and commits the change.
  ThresholdAnnotation? finalizeThresholdMove() {
    if (_movingThresholdAnnotation == null) return null;

    final element = _movingThresholdAnnotation!;
    final tempValue = element.tempValue;

    if (tempValue != null) {
      final updatedAnnotation = element.annotation.copyWith(
        value: tempValue,
      );

      element.clearTempValue();
      cancelThresholdMove();

      _delegate.rebuildSpatialIndex();
      _delegate.markNeedsPaint();

      return updatedAnnotation;
    }

    element.clearTempValue();
    cancelThresholdMove();
    _delegate.markNeedsPaint();
    return null;
  }

  /// Cancels ThresholdAnnotation move without committing changes.
  void cancelThresholdMove() {
    _movingThresholdAnnotation?.clearTempValue();
    _movingThresholdAnnotation = null;
    _moveThresholdStartPosition = null;
    _moveThresholdStartValue = null;
  }

  // ==========================================================================
  // Move Operations - PinAnnotation
  // ==========================================================================

  /// Starts a move operation on a PinAnnotation.
  void startPinMove(PinAnnotationElement annotation, Offset position) {
    _movingPinAnnotation = annotation;
    _movePinStartPosition = position;
    _movePinStartX = annotation.annotation.x;
    _movePinStartY = annotation.annotation.y;
  }

  /// Performs move operation for PinAnnotation during drag.
  void performPinMove(Offset currentPosition) {
    if (_movingPinAnnotation == null ||
        _movePinStartPosition == null ||
        _movePinStartX == null ||
        _movePinStartY == null) {
      return;
    }

    final transform = _delegate.transform;
    if (transform == null) return;

    // Convert delta from plot to data coordinates
    final delta = currentPosition - _movePinStartPosition!;
    final dataPerPixelX =
        (transform.dataXMax - transform.dataXMin) / transform.plotWidth;
    final dataPerPixelY =
        (transform.dataYMax - transform.dataYMin) / transform.plotHeight;

    final newX = _movePinStartX! + delta.dx * dataPerPixelX;
    // Subtract delta.dy because screen Y increases downward but data Y increases upward
    final newY = _movePinStartY! - delta.dy * dataPerPixelY;

    _movingPinAnnotation!.updateTempPosition(newX, newY);
  }

  /// Finalizes PinAnnotation move and commits the change.
  PinAnnotation? finalizePinMove() {
    if (_movingPinAnnotation == null) return null;

    final element = _movingPinAnnotation!;
    final tempPos = element.tempPosition;

    if (tempPos != null) {
      final (tempX, tempY) = tempPos;
      final updatedAnnotation = element.annotation.copyWith(
        x: tempX,
        y: tempY,
      );

      element.clearTempPosition();
      cancelPinMove();

      _delegate.rebuildSpatialIndex();
      _delegate.markNeedsPaint();

      return updatedAnnotation;
    }

    element.clearTempPosition();
    cancelPinMove();
    _delegate.markNeedsPaint();
    return null;
  }

  /// Cancels PinAnnotation move without committing changes.
  void cancelPinMove() {
    _movingPinAnnotation?.clearTempPosition();
    _movingPinAnnotation = null;
    _movePinStartPosition = null;
    _movePinStartX = null;
    _movePinStartY = null;
  }

  // ==========================================================================
  // Move Operations - LegendAnnotation
  // ==========================================================================

  /// Starts a move operation on a LegendAnnotation.
  void startLegendMove(LegendAnnotationElement annotation, Offset position) {
    _movingLegendAnnotation = annotation;
    _moveLegendStartPosition = position;
  }

  /// Performs move operation for LegendAnnotation during drag.
  void performLegendMove(Offset currentPosition) {
    if (_movingLegendAnnotation == null || _moveLegendStartPosition == null)
      return;

    final delta = currentPosition - _moveLegendStartPosition!;
    final currentBounds = _movingLegendAnnotation!.bounds;
    final newTopLeft =
        Offset(currentBounds.left + delta.dx, currentBounds.top + delta.dy);

    _movingLegendAnnotation!.updateTempPosition(newTopLeft);
    _moveLegendStartPosition = currentPosition; // Update for continuous delta
  }

  /// Finalizes LegendAnnotation move and commits the change.
  LegendAnnotation? finalizeLegendMove() {
    if (_movingLegendAnnotation == null) return null;

    final element = _movingLegendAnnotation!;
    final tempPosition = element.tempPosition;

    if (tempPosition != null) {
      final updatedAnnotation = element.annotation.copyWith(
        customPosition: tempPosition,
      );

      element.clearTempPosition();
      cancelLegendMove();

      _delegate.rebuildSpatialIndex();
      _delegate.markNeedsPaint();

      return updatedAnnotation;
    }

    element.clearTempPosition();
    cancelLegendMove();
    _delegate.markNeedsPaint();
    return null;
  }

  /// Cancels LegendAnnotation move without committing changes.
  void cancelLegendMove() {
    _movingLegendAnnotation?.clearTempPosition();
    _movingLegendAnnotation = null;
    _moveLegendStartPosition = null;
  }

  // ==========================================================================
  // Potential Drag State - Click vs Drag Detection
  // ==========================================================================

  /// Sets potential drag state for PointAnnotation.
  void setPotentialPointDrag(
      PointAnnotationElement annotation, Offset position) {
    _potentialDragPointAnnotation = annotation;
    _potentialDragPointStartPosition = position;
  }

  /// Clears potential drag state for PointAnnotation.
  void clearPotentialPointDrag() {
    _potentialDragPointAnnotation = null;
    _potentialDragPointStartPosition = null;
  }

  /// Gets potential PointAnnotation drag info.
  (PointAnnotationElement?, Offset?) get potentialPointDrag =>
      (_potentialDragPointAnnotation, _potentialDragPointStartPosition);

  /// Sets potential drag state for RangeAnnotation.
  void setPotentialRangeDrag(
      RangeAnnotationElement annotation, Offset position) {
    _potentialDragRangeAnnotation = annotation;
    _potentialDragRangeStartPosition = position;
    _potentialDragRangeStartBounds = annotation.bounds;
  }

  /// Clears potential drag state for RangeAnnotation.
  void clearPotentialRangeDrag() {
    _potentialDragRangeAnnotation = null;
    _potentialDragRangeStartPosition = null;
    _potentialDragRangeStartBounds = null;
  }

  /// Gets potential RangeAnnotation drag info.
  (RangeAnnotationElement?, Offset?, Rect?) get potentialRangeDrag => (
        _potentialDragRangeAnnotation,
        _potentialDragRangeStartPosition,
        _potentialDragRangeStartBounds
      );

  /// Sets potential drag state for TextAnnotation.
  void setPotentialTextDrag(TextAnnotationElement annotation, Offset position) {
    _potentialDragTextAnnotation = annotation;
    _potentialDragTextStartPosition = position;
  }

  /// Clears potential drag state for TextAnnotation.
  void clearPotentialTextDrag() {
    _potentialDragTextAnnotation = null;
    _potentialDragTextStartPosition = null;
  }

  /// Gets potential TextAnnotation drag info.
  (TextAnnotationElement?, Offset?) get potentialTextDrag =>
      (_potentialDragTextAnnotation, _potentialDragTextStartPosition);

  /// Sets potential drag state for ThresholdAnnotation.
  void setPotentialThresholdDrag(
      ThresholdAnnotationElement annotation, Offset position) {
    _potentialDragThresholdAnnotation = annotation;
    _potentialDragThresholdStartPosition = position;
  }

  /// Clears potential drag state for ThresholdAnnotation.
  void clearPotentialThresholdDrag() {
    _potentialDragThresholdAnnotation = null;
    _potentialDragThresholdStartPosition = null;
  }

  /// Gets potential ThresholdAnnotation drag info.
  (ThresholdAnnotationElement?, Offset?) get potentialThresholdDrag =>
      (_potentialDragThresholdAnnotation, _potentialDragThresholdStartPosition);

  /// Sets potential drag state for PinAnnotation.
  void setPotentialPinDrag(PinAnnotationElement annotation, Offset position) {
    _potentialDragPinAnnotation = annotation;
    _potentialDragPinStartPosition = position;
  }

  /// Clears potential drag state for PinAnnotation.
  void clearPotentialPinDrag() {
    _potentialDragPinAnnotation = null;
    _potentialDragPinStartPosition = null;
  }

  /// Gets potential PinAnnotation drag info.
  (PinAnnotationElement?, Offset?) get potentialPinDrag =>
      (_potentialDragPinAnnotation, _potentialDragPinStartPosition);

  /// Sets potential drag state for LegendAnnotation.
  void setPotentialLegendDrag(
      LegendAnnotationElement annotation, Offset position) {
    _potentialDragLegendAnnotation = annotation;
    _potentialDragLegendStartPosition = position;
  }

  /// Clears potential drag state for LegendAnnotation.
  void clearPotentialLegendDrag() {
    _potentialDragLegendAnnotation = null;
    _potentialDragLegendStartPosition = null;
  }

  /// Gets potential LegendAnnotation drag info.
  (LegendAnnotationElement?, Offset?) get potentialLegendDrag =>
      (_potentialDragLegendAnnotation, _potentialDragLegendStartPosition);

  /// Checks if pointer has moved beyond drag threshold.
  bool exceedsDragThreshold(Offset startPosition, Offset currentPosition) {
    return (currentPosition - startPosition).distance > dragThresholdPixels;
  }

  // ==========================================================================
  // Clear All State
  // ==========================================================================

  /// Clears all drag/move/resize state.
  void clearAllState() {
    cancelResize();
    cancelRangeMove();
    cancelPointMove();
    cancelTextMove();
    cancelThresholdMove();
    cancelPinMove();
    cancelLegendMove();
    clearPotentialPointDrag();
    clearPotentialRangeDrag();
    clearPotentialTextDrag();
    clearPotentialThresholdDrag();
    clearPotentialPinDrag();
    clearPotentialLegendDrag();
  }

  /// Disposes of resources.
  void dispose() {
    clearAllState();
  }
}
