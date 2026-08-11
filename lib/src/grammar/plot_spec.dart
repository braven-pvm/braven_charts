// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show listEquals;

import '../models/chart_theme.dart' show ChartTheme;
import '../models/grid_config.dart' show GridConfig;
import '../models/interaction_config.dart' show InteractionConfig;
import '../models/polar_chart_config.dart' show PolarChartConfig;
import '../models/radar_chart_config.dart' show RadarChartConfig;
import '../models/x_axis_config.dart' show XAxisConfig;
import '../models/y_axis_config.dart' show YAxisConfig;
import 'facet_spec.dart';
import 'mark.dart';

/// **Beta — work in progress; this API may change before a stable release.**
///
/// A complete, typed grammar-of-graphics specification over rows of type `T`.
///
/// A spec is DECLARATIVE and inert: it names data, geometries and coordinate
/// options, and nothing else. Turning it into the objects the render pipeline
/// understands is the job of `lower`, which produces ordinary
/// `ChartSeries`/`ChartAnnotation`/axis configs — the artifact codecs, Source
/// generation and Workbench are untouched and receive exactly what they
/// already know.
///
/// ```dart
/// PlotSpec<Ride>(
///   data: rides,
///   marks: [
///     LineMark(x: (r) => r.km, y: (r) => r.power, id: 'power'),
///     TrendMark(sourceMarkId: 'power'),
///   ],
///   yAxes: [YAxisConfig(position: YAxisPosition.left, label: 'W')],
/// )
/// ```
///
/// Every lowered chart takes the MULTI-AXIS path: [yAxes] defaults to a single
/// left axis when it is left empty, and the lowering always binds each series
/// to an explicit axis. The legacy single-axis path is never targeted.
class PlotSpec<T> {
  /// Creates a plot specification.
  const PlotSpec({
    required this.data,
    required this.marks,
    this.transposed = false,
    this.theme,
    this.interaction,
    this.xAxis,
    this.yAxes = const <YAxisConfig>[],
    this.grid,
    this.title,
    this.subtitle,
    this.showLegend,
    this.facet,
    this.polar,
    this.radar,
  });

  /// Rows every mark's accessors read from.
  final List<T> data;

  /// Geometries and derived statistics, in paint order.
  ///
  /// A mark without an explicit `id` is lowered as `mark-<index>` using its
  /// index in this list, counting [TrendMark]s.
  final List<Mark<T>> marks;

  /// Whether the Cartesian plane is transposed.
  ///
  /// Transposition is implemented in this package by horizontal bar geometry,
  /// which transposes the WHOLE chart. A transposed spec must therefore
  /// contain bar marks only; anything else is rejected with
  /// `GrammarDiagnosticCode.unsupportedTransposition` instead of rendering
  /// some geometries rotated and others not.
  final bool transposed;

  /// Optional theme handed to the chart unchanged.
  final ChartTheme? theme;

  /// Optional interaction configuration. Null lowers to
  /// `const InteractionConfig()`.
  final InteractionConfig? interaction;

  /// Optional X-axis configuration.
  final XAxisConfig? xAxis;

  /// Y-axis slots marks bind to through [Mark.yAxisId].
  ///
  /// An axis with an empty id is assigned `axis-<index>`. An empty list lowers
  /// to a single default left axis, `axis-0`.
  final List<YAxisConfig> yAxes;

  /// Optional grid configuration.
  ///
  /// Null lowers to the chart's default (`const GridConfig()`), which the
  /// artifact round-trip already reproduces by carrying no grid. A non-null,
  /// non-default grid is forwarded to `BravenChartPlus` unchanged.
  final GridConfig? grid;

  /// Optional chart title, forwarded to `BravenChartPlus` unchanged.
  final String? title;

  /// Optional chart subtitle, forwarded to `BravenChartPlus` unchanged.
  final String? subtitle;

  /// Whether the legend is shown.
  ///
  /// Null lowers to the chart's default (`true`); a non-null value is forwarded
  /// to `BravenChartPlus` unchanged.
  final bool? showLegend;

  /// Optional faceting configuration.
  ///
  /// Null is a single-panel chart — the default, behaving exactly as before.
  /// A non-null value makes this spec a small-multiples grid; it is rendered
  /// with `BravenFacetPlot` (or `BravenChart.buildFaceted()`), and
  /// `PlotSpec.lower()` / `BravenChart.build()` reject it.
  final FacetSpec<T>? facet;

  /// Optional plot-level polar configuration, shared across every polar mark.
  ///
  /// Honored only when every radial mark is a [PolarMark]; such a spec lowers
  /// null to `const PolarChartConfig()`. Setting it on ANY other spec —
  /// Cartesian, pie, donut, or a mixed radial family — raises
  /// `GrammarDiagnosticCode.polarConfigOnNonPolarSpec` rather than dropping it,
  /// so a misplaced `.polarConfig(...)` is never silently discarded. (A spec
  /// with no polar mark carries no polar configuration at all once lowered:
  /// `LoweredPlot.polarChartConfig` stays null.)
  final PolarChartConfig? polar;

  /// Optional plot-level Radar pane and axis configuration shared by every
  /// [RadarMark] profile. A Radar spec without one uses
  /// `const RadarChartConfig()`; non-Radar specs may not carry it.
  final RadarChartConfig? radar;

  /// A copy of this spec with [facet] cleared and everything else identical.
  ///
  /// `BravenFacetPlot` lowers each panel from a facet-cleared copy, so the
  /// per-panel lowering is exactly the single-panel lowering of the same marks.
  PlotSpec<T> facetCleared() => PlotSpec<T>(
    data: data,
    marks: marks,
    transposed: transposed,
    theme: theme,
    interaction: interaction,
    xAxis: xAxis,
    yAxes: yAxes,
    grid: grid,
    title: title,
    subtitle: subtitle,
    showLegend: showLegend,
    polar: polar,
    radar: radar,
  );

  /// Whether any mark is a radial geometry.
  ///
  /// A radial spec lowers through the dedicated radial branch of
  /// `spec.lower()`; a Cartesian spec never enters it.
  bool get isRadial => marks.any((mark) => mark is RadialMark<T>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlotSpec<T> &&
          listEquals(other.data, data) &&
          listEquals(other.marks, marks) &&
          other.transposed == transposed &&
          other.theme == theme &&
          other.interaction == interaction &&
          other.xAxis == xAxis &&
          listEquals(other.yAxes, yAxes) &&
          other.grid == grid &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.showLegend == showLegend &&
          other.facet == facet &&
          other.polar == polar &&
          other.radar == radar;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(data),
    Object.hashAll(marks),
    transposed,
    theme,
    interaction,
    xAxis,
    Object.hashAll(yAxes),
    grid,
    title,
    subtitle,
    showLegend,
    facet,
    polar,
    radar,
  );

  @override
  String toString() =>
      'PlotSpec(rows: ${data.length}, marks: ${marks.length}, '
      'transposed: $transposed)';
}
