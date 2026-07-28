import 'dart:ui' show Color, FontWeight;

import 'package:flutter/foundation.dart' show immutable;

import '../meta/chart_surface.dart';
import '../theming/styles/label_style.dart';
import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'chart_series.dart';
import 'radial_selection_style.dart';
import 'segment_style.dart';
import 'polar_chart_config.dart';
import 'y_axis_config.dart';

/// Direction used to shade a Radial Bar mark.
enum RadialBarGradientType {
  /// Follows the mark from its baseline towards its value endpoint.
  sweep,

  /// Runs across the mark thickness from the inner to the outer track edge.
  radial,
}

/// Serializable gradient applied independently to every Radial Bar mark.
///
/// Null colors are derived from each category's resolved mark color so a
/// gradient preserves categorical identity unless fixed colors are requested.
@immutable
@chartSurface
class RadialBarGradientStyle {
  const RadialBarGradientStyle({
    this.enabled = true,
    this.type = RadialBarGradientType.sweep,
    this.startColor,
    this.endColor,
    this.startLightnessShift = 0.18,
    this.endLightnessShift = -0.12,
  });

  final bool enabled;
  final RadialBarGradientType type;
  final Color? startColor;
  final Color? endColor;
  final double startLightnessShift;
  final double endLightnessShift;

  void validate() {
    for (final (name, value) in <(String, double)>[
      ('startLightnessShift', startLightnessShift),
      ('endLightnessShift', endLightnessShift),
    ]) {
      if (!value.isFinite || value < -1 || value > 1) {
        throw ArgumentError.value(
          value,
          'radialBarStyle.gradient.$name',
          'Value must be finite and in [-1, 1]',
        );
      }
    }
  }

  RadialBarGradientStyle copyWith({
    bool? enabled,
    RadialBarGradientType? type,
    Color? startColor,
    bool clearStartColor = false,
    Color? endColor,
    bool clearEndColor = false,
    double? startLightnessShift,
    double? endLightnessShift,
  }) => RadialBarGradientStyle(
    enabled: enabled ?? this.enabled,
    type: type ?? this.type,
    startColor: clearStartColor ? null : (startColor ?? this.startColor),
    endColor: clearEndColor ? null : (endColor ?? this.endColor),
    startLightnessShift: startLightnessShift ?? this.startLightnessShift,
    endLightnessShift: endLightnessShift ?? this.endLightnessShift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarGradientStyle &&
          enabled == other.enabled &&
          type == other.type &&
          startColor == other.startColor &&
          endColor == other.endColor &&
          startLightnessShift == other.startLightnessShift &&
          endLightnessShift == other.endLightnessShift;

  @override
  int get hashCode => Object.hash(
    enabled,
    type,
    startColor,
    endColor,
    startLightnessShift,
    endLightnessShift,
  );
}

/// Placement of one Radial Bar data label.
enum RadialBarDataLabelPosition {
  /// Keep the label inside the colored mark near its value endpoint.
  ///
  /// Labels that cannot fit without crossing the rounded endpoint or track
  /// edges are omitted.
  insideEnd,

  /// Place labels in collision-managed lanes outside the radial pane.
  ///
  /// A two-segment connector links each label to its category-track endpoint.
  outsideCallout,
}

/// Content shown by a Radial Bar data label.
enum RadialBarDataLabelContent {
  /// The formatted numeric value only.
  value,

  /// The category name only.
  category,

  /// The category name followed by the formatted numeric value.
  categoryAndValue,
}

/// Color resolution used for Radial Bar data labels.
enum RadialBarDataLabelColorMode {
  /// Choose an accessible foreground against the mark or chart background.
  autoContrast,

  /// Use [RadialBarDataLabelConfig.textStyle]'s color.
  ///
  /// When that color is null, the chart theme's label color is used.
  fixed,
}

/// Presentation and placement policy for Radial Bar data labels.
@immutable
@chartSurface
class RadialBarDataLabelConfig {
  const RadialBarDataLabelConfig({
    this.position = RadialBarDataLabelPosition.insideEnd,
    this.content = RadialBarDataLabelContent.value,
    this.colorMode = RadialBarDataLabelColorMode.autoContrast,
    this.textStyle = const PolarLabelStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
    this.offset = 0,
    this.showPanel = false,
    this.panelStyle,
    this.connectorLength = 14,
    this.connectorWidth = 1,
    this.connectorColor,
  });

  /// Inside-end or outside-callout placement.
  final RadialBarDataLabelPosition position;

  /// Category/value content shown by each label.
  final RadialBarDataLabelContent content;

  /// Automatic accessible contrast or an explicit text color.
  final RadialBarDataLabelColorMode colorMode;

  /// Label typography.
  ///
  /// Font size and weight are honored in both color modes. [PolarLabelStyle.color]
  /// is used only when [colorMode] is [RadialBarDataLabelColorMode.fixed].
  final PolarLabelStyle textStyle;

  /// Additional logical-pixel distance from the default placement.
  ///
  /// For [RadialBarDataLabelPosition.insideEnd], positive values move the
  /// label farther inside the colored arc. For
  /// [RadialBarDataLabelPosition.outsideCallout], positive values move the
  /// outside label lane farther from the pane.
  final double offset;

  /// Whether outside callouts use a background panel.
  ///
  /// Inside-end labels remain unboxed so they stay contained by their mark.
  final bool showPanel;

  /// Optional outside-callout panel override.
  ///
  /// Null derives an opaque-enough background, border, radius, and padding
  /// from the active chart theme. [LabelStyle.textStyle] is ignored;
  /// [textStyle] remains the single callout typography contract.
  final LabelStyle? panelStyle;

  /// Logical-pixel connector reach beyond the radial pane.
  final double connectorLength;

  /// Logical-pixel connector stroke width.
  final double connectorWidth;

  /// Optional connector override. Null uses the owning mark color.
  final Color? connectorColor;

  void validate() {
    textStyle.validate(argumentName: 'radialBarStyle.dataLabels.textStyle');
    if (!offset.isFinite || offset < 0) {
      throw ArgumentError.value(
        offset,
        'radialBarStyle.dataLabels.offset',
        'Value must be finite and non-negative',
      );
    }
    if (!connectorLength.isFinite || connectorLength < 0) {
      throw ArgumentError.value(
        connectorLength,
        'radialBarStyle.dataLabels.connectorLength',
        'Value must be finite and non-negative',
      );
    }
    if (!connectorWidth.isFinite || connectorWidth < 0) {
      throw ArgumentError.value(
        connectorWidth,
        'radialBarStyle.dataLabels.connectorWidth',
        'Value must be finite and non-negative',
      );
    }
    final labelStyle = panelStyle;
    if (labelStyle == null) return;
    if (!labelStyle.borderWidth.isFinite || labelStyle.borderWidth < 0) {
      throw ArgumentError.value(
        labelStyle.borderWidth,
        'radialBarStyle.dataLabels.panelStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
    if (!labelStyle.borderRadius.isFinite || labelStyle.borderRadius < 0) {
      throw ArgumentError.value(
        labelStyle.borderRadius,
        'radialBarStyle.dataLabels.panelStyle.borderRadius',
        'Value must be finite and non-negative',
      );
    }
    final shadowBlur = labelStyle.shadowBlurRadius;
    if (shadowBlur != null && (!shadowBlur.isFinite || shadowBlur < 0)) {
      throw ArgumentError.value(
        shadowBlur,
        'radialBarStyle.dataLabels.panelStyle.shadowBlurRadius',
        'Value must be finite and non-negative',
      );
    }
  }

  RadialBarDataLabelConfig copyWith({
    RadialBarDataLabelPosition? position,
    RadialBarDataLabelContent? content,
    RadialBarDataLabelColorMode? colorMode,
    PolarLabelStyle? textStyle,
    double? offset,
    bool? showPanel,
    LabelStyle? panelStyle,
    bool clearPanelStyle = false,
    double? connectorLength,
    double? connectorWidth,
    Color? connectorColor,
    bool clearConnectorColor = false,
  }) => RadialBarDataLabelConfig(
    position: position ?? this.position,
    content: content ?? this.content,
    colorMode: colorMode ?? this.colorMode,
    textStyle: textStyle ?? this.textStyle,
    offset: offset ?? this.offset,
    showPanel: showPanel ?? this.showPanel,
    panelStyle: clearPanelStyle ? null : (panelStyle ?? this.panelStyle),
    connectorLength: connectorLength ?? this.connectorLength,
    connectorWidth: connectorWidth ?? this.connectorWidth,
    connectorColor: clearConnectorColor
        ? null
        : (connectorColor ?? this.connectorColor),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarDataLabelConfig &&
          position == other.position &&
          content == other.content &&
          colorMode == other.colorMode &&
          textStyle == other.textStyle &&
          offset == other.offset &&
          showPanel == other.showPanel &&
          panelStyle == other.panelStyle &&
          connectorLength == other.connectorLength &&
          connectorWidth == other.connectorWidth &&
          connectorColor == other.connectorColor;

  @override
  int get hashCode => Object.hash(
    position,
    content,
    colorMode,
    textStyle,
    offset,
    showPanel,
    panelStyle,
    connectorLength,
    connectorWidth,
    connectorColor,
  );
}

/// Appearance of Radial Bar marks and their background category tracks.
@immutable
@chartSurface
class RadialBarStyle {
  const RadialBarStyle({
    this.cornerRadius = 8,
    this.opacity = 1,
    this.borderColor,
    this.borderWidth = 0,
    this.trackColor,
    this.trackOpacity = 0.12,
    this.gradient,
    this.showDataLabels = true,
    this.dataLabels = const RadialBarDataLabelConfig(),
  });

  final double cornerRadius;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final Color? trackColor;
  final double trackOpacity;
  final RadialBarGradientStyle? gradient;
  final bool showDataLabels;
  final RadialBarDataLabelConfig dataLabels;

  void validate() {
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'radialBarStyle.cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (!opacity.isFinite || opacity < 0 || opacity > 1) {
      throw ArgumentError.value(
        opacity,
        'radialBarStyle.opacity',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!borderWidth.isFinite || borderWidth < 0) {
      throw ArgumentError.value(
        borderWidth,
        'radialBarStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
    if (!trackOpacity.isFinite || trackOpacity < 0 || trackOpacity > 1) {
      throw ArgumentError.value(
        trackOpacity,
        'radialBarStyle.trackOpacity',
        'Value must be finite and in [0, 1]',
      );
    }
    gradient?.validate();
    dataLabels.validate();
  }

  RadialBarStyle copyWith({
    double? cornerRadius,
    double? opacity,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    Color? trackColor,
    bool clearTrackColor = false,
    double? trackOpacity,
    RadialBarGradientStyle? gradient,
    bool clearGradient = false,
    bool? showDataLabels,
    RadialBarDataLabelConfig? dataLabels,
  }) => RadialBarStyle(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    opacity: opacity ?? this.opacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    trackColor: clearTrackColor ? null : (trackColor ?? this.trackColor),
    trackOpacity: trackOpacity ?? this.trackOpacity,
    gradient: clearGradient ? null : (gradient ?? this.gradient),
    showDataLabels: showDataLabels ?? this.showDataLabels,
    dataLabels: dataLabels ?? this.dataLabels,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarStyle &&
          cornerRadius == other.cornerRadius &&
          opacity == other.opacity &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          trackColor == other.trackColor &&
          trackOpacity == other.trackOpacity &&
          gradient == other.gradient &&
          showDataLabels == other.showDataLabels &&
          dataLabels == other.dataLabels;

  @override
  int get hashCode => Object.hash(
    cornerRadius,
    opacity,
    borderColor,
    borderWidth,
    trackColor,
    trackOpacity,
    gradient,
    showDataLabels,
    dataLabels,
  );
}

/// One category-track Radial Bar series.
///
/// Category identity follows stable declaration order. Values map to angular
/// sweep inside the explicit [minimum], [maximum], and [baseline] domain.
/// Values are never normalized into shares unless the caller explicitly
/// supplies percentage data and labels it as such.
@ChartSurface(
  excluded: ['id', 'points'],
  bodyValidated: [
    BodyValidated(
      '_validate() re-runs radialBarStyle.validate() on every construction, '
      'so withRadialBarStyle rejects a nested style that is invalid in this '
      'series.',
    ),
  ],
)
class RadialBarChartSeries extends ChartSeries {
  RadialBarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.metadata,
    super.unit,
    this.minimum = 0,
    this.maximum = 100,
    this.baseline = 0,
    this.radialBarStyle = const RadialBarStyle(),
    this.selectionStyle = const RadialSelectionStyle(),
  }) : super(style: SeriesStyle.radialBar, isXOrdered: true) {
    _validate();
  }

  /// Creates stable ordinal points from insertion-ordered categories.
  factory RadialBarChartSeries.fromMap({
    required String id,
    String? name,
    required Map<String, num> values,
    Map<String, Color> barColors = const {},
    Color? color,
    Map<String, dynamic>? metadata,
    String? unit,
    double minimum = 0,
    double maximum = 100,
    double baseline = 0,
    RadialBarStyle radialBarStyle = const RadialBarStyle(),
    RadialSelectionStyle selectionStyle = const RadialSelectionStyle(),
  }) => RadialBarChartSeries(
    id: id,
    name: name,
    points: [
      for (final (index, entry) in values.entries.indexed)
        ChartDataPoint(
          x: index.toDouble(),
          y: entry.value.toDouble(),
          label: entry.key,
          pointStyle: barColors[entry.key] == null
              ? null
              : PointStyle.color(barColors[entry.key]!),
        ),
    ],
    color: color,
    metadata: metadata,
    unit: unit,
    minimum: minimum,
    maximum: maximum,
    baseline: baseline,
    radialBarStyle: radialBarStyle,
    selectionStyle: selectionStyle,
  );

  /// Explicit minimum on the angular numeric scale.
  final double minimum;

  /// Explicit maximum on the angular numeric scale.
  final double maximum;

  /// Absolute value from which every category mark begins.
  final double baseline;

  final RadialBarStyle radialBarStyle;
  final RadialSelectionStyle selectionStyle;

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
        'Radial Bar requires at least one category',
      );
    }
    if (!minimum.isFinite || !maximum.isFinite || minimum >= maximum) {
      throw ArgumentError.value(
        '$minimum / $maximum',
        'minimum / maximum',
        'Bounds must be finite and maximum must be greater than minimum',
      );
    }
    if (!baseline.isFinite || baseline < minimum || baseline > maximum) {
      throw ArgumentError.value(
        baseline,
        'baseline',
        'Baseline must be finite and inside the explicit domain',
      );
    }
    final categories = <String>{};
    for (final (index, point) in points.indexed) {
      if (!point.x.isFinite || point.x != index.toDouble()) {
        throw ArgumentError.value(
          point.x,
          'points[$index].x',
          'Radial Bar X values must be stable zero-based ordinals',
        );
      }
      if (!point.y.isFinite || point.y < minimum || point.y > maximum) {
        throw ArgumentError.value(
          point.y,
          'points[$index].y',
          'Radial Bar values must be finite and inside the explicit domain',
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
    radialBarStyle.validate();
    _requireSelectionRange(
      selectionStyle.liftScale,
      'selectionStyle.liftScale',
      minimum: 1,
      maximum: 1.5,
    );
    _requireSelectionRange(
      selectionStyle.liftOffset,
      'selectionStyle.liftOffset',
      minimum: 0,
      maximum: 40,
    );
    _requireSelectionRange(
      selectionStyle.backdropBlur,
      'selectionStyle.backdropBlur',
      minimum: 0,
      maximum: 20,
    );
  }

  static void _requireSelectionRange(
    double value,
    String name, {
    required double minimum,
    required double maximum,
  }) {
    if (!value.isFinite || value < minimum || value > maximum) {
      throw ArgumentError.value(
        value,
        name,
        'Value must be finite and in [$minimum, $maximum]',
      );
    }
  }

  @override
  RadialBarChartSeries copyWith({
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
    YAxisConfig? yAxisConfig,
    String? unit,
    bool clearUnit = false,
    double? minimum,
    double? maximum,
    double? baseline,
    RadialBarStyle? radialBarStyle,
    RadialSelectionStyle? selectionStyle,
  }) {
    if (style != null && style != SeriesStyle.radialBar) {
      throw ArgumentError.value(
        style,
        'style',
        'Radial Bar series style is fixed',
      );
    }
    if (isXOrdered == false) {
      throw ArgumentError.value(
        isXOrdered,
        'isXOrdered',
        'Radial Bar category order must remain stable',
      );
    }
    if (annotations != null || yAxisId != null || yAxisConfig != null) {
      throw ArgumentError(
        'Radial Bar owns its angular numeric scale and does not support '
        'Cartesian series annotations or Y axes',
      );
    }
    return RadialBarChartSeries(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      points: points ?? this.points,
      color: clearColor ? null : (color ?? this.color),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      unit: clearUnit ? null : (unit ?? this.unit),
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      baseline: baseline ?? this.baseline,
      radialBarStyle: radialBarStyle ?? this.radialBarStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarChartSeries &&
          super == other &&
          minimum == other.minimum &&
          maximum == other.maximum &&
          baseline == other.baseline &&
          radialBarStyle == other.radialBarStyle &&
          selectionStyle == other.selectionStyle;

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    minimum,
    maximum,
    baseline,
    radialBarStyle,
    selectionStyle,
  );
}
