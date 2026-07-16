import 'dart:ui' show Color;

import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'pie_chart_config.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// A single-ring pie series whose points represent category contributions.
///
/// A chart may contain exactly one [PieChartSeries] and may not mix it with
/// Cartesian series. Each point requires a finite ordering [ChartDataPoint.x],
/// a non-negative finite [ChartDataPoint.y], and a non-empty category label.
/// Zero-valued points remain transportable but do not produce visible slices.
class PieChartSeries extends ChartSeries {
  /// Creates an explicitly ordered pie series and validates it in all modes.
  PieChartSeries({
    required super.id,
    super.name,
    required List<ChartDataPoint> points,
    super.color,
    super.metadata,
    super.unit,
    this.pieStyle = const PieChartStyle(),
    this.dataLabels = const PieDataLabelConfig(),
  }) : super(
         points: List<ChartDataPoint>.unmodifiable(points),
         style: SeriesStyle.pie,
         isXOrdered: true,
       ) {
    _validate();
  }

  /// Creates a pie series from insertion-ordered category/value pairs.
  ///
  /// The generated X values are stable zero-based ordinals. Use [sliceColors]
  /// to attach optional per-category color overrides through [PointStyle].
  factory PieChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> sliceColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PieChartStyle pieStyle = const PieChartStyle(),
    PieDataLabelConfig dataLabels = const PieDataLabelConfig(),
  }) {
    final points = <ChartDataPoint>[];
    for (final (index, entry) in values.entries.indexed) {
      points.add(
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: sliceColors[entry.key] == null
              ? null
              : PointStyle.color(sliceColors[entry.key]!),
        ),
      );
    }
    return PieChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      metadata: metadata,
      unit: unit,
      pieStyle: pieStyle,
      dataLabels: dataLabels,
    );
  }

  /// Geometry and border configuration shared by every slice.
  final PieChartStyle pieStyle;

  /// Data-label eligibility and placement configuration.
  final PieDataLabelConfig dataLabels;

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

  /// Returns a validated copy with selected fields replaced.
  @override
  PieChartSeries copyWith({
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
    PieChartStyle? pieStyle,
    PieDataLabelConfig? dataLabels,
  }) {
    if (style != null && style != SeriesStyle.pie) {
      throw ArgumentError.value(style, 'style', 'Pie series style is fixed');
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Pie slice order must remain stable',
      );
    }
    if (yAxisId != null || yAxisConfig != null || annotations != null) {
      throw ArgumentError(
        'Pie series do not support Cartesian axes or series annotations',
      );
    }
    return PieChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      unit: unit ?? this.unit,
      pieStyle: pieStyle ?? this.pieStyle,
      dataLabels: dataLabels ?? this.dataLabels,
    );
  }

  void _validate() {
    var runningTotal = 0.0;
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Pie slice ordinals must be finite',
        );
      }
      if (!point.y.isFinite || point.y < 0) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Pie slice contributions must be finite and non-negative',
        );
      }
      if (point.label == null || point.label!.trim().isEmpty) {
        throw ArgumentError.value(
          point.label,
          'points[$index].label',
          'Pie slices require a non-empty category label',
        );
      }
      runningTotal += point.y;
      if (!runningTotal.isFinite) {
        throw ArgumentError.value(
          runningTotal,
          'points',
          'Pie slice contributions must have a finite total',
        );
      }
    }

    _requireFinite(pieStyle.startAngleDegrees, 'pieStyle.startAngleDegrees');
    _requireRange(
      pieStyle.radiusFactor,
      'pieStyle.radiusFactor',
      min: 0,
      max: 1,
      minInclusive: false,
    );
    _requireNonNegative(pieStyle.sliceGap, 'pieStyle.sliceGap');
    _requireNonNegative(pieStyle.borderWidth, 'pieStyle.borderWidth');
    _requireNonNegative(
      pieStyle.selectionExplodeOffset,
      'pieStyle.selectionExplodeOffset',
    );
    if (pieStyle.opacity != null) {
      _requireRange(pieStyle.opacity!, 'pieStyle.opacity', min: 0, max: 1);
    }
    if (pieStyle.cornerRadius != null) {
      _requireNonNegative(pieStyle.cornerRadius!, 'pieStyle.cornerRadius');
    }
    if (pieStyle.shadow != null) {
      _validateElevation(pieStyle.shadow!, 'pieStyle.shadow');
    }
    if (pieStyle.selectedElevation != null) {
      _validateElevation(
        pieStyle.selectedElevation!,
        'pieStyle.selectedElevation',
      );
    }
    _requireRange(
      dataLabels.minimumShare,
      'dataLabels.minimumShare',
      min: 0,
      max: 1,
    );
    _requireRange(
      dataLabels.minimumSweepDegrees,
      'dataLabels.minimumSweepDegrees',
      min: 0,
      max: 360,
    );
    _requireNonNegative(dataLabels.padding, 'dataLabels.padding');
    _requireNonNegative(
      dataLabels.connectorLength,
      'dataLabels.connectorLength',
    );
    _requireNonNegative(dataLabels.connectorWidth, 'dataLabels.connectorWidth');
  }

  static void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Value must be finite');
    }
  }

  static void _requireNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        name,
        'Value must be finite and non-negative',
      );
    }
  }

  static void _requireRange(
    double value,
    String name, {
    required double min,
    required double max,
    bool minInclusive = true,
  }) {
    final belowMin = minInclusive ? value < min : value <= min;
    if (!value.isFinite || belowMin || value > max) {
      final left = minInclusive ? '[' : '(';
      throw ArgumentError.value(
        value,
        name,
        'Value must be finite and in $left$min, $max]',
      );
    }
  }

  static void _validateElevation(PieElevationStyle value, String name) {
    _requireNonNegative(value.blurRadius, '$name.blurRadius');
    _requireNonNegative(value.spreadRadius, '$name.spreadRadius');
    _requireRange(value.opacity, '$name.opacity', min: 0, max: 1);
    _requireFinite(value.offset.dx, '$name.offset.dx');
    _requireFinite(value.offset.dy, '$name.offset.dy');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartSeries &&
          super == other &&
          pieStyle == other.pieStyle &&
          dataLabels == other.dataLabels;

  @override
  int get hashCode => Object.hash(super.hashCode, pieStyle, dataLabels);

  @override
  String toString() =>
      'PieChartSeries(id: $id, slices: ${points.length}, total: $total)';
}
