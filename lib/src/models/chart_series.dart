// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'chart_annotation.dart';
import 'bar_chart_style.dart';
import 'chart_data_point.dart';
import 'data_point_label_config.dart';
import 'series_inline_label_config.dart';
import 'y_axis_config.dart';
import 'y_axis_position.dart';

/// Fill style for data point markers.
enum DataPointMarkerStyle {
  /// Solid filled circle (default).
  filled,

  /// Outline-only circle (stroke, no fill).
  hollow,
}

/// Interpolation methods for line and area charts.
enum LineInterpolation { linear, bezier, stepped, monotone }

/// Rendering style hints for series visualization.
enum SeriesStyle { line, bar, scatter, area, pie, donut }

/// Base class for chart series.
///
/// Now concrete to support generic usage like in BravenChart.
/// Supports optional Y-axis binding via [yAxisId] and value formatting
/// via [unit].
class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
    this.annotations = const [],
    this.yAxisId,
    this.yAxisConfig,
    this.unit,
  });

  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;
  final List<ChartAnnotation> annotations;

  /// Optional Y-axis ID for referencing a shared axis in multi-axis mode.
  ///
  /// Use this when multiple series should resolve to the same Y-axis. The ID
  /// should match a [YAxisConfig.id].
  ///
  /// For series with their own dedicated axis, prefer using [yAxisConfig]
  /// instead, which allows inline axis configuration.
  ///
  /// Example:
  /// ```dart
  /// // Reference a shared axis
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   yAxisId: 'shared-axis',  // References YAxisConfig with id='shared-axis'
  /// )
  /// ```
  final String? yAxisId;

  /// Inline Y-axis configuration for this series.
  ///
  /// When set, creates a dedicated Y-axis for this series with the
  /// specified configuration. The axis ID is auto-generated from the
  /// series ID if not explicitly set in the config.
  ///
  /// This is the preferred way to configure axes when each series has
  /// its own axis. For shared axes (multiple series on one axis), use
  /// [yAxisId] to bind those series to the same resolved axis.
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   yAxisConfig: YAxisConfig(
  ///     position: YAxisPosition.left,
  ///     label: 'Power',
  ///     unit: 'W',
  ///   ),
  /// )
  /// ```
  final YAxisConfig? yAxisConfig;

  /// Optional unit suffix for value formatting.
  ///
  /// Used by tooltips and axis labels to display values with units.
  /// Common examples: 'W' (watts), 'bpm' (beats per minute), 'L' (liters).
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   unit: 'W',  // Values displayed as "250 W"
  /// )
  /// ```
  final String? unit;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;

  /// Creates a copy of this series with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
  ChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
  }) {
    return ChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      style: style ?? this.style,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartSeries &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.points, points) &&
        other.color == color &&
        other.style == style &&
        other.isXOrdered == isXOrdered &&
        _mapEquals(other.metadata, metadata) &&
        _listEquals(other.annotations, annotations) &&
        other.yAxisId == yAxisId &&
        other.yAxisConfig == yAxisConfig &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAll(points),
    color,
    style,
    isXOrdered,
    metadata != null ? Object.hashAll(metadata!.entries) : null,
    Object.hashAll(annotations),
    yAxisId,
    yAxisConfig,
    unit,
  );

  /// Helper for list equality comparison.
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper for map equality comparison.
  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'ChartSeries(id: $id, points: ${points.length}, yAxisId: $yAxisId, unit: $unit)';

  /// Serializes this series to a JSON map.
  ///
  /// The [yAxisConfig] is serialized as a nested 'yAxisConfig' object for
  /// consistency with the agentic schema format (FR-001).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      'points': points.map((p) => {'x': p.x, 'y': p.y}).toList(),
      if (color != null) 'color': color!.toARGB32(),
      if (style != null) 'style': style!.name,
      'isXOrdered': isXOrdered,
      if (metadata != null) 'metadata': metadata,
      if (yAxisId != null) 'yAxisId': yAxisId,
      if (yAxisConfig != null)
        'yAxisConfig': {
          'position': yAxisConfig!.position.name,
          if (yAxisConfig!.label != null) 'label': yAxisConfig!.label,
          if (yAxisConfig!.unit != null) 'unit': yAxisConfig!.unit,
          if (yAxisConfig!.min != null) 'min': yAxisConfig!.min,
          if (yAxisConfig!.max != null) 'max': yAxisConfig!.max,
          if (yAxisConfig!.color != null)
            'color': yAxisConfig!.color!.toARGB32(),
        },
      if (unit != null) 'unit': unit,
    };
  }

  /// Creates a ChartSeries from a JSON map.
  ///
  /// The 'yAxisConfig' nested object is parsed into a [YAxisConfig] if present.
  static ChartSeries fromJson(Map<String, dynamic> json) {
    YAxisConfig? yAxisConfig;
    if (json['yAxisConfig'] != null &&
        json['yAxisConfig'] is Map<String, dynamic>) {
      final yAxisMap = json['yAxisConfig'] as Map<String, dynamic>;
      yAxisConfig = YAxisConfig(
        position: yAxisMap['position'] != null
            ? YAxisPosition.values.byName(yAxisMap['position'] as String)
            : YAxisPosition.left,
        label: yAxisMap['label'] as String?,
        unit: yAxisMap['unit'] as String?,
        min: (yAxisMap['min'] as num?)?.toDouble(),
        max: (yAxisMap['max'] as num?)?.toDouble(),
      );
    }

    return ChartSeries(
      id: json['id'] as String,
      name: json['name'] as String?,
      points:
          (json['points'] as List<dynamic>?)
              ?.map(
                (p) => ChartDataPoint(
                  x: (p['x'] as num).toDouble(),
                  y: (p['y'] as num).toDouble(),
                ),
              )
              .toList() ??
          const [],
      yAxisId: json['yAxisId'] as String?,
      yAxisConfig: yAxisConfig,
      unit: json['unit'] as String?,
      isXOrdered: json['isXOrdered'] as bool? ?? false,
    );
  }
}

/// Line chart series with configurable interpolation.
class LineChartSeries extends ChartSeries {
  const LineChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.style,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.25,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
    this.dataPointMarkerStyle = DataPointMarkerStyle.filled,
    this.dataPointMarkerBackground = Colors.white,
    this.lineGlow = 0.0,
    this.dataPointLabels,
    this.inlineLabel,
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double
  tension; // Used for bezier curves (0.0 = straight, 1.0 = very smooth)
  final bool showDataPointMarkers;
  final double dataPointMarkerRadius;
  final DataPointMarkerStyle dataPointMarkerStyle;

  /// Interior fill color for [DataPointMarkerStyle.hollow] markers.
  /// Set this to match your chart background so the circle masks the line.
  final Color dataPointMarkerBackground;
  final double lineGlow;
  final DataPointLabelConfig? dataPointLabels;
  final SeriesInlineLabelConfig? inlineLabel;

  @override
  LineChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
    DataPointMarkerStyle? dataPointMarkerStyle,
    Color? dataPointMarkerBackground,
    double? lineGlow,
    DataPointLabelConfig? dataPointLabels,
    SeriesInlineLabelConfig? inlineLabel,
  }) {
    return LineChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      style: style ?? this.style,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius:
          dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointMarkerStyle: dataPointMarkerStyle ?? this.dataPointMarkerStyle,
      dataPointMarkerBackground:
          dataPointMarkerBackground ?? this.dataPointMarkerBackground,
      lineGlow: lineGlow ?? this.lineGlow,
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
      inlineLabel: inlineLabel ?? this.inlineLabel,
    );
  }

  @override
  String toString() =>
      'LineChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LineChartSeries) return false;
    return super == other &&
        other.interpolation == interpolation &&
        other.strokeWidth == strokeWidth &&
        other.tension == tension &&
        other.showDataPointMarkers == showDataPointMarkers &&
        other.dataPointMarkerRadius == dataPointMarkerRadius &&
        other.dataPointMarkerStyle == dataPointMarkerStyle &&
        other.dataPointMarkerBackground == dataPointMarkerBackground &&
        other.lineGlow == lineGlow &&
        other.dataPointLabels == dataPointLabels &&
        other.inlineLabel == inlineLabel;
  }

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    interpolation,
    strokeWidth,
    tension,
    showDataPointMarkers,
    dataPointMarkerRadius,
    dataPointMarkerStyle,
    dataPointMarkerBackground,
    lineGlow,
    dataPointLabels,
    inlineLabel,
  ]);
}

/// Scatter plot series with configurable marker size.
class ScatterChartSeries extends ChartSeries {
  const ScatterChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.style,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.markerRadius = 5.0,
  });

  final double markerRadius;

  @override
  ScatterChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    double? markerRadius,
  }) {
    return ScatterChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      style: style ?? this.style,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      markerRadius: markerRadius ?? this.markerRadius,
    );
  }

  @override
  String toString() =>
      'ScatterChartSeries(id: $id, points: ${points.length}, markerRadius: $markerRadius)';
}

/// Area chart series with fill and interpolation.
class AreaChartSeries extends ChartSeries {
  const AreaChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.style,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.25,
    this.fillOpacity = 0.3,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
    this.dataPointMarkerStyle = DataPointMarkerStyle.filled,
    this.dataPointMarkerBackground = Colors.white,
    this.lineGlow = 0.0,
    this.dataPointLabels,
    this.inlineLabel,
    this.baselineValue,
    this.aboveBaselineFillColor,
    this.belowBaselineFillColor,
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double tension;
  final double fillOpacity;
  final bool showDataPointMarkers;
  final double dataPointMarkerRadius;
  final DataPointMarkerStyle dataPointMarkerStyle;

  /// Interior fill color for [DataPointMarkerStyle.hollow] markers.
  /// Set this to match your chart background so the circle masks the line.
  final Color dataPointMarkerBackground;
  final double lineGlow;
  final DataPointLabelConfig? dataPointLabels;
  final SeriesInlineLabelConfig? inlineLabel;
  final double? baselineValue;
  final Color? aboveBaselineFillColor;
  final Color? belowBaselineFillColor;

  @override
  AreaChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    double? fillOpacity,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
    DataPointMarkerStyle? dataPointMarkerStyle,
    Color? dataPointMarkerBackground,
    double? lineGlow,
    DataPointLabelConfig? dataPointLabels,
    SeriesInlineLabelConfig? inlineLabel,
    // NOTE: passing null for the three baseline fields preserves the current
    // value (null ?? this.field). To clear them, construct a new instance.
    double? baselineValue,
    Color? aboveBaselineFillColor,
    Color? belowBaselineFillColor,
  }) {
    return AreaChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      style: style ?? this.style,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius:
          dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointMarkerStyle: dataPointMarkerStyle ?? this.dataPointMarkerStyle,
      dataPointMarkerBackground:
          dataPointMarkerBackground ?? this.dataPointMarkerBackground,
      lineGlow: lineGlow ?? this.lineGlow,
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
      inlineLabel: inlineLabel ?? this.inlineLabel,
      baselineValue: baselineValue ?? this.baselineValue,
      aboveBaselineFillColor:
          aboveBaselineFillColor ?? this.aboveBaselineFillColor,
      belowBaselineFillColor:
          belowBaselineFillColor ?? this.belowBaselineFillColor,
    );
  }

  @override
  String toString() =>
      'AreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation, baselineValue: $baselineValue, aboveBaselineFillColor: $aboveBaselineFillColor, belowBaselineFillColor: $belowBaselineFillColor)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AreaChartSeries) return false;
    return super == other &&
        other.interpolation == interpolation &&
        other.strokeWidth == strokeWidth &&
        other.tension == tension &&
        other.fillOpacity == fillOpacity &&
        other.showDataPointMarkers == showDataPointMarkers &&
        other.dataPointMarkerRadius == dataPointMarkerRadius &&
        other.dataPointMarkerStyle == dataPointMarkerStyle &&
        other.dataPointMarkerBackground == dataPointMarkerBackground &&
        other.lineGlow == lineGlow &&
        other.dataPointLabels == dataPointLabels &&
        other.inlineLabel == inlineLabel &&
        other.baselineValue == baselineValue &&
        other.aboveBaselineFillColor == aboveBaselineFillColor &&
        other.belowBaselineFillColor == belowBaselineFillColor;
  }

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    interpolation,
    strokeWidth,
    tension,
    fillOpacity,
    showDataPointMarkers,
    dataPointMarkerRadius,
    dataPointMarkerStyle,
    dataPointMarkerBackground,
    lineGlow,
    dataPointLabels,
    inlineLabel,
    baselineValue,
    aboveBaselineFillColor,
    belowBaselineFillColor,
  ]);
}

/// Bar chart series with configurable geometry and presentation.
class BarChartSeries extends ChartSeries {
  const BarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.style,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.barWidthPercent,
    this.barWidthPixels,
    this.minWidth = 4.0,
    this.maxWidth = 100.0,
    this.barGap = 2.0,
    this.orientation = BarOrientation.vertical,
    this.layoutMode = BarLayoutMode.grouped,
    this.groupId,
    this.overlayWidthFactor = 1.0,
    this.overlayOffsetFactor = 0.0,
    this.baselineValue = 0.0,
    this.rangeStartValues = const [],
    this.waterfallTotalIndices = const {},
    this.waterfallStyle = const BarWaterfallStyle(),
    this.minBarLength = 0.0,
    this.barStyle = const BarChartStyle(),
    this.trackStyle,
    this.labelStyle = const BarLabelStyle(),
  }) : assert(
         barWidthPercent != null || barWidthPixels != null,
         'Must specify either barWidthPercent or barWidthPixels',
       ),
       assert(
         barWidthPercent == null ||
             (barWidthPercent >= 0.0 && barWidthPercent <= 1.0),
         'barWidthPercent must be between 0.0 and 1.0',
       ),
       assert(minWidth >= 0, 'minWidth must be non-negative'),
       assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth'),
       assert(barGap >= 0, 'barGap must be non-negative'),
       assert(
         overlayWidthFactor > 0 && overlayWidthFactor <= 1,
         'overlayWidthFactor must be greater than 0 and at most 1',
       ),
       assert(
         overlayOffsetFactor >= -1 && overlayOffsetFactor <= 1,
         'overlayOffsetFactor must be between -1 and 1',
       ),
       assert(minBarLength >= 0, 'minBarLength must be non-negative');

  final double?
  barWidthPercent; // Percentage of spacing between points (0.0 - 1.0)
  final double? barWidthPixels; // Fixed width in logical pixels
  final double minWidth; // Minimum bar width in logical pixels
  final double maxWidth; // Maximum bar width in logical pixels

  /// Pixel spacing between adjacent series in the same category group.
  final double barGap;

  /// Whether categories are arranged horizontally or vertically on screen.
  final BarOrientation orientation;

  /// How this series shares its category slot with other bar series.
  final BarLayoutMode layoutMode;

  /// Named composition group for stacked and overlaid layouts.
  ///
  /// Series with the same group ID share one category slot.
  final String? groupId;

  /// Width of an overlaid bar relative to its resolved category slot.
  ///
  /// Use `1` for the wide back layer and progressively smaller values for
  /// series painted later in the chart's series list. Ignored by other layout
  /// modes.
  final double overlayWidthFactor;

  /// Category-axis offset relative to the resolved overlay slot width.
  ///
  /// Negative values shift a vertical bar left or a horizontal bar up;
  /// positive values shift it right or down. A value of `0.15` moves the bar
  /// center by 15% of the slot width. Ignored by other layout modes.
  final double overlayOffsetFactor;

  /// Value-axis baseline from which bars grow.
  final double baselineValue;

  /// Optional value-axis starts for floating or range bars.
  ///
  /// Values align by index with [points], whose `y` values remain the range
  /// ends. An empty list preserves ordinary baseline bars. A null entry falls
  /// back to [baselineValue], which allows range and baseline bars in one
  /// series. Range values are supported by grouped and overlaid layouts; they
  /// are intentionally incompatible with stacked layouts.
  final List<double?> rangeStartValues;

  /// Point indices that render the running waterfall total from the baseline.
  ///
  /// A total point's `y` value is retained as source data but ignored for
  /// waterfall geometry. Non-total points are applied as sequential deltas in
  /// list order, starting at [baselineValue].
  final Set<int> waterfallTotalIndices;

  /// Semantic colors and connector presentation for waterfall layout.
  final BarWaterfallStyle waterfallStyle;

  bool isWaterfallTotal(int pointIndex) =>
      waterfallTotalIndices.contains(pointIndex);

  /// Value shown for a waterfall label, crosshair, or tooltip.
  ///
  /// Delta points retain their source `y`; total points resolve to the running
  /// cumulative value immediately before the total column.
  double waterfallDisplayValueFor(int pointIndex) {
    if (layoutMode != BarLayoutMode.waterfall ||
        !isWaterfallTotal(pointIndex)) {
      return points[pointIndex].y;
    }
    var runningTotal = baselineValue;
    for (var index = 0; index < pointIndex; index++) {
      if (!isWaterfallTotal(index)) runningTotal += points[index].y;
    }
    return runningTotal;
  }

  /// Whether at least one point has an explicit range start.
  bool get hasRangeValues => rangeStartValues.any((value) => value != null);

  /// Returns the explicit start for [pointIndex], or [baselineValue].
  double rangeStartValueFor(int pointIndex) =>
      pointIndex < rangeStartValues.length
      ? rangeStartValues[pointIndex] ?? baselineValue
      : baselineValue;

  /// Validates point alignment and composition rules for range values.
  ///
  /// Runtime validation preserves the const constructor because Dart does not
  /// allow list-length access in a const assertion.
  void validateConfiguration() {
    if (rangeStartValues.isNotEmpty &&
        rangeStartValues.length != points.length) {
      throw ArgumentError.value(
        rangeStartValues.length,
        'rangeStartValues',
        'Must be empty or match the points length (${points.length})',
      );
    }
    if (rangeStartValues.isNotEmpty &&
        (layoutMode == BarLayoutMode.stacked ||
            layoutMode == BarLayoutMode.normalizedStacked ||
            layoutMode == BarLayoutMode.waterfall)) {
      throw ArgumentError.value(
        layoutMode,
        'layoutMode',
        'Range bars cannot use stacked or waterfall layout modes',
      );
    }
    if (waterfallTotalIndices.isNotEmpty &&
        layoutMode != BarLayoutMode.waterfall) {
      throw ArgumentError.value(
        layoutMode,
        'layoutMode',
        'Waterfall totals require waterfall layout mode',
      );
    }
    for (final index in waterfallTotalIndices) {
      if (index < 0 || index >= points.length) {
        throw RangeError.range(
          index,
          0,
          points.isEmpty ? 0 : points.length - 1,
          'waterfallTotalIndices',
        );
      }
    }
    if (layoutMode == BarLayoutMode.waterfall) {
      for (var index = 1; index < points.length; index++) {
        if (points[index].x <= points[index - 1].x) {
          throw ArgumentError.value(
            points[index].x,
            'points[$index].x',
            'Waterfall points must use strictly increasing X values',
          );
        }
      }
    }
  }

  /// Backward-compatible validation entry point.
  void validateRangeConfiguration() => validateConfiguration();

  /// Minimum visible bar length in logical pixels.
  final double minBarLength;

  /// Fill, border, opacity, and corner presentation.
  final BarChartStyle barStyle;

  /// Optional passive capacity or target track behind each bar.
  final BarTrackStyle? trackStyle;

  /// Optional labels positioned using the rendered bar rectangle.
  final BarLabelStyle labelStyle;

  @override
  BarChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    double? barWidthPercent,
    double? barWidthPixels,
    double? minWidth,
    double? maxWidth,
    double? barGap,
    BarOrientation? orientation,
    BarLayoutMode? layoutMode,
    String? groupId,
    bool clearGroupId = false,
    double? overlayWidthFactor,
    double? overlayOffsetFactor,
    double? baselineValue,
    List<double?>? rangeStartValues,
    bool clearRangeStartValues = false,
    Set<int>? waterfallTotalIndices,
    bool clearWaterfallTotalIndices = false,
    BarWaterfallStyle? waterfallStyle,
    double? minBarLength,
    BarChartStyle? barStyle,
    BarTrackStyle? trackStyle,
    bool clearTrackStyle = false,
    BarLabelStyle? labelStyle,
  }) {
    return BarChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      style: style ?? this.style,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      barGap: barGap ?? this.barGap,
      orientation: orientation ?? this.orientation,
      layoutMode: layoutMode ?? this.layoutMode,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      overlayWidthFactor: overlayWidthFactor ?? this.overlayWidthFactor,
      overlayOffsetFactor: overlayOffsetFactor ?? this.overlayOffsetFactor,
      baselineValue: baselineValue ?? this.baselineValue,
      rangeStartValues: clearRangeStartValues
          ? const []
          : (rangeStartValues ?? this.rangeStartValues),
      waterfallTotalIndices: clearWaterfallTotalIndices
          ? const {}
          : (waterfallTotalIndices ?? this.waterfallTotalIndices),
      waterfallStyle: waterfallStyle ?? this.waterfallStyle,
      minBarLength: minBarLength ?? this.minBarLength,
      barStyle: barStyle ?? this.barStyle,
      trackStyle: clearTrackStyle ? null : (trackStyle ?? this.trackStyle),
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarChartSeries &&
          super == other &&
          other.barWidthPercent == barWidthPercent &&
          other.barWidthPixels == barWidthPixels &&
          other.minWidth == minWidth &&
          other.maxWidth == maxWidth &&
          other.barGap == barGap &&
          other.orientation == orientation &&
          other.layoutMode == layoutMode &&
          other.groupId == groupId &&
          other.overlayWidthFactor == overlayWidthFactor &&
          other.overlayOffsetFactor == overlayOffsetFactor &&
          other.baselineValue == baselineValue &&
          ChartSeries._listEquals(other.rangeStartValues, rangeStartValues) &&
          other.waterfallTotalIndices.length == waterfallTotalIndices.length &&
          other.waterfallTotalIndices.containsAll(waterfallTotalIndices) &&
          other.waterfallStyle == waterfallStyle &&
          other.minBarLength == minBarLength &&
          other.barStyle == barStyle &&
          other.trackStyle == trackStyle &&
          other.labelStyle == labelStyle;

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    barWidthPercent,
    barWidthPixels,
    minWidth,
    maxWidth,
    barGap,
    orientation,
    layoutMode,
    groupId,
    overlayWidthFactor,
    overlayOffsetFactor,
    baselineValue,
    Object.hashAll(rangeStartValues),
    Object.hashAll(waterfallTotalIndices.toList()..sort()),
    waterfallStyle,
    minBarLength,
    barStyle,
    trackStyle,
    labelStyle,
  ]);

  @override
  String toString() =>
      'BarChartSeries(id: $id, points: ${points.length}, orientation: ${orientation.name}, barWidth: ${barWidthPercent ?? barWidthPixels})';
}
