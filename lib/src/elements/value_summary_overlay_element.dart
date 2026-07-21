// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/painting.dart';

import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../models/cartesian_value_summary_config.dart'
    show CartesianValueSummaryContentModel;
import '../models/chart_overlay_placement.dart';
import 'value_summary_layout.dart';

/// Shared state and painting for the two value summary presentations.
///
/// Both the fixed overlay and the annotation-style panel render the same
/// policy-resolved content through the shared [ValueSummaryLayout] at a
/// [ChartOverlayPlacement]-resolved position, so they stay visually
/// identical; only hit-testing and placement behavior differ per subclass.
///
/// The owning render box drives an element per frame:
///
/// 1. [updateEnvironment] with the current plot rect, ambient text direction,
///    and text scale (cheap; returns whether anything changed);
/// 2. [updateContent] with the policy-resolved content model and the
///    already-resolved effective style whenever the tracking pipeline
///    publishes a new snapshot (equality-guarded: unchanged content marks
///    nothing);
/// 3. [paint] during the foreground element pass — only when [needsRepaint]
///    reported a change does the feedback layer even need to repaint.
///
/// Placement is RTL-aware: the configured [ChartOverlayPlacement.anchor] is
/// treated as direction-relative by mapping it through [AlignmentDirectional]
/// (`Alignment.topLeft` resolves to the top-right plot corner under RTL), and
/// the placement offset displaces the panel toward the plot interior on each
/// anchored edge, so `ChartOverlayPlacement.topLeft`'s baked-in 12 pixel
/// offset stays a 12 pixel inset at every corner and in both directions.
abstract class ValueSummaryPanelElement extends ChartElement {
  /// Creates a summary panel element.
  ValueSummaryPanelElement({
    required this.id,
    ChartOverlayPlacement placement = ChartOverlayPlacement.topLeft,
  }) : _placement = placement;

  @override
  final String id;

  final ValueSummaryLayout _layout = ValueSummaryLayout();

  ChartOverlayPlacement _placement;
  CartesianValueSummaryContentModel? _model;
  ResolvedValueSummaryStyle? _style;
  Rect? _plotRect;
  TextDirection _textDirection = TextDirection.ltr;
  double _textScale = 1.0;
  Rect _bounds = Rect.zero;
  bool _needsRepaint = false;

  /// The effective anchor-relative placement being rendered.
  ChartOverlayPlacement get placement => _placement;

  /// Whether an accepted update requires a feedback-layer repaint.
  ///
  /// Cleared by [paint]; the render box checks this after feeding the
  /// element to decide whether the feedback layer must repaint at all.
  bool get needsRepaint => _needsRepaint;

  /// The plot rect the placement currently resolves against.
  @protected
  Rect? get plotRect => _plotRect;

  /// The ambient reading direction the anchor resolves against.
  @protected
  TextDirection get textDirection => _textDirection;

  /// Flags the element as needing a feedback-layer repaint.
  @protected
  void markNeedsRepaint() => _needsRepaint = true;

  /// Updates the anchor-relative placement.
  ///
  /// Returns true (and marks [needsRepaint]) only when it changed.
  bool updatePlacement(ChartOverlayPlacement placement) {
    if (placement == _placement) {
      return false;
    }
    _placement = placement;
    _needsRepaint = true;
    return true;
  }

  /// Updates the plot-frame inputs the placement resolves against.
  ///
  /// Returns true (and marks [needsRepaint]) only when something changed.
  bool updateEnvironment({
    required Rect plotRect,
    required TextDirection textDirection,
    double textScale = 1.0,
  }) {
    if (plotRect == _plotRect &&
        textDirection == _textDirection &&
        textScale == _textScale) {
      return false;
    }
    _plotRect = plotRect;
    _textDirection = textDirection;
    _textScale = textScale;
    _needsRepaint = true;
    return true;
  }

  /// Updates the displayed content and its resolved effective style.
  ///
  /// Both are compared by value: republishing an identical snapshot-derived
  /// model marks nothing, so raw pointer movement within the same snapped
  /// datum never triggers a repaint. Pass a null [model] to hide the panel
  /// (empty policy resolution).
  bool updateContent(
    CartesianValueSummaryContentModel? model,
    ResolvedValueSummaryStyle style,
  ) {
    if (model == _model && style == _style) {
      return false;
    }
    _model = model;
    _style = style;
    _needsRepaint = true;
    return true;
  }

  /// The last painted panel rect, or [Rect.zero] while hidden.
  @override
  Rect get bounds => _bounds;

  @override
  int get renderOrder => RenderOrder.valueSummary;

  @override
  bool get isSelected => false;

  @override
  bool get isHovered => false;

  @override
  bool get isSelectable => false;

  /// Maximum layout width for the panel content.
  ///
  /// The fixed overlay reserves the configured horizontal inset so the panel
  /// never exceeds the plot; presentations whose offset changes dynamically
  /// (dragging) override this so the layout cache is not thrashed per pixel.
  @protected
  double layoutMaxWidth(Rect plotRect, Offset offset) =>
      math.max(0.0, plotRect.width - offset.dx.abs());

  /// Hook to adjust the placement-resolved panel origin before painting.
  ///
  /// The base implementation returns [origin] unchanged; the annotation
  /// presentation clamps it into the plot when configured to.
  @protected
  Offset adjustOrigin(Offset origin, Size size, Rect plotRect) => origin;

  @override
  void paint(Canvas canvas, Size size) {
    _needsRepaint = false;
    final model = _model;
    final style = _style;
    final plotRect = _plotRect;
    if (model == null ||
        style == null ||
        plotRect == null ||
        model.rows.isEmpty) {
      _bounds = Rect.zero;
      return;
    }

    final offset = _placement.offset;
    final available = layoutMaxWidth(plotRect, offset);
    final result = _layout.layout(
      model,
      style,
      maxWidth: available,
      textScale: _textScale,
      textDirection: _textDirection,
    );
    if (result.size == Size.zero) {
      _bounds = Rect.zero;
      return;
    }

    // Direction-aware anchor: the configured Alignment's x is treated as
    // start-relative, so topLeft flips to the top-right corner under RTL.
    final resolvedAnchor = AlignmentDirectional(
      _placement.anchor.x,
      _placement.anchor.y,
    ).resolve(_textDirection);
    final anchored = resolvedAnchor.inscribe(result.size, plotRect);

    // The offset displaces the panel toward the plot interior on anchored
    // edges (sign-flipped when the resolved anchor sits on the far edge), so
    // a positive inset stays an inset at every corner.
    final dx = resolvedAnchor.x > 0 ? -offset.dx : offset.dx;
    final dy = resolvedAnchor.y > 0 ? -offset.dy : offset.dy;
    final origin = adjustOrigin(
      anchored.topLeft.translate(dx, dy),
      result.size,
      plotRect,
    );

    _bounds = origin & result.size;
    result.paint(canvas, origin);
  }

  @override
  void onSelect() {}

  @override
  void onDeselect() {}

  @override
  void onHoverEnter() {}

  @override
  void onHoverExit() {}

  /// Hover and selection state never restyles a summary panel, so the
  /// element returns itself unchanged.
  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) => this;
}

/// The fixed-overlay presentation of the Cartesian value summary.
///
/// A passive foreground element anchored to the plot interior through a
/// [ChartOverlayPlacement]. It never intercepts pointer input ([hitTest] is
/// always false), does not move with pan or zoom, and paints through the
/// shared [ValueSummaryPanelElement] machinery so both summary presentations
/// stay visually identical.
class ValueSummaryOverlayElement extends ValueSummaryPanelElement {
  /// Creates a fixed overlay summary element.
  ValueSummaryOverlayElement({
    super.id = 'cartesian-value-summary-overlay',
    super.placement,
  });

  /// Classified as a passive tooltip-band element: like the tooltip it is a
  /// display-only feedback surface with passive (zero) hit priority, and it
  /// must never win an interaction.
  @override
  ChartElementType get elementType => ChartElementType.tooltip;

  @override
  bool get isDraggable => false;

  /// Always false: the fixed overlay passes every pointer through to the
  /// chart beneath it.
  @override
  bool hitTest(Offset position) => false;
}
