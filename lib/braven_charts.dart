/// Public Braven Charts API (re-exports the current `src/` implementation)
///
/// This file provides the public package API for example apps and consumers.
library;

// Axis Layer
export 'src/axis/data_normalizer.dart';
export 'src/axis/multi_axis_config.dart';
export 'src/axis/normalization_detector.dart';
export 'src/axis/normalization_mode.dart';
export 'src/axis/series_axis_binding.dart';
export 'src/axis/y_axis_config.dart';
export 'src/axis/y_axis_position.dart';
// BravenChartPlus (new API)
export 'src/braven_chart_plus.dart';
// Chart Configuration
export 'src/charts/line/line_chart_config.dart' show LineStyle;
// Coordinate System
export 'src/coordinates/coordinate_system.dart';
export 'src/coordinates/transform_context.dart';
export 'src/coordinates/universal_coordinate_transformer.dart';
export 'src/coordinates/viewport_state.dart';
// Foundation
export 'src/foundation/foundation.dart';
// Interaction
export 'src/interaction/interaction_callbacks.dart';
export 'src/interaction/models/crosshair_config.dart';
export 'src/interaction/models/gesture_details.dart';
export 'src/interaction/models/interaction_config.dart';
export 'src/interaction/models/interaction_state.dart';
export 'src/interaction/models/tooltip_config.dart';
export 'src/interaction/models/zoom_pan_state.dart';
export 'src/models/annotation_style.dart';
export 'src/models/axis_config.dart';
export 'src/models/chart_annotation.dart';
// Models (public)
export 'src/models/chart_data_point.dart';
// Models
export 'src/models/chart_mode.dart';
export 'src/models/chart_series.dart';
// Theming
export 'src/models/chart_theme.dart';
export 'src/models/streaming_config.dart';
// Painters
export 'src/painters/multi_axis_painter.dart';
// Scrollbar
export 'src/widgets/chart_scrollbar.dart';
// Controllers
export 'src/widgets/controller/streaming_controller.dart';
export 'src/widgets/scrollbar/scrollbar_controller.dart';
export 'src/widgets/scrollbar/scrollbar_painter.dart';
// Widgets
export 'src/widgets/widgets.dart';

// Compatibility: re-export legacy public API for examples and older code
/// Temporary compatibility public API for examples.
///
/// During the migration `src_plus -> src` we temporarily expose the legacy
/// public API only so example apps compile unchanged. Once examples are
/// migrated to the new API, this file can be updated to re-export `src/*`.
export 'legacy/braven_charts.dart';
