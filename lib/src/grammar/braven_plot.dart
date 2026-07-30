// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../braven_chart_plus.dart';
import '../controllers/chart_interaction_group_controller.dart';
import '../models/braven_chart_controller.dart';
import '../models/chart_series.dart';
import '../models/chart_state_config.dart';
import '../models/concentric_donut_config.dart';
import '../models/polar_chart_config.dart';
import 'facet_panel_scope.dart';
import 'grammar_diagnostics.dart';
import 'plot_lowering.dart';
import 'plot_spec.dart';
import 'series_axis_unbinding.dart';

/// Renders a [PlotSpec] as an ordinary Braven chart.
///
/// `BravenPlot` is a thin, stateless adapter: it lowers the spec with
/// [PlotSpecLowering.lower] and hands the resulting `ChartSeries`,
/// `ChartAnnotation`s and axis configs to [BravenChartPlus]. It owns no
/// rendering, no interaction and no state of its own, so a spec-built chart
/// and the hand-written chart it lowers to are the same chart — proven at the
/// config level by `plot_lowering_parity_test.dart` and at the artifact level
/// by `braven_plot_artifact_parity_test.dart`.
///
/// ```dart
/// BravenPlot<Ride>(
///   PlotSpec<Ride>(
///     data: rides,
///     marks: [
///       LineMark(x: (r) => r.km, y: (r) => r.power, id: 'power'),
///       TrendMark(sourceMarkId: 'power'),
///     ],
///   ),
/// )
/// ```
///
/// ## How the Y axis is mounted
///
/// The lowering attaches both `yAxisId` and `yAxisConfig` to every series,
/// which is what selects `BravenChartPlus`'s multi-axis path. That stays the
/// mount for every chart that genuinely has axes to tell apart — several
/// declared axes, or a mark that names the one it wants.
///
/// The one exception is the shape a config author spells with a widget-level
/// `yAxis`: exactly one declared axis, and no mark binding to it explicitly.
/// That chain IS the legacy single-axis chart, so it is mounted as one —
/// `yAxis:` set, series unbound — and the chart a chain produces is then the
/// same DOCUMENT as the config chart the chain was reversed from, not merely
/// one that renders the same. Without it every reversed single-axis chart
/// differs by `series[*].axisId` plus `inlineAxis` and cannot be gated by
/// document equality. This widget still does not EXPOSE a `yAxis` parameter:
/// the axis comes from the spec either way.
///
/// The visible consequence, and it is intended: a one-axis chain now renders
/// AS the legacy chart, Y-axis labels included. `AxisColorResolver` tints an
/// axis from the first series BOUND to it, and the legacy chart binds none, so
/// the tick and axis labels take the default grey instead of the series colour
/// — exactly what the config chart this chain reverses to has always drawn.
///
/// One exception to the exception: a panel of a [BravenFacetPlot] keeps the
/// multi-axis mount. Its spec has the legacy shape, but faceting delivers the
/// shared range `FacetScales.fixed` computes through the inline axis config,
/// and switching mounts would start applying a range the chart has never
/// applied. See `FacetPanelScope`.
///
/// ## Empty data
///
/// An empty `data` list is a runtime STATE — a filter cleared, a fetch returned
/// nothing — not an authoring mistake, so it must not throw out of a widget's
/// `build`. `BravenPlot` handles exactly [GrammarDiagnosticCode.emptyData] by
/// building the chart with no series, which is how every other entry point in
/// this package reaches the standard empty state; configure it through
/// [emptyStateConfig]. Every OTHER diagnostic — an empty `marks` list, an
/// unknown trend source, a channel without its encoding — is an authoring
/// mistake and still surfaces from `build`.
class BravenPlot<T> extends StatelessWidget {
  /// Creates a chart from [spec].
  const BravenPlot(
    this.spec, {
    super.key,
    this.bravenChartController,
    this.interactionGroupController,
    this.emptyStateConfig = const ChartEmptyStateConfig(),
  });

  /// The specification this plot renders.
  final PlotSpec<T> spec;

  /// Optional host handle for visibility, selection and artifact extraction.
  final BravenChartController? bravenChartController;

  /// Optional controller that synchronizes cursor and viewport across charts.
  final ChartInteractionGroupController? interactionGroupController;

  /// Presentation used when [PlotSpec.data] is empty.
  final ChartEmptyStateConfig emptyStateConfig;

  @override
  Widget build(BuildContext context) {
    LoweredPlot? lowered;
    try {
      lowered = spec.lower();
    } on GrammarSpecException catch (error) {
      if (error.code != GrammarDiagnosticCode.emptyData) rethrow;
    }

    // A chain declaring exactly one axis that no mark binds to explicitly is
    // the grammar's spelling of the legacy single-axis chart. Non-null here
    // means "mount it that way"; null keeps today's multi-axis mount verbatim.
    //
    // A FACET PANEL is excluded: its spec has that same shape, but the shared
    // range `FacetScales.fixed` injects reaches the chart only through the
    // inline axis config, and a widget-level axis honours `min`/`max` where an
    // inline one does not — so re-mounting a panel would change what every
    // faceted chart draws. See `FacetPanelScope`.
    final legacySeries = FacetPanelScope.isPanel(context)
        ? null
        : _legacySingleAxisSeries<T>(spec, lowered);

    return BravenChartPlus(
      series: legacySeries ?? lowered?.series ?? const <ChartSeries>[],
      // Set ONLY on the legacy shape. `BravenChartPlus` ignores a widget-level
      // yAxis as soon as any series carries an inline config, so passing it
      // alongside bound series would be a lie the render path quietly drops.
      yAxis: legacySeries == null ? null : lowered!.yAxes.single,
      annotations: lowered?.annotations ?? const [],
      xAxisConfig: spec.xAxis,
      interactionConfig: lowered?.interaction ?? spec.interaction,
      theme: spec.theme,
      // Chart-level options are data-independent, so they are read straight off
      // the spec — they must reach the chart even on the emptyData path, where
      // `lowered` is null and the chart renders its empty state.
      grid: spec.grid,
      title: spec.title,
      subtitle: spec.subtitle,
      showLegend: spec.showLegend ?? true,
      concentricDonutConfig:
          lowered?.concentricDonutConfig ?? const ConcentricDonutConfig(),
      // `PlotSpec.polar` is a SPEC field, so it belongs with the chart-level
      // options above: it must reach the chart on the emptyData path too, where
      // `lowered` is null. It cannot leak onto a chart that should not have it —
      // `polarConfigOnNonPolarSpec` refuses a non-polar spec that carries one,
      // and that guard runs ABOVE the emptyData guard — so a Cartesian spec
      // still falls through to the const default, exactly as before.
      // (`ConcentricDonutConfig` has no spec-level twin: it lives on the donut
      // MARK, so there is nothing to read off the spec here.)
      polarChartConfig:
          lowered?.polarChartConfig ?? spec.polar ?? const PolarChartConfig(),
      emptyStateConfig: emptyStateConfig,
      bravenChartController: bravenChartController,
      interactionGroupController: interactionGroupController,
    );
  }
}

/// [LoweredPlot.series] re-mounted the way a config author writes a single-axis
/// chart — every binding stripped — or null when this plot is not that shape
/// and must keep the multi-axis mount.
///
/// The gate reads the SPEC's marks, not the lowered series: lowering always
/// binds (`_bindAxis` resolves `mark.yAxisId ?? axes.first.id`), so by the time
/// a series exists the author's own intent has been overwritten. A mark that
/// names its axis asked for the multi-axis path and keeps it, even when only
/// one axis is declared.
///
/// Radial charts lower to no Y axes at all, so they can never reach this shape
/// and their mount is untouched.
List<ChartSeries>? _legacySingleAxisSeries<T>(
  PlotSpec<T> spec,
  LoweredPlot? lowered,
) {
  if (lowered == null || lowered.yAxes.length != 1) return null;
  if (spec.marks.any((mark) => mark.yAxisId != null)) return null;
  final unbound = <ChartSeries>[];
  for (final series in lowered.series) {
    final stripped = seriesWithoutAxisBinding(series);
    // A family that cannot express an unbound series must not be mounted
    // half-legacy — a widget-level axis beside a still-bound series is a third
    // shape, neither the legacy chart nor the multi-axis one. Fall back to the
    // multi-axis mount for the whole plot instead.
    if (stripped == null) return null;
    unbound.add(stripped);
  }
  return unbound;
}
