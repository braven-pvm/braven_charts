// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chart_element.dart';
import 'interaction_mode.dart';

/// Information about a hovered marker within a series.
///
/// Used to track which specific marker (datapoint) is being hovered,
/// allowing per-marker visual feedback without creating individual elements.
class HoveredMarkerInfo {
  const HoveredMarkerInfo({
    required this.seriesId,
    required this.markerIndex,
    required this.plotPosition,
  });

  /// ID of the series containing the hovered marker.
  final String seriesId;

  /// Index of the hovered marker within the series.points list.
  final int markerIndex;

  /// Position of the marker in plot coordinates.
  final Offset plotPosition;

  /// Checks if this marker refers to the same data point as [other].
  ///
  /// This compares only [seriesId] and [markerIndex], ignoring [plotPosition].
  /// Useful for tooltip logic where we care about marker identity, not exact position.
  bool sameMarkerAs(HoveredMarkerInfo? other) {
    if (other == null) return false;
    return seriesId == other.seriesId && markerIndex == other.markerIndex;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoveredMarkerInfo &&
        other.seriesId == seriesId &&
        other.markerIndex == markerIndex &&
        other.plotPosition == plotPosition;
  }

  @override
  int get hashCode => Object.hash(seriesId, markerIndex, plotPosition);
}

/// Central coordinator for all chart interactions.
///
/// **Purpose**: Prevent gesture arena conflicts via explicit state management.
///
/// **Responsibilities** (per INTERACTION_ARCHITECTURE_DESIGN.md):
/// - Track current interaction mode (idle, panning, dragging, selecting, etc.)
/// - Claim/release interaction rights to prevent conflicts
/// - Track keyboard modifier state (Ctrl, Shift, Alt)
/// - Notify listeners of interaction state changes
///
/// **Integration**: Use with Provider/Riverpod for widget tree access.
///
/// **Conflict Resolution**: Before accepting a gesture, custom recognizers
/// must check if the coordinator allows that interaction based on current mode
/// and priority levels from CONFLICT_RESOLUTION_TABLE.md.
class ChartInteractionCoordinator extends ChangeNotifier {
  /// Whether this coordinator has been disposed.
  bool _isDisposed = false;

  /// Returns true if this coordinator has been disposed.
  bool get isDisposed => _isDisposed;

  /// Current interaction mode.
  InteractionMode _currentMode = InteractionMode.idle;

  /// Currently active (focused) element during interaction.
  ChartElement? _activeElement;

  /// Set of all currently selected elements.
  final Set<ChartElement> _selectedElements = {};

  /// Set of elements in preview selection (during box drag, before commit).
  final Set<ChartElement> _previewSelection = {};

  /// Currently hovered element (if any).
  ChartElement? _hoveredElement;

  /// Currently hovered marker within a series (if any).
  ///
  /// Tracks per-marker hover state without creating individual marker elements.
  /// Allows highlighting individual datapoints while preserving SeriesElement
  /// as single spatial index entry (performance optimization).
  HoveredMarkerInfo? _hoveredMarker;

  /// Set of currently pressed keyboard modifier keys.
  final Set<LogicalKeyboardKey> _modifierKeys = {};

  /// Position where current interaction started (for drag distance calculations).
  Offset? _interactionStartPosition;

  /// Element that interaction started on (for determining drag vs select).
  ChartElement? _interactionStartElement;

  /// Box selection rectangle (if boxSelecting mode is active).
  Rect? _boxSelectionRect;

  // ============================================================================
  // Public Getters
  // ============================================================================

  /// Current interaction mode.
  InteractionMode get currentMode => _currentMode;

  /// Currently active element (being dragged, resized, edited, etc.).
  ChartElement? get activeElement => _activeElement;

  /// All currently selected elements.
  Set<ChartElement> get selectedElements => Set.unmodifiable(_selectedElements);

  /// Elements in preview selection (during box drag, before commit).
  Set<ChartElement> get previewSelectedElements =>
      Set.unmodifiable(_previewSelection);

  /// Currently hovered element.
  ChartElement? get hoveredElement => _hoveredElement;

  /// Currently hovered marker within a series.
  HoveredMarkerInfo? get hoveredMarker => _hoveredMarker;

  /// Whether Ctrl/Command modifier is pressed.
  bool get isCtrlPressed =>
      _modifierKeys.contains(LogicalKeyboardKey.control) ||
      _modifierKeys.contains(LogicalKeyboardKey.meta);

  /// Whether Shift modifier is pressed.
  bool get isShiftPressed => _modifierKeys.contains(LogicalKeyboardKey.shift);

  /// Whether Alt/Option modifier is pressed.
  bool get isAltPressed => _modifierKeys.contains(LogicalKeyboardKey.alt);

  /// Position where current interaction started.
  Offset? get interactionStartPosition => _interactionStartPosition;

  /// Element that interaction started on.
  ChartElement? get interactionStartElement => _interactionStartElement;

  /// Current box selection rectangle (if in boxSelecting mode).
  Rect? get boxSelectionRect => _boxSelectionRect;

  /// Whether chart is currently in a modal state (blocks other interactions).
  bool get isModal => _currentMode.isModal;

  /// Whether chart is currently in a dragging state.
  bool get isDragging => _currentMode.isDragging;

  /// Whether chart is currently panning.
  ///
  /// Per conflict resolution scenario 12: Tooltips should be suspended while panning.
  bool get isPanning => _currentMode == InteractionMode.panning;

  /// Whether chart is currently zooming.
  ///
  /// Tooltips should be hidden during zoom operations.
  bool get isZooming => _currentMode == InteractionMode.zooming;

  /// Whether chart is actively panning or zooming.
  ///
  /// Tooltips and crosshair labels should be hidden during these operations.
  bool get isPanningOrZooming => isPanning || isZooming;

  /// Whether chart is currently in a selecting state.
  bool get isSelecting => _currentMode.isSelecting;

  /// Whether an interaction is currently in progress (not idle/hovering).
  bool get isInteracting => !_currentMode.isPassive;

  // ============================================================================
  // Interaction Mode Management
  // ============================================================================

  /// Attempts to claim an interaction mode.
  ///
  /// Returns true if the mode was claimed successfully, false if blocked.
  ///
  /// **Conflict Resolution Logic**:
  /// - Modal modes (contextMenuOpen, editingAnnotation) block all other modes
  /// - Higher priority modes block lower priority modes
  /// - Same priority modes: first claimed wins
  ///
  /// [requestedMode] is the mode being requested.
  /// [element] is the element associated with this mode (if any).
  bool claimMode(InteractionMode requestedMode, {ChartElement? element}) {
    // Modal states block everything except themselves
    if (_currentMode.isModal && requestedMode != _currentMode) {
      return false;
    }

    // Check priority: higher priority can interrupt lower priority
    if (_currentMode.priority > requestedMode.priority) {
      return false;
    }

    // Clear hovered marker when entering zoom/pan modes
    // This prevents stale marker positions from being used after zoom/pan completes
    if (requestedMode == InteractionMode.zooming ||
        requestedMode == InteractionMode.panning) {
      _hoveredMarker = null;
    }

    // Allow mode claim
    _setMode(requestedMode, element: element);
    return true;
  }

  /// Sets the interaction mode (internal).
  void _setMode(InteractionMode mode, {ChartElement? element}) {
    if (_currentMode == mode && _activeElement == element) {
      return; // No change
    }

    _currentMode = mode;
    _activeElement = element;

    // Reset interaction state when returning to idle
    if (mode == InteractionMode.idle) {
      _interactionStartPosition = null;
      _interactionStartElement = null;
      _boxSelectionRect = null;
    }

    notifyListeners();
  }

  /// Releases the current interaction mode and returns to idle.
  ///
  /// [force] if true, releases even modal modes (use with caution).
  void releaseMode({bool force = false}) {
    if (_currentMode.isModal && !force) {
      return; // Don't release modal modes unless forced
    }

    _setMode(InteractionMode.idle);
  }

  /// Forces the mode to idle regardless of current state.
  ///
  /// Use for error recovery or cancel operations (e.g., Escape key).
  void forceIdle() {
    _setMode(InteractionMode.idle);
  }

  // ============================================================================
  // Selection Management
  // ============================================================================

  /// Selects a single element, clearing previous selection.
  ///
  /// Per conflict resolution: Left-click on element = select.
  void selectElement(ChartElement element) {
    if (!element.isSelectable) return;

    clearSelection();
    _selectedElements.add(element);
    element.onSelect();
    notifyListeners();
  }

  /// Toggles selection of an element (for Ctrl+Click multi-select).
  ///
  /// Per conflict resolution scenario 9: Ctrl+Click toggles selection.
  void toggleElementSelection(ChartElement element) {
    if (!element.isSelectable) return;

    if (_selectedElements.contains(element)) {
      _selectedElements.remove(element);
      element.onDeselect();
    } else {
      _selectedElements.add(element);
      element.onSelect();
    }
    notifyListeners();
  }

  /// Adds multiple elements to selection (for box select).
  ///
  /// Per conflict resolution scenario 5 & 14: Box-select adds only datapoints.
  void addToSelection(Set<ChartElement> elements) {
    for (final element in elements) {
      if (element.isSelectable && !_selectedElements.contains(element)) {
        _selectedElements.add(element);
        element.onSelect();
      }
    }
    notifyListeners();
  }

  /// Clears all selected elements.
  void clearSelection() {
    for (final element in _selectedElements) {
      element.onDeselect();
    }
    _selectedElements.clear();
    notifyListeners();
  }

  /// Returns true if the given element is selected.
  bool isElementSelected(ChartElement element) {
    return _selectedElements.contains(element);
  }

  // ============================================================================
  // Hover Management
  // ============================================================================

  /// Sets the currently hovered element.
  ///
  /// Per conflict resolution: Hover is passive and doesn't claim interactions.
  /// Per scenario 12: Hover/tooltips suspended during panning.
  void setHoveredElement(ChartElement? element) {
    if (_hoveredElement == element) return;

    // Exit previous hover
    _hoveredElement?.onHoverExit();

    _hoveredElement = element;

    // Enter new hover (if not panning - per scenario 12)
    if (element != null && !isPanning) {
      element.onHoverEnter();
      if (_currentMode == InteractionMode.idle) {
        _setMode(InteractionMode.hovering, element: element);
      }
    } else if (_currentMode == InteractionMode.hovering) {
      _setMode(InteractionMode.idle);
    }

    notifyListeners();
  }

  /// Sets the currently hovered marker within a series.
  ///
  /// This allows per-marker hover feedback without creating individual marker
  /// elements in the spatial index (performance optimization).
  ///
  /// Typically called after setHoveredElement() when the hovered element is
  /// a SeriesElement, to provide finer-grained hover feedback.
  ///
  /// Uses identity comparison (seriesId + markerIndex) to avoid spurious
  /// notifications when only plotPosition changes slightly between frames.
  void setHoveredMarker(HoveredMarkerInfo? marker) {
    // Use identity comparison to avoid excessive notifications from plotPosition drift
    if (_hoveredMarker != null && marker != null) {
      if (_hoveredMarker!.sameMarkerAs(marker)) {
        // Same marker identity - update position silently without notifying
        _hoveredMarker = marker;
        return;
      }
    } else if (_hoveredMarker == null && marker == null) {
      return; // Both null, no change
    }
    // Different marker or one is null - this is a real change
    _hoveredMarker = marker;
    notifyListeners();
  }

  // ============================================================================
  // Keyboard Modifier Tracking
  // ============================================================================

  /// Updates keyboard modifier key state.
  ///
  /// Call this from RawKeyEvent handlers to track Ctrl/Shift/Alt state.
  void updateModifierKeys(Set<LogicalKeyboardKey> keys) {
    _modifierKeys
      ..clear()
      ..addAll(keys);
    notifyListeners();
  }

  /// Adds a modifier key to the pressed set.
  void addModifierKey(LogicalKeyboardKey key) {
    if (_modifierKeys.add(key)) {
      notifyListeners();
    }
  }

  /// Removes a modifier key from the pressed set.
  void removeModifierKey(LogicalKeyboardKey key) {
    if (_modifierKeys.remove(key)) {
      notifyListeners();
    }
  }

  // ============================================================================
  // Interaction Start/Update/End
  // ============================================================================

  /// Starts an interaction at the given position.
  ///
  /// [position] is the starting position in chart coordinates.
  /// [element] is the element the interaction started on (if any).
  void startInteraction(Offset position, {ChartElement? element}) {
    _interactionStartPosition = position;
    _interactionStartElement = element;
  }

  /// Updates box selection rectangle.
  ///
  /// [start] is the starting position (from startInteraction).
  /// [current] is the current pointer position.
  void updateBoxSelection(Offset start, Offset current) {
    _boxSelectionRect = Rect.fromPoints(start, current);
    notifyListeners();
  }

  /// Updates preview selection set with elements currently in the box.
  ///
  /// This provides live visual feedback during box drag without committing
  /// to actual selection until pointer up.
  ///
  /// [elements] are the elements currently intersecting the box selection rect.
  void updatePreviewSelection(Set<ChartElement> elements) {
    _previewSelection.clear();
    _previewSelection.addAll(elements);
    notifyListeners();
  }

  /// Clears preview selection.
  ///
  /// Called when box selection is committed or cancelled.
  void clearPreviewSelection() {
    _previewSelection.clear();
    notifyListeners();
  }

  /// Ends the current interaction.
  void endInteraction() {
    _interactionStartPosition = null;
    _interactionStartElement = null;
    _boxSelectionRect = null;
    clearPreviewSelection(); // Clear preview when interaction ends
  }

  // ============================================================================
  // Conflict Resolution Helpers
  // ============================================================================

  /// Returns true if the given interaction mode is allowed in the current state.
  ///
  /// Used by custom recognizers to check if they should accept/reject gestures.
  bool canStartInteraction(InteractionMode mode) {
    // Modal states block everything except themselves
    if (_currentMode.isModal && mode != _currentMode) {
      return false;
    }

    // Higher priority modes block lower priority
    return mode.priority >= _currentMode.priority;
  }

  /// Determines if a pointer down on the given element should start a drag.
  ///
  /// Per conflict resolution scenario 5:
  /// - If started on datapoint (within radius) -> datapoint drag
  /// - If started on annotation -> annotation drag
  /// - If started on empty space -> box select (after threshold distance)
  bool shouldStartDrag(ChartElement? element, Offset currentPosition) {
    if (element == null || _interactionStartPosition == null) {
      return false;
    }

    // Calculate drag distance
    final distance = (currentPosition - _interactionStartPosition!).distance;

    // Per scenario 5: datapoint radius = 10px, box-select threshold = 5px
    if (element.isDraggable) {
      // Element is draggable - allow drag immediately
      return distance > 0;
    }

    return false;
  }

  /// Determines if a drag should be interpreted as box selection.
  ///
  /// Per conflict resolution scenario 5:
  /// - Started on empty space (no element)
  /// - Drag distance > 5px
  bool shouldStartBoxSelect(Offset currentPosition) {
    if (_interactionStartPosition == null || _interactionStartElement != null) {
      return false;
    }

    final distance = (currentPosition - _interactionStartPosition!).distance;
    return distance > 5.0; // 5px threshold per scenario 5
  }

  // ============================================================================
  // Debug & State Inspection
  // ============================================================================

  /// Returns a debug string representation of current state.
  String debugState() {
    return '''
ChartInteractionCoordinator State:
  Mode: ${_currentMode.description} (priority: ${_currentMode.priority})
  Active Element: ${_activeElement?.id ?? 'none'}
  Selected: ${_selectedElements.length} elements
  Hovered: ${_hoveredElement?.id ?? 'none'}
  Modifiers: Ctrl:$isCtrlPressed Shift:$isShiftPressed Alt:$isAltPressed
  Interaction Start: $_interactionStartPosition
  Box Selection: $_boxSelectionRect
''';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _selectedElements.clear();
    _modifierKeys.clear();
    super.dispose();
  }
}
