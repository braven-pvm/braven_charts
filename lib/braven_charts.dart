// Copyright (c) 2025 braven_charts. All rights reserved.
/// Public API for the BravenChartPlus package.
///
/// Import this library to access the `BravenChartPlus` widget and core models.
///
/// Import `package:braven_charts/braven_charts.dart`, then create the widget:
///
/// ```dart
/// final series = ChartSeries(
///   id: 'revenue',
///   points: const [
///     ChartDataPoint(x: 1, y: 10),
///     ChartDataPoint(x: 2, y: 15),
///   ],
/// );
///
/// BravenChartPlus(
///   series: [series],
///   xAxisConfig: const XAxisConfig(label: 'Month'),
///   yAxis: const YAxisConfig(label: 'USD'),
/// );
/// ```
///
/// {@category Get started}
/// {@category Chart families}
/// {@category Interaction and display}
/// {@category Workbench and artifacts}

library;

// AI Integration
export 'src/ai/chart_agent_interface.dart';
export 'src/ai/chart_config_builder.dart';
export 'src/ai/chart_tool_schema.dart';
// Axis - Auto-detection
export 'src/axis/normalization_detector.dart';
export 'src/axis/range_ratio_calculator.dart';
export 'src/axis/series_axis_resolver.dart';
// Portable chart artifacts
export 'src/artifacts/chart_artifact_diagnostics.dart';
export 'src/artifacts/chart_artifact_canonicalizer.dart';
export 'src/artifacts/chart_artifact_deduplicator.dart';
export 'src/artifacts/chart_artifact_json_codec.dart';
export 'src/artifacts/chart_artifact_migrations.dart';
export 'src/artifacts/chart_artifact.dart';
export 'src/artifacts/chart_artifact_extractor.dart'
    show ChartArtifactExtractOptions;
export 'src/artifacts/chart_annotation_document.dart';
export 'src/artifacts/chart_annotation_document_codec.dart';
export 'src/artifacts/chart_axis_document_codec.dart';
export 'src/artifacts/chart_data_payload.dart';
export 'src/artifacts/chart_data_resolver.dart';
export 'src/artifacts/chart_data_storage.dart';
export 'src/artifacts/chart_configuration_document_codec.dart';
export 'src/artifacts/chart_configuration_documents.dart';
export 'src/artifacts/chart_document.dart';
export 'src/artifacts/chart_document_hydrator.dart';
export 'src/artifacts/chart_document_extractor.dart'
    show
        ChartDataScope,
        ChartSelectionProjectionOptions,
        ChartSelectionAnnotationProjection,
        ChartSelectionIntervalBoundaryProjection,
        ChartSelectionSeriesProjection,
        ChartDocumentExtractOptions,
        ChartDocumentExtractionHandler,
        ChartDocumentRevision,
        ChartDocumentSnapshot;
export 'src/artifacts/chart_interaction_document_codec.dart';
export 'src/artifacts/chart_runtime_bindings.dart';
export 'src/artifacts/heatmap_viewport_provider_binding.dart';
export 'src/artifacts/heatmap_raster_viewport_provider_binding.dart';
export 'src/artifacts/radial_formatter_document_descriptors.dart';
export 'src/artifacts/chart_preview.dart';
export 'src/artifacts/chart_preview_capture.dart';
export 'src/artifacts/chart_series_document_codec.dart';
export 'src/artifacts/chart_theme_document_codec.dart';
export 'src/artifacts/chart_view_state.dart';
export 'src/table/chart_table_model.dart';
export 'src/table/chart_table_options.dart';
export 'src/table/chart_table_controller.dart';
export 'src/table/chart_table_export.dart';
export 'src/table/chart_data_table.dart';
export 'src/table/chart_data_table_theme.dart';
export 'src/workbench/braven_chart_workbench.dart';
export 'src/workbench/chart_workbench_group.dart';
export 'src/workbench/chart_workbench_models.dart';
export 'src/artifacts/json_value.dart';
// Core chart widget
export 'src/braven_chart_plus.dart';
// Controllers
export 'src/controllers/annotation_controller.dart';
export 'src/controllers/chart_controller.dart';
export 'src/controllers/chart_interaction_group_controller.dart'
    hide ChartInteractionGroupParticipant;
export 'src/controllers/heatmap_viewport_controller.dart';
export 'src/controllers/heatmap_raster_viewport_controller.dart';
// Coordinates
export 'src/coordinates/chart_transform.dart';
// Comparison
export 'src/comparison/chart_comparison_builder.dart';
export 'src/comparison/chart_comparison_export.dart';
export 'src/comparison/chart_comparison_model.dart';
// Formatting
export 'src/formatting/multi_axis_value_formatter.dart';
// Grammar
// Beta — work in progress; the grammar-of-graphics authoring API (BravenChart,
// PlotSpec, marks and channels) is experimental and may change before a stable
// release. Pin a version if you depend on it.
export 'src/grammar/braven_facet_plot.dart';
export 'src/grammar/braven_plot.dart';
export 'src/grammar/channel.dart';
export 'src/grammar/chart_builder.dart';
export 'src/grammar/facet_spec.dart';
export 'src/grammar/grammar_diagnostics.dart';
export 'src/grammar/mark.dart';
export 'src/grammar/plot_lowering.dart';
export 'src/grammar/plot_spec.dart';
// Interaction
export 'src/interaction/core/cartesian_tracking_snapshot.dart';
// Layout
export 'src/layout/axis_layout_manager.dart';
export 'src/layout/multi_axis_layout.dart';
// Cartesian navigator
export 'src/navigator/cartesian_navigator.dart';
export 'src/navigator/cartesian_navigator_models.dart';
// Models
export 'src/models/annotation_style.dart';
export 'src/models/auto_scroll_config.dart';
export 'src/models/axis_scale_type.dart';
export 'src/models/bar_chart_style.dart';
export 'src/models/bar_group_info.dart';
export 'src/models/category_axis_config.dart';
export 'src/models/candlestick_chart_series.dart';
export 'src/models/candlestick_chart_style.dart';
export 'src/models/candlestick_data_point.dart';
export 'src/models/candlestick_density_grouping.dart';
export 'src/models/candlestick_interaction_details.dart';
export 'src/models/cartesian_value_summary_config.dart';
export 'src/models/cartesian_value_summary_style.dart';
export 'src/models/financial_time_domain.dart';
// X-axis configuration uses XAxisConfig; Y-axis uses YAxisConfig.
export 'src/models/chart_annotation.dart';
export 'src/models/chart_context_action.dart';
export 'src/models/chart_overlay_placement.dart';
export 'src/models/chart_style_value.dart';
export 'src/models/chart_data_point.dart';
export 'src/models/data_point_label_config.dart';
export 'src/models/series_inline_label_config.dart';
export 'src/models/chart_series.dart';
export 'src/models/chart_state_config.dart';
export 'src/models/chart_selection_result.dart';
export 'src/models/chart_selection_expression.dart';
export 'src/models/chart_point_identity.dart';
export 'src/models/chart_theme.dart';
export 'src/models/chart_type.dart';
export 'src/models/concentric_donut_config.dart';
export 'src/models/data_range.dart';
export 'src/models/donut_chart_config.dart';
export 'src/models/donut_center_builder.dart';
export 'src/models/donut_chart_series.dart';
export 'src/models/gauge_chart_config.dart';
export 'src/models/gauge_chart_series.dart';
export 'src/models/gauge_center_builder.dart';
export 'src/models/enums.dart';
export 'src/models/grid_config.dart';
export 'src/models/heatmap_color_scale.dart';
export 'src/models/heatmap_chart_series.dart';
export 'src/models/heatmap_shared_color_domain.dart';
export 'src/models/heatmap_cluster_data.dart';
export 'src/models/heatmap_contour_data.dart';
export 'src/models/heatmap_data_point.dart';
export 'src/models/heatmap_dendrogram_data.dart';
export 'src/models/heatmap_hierarchy_projection.dart';
export 'src/models/heatmap_density_data.dart';
export 'src/models/heatmap_histogram_data.dart';
export 'src/models/heatmap_viewport_source.dart';
export 'src/models/heatmap_raster_viewport_source.dart';
export 'src/models/histogram_chart_data.dart';
export 'src/models/interaction_callbacks.dart';
export 'src/models/interaction_config.dart';
export 'src/models/legend_style.dart';
export 'src/models/multi_axis_config.dart';
export 'src/models/normalization_mode.dart';
export 'src/models/path_animation_style.dart';
export 'src/models/range_area_chart_series.dart';
export 'src/models/range_area_data_point.dart';
export 'src/models/range_area_interaction_details.dart';
export 'src/models/range_area_style.dart';
export 'src/models/radial_selection_style.dart';
export 'src/models/pareto_chart_data.dart';
export 'src/models/pie_chart_config.dart';
export 'src/models/pie_chart_series.dart';
export 'src/models/polar_chart_config.dart';
export 'src/models/polar_column_chart_series.dart';
export 'src/models/radial_bar_chart_config.dart';
export 'src/models/radial_bar_chart_series.dart';
export 'src/models/radial_category_series.dart';
export 'src/models/radial_legend_item.dart';
export 'src/models/segment_style.dart';
export 'src/models/scatter_marker_style.dart';
export 'src/models/scatter_marginal_data.dart';
export 'src/models/scatter_render_config.dart';
// Note: SeriesAxisBinding is internal-only. Use ChartSeries.yAxisConfig or yAxisId instead.
export 'src/models/streaming_config.dart';
export 'src/models/x_axis_config.dart';
export 'src/models/x_axis_position.dart';
export 'src/models/axis_swap_mode.dart';
export 'src/models/braven_chart_controller.dart';
export 'src/models/y_axis_config.dart';
export 'src/models/y_axis_position.dart';
// Rendering
export 'src/rendering/axis_color_resolver.dart';
export 'src/rendering/candlestick_geometry.dart';
export 'src/rendering/multi_axis_normalizer.dart';
export 'src/rendering/multi_axis_painter.dart';
// Generated Dart source
export 'src/source/chart_dart_source_generator.dart';
export 'src/source/chart_grammar_source_generator.dart';
export 'src/source/chart_source_models.dart';
export 'src/source/chart_source_view.dart';
// The themed Dart renderer the Source tab is built from — reusable anywhere a
// surface shows Dart (lives in src/widgets, exported here next to its caller).
export 'src/widgets/chart_code_block.dart';
// Statistics
export 'src/statistics/trend_statistics.dart';
export 'src/statistics/linear_regression_intervals.dart';
// Streaming
export 'src/streaming/live_stream_controller.dart';
export 'src/streaming/streaming_buffer.dart';
export 'src/streaming/streaming_controller.dart';
// Widgets
export 'src/widgets/dialogs/annotation_color_palette.dart'
    show ChartColorPalette;
export 'src/widgets/chart_legend.dart';
export 'src/widgets/heatmap_color_legend.dart';
export 'src/widgets/heatmap_dendrogram.dart';
export 'src/widgets/heatmap_dendrogram_interaction.dart';
export 'src/widgets/scatter_marginal_composition.dart';
// Theming
export 'src/theming/components/animation_theme.dart';
export 'src/theming/components/candlestick_theme.dart';
export 'src/theming/components/cartesian_value_summary_theme.dart';
export 'src/theming/components/annotation_theme.dart';
export 'src/theming/components/axis_style.dart';
export 'src/theming/components/grid_style.dart';
export 'src/theming/components/interaction_theme.dart';
export 'src/theming/components/range_area_theme.dart';
export 'src/theming/components/scrollbar_config.dart';
export 'src/theming/components/series_theme.dart'
    show SeriesMarkerShape, SeriesTheme;
export 'src/theming/components/typography_theme.dart';
export 'src/theming/styles/label_style.dart';
