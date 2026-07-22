// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'bar_chart_style.dart';
import 'chart_data_point.dart';
import 'data_point_label_config.dart';
import 'series_inline_label_config.dart';
import 'path_animation_style.dart';
import 'scatter_marker_style.dart';
import 'scatter_render_config.dart';
import 'y_axis_config.dart';
import 'y_axis_position.dart';
import '../theming/components/series_theme.dart' show SeriesMarkerShape;

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
enum SeriesStyle {
  line,
  bar,
  scatter,
  area,
  rangeArea,
  pie,
  donut,
  candlestick,
  polarColumn,
}

/// Base class for chart series.
///
/// Now concrete to support generic usage like in BravenChart.
/// Supports optional Y-axis binding via [yAxisId] and value formatting
/// via [unit].
@ChartSurfaceExempt(
  'Base of the series family; the concrete series types are modelled '
  'individually. ChartSeries.copyWith returns ChartSeries, so every '
  'ChartSeriesFluent verb would hand back a statically bare ChartSeries and '
  'end the chain — no line-, bar- or scatter-specific verb could follow, '
  'which is exactly how series values are usually typed. The runtime value '
  'would survive (every concrete series overrides copyWith), so this is an '
  'API-quality exemption, not a data-loss one.',
)
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
      'points': points
          .map(
            (p) => {
              'x': p.x,
              'y': p.y,
              if (p.pointKey != null) 'pointKey': p.pointKey,
            },
          )
          .toList(),
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
                  pointKey: p['pointKey'] as String?,
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
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(excluded: ['id'])
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
    this.pathAnimation = const PathAnimationStyle(),
    this.dashPattern = const [],
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
  final PathAnimationStyle pathAnimation;

  /// Alternating painted and skipped distances used to stroke the line path.
  ///
  /// An empty list renders a solid stroke. Non-empty patterns must contain an
  /// even number of positive, finite values, for example `[2, 6]` for dots.
  final List<double> dashPattern;

  @override
  LineChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool clearStyle = false,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    bool clearYAxisId = false,
    YAxisConfig? yAxisConfig,
    bool clearYAxisConfig = false,
    String? unit,
    bool clearUnit = false,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
    DataPointMarkerStyle? dataPointMarkerStyle,
    Color? dataPointMarkerBackground,
    double? lineGlow,
    DataPointLabelConfig? dataPointLabels,
    bool clearDataPointLabels = false,
    SeriesInlineLabelConfig? inlineLabel,
    bool clearInlineLabel = false,
    PathAnimationStyle? pathAnimation,
    List<double>? dashPattern,
  }) {
    return LineChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      style: clearStyle ? null : (style ?? this.style),
      annotations: annotations ?? this.annotations,
      yAxisId: clearYAxisId ? null : (yAxisId ?? this.yAxisId),
      yAxisConfig: clearYAxisConfig
          ? null
          : (yAxisConfig ?? this.yAxisConfig),
      unit: clearUnit ? null : (unit ?? this.unit),
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
      dataPointLabels: clearDataPointLabels
          ? null
          : (dataPointLabels ?? this.dataPointLabels),
      inlineLabel: clearInlineLabel
          ? null
          : (inlineLabel ?? this.inlineLabel),
      pathAnimation: pathAnimation ?? this.pathAnimation,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }

  @override
  String toString() =>
      'LineChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation, dashPattern: $dashPattern)';

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
        other.inlineLabel == inlineLabel &&
        other.pathAnimation == pathAnimation &&
        ChartSeries._listEquals(other.dashPattern, dashPattern);
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
    pathAnimation,
    Object.hashAll(dashPattern),
  ]);
}

/// Scatter plot series with configurable marker size.
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(excluded: ['id'])
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
    this.markerShape = SeriesMarkerShape.circle,
    this.markerStyle,
    this.sizeEncoding,
    this.colorEncoding,
    this.opacityEncoding,
    this.categoryEncoding,
    this.jitter = const ScatterJitterConfig(),
    this.renderMode = ScatterRenderMode.points,
    this.clusterConfig = const ScatterClusterConfig(),
    this.binConfig = const ScatterBinConfig(),
    this.densityConfig = const ScatterDensityConfig(),
    this.dataPointLabels,
    this.interactionStyle = const ScatterInteractionStyle(),
  });

  final double markerRadius;
  final SeriesMarkerShape markerShape;
  final ScatterMarkerStyle? markerStyle;
  final ScatterSizeEncoding? sizeEncoding;
  final ScatterColorEncoding? colorEncoding;
  final ScatterOpacityEncoding? opacityEncoding;
  final ScatterCategoryEncoding? categoryEncoding;
  final ScatterJitterConfig jitter;
  final ScatterRenderMode renderMode;
  final ScatterClusterConfig clusterConfig;
  final ScatterBinConfig binConfig;
  final ScatterDensityConfig densityConfig;
  final DataPointLabelConfig? dataPointLabels;
  final ScatterInteractionStyle interactionStyle;

  @override
  ScatterChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool clearStyle = false,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    bool clearYAxisId = false,
    YAxisConfig? yAxisConfig,
    bool clearYAxisConfig = false,
    String? unit,
    bool clearUnit = false,
    double? markerRadius,
    SeriesMarkerShape? markerShape,
    ScatterMarkerStyle? markerStyle,
    bool clearMarkerStyle = false,
    ScatterSizeEncoding? sizeEncoding,
    bool clearSizeEncoding = false,
    ScatterColorEncoding? colorEncoding,
    bool clearColorEncoding = false,
    ScatterOpacityEncoding? opacityEncoding,
    bool clearOpacityEncoding = false,
    ScatterCategoryEncoding? categoryEncoding,
    bool clearCategoryEncoding = false,
    ScatterJitterConfig? jitter,
    ScatterRenderMode? renderMode,
    ScatterClusterConfig? clusterConfig,
    ScatterBinConfig? binConfig,
    ScatterDensityConfig? densityConfig,
    DataPointLabelConfig? dataPointLabels,
    bool clearDataPointLabels = false,
    ScatterInteractionStyle? interactionStyle,
  }) {
    return ScatterChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      style: clearStyle ? null : (style ?? this.style),
      annotations: annotations ?? this.annotations,
      yAxisId: clearYAxisId ? null : (yAxisId ?? this.yAxisId),
      yAxisConfig: clearYAxisConfig
          ? null
          : (yAxisConfig ?? this.yAxisConfig),
      unit: clearUnit ? null : (unit ?? this.unit),
      markerRadius: markerRadius ?? this.markerRadius,
      markerShape: markerShape ?? this.markerShape,
      markerStyle: clearMarkerStyle ? null : (markerStyle ?? this.markerStyle),
      sizeEncoding: clearSizeEncoding
          ? null
          : (sizeEncoding ?? this.sizeEncoding),
      colorEncoding: clearColorEncoding
          ? null
          : (colorEncoding ?? this.colorEncoding),
      opacityEncoding: clearOpacityEncoding
          ? null
          : (opacityEncoding ?? this.opacityEncoding),
      categoryEncoding: clearCategoryEncoding
          ? null
          : (categoryEncoding ?? this.categoryEncoding),
      jitter: jitter ?? this.jitter,
      renderMode: renderMode ?? this.renderMode,
      clusterConfig: clusterConfig ?? this.clusterConfig,
      binConfig: binConfig ?? this.binConfig,
      densityConfig: densityConfig ?? this.densityConfig,
      dataPointLabels: clearDataPointLabels
          ? null
          : (dataPointLabels ?? this.dataPointLabels),
      interactionStyle: interactionStyle ?? this.interactionStyle,
    );
  }

  @override
  String toString() =>
      'ScatterChartSeries(id: $id, points: ${points.length}, markerRadius: $markerRadius, markerShape: ${markerShape.name}, markerStyle: $markerStyle, sizeEncoding: $sizeEncoding, colorEncoding: $colorEncoding, opacityEncoding: $opacityEncoding, categoryEncoding: $categoryEncoding, jitter: $jitter, renderMode: ${renderMode.name}, clusterConfig: $clusterConfig, binConfig: $binConfig, densityConfig: $densityConfig, dataPointLabels: $dataPointLabels, interactionStyle: $interactionStyle)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScatterChartSeries) return false;
    return super == other &&
        other.markerRadius == markerRadius &&
        other.markerShape == markerShape &&
        other.markerStyle == markerStyle &&
        other.sizeEncoding == sizeEncoding &&
        other.colorEncoding == colorEncoding &&
        other.opacityEncoding == opacityEncoding &&
        other.categoryEncoding == categoryEncoding &&
        other.jitter == jitter &&
        other.renderMode == renderMode &&
        other.clusterConfig == clusterConfig &&
        other.binConfig == binConfig &&
        other.densityConfig == densityConfig &&
        other.dataPointLabels == dataPointLabels &&
        other.interactionStyle == interactionStyle;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    markerRadius,
    markerShape,
    markerStyle,
    sizeEncoding,
    colorEncoding,
    opacityEncoding,
    categoryEncoding,
    jitter,
    renderMode,
    clusterConfig,
    binConfig,
    densityConfig,
    dataPointLabels,
    interactionStyle,
  );
}

/// A linear gradient used to paint the interior of an [AreaChartSeries].
///
/// The gradient is resolved against the chart's plot bounds, so its colors stay
/// visually stable while series geometry animates or changes. Each color's
/// alpha is multiplied by [AreaChartSeries.fillOpacity].
class AreaGradient {
  const AreaGradient({
    required this.colors,
    this.stops,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  /// The colors blended across the area fill. Provide at least two colors.
  final List<Color> colors;

  /// Optional ordered positions from 0 to 1 corresponding to [colors].
  final List<double>? stops;

  /// Alignment where the gradient begins within the plot bounds.
  final Alignment begin;

  /// Alignment where the gradient ends within the plot bounds.
  final Alignment end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaGradient &&
          _listEquals(other.colors, colors) &&
          _listEquals(other.stops, stops) &&
          other.begin == begin &&
          other.end == end;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colors),
    stops == null ? null : Object.hashAll(stops!),
    begin,
    end,
  );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Area chart series with fill and interpolation.
///
/// [id] is force-excluded from the fluent surface: a series id is a JOIN
/// KEY — Y axes, annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Construct the series with the id it should carry.
@ChartSurface(excluded: ['id'])
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
    this.fillGradient,
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
    this.pathAnimation = const PathAnimationStyle(),
    this.dashPattern = const [],
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double tension;
  final double fillOpacity;

  /// Optional plot-bound gradient for the area interior.
  ///
  /// When [baselineValue] is configured, the positive and negative baseline
  /// fill colors take precedence and this gradient is ignored.
  final AreaGradient? fillGradient;
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
  final PathAnimationStyle pathAnimation;

  /// Alternating painted and skipped distances used to stroke the area edge.
  ///
  /// The area fill remains continuous. An empty list renders a solid edge;
  /// non-empty patterns must contain an even number of positive, finite values.
  final List<double> dashPattern;

  @override
  AreaChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool clearStyle = false,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    bool clearYAxisId = false,
    YAxisConfig? yAxisConfig,
    bool clearYAxisConfig = false,
    String? unit,
    bool clearUnit = false,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    double? fillOpacity,
    AreaGradient? fillGradient,
    bool clearFillGradient = false,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
    DataPointMarkerStyle? dataPointMarkerStyle,
    Color? dataPointMarkerBackground,
    double? lineGlow,
    DataPointLabelConfig? dataPointLabels,
    bool clearDataPointLabels = false,
    SeriesInlineLabelConfig? inlineLabel,
    bool clearInlineLabel = false,
    double? baselineValue,
    bool clearBaselineValue = false,
    Color? aboveBaselineFillColor,
    bool clearAboveBaselineFillColor = false,
    Color? belowBaselineFillColor,
    bool clearBelowBaselineFillColor = false,
    PathAnimationStyle? pathAnimation,
    List<double>? dashPattern,
  }) {
    return AreaChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      style: clearStyle ? null : (style ?? this.style),
      annotations: annotations ?? this.annotations,
      yAxisId: clearYAxisId ? null : (yAxisId ?? this.yAxisId),
      yAxisConfig: clearYAxisConfig
          ? null
          : (yAxisConfig ?? this.yAxisConfig),
      unit: clearUnit ? null : (unit ?? this.unit),
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      fillGradient: clearFillGradient
          ? null
          : fillGradient ?? this.fillGradient,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius:
          dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointMarkerStyle: dataPointMarkerStyle ?? this.dataPointMarkerStyle,
      dataPointMarkerBackground:
          dataPointMarkerBackground ?? this.dataPointMarkerBackground,
      lineGlow: lineGlow ?? this.lineGlow,
      dataPointLabels: clearDataPointLabels
          ? null
          : (dataPointLabels ?? this.dataPointLabels),
      inlineLabel: clearInlineLabel
          ? null
          : (inlineLabel ?? this.inlineLabel),
      baselineValue: clearBaselineValue
          ? null
          : (baselineValue ?? this.baselineValue),
      aboveBaselineFillColor: clearAboveBaselineFillColor
          ? null
          : (aboveBaselineFillColor ?? this.aboveBaselineFillColor),
      belowBaselineFillColor: clearBelowBaselineFillColor
          ? null
          : (belowBaselineFillColor ?? this.belowBaselineFillColor),
      pathAnimation: pathAnimation ?? this.pathAnimation,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }

  @override
  String toString() =>
      'AreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation, dashPattern: $dashPattern, fillGradient: $fillGradient, baselineValue: $baselineValue, aboveBaselineFillColor: $aboveBaselineFillColor, belowBaselineFillColor: $belowBaselineFillColor)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AreaChartSeries) return false;
    return super == other &&
        other.interpolation == interpolation &&
        other.strokeWidth == strokeWidth &&
        other.tension == tension &&
        other.fillOpacity == fillOpacity &&
        other.fillGradient == fillGradient &&
        other.showDataPointMarkers == showDataPointMarkers &&
        other.dataPointMarkerRadius == dataPointMarkerRadius &&
        other.dataPointMarkerStyle == dataPointMarkerStyle &&
        other.dataPointMarkerBackground == dataPointMarkerBackground &&
        other.lineGlow == lineGlow &&
        other.dataPointLabels == dataPointLabels &&
        other.inlineLabel == inlineLabel &&
        other.baselineValue == baselineValue &&
        other.aboveBaselineFillColor == aboveBaselineFillColor &&
        other.belowBaselineFillColor == belowBaselineFillColor &&
        other.pathAnimation == pathAnimation &&
        ChartSeries._listEquals(other.dashPattern, dashPattern);
  }

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    interpolation,
    strokeWidth,
    tension,
    fillOpacity,
    fillGradient,
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
    pathAnimation,
    Object.hashAll(dashPattern),
  ]);
}

/// Bar chart series with configurable geometry and presentation.
///
/// Bar WIDTH is construction-only: there is no generated verb for
/// [barWidthPercent] or [barWidthPixels]. The constructor asserts
/// `barWidthPercent != null || barWidthPixels != null` — an OR, so the two
/// are alternatives, not a pair — while `copyWith` merges each with `??` and
/// exposes no clear flag for either. No fluent verb can therefore express
/// "size in percent INSTEAD of pixels": `withBarWidthPercent` would leave the
/// pixel width in place and lose to it at render time, and the combined
/// `withBarWidth(percent, pixels)` this class used to generate required BOTH,
/// which made its percent argument dead in every possible call. Choose the
/// sizing mode at construction, where the alternatives are visible.
///
/// `id` is force-excluded as well: a series id is a JOIN KEY — axes
/// ([yAxisId]), annotations and artifact documents bind to it — so a verb
/// that rewrites it mid-chain silently detaches the series from everything
/// that references it. Rebuild the series with the id it should carry.
@ChartSurface(
  excluded: ['id', 'barWidthPercent', 'barWidthPixels'],
  combinedSetters: [
    // `maxWidth >= minWidth` — the bounds only move as a pair.
    CombinedSetter('withWidthBounds', ['maxWidth', 'minWidth']),
  ],
)
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
    this.divergingRole = BarDivergingRole.positive,
    this.divergingStyle = const BarDivergingStyle(),
    this.overlayWidthFactor = 1.0,
    this.overlayOffsetFactor = 0.0,
    this.baselineValue = 0.0,
    this.rangeStartValues = const [],
    this.waterfallTotalIndices = const {},
    this.waterfallStyle = const BarWaterfallStyle(),
    this.minBarLength = 0.0,
    this.barStyle = const BarChartStyle(),
    this.trackStyle,
    this.lollipopStyle,
    this.bulletStyle,
    this.targetValues = const [],
    this.targetMarkerStyle = const BarTargetMarkerStyle(),
    this.errorLowerValues = const [],
    this.errorUpperValues = const [],
    this.errorBarStyle = const BarErrorBarStyle(),
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

  /// Side occupied by this series in [BarLayoutMode.divergingStacked].
  ///
  /// Values remain non-negative magnitudes; the role supplies direction.
  final BarDivergingRole divergingRole;

  /// Shared center-line presentation for a diverging composition.
  final BarDivergingStyle divergingStyle;

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
      if (!isWaterfallTotal(index) && points[index].isValid) {
        runningTotal += points[index].y;
      }
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
    if (targetValues.isNotEmpty && targetValues.length != points.length) {
      throw ArgumentError.value(
        targetValues.length,
        'targetValues',
        'Must be empty or match the points length (${points.length})',
      );
    }
    if (errorLowerValues.isNotEmpty &&
        errorLowerValues.length != points.length) {
      throw ArgumentError.value(
        errorLowerValues.length,
        'errorLowerValues',
        'Must be empty or match the points length (${points.length})',
      );
    }
    if (errorUpperValues.isNotEmpty &&
        errorUpperValues.length != points.length) {
      throw ArgumentError.value(
        errorUpperValues.length,
        'errorUpperValues',
        'Must be empty or match the points length (${points.length})',
      );
    }
    if (errorLowerValues.isEmpty != errorUpperValues.isEmpty) {
      throw ArgumentError(
        'errorLowerValues and errorUpperValues must both be empty or supplied',
      );
    }
    for (var index = 0; index < errorLowerValues.length; index++) {
      final lower = errorLowerValues[index];
      final upper = errorUpperValues[index];
      if ((lower == null) != (upper == null)) {
        throw ArgumentError(
          'Error interval at index $index must supply both endpoints or neither',
        );
      }
      if (lower != null && upper != null && lower > upper) {
        throw ArgumentError(
          'Error interval lower value must not exceed its upper value at index $index',
        );
      }
    }
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
            layoutMode == BarLayoutMode.divergingStacked ||
            layoutMode == BarLayoutMode.waterfall)) {
      throw ArgumentError.value(
        layoutMode,
        'layoutMode',
        'Range bars cannot use stacked or waterfall layout modes',
      );
    }
    if (layoutMode == BarLayoutMode.divergingStacked) {
      for (var index = 0; index < points.length; index++) {
        if (!points[index].isValid) continue;
        final magnitude = points[index].y - baselineValue;
        if (!magnitude.isFinite || magnitude < 0) {
          throw ArgumentError.value(
            points[index].y,
            'points[$index].y',
            'Diverging stacked values must be finite magnitudes at or above the baseline',
          );
        }
      }
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
      double? previousX;
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        if (!point.isValid) continue;
        if (previousX != null && point.x <= previousX) {
          throw ArgumentError.value(
            point.x,
            'points[$index].x',
            'Waterfall points must use strictly increasing X values',
          );
        }
        previousX = point.x;
      }
    }
    final bullet = bulletStyle;
    if (lollipopStyle != null &&
        layoutMode != BarLayoutMode.grouped &&
        layoutMode != BarLayoutMode.overlaid) {
      throw ArgumentError.value(
        layoutMode,
        'layoutMode',
        'Lollipop bars require grouped or overlaid layout mode',
      );
    }
    if (lollipopStyle != null && bullet != null) {
      throw ArgumentError(
        'lollipopStyle and bulletStyle cannot both be supplied',
      );
    }
    if (bullet != null) {
      if (layoutMode != BarLayoutMode.grouped) {
        throw ArgumentError.value(
          layoutMode,
          'layoutMode',
          'Bullet ranges require grouped layout mode',
        );
      }
      if (trackStyle != null) {
        throw ArgumentError(
          'bulletStyle and trackStyle cannot both be supplied',
        );
      }
      if (hasRangeValues) {
        throw ArgumentError(
          'bulletStyle and rangeStartValues cannot both be supplied',
        );
      }
      if (bullet.ranges.isEmpty) {
        throw ArgumentError.value(
          bullet.ranges,
          'bulletStyle.ranges',
          'Bullet charts require at least one qualitative range',
        );
      }
      var previous = baselineValue;
      for (var index = 0; index < bullet.ranges.length; index++) {
        final range = bullet.ranges[index];
        if (!range.endValue.isFinite || range.endValue <= previous) {
          throw ArgumentError.value(
            range.endValue,
            'bulletStyle.ranges[$index].endValue',
            'Bullet range endpoints must be finite and strictly increase from the baseline',
          );
        }
        if (range.label?.trim().isEmpty == true) {
          throw ArgumentError.value(
            range.label,
            'bulletStyle.ranges[$index].label',
            'Bullet range labels must be non-empty when supplied',
          );
        }
        previous = range.endValue;
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

  /// Optional stem-and-head treatment replacing the filled bar body.
  ///
  /// Lollipop marks support grouped and overlaid layouts in either
  /// orientation. Tracks, labels, targets, and uncertainty remain available.
  final BarLollipopStyle? lollipopStyle;

  /// Optional qualitative ranges that turn each point into a bullet chart.
  ///
  /// The actual bar remains the interactive measure and [targetValues]
  /// provide the comparative marker. Ranges are passive shared context.
  final BarBulletStyle? bulletStyle;

  /// Optional benchmark values aligned by index with [points].
  ///
  /// Null entries omit the marker for that point. An empty list disables
  /// target markers for the series.
  final List<double?> targetValues;

  /// Presentation for benchmark markers drawn across the bars.
  final BarTargetMarkerStyle targetMarkerStyle;

  double? targetValueFor(int pointIndex) =>
      pointIndex < targetValues.length ? targetValues[pointIndex] : null;

  /// Absolute lower value-axis endpoints aligned by index with [points].
  ///
  /// Values are not deltas. A null pair omits the interval for that point.
  final List<double?> errorLowerValues;

  /// Absolute upper value-axis endpoints aligned by index with [points].
  final List<double?> errorUpperValues;

  /// Presentation for uncertainty stems and endpoint caps.
  final BarErrorBarStyle errorBarStyle;

  double? errorLowerValueFor(int pointIndex) =>
      pointIndex < errorLowerValues.length
      ? errorLowerValues[pointIndex]
      : null;

  double? errorUpperValueFor(int pointIndex) =>
      pointIndex < errorUpperValues.length
      ? errorUpperValues[pointIndex]
      : null;

  /// Optional labels positioned using the rendered bar rectangle.
  final BarLabelStyle labelStyle;

  @override
  BarChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
    bool clearStyle = false,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    bool clearYAxisId = false,
    YAxisConfig? yAxisConfig,
    bool clearYAxisConfig = false,
    String? unit,
    bool clearUnit = false,
    double? barWidthPercent,
    double? barWidthPixels,
    double? minWidth,
    double? maxWidth,
    double? barGap,
    BarOrientation? orientation,
    BarLayoutMode? layoutMode,
    String? groupId,
    bool clearGroupId = false,
    BarDivergingRole? divergingRole,
    BarDivergingStyle? divergingStyle,
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
    BarLollipopStyle? lollipopStyle,
    bool clearLollipopStyle = false,
    BarBulletStyle? bulletStyle,
    bool clearBulletStyle = false,
    List<double?>? targetValues,
    bool clearTargetValues = false,
    BarTargetMarkerStyle? targetMarkerStyle,
    List<double?>? errorLowerValues,
    List<double?>? errorUpperValues,
    bool clearErrorValues = false,
    BarErrorBarStyle? errorBarStyle,
    BarLabelStyle? labelStyle,
  }) {
    return BarChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      style: clearStyle ? null : (style ?? this.style),
      annotations: annotations ?? this.annotations,
      yAxisId: clearYAxisId ? null : (yAxisId ?? this.yAxisId),
      yAxisConfig: clearYAxisConfig
          ? null
          : (yAxisConfig ?? this.yAxisConfig),
      unit: clearUnit ? null : (unit ?? this.unit),
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      barGap: barGap ?? this.barGap,
      orientation: orientation ?? this.orientation,
      layoutMode: layoutMode ?? this.layoutMode,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      divergingRole: divergingRole ?? this.divergingRole,
      divergingStyle: divergingStyle ?? this.divergingStyle,
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
      lollipopStyle: clearLollipopStyle
          ? null
          : (lollipopStyle ?? this.lollipopStyle),
      bulletStyle: clearBulletStyle ? null : (bulletStyle ?? this.bulletStyle),
      targetValues: clearTargetValues
          ? const []
          : (targetValues ?? this.targetValues),
      targetMarkerStyle: targetMarkerStyle ?? this.targetMarkerStyle,
      errorLowerValues: clearErrorValues
          ? const []
          : (errorLowerValues ?? this.errorLowerValues),
      errorUpperValues: clearErrorValues
          ? const []
          : (errorUpperValues ?? this.errorUpperValues),
      errorBarStyle: errorBarStyle ?? this.errorBarStyle,
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
          other.divergingRole == divergingRole &&
          other.divergingStyle == divergingStyle &&
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
          other.lollipopStyle == lollipopStyle &&
          other.bulletStyle == bulletStyle &&
          ChartSeries._listEquals(other.targetValues, targetValues) &&
          other.targetMarkerStyle == targetMarkerStyle &&
          ChartSeries._listEquals(other.errorLowerValues, errorLowerValues) &&
          ChartSeries._listEquals(other.errorUpperValues, errorUpperValues) &&
          other.errorBarStyle == errorBarStyle &&
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
    divergingRole,
    divergingStyle,
    overlayWidthFactor,
    overlayOffsetFactor,
    baselineValue,
    Object.hashAll(rangeStartValues),
    Object.hashAll(waterfallTotalIndices.toList()..sort()),
    waterfallStyle,
    minBarLength,
    barStyle,
    trackStyle,
    lollipopStyle,
    bulletStyle,
    Object.hashAll(targetValues),
    targetMarkerStyle,
    Object.hashAll(errorLowerValues),
    Object.hashAll(errorUpperValues),
    errorBarStyle,
    labelStyle,
  ]);

  @override
  String toString() =>
      'BarChartSeries(id: $id, points: ${points.length}, orientation: ${orientation.name}, barWidth: ${barWidthPercent ?? barWidthPixels})';
}
