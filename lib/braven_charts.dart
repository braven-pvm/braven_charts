// Copyright (c) 2025 braven_charts. All rights reserved.
// Public API for braven_charts package

library;

// Axis - Auto-detection
export 'src/axis/normalization_detector.dart';
export 'src/axis/range_ratio_calculator.dart';
export 'src/axis/series_axis_resolver.dart';
// Core chart widget
export 'src/braven_chart_plus.dart';
// Controllers
export 'src/controllers/annotation_controller.dart';
export 'src/controllers/chart_controller.dart';
// Formatting
export 'src/formatting/multi_axis_value_formatter.dart';
// Layout
export 'src/layout/axis_layout_manager.dart';
export 'src/layout/multi_axis_layout.dart';
// Models
export 'src/models/annotation_style.dart';
export 'src/models/auto_scroll_config.dart';
export 'src/models/axis_config.dart';
export 'src/models/chart_annotation.dart';
export 'src/models/chart_data_point.dart';
export 'src/models/chart_series.dart';
export 'src/models/chart_theme.dart';
export 'src/models/chart_type.dart';
export 'src/models/data_range.dart';
export 'src/models/enums.dart';
export 'src/models/interaction_callbacks.dart';
export 'src/models/interaction_config.dart';
export 'src/models/multi_axis_config.dart';
export 'src/models/normalization_mode.dart';
export 'src/models/segment_style.dart';
// Note: SeriesAxisBinding is internal-only. Use ChartSeries.yAxisConfig or yAxisId instead.
export 'src/models/streaming_config.dart';
export 'src/models/y_axis_config.dart';
export 'src/models/y_axis_position.dart';
// Rendering
export 'src/rendering/axis_color_resolver.dart';
export 'src/rendering/multi_axis_normalizer.dart';
export 'src/rendering/multi_axis_painter.dart';
// Streaming
export 'src/streaming/live_stream_controller.dart';
export 'src/streaming/streaming_buffer.dart';
export 'src/streaming/streaming_controller.dart';
// Theming
export 'src/theming/components/scrollbar_config.dart';
