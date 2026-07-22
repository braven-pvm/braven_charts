// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../braven_chart_plus.dart';
import '../controllers/chart_interaction_group_controller.dart';
import '../models/braven_chart_controller.dart';
import '../models/chart_series.dart';
import '../models/chart_state_config.dart';
import 'grammar_diagnostics.dart';
import 'plot_lowering.dart';
import 'plot_spec.dart';

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
/// ## Why no widget-level `yAxis`
///
/// The lowering attaches both `yAxisId` and `yAxisConfig` to every series,
/// which is what selects `BravenChartPlus`'s multi-axis path. Passing a
/// widget-level `yAxis` would re-enter the legacy single-axis path and silently
/// change how the chart scales, so this widget deliberately does not expose it.
/// `LoweredPlot.yAxes` is informational.
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

    return BravenChartPlus(
      series: lowered?.series ?? const <ChartSeries>[],
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
      emptyStateConfig: emptyStateConfig,
      bravenChartController: bravenChartController,
      interactionGroupController: interactionGroupController,
    );
  }
}
