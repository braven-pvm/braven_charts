import 'package:flutter/material.dart';
import 'chart_annotation.dart';
import 'annotation_style.dart';
import '../enums/trend_type.dart';

/// A trend annotation that overlays statistical trend lines on chart data.
///
/// TrendAnnotation calculates and displays trend lines (linear regression,
/// polynomial fits, moving averages, etc.) for a specific data series.
///
/// Example:
/// ```dart
/// TrendAnnotation(
///   id: 'trend1',
///   seriesId: 'temperature',
///   trendType: TrendType.linear,
///   lineColor: Colors.red,
///   dashPattern: [5, 5],
/// )
/// ```
class TrendAnnotation extends ChartAnnotation {
  /// Creates a trend annotation.
  ///
  /// The [seriesId] identifies which series to calculate the trend for.
  /// The [trendType] determines the statistical method used.
  /// The [windowSize] is required for moving average trends.
  /// The [degree] is used for polynomial trends (default 2).
  /// The [lineColor] sets the trend line color.
  /// The [lineWidth] controls the line thickness.
  /// The [dashPattern] creates a dashed line if provided.
  ///
  /// Throws [AssertionError] if windowSize <= 0 when trendType is movingAverage.
  TrendAnnotation({
    super.id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.seriesId,
    required this.trendType,
    this.windowSize,
    this.degree = 2,
    this.lineColor = Colors.blue,
    this.lineWidth = 2.0,
    this.dashPattern,
  }) : assert(
          trendType != TrendType.movingAverage || (windowSize != null && windowSize > 0),
          'windowSize must be positive when trendType is movingAverage',
        );

  /// The ID of the series to calculate the trend for.
  final String seriesId;

  /// The type of trend calculation to perform.
  ///
  /// See [TrendType] for available options.
  final TrendType trendType;

  /// Window size for moving average trends.
  ///
  /// Required and must be > 0 when [trendType] is [TrendType.movingAverage].
  /// Ignored for other trend types.
  final int? windowSize;

  /// Polynomial degree for polynomial regression.
  ///
  /// Used when [trendType] is [TrendType.polynomial].
  /// Defaults to 2 (quadratic). Ignored for other trend types.
  final int degree;

  /// The color of the trend line.
  final Color lineColor;

  /// The width of the trend line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the trend line.
  ///
  /// If null, the line is solid. If provided, alternates between
  /// dash length and gap length (e.g., [5, 3] for 5px dash, 3px gap).
  final List<double>? dashPattern;

  @override
  TrendAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? seriesId,
    TrendType? trendType,
    int? windowSize,
    int? degree,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
  }) {
    return TrendAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      seriesId: seriesId ?? this.seriesId,
      trendType: trendType ?? this.trendType,
      windowSize: windowSize ?? this.windowSize,
      degree: degree ?? this.degree,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.seriesId == seriesId &&
        other.trendType == trendType &&
        other.windowSize == windowSize &&
        other.degree == degree &&
        other.lineColor == lineColor &&
        other.lineWidth == lineWidth &&
        _listEquals(other.dashPattern, dashPattern);
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        style,
        allowDragging,
        allowEditing,
        zIndex,
        seriesId,
        trendType,
        windowSize,
        degree,
        lineColor,
        lineWidth,
        Object.hashAll(dashPattern ?? []),
      );

  /// Helper to compare nullable lists.
  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
