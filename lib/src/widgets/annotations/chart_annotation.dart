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
  ChartAnnotation({
    String? id,
    this.label,
    this.style = const AnnotationStyle(),
    this.allowDragging = false,
    this.allowEditing = false,
    this.zIndex = 0,
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
        other.zIndex == zIndex;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        style,
        allowDragging,
        allowEditing,
        zIndex,
      );
}
