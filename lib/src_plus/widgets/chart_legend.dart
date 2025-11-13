// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Legend Widget - Show/Hide Series Control

import 'package:flutter/material.dart';

import '../models/chart_series.dart';

/// A legend widget for displaying chart series with show/hide functionality.
///
/// The legend displays all series with their colors and names, allowing users
/// to toggle series visibility. This is meant to be used alongside BravenChartPlus.
///
/// Example:
/// ```dart
/// class MyChartWithLegend extends StatefulWidget {
///   @override
///   State<MyChartWithLegend> createState() => _MyChartWithLegendState();
/// }
///
/// class _MyChartWithLegendState extends State<MyChartWithLegend> {
///   final List<ChartSeries> _allSeries = [...]; // All series
///   final Set<String> _hiddenSeriesIds = {}; // IDs of hidden series
///
///   List<ChartSeries> get _visibleSeries =>
///       _allSeries.where((s) => !_hiddenSeriesIds.contains(s.id)).toList();
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Expanded(
///           child: BravenChartPlus(
///             chartType: ChartType.line,
///             series: _visibleSeries,
///             theme: ChartTheme.light,
///           ),
///         ),
///         ChartLegend(
///           series: _allSeries,
///           hiddenSeriesIds: _hiddenSeriesIds,
///           onSeriesToggle: (seriesId) {
///             setState(() {
///               if (_hiddenSeriesIds.contains(seriesId)) {
///                 _hiddenSeriesIds.remove(seriesId);
///               } else {
///                 _hiddenSeriesIds.add(seriesId);
///               }
///             });
///           },
///         ),
///       ],
///     );
///   }
/// }
/// ```
class ChartLegend extends StatelessWidget {
  /// Creates a chart legend widget.
  ///
  /// [series] is the list of all chart series to display in the legend.
  /// [hiddenSeriesIds] is the set of series IDs that are currently hidden.
  /// [onSeriesToggle] is called when a user clicks on a legend item to show/hide a series.
  const ChartLegend({
    super.key,
    required this.series,
    required this.hiddenSeriesIds,
    required this.onSeriesToggle,
    this.orientation = Axis.horizontal,
    this.spacing = 16.0,
    this.runSpacing = 8.0,
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.showBorder = true,
    this.borderColor,
  });

  /// List of all series to display in the legend.
  final List<ChartSeries> series;

  /// Set of series IDs that are currently hidden.
  final Set<String> hiddenSeriesIds;

  /// Callback when a legend item is tapped to toggle series visibility.
  final ValueChanged<String> onSeriesToggle;

  /// Orientation of the legend items (horizontal or vertical).
  final Axis orientation;

  /// Spacing between legend items.
  final double spacing;

  /// Run spacing for wrapped items (when using horizontal orientation).
  final double runSpacing;

  /// Padding around the legend content.
  final EdgeInsets padding;

  /// Background color of the legend. Defaults to theme's card color.
  final Color? backgroundColor;

  /// Border radius of the legend container.
  final BorderRadius borderRadius;

  /// Whether to show a border around the legend.
  final bool showBorder;

  /// Color of the legend border. Defaults to theme's divider color.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.cardColor;
    final effectiveBorderColor = borderColor ?? theme.dividerColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: effectiveBorderColor) : null,
      ),
      child: orientation == Axis.horizontal
          ? Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: series.map(_buildLegendItem).toList(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: series
                  .map((s) => Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _buildLegendItem(s),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildLegendItem(ChartSeries series) {
    final isHidden = hiddenSeriesIds.contains(series.id);
    final seriesColor = _getSeriesColor(series);

    return InkWell(
      onTap: () => onSeriesToggle(series.id),
      borderRadius: BorderRadius.circular(4.0),
      child: Opacity(
        opacity: isHidden ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color indicator
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isHidden ? Colors.grey : seriesColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHidden ? Colors.grey : seriesColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Series name
              Text(
                _getSeriesName(series),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                  color: isHidden ? Colors.grey : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get the color for a series based on its type.
  Color _getSeriesColor(ChartSeries series) {
    // Use provided color or generate from series hash
    if (series.color != null) {
      return series.color!;
    }
    final colorIndex = series.hashCode.abs() % _defaultColors.length;
    return _defaultColors[colorIndex];
  }

  /// Get the display name for a series.
  String _getSeriesName(ChartSeries series) {
    // ChartSeries has a displayName getter that returns name ?? id
    return series.displayName;
  }

  /// Default color palette for series.
  static const List<Color> _defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFF795548), // Brown
  ];
}
