// Copyright (c) 2025 braven_charts. All rights reserved.

import 'package:flutter/foundation.dart';

import '../models/chart_annotation.dart';

/// Controller for managing chart annotations with CRUD operations, selection,
/// and reactive updates.
///
/// Provides a centralized way to manage annotations with features like:
/// - Add, update, delete, and clear annotations
/// - Batch operations for multiple annotations
/// - Selection management
/// - Reactive updates via [ChangeNotifier]
/// - Type-safe queries
///
/// Example usage:
/// ```dart
/// final controller = AnnotationController();
///
/// // Add annotations
/// controller.addAnnotation(RangeAnnotation(
///   id: 'range1',
///   startX: 5.0,
///   endX: 7.0,
///   label: 'Weekend',
/// ));
///
/// // Update annotation (e.g., after drag)
/// controller.updateAnnotation('range1', updatedAnnotation);
///
/// // Listen to changes
/// controller.addListener(() {
///   print('Annotations changed: ${controller.annotations.length}');
/// });
///
/// // Use with BravenChartPlus
/// BravenChartPlus(
///   annotationController: controller,
///   // ...
/// )
/// ```
class AnnotationController extends ChangeNotifier {
  /// Creates an [AnnotationController] with an optional initial list of annotations.
  AnnotationController({List<ChartAnnotation>? initialAnnotations})
    : _annotations = initialAnnotations != null
          ? List.from(initialAnnotations)
          : [];

  // Private state
  List<ChartAnnotation> _annotations;
  String? _selectedAnnotationId;

  /// Returns an unmodifiable view of all annotations.
  ///
  /// To modify annotations, use the provided mutation methods like
  /// [addAnnotation], [updateAnnotation], or [removeAnnotation].
  List<ChartAnnotation> get annotations => List.unmodifiable(_annotations);

  /// The ID of the currently selected annotation, or null if none selected.
  String? get selectedAnnotationId => _selectedAnnotationId;

  /// Gets the currently selected annotation, or null if none selected.
  ChartAnnotation? get selectedAnnotation {
    if (_selectedAnnotationId == null) return null;
    return getAnnotation(_selectedAnnotationId!);
  }

  /// Returns the number of annotations.
  int get length => _annotations.length;

  /// Returns true if there are no annotations.
  bool get isEmpty => _annotations.isEmpty;

  /// Returns true if there are any annotations.
  bool get isNotEmpty => _annotations.isNotEmpty;

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Adds a new annotation to the chart.
  ///
  /// Throws [ArgumentError] if an annotation with the same ID already exists.
  void addAnnotation(ChartAnnotation annotation) {
    if (_annotations.any((a) => a.id == annotation.id)) {
      throw ArgumentError(
        'Annotation with id "${annotation.id}" already exists',
      );
    }
    _annotations.add(annotation);
    notifyListeners();
  }

  /// Updates an existing annotation.
  ///
  /// The [id] must match an existing annotation. The [updated] annotation
  /// replaces the old one entirely (including the ID).
  ///
  /// Throws [ArgumentError] if no annotation with [id] exists.
  void updateAnnotation(String id, ChartAnnotation updated) {
    final index = _annotations.indexWhere((a) => a.id == id);
    if (index == -1) {
      throw ArgumentError('No annotation with id "$id" found');
    }

    // Ensure the updated annotation has the same ID
    if (updated.id != id) {
      throw ArgumentError(
        'Updated annotation ID "${updated.id}" does not match original ID "$id"',
      );
    }

    _annotations[index] = updated;
    notifyListeners();
  }

  /// Removes an annotation by ID.
  ///
  /// Returns true if an annotation was removed, false if no annotation
  /// with the given ID exists.
  ///
  /// If the removed annotation was selected, the selection is cleared.
  bool removeAnnotation(String id) {
    final initialLength = _annotations.length;
    _annotations.removeWhere((a) => a.id == id);

    final wasRemoved = _annotations.length < initialLength;
    if (wasRemoved) {
      // Clear selection if the removed annotation was selected
      if (_selectedAnnotationId == id) {
        _selectedAnnotationId = null;
      }
      notifyListeners();
    }

    return wasRemoved;
  }

  /// Removes all annotations and clears the selection.
  void clearAnnotations() {
    if (_annotations.isEmpty) return;

    _annotations.clear();
    _selectedAnnotationId = null;
    notifyListeners();
  }

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Adds multiple annotations at once.
  ///
  /// Throws [ArgumentError] if any annotation ID already exists or if there
  /// are duplicate IDs in the provided list.
  ///
  /// This is more efficient than calling [addAnnotation] multiple times as
  /// it only notifies listeners once.
  void addAll(List<ChartAnnotation> annotations) {
    if (annotations.isEmpty) return;

    // Validate no duplicates in input
    final inputIds = annotations.map((a) => a.id).toSet();
    if (inputIds.length != annotations.length) {
      throw ArgumentError('Duplicate annotation IDs in input list');
    }

    // Validate no conflicts with existing annotations
    for (final annotation in annotations) {
      if (_annotations.any((a) => a.id == annotation.id)) {
        throw ArgumentError(
          'Annotation with id "${annotation.id}" already exists',
        );
      }
    }

    _annotations.addAll(annotations);
    notifyListeners();
  }

  /// Updates multiple annotations at once.
  ///
  /// The [updates] map should contain annotation IDs as keys and the updated
  /// annotations as values. Only annotations with matching IDs are updated.
  ///
  /// Throws [ArgumentError] if any annotation ID doesn't exist or if the
  /// updated annotation's ID doesn't match the key.
  ///
  /// This is more efficient than calling [updateAnnotation] multiple times.
  void updateAll(Map<String, ChartAnnotation> updates) {
    if (updates.isEmpty) return;

    // Validate all IDs exist and updated annotations have matching IDs
    for (final entry in updates.entries) {
      final id = entry.key;
      final updated = entry.value;

      if (!_annotations.any((a) => a.id == id)) {
        throw ArgumentError('No annotation with id "$id" found');
      }

      if (updated.id != id) {
        throw ArgumentError(
          'Updated annotation ID "${updated.id}" does not match key "$id"',
        );
      }
    }

    // Apply all updates
    for (final entry in updates.entries) {
      final index = _annotations.indexWhere((a) => a.id == entry.key);
      _annotations[index] = entry.value;
    }

    notifyListeners();
  }

  /// Removes multiple annotations by their IDs.
  ///
  /// Returns the number of annotations that were actually removed.
  ///
  /// If any removed annotation was selected, the selection is cleared.
  int removeAll(List<String> ids) {
    if (ids.isEmpty) return 0;

    final initialLength = _annotations.length;
    _annotations.removeWhere((a) => ids.contains(a.id));

    final removedCount = initialLength - _annotations.length;
    if (removedCount > 0) {
      // Clear selection if it was in the removed set
      if (_selectedAnnotationId != null &&
          ids.contains(_selectedAnnotationId)) {
        _selectedAnnotationId = null;
      }
      notifyListeners();
    }

    return removedCount;
  }

  /// Replaces all annotations with a new list.
  ///
  /// This clears existing annotations and adds the new ones.
  /// The selection is preserved if an annotation with the same ID exists
  /// in the new list, otherwise it's cleared.
  ///
  /// Throws [ArgumentError] if there are duplicate IDs in [annotations].
  void replaceAll(List<ChartAnnotation> annotations) {
    // Validate no duplicates
    final ids = annotations.map((a) => a.id).toSet();
    if (ids.length != annotations.length) {
      throw ArgumentError('Duplicate annotation IDs in replacement list');
    }

    _annotations = List.from(annotations);

    // Clear selection if the selected annotation no longer exists
    if (_selectedAnnotationId != null) {
      if (!_annotations.any((a) => a.id == _selectedAnnotationId)) {
        _selectedAnnotationId = null;
      }
    }

    notifyListeners();
  }

  // ============================================================================
  // Selection Management
  // ============================================================================

  /// Selects an annotation by ID.
  ///
  /// Pass null to clear the selection.
  ///
  /// Throws [ArgumentError] if the ID doesn't match any annotation.
  void selectAnnotation(String? id) {
    if (id != null && !_annotations.any((a) => a.id == id)) {
      throw ArgumentError('No annotation with id "$id" found');
    }

    if (_selectedAnnotationId != id) {
      _selectedAnnotationId = id;
      notifyListeners();
    }
  }

  /// Clears the current selection.
  void clearSelection() {
    if (_selectedAnnotationId != null) {
      _selectedAnnotationId = null;
      notifyListeners();
    }
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Gets an annotation by ID, or null if not found.
  ChartAnnotation? getAnnotation(String id) {
    try {
      return _annotations.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns all annotations of a specific type.
  ///
  /// Example:
  /// ```dart
  /// final rangeAnnotations = controller.getAnnotationsByType<RangeAnnotation>();
  /// ```
  List<T> getAnnotationsByType<T extends ChartAnnotation>() {
    return _annotations.whereType<T>().toList();
  }

  /// Returns all annotations that match the given predicate.
  List<ChartAnnotation> where(bool Function(ChartAnnotation) predicate) {
    return _annotations.where(predicate).toList();
  }

  /// Returns true if any annotation matches the given predicate.
  bool any(bool Function(ChartAnnotation) predicate) {
    return _annotations.any(predicate);
  }

  /// Returns true if all annotations match the given predicate.
  bool every(bool Function(ChartAnnotation) predicate) {
    return _annotations.every(predicate);
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  /// Returns true if an annotation with the given ID exists.
  bool containsId(String id) {
    return _annotations.any((a) => a.id == id);
  }

  /// Returns the index of an annotation by ID, or -1 if not found.
  int indexOf(String id) {
    return _annotations.indexWhere((a) => a.id == id);
  }

  @override
  void dispose() {
    _annotations.clear();
    _selectedAnnotationId = null;
    super.dispose();
  }

  @override
  String toString() {
    return 'AnnotationController(annotations: ${_annotations.length}, selected: $_selectedAnnotationId)';
  }
}
