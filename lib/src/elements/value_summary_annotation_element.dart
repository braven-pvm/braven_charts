// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../interaction/core/element_types.dart';
import '../models/chart_overlay_placement.dart';
import 'value_summary_overlay_element.dart';

/// The annotation-style presentation of the Cartesian value summary.
///
/// Renders the exact same policy-resolved content as the fixed overlay
/// (shared [ValueSummaryPanelElement] machinery) at a plot-screen-space
/// anchor + offset, and — unlike the overlay — can be interactive:
///
/// * When [isDraggable], [hitTest] is true strictly within the painted panel
///   bounds, so the panel wins the pointer inside itself and never steals a
///   hit anywhere else. The element never enters the chart's element list or
///   spatial index; the render box consults it explicitly before the spatial
///   query, and `EventHandlerManager` owns the live drag exactly like the
///   other draggable annotations.
/// * When [clampToPlot], the placement-resolved origin is clamped at paint
///   time so the panel stays inside the plot across drags, keyboard nudges,
///   and plot resizes — regardless of whether the effective placement came
///   from configuration or from a drag override.
///
/// The layout max-width intentionally ignores the placement offset (unlike
/// the fixed overlay): a drag changes the offset every frame, and shrinking
/// the available width with it would thrash the layout cache per pixel and
/// visibly reflow the panel mid-drag.
class ValueSummaryAnnotationElement extends ValueSummaryPanelElement {
  /// Creates an annotation-style summary element.
  ValueSummaryAnnotationElement({
    super.id = 'cartesian-value-summary-annotation',
    super.placement,
  });

  bool _draggable = false;
  bool _clampToPlot = true;

  /// Whether the panel is clamped inside the plot after drags and resizes.
  bool get clampToPlot => _clampToPlot;

  /// Updates the interaction behavior flags from the active presentation.
  ///
  /// Returns true (and marks [needsRepaint]) only when something changed.
  bool updateBehavior({required bool draggable, required bool clampToPlot}) {
    if (draggable == _draggable && clampToPlot == _clampToPlot) {
      return false;
    }
    _draggable = draggable;
    _clampToPlot = clampToPlot;
    markNeedsRepaint();
    return true;
  }

  /// Classified as an annotation: the panel behaves like the other draggable
  /// annotation overlays. Hit priority never actually competes with data
  /// elements — the render box consults this element explicitly (bounds-only
  /// [hitTest]) before the spatial-index query, so it wins within its bounds
  /// by construction and cannot steal data-point hits elsewhere.
  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  bool get isDraggable => _draggable;

  /// True only within the painted panel bounds, and only while draggable.
  @override
  bool hitTest(Offset position) =>
      _draggable && bounds != Rect.zero && bounds.contains(position);

  @override
  double layoutMaxWidth(Rect plotRect, Offset offset) => plotRect.width;

  @override
  Offset adjustOrigin(Offset origin, Size size, Rect plotRect) =>
      _clampToPlot ? _clampOrigin(origin, size, plotRect) : origin;

  /// Clamps a panel top-left so the panel rect stays inside the plot,
  /// preferring the top-left edges when the panel exceeds the plot.
  Offset clampOriginToPlot(Offset origin) {
    final plotRect = this.plotRect;
    if (plotRect == null || bounds == Rect.zero) return origin;
    return _clampOrigin(origin, bounds.size, plotRect);
  }

  static Offset _clampOrigin(Offset origin, Size size, Rect plotRect) {
    final maxLeft = math.max(plotRect.left, plotRect.right - size.width);
    final maxTop = math.max(plotRect.top, plotRect.bottom - size.height);
    return Offset(
      origin.dx.clamp(plotRect.left, maxLeft),
      origin.dy.clamp(plotRect.top, maxTop),
    );
  }

  /// Computes the anchor-relative [ChartOverlayPlacement] whose resolution
  /// paints the panel with its top-left at [origin] (plot-local space).
  ///
  /// This is the exact inverse of the paint-time placement resolution: the
  /// offset is recomputed relative to the configured [anchor] in the same
  /// interior-inset sign convention (and through the same RTL anchor
  /// resolution), so committing a drag round-trips pixel-exactly.
  ChartOverlayPlacement placementForOrigin(
    Offset origin, {
    required Alignment anchor,
  }) {
    final plotRect = this.plotRect ?? Rect.zero;
    final size = bounds.size;
    final resolvedAnchor = AlignmentDirectional(
      anchor.x,
      anchor.y,
    ).resolve(textDirection);
    final anchoredTopLeft = resolvedAnchor.inscribe(size, plotRect).topLeft;
    final rawDx = origin.dx - anchoredTopLeft.dx;
    final rawDy = origin.dy - anchoredTopLeft.dy;
    return ChartOverlayPlacement(
      anchor: anchor,
      offset: Offset(
        resolvedAnchor.x > 0 ? -rawDx : rawDx,
        resolvedAnchor.y > 0 ? -rawDy : rawDy,
      ),
    );
  }
}
