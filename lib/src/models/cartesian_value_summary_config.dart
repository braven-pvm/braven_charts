// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Public configuration contract for the Cartesian value summary.
///
/// The value summary keeps the current policy-resolved datum visible in a
/// persistent panel — either a fixed overlay anchored inside the plot or an
/// optionally draggable, annotation-style panel — fed by the chart's shared
/// tracking snapshot. It is configured through
/// `InteractionConfig.valueSummary` and is independent of the crosshair
/// tracking panel, point tooltip, axis value labels, and intersection
/// markers: enabling one never implicitly enables another.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, ValueChanged, internal;

import '../artifacts/chart_view_state.dart' show ChartPointRef;
import '../interaction/core/cartesian_tracking_snapshot.dart'
    show CartesianTrackingSnapshot;
import '../meta/chart_surface.dart';
import 'cartesian_value_summary_style.dart';
import 'chart_overlay_placement.dart';

/// How the value summary chooses the datum it displays.
///
/// Each policy is a deterministic precedence chain. When a source in the
/// chain is unavailable (no active tracking, no valid pin), resolution falls
/// through to the next source; when no source yields a valid datum the
/// summary is hidden. An explicit pin that references a removed point is
/// cleared and resolution continues through the chain.
enum CartesianValueSummaryValuePolicy {
  /// Show the active tracking snapshot, otherwise the latest visible datum.
  trackingThenLatest,

  /// Show the active tracking snapshot, otherwise the first visible datum.
  trackingThenFirst,

  /// Show the focused/selected point, then active tracking, then the latest
  /// visible datum.
  selectionThenTrackingThenLatest,

  /// Show the explicitly pinned point, then active tracking, then the latest
  /// visible datum.
  pinnedThenTrackingThenLatest,

  /// Show only an explicitly pinned point; hide the summary otherwise.
  explicitOnly,
}

/// What the value summary's live-tracking rows report while the cursor sits
/// between samples.
///
/// The mode governs only the tracking stage of the value policy chain; the
/// pinned, selection, and latest/first fallback stages always report actual
/// data points.
enum CartesianValueSummaryValueMode {
  /// Track the interpolated curve (the default, matching the crosshair).
  ///
  /// The summary reuses the crosshair's value resolution as-is: with
  /// `CrosshairConfig.interpolateValues` true (its default) the rows carry
  /// values computed at the exact cursor X between samples; with it false
  /// they snap to the nearest datum. Zero additional resolutions in either
  /// case.
  interpolated,

  /// Snap the rows to the nearest actual data point, regardless of the
  /// crosshair's interpolation setting.
  ///
  /// Rows report the real sample (`isInterpolated` false, the datum's own
  /// formatted values). While the crosshair simultaneously tracks with
  /// interpolation enabled, the summary resolves through a dedicated
  /// memoized resolver — one extra resolution per cursor change, never per
  /// repaint; in every other combination the shared resolution is reused
  /// with no extra cost.
  dataPoints,
}

/// How the value summary is presented inside the plot.
///
/// The hierarchy is sealed: the two concrete kinds are
/// [CartesianValueSummaryOverlay] and [CartesianValueSummaryAnnotation], and
/// switches over a presentation are exhaustive without a wildcard. Both kinds
/// share the same content, style resolution, and semantics; only placement
/// behavior differs.
@ChartSurface(
  sealedVariants: [
    'CartesianValueSummaryOverlay',
    'CartesianValueSummaryAnnotation',
  ],
)
sealed class CartesianValueSummaryPresentation {
  const CartesianValueSummaryPresentation._();

  /// A fixed panel anchored to the plot interior.
  ///
  /// The overlay does not move with pan or zoom and always passes pointer
  /// input through to the chart beneath it.
  const factory CartesianValueSummaryPresentation.overlay({
    ChartOverlayPlacement placement,
  }) = CartesianValueSummaryOverlay;

  /// An in-plot, annotation-style panel that can optionally be dragged.
  ///
  /// The panel's position is plot-screen space expressed as anchor + offset;
  /// it is not tied to a data coordinate. Dragging emits continuous visual
  /// updates and exactly one committed placement through
  /// [CartesianValueSummaryConfig.onPlacementChanged].
  const factory CartesianValueSummaryPresentation.annotation({
    ChartOverlayPlacement placement,
    bool draggable,
    bool clampToPlot,
  }) = CartesianValueSummaryAnnotation;
}

/// The fixed-overlay presentation of the value summary.
@chartSurface
final class CartesianValueSummaryOverlay
    extends CartesianValueSummaryPresentation {
  /// Creates a fixed overlay presentation.
  const CartesianValueSummaryOverlay({
    this.placement = ChartOverlayPlacement.topLeft,
  }) : super._();

  /// Where the overlay is anchored inside the plot area.
  final ChartOverlayPlacement placement;

  /// Creates a copy with the given fields replaced.
  CartesianValueSummaryOverlay copyWith({ChartOverlayPlacement? placement}) =>
      CartesianValueSummaryOverlay(placement: placement ?? this.placement);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryOverlay && other.placement == placement;

  @override
  int get hashCode => Object.hash('overlay', placement);

  @override
  String toString() => 'CartesianValueSummaryOverlay(placement: $placement)';
}

/// The annotation-style presentation of the value summary.
@chartSurface
final class CartesianValueSummaryAnnotation
    extends CartesianValueSummaryPresentation {
  /// Creates an annotation-style presentation.
  const CartesianValueSummaryAnnotation({
    this.placement = ChartOverlayPlacement.topLeft,
    this.draggable = false,
    this.clampToPlot = true,
  }) : super._();

  /// Where the panel sits, as an anchor and offset in plot-screen space.
  final ChartOverlayPlacement placement;

  /// Whether the panel can be dragged with the pointer or moved with the
  /// arrow keys while focused.
  final bool draggable;

  /// Whether the panel is clamped inside the plot after drags and resizes.
  final bool clampToPlot;

  /// Creates a copy with the given fields replaced.
  CartesianValueSummaryAnnotation copyWith({
    ChartOverlayPlacement? placement,
    bool? draggable,
    bool? clampToPlot,
  }) => CartesianValueSummaryAnnotation(
    placement: placement ?? this.placement,
    draggable: draggable ?? this.draggable,
    clampToPlot: clampToPlot ?? this.clampToPlot,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryAnnotation &&
          other.placement == placement &&
          other.draggable == draggable &&
          other.clampToPlot == clampToPlot;

  @override
  int get hashCode => Object.hash('annotation', placement, draggable, clampToPlot);

  @override
  String toString() =>
      'CartesianValueSummaryAnnotation(placement: $placement, '
      'draggable: $draggable, clampToPlot: $clampToPlot)';
}

/// Builds a summary content model from a resolved tracking snapshot.
///
/// The builder receives the immutable [CartesianTrackingSnapshot] published
/// by the chart's tracking pipeline and returns the rows to display. It must
/// be a pure function of the snapshot; it is invoked only when a new snapshot
/// is published, never per pointer pixel.
typedef CartesianValueSummaryRowBuilder =
    CartesianValueSummaryContentModel Function(
      CartesianTrackingSnapshot snapshot,
    );

/// What the value summary displays for a resolved datum.
///
/// The hierarchy is sealed: the two concrete kinds are
/// [CartesianValueSummaryAutomaticContent] and
/// [CartesianValueSummaryBuilderContent], and switches over a content value
/// are exhaustive without a wildcard.
@ChartSurface(
  sealedVariants: [
    'CartesianValueSummaryAutomaticContent',
    'CartesianValueSummaryBuilderContent',
  ],
)
sealed class CartesianValueSummaryContent {
  const CartesianValueSummaryContent._();

  /// Family-specific rows generated automatically from the snapshot.
  ///
  /// Line and Area series produce name, X, and formatted Y with unit; Bar
  /// produces category and value with group context; Scatter adds its active
  /// encodings; Candlestick produces OHLC, change, and direction rows. Mixed
  /// charts produce one grouped section per visible series.
  const factory CartesianValueSummaryContent.automatic({
    bool includeTrends,
    bool includeHiddenSeries,
  }) = CartesianValueSummaryAutomaticContent;

  /// Application-defined rows produced by [builder].
  ///
  /// Builder content is non-portable unless [descriptorId] names a registered
  /// runtime content descriptor: artifacts and generated Source emit an
  /// omitted-dependency diagnostic for unregistered builders and never
  /// serialize the rendered text.
  const factory CartesianValueSummaryContent.builder(
    CartesianValueSummaryRowBuilder builder, {
    String? descriptorId,
  }) = CartesianValueSummaryBuilderContent;
}

/// Automatic, family-aware summary content.
@chartSurface
final class CartesianValueSummaryAutomaticContent
    extends CartesianValueSummaryContent {
  /// Creates automatic content.
  const CartesianValueSummaryAutomaticContent({
    this.includeTrends = false,
    this.includeHiddenSeries = false,
  }) : super._();

  /// Whether rows derived from trend annotations are included.
  final bool includeTrends;

  /// Whether series hidden from the plot still contribute rows.
  final bool includeHiddenSeries;

  /// Creates a copy with the given fields replaced.
  CartesianValueSummaryAutomaticContent copyWith({
    bool? includeTrends,
    bool? includeHiddenSeries,
  }) => CartesianValueSummaryAutomaticContent(
    includeTrends: includeTrends ?? this.includeTrends,
    includeHiddenSeries: includeHiddenSeries ?? this.includeHiddenSeries,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryAutomaticContent &&
          other.includeTrends == includeTrends &&
          other.includeHiddenSeries == includeHiddenSeries;

  @override
  int get hashCode => Object.hash('automatic', includeTrends, includeHiddenSeries);

  @override
  String toString() =>
      'CartesianValueSummaryAutomaticContent(includeTrends: $includeTrends, '
      'includeHiddenSeries: $includeHiddenSeries)';
}

/// Application-defined summary content produced by a runtime builder.
final class CartesianValueSummaryBuilderContent
    extends CartesianValueSummaryContent {
  /// Creates builder content.
  const CartesianValueSummaryBuilderContent(this.builder, {this.descriptorId})
    : super._();

  /// Builds the content model for each published snapshot.
  final CartesianValueSummaryRowBuilder builder;

  /// Optional id of a registered runtime content descriptor that makes this
  /// content portable through artifacts and generated Source.
  final String? descriptorId;

  /// Equality follows the `TooltipConfig.customBuilder` precedent: the
  /// [builder] function is compared by reference alongside [descriptorId].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryBuilderContent &&
          other.builder == builder &&
          other.descriptorId == descriptorId;

  @override
  int get hashCode => Object.hash('builder', builder, descriptorId);

  @override
  String toString() =>
      'CartesianValueSummaryBuilderContent(descriptorId: $descriptorId)';
}

/// The semantic content the summary renderer displays for one resolved datum.
///
/// The renderer consumes these typed rows rather than a preformatted block of
/// text, so both presentations, semantics, and theming share one model.
class CartesianValueSummaryContentModel {
  /// Creates a content model.
  const CartesianValueSummaryContentModel({
    this.title,
    this.subtitle,
    this.accentColor,
    this.rows = const [],
  });

  /// Optional panel title, typically the series or symbol name.
  final String? title;

  /// Optional secondary line, typically the resolved X label.
  final String? subtitle;

  /// Optional accent color for the panel's series indicator.
  final Color? accentColor;

  /// The labelled values to display, in meaningful source order.
  final List<CartesianValueSummaryRow> rows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryContentModel &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.accentColor == accentColor &&
          _rowsEqual(other.rows, rows);

  @override
  int get hashCode =>
      Object.hash(title, subtitle, accentColor, Object.hashAll(rows));

  @override
  String toString() =>
      'CartesianValueSummaryContentModel(title: $title, subtitle: $subtitle, '
      'rows: ${rows.length})';
}

bool _rowsEqual(
  List<CartesianValueSummaryRow> left,
  List<CartesianValueSummaryRow> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

/// One labelled value inside a summary panel.
class CartesianValueSummaryRow {
  /// Creates a summary row.
  const CartesianValueSummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.semanticValue,
  });

  /// The row label, for example `Close` or a series name.
  final String label;

  /// The display-ready formatted value, including any unit.
  final String value;

  /// Optional row accent, typically the series color.
  final Color? color;

  /// Optional screen-reader value announced instead of [value].
  final String? semanticValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryRow &&
          other.label == label &&
          other.value == value &&
          other.color == color &&
          other.semanticValue == semanticValue;

  @override
  int get hashCode => Object.hash(label, value, color, semanticValue);

  @override
  String toString() => 'CartesianValueSummaryRow($label: $value)';
}

/// Programmatic control surface for the value summary.
///
/// The controller is deliberately small: it pins and unpins a datum by stable
/// [ChartPointRef] identity and resets a dragged panel to its configured
/// placement. It never accepts formatted strings, paints the panel, or owns
/// placement — the immutable widget configuration remains authoritative, and
/// committed drags are surfaced through
/// [CartesianValueSummaryConfig.onPlacementChanged].
abstract interface class CartesianValueSummaryController {
  /// The currently pinned point, or null when nothing is pinned.
  ChartPointRef? get pinnedPoint;

  /// Pins [point] so the summary keeps showing it per the active policy.
  void pin(ChartPointRef point);

  /// Clears the explicit pin; resolution falls through the active policy.
  void clearPin();

  /// Restores the panel to the placement in the widget configuration.
  void resetPlacement();
}

/// A ready-to-use, listenable [CartesianValueSummaryController].
///
/// Applications may implement [CartesianValueSummaryController] themselves,
/// but the chart observes controllers only as a generic [ChangeNotifier]-style
/// listenable: a plain notification carries no verb, so a custom
/// implementation's [resetPlacement] cannot reach the chart. This class
/// carries the internal reset handshake the chart consumes on notification —
/// use it (or subclass it) whenever [resetPlacement] must actually restore a
/// dragged annotation-style panel to its configured placement.
class DefaultCartesianValueSummaryController extends ChangeNotifier
    implements CartesianValueSummaryController {
  ChartPointRef? _pinnedPoint;
  bool _resetPlacementRequested = false;

  @override
  ChartPointRef? get pinnedPoint => _pinnedPoint;

  @override
  void pin(ChartPointRef point) {
    if (_pinnedPoint == point) return;
    _pinnedPoint = point;
    notifyListeners();
  }

  @override
  void clearPin() {
    if (_pinnedPoint == null) return;
    _pinnedPoint = null;
    notifyListeners();
  }

  @override
  void resetPlacement() {
    _resetPlacementRequested = true;
    notifyListeners();
  }

  /// Consumes a pending [resetPlacement] request.
  ///
  /// Chart-internal handshake: the value summary pipeline calls this on
  /// every controller notification and clears the flag, so one request
  /// produces exactly one placement reset.
  @internal
  bool consumeResetPlacementRequest() {
    final requested = _resetPlacementRequested;
    _resetPlacementRequested = false;
    return requested;
  }
}

/// Configuration for the Cartesian value summary.
///
/// The summary defaults to disabled and has zero visual effect until
/// [enabled] is true. It applies to every built-in Cartesian family — Line,
/// Area, Bar, Scatter, and Candlestick — including multi-series and
/// multi-axis charts, and is independent of the crosshair panel, point
/// tooltip, and axis value labels.
///
/// Example:
/// ```dart
/// BravenChartPlus(
///   series: series,
///   interactionConfig: InteractionConfig(
///     valueSummary: CartesianValueSummaryConfig(
///       enabled: true,
///       presentation: CartesianValueSummaryPresentation.overlay(
///         placement: ChartOverlayPlacement.topLeft,
///       ),
///     ),
///   ),
/// )
/// ```
///
/// The fluent surface generates a variant helper per sealed factory, EXCEPT
/// for factories that take a function: `withBuilderContent` used to be the
/// only function-typed verb on the whole surface, and the config it minted
/// (`CartesianValueSummaryContent.builder`) is precisely the one artifacts
/// and generated Source refuse to serialize unless a REGISTERED
/// `descriptorId` accompanies it — something no generated signature can
/// enforce. Call `withContent(CartesianValueSummaryContent.builder(fn,
/// descriptorId: id))` instead, where that requirement is documented at the
/// point of use.
@chartSurface
class CartesianValueSummaryConfig {
  /// Creates a value summary configuration.
  const CartesianValueSummaryConfig({
    this.enabled = false,
    this.presentation = const CartesianValueSummaryPresentation.overlay(),
    this.valuePolicy = CartesianValueSummaryValuePolicy.trackingThenLatest,
    this.valueMode = CartesianValueSummaryValueMode.interpolated,
    this.content = const CartesianValueSummaryContent.automatic(),
    this.style = const CartesianValueSummaryStyle(),
    this.showSeriesAccent = true,
    this.announceChanges = false,
    this.onPlacementChanged,
    this.controller,
  });

  /// Whether the value summary is shown. Defaults to false.
  final bool enabled;

  /// How the summary is presented inside the plot.
  final CartesianValueSummaryPresentation presentation;

  /// How the displayed datum is chosen.
  final CartesianValueSummaryValuePolicy valuePolicy;

  /// Whether tracked rows follow the interpolated curve or snap to actual
  /// data points. Defaults to [CartesianValueSummaryValueMode.interpolated].
  final CartesianValueSummaryValueMode valueMode;

  /// What the summary displays for the resolved datum.
  final CartesianValueSummaryContent content;

  /// Tri-state visual overrides resolved against the summary theme.
  final CartesianValueSummaryStyle style;

  /// Whether rows show a series accent mark next to their values.
  final bool showSeriesAccent;

  /// Whether screen readers announce summary changes.
  ///
  /// Defaults to false. When enabled, announcements are debounced by
  /// resolved-datum identity, never emitted per pointer pixel.
  final bool announceChanges;

  /// Called once per completed drag with the committed placement.
  ///
  /// Excluded from [operator ==] and [hashCode], following the
  /// `InteractionConfig` callback rule.
  final ValueChanged<ChartOverlayPlacement>? onPlacementChanged;

  /// Optional programmatic pin and placement control.
  ///
  /// Excluded from [operator ==] and [hashCode], following the
  /// `InteractionConfig` callback rule.
  final CartesianValueSummaryController? controller;

  /// Creates a copy with the given fields replaced.
  CartesianValueSummaryConfig copyWith({
    bool? enabled,
    CartesianValueSummaryPresentation? presentation,
    CartesianValueSummaryValuePolicy? valuePolicy,
    CartesianValueSummaryValueMode? valueMode,
    CartesianValueSummaryContent? content,
    CartesianValueSummaryStyle? style,
    bool? showSeriesAccent,
    bool? announceChanges,
    ValueChanged<ChartOverlayPlacement>? onPlacementChanged,
    CartesianValueSummaryController? controller,
  }) => CartesianValueSummaryConfig(
    enabled: enabled ?? this.enabled,
    presentation: presentation ?? this.presentation,
    valuePolicy: valuePolicy ?? this.valuePolicy,
    valueMode: valueMode ?? this.valueMode,
    content: content ?? this.content,
    style: style ?? this.style,
    showSeriesAccent: showSeriesAccent ?? this.showSeriesAccent,
    announceChanges: announceChanges ?? this.announceChanges,
    onPlacementChanged: onPlacementChanged ?? this.onPlacementChanged,
    controller: controller ?? this.controller,
  );

  /// Value equality over every configuration field except
  /// [onPlacementChanged] and [controller].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryConfig &&
          other.enabled == enabled &&
          other.presentation == presentation &&
          other.valuePolicy == valuePolicy &&
          other.valueMode == valueMode &&
          other.content == content &&
          other.style == style &&
          other.showSeriesAccent == showSeriesAccent &&
          other.announceChanges == announceChanges;

  @override
  int get hashCode => Object.hash(
    enabled,
    presentation,
    valuePolicy,
    valueMode,
    content,
    style,
    showSeriesAccent,
    announceChanges,
  );
}
