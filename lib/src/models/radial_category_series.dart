import 'dart:ui' show Color;

import 'chart_data_point.dart';
import 'chart_series.dart';
import 'pie_chart_config.dart';
import 'segment_style.dart';

/// Policy used to combine the second radius metric of grouped radial slices.
enum RadialSliceRadiusAggregation {
  /// Add every grouped radius value.
  sum,

  /// Use the arithmetic mean of grouped radius values.
  mean,

  /// Weight each radius value by its primary contribution value.
  weightedMean,

  /// Use the smallest grouped radius value.
  minimum,

  /// Use the largest grouped radius value.
  maximum,
}

/// Deterministic small-slice grouping for Pie and Donut category series.
///
/// Positive source points whose contribution is smaller than [minimumShare]
/// are projected into one visible slice when at least [minimumSourceCount]
/// points qualify. The source points remain unchanged for artifacts, tables,
/// copy/export, callbacks, and controller point references.
class RadialSliceGroupingConfig {
  /// Creates a grouping policy.
  const RadialSliceGroupingConfig({
    this.minimumShare = 0.05,
    this.minimumSourceCount = 2,
    this.label = 'Other',
    this.color,
    this.radiusAggregation,
  });

  /// Exclusive fractional threshold below which a positive point is grouped.
  final double minimumShare;

  /// Minimum number of qualifying source points required to create a group.
  final int minimumSourceCount;

  /// Category label used by the projected aggregate slice.
  final String label;

  /// Optional fixed color for the aggregate slice.
  final Color? color;

  /// Explicit policy for a grouped variable-radius second metric.
  ///
  /// This is required when grouping is combined with
  /// `RadialSliceRadiusConfig`; the package never guesses how two different
  /// measures should aggregate.
  final RadialSliceRadiusAggregation? radiusAggregation;

  /// Returns a copy with selected fields replaced.
  RadialSliceGroupingConfig copyWith({
    double? minimumShare,
    int? minimumSourceCount,
    String? label,
    Color? color,
    bool clearColor = false,
    RadialSliceRadiusAggregation? radiusAggregation,
    bool clearRadiusAggregation = false,
  }) => RadialSliceGroupingConfig(
    minimumShare: minimumShare ?? this.minimumShare,
    minimumSourceCount: minimumSourceCount ?? this.minimumSourceCount,
    label: label ?? this.label,
    color: clearColor ? null : (color ?? this.color),
    radiusAggregation: clearRadiusAggregation
        ? null
        : (radiusAggregation ?? this.radiusAggregation),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialSliceGroupingConfig &&
          other.minimumShare == minimumShare &&
          other.minimumSourceCount == minimumSourceCount &&
          other.label == label &&
          other.color == color &&
          other.radiusAggregation == radiusAggregation;

  @override
  int get hashCode => Object.hash(
    minimumShare,
    minimumSourceCount,
    label,
    color,
    radiusAggregation,
  );
}

/// One visible radial category and the original source points it represents.
class RadialCategorySlice {
  /// Creates a projected radial category.
  RadialCategorySlice({
    required this.point,
    required List<int> sourcePointIndices,
  }) : assert(sourcePointIndices.isNotEmpty),
       sourcePointIndices = List<int>.unmodifiable(sourcePointIndices);

  /// Point rendered by labels, tooltips, legends, and public tap callbacks.
  ///
  /// Ungrouped slices retain the original point. A grouped slice receives a
  /// synthetic point containing the aggregate value and configured label.
  final ChartDataPoint point;

  /// Stable original point indices represented by this visible slice.
  final List<int> sourcePointIndices;

  /// Primary source index used by legacy single-index internal paths.
  int get pointIndex => sourcePointIndices.first;

  /// Whether this visible category aggregates multiple source points.
  bool get isGrouped => sourcePointIndices.length > 1;

  /// Whether [sourcePointIndex] contributes to this visible category.
  bool containsSourcePoint(int sourcePointIndex) =>
      sourcePointIndices.contains(sourcePointIndex);
}

/// Shared validated source contract for Pie and Donut category series.
///
/// Concrete radial chart types remain distinct public models. This base owns
/// only the source-point identity, common appearance contract, optional second
/// radius metric, and validation that must remain identical across them.
abstract class RadialCategorySeries extends ChartSeries {
  /// Creates the shared immutable radial category state.
  RadialCategorySeries({
    required super.id,
    super.name,
    required List<ChartDataPoint> points,
    super.color,
    super.metadata,
    super.unit,
    required SeriesStyle style,
    required this.radialStyle,
    required this.dataLabels,
    required this.sliceRadiusConfig,
    required this.sliceGroupingConfig,
  }) : super(
         points: List<ChartDataPoint>.unmodifiable(points),
         style: style,
         isXOrdered: true,
       );

  /// Shared slice geometry and appearance consumed by the radial renderer.
  final RadialChartStyle radialStyle;

  /// Data-label eligibility and placement configuration.
  final PieDataLabelConfig dataLabels;

  /// Optional second-metric encoding used for variable slice radii.
  final RadialSliceRadiusConfig? sliceRadiusConfig;

  /// Optional deterministic projection of small categories into one slice.
  final RadialSliceGroupingConfig? sliceGroupingConfig;

  /// Radius of the shared center opening relative to the maximum outer radius.
  double get innerRadiusFactor;

  /// Total configured angular span in degrees.
  double get sweepAngleDegrees;

  /// Whether every slice carries an active variable-radius value.
  bool get hasVariableSliceRadius => sliceRadiusConfig != null;

  /// Sum of all visible, positive slice contributions.
  double get total => points.fold<double>(0, (sum, point) => sum + point.y);

  /// Visible radial categories after the configured grouping projection.
  late final List<RadialCategorySlice> visibleSlices = _buildVisibleSlices();

  List<RadialCategorySlice> _buildVisibleSlices() {
    final positive = <RadialCategorySlice>[
      for (final (index, point) in points.indexed)
        if (point.y > 0)
          RadialCategorySlice(point: point, sourcePointIndices: [index]),
    ];
    final grouping = sliceGroupingConfig;
    if (grouping == null || total <= 0) {
      return List<RadialCategorySlice>.unmodifiable(positive);
    }

    final grouped = <RadialCategorySlice>[];
    final retained = <RadialCategorySlice>[];
    for (final slice in positive) {
      if (slice.point.y / total < grouping.minimumShare) {
        grouped.add(slice);
      } else {
        retained.add(slice);
      }
    }
    if (grouped.length < grouping.minimumSourceCount) {
      return List<RadialCategorySlice>.unmodifiable(positive);
    }

    final groupedIndices = <int>[
      for (final slice in grouped) ...slice.sourcePointIndices,
    ];
    final groupedValue = grouped.fold<double>(
      0,
      (sum, slice) => sum + slice.point.y,
    );
    final groupedRadius = _aggregateGroupedRadius(grouped, grouping);
    final groupPoint = ChartDataPoint(
      x: grouped.first.point.x,
      y: groupedValue,
      label: grouping.label.trim(),
      pointStyle: grouping.color == null && groupedRadius == null
          ? null
          : PointStyle(color: grouping.color, size: groupedRadius),
    );
    return List<RadialCategorySlice>.unmodifiable([
      ...retained,
      RadialCategorySlice(
        point: groupPoint,
        sourcePointIndices: groupedIndices,
      ),
    ]);
  }

  double? _aggregateGroupedRadius(
    List<RadialCategorySlice> grouped,
    RadialSliceGroupingConfig grouping,
  ) {
    final policy = grouping.radiusAggregation;
    if (sliceRadiusConfig == null || policy == null) return null;
    final values = [for (final slice in grouped) slice.point.pointStyle!.size!];
    return switch (policy) {
      RadialSliceRadiusAggregation.sum => values.fold<double>(
        0,
        (a, b) => a + b,
      ),
      RadialSliceRadiusAggregation.mean =>
        values.fold<double>(0, (a, b) => a + b) / values.length,
      RadialSliceRadiusAggregation.weightedMean =>
        grouped.fold<double>(
              0,
              (sum, slice) =>
                  sum + slice.point.pointStyle!.size! * slice.point.y,
            ) /
            grouped.fold<double>(0, (sum, slice) => sum + slice.point.y),
      RadialSliceRadiusAggregation.minimum => values.reduce(
        (a, b) => a < b ? a : b,
      ),
      RadialSliceRadiusAggregation.maximum => values.reduce(
        (a, b) => a > b ? a : b,
      ),
    };
  }

  /// Primary source indices that produce visible projected geometry.
  List<int> get visiblePointIndices => List<int>.unmodifiable([
    for (final slice in visibleSlices) slice.pointIndex,
  ]);

  /// Finds the visible slice containing [sourcePointIndex].
  RadialCategorySlice? visibleSliceForSourcePointIndex(int sourcePointIndex) {
    for (final slice in visibleSlices) {
      if (slice.containsSourcePoint(sourcePointIndex)) return slice;
    }
    return null;
  }

  /// Whether this series contains data but every contribution is zero.
  bool get isAllZero =>
      points.isNotEmpty && points.every((point) => point.y == 0);

  /// Removes the optional second-metric radius from one source point.
  static ChartDataPoint withoutSliceRadius(ChartDataPoint point) {
    final style = point.pointStyle;
    if (style?.size == null) return point;
    final withoutSize = style!.copyWith(clearSize: true);
    return withoutSize.hasOverrides
        ? point.copyWith(pointStyle: withoutSize)
        : point.copyWith(clearPointStyle: true);
  }

  /// Validates the common radial source and visual contract in every build
  /// mode. Concrete types call this after their own fields are initialized.
  void validateRadialConfiguration({required String chartName}) {
    var runningTotal = 0.0;
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          '$chartName slice ordinals must be finite',
        );
      }
      if (!point.y.isFinite || point.y < 0) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          '$chartName slice contributions must be finite and non-negative',
        );
      }
      if (point.label == null || point.label!.trim().isEmpty) {
        throw ArgumentError.value(
          point.label,
          'points[$index].label',
          '$chartName slices require a non-empty category label',
        );
      }
      runningTotal += point.y;
      if (!runningTotal.isFinite) {
        throw ArgumentError.value(
          runningTotal,
          'points',
          '$chartName slice contributions must have a finite total',
        );
      }
    }

    requireFinite(
      radialStyle.startAngleDegrees,
      'radialStyle.startAngleDegrees',
    );
    requireRange(
      radialStyle.radiusFactor,
      'radialStyle.radiusFactor',
      min: 0,
      max: 1,
      minInclusive: false,
    );
    requireNonNegative(radialStyle.sliceGap, 'radialStyle.sliceGap');
    requireNonNegative(radialStyle.borderWidth, 'radialStyle.borderWidth');
    if (radialStyle.borderHueShiftDegrees != null) {
      requireFinite(
        radialStyle.borderHueShiftDegrees!,
        'radialStyle.borderHueShiftDegrees',
      );
    }
    if (radialStyle.borderSaturationShift != null) {
      requireRange(
        radialStyle.borderSaturationShift!,
        'radialStyle.borderSaturationShift',
        min: -1,
        max: 1,
      );
    }
    if (radialStyle.borderLightnessShift != null) {
      requireRange(
        radialStyle.borderLightnessShift!,
        'radialStyle.borderLightnessShift',
        min: -1,
        max: 1,
      );
    }
    if (radialStyle.gradient case final gradient?) {
      requireRange(
        gradient.startLightnessShift,
        'radialStyle.gradient.startLightnessShift',
        min: -1,
        max: 1,
      );
      requireRange(
        gradient.endLightnessShift,
        'radialStyle.gradient.endLightnessShift',
        min: -1,
        max: 1,
      );
      requireFinite(gradient.angleDegrees, 'radialStyle.gradient.angleDegrees');
    }
    requireNonNegative(
      radialStyle.selectionExplodeOffset,
      'radialStyle.selectionExplodeOffset',
    );
    if (radialStyle.opacity != null) {
      requireRange(radialStyle.opacity!, 'radialStyle.opacity', min: 0, max: 1);
    }
    if (radialStyle.cornerRadius != null) {
      requireNonNegative(radialStyle.cornerRadius!, 'radialStyle.cornerRadius');
    }
    if (radialStyle.shadow != null) {
      _validateElevation(radialStyle.shadow!, 'radialStyle.shadow');
    }
    if (radialStyle.selectedElevation != null) {
      _validateElevation(
        radialStyle.selectedElevation!,
        'radialStyle.selectedElevation',
      );
    }
    requireRange(
      dataLabels.minimumShare,
      'dataLabels.minimumShare',
      min: 0,
      max: 1,
    );
    requireRange(
      dataLabels.minimumSweepDegrees,
      'dataLabels.minimumSweepDegrees',
      min: 0,
      max: 360,
    );
    requireNonNegative(dataLabels.padding, 'dataLabels.padding');
    requireNonNegative(dataLabels.outsideOffset, 'dataLabels.outsideOffset');
    requireNonNegative(
      dataLabels.connectorLength,
      'dataLabels.connectorLength',
    );
    requireNonNegative(dataLabels.connectorWidth, 'dataLabels.connectorWidth');

    final radiusSizes = [for (final point in points) point.pointStyle?.size];
    final hasAnyRadiusValue = radiusSizes.any((value) => value != null);
    if (hasAnyRadiusValue != (sliceRadiusConfig != null)) {
      throw ArgumentError(
        'Variable $chartName radii require both sliceRadiusConfig and one '
        'PointStyle.size value for every point',
      );
    }
    if (sliceRadiusConfig case final config?) {
      requireRange(
        config.minimumFactor,
        'sliceRadiusConfig.minimumFactor',
        min: 0,
        max: 1,
      );
      if (config.label.trim().isEmpty) {
        throw ArgumentError.value(
          config.label,
          'sliceRadiusConfig.label',
          'Radius metric label must not be empty',
        );
      }
      for (final (index, value) in radiusSizes.indexed) {
        if (value == null || !value.isFinite || value < 0) {
          throw ArgumentError.value(
            value,
            'points[$index].pointStyle.size',
            'Variable $chartName radius values must be finite and non-negative',
          );
        }
      }
    }
    if (sliceGroupingConfig case final grouping?) {
      requireRange(
        grouping.minimumShare,
        'sliceGroupingConfig.minimumShare',
        min: 0,
        max: 1,
        minInclusive: false,
        maxInclusive: false,
      );
      if (grouping.minimumSourceCount < 2) {
        throw ArgumentError.value(
          grouping.minimumSourceCount,
          'sliceGroupingConfig.minimumSourceCount',
          'Grouped radial slices require at least two source points',
        );
      }
      if (grouping.label.trim().isEmpty) {
        throw ArgumentError.value(
          grouping.label,
          'sliceGroupingConfig.label',
          'Grouped radial slices require a visible label',
        );
      }
      if (sliceRadiusConfig != null && grouping.radiusAggregation == null) {
        throw ArgumentError(
          'Radial slice grouping cannot be combined with variable slice '
          'radii without an explicit second-metric aggregation policy',
        );
      }
      if (sliceRadiusConfig == null && grouping.radiusAggregation != null) {
        throw ArgumentError(
          'A radial radius aggregation policy requires variable slice radii',
        );
      }
    }
  }

  /// Requires a finite value.
  static void requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Value must be finite');
    }
  }

  /// Requires a finite non-negative value.
  static void requireNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        name,
        'Value must be finite and non-negative',
      );
    }
  }

  /// Requires a finite value within the configured range.
  static void requireRange(
    double value,
    String name, {
    required double min,
    required double max,
    bool minInclusive = true,
    bool maxInclusive = true,
  }) {
    final belowMin = minInclusive ? value < min : value <= min;
    final aboveMax = maxInclusive ? value > max : value >= max;
    if (!value.isFinite || belowMin || aboveMax) {
      final left = minInclusive ? '[' : '(';
      final right = maxInclusive ? ']' : ')';
      throw ArgumentError.value(
        value,
        name,
        'Value must be finite and in $left$min, $max$right',
      );
    }
  }

  static void _validateElevation(PieElevationStyle value, String name) {
    requireNonNegative(value.blurRadius, '$name.blurRadius');
    requireNonNegative(value.spreadRadius, '$name.spreadRadius');
    requireRange(value.opacity, '$name.opacity', min: 0, max: 1);
    requireFinite(value.offset.dx, '$name.offset.dx');
    requireFinite(value.offset.dy, '$name.offset.dy');
  }
}
