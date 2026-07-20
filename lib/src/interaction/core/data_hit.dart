import 'dart:ui';

import '../../models/chart_data_point.dart';
import '../../models/candlestick_interaction_details.dart';

/// Immutable identity and display payload for one interactable chart datum.
///
/// Cartesian markers and radial slices share this boundary so hover, tooltip,
/// activation, and assistive semantics do not depend on a renderer shape.
class ChartDataHit {
  /// Creates a resolved data hit in plot-local coordinates.
  const ChartDataHit({
    required this.seriesId,
    required this.pointIndex,
    this.sourcePointIndices = const <int>[],
    required this.plotPosition,
    required this.semanticBounds,
    required this.point,
    required this.formattedValue,
    this.formattedXValue,
    required this.ordinal,
    required this.count,
    this.category,
    this.total,
    this.share,
    this.formattedShare,
    this.radiusValue,
    this.formattedRadiusValue,
    this.radiusLabel,
    this.groupLabel,
    this.groupName,
    this.groupOrdinal,
    this.groupCount,
    this.categoryValue,
    this.categoryLabel,
    this.colorValue,
    this.formattedColorValue,
    this.colorLabel,
    this.markerColor,
    this.opacityValue,
    this.formattedOpacityValue,
    this.opacityLabel,
    this.markerOpacity,
    this.candlestick,
    this.aggregateValue,
    this.formattedAggregateValue,
    this.aggregateLabel,
    this.aggregateSampleCount,
    this.isSelected = false,
    this.isFocused = false,
  });

  /// Stable source-series ID.
  final String seriesId;

  /// Stable source point index within the series.
  final int pointIndex;

  /// Original point indices represented by this hit.
  ///
  /// Cartesian data and ungrouped radial slices leave this empty and use
  /// [pointIndex]. Grouped radial slices carry every source point here.
  final List<int> sourcePointIndices;

  /// Complete source identity represented by this hit.
  List<int> get effectiveSourcePointIndices => sourcePointIndices.isEmpty
      ? <int>[pointIndex]
      : List<int>.unmodifiable(sourcePointIndices);

  /// Preferred tooltip anchor in plot-local coordinates.
  final Offset plotPosition;

  /// Assistive hit region in plot-local coordinates.
  final Rect semanticBounds;

  /// Original transported point passed to public callbacks.
  final ChartDataPoint point;

  /// Optional category label for categorical renderers.
  final String? category;

  /// Raw total used to calculate a categorical share.
  final double? total;

  /// Fractional contribution in the inclusive range 0–1.
  final double? share;

  /// Optional visual formatting for [share], including its percent suffix.
  final String? formattedShare;

  /// Optional raw second metric controlling radial extent.
  final double? radiusValue;

  /// Optional formatted radius metric including its unit.
  final String? formattedRadiusValue;

  /// Optional human-readable name of the radius metric.
  final String? radiusLabel;

  /// Optional position label for a datum inside a composed data group.
  ///
  /// Concentric Donut uses this for values such as `Outer ring` and keeps it
  /// null for standalone Pie and Donut charts so their existing presentation
  /// remains unchanged.
  final String? groupLabel;

  /// Optional user-facing name of the composed data group.
  final String? groupName;

  /// One-based traversal position of the composed data group.
  final int? groupOrdinal;

  /// Number of groups participating in the composition.
  final int? groupCount;

  /// Optional categorical Scatter value encoded through marker color/shape.
  final String? categoryValue;

  /// Human-readable field name for [categoryValue].
  final String? categoryLabel;

  /// Optional quantitative Scatter value represented through marker color.
  final double? colorValue;

  /// Display-ready [colorValue], including its unit.
  final String? formattedColorValue;

  /// Human-readable name for [colorValue].
  final String? colorLabel;

  /// Effective marker color after point and quantitative encoding overrides.
  final Color? markerColor;

  /// Optional quantitative Scatter value represented through marker opacity.
  final double? opacityValue;

  /// Display-ready [opacityValue], including its unit.
  final String? formattedOpacityValue;

  /// Human-readable name for [opacityValue].
  final String? opacityLabel;

  /// Effective marker opacity after point and quantitative overrides.
  final double? markerOpacity;

  /// Typed OHLC values for a native Candlestick datum.
  final CandlestickInteractionDetails? candlestick;

  /// Optional statistic represented by an aggregate Cartesian mark.
  final double? aggregateValue;

  /// Display-ready [aggregateValue], including any unit or percent suffix.
  final String? formattedAggregateValue;

  /// Human-readable name of the aggregate statistic.
  final String? aggregateLabel;

  /// Number of source observations that contributed to [aggregateValue].
  ///
  /// This can be smaller than [effectiveSourcePointIndices] when an optional
  /// Scatter metric is absent from some observations in an aggregate bin.
  final int? aggregateSampleCount;

  /// Preformatted value including an applicable unit.
  final String formattedValue;

  /// Optional preformatted X value for genuinely two-dimensional marks.
  final String? formattedXValue;

  /// One-based visible position of this datum.
  final int ordinal;

  /// Number of visible data items in this element.
  final int count;

  /// Whether this datum has durable selection state.
  final bool isSelected;

  /// Whether this datum has transient keyboard or linked focus.
  final bool isFocused;

  /// Complete non-color-only announcement for assistive technologies.
  String get semanticLabel {
    final name = category ?? point.label ?? 'Data point';
    final parts = <String>[?groupLabel, ?groupName, name];
    if (candlestick case final details?) {
      parts.add(details.semanticLabel);
    } else {
      if (formattedXValue != null) parts.add('X $formattedXValue');
      parts.add(formattedValue);
    }
    if (share != null) {
      final display = formattedShare ?? '${(share! * 100).toStringAsFixed(1)}%';
      parts.add(
        display.endsWith('%')
            ? '${display.substring(0, display.length - 1)} percent'
            : display,
      );
    }
    if (formattedRadiusValue != null) {
      parts.add('${radiusLabel ?? 'Radius'} $formattedRadiusValue');
    }
    if (formattedColorValue != null) {
      parts.add('${colorLabel ?? 'Color value'} $formattedColorValue');
    }
    if (formattedOpacityValue != null) {
      parts.add('${opacityLabel ?? 'Opacity value'} $formattedOpacityValue');
    }
    if (categoryValue != null) {
      parts.add('${categoryLabel ?? 'Category'} $categoryValue');
    }
    if (formattedAggregateValue != null) {
      parts.add('${aggregateLabel ?? 'Aggregate'} $formattedAggregateValue');
    }
    if (aggregateSampleCount case final sampleCount?
        when sampleCount < effectiveSourcePointIndices.length) {
      parts.add(
        '$sampleCount of ${effectiveSourcePointIndices.length} observations '
        'contributed to the aggregate',
      );
    }
    if (candlestick == null && effectiveSourcePointIndices.length > 1) {
      parts.add(
        share == null
            ? '${effectiveSourcePointIndices.length} source points'
            : '${effectiveSourcePointIndices.length} grouped categories',
      );
    }
    parts.add('${share == null ? 'point' : 'slice'} $ordinal of $count');
    parts.add(isSelected ? 'selected' : 'not selected');
    return parts.join(', ');
  }

  /// Stable sort position for assistive traversal across composed groups.
  double get semanticSortOrdinal =>
      ((groupOrdinal ?? 1) - 1) * 1000000 + ordinal.toDouble();
}
