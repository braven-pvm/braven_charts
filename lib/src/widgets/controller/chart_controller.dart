import 'package:braven_charts/src/foundation/data_models/chart_data_point.dart';
import 'package:flutter/material.dart';

import '../annotations/chart_annotation.dart';
import '../annotations/text_annotation.dart';

/// ChangeNotifier-based controller for programmatic chart updates.
///
/// Manages chart data and annotations, providing methods for real-time
/// updates with automatic listener notification.
///
/// Example:
/// ```dart
/// final controller = ChartController();
///
/// // Add data points
/// controller.addPoint('temperature', ChartDataPoint(x: 0, y: 20.0));
/// controller.addPoint('temperature', ChartDataPoint(x: 1, y: 22.5));
///
/// // Add annotations
/// controller.addAnnotation(
///   TextAnnotation(
///     position: Offset(100, 50),
///     label: 'High temp alert',
///   ),
/// );
///
/// // Clean up
/// controller.dispose();
/// ```
class ChartController extends ChangeNotifier {
  /// Internal data storage: series ID -> list of data points.
  final Map<String, List<ChartDataPoint>> _seriesData = {};

  /// Internal annotation storage: annotation ID -> annotation.
  final Map<String, ChartAnnotation> _annotations = {};

  /// Counter for generating annotation IDs.
  int _annotationIdCounter = 0;

  // ========== Data Management Methods ==========

  /// Adds a data point to the specified series.
  ///
  /// If the series doesn't exist, it will be created.
  /// Validates that coordinates are not NaN or infinity.
  /// Notifies listeners after the point is added.
  ///
  /// Throws [AssertionError] if coordinates are NaN or infinity.
  void addPoint(String seriesId, ChartDataPoint point) {
    assert(
      point.x.isFinite && point.y.isFinite,
      'Cannot add point with NaN or infinity coordinates',
    );

    final series = _seriesData.putIfAbsent(seriesId, () => []);
    series.add(point);

    notifyListeners();
  }

  /// Removes the oldest point from the specified series.
  ///
  /// Does nothing if the series doesn't exist or is empty.
  /// Notifies listeners after the point is removed.
  void removeOldestPoint(String seriesId) {
    final series = _seriesData[seriesId];
    if (series == null || series.isEmpty) return;

    series.removeAt(0);

    notifyListeners();
  }

  /// Clears all points from the specified series.
  ///
  /// The series will still exist but will be empty.
  /// Notifies listeners after clearing.
  void clearSeries(String seriesId) {
    final series = _seriesData[seriesId];
    if (series == null) return;

    series.clear();

    notifyListeners();
  }

  /// Returns a copy of all series data.
  ///
  /// Returns a new map instance to prevent external modification.
  /// Each series list is also copied.
  Map<String, List<ChartDataPoint>> getAllSeries() {
    return Map.fromEntries(
      _seriesData.entries.map(
        (entry) => MapEntry(entry.key, List.from(entry.value)),
      ),
    );
  }

  // ========== Annotation Management Methods ==========

  /// Adds a chart-level text annotation.
  ///
  /// Only TextAnnotation is supported at chart level since it's not tied to a specific series.
  /// For series-specific annotations (Point, Range, Threshold, Trend), add them to ChartSeries.annotations.
  ///
  /// Returns the annotation's ID. If the annotation already has an ID,
  /// that ID is used. Otherwise, a new ID is auto-generated.
  ///
  /// Notifies listeners after the annotation is added.
  String addAnnotation(TextAnnotation annotation) {
    final id = annotation.id.isEmpty ? 'annotation_${_annotationIdCounter++}' : annotation.id;

    _annotations[id] = annotation;
    notifyListeners();
    return id;
  }

  /// Removes an annotation by ID.
  ///
  /// Does nothing if the annotation doesn't exist.
  /// Notifies listeners after removal.
  void removeAnnotation(String id) {
    if (!_annotations.containsKey(id)) return;

    _annotations.remove(id);
    notifyListeners();
  }

  /// Updates an existing chart-level text annotation.
  ///
  /// Only TextAnnotation is supported at chart level.
  /// Throws [StateError] if the annotation doesn't exist.
  /// Notifies listeners after the update.
  void updateAnnotation(String id, TextAnnotation annotation) {
    if (!_annotations.containsKey(id)) {
      throw StateError('Cannot update non-existent annotation: $id');
    }

    _annotations[id] = annotation;
    notifyListeners();
  }

  /// Returns a chart-level text annotation by ID, or null if not found.
  TextAnnotation? getAnnotation(String id) {
    final annotation = _annotations[id];
    return annotation is TextAnnotation ? annotation : null;
  }

  /// Returns a copy of all chart-level text annotations as a list.
  ///
  /// Returns a new list instance to prevent external modification.
  List<TextAnnotation> getAllAnnotations() {
    return _annotations.values.whereType<TextAnnotation>().toList();
  }

  /// Clears all annotations from the chart.
  ///
  /// Notifies listeners after clearing.
  void clearAnnotations() {
    _annotations.clear();
    notifyListeners();
  }

  /// Finds annotations near the specified position.
  ///
  /// Returns annotations where the position is within a reasonable
  /// hit-test area (approximately 20 pixels).
  ///
  /// For TextAnnotation: checks if position is near the annotation's position.
  /// For other types: returns empty list (not yet implemented).
  List<ChartAnnotation> findAnnotationsAt(Offset position) {
    const hitTestRadius = 20.0;
    final found = <ChartAnnotation>[];

    for (final annotation in _annotations.values) {
      // Check if annotation has a position property (TextAnnotation)
      try {
        final annotationPosition = (annotation as dynamic).position as Offset?;
        if (annotationPosition == null) continue;

        final dx = (annotationPosition.dx - position.dx).abs();
        final dy = (annotationPosition.dy - position.dy).abs();

        if (dx <= hitTestRadius && dy <= hitTestRadius) {
          found.add(annotation);
        }
      } catch (_) {
        // Annotation doesn't have position property, skip
        continue;
      }
    }

    return found;
  }

  // ========== Lifecycle ==========

  @override
  void dispose() {
    _seriesData.clear();
    _annotations.clear();
    super.dispose();
  }
}
