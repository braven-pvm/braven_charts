import 'dart:async';

import 'package:flutter/material.dart';

import 'chart_data_point.dart';

/// Builds host-defined actions for one native chart context-menu invocation.
typedef ChartContextActionsBuilder =
    List<ChartContextAction> Function(
      BuildContext context,
      ChartContextInvocation invocation,
    );

/// Builds one optional compact action rendered over the chart viewport.
///
/// Returning null hides the button for the current state.
typedef ChartOverlayActionBuilder =
    ChartOverlayAction? Function(BuildContext context);

/// One host-defined command rendered as a compact in-chart button.
@immutable
class ChartOverlayAction {
  const ChartOverlayAction({
    required this.id,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.semanticLabel,
  }) : assert(id.length > 0),
       assert(tooltip.length > 0);

  /// Stable identity used by widget tests and assistive tooling.
  final String id;

  /// Short verb-and-noun description shown on hover or long press.
  final String tooltip;

  final IconData icon;
  final bool enabled;

  /// Optional assistive label when [tooltip] is not sufficiently descriptive.
  final String? semanticLabel;

  final FutureOr<void> Function() onPressed;
}

/// Layout and Material presentation for a compact in-chart action button.
@immutable
class ChartOverlayActionButtonConfig {
  const ChartOverlayActionButtonConfig({
    this.alignment = Alignment.topLeft,
    this.margin = const EdgeInsets.all(8),
    this.buttonSize = 48,
    this.iconSize = 20,
    this.style,
  }) : assert(buttonSize >= 48),
       assert(iconSize > 0),
       assert(iconSize <= buttonSize);

  /// Viewport corner or edge used by the button.
  final AlignmentGeometry alignment;

  /// Space between the button target and the chart viewport edge.
  final EdgeInsetsGeometry margin;

  /// Accessible pointer and touch target size.
  ///
  /// The minimum is 48 logical pixels even when [iconSize] is visually small.
  final double buttonSize;

  final double iconSize;

  /// Optional complete Material button override.
  ///
  /// When null, the current application theme provides a translucent surface,
  /// foreground, hover, focus, press, and disabled treatment. Non-null style
  /// properties override those defaults, so hosts can match their own button
  /// hierarchy without replacing the accessible target behavior.
  final ButtonStyle? style;
}

/// Input path that requested a chart context menu.
enum ChartContextInvocationSource {
  /// A mouse or trackpad secondary click.
  secondaryClick,

  /// The keyboard Context Menu key or Shift+F10.
  keyboard,

  /// An opt-in touch or stylus long-press.
  longPress,
}

/// Stable public target categories for a chart context-menu invocation.
enum ChartContextHitKind {
  /// No chart element was targeted.
  background,

  /// A rendered series was targeted without resolving one datum.
  series,

  /// One renderer-neutral datum was targeted.
  point,

  /// One package annotation was targeted.
  annotation,
}

/// Renderer-neutral target information for a chart context-menu invocation.
///
/// Private render elements are deliberately not exposed. Hosts can use stable
/// series, point, and annotation identity without depending on chart-family
/// geometry.
@immutable
class ChartContextHit {
  const ChartContextHit._({
    required this.kind,
    this.seriesId,
    this.pointIndex,
    this.sourcePointIndices = const <int>[],
    this.point,
    this.annotationId,
    this.annotationTypeId,
  });

  /// A chart-background target.
  const ChartContextHit.background()
    : this._(kind: ChartContextHitKind.background);

  /// A whole-series target.
  const ChartContextHit.series({required String seriesId})
    : this._(kind: ChartContextHitKind.series, seriesId: seriesId);

  /// A resolved data-point or grouped-datum target.
  const ChartContextHit.point({
    required String seriesId,
    required int pointIndex,
    required ChartDataPoint point,
    List<int> sourcePointIndices = const <int>[],
  }) : this._(
         kind: ChartContextHitKind.point,
         seriesId: seriesId,
         pointIndex: pointIndex,
         point: point,
         sourcePointIndices: sourcePointIndices,
       );

  /// A package annotation target.
  const ChartContextHit.annotation({
    required String annotationId,
    required String annotationTypeId,
  }) : this._(
         kind: ChartContextHitKind.annotation,
         annotationId: annotationId,
         annotationTypeId: annotationTypeId,
       );

  final ChartContextHitKind kind;
  final String? seriesId;
  final int? pointIndex;
  final List<int> sourcePointIndices;
  final ChartDataPoint? point;
  final String? annotationId;
  final String? annotationTypeId;
}

/// Capabilities that are valid for the current context-menu invocation.
@immutable
class ChartContextCapabilities {
  const ChartContextCapabilities({
    required this.annotationsAvailable,
    required this.canEditTargetAnnotation,
    required this.hasDataHit,
  });

  /// Whether this mounted chart can create annotations.
  final bool annotationsAvailable;

  /// Whether the current target is an editable package annotation.
  final bool canEditTargetAnnotation;

  /// Whether [ChartContextInvocation.hit] identifies a datum.
  final bool hasDataHit;
}

/// Complete, current context supplied to a host action builder.
@immutable
class ChartContextInvocation {
  const ChartContextInvocation({
    required this.localPosition,
    required this.globalPosition,
    required this.source,
    required this.hit,
    required this.capabilities,
  });

  /// Invocation position in chart-widget coordinates.
  final Offset localPosition;

  /// Invocation position in global overlay coordinates.
  final Offset globalPosition;

  final ChartContextInvocationSource source;
  final ChartContextHit hit;
  final ChartContextCapabilities capabilities;
}

/// Deterministic placement group for a chart context action.
enum ChartContextActionSection {
  /// Non-destructive commands specific to the current target.
  target,

  /// General host or chart commands.
  host,

  /// Package or host commands that create annotations.
  annotation,

  /// Destructive commands, rendered last.
  destructive,
}

/// One typed native chart context-menu command.
@immutable
class ChartContextAction {
  const ChartContextAction({
    required this.id,
    required this.label,
    required this.onSelected,
    this.icon,
    this.enabled = true,
    this.section = ChartContextActionSection.host,
    this.shortcutLabel,
    this.semanticLabel,
  }) : assert(id.length > 0),
       assert(label.length > 0);

  /// Stable ID unique within the effective menu.
  final String id;

  final String label;
  final IconData? icon;
  final bool enabled;
  final ChartContextActionSection section;
  final String? shortcutLabel;

  /// Optional assistive label when [label] alone is insufficient.
  final String? semanticLabel;

  /// Invoked only after the chart interaction coordinator has been released.
  final FutureOr<void> Function() onSelected;
}

/// Optional input and focus behavior for native chart context menus.
@immutable
class ChartContextMenuConfig {
  const ChartContextMenuConfig({
    this.enableLongPress = false,
    this.longPressDuration,
    this.restoreChartFocus = true,
  });

  /// Enables touch and stylus long-press as an accelerator.
  ///
  /// Defaults to false so existing pan, zoom, selection, and annotation
  /// gestures retain their current behavior.
  final bool enableLongPress;

  /// Overrides [GestureConfig.longPressTimeout] when non-null.
  final Duration? longPressDuration;

  /// Restores focus to the chart after the menu is dismissed.
  final bool restoreChartFocus;
}
