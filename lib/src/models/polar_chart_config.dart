import 'package:flutter/foundation.dart';

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
}

/// Plot-level composition behavior for multiple Polar Column series.
@immutable
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

/// Angular category-axis behavior for Polar Column V1.
@immutable
class PolarCategoryAxisConfig {
  const PolarCategoryAxisConfig({
    this.innerPadding = 0.12,
    this.outerPadding = 0.04,
    this.showLabels = true,
    this.showGridLines = true,
  });

  /// Gap between adjacent marks as a fraction of one category step.
  final double innerPadding;

  /// Space before and after the category collection in step fractions.
  final double outerPadding;

  final bool showLabels;
  final bool showGridLines;

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
  }

  PolarCategoryAxisConfig copyWith({
    double? innerPadding,
    double? outerPadding,
    bool? showLabels,
    bool? showGridLines,
  }) => PolarCategoryAxisConfig(
    innerPadding: innerPadding ?? this.innerPadding,
    outerPadding: outerPadding ?? this.outerPadding,
    showLabels: showLabels ?? this.showLabels,
    showGridLines: showGridLines ?? this.showGridLines,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarCategoryAxisConfig &&
          innerPadding == other.innerPadding &&
          outerPadding == other.outerPadding &&
          showLabels == other.showLabels &&
          showGridLines == other.showGridLines;

  @override
  int get hashCode =>
      Object.hash(innerPadding, outerPadding, showLabels, showGridLines);
}

/// Radial numeric-axis behavior for Polar Column V1.
@immutable
class PolarNumericAxisConfig {
  const PolarNumericAxisConfig({
    this.minimum,
    this.maximum,
    this.scaleMode,
    this.tickCount = 5,
    this.showLabels = true,
    this.showGridLines = true,
  });

  final double? minimum;
  final double? maximum;

  /// Null selects the series-family default: linear for Polar Column and
  /// area-correct for the Rose preset.
  final PolarRadialScaleMode? scaleMode;

  final int tickCount;
  final bool showLabels;
  final bool showGridLines;

  void validate() {
    if (minimum case final value?) {
      _requireRange(
        value,
        'radialAxis.minimum',
        minimum: 0,
        maximum: double.infinity,
      );
    }
    if (maximum case final value?) {
      _requireRange(
        value,
        'radialAxis.maximum',
        minimum: 0,
        maximum: double.infinity,
        minimumInclusive: false,
      );
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
  }

  PolarNumericAxisConfig copyWith({
    double? minimum,
    double? maximum,
    PolarRadialScaleMode? scaleMode,
    bool clearScaleMode = false,
    int? tickCount,
    bool? showLabels,
    bool? showGridLines,
  }) => PolarNumericAxisConfig(
    minimum: minimum ?? this.minimum,
    maximum: maximum ?? this.maximum,
    scaleMode: clearScaleMode ? null : (scaleMode ?? this.scaleMode),
    tickCount: tickCount ?? this.tickCount,
    showLabels: showLabels ?? this.showLabels,
    showGridLines: showGridLines ?? this.showGridLines,
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
          showGridLines == other.showGridLines;

  @override
  int get hashCode => Object.hash(
    minimum,
    maximum,
    scaleMode,
    tickCount,
    showLabels,
    showGridLines,
  );
}

/// Plot-level configuration for axis-based polar charts.
@immutable
class PolarChartConfig {
  const PolarChartConfig({
    this.pane = const PolarPaneConfig(),
    this.angularAxis = const PolarCategoryAxisConfig(),
    this.radialAxis = const PolarNumericAxisConfig(),
    this.composition = const PolarColumnCompositionConfig(),
  });

  final PolarPaneConfig pane;
  final PolarCategoryAxisConfig angularAxis;
  final PolarNumericAxisConfig radialAxis;

  /// How compatible Polar Column series share their angular category bands.
  final PolarColumnCompositionConfig composition;

  void validate() {
    pane.validate();
    angularAxis.validate();
    radialAxis.validate();
    composition.validate();
  }

  PolarChartConfig copyWith({
    PolarPaneConfig? pane,
    PolarCategoryAxisConfig? angularAxis,
    PolarNumericAxisConfig? radialAxis,
    PolarColumnCompositionConfig? composition,
  }) => PolarChartConfig(
    pane: pane ?? this.pane,
    angularAxis: angularAxis ?? this.angularAxis,
    radialAxis: radialAxis ?? this.radialAxis,
    composition: composition ?? this.composition,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarChartConfig &&
          pane == other.pane &&
          angularAxis == other.angularAxis &&
          radialAxis == other.radialAxis &&
          composition == other.composition;

  @override
  int get hashCode => Object.hash(pane, angularAxis, radialAxis, composition);
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
