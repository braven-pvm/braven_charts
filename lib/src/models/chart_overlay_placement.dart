// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Offset;

import 'package:flutter/painting.dart' show Alignment;

/// An anchor-relative position for an overlay panel inside the plot area.
///
/// The [anchor] selects a point on the plot rectangle (for example
/// [Alignment.topLeft]) and [offset] displaces the panel from that point in
/// logical pixels. Because the position is expressed relative to an anchor
/// rather than as an absolute canvas offset, a placed panel stays stable
/// across plot resizes, axis-width changes, RTL resolution, and responsive
/// layouts. Dragging a panel updates the offset relative to its anchor.
class ChartOverlayPlacement {
  /// Creates a placement at [anchor], displaced by [offset] logical pixels.
  const ChartOverlayPlacement({required this.anchor, this.offset = Offset.zero});

  /// The point on the plot rectangle the panel is anchored to.
  ///
  /// Resolved against the ambient text direction, so `topLeft` mirrors
  /// appropriately in RTL layouts.
  final Alignment anchor;

  /// Displacement from [anchor] in logical pixels.
  final Offset offset;

  /// The default placement: the top-left plot corner with a 12 pixel inset.
  static const topLeft = ChartOverlayPlacement(
    anchor: Alignment.topLeft,
    offset: Offset(12, 12),
  );

  /// Creates a copy with the given fields replaced.
  ChartOverlayPlacement copyWith({Alignment? anchor, Offset? offset}) =>
      ChartOverlayPlacement(
        anchor: anchor ?? this.anchor,
        offset: offset ?? this.offset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartOverlayPlacement &&
          other.anchor == anchor &&
          other.offset == offset;

  @override
  int get hashCode => Object.hash(anchor, offset);

  @override
  String toString() => 'ChartOverlayPlacement(anchor: $anchor, offset: $offset)';
}
