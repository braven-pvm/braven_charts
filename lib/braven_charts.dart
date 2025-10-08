/// Braven Charts - A comprehensive Flutter charting library
///
/// This library provides advanced charting capabilities with support for:
/// - Multiple chart types (line, bar, pie, scatter, etc.)
/// - Interactive annotations and markers
/// - Custom theming and styling
/// - Performance optimized rendering
/// - Universal coordinate transformation
library;

// Coordinate System Layer - Universal transformation system
export 'src/coordinates/coordinate_system.dart';
export 'src/coordinates/transform_context.dart';
export 'src/coordinates/universal_coordinate_transformer.dart';
export 'src/coordinates/viewport_state.dart';
// Foundation Layer - Core data structures and utilities
export 'src/foundation/foundation.dart';
// Interaction Layer - User interaction system (Layer 7)
export 'src/interaction/interaction_callbacks.dart';
export 'src/interaction/models/crosshair_config.dart';
export 'src/interaction/models/gesture_details.dart';
export 'src/interaction/models/interaction_config.dart';
export 'src/interaction/models/interaction_state.dart';
export 'src/interaction/models/tooltip_config.dart';
export 'src/interaction/models/zoom_pan_state.dart';
// Theming Layer - Chart themes and styling
export 'src/theming/chart_theme.dart';
// Widgets Layer - User-facing chart widgets (Layer 5)
export 'src/widgets/widgets.dart';

// TODO: Uncomment as layers are implemented
// Annotation system exports
// export 'src/annotations/annotation_system.dart';
// export 'src/annotations/marker_system.dart';
// export 'src/charts/bar_chart.dart';
// Core exports
// export 'src/charts/chart_base.dart';
// export 'src/charts/line_chart.dart';
// export 'src/charts/pie_chart.dart';
// Theming exports
// export 'src/theming/chart_theme.dart';
// export 'src/theming/theme_data.dart';
// Utilities exports
// export 'src/utils/coordinate_transformer.dart';
// export 'src/utils/performance_utils.dart';
