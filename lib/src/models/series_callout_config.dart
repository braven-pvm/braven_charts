// Copyright (c) 2025 braven_charts. All rights reserved.

import 'package:flutter/material.dart';

import '../meta/chart_surface.dart';

/// Side of the plot used by the shared series-callout lane.
enum SeriesCalloutSide { left, right }

/// Horizontal placement of the shared series-callout lane.
enum SeriesCalloutLanePlacement {
  /// Pin the lane to the selected [SeriesCalloutSide] of the plot.
  plotEdge,

  /// Keep the lane beside the furthest resolved series anchor.
  ///
  /// This is useful for progressive charts such as line races, where the
  /// current data frontier advances through a wider, stable X-axis domain.
  anchorFrontier,
}

/// Data feature used to anchor a callout connector to a series.
enum SeriesCalloutAnchor {
  /// The last finite point inside the visible X window.
  lastVisible,

  /// The first finite point inside the visible X window.
  firstVisible,

  /// The highest finite visible value.
  maximumVisible,

  /// The lowest finite visible value.
  minimumVisible,

  /// The series value at [SeriesCalloutSpec.anchorX].
  xValue,
}

/// Connector geometry between a series anchor and its callout label.
enum SeriesCalloutConnector { straight, elbow }

/// How resolved callout labels occupy their shared vertical lane.
enum SeriesCalloutPacking {
  /// Keep labels at their exact anchor positions and hide lower-priority
  /// labels that would collide.
  ///
  /// This is useful for moving-frontier charts where displacing a label would
  /// imply that it belongs to a different data value.
  hideCollisions,

  /// Keep each label as close as possible to its own series anchor.
  followAnchors,

  /// Keep labels together with exactly the configured minimum gap.
  compact,
}

/// Per-series override for [SeriesCalloutConfig].
@ChartSurface(
  clearFlags: {
    'show': 'clearShow',
    'label': 'clearLabel',
    'anchor': 'clearAnchor',
    'anchorX': 'clearAnchorX',
    'color': 'clearColor',
    'textStyle': 'clearTextStyle',
    'backgroundColor': 'clearBackgroundColor',
    'borderColor': 'clearBorderColor',
    'connectorWidth': 'clearConnectorWidth',
    'connectorOpacity': 'clearConnectorOpacity',
    'connectorGlow': 'clearConnectorGlow',
    'backgroundOpacity': 'clearBackgroundOpacity',
    'borderWidth': 'clearBorderWidth',
    'borderRadius': 'clearBorderRadius',
  },
)
@immutable
class SeriesCalloutSpec {
  const SeriesCalloutSpec({
    this.show,
    this.label,
    this.anchor,
    this.anchorX,
    this.priority = 0,
    this.color,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
    this.connectorWidth,
    this.connectorOpacity,
    this.connectorGlow,
    this.backgroundOpacity,
    this.borderWidth,
    this.borderRadius,
  }) : assert(connectorWidth == null || connectorWidth > 0),
       assert(
         connectorOpacity == null ||
             (connectorOpacity >= 0 && connectorOpacity <= 1),
       ),
       assert(connectorGlow == null || connectorGlow >= 0),
       assert(
         backgroundOpacity == null ||
             (backgroundOpacity >= 0 && backgroundOpacity <= 1),
       ),
       assert(borderWidth == null || borderWidth >= 0),
       assert(borderRadius == null || borderRadius >= 0);

  /// Overrides whether this series participates in the callout lane.
  final bool? show;

  /// Label override. The series display name is used when null.
  final String? label;

  /// Anchor strategy override.
  final SeriesCalloutAnchor? anchor;

  /// Data X coordinate used when [anchor] is [SeriesCalloutAnchor.xValue].
  final double? anchorX;

  /// Higher-priority labels survive first when the lane cannot fit every label.
  final int priority;

  /// Connector and marker color override. The series color is used when null.
  final Color? color;

  /// Text style override merged over the global label style.
  final TextStyle? textStyle;

  /// Label background override.
  final Color? backgroundColor;

  /// Label border override.
  final Color? borderColor;

  /// Connector width override in logical pixels.
  final double? connectorWidth;

  /// Connector and anchor opacity override from 0 to 1.
  final double? connectorOpacity;

  /// Connector glow radius override in logical pixels.
  final double? connectorGlow;

  /// Label background opacity override from 0 to 1.
  final double? backgroundOpacity;

  /// Label border width override in logical pixels.
  final double? borderWidth;

  /// Label corner radius override in logical pixels.
  final double? borderRadius;

  SeriesCalloutSpec copyWith({
    bool? show,
    String? label,
    SeriesCalloutAnchor? anchor,
    double? anchorX,
    int? priority,
    Color? color,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? connectorWidth,
    double? connectorOpacity,
    double? connectorGlow,
    double? backgroundOpacity,
    double? borderWidth,
    double? borderRadius,
    bool clearShow = false,
    bool clearLabel = false,
    bool clearAnchor = false,
    bool clearAnchorX = false,
    bool clearColor = false,
    bool clearTextStyle = false,
    bool clearBackgroundColor = false,
    bool clearBorderColor = false,
    bool clearConnectorWidth = false,
    bool clearConnectorOpacity = false,
    bool clearConnectorGlow = false,
    bool clearBackgroundOpacity = false,
    bool clearBorderWidth = false,
    bool clearBorderRadius = false,
  }) => SeriesCalloutSpec(
    show: clearShow ? null : (show ?? this.show),
    label: clearLabel ? null : (label ?? this.label),
    anchor: clearAnchor ? null : (anchor ?? this.anchor),
    anchorX: clearAnchorX ? null : (anchorX ?? this.anchorX),
    priority: priority ?? this.priority,
    color: clearColor ? null : (color ?? this.color),
    textStyle: clearTextStyle ? null : (textStyle ?? this.textStyle),
    backgroundColor: clearBackgroundColor
        ? null
        : (backgroundColor ?? this.backgroundColor),
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    connectorWidth: clearConnectorWidth
        ? null
        : (connectorWidth ?? this.connectorWidth),
    connectorOpacity: clearConnectorOpacity
        ? null
        : (connectorOpacity ?? this.connectorOpacity),
    connectorGlow: clearConnectorGlow
        ? null
        : (connectorGlow ?? this.connectorGlow),
    backgroundOpacity: clearBackgroundOpacity
        ? null
        : (backgroundOpacity ?? this.backgroundOpacity),
    borderWidth: clearBorderWidth ? null : (borderWidth ?? this.borderWidth),
    borderRadius: clearBorderRadius
        ? null
        : (borderRadius ?? this.borderRadius),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesCalloutSpec &&
          other.show == show &&
          other.label == label &&
          other.anchor == anchor &&
          other.anchorX == anchorX &&
          other.priority == priority &&
          other.color == color &&
          other.textStyle == textStyle &&
          other.backgroundColor == backgroundColor &&
          other.borderColor == borderColor &&
          other.connectorWidth == connectorWidth &&
          other.connectorOpacity == connectorOpacity &&
          other.connectorGlow == connectorGlow &&
          other.backgroundOpacity == backgroundOpacity &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(
    show,
    label,
    anchor,
    anchorX,
    priority,
    color,
    textStyle,
    backgroundColor,
    borderColor,
    connectorWidth,
    connectorOpacity,
    connectorGlow,
    backgroundOpacity,
    borderWidth,
    borderRadius,
  );
}

/// Global policy and styling for collision-aware series label callouts.
///
/// Callouts are disabled by default. When enabled, every supported visible
/// series participates unless its [series] override sets `show: false`.
@ChartSurface(
  clearFlags: {
    'anchorX': 'clearAnchorX',
    'connectorColor': 'clearConnectorColor',
    'backgroundColor': 'clearBackgroundColor',
    'borderColor': 'clearBorderColor',
    'panelBackgroundColor': 'clearPanelBackgroundColor',
    'panelBorderColor': 'clearPanelBorderColor',
  },
)
@immutable
class SeriesCalloutConfig {
  const SeriesCalloutConfig({
    this.enabled = false,
    this.showByDefault = true,
    this.side = SeriesCalloutSide.right,
    this.lanePlacement = SeriesCalloutLanePlacement.plotEdge,
    this.anchor = SeriesCalloutAnchor.lastVisible,
    this.anchorX,
    this.connector = SeriesCalloutConnector.elbow,
    this.packing = SeriesCalloutPacking.followAnchors,
    this.laneWidth = 156,
    this.inset = 8,
    this.minimumGap = 6,
    this.maximumVisible = 12,
    this.collisionFadeDuration = const Duration(milliseconds: 180),
    this.connectorColor,
    this.connectorWidth = 1.25,
    this.connectorOpacity = 1,
    this.connectorGlow = 0,
    this.anchorRadius = 3,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.labelStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    this.backgroundColor,
    this.backgroundOpacity = 1,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 5,
    this.panelBackgroundColor,
    this.panelOpacity = 1,
    this.panelBorderColor,
    this.panelBorderWidth = 0,
    this.panelBorderRadius = 6,
    this.panelPadding = const EdgeInsets.all(6),
    this.series = const {},
  }) : assert(laneWidth > 0),
       assert(inset >= 0),
       assert(minimumGap >= 0),
       assert(maximumVisible > 0),
       assert(connectorWidth > 0),
       assert(connectorOpacity >= 0 && connectorOpacity <= 1),
       assert(connectorGlow >= 0),
       assert(anchorRadius >= 0),
       assert(backgroundOpacity >= 0 && backgroundOpacity <= 1),
       assert(borderWidth >= 0),
       assert(borderRadius >= 0),
       assert(panelOpacity >= 0 && panelOpacity <= 1),
       assert(panelBorderWidth >= 0),
       assert(panelBorderRadius >= 0);

  final bool enabled;
  final bool showByDefault;
  final SeriesCalloutSide side;
  final SeriesCalloutLanePlacement lanePlacement;
  final SeriesCalloutAnchor anchor;
  final double? anchorX;
  final SeriesCalloutConnector connector;
  final SeriesCalloutPacking packing;
  final double laneWidth;
  final double inset;
  final double minimumGap;
  final int maximumVisible;

  /// Time used to fade labels when collision acceptance changes.
  ///
  /// Set to [Duration.zero] to switch visibility immediately. Ambient reduced
  /// motion also bypasses this transition.
  final Duration collisionFadeDuration;

  /// Fixed connector color. Null inherits each series color.
  final Color? connectorColor;
  final double connectorWidth;
  final double connectorOpacity;
  final double connectorGlow;
  final double anchorRadius;
  final EdgeInsets labelPadding;
  final TextStyle labelStyle;
  final Color? backgroundColor;
  final double backgroundOpacity;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color? panelBackgroundColor;
  final double panelOpacity;
  final Color? panelBorderColor;
  final double panelBorderWidth;
  final double panelBorderRadius;

  /// Space between the content-sized lane panel and its resolved labels.
  final EdgeInsets panelPadding;

  /// Overrides keyed by stable [ChartSeries.id].
  final Map<String, SeriesCalloutSpec> series;

  SeriesCalloutSpec specFor(String seriesId) =>
      series[seriesId] ?? const SeriesCalloutSpec();

  bool showsSeries(String seriesId) =>
      enabled && (specFor(seriesId).show ?? showByDefault);

  SeriesCalloutConfig copyWith({
    bool? enabled,
    bool? showByDefault,
    SeriesCalloutSide? side,
    SeriesCalloutLanePlacement? lanePlacement,
    SeriesCalloutAnchor? anchor,
    double? anchorX,
    SeriesCalloutConnector? connector,
    SeriesCalloutPacking? packing,
    double? laneWidth,
    double? inset,
    double? minimumGap,
    int? maximumVisible,
    Duration? collisionFadeDuration,
    Color? connectorColor,
    double? connectorWidth,
    double? connectorOpacity,
    double? connectorGlow,
    double? anchorRadius,
    EdgeInsets? labelPadding,
    TextStyle? labelStyle,
    Color? backgroundColor,
    double? backgroundOpacity,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? panelBackgroundColor,
    double? panelOpacity,
    Color? panelBorderColor,
    double? panelBorderWidth,
    double? panelBorderRadius,
    EdgeInsets? panelPadding,
    Map<String, SeriesCalloutSpec>? series,
    bool clearAnchorX = false,
    bool clearConnectorColor = false,
    bool clearBackgroundColor = false,
    bool clearBorderColor = false,
    bool clearPanelBackgroundColor = false,
    bool clearPanelBorderColor = false,
  }) => SeriesCalloutConfig(
    enabled: enabled ?? this.enabled,
    showByDefault: showByDefault ?? this.showByDefault,
    side: side ?? this.side,
    lanePlacement: lanePlacement ?? this.lanePlacement,
    anchor: anchor ?? this.anchor,
    anchorX: clearAnchorX ? null : (anchorX ?? this.anchorX),
    connector: connector ?? this.connector,
    packing: packing ?? this.packing,
    laneWidth: laneWidth ?? this.laneWidth,
    inset: inset ?? this.inset,
    minimumGap: minimumGap ?? this.minimumGap,
    maximumVisible: maximumVisible ?? this.maximumVisible,
    collisionFadeDuration: collisionFadeDuration ?? this.collisionFadeDuration,
    connectorColor: clearConnectorColor
        ? null
        : (connectorColor ?? this.connectorColor),
    connectorWidth: connectorWidth ?? this.connectorWidth,
    connectorOpacity: connectorOpacity ?? this.connectorOpacity,
    connectorGlow: connectorGlow ?? this.connectorGlow,
    anchorRadius: anchorRadius ?? this.anchorRadius,
    labelPadding: labelPadding ?? this.labelPadding,
    labelStyle: labelStyle ?? this.labelStyle,
    backgroundColor: clearBackgroundColor
        ? null
        : (backgroundColor ?? this.backgroundColor),
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    panelBackgroundColor: clearPanelBackgroundColor
        ? null
        : (panelBackgroundColor ?? this.panelBackgroundColor),
    panelOpacity: panelOpacity ?? this.panelOpacity,
    panelBorderColor: clearPanelBorderColor
        ? null
        : (panelBorderColor ?? this.panelBorderColor),
    panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
    panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
    panelPadding: panelPadding ?? this.panelPadding,
    series: series ?? this.series,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesCalloutConfig &&
          other.enabled == enabled &&
          other.showByDefault == showByDefault &&
          other.side == side &&
          other.lanePlacement == lanePlacement &&
          other.anchor == anchor &&
          other.anchorX == anchorX &&
          other.connector == connector &&
          other.packing == packing &&
          other.laneWidth == laneWidth &&
          other.inset == inset &&
          other.minimumGap == minimumGap &&
          other.maximumVisible == maximumVisible &&
          other.collisionFadeDuration == collisionFadeDuration &&
          other.connectorColor == connectorColor &&
          other.connectorWidth == connectorWidth &&
          other.connectorOpacity == connectorOpacity &&
          other.connectorGlow == connectorGlow &&
          other.anchorRadius == anchorRadius &&
          other.labelPadding == labelPadding &&
          other.labelStyle == labelStyle &&
          other.backgroundColor == backgroundColor &&
          other.backgroundOpacity == backgroundOpacity &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.panelBackgroundColor == panelBackgroundColor &&
          other.panelOpacity == panelOpacity &&
          other.panelBorderColor == panelBorderColor &&
          other.panelBorderWidth == panelBorderWidth &&
          other.panelBorderRadius == panelBorderRadius &&
          other.panelPadding == panelPadding &&
          _mapsEqual(other.series, series);

  @override
  int get hashCode => Object.hashAll([
    enabled,
    showByDefault,
    side,
    lanePlacement,
    anchor,
    anchorX,
    connector,
    packing,
    laneWidth,
    inset,
    minimumGap,
    maximumVisible,
    collisionFadeDuration,
    connectorColor,
    connectorWidth,
    connectorOpacity,
    connectorGlow,
    anchorRadius,
    labelPadding,
    labelStyle,
    backgroundColor,
    backgroundOpacity,
    borderColor,
    borderWidth,
    borderRadius,
    panelBackgroundColor,
    panelOpacity,
    panelBorderColor,
    panelBorderWidth,
    panelBorderRadius,
    panelPadding,
    Object.hashAllUnordered(
      series.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  ]);

  static bool _mapsEqual(
    Map<String, SeriesCalloutSpec> a,
    Map<String, SeriesCalloutSpec> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
