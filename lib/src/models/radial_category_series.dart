import 'chart_data_point.dart';
import 'chart_series.dart';
import 'pie_chart_config.dart';

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

  /// Radius of the shared center opening relative to the maximum outer radius.
  double get innerRadiusFactor;

  /// Total configured angular span in degrees.
  double get sweepAngleDegrees;

  /// Whether every slice carries an active variable-radius value.
  bool get hasVariableSliceRadius => sliceRadiusConfig != null;

  /// Sum of all visible, positive slice contributions.
  double get total => points.fold<double>(0, (sum, point) => sum + point.y);

  /// Original point indices that produce visible geometry.
  List<int> get visiblePointIndices => List<int>.unmodifiable([
    for (final (index, point) in points.indexed)
      if (point.y > 0) index,
  ]);

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
