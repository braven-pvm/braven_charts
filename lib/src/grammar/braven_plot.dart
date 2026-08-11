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
import '../models/radar_chart_config.dart';
import '../models/y_axis_config.dart' show YAxisConfig;
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
/// axis from the first series BOUND to it, and "unbound" at the WIDGET level
/// does not mean unbound at the RENDER level: `MultiAxisManager` binds a
/// series that carries no binding of its own to the chart's primary axis. So
/// the legacy chart's axis IS bound and IS tinted with the series colour —
/// measured `#2563EB` tick labels for a `#2563EB` line.
///
/// ## Two questions, and only one of them is answered by parity
///
/// "A chain reversed from a config chart renders like that chart" is measured
/// at 0 of 240,000 pixels across eight shapes, and it stays true. It is NOT an
/// answer to "does an authored spec render like it did before this mount
/// landed", and quoting it as one is the specific mistake to avoid here.
///
/// It does not, for six shapes, because the legacy chart honours axis settings
/// the inline mount dropped. Measured against the previous mount at a 600x400
/// host, of 240,000 pixels (the second figure is outside the Y-label gutter):
///
/// | authored single-axis shape | changed | in plot area |
/// |---|---|---|
/// | `min` AND `max` | 25,885 | 20,770 |
/// | `min` only | 25,126 | 20,284 |
/// | `max` only | 23,196 | 17,854 |
/// | `scaleType: AxisScaleType.log` | 11,948 | 11,745 |
/// | `position: YAxisPosition.hidden` | 9,721 | 8,532 |
/// | `visible: false` | 9,721 | 8,532 |
/// | no axis / a plain labelled axis / a named axis | 0 | 0 |
///
/// Three of those are settings the previous mount ignored OUTRIGHT, which is
/// why they are published as fixes: a ranged axis drew the byte-identical
/// frame to the same axis carrying no range, and a `log` axis drew log tick
/// labels over a plot whose data was mapped linearly — `BravenChartPlus` reads
/// `widget.yAxis?.scaleType ?? AxisScaleType.linear`, and the previous mount
/// set no `widget.yAxis`. The hidden pair is a behaviour change rather than a
/// fix: both mounts hide the axis and lay the plot area out identically, and
/// the whole difference is that the previous mount kept drawing the hidden
/// axis' horizontal grid.
///
/// Every row is asserted, both halves, by the mount divergence table in
/// `test/widgets/braven_plot_pixel_parity_test.dart`, which rebuilds the
/// previous mount in process so the comparison needs no revert.
///
/// That was true only for an ANONYMOUS widget-level axis until the binding
/// itself was fixed. `MultiAxisManager.getEffectiveBindings` used to name the
/// synthetic `'primary_axis'` literally, and that is the id
/// `getEffectiveYAxes` invents only when the widget-level axis carries none —
/// so a mounted axis with an id of its own was left DANGLING: nothing bound to
/// it, grey labels, and a `computeAxisBounds` that fell through to its
/// `0..100` no-data fallback for a chart that plainly has data. Every id this
/// mount can produce hit that: the `'y'` extraction stamps, the `'axis-0'`
/// `PlotSpecLowering` stamps on a spec that names no axis, and any name the
/// author chose. The mount is no longer sensitive to the id; see
/// [_asAuthoredWidgetAxis] for what is left of the id handling and why it
/// stays.
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
      yAxis: legacySeries == null
          ? null
          : _asAuthoredWidgetAxis(lowered!.yAxes.single),
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
      radarChartConfig:
          lowered?.radarChartConfig ?? spec.radar ?? const RadarChartConfig(),
      emptyStateConfig: emptyStateConfig,
      bravenChartController: bravenChartController,
      interactionGroupController: interactionGroupController,
    );
  }
}

/// The id extraction stamps on a widget-level axis that carried none.
///
/// `BravenChartPlus._buildDocumentExtractionSource` writes
/// `addAxis(widget.yAxis!, 'y')`, so an axis id of `'y'` in a chart document
/// means "the chart had an ANONYMOUS widget-level axis" — the ordinary
/// `YAxisConfig(...)` constructor, which takes no id at all.
const _anonymousAxisFallbackId = 'y';

/// [axis] as the widget-level axis the chart this chain reverses to actually
/// had.
///
/// Extraction keeps a non-empty axis id and stamps [_anonymousAxisFallbackId]
/// on an empty one, so a chain reversed from a chart whose widget-level axis
/// was ANONYMOUS always spells `id: 'y'`. Unwinding that back to the empty id
/// mounts the axis under the same effective id the config chart's does
/// (`getEffectiveYAxes` auto-generates `'primary_axis'` for both), so the two
/// charts are the same chart in render-time axis IDENTITY and not merely in
/// what they draw. The document is untouched either way: extraction re-stamps
/// the fallback on the empty id it gets back.
///
/// ## What this is no longer worth, stated plainly
///
/// This used to be the difference between a TINTED and an UNTINTED Y gutter —
/// 4,658 (no widget axis), 5,378 (labelled axis) and 3,612 (min/max axis) of
/// 240,000 pixels — because `MultiAxisManager.getEffectiveBindings` sent every
/// unbound series to the literal `'primary_axis'` and so bound nothing to an
/// axis carrying any other id. That was a defect in the BINDING, it was never
/// confined to reversed chains (a hand-written spec mounts `'axis-0'` and was
/// hit just as hard, and so was a plain `BravenChartPlus` with a named
/// widget-level `yAxis`), and it is fixed in `MultiAxisManager`. With that
/// fixed, mounting the axis verbatim draws the identical image: measured by
/// disabling this function and re-running the whole pixel-parity file, which
/// stayed green on every shape. It is kept for the identity above and because
/// the mount tests pin it, NOT because the picture depends on it.
///
/// Only the fallback id is unwound. An axis the author NAMED (`.yAxis(
/// YAxisConfig.withId(id: 'watts', ...))`) keeps its name, because extraction
/// preserves it and the config chart it reverses to carries the same name.
///
/// The one shape this cannot serve is a config chart that spells
/// `YAxisConfig.withId(id: 'y', ...)` at the WIDGET level: its document is
/// byte-identical to the anonymous chart's — the fallback collides with a
/// legal id — so exactly one of the two can be reproduced, and this reproduces
/// the one every ordinary `YAxisConfig(...)` produces. Since the binding fix
/// the two render alike anyway, so the collision costs an axis id and nothing
/// visible.
///
/// Pinned by `test/widgets/braven_plot_pixel_parity_test.dart`.
YAxisConfig _asAuthoredWidgetAxis(YAxisConfig axis) =>
    axis.id == _anonymousAxisFallbackId ? axis.copyWith(id: '') : axis;

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
///
/// ## An axis carrying min/max is NOT declined here, and that was measured
///
/// The two mounts really do disagree about `min`/`max` — a widget-level axis
/// applies it to the Y domain and an inline one does not, which is why
/// `FacetPanelScope` gates the seam off for panels. Declining the legacy mount
/// here for the same reason looks symmetric and is wrong, in both directions:
///
///  * It removes nothing. Adding the decline HERE and the matching clause to
///    `_firstMismatch`'s `legacySingleAxis` normalisation leaves the whole
///    suite's emitter corpus untouched — not one round-trip or showcase state
///    stops emitting. A document can only reach this shape with every series
///    unbound, and extraction produces that only for a chart that had a
///    widget-level (or no) axis, which is exactly the path that DOES apply
///    min/max. The inline chart that would be harmed is refused a layer
///    earlier, by name, for leaving `yAxisId` unset.
///  * It costs the reversal. The config chart the chain came from applied the
///    range; a declined mount would not. Measured at 25,885 of 240,000 pixels,
///    20,770 of them in the plot area — the plot area moves — and the extracted
///    documents diverge too, on `series[*].axisId` and `inlineAxis`.
///
/// Note what that 25,885 is NOT. It is the distance between the two MOUNTS, so
/// it is equally the amount an AUTHORED min/max spec changed by when this mount
/// landed — a user-visible change, published under **Fixed** in `CHANGELOG.md`
/// because the previous mount applied no range at all. It is not merely the
/// price tag on an alternative nobody shipped, and citing it only that way is
/// how the release note came to under-report six changed shapes. The min/max
/// row is one of those six; the table is on [BravenPlot].
///
/// The faceting case is different in the one way that matters: `FacetScales`
/// injects its shared range as an INLINE axis on each series, so a panel's
/// chart genuinely never applied it. The gate belongs where it is.
///
/// Both measurements live in `test/widgets/braven_plot_pixel_parity_test.dart`
/// — shape (c) and the mount control — and in the facet seam's own control,
/// `braven_facet_plot_test.dart`'s "the gate is the panel, not the spec".
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
