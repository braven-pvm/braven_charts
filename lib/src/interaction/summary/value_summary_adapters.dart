// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show internal;

import '../../models/cartesian_value_summary_config.dart';
import '../core/cartesian_tracking_snapshot.dart';

/// Builds the value summary's typed display rows from a resolved snapshot.
///
/// The adapter is a pure function of the snapshot and content selection:
/// identical inputs always produce an equal [CartesianValueSummaryContentModel]
/// (the model has value equality), so the output itself can serve as the
/// change key for layout caching.
///
/// Formatting is consumed as-is from the snapshot. `formattedX`/`formattedY`
/// already carry the tooltip-parity formatting (including the multi-axis unit
/// inside `formattedY`), and the candlestick payload's formatted OHLC/change
/// strings are already unit-suffixed by `CandlestickInteractionDetails`. The
/// adapter never re-formats numbers and never imposes financial two-decimal
/// precision on non-financial series.
///
/// Family detection is field-driven because the snapshot deliberately carries
/// no series-type discriminator:
///
/// - a value with a candlestick payload renders OHLC rows;
/// - a value with a Range Area payload renders low/high/midpoint/span rows;
/// - a value with any scatter detail (point label or size/color/opacity/
///   category encoding) renders X/Y plus one row per present encoding,
///   mirroring the tracking tooltip's detection and fallback labels;
/// - anything else (Line, Area, Bar) renders a single formatted value row,
///   plus a grouped-context row when the sample aggregates multiple source
///   points.
///
/// Hidden series never reach the adapter: `ResolvedChartData.renderSeries`
/// filters `hiddenSeriesIds` before series elements are built, so the
/// snapshot's values are visible series only. That is why
/// [CartesianValueSummaryAutomaticContent.includeHiddenSeries] has no
/// adapter-side effect — re-admitting hidden series would require the
/// upstream pipeline to resolve them into the snapshot first.
@internal
abstract final class ValueSummaryAdapter {
  /// Builds the content model for [snapshot] under [content].
  ///
  /// [showSeriesAccent] controls whether the model carries the primary
  /// value's series color as [CartesianValueSummaryContentModel.accentColor].
  static CartesianValueSummaryContentModel build(
    CartesianTrackingSnapshot snapshot, {
    required CartesianValueSummaryContent content,
    required bool showSeriesAccent,
  }) {
    switch (content) {
      case CartesianValueSummaryBuilderContent(:final builder):
        return builder(snapshot);
      case CartesianValueSummaryAutomaticContent(:final includeTrends):
        return _buildAutomatic(
          snapshot,
          includeTrends: includeTrends,
          showSeriesAccent: showSeriesAccent,
        );
    }
  }

  static CartesianValueSummaryContentModel _buildAutomatic(
    CartesianTrackingSnapshot snapshot, {
    required bool includeTrends,
    required bool showSeriesAccent,
  }) {
    final values = [
      for (final value in snapshot.values)
        if (!value.isTrend || includeTrends) value,
    ];
    if (values.isEmpty) return const CartesianValueSummaryContentModel();

    final primary = values.firstWhere(
      (value) => !value.isTrend,
      orElse: () => values.first,
    );
    final accentColor = showSeriesAccent ? primary.seriesColor : null;

    if (values.length == 1) {
      final value = values.single;
      return CartesianValueSummaryContentModel(
        title: value.seriesName,
        subtitle: _xContext(value),
        accentColor: accentColor,
        rows: _familyRows(value),
      );
    }

    // Multi-series and mixed charts: one grouped section per series at the
    // resolved X. Single-row families collapse into one accented
    // `name: value` row; multi-row families emit an accented series title
    // row followed by their family rows.
    final rows = <CartesianValueSummaryRow>[];
    for (final value in values) {
      final familyRows = _familyRows(value);
      if (familyRows.length == 1) {
        rows.add(
          CartesianValueSummaryRow(
            label: value.seriesName,
            value: familyRows.single.value,
            color: value.seriesColor,
          ),
        );
      } else {
        rows.add(
          CartesianValueSummaryRow(
            label: value.seriesName,
            value: '',
            color: value.seriesColor,
          ),
        );
        rows.addAll(familyRows);
      }
    }
    return CartesianValueSummaryContentModel(
      title: _xContext(primary),
      accentColor: accentColor,
      rows: rows,
    );
  }

  /// The resolved X context shown as the panel's subtitle (single series) or
  /// title (multi-series): the candlestick timestamp when formatted, else the
  /// discrete point label, else the formatted X value.
  static String _xContext(CartesianTrackedSeriesValue value) =>
      value.candlestick?.formattedTimestamp ??
      value.pointLabel ??
      value.formattedX;

  static List<CartesianValueSummaryRow> _familyRows(
    CartesianTrackedSeriesValue value,
  ) {
    final candle = value.candlestick;
    if (candle != null) {
      return [
        CartesianValueSummaryRow(label: 'Open', value: candle.formattedOpen),
        CartesianValueSummaryRow(label: 'High', value: candle.formattedHigh),
        CartesianValueSummaryRow(label: 'Low', value: candle.formattedLow),
        CartesianValueSummaryRow(label: 'Close', value: candle.formattedClose),
        CartesianValueSummaryRow(
          label: 'Change',
          value: candle.formattedChange,
        ),
        CartesianValueSummaryRow(
          label: 'Direction',
          value: candle.direction.name,
        ),
        if (candle.sourceCount > 1)
          CartesianValueSummaryRow(
            label: 'Grouped',
            value: '${candle.sourceCount} candles',
          ),
      ];
    }

    final range = value.rangeArea;
    if (range != null) {
      return [
        CartesianValueSummaryRow(label: 'Low', value: range.formattedLow),
        CartesianValueSummaryRow(label: 'High', value: range.formattedHigh),
        CartesianValueSummaryRow(
          label: 'Midpoint',
          value: range.formattedMidpoint,
        ),
        CartesianValueSummaryRow(label: 'Span', value: range.formattedSpan),
      ];
    }

    // Mirrors the tracking tooltip's scatter-detail detection so both
    // surfaces classify the same sample the same way.
    final hasScatterDetail =
        value.pointLabel != null ||
        value.formattedMagnitudeValue != null ||
        value.formattedColorValue != null ||
        value.formattedOpacityValue != null ||
        value.categoryValue != null;
    if (hasScatterDetail) {
      return [
        CartesianValueSummaryRow(label: 'X', value: value.formattedX),
        CartesianValueSummaryRow(label: 'Y', value: value.formattedY),
        if (value.formattedMagnitudeValue case final magnitude?)
          CartesianValueSummaryRow(
            label: value.magnitudeLabel ?? 'Magnitude',
            value: magnitude,
          ),
        if (value.formattedColorValue case final color?)
          CartesianValueSummaryRow(
            label: value.colorLabel ?? 'Color value',
            value: color,
          ),
        if (value.formattedOpacityValue case final opacity?)
          CartesianValueSummaryRow(
            label: value.opacityLabel ?? 'Opacity value',
            value: opacity,
          ),
        if (value.categoryValue case final category?)
          CartesianValueSummaryRow(
            label: value.categoryLabel ?? 'Category',
            value: category,
          ),
      ];
    }

    return [
      CartesianValueSummaryRow(label: 'Value', value: value.formattedY),
      if (value.sourcePointIndices.length > 1)
        CartesianValueSummaryRow(
          label: 'Grouped',
          value: '${value.sourcePointIndices.length} points',
        ),
    ];
  }
}
