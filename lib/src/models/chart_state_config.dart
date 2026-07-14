import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// Built-in visual treatments for a chart loading state.
enum ChartLoadingIndicator {
  /// An animated chart-shaped placeholder that preserves the viewport context.
  skeleton,

  /// A centered circular progress indicator.
  circular,

  /// A centered horizontal progress indicator.
  linear,
}

/// Visual and motion styling for the animated chart loading placeholder.
///
/// Null colors inherit from the chart's [ChartTheme], then the surrounding
/// Material theme. The loader scales with its viewport up to [maxWidth].
@immutable
class ChartLoadingSkeletonStyle {
  /// Creates styling for the built-in animated chart placeholder.
  const ChartLoadingSkeletonStyle({
    this.seriesColor,
    this.secondarySeriesColor,
    this.gridColor,
    this.animationDuration = const Duration(milliseconds: 2400),
    this.maxWidth = 720,
    this.widthFactor = 0.78,
    this.aspectRatio = 2.4,
    this.motionIntensity = 1,
    this.showSecondaryTrace = true,
    this.showGrid = false,
    this.edgeFadeFraction = 0.12,
  }) : assert(maxWidth > 0),
       assert(widthFactor > 0 && widthFactor <= 1),
       assert(aspectRatio > 0),
       assert(motionIntensity >= 0 && motionIntensity <= 1),
       assert(edgeFadeFraction >= 0 && edgeFadeFraction <= 0.4);

  /// Primary trace color. Defaults to the first chart series color.
  final Color? seriesColor;

  /// Supporting trace color. Defaults to the second chart series color.
  final Color? secondarySeriesColor;

  /// Grid and axis color. Defaults to the chart theme's major grid color.
  final Color? gridColor;

  /// Time taken for one complete animation cycle.
  final Duration animationDuration;

  /// Maximum rendered width in logical pixels.
  final double maxWidth;

  /// Proportion of a wide viewport occupied by the placeholder.
  ///
  /// Compact viewports use all available width.
  final double widthFactor;

  /// Width-to-height ratio of the placeholder.
  final double aspectRatio;

  /// Strength of waveform movement from 0 (calm) to 1 (full motion).
  final double motionIntensity;

  /// Whether to render a faint supporting series behind the primary trace.
  final bool showSecondaryTrace;

  /// Whether to render the chart grid and axes behind the animated traces.
  final bool showGrid;

  /// Portion of each horizontal edge used to fade the chart layer.
  ///
  /// Set to 0 to disable the fade. Values up to 0.4 are supported.
  final double edgeFadeFraction;
}

/// Configures the content shown while [BravenChartPlus.isLoading] is true.
@immutable
class ChartLoadingConfig {
  /// Creates an animated chart-shaped loading placeholder.
  const ChartLoadingConfig.skeleton({
    this.message = 'Loading chart data',
    this.semanticLabel = 'Loading chart data',
    this.showMessage = true,
    this.skeletonStyle = const ChartLoadingSkeletonStyle(),
    this.customBuilder,
  }) : indicator = ChartLoadingIndicator.skeleton,
       progress = null;

  /// Creates a circular loading indicator.
  const ChartLoadingConfig.circular({
    this.progress,
    this.message = 'Loading chart data',
    this.semanticLabel = 'Loading chart data',
    this.showMessage = true,
    this.customBuilder,
  }) : assert(progress == null || (progress >= 0 && progress <= 1)),
       indicator = ChartLoadingIndicator.circular,
       skeletonStyle = const ChartLoadingSkeletonStyle();

  /// Creates a horizontal loading indicator.
  const ChartLoadingConfig.linear({
    this.progress,
    this.message = 'Loading chart data',
    this.semanticLabel = 'Loading chart data',
    this.showMessage = true,
    this.customBuilder,
  }) : assert(progress == null || (progress >= 0 && progress <= 1)),
       indicator = ChartLoadingIndicator.linear,
       skeletonStyle = const ChartLoadingSkeletonStyle();

  /// Built-in indicator to render when [customBuilder] is null.
  final ChartLoadingIndicator indicator;

  /// Optional determinate progress from 0 to 1.
  ///
  /// Only circular and linear indicators use this value. A null value renders
  /// an indeterminate indicator.
  final double? progress;

  /// Short status text displayed beneath the indicator.
  final String message;

  /// Assistive-technology label announced for the loading region.
  final String semanticLabel;

  /// Whether [message] is displayed visually.
  final bool showMessage;

  /// Styling for the built-in chart placeholder.
  ///
  /// Only used when [indicator] is [ChartLoadingIndicator.skeleton].
  final ChartLoadingSkeletonStyle skeletonStyle;

  /// Optional complete replacement for the built-in loading presentation.
  final WidgetBuilder? customBuilder;
}

/// Configures the state shown when loading has finished without chart data.
@immutable
class ChartEmptyStateConfig {
  /// Creates an empty-state presentation.
  const ChartEmptyStateConfig({
    this.title = 'No data to display',
    this.message = 'Data will appear here when it becomes available.',
    this.icon = Icons.insert_chart_outlined,
    this.showIcon = true,
    this.semanticLabel,
    this.customBuilder,
  });

  /// Concise explanation of the empty state.
  final String title;

  /// Optional guidance about what happens next.
  final String? message;

  /// Supporting icon. Meaning is also communicated by [title].
  final IconData icon;

  /// Whether [icon] is displayed.
  final bool showIcon;

  /// Optional assistive-technology label. Defaults to title and message.
  final String? semanticLabel;

  /// Optional complete replacement for the built-in empty presentation.
  final WidgetBuilder? customBuilder;
}
