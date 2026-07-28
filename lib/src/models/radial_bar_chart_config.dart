import 'dart:ui' show Color, FontWeight;

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import '../theming/styles/label_style.dart';
import 'polar_chart_config.dart';

/// Radial ordering of category tracks.
enum RadialBarTrackOrder {
  /// The first category owns the outside track.
  outerToInner,

  /// The first category owns the inside track.
  innerToOuter,
}

/// Placement policy for Radial Bar category labels.
enum RadialBarCategoryLabelPosition {
  /// Place categories in one collision-managed vertical lane beside their
  /// shared angular origin.
  ///
  /// Optional leaders begin at the pane circumference and never reinterpret a
  /// category name as a value-end label.
  outsideCallout,

  /// Place every category immediately before its owning track's shared start.
  ///
  /// Labels remain attached to their track for both partial and full-circle
  /// panes. Collision resolution may move a label farther into the pre-start
  /// direction, but never converts it into an unrelated outside legend.
  startGap,

  /// Paint labels over their owning track at the shared angular origin.
  ///
  /// This preserves the v0.1 artifact appearance. It is not recommended when
  /// marks, tracks, or the pane background can vary in contrast.
  legacyOnTrack,
}

/// Orientation policy for category labels attached to the shared track start.
enum RadialBarCategoryLabelOrientation {
  /// Adapt labels to the shared track start.
  ///
  /// The renderer snaps to the nearest readable horizontal or vertical
  /// orientation. This keeps every category visibly attached as the pane
  /// rotates without retaining hard-to-scan diagonal text or forcing the chart
  /// to use one fixed start angle.
  followStartAngle,

  /// Keep category text horizontal regardless of the pane start angle.
  ///
  /// This is useful for intentionally upright dashboards, but may require more
  /// collision displacement near left- and right-facing track starts.
  horizontal,
}

/// Presentation and placement policy for Radial Bar category labels.
@immutable
@chartSurface
class RadialBarCategoryLabelConfig {
  const RadialBarCategoryLabelConfig({
    this.position = RadialBarCategoryLabelPosition.startGap,
    this.orientation = RadialBarCategoryLabelOrientation.followStartAngle,
    this.offset = 8,
    this.textStyle = const PolarLabelStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
    this.showPanel = false,
    this.panelStyle,
    this.connectorLength = 14,
    this.connectorWidth = 0,
    this.connectorColor,
  });

  /// Recommended outside callout, measured partial-sweep gap, or legacy track.
  final RadialBarCategoryLabelPosition position;

  /// Orientation for labels placed at the shared track start.
  ///
  /// Outside callouts and [RadialBarCategoryLabelPosition.legacyOnTrack]
  /// remain horizontal so their established reading and artifact behavior do
  /// not change.
  final RadialBarCategoryLabelOrientation orientation;

  /// Additional logical-pixel separation from the pane or partial-sweep gap.
  final double offset;

  /// Category-label typography.
  ///
  /// A null color inherits from the active chart theme. Category labels do not
  /// use mark-based automatic contrast because their bounds may cross several
  /// unrelated surfaces.
  final PolarLabelStyle textStyle;

  /// Whether to paint the configured or theme-derived label panel.
  final bool showPanel;

  /// Optional panel override.
  ///
  /// Null derives a background, border, radius, and padding from the active
  /// chart theme. [LabelStyle.textStyle] is ignored; [textStyle] remains the
  /// single category-label typography contract.
  final LabelStyle? panelStyle;

  /// Logical-pixel reach beyond the radial pane for outside callouts.
  final double connectorLength;

  /// Logical-pixel connector stroke width.
  ///
  /// Zero keeps the outside label and its category color without drawing a
  /// leader through unrelated concentric tracks.
  final double connectorWidth;

  /// Optional connector override. Null uses the owning category color.
  final Color? connectorColor;

  void validate() {
    if (!offset.isFinite || offset < 0) {
      throw ArgumentError.value(
        offset,
        'categoryLabels.offset',
        'Value must be finite and non-negative',
      );
    }
    if (!connectorLength.isFinite || connectorLength < 0) {
      throw ArgumentError.value(
        connectorLength,
        'categoryLabels.connectorLength',
        'Value must be finite and non-negative',
      );
    }
    if (!connectorWidth.isFinite || connectorWidth < 0) {
      throw ArgumentError.value(
        connectorWidth,
        'categoryLabels.connectorWidth',
        'Value must be finite and non-negative',
      );
    }
    textStyle.validate(argumentName: 'categoryLabels.textStyle');
    final labelStyle = panelStyle;
    if (labelStyle == null) return;
    if (!labelStyle.borderWidth.isFinite || labelStyle.borderWidth < 0) {
      throw ArgumentError.value(
        labelStyle.borderWidth,
        'categoryLabels.panelStyle.borderWidth',
        'Value must be finite and non-negative',
      );
    }
    if (!labelStyle.borderRadius.isFinite || labelStyle.borderRadius < 0) {
      throw ArgumentError.value(
        labelStyle.borderRadius,
        'categoryLabels.panelStyle.borderRadius',
        'Value must be finite and non-negative',
      );
    }
    final shadowBlur = labelStyle.shadowBlurRadius;
    if (shadowBlur != null && (!shadowBlur.isFinite || shadowBlur < 0)) {
      throw ArgumentError.value(
        shadowBlur,
        'categoryLabels.panelStyle.shadowBlurRadius',
        'Value must be finite and non-negative',
      );
    }
  }

  RadialBarCategoryLabelConfig copyWith({
    RadialBarCategoryLabelPosition? position,
    RadialBarCategoryLabelOrientation? orientation,
    double? offset,
    PolarLabelStyle? textStyle,
    bool? showPanel,
    LabelStyle? panelStyle,
    bool clearPanelStyle = false,
    double? connectorLength,
    double? connectorWidth,
    Color? connectorColor,
    bool clearConnectorColor = false,
  }) => RadialBarCategoryLabelConfig(
    position: position ?? this.position,
    orientation: orientation ?? this.orientation,
    offset: offset ?? this.offset,
    textStyle: textStyle ?? this.textStyle,
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
      other is RadialBarCategoryLabelConfig &&
          position == other.position &&
          orientation == other.orientation &&
          offset == other.offset &&
          textStyle == other.textStyle &&
          showPanel == other.showPanel &&
          panelStyle == other.panelStyle &&
          connectorLength == other.connectorLength &&
          connectorWidth == other.connectorWidth &&
          connectorColor == other.connectorColor;

  @override
  int get hashCode => Object.hash(
    position,
    orientation,
    offset,
    textStyle,
    showPanel,
    panelStyle,
    connectorLength,
    connectorWidth,
    connectorColor,
  );
}

/// One absolute reference on a Radial Bar angular value scale.
@immutable
@chartSurface
class RadialBarThreshold {
  const RadialBarThreshold({
    required this.value,
    this.label,
    this.color,
    this.width = 1.5,
    this.dashPattern = const <double>[6, 4],
  });

  /// Absolute value on the shared angular numeric scale.
  final double value;

  /// Optional compact label painted beside the reference guide.
  final String? label;

  /// Explicit guide color. Null resolves through the chart theme.
  final Color? color;

  /// Guide width in logical pixels.
  final double width;

  /// Alternating painted and skipped lengths. Empty renders a solid guide.
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

  RadialBarThreshold copyWith({
    double? value,
    String? label,
    bool clearLabel = false,
    Color? color,
    bool clearColor = false,
    double? width,
    List<double>? dashPattern,
  }) => RadialBarThreshold(
    value: value ?? this.value,
    label: clearLabel ? null : (label ?? this.label),
    color: clearColor ? null : (color ?? this.color),
    width: width ?? this.width,
    dashPattern: dashPattern ?? this.dashPattern,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarThreshold &&
          value == other.value &&
          label == other.label &&
          color == other.color &&
          width == other.width &&
          listEquals(dashPattern, other.dashPattern);

  @override
  int get hashCode =>
      Object.hash(value, label, color, width, Object.hashAll(dashPattern));
}

/// Plot-level geometry and guides for one Radial Bar chart.
///
/// Radial Bar is an axis-based family: categories occupy concentric tracks and
/// source values map to angular sweep. It never derives Pie-style shares.
@immutable
@chartSurface
class RadialBarChartConfig {
  const RadialBarChartConfig({
    this.pane = const PolarPaneConfig(
      innerRadiusFactor: 0.22,
      outerRadiusFactor: 0.82,
    ),
    this.trackGap = 6,
    this.trackOrder = RadialBarTrackOrder.outerToInner,
    this.showCategoryLabels = true,
    this.categoryLabels = const RadialBarCategoryLabelConfig(),
    this.showScaleLabels = true,
    this.showGridLines = true,
    this.tickCount = 5,
    this.thresholds = const <RadialBarThreshold>[],
  });

  final PolarPaneConfig pane;

  /// Requested physical gap between adjacent category tracks.
  ///
  /// Compact panes reduce this value as needed so every category remains
  /// visible and interactable.
  final double trackGap;

  final RadialBarTrackOrder trackOrder;
  final bool showCategoryLabels;
  final RadialBarCategoryLabelConfig categoryLabels;
  final bool showScaleLabels;
  final bool showGridLines;
  final int tickCount;
  final List<RadialBarThreshold> thresholds;

  void validate() {
    pane.validate();
    if (!trackGap.isFinite || trackGap < 0) {
      throw ArgumentError.value(
        trackGap,
        'trackGap',
        'Value must be finite and non-negative',
      );
    }
    if (tickCount < 2 || tickCount > 12) {
      throw ArgumentError.value(
        tickCount,
        'tickCount',
        'Tick count must be between 2 and 12',
      );
    }
    categoryLabels.validate();
    for (final threshold in thresholds) {
      threshold.validate();
    }
  }

  RadialBarChartConfig copyWith({
    PolarPaneConfig? pane,
    double? trackGap,
    RadialBarTrackOrder? trackOrder,
    bool? showCategoryLabels,
    RadialBarCategoryLabelConfig? categoryLabels,
    bool? showScaleLabels,
    bool? showGridLines,
    int? tickCount,
    List<RadialBarThreshold>? thresholds,
  }) => RadialBarChartConfig(
    pane: pane ?? this.pane,
    trackGap: trackGap ?? this.trackGap,
    trackOrder: trackOrder ?? this.trackOrder,
    showCategoryLabels: showCategoryLabels ?? this.showCategoryLabels,
    categoryLabels: categoryLabels ?? this.categoryLabels,
    showScaleLabels: showScaleLabels ?? this.showScaleLabels,
    showGridLines: showGridLines ?? this.showGridLines,
    tickCount: tickCount ?? this.tickCount,
    thresholds: thresholds ?? this.thresholds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialBarChartConfig &&
          pane == other.pane &&
          trackGap == other.trackGap &&
          trackOrder == other.trackOrder &&
          showCategoryLabels == other.showCategoryLabels &&
          categoryLabels == other.categoryLabels &&
          showScaleLabels == other.showScaleLabels &&
          showGridLines == other.showGridLines &&
          tickCount == other.tickCount &&
          listEquals(thresholds, other.thresholds);

  @override
  int get hashCode => Object.hash(
    pane,
    trackGap,
    trackOrder,
    showCategoryLabels,
    categoryLabels,
    showScaleLabels,
    showGridLines,
    tickCount,
    Object.hashAll(thresholds),
  );
}
