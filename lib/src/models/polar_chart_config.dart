import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show FontWeight;

import '../meta/chart_surface.dart';

/// Pane-wide reference threshold on a Polar Column radial numeric axis.
@immutable
@chartSurface
class PolarThreshold {
  const PolarThreshold({
    required this.value,
    this.label,
    this.color,
    this.width = 1.5,
    this.dashPattern = const <double>[6, 4],
  });

  /// Absolute value on the shared radial numeric scale.
  final double value;

  /// Optional compact label painted beside the reference arc.
  final String? label;

  /// Explicit line and label color. Null uses the chart focus color.
  final Color? color;

  /// Reference arc width in logical pixels.
  final double width;

  /// Alternating painted and skipped path lengths. Empty renders a solid arc.
  final List<double> dashPattern;

  void validate() {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'threshold.value',
        'Value must be finite',
      );
    }
    if (label != null && label!.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'threshold.label',
        'Label must be null or visible text',
      );
    }
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(
        width,
        'threshold.width',
        'Value must be finite and positive',
      );
    }
    if (dashPattern.length.isOdd) {
      throw ArgumentError.value(
        dashPattern,
        'threshold.dashPattern',
        'Dash patterns must contain painted-gap pairs',
      );
    }
    for (final (index, interval) in dashPattern.indexed) {
      if (!interval.isFinite || interval <= 0) {
        throw ArgumentError.value(
          interval,
          'threshold.dashPattern[$index]',
          'Intervals must be finite and positive',
        );
      }
    }
  }

  PolarThreshold copyWith({
    double? value,
    String? label,
    bool clearLabel = false,
    Color? color,
    bool clearColor = false,
    double? width,
    List<double>? dashPattern,
  }) => PolarThreshold(
    value: value ?? this.value,
    label: clearLabel ? null : (label ?? this.label),
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    dashPattern: dashPattern ?? this.dashPattern,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarThreshold &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          width == other.width &&
          listEquals(dashPattern, other.dashPattern);

  @override
  int get hashCode =>
      Object.hash(value, label, color, width, Object.hashAll(dashPattern));
}

/// Numeric mapping used by a Polar Column radial axis.
enum PolarRadialScaleMode {
  /// Equal value differences produce equal radial distances.
  linear,

  /// Equal value proportions produce equal annular-sector areas.
  areaCorrect,
}

/// How multiple compatible Polar Column series share each category band.
enum PolarColumnCompositionMode {
  /// Every series occupies the full category band in declaration order.
  layered,

  /// Every series occupies a separate angular sub-band within the category.
  grouped,

  /// Series accumulate radially from zero inside the complete category band.
  ///
  /// Positive and negative values use independent declaration-order stacks.
  stacked,
}

/// Plot-level composition behavior for multiple Polar Column series.
@immutable
@chartSurface
class PolarColumnCompositionConfig {
  const PolarColumnCompositionConfig({
    this.mode = PolarColumnCompositionMode.layered,
    this.groupInnerPadding = 0.12,
  });

  /// Angular arrangement used when more than one compatible series is present.
  final PolarColumnCompositionMode mode;

  /// Gap between grouped series as a fraction of one series sub-band.
  ///
  /// This is separate from [PolarCategoryAxisConfig.innerPadding], which
  /// controls the gap between complete category bands.
  final double groupInnerPadding;

  void validate() {
    _requireRange(
      groupInnerPadding,
      'composition.groupInnerPadding',
      minimum: 0,
      maximum: 1,
      maximumInclusive: false,
    );
  }

  PolarColumnCompositionConfig copyWith({
    PolarColumnCompositionMode? mode,
    double? groupInnerPadding,
  }) => PolarColumnCompositionConfig(
    mode: mode ?? this.mode,
    groupInnerPadding: groupInnerPadding ?? this.groupInnerPadding,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarColumnCompositionConfig &&
          mode == other.mode &&
          groupInnerPadding == other.groupInnerPadding;

  @override
  int get hashCode => Object.hash(mode, groupInnerPadding);
}

/// Geometry shared by every axis-based series in one polar pane.
@immutable
@chartSurface
class PolarPaneConfig {
  const PolarPaneConfig({
    this.startAngleDegrees = -90,
    this.sweepAngleDegrees = 360,
    this.clockwise = true,
    this.innerRadiusFactor = 0,
    this.outerRadiusFactor = 0.88,
    this.clipMarks = true,
  });

  final double startAngleDegrees;
  final double sweepAngleDegrees;
  final bool clockwise;
  final double innerRadiusFactor;
  final double outerRadiusFactor;
  final bool clipMarks;

  void validate() {
    _requireFinite(startAngleDegrees, 'pane.startAngleDegrees');
    _requireRange(
      sweepAngleDegrees,
      'pane.sweepAngleDegrees',
      minimum: 0,
      maximum: 360,
      minimumInclusive: false,
    );
    _requireRange(
      innerRadiusFactor,
      'pane.innerRadiusFactor',
      minimum: 0,
      maximum: 1,
      maximumInclusive: false,
    );
    _requireRange(
      outerRadiusFactor,
      'pane.outerRadiusFactor',
      minimum: 0,
      maximum: 1,
      minimumInclusive: false,
    );
    if (innerRadiusFactor >= outerRadiusFactor) {
      throw ArgumentError.value(
        innerRadiusFactor,
        'pane.innerRadiusFactor',
        'Inner radius must be smaller than outer radius',
      );
    }
  }

  PolarPaneConfig copyWith({
    double? startAngleDegrees,
    double? sweepAngleDegrees,
    bool? clockwise,
    double? innerRadiusFactor,
    double? outerRadiusFactor,
    bool? clipMarks,
  }) => PolarPaneConfig(
    startAngleDegrees: startAngleDegrees ?? this.startAngleDegrees,
    sweepAngleDegrees: sweepAngleDegrees ?? this.sweepAngleDegrees,
    clockwise: clockwise ?? this.clockwise,
    innerRadiusFactor: innerRadiusFactor ?? this.innerRadiusFactor,
    outerRadiusFactor: outerRadiusFactor ?? this.outerRadiusFactor,
    clipMarks: clipMarks ?? this.clipMarks,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarPaneConfig &&
          startAngleDegrees == other.startAngleDegrees &&
          sweepAngleDegrees == other.sweepAngleDegrees &&
          clockwise == other.clockwise &&
          innerRadiusFactor == other.innerRadiusFactor &&
          outerRadiusFactor == other.outerRadiusFactor &&
          clipMarks == other.clipMarks;

  @override
  int get hashCode => Object.hash(
    startAngleDegrees,
    sweepAngleDegrees,
    clockwise,
    innerRadiusFactor,
    outerRadiusFactor,
    clipMarks,
  );
}

/// Reusable text appearance for Polar Column labels.
///
/// Null values inherit the corresponding property from the chart theme. This
/// keeps Polar labels theme-aware while allowing category, value, and radial
/// axis labels to be styled independently.
@immutable
@chartSurface
class PolarLabelStyle {
  const PolarLabelStyle({this.color, this.fontSize, this.fontWeight});

  /// Explicit text color. Null inherits the chart theme or automatic contrast.
  final Color? color;

  /// Explicit logical-pixel text size. Null inherits the chart theme.
  final double? fontSize;

  /// Explicit text weight. Null inherits the chart theme or renderer default.
  final FontWeight? fontWeight;

  void validate({String argumentName = 'labelStyle'}) {
    if (fontSize case final value? when !value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        '$argumentName.fontSize',
        'Value must be finite and positive',
      );
    }
  }

  PolarLabelStyle copyWith({
    Color? color,
    bool clearColor = false,
    double? fontSize,
    bool clearFontSize = false,
    FontWeight? fontWeight,
    bool clearFontWeight = false,
  }) => PolarLabelStyle(
    color: clearColor ? null : (color ?? this.color),
    fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
    fontWeight: clearFontWeight ? null : (fontWeight ?? this.fontWeight),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarLabelStyle &&
          color == other.color &&
          fontSize == other.fontSize &&
          fontWeight == other.fontWeight;

  @override
  int get hashCode => Object.hash(color, fontSize, fontWeight);
}

/// Angular anchor used for radial numeric-axis labels.
enum PolarRadialLabelPosition {
  /// Place labels on the pane's configured start-angle ray.
  start,

  /// Place labels halfway through the configured angular sweep.
  middle,

  /// Place labels on the pane's configured end-angle ray.
  end,
}

/// Angular category-axis behavior for Polar Column V1.
@immutable
@chartSurface
class PolarCategoryAxisConfig {
  const PolarCategoryAxisConfig({
    this.innerPadding = 0.12,
    this.outerPadding = 0.04,
    this.showLabels = true,
    this.showGridLines = true,
    this.maximumVisibleLabels = 24,
    this.maximumVisibleGridLines = 72,
    this.labelOffset = 0,
    this.labelStyle = const PolarLabelStyle(),
  });

  /// Gap between adjacent marks as a fraction of one category step.
  final double innerPadding;

  /// Space before and after the category collection in step fractions.
  final double outerPadding;

  final bool showLabels;
  final bool showGridLines;

  /// Upper bound for painted category labels before spatial thinning.
  ///
  /// The renderer may paint fewer labels when the active pane or text scale
  /// cannot fit this many. Source categories, interaction, table rows, and
  /// semantics are never removed.
  final int maximumVisibleLabels;

  /// Upper bound for painted angular grid spokes.
  ///
  /// This limits visual and paint density only. Every category retains its
  /// exact angular band and interaction identity.
  final int maximumVisibleGridLines;

  /// Additional logical-pixel distance beyond the compact default label ring.
  ///
  /// Zero keeps labels tight to the plot. Positive values move them away from
  /// the columns; negative values move them inward while remaining in-bounds.
  final double labelOffset;

  /// Category-label appearance independent from radial and value labels.
  final PolarLabelStyle labelStyle;

  void validate() {
    _requireRange(
      innerPadding,
      'angularAxis.innerPadding',
      minimum: 0,
      maximum: 1,
      maximumInclusive: false,
    );
    _requireRange(
      outerPadding,
      'angularAxis.outerPadding',
      minimum: 0,
      maximum: 1,
    );
    if (maximumVisibleLabels < 1) {
      throw ArgumentError.value(
        maximumVisibleLabels,
        'angularAxis.maximumVisibleLabels',
        'Value must be positive',
      );
    }
    if (maximumVisibleGridLines < 1) {
      throw ArgumentError.value(
        maximumVisibleGridLines,
        'angularAxis.maximumVisibleGridLines',
        'Value must be positive',
      );
    }
    if (!labelOffset.isFinite) {
      throw ArgumentError.value(
        labelOffset,
        'angularAxis.labelOffset',
        'Value must be finite',
      );
    }
    labelStyle.validate(argumentName: 'angularAxis.labelStyle');
  }

  PolarCategoryAxisConfig copyWith({
    double? innerPadding,
    double? outerPadding,
    bool? showLabels,
    bool? showGridLines,
    int? maximumVisibleLabels,
    int? maximumVisibleGridLines,
    double? labelOffset,
    PolarLabelStyle? labelStyle,
  }) => PolarCategoryAxisConfig(
    innerPadding: innerPadding ?? this.innerPadding,
    outerPadding: outerPadding ?? this.outerPadding,
    showLabels: showLabels ?? this.showLabels,
    showGridLines: showGridLines ?? this.showGridLines,
    maximumVisibleLabels: maximumVisibleLabels ?? this.maximumVisibleLabels,
    maximumVisibleGridLines:
        maximumVisibleGridLines ?? this.maximumVisibleGridLines,
    labelOffset: labelOffset ?? this.labelOffset,
    labelStyle: labelStyle ?? this.labelStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarCategoryAxisConfig &&
          innerPadding == other.innerPadding &&
          outerPadding == other.outerPadding &&
          showLabels == other.showLabels &&
          showGridLines == other.showGridLines &&
          maximumVisibleLabels == other.maximumVisibleLabels &&
          maximumVisibleGridLines == other.maximumVisibleGridLines &&
          labelOffset == other.labelOffset &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    innerPadding,
    outerPadding,
    showLabels,
    showGridLines,
    maximumVisibleLabels,
    maximumVisibleGridLines,
    labelOffset,
    labelStyle,
  );
}

/// Radial numeric-axis behavior for Polar Column V1.
@immutable
@chartSurface
class PolarNumericAxisConfig {
  const PolarNumericAxisConfig({
    this.minimum,
    this.maximum,
    this.scaleMode,
    this.tickCount = 5,
    this.showLabels = true,
    this.showGridLines = true,
    this.labelPosition = PolarRadialLabelPosition.start,
    this.labelAngleOffsetDegrees = 0,
    this.labelOffset = 4,
    this.labelStyle = const PolarLabelStyle(fontSize: 10),
  });

  final double? minimum;
  final double? maximum;

  /// Null selects the series-family default: linear for Polar Column and
  /// area-correct for the Rose preset.
  final PolarRadialScaleMode? scaleMode;

  final int tickCount;
  final bool showLabels;
  final bool showGridLines;

  /// Named sweep anchor for the ring-value labels.
  final PolarRadialLabelPosition labelPosition;

  /// Fine angular adjustment applied after [labelPosition] is resolved.
  final double labelAngleOffsetDegrees;

  /// Logical-pixel displacement along the resolved label ray.
  final double labelOffset;

  /// Radial-axis label appearance independent from category and value labels.
  final PolarLabelStyle labelStyle;

  void validate() {
    if (minimum case final value?) {
      _requireFinite(value, 'radialAxis.minimum');
    }
    if (maximum case final value?) {
      _requireFinite(value, 'radialAxis.maximum');
    }
    if (minimum != null && maximum != null && minimum! >= maximum!) {
      throw ArgumentError.value(
        maximum,
        'radialAxis.maximum',
        'Maximum must be greater than minimum',
      );
    }
    if (tickCount < 2 || tickCount > 12) {
      throw ArgumentError.value(
        tickCount,
        'radialAxis.tickCount',
        'Tick count must be between 2 and 12',
      );
    }
    if (!labelAngleOffsetDegrees.isFinite) {
      throw ArgumentError.value(
        labelAngleOffsetDegrees,
        'radialAxis.labelAngleOffsetDegrees',
        'Value must be finite',
      );
    }
    if (!labelOffset.isFinite) {
      throw ArgumentError.value(
        labelOffset,
        'radialAxis.labelOffset',
        'Value must be finite',
      );
    }
    labelStyle.validate(argumentName: 'radialAxis.labelStyle');
  }

  PolarNumericAxisConfig copyWith({
    double? minimum,
    bool clearMinimum = false,
    double? maximum,
    bool clearMaximum = false,
    PolarRadialScaleMode? scaleMode,
    bool clearScaleMode = false,
    int? tickCount,
    bool? showLabels,
    bool? showGridLines,
    PolarRadialLabelPosition? labelPosition,
    double? labelAngleOffsetDegrees,
    double? labelOffset,
    PolarLabelStyle? labelStyle,
  }) => PolarNumericAxisConfig(
    minimum: clearMinimum ? null : (minimum ?? this.minimum),
    maximum: clearMaximum ? null : (maximum ?? this.maximum),
    scaleMode: clearScaleMode ? null : (scaleMode ?? this.scaleMode),
    tickCount: tickCount ?? this.tickCount,
    showLabels: showLabels ?? this.showLabels,
    showGridLines: showGridLines ?? this.showGridLines,
    labelPosition: labelPosition ?? this.labelPosition,
    labelAngleOffsetDegrees:
        labelAngleOffsetDegrees ?? this.labelAngleOffsetDegrees,
    labelOffset: labelOffset ?? this.labelOffset,
    labelStyle: labelStyle ?? this.labelStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarNumericAxisConfig &&
          minimum == other.minimum &&
          maximum == other.maximum &&
          scaleMode == other.scaleMode &&
          tickCount == other.tickCount &&
          showLabels == other.showLabels &&
          showGridLines == other.showGridLines &&
          labelPosition == other.labelPosition &&
          labelAngleOffsetDegrees == other.labelAngleOffsetDegrees &&
          labelOffset == other.labelOffset &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    minimum,
    maximum,
    scaleMode,
    tickCount,
    showLabels,
    showGridLines,
    labelPosition,
    labelAngleOffsetDegrees,
    labelOffset,
    labelStyle,
  );
}

/// Plot-level configuration for axis-based polar charts.
@immutable
@chartSurface
class PolarChartConfig {
  /// Artifact capability required by non-default Polar label presentation.
  static const labelAppearanceCapability = 'chart.polar.labels.v1';

  const PolarChartConfig({
    this.pane = const PolarPaneConfig(),
    this.angularAxis = const PolarCategoryAxisConfig(),
    this.radialAxis = const PolarNumericAxisConfig(),
    this.composition = const PolarColumnCompositionConfig(),
    this.thresholds = const <PolarThreshold>[],
  });

  final PolarPaneConfig pane;
  final PolarCategoryAxisConfig angularAxis;
  final PolarNumericAxisConfig radialAxis;

  /// How compatible Polar Column series share their angular category bands.
  final PolarColumnCompositionConfig composition;

  /// Pane-wide radial references drawn behind every Polar Column series.
  final List<PolarThreshold> thresholds;

  /// Whether this config uses label presentation beyond V1 defaults.
  bool get hasCustomLabelAppearance =>
      angularAxis.labelOffset != 0 ||
      angularAxis.labelStyle != const PolarLabelStyle() ||
      radialAxis.labelPosition != PolarRadialLabelPosition.start ||
      radialAxis.labelAngleOffsetDegrees != 0 ||
      radialAxis.labelOffset != 4 ||
      radialAxis.labelStyle != const PolarLabelStyle(fontSize: 10);

  void validate() {
    pane.validate();
    angularAxis.validate();
    radialAxis.validate();
    composition.validate();
    for (final threshold in thresholds) {
      threshold.validate();
    }
    if (composition.mode == PolarColumnCompositionMode.stacked) {
      if (radialAxis.minimum case final minimum? when minimum > 0) {
        throw ArgumentError.value(
          minimum,
          'radialAxis.minimum',
          'Stacked Polar Column bounds must contain the zero baseline',
        );
      }
      if (radialAxis.maximum case final maximum? when maximum < 0) {
        throw ArgumentError.value(
          maximum,
          'radialAxis.maximum',
          'Stacked Polar Column bounds must contain the zero baseline',
        );
      }
    }
  }

  PolarChartConfig copyWith({
    PolarPaneConfig? pane,
    PolarCategoryAxisConfig? angularAxis,
    PolarNumericAxisConfig? radialAxis,
    PolarColumnCompositionConfig? composition,
    List<PolarThreshold>? thresholds,
  }) => PolarChartConfig(
    pane: pane ?? this.pane,
    angularAxis: angularAxis ?? this.angularAxis,
    radialAxis: radialAxis ?? this.radialAxis,
    composition: composition ?? this.composition,
    thresholds: thresholds ?? this.thresholds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarChartConfig &&
          pane == other.pane &&
          angularAxis == other.angularAxis &&
          radialAxis == other.radialAxis &&
          composition == other.composition &&
          listEquals(thresholds, other.thresholds);

  @override
  int get hashCode => Object.hash(
    pane,
    angularAxis,
    radialAxis,
    composition,
    Object.hashAll(thresholds),
  );
}

void _requireFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'Value must be finite');
  }
}

void _requireRange(
  double value,
  String name, {
  required double minimum,
  required double maximum,
  bool minimumInclusive = true,
  bool maximumInclusive = true,
}) {
  final aboveMinimum = minimumInclusive ? value >= minimum : value > minimum;
  final belowMaximum = maximumInclusive ? value <= maximum : value < maximum;
  if (!value.isFinite || !aboveMinimum || !belowMaximum) {
    throw ArgumentError.value(value, name, 'Value is outside the valid range');
  }
}
