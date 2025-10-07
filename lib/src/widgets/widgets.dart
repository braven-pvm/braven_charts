/// Layer 5: Chart Widgets
///
/// User-facing widget API for Braven Charts.
/// Single entry point: BravenChart widget.
library;

export 'annotations/annotation_style.dart';
// Annotations
export 'annotations/chart_annotation.dart';
export 'annotations/point_annotation.dart';
export 'annotations/range_annotation.dart';
export 'annotations/text_annotation.dart';
export 'annotations/threshold_annotation.dart';
export 'annotations/trend_annotation.dart';
// Axis
export 'axis/axis_config.dart';
// Main widget
export 'braven_chart.dart';
// Controller
export 'controller/chart_controller.dart';
export 'enums/annotation_anchor.dart';
export 'enums/annotation_axis.dart';
export 'enums/axis_position.dart';
export 'enums/axis_range.dart';
// Enums
export 'enums/chart_type.dart';
export 'enums/marker_shape.dart';
export 'enums/trend_type.dart';
