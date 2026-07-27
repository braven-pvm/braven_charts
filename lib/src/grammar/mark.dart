// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/painting.dart' show Color;

import '../models/bar_chart_style.dart' show BarLabelStyle, BarLayoutMode;
import '../models/chart_annotation.dart' show AnnotationAxis, TrendType;
import '../models/chart_series.dart' show LineInterpolation;
import '../models/data_point_label_config.dart' show DataPointLabelConfig;
import '../models/enums.dart' show MarkerShape;
import '../models/scatter_marker_style.dart'
    show
        ScatterCategoryStyle,
        ScatterColorEncoding,
        ScatterMarkerStyle,
        ScatterOpacityEncoding,
        ScatterSizeEncoding;
import '../theming/components/series_theme.dart' show SeriesMarkerShape;
import '../models/donut_chart_config.dart'
    show DonutCenterContent, DonutChartStyle;
import '../models/pie_chart_config.dart'
    show PieChartStyle, PieDataLabelConfig, RadialSliceRadiusConfig;
import '../models/polar_column_chart_series.dart'
    show
        PolarColumnIntervalStyle,
        PolarColumnPreset,
        PolarColumnStyle,
        PolarColumnTargetMarkerStyle;
import '../models/radial_category_series.dart' show RadialSliceGroupingConfig;
import '../models/radial_selection_style.dart' show RadialSelectionStyle;
import 'channel.dart';

/// One geometry (or one derived statistic) in a [PlotSpec].
///
/// The hierarchy is `sealed`: a `switch` over a `Mark<T>` that misses a
/// variant does not compile, so every dispatch site — the lowering, the
/// facade, a future emitter — is checked when a variant is added.
///
/// ## Geometry families
///
/// Cartesian geometries — [LineMark], [AreaMark], [BarMark], [ScatterMark],
/// [CandlestickMark] and [TrendMark] — plus the radial [RadialMark] family
/// ([PieMark], [DonutMark], [PolarMark]). A spec is either Cartesian or radial:
/// a [RadialMark] lowers through the radial branch of `spec.lower()`, may share
/// the spec with no other mark, and honors no Cartesian axis/grid option.
/// Faceting, log/time scale objects and string-column data adapters remain V2.
///
/// ## Marks have no `copyWith`
///
/// This is a decision, not an omission. A `copyWith` would make marks
/// config-shaped, which the package's surface enforcement reads as "must carry
/// `@chartSurface`", which would in turn generate a fluent verb surface over
/// the grammar layer — a second vocabulary for the same objects. Marks are
/// small; modify one by constructing a new one, or author through the chained
/// facade.
sealed class Mark<T> {
  /// Shared identity and axis-binding fields.
  const Mark({this.id, this.name, this.color, this.yAxisId});

  /// Stable id for this mark.
  ///
  /// It becomes the lowered series id, so annotations and axes bind to it.
  /// When omitted, the lowering assigns `mark-<index>` using the mark's
  /// position in [PlotSpec.marks].
  final String? id;

  /// Display name used by legends and tooltips.
  final String? name;

  /// Base color for this geometry. Null inherits the theme's series color.
  final Color? color;

  /// Id of the [YAxisConfig] in [PlotSpec.yAxes] this mark measures against.
  ///
  /// Null binds to the first axis. An id that matches no axis is rejected with
  /// `GrammarDiagnosticCode.unknownAxisId`.
  final String? yAxisId;
}

/// A connected line through `(x, y)`.
final class LineMark<T> extends Mark<T> {
  /// Creates a line geometry.
  const LineMark({
    required this.x,
    required this.y,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.colorBy,
    this.colorEncoding,
    this.strokeWidth,
    this.dashPattern,
    this.interpolation,
    this.showDataPointMarkers,
    this.dataPointLabels,
  });

  /// Horizontal position accessor.
  final FieldAccessor<T, num> x;

  /// Vertical position accessor.
  final FieldAccessor<T, num> y;

  /// Optional colour channel: each segment's stroke is the ramp colour of the
  /// leading point's value over the data's finite domain, baked at lowering
  /// into `ChartDataPoint.segmentStyle.color`. Requires [colorEncoding].
  final Channel<T>? colorBy;

  /// Colour ramp for [colorBy] (reused from scatter). Required when [colorBy]
  /// is set; inert otherwise (raises `orphanChannelEncoding`).
  final ScatterColorEncoding? colorEncoding;

  /// Stroke width in logical pixels. Null keeps the series default.
  final double? strokeWidth;

  /// Alternating painted/skipped distances. Null keeps the series default.
  final List<double>? dashPattern;

  /// Path interpolation. Null keeps the series default.
  final LineInterpolation? interpolation;

  /// Whether to draw a marker at each data point. Null keeps the series
  /// default (`LineChartSeries.showDataPointMarkers`, which is `false`).
  final bool? showDataPointMarkers;

  /// Inline data-point label configuration. Null keeps the series default
  /// (`LineChartSeries.dataPointLabels`, which is unset).
  final DataPointLabelConfig? dataPointLabels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineMark<T> &&
          other.x == x &&
          other.y == y &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.colorBy == colorBy &&
          other.colorEncoding == colorEncoding &&
          other.strokeWidth == strokeWidth &&
          listEquals(other.dashPattern, dashPattern) &&
          other.interpolation == interpolation &&
          other.showDataPointMarkers == showDataPointMarkers &&
          other.dataPointLabels == dataPointLabels;

  @override
  int get hashCode => Object.hash(
    x,
    y,
    id,
    name,
    color,
    yAxisId,
    colorBy,
    colorEncoding,
    strokeWidth,
    dashPattern == null ? null : Object.hashAll(dashPattern!),
    interpolation,
    showDataPointMarkers,
    dataPointLabels,
  );

  @override
  String toString() => 'LineMark(id: $id, name: $name)';
}

/// A filled band between `y` and a baseline.
final class AreaMark<T> extends Mark<T> {
  /// Creates an area geometry.
  const AreaMark({
    required this.x,
    required this.y,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.colorBy,
    this.colorEncoding,
    this.baseline,
    this.fillOpacity,
    this.strokeWidth,
    this.dashPattern,
    this.interpolation,
    this.showDataPointMarkers,
    this.dataPointLabels,
  });

  /// Horizontal position accessor.
  final FieldAccessor<T, num> x;

  /// Vertical position accessor.
  final FieldAccessor<T, num> y;

  /// Optional colour channel. Colours the area's TOP EDGE per segment (the
  /// leading-point rule), NOT the fill — value-driven fill is not yet
  /// supported. Baked at lowering into `ChartDataPoint.segmentStyle.color`.
  final Channel<T>? colorBy;

  /// Colour ramp for [colorBy] (reused from scatter). Required when [colorBy]
  /// is set; inert otherwise (raises `orphanChannelEncoding`).
  final ScatterColorEncoding? colorEncoding;

  /// Value the fill is anchored to. Null fills to the axis floor.
  final double? baseline;

  /// Fill opacity in `[0, 1]`. Null keeps the series default.
  final double? fillOpacity;

  /// Stroke width in logical pixels. Null keeps the series default.
  final double? strokeWidth;

  /// Alternating painted/skipped distances. Null keeps the series default.
  final List<double>? dashPattern;

  /// Path interpolation. Null keeps the series default.
  final LineInterpolation? interpolation;

  /// Whether to draw a marker at each data point. Null keeps the series
  /// default (`AreaChartSeries.showDataPointMarkers`, which is `false`).
  final bool? showDataPointMarkers;

  /// Inline data-point label configuration. Null keeps the series default
  /// (`AreaChartSeries.dataPointLabels`, which is unset).
  final DataPointLabelConfig? dataPointLabels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaMark<T> &&
          other.x == x &&
          other.y == y &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.colorBy == colorBy &&
          other.colorEncoding == colorEncoding &&
          other.baseline == baseline &&
          other.fillOpacity == fillOpacity &&
          other.strokeWidth == strokeWidth &&
          listEquals(other.dashPattern, dashPattern) &&
          other.interpolation == interpolation &&
          other.showDataPointMarkers == showDataPointMarkers &&
          other.dataPointLabels == dataPointLabels;

  @override
  int get hashCode => Object.hash(
    x,
    y,
    id,
    name,
    color,
    yAxisId,
    colorBy,
    colorEncoding,
    baseline,
    fillOpacity,
    strokeWidth,
    dashPattern == null ? null : Object.hashAll(dashPattern!),
    interpolation,
    showDataPointMarkers,
    dataPointLabels,
  );

  @override
  String toString() => 'AreaMark(id: $id, name: $name)';
}

/// A rectangular bar per row.
///
/// Orientation is NOT a per-mark property: transposing a Cartesian chart is a
/// whole-chart operation in this package, expressed by [PlotSpec.transposed].
final class BarMark<T> extends Mark<T> {
  /// Creates a bar geometry.
  const BarMark({
    required this.x,
    required this.y,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.barWidthPercent,
    this.barWidthPixels,
    this.barGap,
    this.layoutMode,
    this.groupId,
    this.baselineValue,
    this.labelStyle,
    this.colorBy,
    this.colorEncoding,
    this.sizeBy,
    this.sizeEncoding,
  });

  /// Horizontal position accessor.
  final FieldAccessor<T, num> x;

  /// Vertical position accessor.
  final FieldAccessor<T, num> y;

  /// Optional colour channel: each bar's fill is the ramp colour of this
  /// field's value over the data's finite domain, baked at lowering into
  /// `ChartDataPoint.pointStyle.color`. Requires [colorEncoding].
  final Channel<T>? colorBy;

  /// Colour ramp for [colorBy] (reused from scatter). Required when [colorBy]
  /// is set; inert otherwise (raises `orphanChannelEncoding`).
  final ScatterColorEncoding? colorEncoding;

  /// Optional size channel driving each bar's WIDTH. The value is mapped
  /// LINEARLY into [sizeEncoding]'s `[minimumRadius, maximumRadius]` range,
  /// reinterpreted as a width MULTIPLIER (scatter's sqrt/area radius mapping is
  /// wrong for width). Baked at lowering into `ChartDataPoint.pointStyle.size`.
  final Channel<T>? sizeBy;

  /// Width-multiplier range for [sizeBy] (min/max interpreted as multipliers).
  /// Defaults to 0.3..1.0 when [sizeBy] is set and this is null.
  final ScatterSizeEncoding? sizeEncoding;

  /// Bar width as a fraction of the slot, `0..1`.
  ///
  /// `BarChartSeries` requires exactly one of width percent or width pixels.
  /// When both are null the lowering supplies `0.8`, the package default.
  final double? barWidthPercent;

  /// Fixed bar width in logical pixels.
  final double? barWidthPixels;

  /// Gap between bars in logical pixels. Null keeps the series default.
  final double? barGap;

  /// Grouped, stacked, overlay or waterfall layout. Null keeps the default.
  final BarLayoutMode? layoutMode;

  /// Group key that ties this mark to sibling bars in the same slot.
  final String? groupId;

  /// Value bars grow from. Null keeps the series default.
  final double? baselineValue;

  /// Inline bar-label configuration. Bars have no per-point marker toggle —
  /// a bar is its own mark — so this is the bar family's equivalent of the
  /// data-point labels the line and area marks carry. Null keeps the series
  /// default (`BarChartSeries.labelStyle`, which is `const BarLabelStyle()`).
  final BarLabelStyle? labelStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarMark<T> &&
          other.x == x &&
          other.y == y &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.barWidthPercent == barWidthPercent &&
          other.barWidthPixels == barWidthPixels &&
          other.barGap == barGap &&
          other.layoutMode == layoutMode &&
          other.groupId == groupId &&
          other.baselineValue == baselineValue &&
          other.labelStyle == labelStyle &&
          other.colorBy == colorBy &&
          other.colorEncoding == colorEncoding &&
          other.sizeBy == sizeBy &&
          other.sizeEncoding == sizeEncoding;

  @override
  int get hashCode => Object.hash(
    x,
    y,
    id,
    name,
    color,
    yAxisId,
    barWidthPercent,
    barWidthPixels,
    barGap,
    layoutMode,
    groupId,
    baselineValue,
    labelStyle,
    colorBy,
    colorEncoding,
    sizeBy,
    sizeEncoding,
  );

  @override
  String toString() => 'BarMark(id: $id, name: $name)';
}

/// A marker per row, the only V1 geometry with scale-driven channels.
///
/// ## Channels and their encoding templates
///
/// A channel says WHICH field to read; the matching `Scatter*Encoding` says
/// how the scale is configured. Two of the three quantitative encodings have
/// a usable all-default configuration, so the template is optional:
///
/// | channel      | template          | required? |
/// |--------------|-------------------|-----------|
/// | [size]       | [sizeEncoding]    | optional — defaults to `ScatterSizeEncoding()` |
/// | [opacityBy]  | [opacityEncoding] | optional — defaults to `ScatterOpacityEncoding()` |
/// | [colorBy]    | [colorEncoding]   | REQUIRED — a color ramp has no sensible default |
/// | [categoryBy] | [categories]      | REQUIRED — each category must set a color or a shape |
///
/// A channel without its required template is rejected with
/// `GrammarDiagnosticCode.missingChannelEncoding`. The package ships no
/// categorical palette and no default color ramp, and inventing one here would
/// mint design surface the rest of the library does not have.
final class ScatterMark<T> extends Mark<T> {
  /// Creates a scatter geometry.
  const ScatterMark({
    required this.x,
    required this.y,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.size,
    this.sizeEncoding,
    this.colorBy,
    this.colorEncoding,
    this.opacityBy,
    this.opacityEncoding,
    this.categoryBy,
    this.categories = const <ScatterCategoryStyle>[],
    this.markerRadius,
    this.markerShape,
    this.markerStyle,
  });

  /// Horizontal position accessor.
  final FieldAccessor<T, num> x;

  /// Vertical position accessor.
  final FieldAccessor<T, num> y;

  /// Marker-area channel. Lowers to `ChartDataPoint.magnitude`.
  final Channel<T>? size;

  /// Scale configuration for [size].
  final ScatterSizeEncoding? sizeEncoding;

  /// Continuous color channel. Lowers to `ChartDataPoint.colorValue`.
  final Channel<T>? colorBy;

  /// Scale configuration for [colorBy]. Required whenever [colorBy] is set.
  final ScatterColorEncoding? colorEncoding;

  /// Opacity channel. Lowers to `ChartDataPoint.opacityValue`.
  final Channel<T>? opacityBy;

  /// Scale configuration for [opacityBy].
  final ScatterOpacityEncoding? opacityEncoding;

  /// Categorical channel. Lowers to `ChartDataPoint.categoryValue`.
  final CategoryChannel<T>? categoryBy;

  /// Category styles for [categoryBy]. Required whenever [categoryBy] is set.
  final List<ScatterCategoryStyle> categories;

  /// Base marker radius in logical pixels. Null keeps the series default.
  final double? markerRadius;

  /// Marker silhouette. Null keeps the series default.
  final SeriesMarkerShape? markerShape;

  /// Marker fill/stroke overrides. Null keeps the series default.
  final ScatterMarkerStyle? markerStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterMark<T> &&
          other.x == x &&
          other.y == y &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.size == size &&
          other.sizeEncoding == sizeEncoding &&
          other.colorBy == colorBy &&
          other.colorEncoding == colorEncoding &&
          other.opacityBy == opacityBy &&
          other.opacityEncoding == opacityEncoding &&
          other.categoryBy == categoryBy &&
          listEquals(other.categories, categories) &&
          other.markerRadius == markerRadius &&
          other.markerShape == markerShape &&
          other.markerStyle == markerStyle;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    x,
    y,
    id,
    name,
    color,
    yAxisId,
    size,
    sizeEncoding,
    colorBy,
    colorEncoding,
    opacityBy,
    opacityEncoding,
    categoryBy,
    Object.hashAll(categories),
    markerRadius,
    markerShape,
    markerStyle,
  ]);

  @override
  String toString() => 'ScatterMark(id: $id, name: $name)';
}

/// An open-high-low-close candle per row.
final class CandlestickMark<T> extends Mark<T> {
  /// Creates a candlestick geometry.
  const CandlestickMark({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.timestamp,
  });

  /// Horizontal position accessor. Values must be finite and strictly
  /// increasing across the data list.
  final FieldAccessor<T, num> x;

  /// Opening value accessor.
  final FieldAccessor<T, num> open;

  /// High value accessor.
  final FieldAccessor<T, num> high;

  /// Low value accessor.
  final FieldAccessor<T, num> low;

  /// Closing value accessor. Also becomes the point's generic `y`.
  final FieldAccessor<T, num> close;

  /// Optional wall-clock stamp carried on each candle.
  final FieldAccessor<T, DateTime>? timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickMark<T> &&
          other.x == x &&
          other.open == open &&
          other.high == high &&
          other.low == low &&
          other.close == close &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(
    x,
    open,
    high,
    low,
    close,
    id,
    name,
    color,
    yAxisId,
    timestamp,
  );

  @override
  String toString() => 'CandlestickMark(id: $id, name: $name)';
}

/// A statistical trend derived from another mark's lowered series.
///
/// Unlike the other variants this mark produces no geometry of its own: it
/// lowers to a `TrendAnnotation` bound to [sourceMarkId]. The inherited
/// [Mark.color] is the trend line's color.
///
/// [Mark.yAxisId] is deliberately NOT a constructor parameter here: a trend is
/// drawn in its source series' coordinate space, so it follows that series'
/// axis and cannot be bound to a different one.
final class TrendMark<T> extends Mark<T> {
  /// Creates a trend statistic over the mark identified by [sourceMarkId].
  const TrendMark({
    required this.sourceMarkId,
    super.id,
    super.name,
    super.color,
    this.trendType = TrendType.linear,
    this.windowSize,
    this.showConfidenceBand = false,
    this.lineWidth,
    this.dashPattern,
  });

  /// Id of the geometry mark this trend is computed over.
  ///
  /// Must resolve to a non-trend mark in the same [PlotSpec], otherwise
  /// `GrammarDiagnosticCode.unknownTrendSource` is raised.
  final String sourceMarkId;

  /// Which statistic to fit.
  final TrendType trendType;

  /// Window length. Required when [trendType] is a moving average.
  final int? windowSize;

  /// Whether to draw the two-sided confidence band (linear fits only).
  final bool showConfidenceBand;

  /// Trend line width in logical pixels. Null keeps the annotation default.
  final double? lineWidth;

  /// Trend line dash pattern. Null draws a solid line.
  final List<double>? dashPattern;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendMark<T> &&
          other.sourceMarkId == sourceMarkId &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.trendType == trendType &&
          other.windowSize == windowSize &&
          other.showConfidenceBand == showConfidenceBand &&
          other.lineWidth == lineWidth &&
          listEquals(other.dashPattern, dashPattern);

  @override
  int get hashCode => Object.hash(
    sourceMarkId,
    id,
    name,
    color,
    yAxisId,
    trendType,
    windowSize,
    showConfidenceBand,
    lineWidth,
    dashPattern == null ? null : Object.hashAll(dashPattern!),
  );

  @override
  String toString() => 'TrendMark(id: $id, source: $sourceMarkId)';
}

/// A reference line at a fixed value on one axis.
///
/// Like [TrendMark], this mark produces no geometry: it lowers to a
/// `ThresholdAnnotation` appended to the plot's annotations. It carries neither
/// [Mark.name] nor [Mark.yAxisId] as a constructor parameter — a threshold is
/// drawn in axis-VALUE space, not a series' coordinate space, so it binds no Y
/// axis, and its on-chart caption is [label] (the annotation's own field),
/// which is why an inherited `name` that lowers to nothing is deliberately not
/// offered. The inherited [Mark.color] is the line color.
final class ThresholdMark<T> extends Mark<T> {
  /// Creates a reference line at [value] on [axis].
  const ThresholdMark({
    required this.value,
    this.axis = AnnotationAxis.y,
    super.id,
    super.color,
    this.label,
    this.strokeWidth,
    this.dashPattern,
  });

  /// The axis value the line is drawn at.
  final double value;

  /// Which axis the line is perpendicular to. Defaults to the Y axis.
  final AnnotationAxis axis;

  /// Optional on-chart caption. Null draws no label.
  final String? label;

  /// Line width in logical pixels. Null keeps the annotation default.
  final double? strokeWidth;

  /// Alternating painted/skipped distances. Null draws a solid line.
  final List<double>? dashPattern;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThresholdMark<T> &&
          other.value == value &&
          other.axis == axis &&
          other.id == id &&
          other.color == color &&
          other.label == label &&
          other.strokeWidth == strokeWidth &&
          listEquals(other.dashPattern, dashPattern);

  @override
  int get hashCode => Object.hash(
    value,
    axis,
    id,
    color,
    label,
    strokeWidth,
    dashPattern == null ? null : Object.hashAll(dashPattern!),
  );

  @override
  String toString() => 'ThresholdMark(id: $id, value: $value)';
}

/// A shaded band between two values on one axis.
///
/// Like [TrendMark], this mark produces no geometry: it lowers to a
/// `RangeAnnotation` appended to the plot's annotations. [axis] selects whether
/// the band spans the X or the Y axis; the perpendicular direction is left
/// unbounded, so this expresses a 1-D band, not a 2-D box. It carries neither
/// [Mark.name] nor [Mark.yAxisId] as a constructor parameter, for the same
/// reason [ThresholdMark] does not; the inherited [Mark.color] is the fill.
final class BandMark<T> extends Mark<T> {
  /// Creates a band from [start] to [end] on [axis].
  const BandMark({
    required this.start,
    required this.end,
    this.axis = AnnotationAxis.y,
    super.id,
    super.color,
    this.label,
  });

  /// The band's lower bound on [axis].
  final double start;

  /// The band's upper bound on [axis].
  final double end;

  /// Which axis the band spans. Defaults to the Y axis.
  final AnnotationAxis axis;

  /// Optional on-chart caption. Null draws no label.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BandMark<T> &&
          other.start == start &&
          other.end == end &&
          other.axis == axis &&
          other.id == id &&
          other.color == color &&
          other.label == label;

  @override
  int get hashCode => Object.hash(start, end, axis, id, color, label);

  @override
  String toString() => 'BandMark(id: $id, start: $start, end: $end)';
}

/// A marker on one existing series' data point.
///
/// Like [TrendMark], this mark produces no geometry: it lowers to a
/// `PointAnnotation` bound to ([seriesId], [dataPointIndex]) and appended to the
/// plot's annotations. It is NOT the scatter geometry — it annotates ONE point
/// of a series already in the plot, not a whole row list. The inherited
/// [Mark.color] is the marker fill; [Mark.name]/[Mark.yAxisId] are not
/// parameters here for the same reason the other reference marks omit them.
final class PointMark<T> extends Mark<T> {
  /// Marks point [dataPointIndex] of the series identified by [seriesId].
  const PointMark({
    required this.seriesId,
    required this.dataPointIndex,
    super.id,
    super.color,
    this.label,
    this.markerSize,
    this.markerShape,
  });

  /// Id of the geometry mark whose point is annotated.
  final String seriesId;

  /// Index of the annotated point within that series (must be `>= 0`).
  final int dataPointIndex;

  /// Optional on-chart caption. Null draws no label.
  final String? label;

  /// Marker size in logical pixels. Null keeps the annotation default.
  final double? markerSize;

  /// Marker silhouette. Null keeps the annotation default.
  final MarkerShape? markerShape;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointMark<T> &&
          other.seriesId == seriesId &&
          other.dataPointIndex == dataPointIndex &&
          other.id == id &&
          other.color == color &&
          other.label == label &&
          other.markerSize == markerSize &&
          other.markerShape == markerShape;

  @override
  int get hashCode => Object.hash(
    seriesId,
    dataPointIndex,
    id,
    color,
    label,
    markerSize,
    markerShape,
  );

  @override
  String toString() => 'PointMark(id: $id, series: $seriesId)';
}

/// A radial geometry: a whole-dataset arc mark, not a per-point Cartesian one.
///
/// Every radial variant shares two channels — [category] (the slice/column
/// identity) and [value] (its magnitude) — so they live on this sealed base.
/// A spec containing any [RadialMark] is a RADIAL spec: it lowers through the
/// radial branch of `spec.lower()`, may contain no other mark, and honors no
/// Cartesian axis/grid option. Like the Cartesian marks these hold functions,
/// so they carry no `copyWith` and no `@chartSurface`.
sealed class RadialMark<T> extends Mark<T> {
  /// Shared radial channels plus the inherited identity fields.
  const RadialMark({
    required this.category,
    required this.value,
    super.id,
    super.name,
    super.color,
    this.unit,
  });

  /// Slice/column identity accessor. Stringified into the category label.
  final FieldAccessor<T, Object?> category;

  /// Magnitude accessor: angle-share for pie/donut, radius for polar.
  final FieldAccessor<T, num> value;

  /// Measure unit carried by every radial series (`ChartSeries.unit`). Null
  /// lowers to a series with no unit. Shared by pie/donut/concentric/polar.
  final String? unit;
}

/// A pie: each row is a slice, [RadialMark.value] is the angle-share.
final class PieMark<T> extends RadialMark<T> {
  /// Creates a pie geometry.
  const PieMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    super.unit,
    this.radius,
    this.style,
    this.selectionStyle,
    this.dataLabels,
    this.sliceRadiusConfig,
    this.sliceGroupingConfig,
  });

  /// Optional second metric → variable slice radius (Nightingale). Null keeps
  /// every slice at the series radius.
  final FieldAccessor<T, num>? radius;

  /// Slice geometry/appearance. Null lowers to `const PieChartStyle()`.
  final PieChartStyle? style;

  /// Durable slice-selection presentation. Null lowers to
  /// `const RadialSelectionStyle()`.
  final RadialSelectionStyle? selectionStyle;

  /// Data-label configuration. Null lowers to `const PieDataLabelConfig()`.
  final PieDataLabelConfig? dataLabels;

  /// Variable slice-radius encoding for the [radius] second metric. Null keeps
  /// a fixed radius. Its optional `formatter` callback is not reproducible as a
  /// literal and is dropped by the source emitter with an honest placeholder.
  final RadialSliceRadiusConfig? sliceRadiusConfig;

  /// Deterministic small-slice grouping projection. Null keeps every slice.
  final RadialSliceGroupingConfig? sliceGroupingConfig;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieMark<T> &&
          other.category == category &&
          other.value == value &&
          other.radius == radius &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.unit == unit &&
          other.style == style &&
          other.selectionStyle == selectionStyle &&
          other.dataLabels == dataLabels &&
          other.sliceRadiusConfig == sliceRadiusConfig &&
          other.sliceGroupingConfig == sliceGroupingConfig;

  @override
  int get hashCode => Object.hash(
    category,
    value,
    radius,
    id,
    name,
    color,
    unit,
    style,
    selectionStyle,
    dataLabels,
    sliceRadiusConfig,
    sliceGroupingConfig,
  );

  @override
  String toString() => 'PieMark(id: $id, name: $name)';
}

/// A donut. With [ring] set, rows partition into concentric `DonutChartSeries`
/// (one per distinct ring value, in first-seen order); without it, a single
/// donut.
final class DonutMark<T> extends RadialMark<T> {
  /// Creates a donut geometry.
  const DonutMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    super.unit,
    this.radius,
    this.ring,
    this.style,
    this.selectionStyle,
    this.center,
    this.dataLabels,
    this.sliceRadiusConfig,
    this.sliceGroupingConfig,
  });

  /// Optional second metric → variable slice radius. Null keeps a fixed radius.
  final FieldAccessor<T, num>? radius;

  /// Concentric-ring grouping channel. Absent = a single donut.
  final FieldAccessor<T, Object?>? ring;

  /// Donut geometry/appearance. Null lowers to `const DonutChartStyle()`.
  final DonutChartStyle? style;

  /// Durable slice-selection presentation. Null lowers to
  /// `const RadialSelectionStyle()`.
  final RadialSelectionStyle? selectionStyle;

  /// Center summary. For a single donut this is the series' center; for a
  /// concentric composition it is the shared `ConcentricDonutConfig.centerContent`.
  final DonutCenterContent? center;

  /// Data-label configuration. Null lowers to `const PieDataLabelConfig()`.
  final PieDataLabelConfig? dataLabels;

  /// Variable slice-radius encoding for the [radius] second metric. Null keeps
  /// a fixed radius. Its optional `formatter` callback is not reproducible as a
  /// literal and is dropped by the source emitter with an honest placeholder.
  final RadialSliceRadiusConfig? sliceRadiusConfig;

  /// Deterministic small-slice grouping projection. Null keeps every slice.
  final RadialSliceGroupingConfig? sliceGroupingConfig;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutMark<T> &&
          other.category == category &&
          other.value == value &&
          other.radius == radius &&
          other.ring == ring &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.unit == unit &&
          other.style == style &&
          other.selectionStyle == selectionStyle &&
          other.center == center &&
          other.dataLabels == dataLabels &&
          other.sliceRadiusConfig == sliceRadiusConfig &&
          other.sliceGroupingConfig == sliceGroupingConfig;

  @override
  int get hashCode => Object.hash(
    category,
    value,
    radius,
    ring,
    id,
    name,
    color,
    unit,
    style,
    selectionStyle,
    center,
    dataLabels,
    sliceRadiusConfig,
    sliceGroupingConfig,
  );

  @override
  String toString() => 'DonutMark(id: $id, name: $name)';
}

/// A polar column: [RadialMark.category] is the angular position and
/// [RadialMark.value] is the radius (magnitude).
final class PolarMark<T> extends RadialMark<T> {
  /// Creates a polar-column geometry.
  const PolarMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    super.unit,
    this.style,
    this.selectionStyle,
    this.columnColor,
    this.target,
    this.targetMarkerStyle,
    this.intervalLow,
    this.intervalHigh,
    this.intervalStyle,
    this.preset = PolarColumnPreset.standard,
  });

  /// Column geometry/appearance. Null lowers to `const PolarColumnStyle()`.
  final PolarColumnStyle? style;

  /// Durable column-selection presentation. Null lowers to
  /// `const RadialSelectionStyle()`.
  final RadialSelectionStyle? selectionStyle;

  /// Per-row column color override, keyed by the row's category.
  ///
  /// Returning null for a row leaves that category on the series color, which
  /// is what an unset accessor does for every row.
  final FieldAccessor<T, Color?>? columnColor;

  /// Per-row target (benchmark) value on the shared radial scale.
  ///
  /// Targets are absolute values, not deltas from [value]. Returning null for a
  /// row leaves that category without a target marker.
  final FieldAccessor<T, num?>? target;

  /// Appearance of the target markers drawn for [target]. Null lowers to
  /// `const PolarColumnTargetMarkerStyle()`.
  final PolarColumnTargetMarkerStyle? targetMarkerStyle;

  /// Per-row lower interval bound on the shared radial scale.
  ///
  /// Must be set together with [intervalHigh]; supplying only one bound raises
  /// `GrammarDiagnosticCode.incompletePolarInterval` at lowering.
  final FieldAccessor<T, num?>? intervalLow;

  /// Per-row upper interval bound on the shared radial scale.
  ///
  /// Must be set together with [intervalLow]; supplying only one bound raises
  /// `GrammarDiagnosticCode.incompletePolarInterval` at lowering.
  final FieldAccessor<T, num?>? intervalHigh;

  /// Appearance of the intervals drawn for [intervalLow]/[intervalHigh]. Null
  /// lowers to `const PolarColumnIntervalStyle()`.
  final PolarColumnIntervalStyle? intervalStyle;

  /// Named interpretation of the series — linear-radius columns
  /// ([PolarColumnPreset.standard]) or an equal-angle Rose/Nightingale
  /// presentation ([PolarColumnPreset.rose]).
  final PolarColumnPreset preset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarMark<T> &&
          other.category == category &&
          other.value == value &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.unit == unit &&
          other.style == style &&
          other.selectionStyle == selectionStyle &&
          other.columnColor == columnColor &&
          other.target == target &&
          other.targetMarkerStyle == targetMarkerStyle &&
          other.intervalLow == intervalLow &&
          other.intervalHigh == intervalHigh &&
          other.intervalStyle == intervalStyle &&
          other.preset == preset;

  @override
  int get hashCode => Object.hash(
    category,
    value,
    id,
    name,
    color,
    unit,
    style,
    selectionStyle,
    columnColor,
    target,
    targetMarkerStyle,
    intervalLow,
    intervalHigh,
    intervalStyle,
    preset,
  );

  @override
  String toString() => 'PolarMark(id: $id, name: $name, preset: ${preset.name})';
}
