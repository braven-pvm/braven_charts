// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Internal marker identifying the subtree of one faceted panel.
///
/// Deliberately NOT exported from `braven_charts.dart`: this is a seam between
/// two widgets in `lib/src/grammar/`, not API. It exists because Dart privacy
/// is per-library, so `BravenFacetPlot` cannot reach a `_`-private flag on
/// `BravenPlot`, and adding a public constructor parameter to `BravenPlot`
/// would widen the package's surface for something no host may set.
library;

import 'package:flutter/widgets.dart';

/// Wraps the [BravenPlot] of one facet panel so the plot can tell it is one.
///
/// The only thing this changes is the Y-axis MOUNT. A facet panel's spec is
/// exactly the shape `BravenPlot`'s legacy single-axis mount claims — one
/// declared (or, under a shared Y range, one synthesized) axis, and no mark
/// naming it — so without this marker every faceted chart would silently
/// switch mounts.
///
/// It must not, because the two mounts do not render the same chart: a
/// widget-level `yAxis` honours `min`/`max` while the same axis reaching the
/// chart through each series' inline `yAxisConfig` does not. Faceting injects
/// its shared range as exactly that inline axis, so re-mounting a panel starts
/// applying a range the chart has never applied — measured at 11.94% of the
/// `grammar_faceting_fixed` golden, every panel switching from autoscale to
/// the shared 180..320 interval.
///
/// That the shared range does not reach the render is a real defect, and it is
/// a defect in the multi-axis render path, not in this seam. Fixing it is a
/// deliberate change to `FacetScales.fixed` with its own golden re-baseline, so
/// the seam is gated off here and the faceted render is left exactly as it was.
class FacetPanelScope extends InheritedWidget {
  /// Marks [child] as living inside one facet panel.
  const FacetPanelScope({required super.child, super.key});

  /// Whether [context] sits inside a facet panel.
  ///
  /// Reads the element tree WITHOUT registering a dependency: the answer is a
  /// structural fact that cannot change for a given plot, so a dependency would
  /// only add rebuild bookkeeping.
  static bool isPanel(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FacetPanelScope>() != null;

  @override
  bool updateShouldNotify(FacetPanelScope oldWidget) => false;
}
