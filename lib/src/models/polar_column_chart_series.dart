import 'dart:ui' show Color;

import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'y_axis_config.dart';

/// Named interpretation applied to one Polar Column series.
enum PolarColumnPreset {
  /// Linear-radius Polar Column unless the radial axis overrides it.
  standard,

  /// Equal-angle Rose/Nightingale presentation with area-correct radial
  /// scaling unless the radial axis explicitly overrides it.
  rose,
}

/// Visual treatment for an absolute lower/upper Polar Column interval.
enum PolarColumnIntervalDisplay {
  /// A radial stem with tangential caps at the lower and upper endpoints.
  whisker,

  /// A compact annular band spanning the lower and upper endpoints.
  band,
}

/// Absolute lower and upper values associated with one polar category.
///
/// Intervals are analytical references on the shared radial numeric scale;
/// they are not deltas from the column value.
class PolarColumnInterval {
  const PolarColumnInterval({required this.lower, required this.upper});

  final double lower;
  final double upper;

  void validate({String argumentName = 'interval'}) {
    if (!lower.isFinite || !upper.isFinite) {
      throw ArgumentError.value(
        this,
        argumentName,
        'Interval endpoints must be finite',
      );
    }
    if (lower > upper) {
      throw ArgumentError.value(
        this,
        argumentName,
        'Interval lower value must not exceed its upper value',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnInterval &&
          lower == other.lower &&
          upper == other.upper;

  @override
  int get hashCode => Object.hash(lower, upper);
}

/// Appearance of per-category Polar Column uncertainty/range intervals.
class PolarColumnIntervalStyle {
  const PolarColumnIntervalStyle({
    this.display = PolarColumnIntervalDisplay.whisker,
    this.color,
    this.width = 1.5,
    this.capLengthFactor = 0.62,
    this.bandLengthFactor = 0.58,
    this.opacity = 0.92,
  });

  final PolarColumnIntervalDisplay display;

  /// Explicit interval color. Null uses a high-contrast theme color.
  final Color? color;

  /// Stroke width for whiskers and the outline of range bands.
  final double width;

  /// Fraction of the resolved category/group band occupied by whisker caps.
  final double capLengthFactor;

  /// Fraction of the resolved category/group band occupied by a range band.
  final double bandLengthFactor;

  /// Interval opacity in the inclusive range `[0, 1]`.
  final double opacity;

  void validate() {
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        width,
        'intervalStyle.width',
        'Value must be finite and positive',
      );
    }
    if (!capLengthFactor.isFinite ||
        capLengthFactor <= 0 ||
        capLengthFactor > 1) {
      throw ArgumentError.value(
        capLengthFactor,
        'intervalStyle.capLengthFactor',
        'Value must be finite and in (0, 1]',
      );
    }
    if (!bandLengthFactor.isFinite ||
        bandLengthFactor <= 0 ||
        bandLengthFactor > 1) {
      throw ArgumentError.value(
        bandLengthFactor,
        'intervalStyle.bandLengthFactor',
        'Value must be finite and in (0, 1]',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'intervalStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
  }

  PolarColumnIntervalStyle copyWith({
    PolarColumnIntervalDisplay? display,
    Color? color,
    bool clearColor = false,
    double? width,
    double? capLengthFactor,
    double? bandLengthFactor,
    double? opacity,
  }) => PolarColumnIntervalStyle(
    display: display ?? this.display,
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    capLengthFactor: capLengthFactor ?? this.capLengthFactor,
    bandLengthFactor: bandLengthFactor ?? this.bandLengthFactor,
    opacity: opacity ?? this.opacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnIntervalStyle &&
          display == other.display &&
          color == other.color &&
          width == other.width &&
          capLengthFactor == other.capLengthFactor &&
          bandLengthFactor == other.bandLengthFactor &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(
    display,
    color,
    width,
    capLengthFactor,
    bandLengthFactor,
    opacity,
  );
}

/// Appearance of a per-category target marker on a Polar Column series.
///
/// Targets are absolute values on the shared radial numeric axis. They do not
/// participate in grouped or stacked geometry and remain fixed when a column
/// is lifted for selection, so the represented value can be compared against
/// its benchmark.
class PolarColumnTargetMarkerStyle {
  const PolarColumnTargetMarkerStyle({
    this.color,
    this.width = 2.5,
    this.lengthFactor = 0.72,
    this.opacity = 1,
  });

  /// Explicit marker color. Null uses the chart focus color.
  final Color? color;

  /// Tangential marker stroke width in logical pixels.
  final double width;

  /// Fraction of the resolved category or grouped-series band occupied by the
  /// marker.
  final double lengthFactor;

  /// Marker opacity in the inclusive range `[0, 1]`.
  final double opacity;

  void validate() {
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        width,
        'targetMarkerStyle.width',
        'Value must be finite and positive',
      );
    }
    if (!lengthFactor.isFinite || lengthFactor <= 0 || lengthFactor > 1) {
      throw ArgumentError.value(
        lengthFactor,
        'targetMarkerStyle.lengthFactor',
        'Value must be finite and in (0, 1]',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'targetMarkerStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
  }

  PolarColumnTargetMarkerStyle copyWith({
    Color? color,
    bool clearColor = false,
    double? width,
    double? lengthFactor,
    double? opacity,
  }) => PolarColumnTargetMarkerStyle(
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    lengthFactor: lengthFactor ?? this.lengthFactor,
    opacity: opacity ?? this.opacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnTargetMarkerStyle &&
          color == other.color &&
          width == other.width &&
          lengthFactor == other.lengthFactor &&
          opacity == other.opacity;

  @override
  int get hashCode => Object.hash(color, width, lengthFactor, opacity);
}

/// Mark appearance for one Polar Column series.
class PolarColumnStyle {
  const PolarColumnStyle({
    this.cornerRadius = 4,
    this.opacity = 1,
    this.borderColor,
    this.borderWidth = 1,
    this.showDataLabels = true,
    this.maximumVisibleDataLabels = 24,
  });

  final double cornerRadius;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final bool showDataLabels;

  /// Maximum number of direct value labels painted for this series.
  ///
  /// Spatial fit may reduce the visible count further. This never removes
  /// source values from hit testing, semantics, artifacts, or data tables.
  final int maximumVisibleDataLabels;

  void validate() {
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'polarStyle.cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'polarStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!borderWidth.isFinite || borderWidth < 0) {
      throw ArgumentError.value(
        borderWidth,
        'polarStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
    if (maximumVisibleDataLabels < 1) {
      throw ArgumentError.value(
        maximumVisibleDataLabels,
        'polarStyle.maximumVisibleDataLabels',
        'Value must be positive',
      );
    }
  }

  PolarColumnStyle copyWith({
    double? cornerRadius,
    double? opacity,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    bool? showDataLabels,
    int? maximumVisibleDataLabels,
  }) => PolarColumnStyle(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    opacity: opacity ?? this.opacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    showDataLabels: showDataLabels ?? this.showDataLabels,
    maximumVisibleDataLabels:
        maximumVisibleDataLabels ?? this.maximumVisibleDataLabels,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnStyle &&
          cornerRadius == other.cornerRadius &&
          opacity == other.opacity &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          showDataLabels == other.showDataLabels &&
          maximumVisibleDataLabels == other.maximumVisibleDataLabels;

  @override
  int get hashCode => Object.hash(
    cornerRadius,
    opacity,
    borderColor,
    borderWidth,
    showDataLabels,
    maximumVisibleDataLabels,
  );
}

/// One signed, category-based series rendered against polar axes.
///
/// Angle communicates category position. Radius communicates [ChartDataPoint.y]
/// against an explicit numeric axis; values are not converted into Pie shares.
/// Multiple compatible series may be layered in declaration order, grouped
/// into stable angular sub-bands, or stacked independently on the positive and
/// negative sides of zero. They share category labels/order, preset, unit, and
/// one radial scale.
class PolarColumnChartSeries extends ChartSeries {
  PolarColumnChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    this.preset = PolarColumnPreset.standard,
    this.polarStyle = const PolarColumnStyle(),
    this.selectionStyle = const RadialSelectionStyle(),
    this.targetValues = const [],
    this.targetMarkerStyle = const PolarColumnTargetMarkerStyle(),
    this.intervalLowerValues = const [],
    this.intervalUpperValues = const [],
    this.intervalStyle = const PolarColumnIntervalStyle(),
  }) : super(style: SeriesStyle.polarColumn, isXOrdered: true) {
    _validate();
  }

  /// Creates stable ordinal points from insertion-ordered categories.
  factory PolarColumnChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> columnColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PolarColumnStyle polarStyle = const PolarColumnStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
    Map<String, num?> targets = const {},
    PolarColumnTargetMarkerStyle targetMarkerStyle =
        const PolarColumnTargetMarkerStyle(),
    Map<String, PolarColumnInterval> intervals = const {},
    PolarColumnIntervalStyle intervalStyle = const PolarColumnIntervalStyle(),
  }) => PolarColumnChartSeries._fromMap(
    id: id,
    name: name,
    values: values,
    columnColors: columnColors,
    color: color,
    metadata: metadata,
    unit: unit,
    preset: PolarColumnPreset.standard,
    polarStyle: polarStyle,
    selectionStyle: selectionStyle,
    targets: targets,
    targetMarkerStyle: targetMarkerStyle,
    intervals: intervals,
    intervalStyle: intervalStyle,
  );

  /// Creates an equal-angle Rose/Nightingale series.
  factory PolarColumnChartSeries.rose({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> columnColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    PolarColumnStyle polarStyle = const PolarColumnStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
    Map<String, num?> targets = const {},
    PolarColumnTargetMarkerStyle targetMarkerStyle =
        const PolarColumnTargetMarkerStyle(),
    Map<String, PolarColumnInterval> intervals = const {},
    PolarColumnIntervalStyle intervalStyle = const PolarColumnIntervalStyle(),
  }) => PolarColumnChartSeries._fromMap(
    id: id,
    name: name,
    values: values,
    columnColors: columnColors,
    color: color,
    metadata: metadata,
    unit: unit,
    preset: PolarColumnPreset.rose,
    polarStyle: polarStyle,
    selectionStyle: selectionStyle,
    targets: targets,
    targetMarkerStyle: targetMarkerStyle,
    intervals: intervals,
    intervalStyle: intervalStyle,
  );

  factory PolarColumnChartSeries._fromMap({
    required String id,
    required String? name,
    required Map<String, num> values,
    required Map<String, Color> columnColors,
    required Color? color,
    required Map<String, dynamic>? metadata,
    required String? unit,
    required PolarColumnPreset preset,
    required PolarColumnStyle polarStyle,
    required RadialSelectionStyle selectionStyle,
    required Map<String, num?> targets,
    required PolarColumnTargetMarkerStyle targetMarkerStyle,
    required Map<String, PolarColumnInterval> intervals,
    required PolarColumnIntervalStyle intervalStyle,
  }) {
    final unknownTargetCategories = targets.keys
        .where((category) => !values.containsKey(category))
        .toList(growable: false);
    if (unknownTargetCategories.isNotEmpty) {
      throw ArgumentError.value(
        unknownTargetCategories,
        'targets',
        'Target categories must exist in values',
      );
    }
    final unknownIntervalCategories = intervals.keys
        .where((category) => !values.containsKey(category))
        .toList(growable: false);
    if (unknownIntervalCategories.isNotEmpty) {
      throw ArgumentError.value(
        unknownIntervalCategories,
        'intervals',
        'Interval categories must exist in values',
      );
    }
    final points = <ChartDataPoint>[];
    for (final (index, entry) in values.entries.indexed) {
      final pointColor = columnColors[entry.key];
      points.add(
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: pointColor == null ? null : PointStyle.color(pointColor),
        ),
      );
    }
    return PolarColumnChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      metadata: metadata,
      unit: unit,
      preset: preset,
      polarStyle: polarStyle,
      selectionStyle: selectionStyle,
      targetValues: targets.isEmpty
          ? const <double?>[]
          : [for (final category in values.keys) targets[category]?.toDouble()],
      targetMarkerStyle: targetMarkerStyle,
      intervalLowerValues: intervals.isEmpty
          ? const <double?>[]
          : [for (final category in values.keys) intervals[category]?.lower],
      intervalUpperValues: intervals.isEmpty
          ? const <double?>[]
          : [for (final category in values.keys) intervals[category]?.upper],
      intervalStyle: intervalStyle,
    );
  }

  final PolarColumnPreset preset;
  final PolarColumnStyle polarStyle;
  final RadialSelectionStyle selectionStyle;

  /// Optional absolute target for every category in stable point order.
  ///
  /// Supply either an empty list or one nullable entry per point. Null keeps a
  /// category without a marker while preserving its point identity.
  final List<double?> targetValues;

  /// Shared appearance for this series' target markers.
  final PolarColumnTargetMarkerStyle targetMarkerStyle;

  /// Optional absolute lower interval endpoint in stable point order.
  final List<double?> intervalLowerValues;

  /// Optional absolute upper interval endpoint in stable point order.
  final List<double?> intervalUpperValues;

  /// Shared appearance for this series' intervals.
  final PolarColumnIntervalStyle intervalStyle;

  bool get hasIntervals => intervalLowerValues.any((value) => value != null);

  PolarColumnInterval? intervalFor(int pointIndex) {
    if (pointIndex < 0 ||
        pointIndex >= intervalLowerValues.length ||
        pointIndex >= intervalUpperValues.length) {
      return null;
    }
    final lower = intervalLowerValues[pointIndex];
    final upper = intervalUpperValues[pointIndex];
    return lower == null || upper == null
        ? null
        : PolarColumnInterval(lower: lower, upper: upper);
  }

  double? targetValueFor(int pointIndex) =>
      pointIndex < targetValues.length ? targetValues[pointIndex] : null;

  List<String> get categories =>
      List<String>.unmodifiable(points.map((point) => point.label!));

  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Series ID cannot be blank');
    }
    if (points.isEmpty) {
      throw ArgumentError.value(
        points,
        'points',
        'Polar Column requires at least one category',
      );
    }
    final categories = <String>{};
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite || point.x != index.toDouble()) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Polar Column X values must be stable zero-based ordinals',
        );
      }
      if (!point.y.isFinite) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Polar Column values must be finite',
        );
      }
      final category = point.label?.trim();
      if (category == null || category.isEmpty || !categories.add(category)) {
        throw ArgumentError.value(
          point.label,
          'points[$index].label',
          'Categories must be visible and unique',
        );
      }
    }
    polarStyle.validate();
    if (targetValues.isNotEmpty && targetValues.length != points.length) {
      throw ArgumentError.value(
        targetValues.length,
        'targetValues',
        'Target value count must match point count (${points.length})',
      );
    }
    for (final (index, target) in targetValues.indexed) {
      if (target != null && !target.isFinite) {
        throw ArgumentError.value(
          target,
          'targetValues[$index]',
          'Target values must be null or finite',
        );
      }
    }
    targetMarkerStyle.validate();
    if (intervalLowerValues.isEmpty != intervalUpperValues.isEmpty) {
      throw ArgumentError(
        'Polar Column interval lower and upper values must be supplied together',
      );
    }
    if (intervalLowerValues.isNotEmpty &&
        intervalLowerValues.length != points.length) {
      throw ArgumentError.value(
        intervalLowerValues.length,
        'intervalLowerValues',
        'Interval count must match point count (${points.length})',
      );
    }
    if (intervalUpperValues.isNotEmpty &&
        intervalUpperValues.length != points.length) {
      throw ArgumentError.value(
        intervalUpperValues.length,
        'intervalUpperValues',
        'Interval count must match point count (${points.length})',
      );
    }
    for (var index = 0; index < intervalLowerValues.length; index++) {
      final lower = intervalLowerValues[index];
      final upper = intervalUpperValues[index];
      if ((lower == null) != (upper == null)) {
        throw ArgumentError.value(
          '$lower / $upper',
          'intervalValues[$index]',
          'Both interval endpoints or neither must be supplied',
        );
      }
      if (lower != null && upper != null) {
        PolarColumnInterval(
          lower: lower,
          upper: upper,
        ).validate(argumentName: 'intervalValues[$index]');
      }
    }
    intervalStyle.validate();
  }

  @override
  PolarColumnChartSeries copyWith({
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
    PolarColumnPreset? preset,
    PolarColumnStyle? polarStyle,
    RadialSelectionStyle? selectionStyle,
    List<double?>? targetValues,
    bool clearTargetValues = false,
    PolarColumnTargetMarkerStyle? targetMarkerStyle,
    List<double?>? intervalLowerValues,
    List<double?>? intervalUpperValues,
    bool clearIntervalValues = false,
    PolarColumnIntervalStyle? intervalStyle,
  }) {
    if (style != null && style != SeriesStyle.polarColumn) {
      throw ArgumentError.value(
        style,
        'style',
        'Polar Column series style is fixed',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Polar category order must remain stable',
      );
    }
    if (annotations != null || yAxisId != null || yAxisConfig != null) {
      throw ArgumentError(
        'Polar Column uses its PolarChartConfig axes and does not support '
        'Cartesian series annotations',
      );
    }
    return PolarColumnChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      unit: unit ?? this.unit,
      preset: preset ?? this.preset,
      polarStyle: polarStyle ?? this.polarStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      targetValues: clearTargetValues
          ? const <double?>[]
          : (targetValues ?? this.targetValues),
      targetMarkerStyle: targetMarkerStyle ?? this.targetMarkerStyle,
      intervalLowerValues: clearIntervalValues
          ? const <double?>[]
          : (intervalLowerValues ?? this.intervalLowerValues),
      intervalUpperValues: clearIntervalValues
          ? const <double?>[]
          : (intervalUpperValues ?? this.intervalUpperValues),
      intervalStyle: intervalStyle ?? this.intervalStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnChartSeries &&
          super == other &&
          preset == other.preset &&
          polarStyle == other.polarStyle &&
          selectionStyle == other.selectionStyle &&
          _nullableDoubleListsEqual(targetValues, other.targetValues) &&
          targetMarkerStyle == other.targetMarkerStyle &&
          _nullableDoubleListsEqual(
            intervalLowerValues,
            other.intervalLowerValues,
          ) &&
          _nullableDoubleListsEqual(
            intervalUpperValues,
            other.intervalUpperValues,
          ) &&
          intervalStyle == other.intervalStyle;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    preset,
    polarStyle,
    selectionStyle,
    Object.hashAll(targetValues),
    targetMarkerStyle,
    Object.hashAll(intervalLowerValues),
    Object.hashAll(intervalUpperValues),
    intervalStyle,
  );
}

bool _nullableDoubleListsEqual(List<double?> first, List<double?> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
