// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The one definition of "this series, with its Y-axis binding removed".
///
/// Deliberately NOT exported from `braven_charts.dart`: it is a seam shared by
/// two internal callers, not API.
///
/// Two of them need it and they need OPPOSITE fallbacks, which is exactly why
/// it lives in one place. `BravenPlot` uses the null to abandon the legacy
/// single-axis mount for the whole plot rather than mount a half-legacy third
/// shape; `ChartGrammarSourceGenerator` maps the null back to the series
/// UNCHANGED, so an unknown family keeps its binding and fails the round-trip
/// comparison rather than slipping through it. Written twice, the two family
/// lists would drift the moment a sixth Cartesian family is added — the
/// generator would normalise a binding away and emit a chain that `BravenPlot`
/// then mounts multi-axis, so the chain would hand back a document carrying
/// `axisId` and `inlineAxis` the captured chart does not have. Neither the
/// round-trip proof (which compares lowered against captured, never MOUNTED
/// against captured) nor the hand-written `rebuilt` twins would notice.
library;

import '../models/candlestick_chart_series.dart';
import '../models/chart_series.dart';

/// [series] rebuilt without `yAxisId` or `yAxisConfig`, or null when its family
/// cannot express an unbound series.
///
/// `ChartSeries.copyWith` merges every field with `??` and so cannot null one
/// out; the concrete families carry the `clearYAxisId`/`clearYAxisConfig` flags
/// that can. Rebuilding here rather than adding a base-class clear keeps the
/// capability out of the config surface entirely.
///
/// The five families listed are the Cartesian ones the grammar reverses. Every
/// other family — radial, gauge, range-area — returns null: a family that has
/// no `clearYAxisId` cannot be unbound, and guessing is how the two callers
/// would silently disagree.
ChartSeries? seriesWithoutAxisBinding(ChartSeries series) => switch (series) {
  LineChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
  AreaChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
  BarChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
  ScatterChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
  CandlestickChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
  _ => null,
};
