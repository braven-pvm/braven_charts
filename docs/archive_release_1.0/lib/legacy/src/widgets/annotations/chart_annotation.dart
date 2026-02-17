import 'annotation_style.dart';

/// Counter for auto-generating annotation IDs.
int _annotationIdCounter = 0;

/// Base class for all chart annotations.
///
/// This abstract class defines the common interface for all annotation types
/// in the Braven Charts library. All concrete annotation implementations
/// (TextAnnotation, PointAnnotation, etc.) must extend this base class.
///
/// See Also:
/// - [TextAnnotation] for text labels
/// - [PointAnnotation] for point markers
/// - [RangeAnnotation] for horizontal/vertical ranges
/// - [ThresholdAnnotation] for threshold lines
/// - [TrendAnnotation] for trend lines
abstract class ChartAnnotation {
  /// Creates a chart annotation.
  ///
  /// If [id] is not provided, a unique ID will be auto-generated.
  /// The [label] is optional and can be used to identify the annotation in the UI.
  /// The [style] controls the visual appearance of the annotation.
  /// The [allowDragging] flag enables interactive repositioning.
  /// The [allowEditing] flag enables interactive editing.
  /// The [zIndex] determines the rendering order (higher values render on top).
  /// The [snapToValue] enables snapping to nearest data point values when dragging.
  /// The [snapIncrement] controls the snap granularity (e.g., 0.5, 1.0, 10.0).
  ChartAnnotation({
    String? id,
    this.label,
    this.style = const AnnotationStyle(),
    this.allowDragging = false,
    this.allowEditing = false,
    this.zIndex = 0,
    this.snapToValue = false,
    this.snapIncrement = 0.5,
  }) : id = id ?? 'annotation_${_annotationIdCounter++}';

  /// Unique identifier for this annotation.
  ///
  /// Used for managing, updating, and removing annotations from a chart.
  /// Must be unique within a single chart instance.
  /// If not provided in the constructor, an ID will be auto-generated.
  final String id;

  /// Optional label for this annotation.
  ///
  /// Can be displayed in the UI or used for accessibility purposes.
  final String? label;

  /// Visual style configuration for this annotation.
  ///
  /// Controls font size, colors, borders, and other visual properties.
  final AnnotationStyle style;

  /// Whether this annotation can be dragged by the user.
  ///
  /// When true, the annotation can be repositioned interactively.
  final bool allowDragging;

  /// Whether this annotation can be edited by the user.
  ///
  /// When true, the annotation's properties can be modified interactively.
  final bool allowEditing;

  /// Rendering order for this annotation.
  ///
  /// Annotations with higher zIndex values are rendered on top of
  /// annotations with lower values.
  final int zIndex;

  /// Whether to snap annotation values to nearest data point values when dragging.
  ///
  /// When true, dragging the annotation will snap its position to the nearest
  /// actual data point values on the chart axes. This is useful for range
  /// annotations that should align with specific data values rather than
  /// arbitrary positions.
  ///
  /// Example:
  /// ```dart
  /// RangeAnnotation(
  ///   startX: 2.0,
  ///   endX: 5.0,
  ///   allowDragging: true,
  ///   snapToValue: true,  // Snap to integer x-values when dragging
  /// )
  /// ```
  final bool snapToValue;

  /// The increment to snap to when [snapToValue] is enabled.
  ///
  /// Controls the granularity of snapping. For example:
  /// - 0.1: Snap to tenths (2.3, 2.4, 2.5)
  /// - 0.5: Snap to halves (2.0, 2.5, 3.0) - default
  /// - 1.0: Snap to integers (2, 3, 4)
  /// - 10.0: Snap to tens (10, 20, 30)
  ///
  /// Only used when [snapToValue] is true.
  ///
  /// Example:
  /// ```dart
  /// RangeAnnotation(
  ///   startX: 2.0,
  ///   endX: 5.0,
  ///   allowDragging: true,
  ///   snapToValue: true,
  ///   snapIncrement: 1.0,  // Snap to whole numbers
  /// )
  /// ```
  final double snapIncrement;

  /// Creates a copy of this annotation.
  ///
  /// Subclasses must implement this method to support annotation updates.
  ChartAnnotation copyWith();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.snapToValue == snapToValue &&
        other.snapIncrement == snapIncrement;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    style,
    allowDragging,
    allowEditing,
    zIndex,
    snapToValue,
    snapIncrement,
  );
}
