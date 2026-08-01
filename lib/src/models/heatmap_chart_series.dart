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

/// Presentation applied to finite cells outside a [HeatmapValueFilter].
enum HeatmapValueFilterMode {
  /// Keep excluded cells visible at a reduced opacity.
  dim,

  /// Remove excluded cells from painting and hit testing.
  hide,
}

/// An inclusive measured-value window for Heatmap presentation.
///
/// Filtering never mutates or removes source cells. Tables, artifacts, source
/// generation, and copied series continue to contain the complete matrix.
/// Missing cells are independent from this measured-value window and retain
/// their normal missing-cell presentation.
@ChartSurface()
final class HeatmapValueFilter {
  const HeatmapValueFilter({
    required this.minimumValue,
    required this.maximumValue,
    this.mode = HeatmapValueFilterMode.dim,
    this.excludedOpacity = 0.14,
  });

  /// Inclusive lower bound of the visible measured-value window.
  final double minimumValue;

  /// Inclusive upper bound of the visible measured-value window.
  final double maximumValue;

  /// Presentation used for finite cells outside the window.
  final HeatmapValueFilterMode mode;

  /// Opacity applied to excluded cells when [mode] is
  /// [HeatmapValueFilterMode.dim].
  final double excludedOpacity;

  /// Whether [cell] belongs to the inclusive measured-value window.
  ///
  /// Missing cells are not excluded by a measured-value filter.
  bool includes(HeatmapDataPoint cell) {
    final value = cell.value;
    return cell.isMissing ||
        value == null ||
        (value >= minimumValue && value <= maximumValue);
  }

  void validate() {
    if (!minimumValue.isFinite) {
      throw ArgumentError.value(
        minimumValue,
        'valueFilter.minimumValue',
        'must be finite',
      );
    }
    if (!maximumValue.isFinite) {
      throw ArgumentError.value(
        maximumValue,
        'valueFilter.maximumValue',
        'must be finite',
      );
    }
    if (minimumValue > maximumValue) {
      throw ArgumentError.value(
        minimumValue,
        'valueFilter.minimumValue',
        'must be less than or equal to maximumValue',
      );
    }
    if (!excludedOpacity.isFinite ||
        excludedOpacity < 0 ||
        excludedOpacity > 1) {
      throw ArgumentError.value(
        excludedOpacity,
        'valueFilter.excludedOpacity',
        'must be finite and between zero and one',
      );
    }
  }

  HeatmapValueFilter copyWith({
    double? minimumValue,
    double? maximumValue,
    HeatmapValueFilterMode? mode,
    double? excludedOpacity,
  }) => HeatmapValueFilter(
    minimumValue: minimumValue ?? this.minimumValue,
    maximumValue: maximumValue ?? this.maximumValue,
    mode: mode ?? this.mode,
    excludedOpacity: excludedOpacity ?? this.excludedOpacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapValueFilter &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          other.mode == mode &&
          other.excludedOpacity == excludedOpacity;

  @override
  int get hashCode =>
      Object.hash(minimumValue, maximumValue, mode, excludedOpacity);
}

/// Presentation for a real Heatmap cell whose measured value represents an
/// application-defined empty state.
///
/// This is deliberately independent from [HeatmapDataPoint.missing]. A
/// matching cell remains a finite, selectable data point and continues to
/// participate in tables, artifacts, tooltips, and the measured-value domain.
/// Missing cells still use [HeatmapColorScale.missingColor].
@ChartSurface()
final class HeatmapEmptyValueStyle {
  const HeatmapEmptyValueStyle({
    this.value = 0,
    this.fillColor = const Color(0xFFE5E7EB),
    this.borderColor,
    this.borderWidth,
    this.showLabel = false,
    this.showInLegend = true,
    this.legendLabel = 'No activity',
  });

  /// Finite measured value treated as the empty application state.
  final double value;

  /// Fill used instead of the measured colour-scale result.
  final Color fillColor;

  /// Optional outline colour. When absent, the series outline is inherited.
  final Color? borderColor;

  /// Optional outline width. When absent, the series width is inherited.
  final double? borderWidth;

  /// Whether matching cells show their numeric value.
  ///
  /// This is independent from [HeatmapChartSeries.showCellLabels].
  final bool showLabel;

  /// Whether [legendLabel] and [fillColor] appear beside the colour scale.
  final bool showInLegend;

  /// Human-readable wording for the empty-value legend swatch.
  final String legendLabel;

  bool matches(HeatmapDataPoint cell) => !cell.isMissing && cell.value == value;

  void validate() {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'emptyValueStyle.value',
        'must be finite',
      );
    }
    final width = borderWidth;
    if (width != null && (!width.isFinite || width < 0)) {
      throw ArgumentError.value(
        width,
        'emptyValueStyle.borderWidth',
        'must be finite and non-negative',
      );
    }
    if (legendLabel.trim().isEmpty) {
      throw ArgumentError.value(
        legendLabel,
        'emptyValueStyle.legendLabel',
        'must not be blank',
      );
    }
  }

  HeatmapEmptyValueStyle copyWith({
    double? value,
    Color? fillColor,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    bool clearBorderWidth = false,
    bool? showLabel,
    bool? showInLegend,
    String? legendLabel,
  }) => HeatmapEmptyValueStyle(
    value: value ?? this.value,
    fillColor: fillColor ?? this.fillColor,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: clearBorderWidth ? null : (borderWidth ?? this.borderWidth),
    showLabel: showLabel ?? this.showLabel,
    showInLegend: showInLegend ?? this.showInLegend,
    legendLabel: legendLabel ?? this.legendLabel,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapEmptyValueStyle &&
          other.value == value &&
          other.fillColor == fillColor &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.showLabel == showLabel &&
          other.showInLegend == showInLegend &&
          other.legendLabel == legendLabel;

  @override
  int get hashCode => Object.hash(
    value,
    fillColor,
    borderColor,
    borderWidth,
    showLabel,
    showInLegend,
    legendLabel,
  );
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
    super.showInLegend,
    super.showTrackingAxisLabel,
    super.showInTrackingTooltip,
    this.cellWidth = 1,
    this.cellHeight = 1,
    this.gapFraction = 0.06,
    this.borderColor = const Color(0x26FFFFFF),
    this.borderWidth = 0,
    this.cornerRadius = 0,
    this.showCellLabels = false,
    this.cellLabelColor,
    this.cellLabelFontSize = 11,
    this.emptyValueStyle,
    this.valueFilter,
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

  /// Optional presentation for a finite application-defined empty value.
  ///
  /// A null value keeps every finite cell on [colorScale]. This never changes
  /// the behaviour of [HeatmapDataPoint.missing].
  final HeatmapEmptyValueStyle? emptyValueStyle;

  /// Optional inclusive measured-value window used for presentation.
  ///
  /// The complete source matrix remains available through [cells], tables,
  /// artifacts, and generated source regardless of this filter.
  final HeatmapValueFilter? valueFilter;

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
    emptyValueStyle?.validate();
    valueFilter?.validate();
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
    bool? showInLegend,
    bool? showTrackingAxisLabel,
    bool? showInTrackingTooltip,
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
    HeatmapEmptyValueStyle? emptyValueStyle,
    bool clearEmptyValueStyle = false,
    HeatmapValueFilter? valueFilter,
    bool clearValueFilter = false,
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
      showInLegend: showInLegend ?? this.showInLegend,
      showTrackingAxisLabel:
          showTrackingAxisLabel ?? this.showTrackingAxisLabel,
      showInTrackingTooltip:
          showInTrackingTooltip ?? this.showInTrackingTooltip,
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
      emptyValueStyle: clearEmptyValueStyle
          ? null
          : (emptyValueStyle ?? this.emptyValueStyle),
      valueFilter: clearValueFilter ? null : (valueFilter ?? this.valueFilter),
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
        other.emptyValueStyle == emptyValueStyle &&
        other.valueFilter == valueFilter &&
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
    emptyValueStyle,
    valueFilter,
    animation,
  );
}
