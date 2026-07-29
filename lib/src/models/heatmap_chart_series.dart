// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../meta/chart_surface.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'category_axis_config.dart';
import 'heatmap_color_scale.dart';
import 'heatmap_data_point.dart';
import 'path_animation_style.dart';
import 'y_axis_config.dart';

/// How Heatmap cells enter the plot.
enum HeatmapEntranceMode {
  /// Paint the target cells immediately.
  none,

  /// Fade cells from transparent to their resolved colour.
  fade,

  /// Fade and grow cells from their centres.
  scale,
}

/// Deterministic ordering applied to a Heatmap entrance animation.
enum HeatmapEntranceOrder {
  /// Animate every visible cell together.
  simultaneous,

  /// Reveal rows from the lowest Y coordinate to the highest.
  row,

  /// Reveal columns from the lowest X coordinate to the highest.
  column,

  /// Reveal from the matrix centre towards its edges.
  radial,
}

/// Motion settings for a native Heatmap series.
@ChartSurface()
final class HeatmapAnimationStyle {
  const HeatmapAnimationStyle({
    this.entranceMode = HeatmapEntranceMode.fade,
    this.entranceOrder = HeatmapEntranceOrder.row,
    this.entranceScale = 0.82,
    this.staggerFraction = 0.55,
    this.animateDataUpdates = true,
    this.entranceTiming = const PathAnimationTiming(),
    this.dataUpdateTiming = const PathAnimationTiming(),
  });

  /// Visual treatment used while the matrix first appears.
  final HeatmapEntranceMode entranceMode;

  /// Stable order in which cells join the entrance.
  final HeatmapEntranceOrder entranceOrder;

  /// Initial cell scale used by [HeatmapEntranceMode.scale].
  final double entranceScale;

  /// Fraction of the entrance timeline allocated to per-cell delay.
  final double staggerFraction;

  /// Whether stable-identity measured values interpolate on data updates.
  final bool animateDataUpdates;

  /// Timeline placement for the entrance animation.
  final PathAnimationTiming entranceTiming;

  /// Timeline placement for stable-identity value updates.
  final PathAnimationTiming dataUpdateTiming;

  void validate() {
    if (!entranceScale.isFinite || entranceScale < 0 || entranceScale > 1) {
      throw ArgumentError.value(
        entranceScale,
        'entranceScale',
        'must be finite and between zero and one',
      );
    }
    if (!staggerFraction.isFinite ||
        staggerFraction < 0 ||
        staggerFraction >= 1) {
      throw ArgumentError.value(
        staggerFraction,
        'staggerFraction',
        'must be finite, non-negative, and less than one',
      );
    }
    for (final (name, timing) in <(String, PathAnimationTiming)>[
      ('entranceTiming', entranceTiming),
      ('dataUpdateTiming', dataUpdateTiming),
    ]) {
      if (timing.delay.isNegative || (timing.duration?.isNegative ?? false)) {
        throw ArgumentError.value(
          timing,
          name,
          'delay and duration must be non-negative',
        );
      }
    }
  }

  HeatmapAnimationStyle copyWith({
    HeatmapEntranceMode? entranceMode,
    HeatmapEntranceOrder? entranceOrder,
    double? entranceScale,
    double? staggerFraction,
    bool? animateDataUpdates,
    PathAnimationTiming? entranceTiming,
    PathAnimationTiming? dataUpdateTiming,
  }) => HeatmapAnimationStyle(
    entranceMode: entranceMode ?? this.entranceMode,
    entranceOrder: entranceOrder ?? this.entranceOrder,
    entranceScale: entranceScale ?? this.entranceScale,
    staggerFraction: staggerFraction ?? this.staggerFraction,
    animateDataUpdates: animateDataUpdates ?? this.animateDataUpdates,
    entranceTiming: entranceTiming ?? this.entranceTiming,
    dataUpdateTiming: dataUpdateTiming ?? this.dataUpdateTiming,
  );

  @override
  bool operator ==(Object other) =>
      other is HeatmapAnimationStyle &&
      other.entranceMode == entranceMode &&
      other.entranceOrder == entranceOrder &&
      other.entranceScale == entranceScale &&
      other.staggerFraction == staggerFraction &&
      other.animateDataUpdates == animateDataUpdates &&
      other.entranceTiming == entranceTiming &&
      other.dataUpdateTiming == dataUpdateTiming;

  @override
  int get hashCode => Object.hash(
    entranceMode,
    entranceOrder,
    entranceScale,
    staggerFraction,
    animateDataUpdates,
    entranceTiming,
    dataUpdateTiming,
  );
}

/// A native Cartesian matrix whose independent measured value is encoded by
/// colour.
///
/// [x] and [y] remain spatial coordinates. [HeatmapDataPoint.value] is not
/// substituted into either axis, which keeps colour-scale semantics available
/// to rendering, interaction, tables, and generated source.
///
/// There is no generated `withPoints` verb. [points] is force-excluded because
/// `copyWith` accepts the wider `List<ChartDataPoint>` while every element must
/// remain a [HeatmapDataPoint] and every cell identity must remain unique.
/// Rebuild the series or use [copyWith] when replacing the matrix.
///
/// [id] is also force-excluded: it is a join key used by axes, annotations,
/// artifacts, and host integrations, not a presentation property.
@ChartSurface(
  excluded: ['id', 'points'],
  bodyValidated: [
    BodyValidated(
      'validateConfiguration() checks cell dimensions, gap and border '
      'geometry, label sizing, typed points, and unique cell identity after '
      'every construction. The validation reads fields rather than named '
      'parameters, so surface_gen cannot narrow it below the whole class.',
    ),
  ],
)
final class HeatmapChartSeries extends ChartSeries {
  HeatmapChartSeries({
    required super.id,
    super.name,
    required List<HeatmapDataPoint> points,
    required this.colorScale,
    super.metadata,
    super.annotations,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.cellWidth = 1,
    this.cellHeight = 1,
    this.gapFraction = 0.06,
    this.borderColor = const Color(0x26FFFFFF),
    this.borderWidth = 0,
    this.cornerRadius = 0,
    this.showCellLabels = false,
    this.cellLabelColor,
    this.cellLabelFontSize = 11,
    this.animation = const HeatmapAnimationStyle(),
  }) : super(
         points: List<HeatmapDataPoint>.unmodifiable(points),
         style: SeriesStyle.heatmap,
       ) {
    validateConfiguration();
  }

  /// Maps cell values to their rendered colours.
  final HeatmapColorScale colorScale;

  /// Width occupied by one cell in X-axis data units.
  final double cellWidth;

  /// Height occupied by one cell in Y-axis data units.
  final double cellHeight;

  /// Proportion of each cell reserved as spacing on both dimensions.
  final double gapFraction;

  /// Optional cell outline colour.
  final Color borderColor;

  /// Cell outline width in logical pixels.
  final double borderWidth;

  /// Cell corner radius in logical pixels.
  final double cornerRadius;

  /// Whether finite cell values are painted inside their cells.
  final bool showCellLabels;

  /// Explicit label colour. When absent, a contrast colour is derived.
  final Color? cellLabelColor;

  /// Cell-label size in logical pixels.
  final double cellLabelFontSize;

  /// Entrance and stable-identity data-update motion.
  final HeatmapAnimationStyle animation;

  late final List<HeatmapDataPoint> cells = points.cast<HeatmapDataPoint>();

  late final List<double> measuredValues = List<double>.unmodifiable([
    for (final cell in cells)
      if (!cell.isMissing) cell.value!,
  ]);

  late final double resolvedMinimumValue = measuredValues.isEmpty
      ? 0
      : measuredValues.reduce((left, right) => left < right ? left : right);

  late final double resolvedMaximumValue = measuredValues.isEmpty
      ? 1
      : measuredValues.reduce((left, right) => left > right ? left : right);

  HeatmapDataPoint cellAt(int index) => points[index] as HeatmapDataPoint;

  void validateConfiguration() {
    if (!cellWidth.isFinite || cellWidth <= 0) {
      throw ArgumentError.value(
        cellWidth,
        'cellWidth',
        'must be finite and greater than zero',
      );
    }
    if (!cellHeight.isFinite || cellHeight <= 0) {
      throw ArgumentError.value(
        cellHeight,
        'cellHeight',
        'must be finite and greater than zero',
      );
    }
    if (!gapFraction.isFinite || gapFraction < 0 || gapFraction >= 1) {
      throw ArgumentError.value(
        gapFraction,
        'gapFraction',
        'must be finite, non-negative, and less than one',
      );
    }
    if (!borderWidth.isFinite || borderWidth < 0) {
      throw ArgumentError.value(
        borderWidth,
        'borderWidth',
        'must be finite and non-negative',
      );
    }
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'cornerRadius',
        'must be finite and non-negative',
      );
    }
    if (!cellLabelFontSize.isFinite || cellLabelFontSize <= 0) {
      throw ArgumentError.value(
        cellLabelFontSize,
        'cellLabelFontSize',
        'must be finite and greater than zero',
      );
    }
    animation.validate();

    final identities = <HeatmapCellIdentity>{};
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point is! HeatmapDataPoint) {
        throw ArgumentError.value(
          point.runtimeType,
          'points[$index]',
          'HeatmapChartSeries requires HeatmapDataPoint values',
        );
      }
      if (!identities.add(point.identity)) {
        throw ArgumentError.value(
          point.identity,
          'points[$index]',
          'duplicates an existing Heatmap cell identity',
        );
      }
    }
  }

  /// Validates matrix coordinates against optional categorical axes.
  ///
  /// Heatmap cells use integer category centres. Supplying a categorical axis
  /// therefore makes fractional or out-of-domain coordinates an error instead
  /// of silently painting an unlabelled cell.
  void validateCategoryCoordinates({
    CategoryAxisConfig? xAxis,
    CategoryAxisConfig? yAxis,
  }) {
    xAxis?.validate(parameterName: 'xAxis.categoryAxis');
    yAxis?.validate(parameterName: 'yAxis.categoryAxis');

    for (var index = 0; index < cells.length; index++) {
      final cell = cells[index];
      _validateCategoryCoordinate(
        cell.x,
        axis: xAxis,
        parameterName: 'points[$index].x',
      );
      _validateCategoryCoordinate(
        cell.y,
        axis: yAxis,
        parameterName: 'points[$index].y',
      );
    }
  }

  static void _validateCategoryCoordinate(
    double value, {
    required CategoryAxisConfig? axis,
    required String parameterName,
  }) {
    if (axis == null || axis.categories.isEmpty) return;
    final index = value.round();
    if ((value - index).abs() > 0.000001) {
      throw ArgumentError.value(
        value,
        parameterName,
        'must be an integer category centre',
      );
    }
    if (index < 0 || index >= axis.categories.length) {
      throw ArgumentError.value(
        value,
        parameterName,
        'falls outside the configured category domain',
      );
    }
  }

  @override
  HeatmapChartSeries copyWith({
    String? id,
    String? name,
    bool clearName = false,
    List<ChartDataPoint>? points,
    Color? color,
    bool clearColor = false,
    SeriesStyle? style,
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
    HeatmapColorScale? colorScale,
    double? cellWidth,
    double? cellHeight,
    double? gapFraction,
    Color? borderColor,
    double? borderWidth,
    double? cornerRadius,
    bool? showCellLabels,
    Color? cellLabelColor,
    bool clearCellLabelColor = false,
    double? cellLabelFontSize,
    HeatmapAnimationStyle? animation,
  }) {
    if (style != null && style != SeriesStyle.heatmap) {
      throw ArgumentError.value(
        style,
        'style',
        'HeatmapChartSeries style must remain heatmap',
      );
    }
    final nextPoints = points ?? this.points;
    for (var index = 0; index < nextPoints.length; index++) {
      if (nextPoints[index] is! HeatmapDataPoint) {
        throw ArgumentError.value(
          nextPoints[index].runtimeType,
          'points[$index]',
          'HeatmapChartSeries requires HeatmapDataPoint values',
        );
      }
    }
    return HeatmapChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: nextPoints.cast<HeatmapDataPoint>(),
      colorScale: colorScale ?? this.colorScale,
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      annotations: annotations ?? this.annotations,
      yAxisId: clearYAxisId ? null : (yAxisId ?? this.yAxisId),
      yAxisConfig: clearYAxisConfig ? null : (yAxisConfig ?? this.yAxisConfig),
      unit: clearUnit ? null : (unit ?? this.unit),
      cellWidth: cellWidth ?? this.cellWidth,
      cellHeight: cellHeight ?? this.cellHeight,
      gapFraction: gapFraction ?? this.gapFraction,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      showCellLabels: showCellLabels ?? this.showCellLabels,
      cellLabelColor: clearCellLabelColor
          ? null
          : (cellLabelColor ?? this.cellLabelColor),
      cellLabelFontSize: cellLabelFontSize ?? this.cellLabelFontSize,
      animation: animation ?? this.animation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HeatmapChartSeries) return false;
    return super == other &&
        other.colorScale == colorScale &&
        other.cellWidth == cellWidth &&
        other.cellHeight == cellHeight &&
        other.gapFraction == gapFraction &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.cornerRadius == cornerRadius &&
        other.showCellLabels == showCellLabels &&
        other.cellLabelColor == cellLabelColor &&
        other.cellLabelFontSize == cellLabelFontSize &&
        other.animation == animation;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    colorScale,
    cellWidth,
    cellHeight,
    gapFraction,
    borderColor,
    borderWidth,
    cornerRadius,
    showCellLabels,
    cellLabelColor,
    cellLabelFontSize,
    animation,
  );
}
