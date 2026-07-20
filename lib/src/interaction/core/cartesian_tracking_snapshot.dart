// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;

import '../../artifacts/chart_view_state.dart' show ChartPointRef;
import '../../models/candlestick_interaction_details.dart';
import '../../models/interaction_config.dart' show CrosshairSeriesValue;

/// Number of fields declared on [CrosshairSeriesValue] that
/// [CartesianTrackedSeriesValue.fromCrosshairValue] must copy exhaustively.
///
/// Field-count tripwire: adding a field to [CrosshairSeriesValue] without
/// mirroring it on [CartesianTrackedSeriesValue] (and copying it in
/// [CartesianTrackedSeriesValue.fromCrosshairValue]) would silently drop the
/// value from every published tracking snapshot. The exhaustive-copy test and
/// the field-count test in `cartesian_tracking_snapshot_test.dart` both
/// assert this constant, so a new field forces a deliberate review of the
/// copy chain before either test can pass again.
@visibleForTesting
const int crosshairSeriesValueFieldCount = 23;

/// The interaction source that produced a [CartesianTrackingSnapshot].
///
/// Consumers such as the value summary use the origin to distinguish live
/// pointer tracking from programmatic or fallback resolutions without
/// re-deriving that context from pointer state.
enum CartesianTrackingOrigin {
  /// Resolved from a local pointer hover or drag over the plot area.
  pointer,

  /// Resolved from keyboard-driven data navigation.
  keyboard,

  /// Resolved from a synchronized cursor broadcast by another chart in the
  /// same interaction group.
  synchronized,

  /// Resolved from an explicitly pinned data point.
  pinned,

  /// Resolved from a deterministic fallback (for example the latest visible
  /// datum) when no live tracking source is active.
  fallback,
}

/// One tracked series sample within a [CartesianTrackingSnapshot].
///
/// Mirrors every field of [CrosshairSeriesValue] and additionally carries the
/// display-ready [formattedX], [formattedY], and [unitLabel] resolved at
/// snapshot time, so consumers never reach back into paint-coupled axis state
/// to format values.
@immutable
class CartesianTrackedSeriesValue {
  /// Creates a tracked series value.
  const CartesianTrackedSeriesValue({
    required this.seriesId,
    required this.seriesName,
    required this.seriesColor,
    required this.x,
    required this.y,
    required this.dataPointIndex,
    this.sourcePointIndices = const <int>[],
    required this.isInterpolated,
    this.linkedSeriesId,
    this.isTrend = false,
    this.pointLabel,
    this.magnitudeValue,
    this.formattedMagnitudeValue,
    this.magnitudeLabel,
    this.colorValue,
    this.formattedColorValue,
    this.colorLabel,
    this.opacityValue,
    this.formattedOpacityValue,
    this.opacityLabel,
    this.candlestick,
    this.categoryValue,
    this.categoryLabel,
    required this.formattedX,
    required this.formattedY,
    this.unitLabel,
  });

  /// Creates a tracked value from a resolved [CrosshairSeriesValue], copying
  /// every field and attaching the display-ready formatting.
  ///
  /// This copy must stay exhaustive over all
  /// [crosshairSeriesValueFieldCount] fields of [CrosshairSeriesValue]
  /// (declared in `models/interaction_config.dart`). When a field is added
  /// there, mirror it here and on [CartesianTrackedSeriesValue], then update
  /// the tripwire constant and its tests together.
  factory CartesianTrackedSeriesValue.fromCrosshairValue(
    CrosshairSeriesValue value, {
    required String formattedX,
    required String formattedY,
    String? unitLabel,
  }) {
    return CartesianTrackedSeriesValue(
      seriesId: value.seriesId,
      seriesName: value.seriesName,
      seriesColor: value.seriesColor,
      x: value.x,
      y: value.y,
      dataPointIndex: value.dataPointIndex,
      sourcePointIndices: value.sourcePointIndices,
      isInterpolated: value.isInterpolated,
      linkedSeriesId: value.linkedSeriesId,
      isTrend: value.isTrend,
      pointLabel: value.pointLabel,
      magnitudeValue: value.magnitudeValue,
      formattedMagnitudeValue: value.formattedMagnitudeValue,
      magnitudeLabel: value.magnitudeLabel,
      colorValue: value.colorValue,
      formattedColorValue: value.formattedColorValue,
      colorLabel: value.colorLabel,
      opacityValue: value.opacityValue,
      formattedOpacityValue: value.formattedOpacityValue,
      opacityLabel: value.opacityLabel,
      candlestick: value.candlestick,
      categoryValue: value.categoryValue,
      categoryLabel: value.categoryLabel,
      formattedX: formattedX,
      formattedY: formattedY,
      unitLabel: unitLabel,
    );
  }

  /// Stable identifier of the tracked series.
  final String seriesId;

  /// Human-readable name of the tracked series.
  final String seriesName;

  /// Resolved series color at snapshot time.
  final Color seriesColor;

  /// Tracked X value in data space.
  final double x;

  /// Tracked Y value in data space.
  final double y;

  /// Index of the snapped data point in the series' effective points.
  final int dataPointIndex;

  /// Source-point indices contributing to this sample when the tracked datum
  /// aggregates multiple points (for example density-grouped candles).
  final List<int> sourcePointIndices;

  /// Whether [y] was interpolated between data points rather than snapped.
  final bool isInterpolated;

  /// For trend annotations, the ID of the data series this trend is linked
  /// to. Used for axis resolution so trend values align with the correct
  /// Y axis.
  final String? linkedSeriesId;

  /// Whether this value represents a trend annotation rather than a data
  /// series.
  final bool isTrend;

  /// Optional source-point label for discrete Scatter tracking.
  final String? pointLabel;

  /// Optional third quantitative Scatter value represented by marker area.
  final double? magnitudeValue;

  /// Display-ready [magnitudeValue], including its unit.
  final String? formattedMagnitudeValue;

  /// Human-readable name for [magnitudeValue].
  final String? magnitudeLabel;

  /// Optional quantitative Scatter value represented through marker color.
  final double? colorValue;

  /// Display-ready [colorValue], including its unit.
  final String? formattedColorValue;

  /// Human-readable name for [colorValue].
  final String? colorLabel;

  /// Optional quantitative Scatter value represented through marker opacity.
  final double? opacityValue;

  /// Display-ready [opacityValue], including its unit.
  final String? formattedOpacityValue;

  /// Human-readable name for [opacityValue].
  final String? opacityLabel;

  /// Typed OHLC values when this tracked sample is a Candlestick.
  final CandlestickInteractionDetails? candlestick;

  /// Display-ready categorical Scatter value.
  final String? categoryValue;

  /// Human-readable name for [categoryValue].
  final String? categoryLabel;

  /// Display-ready [x], formatted with the resolved X-axis formatter.
  final String formattedX;

  /// Display-ready [y], formatted with the resolved Y-axis formatter.
  final String formattedY;

  /// Optional unit suffix resolved from the series' Y axis (for example `W`).
  final String? unitLabel;

  /// Returns the series ID to use for axis resolution (linked series for
  /// trends).
  String get axisSeriesId => linkedSeriesId ?? seriesId;
}

/// Immutable product of one Cartesian tracking resolution.
///
/// A snapshot is the single resolved-tracking model shared by the crosshair
/// renderer, the synchronized-cursor path, and the value summary pipeline.
/// It is published with identity-based change suppression: consumers compare
/// snapshots with [sameIdentityAs] and skip work when the tracked datum and
/// its formatted values are unchanged.
@immutable
class CartesianTrackingSnapshot {
  /// Creates a snapshot.
  ///
  /// The [values] list is defensively copied into an unmodifiable list, so
  /// later mutation of the argument never leaks into a published snapshot.
  CartesianTrackingSnapshot({
    required this.dataX,
    required this.plotX,
    required List<CartesianTrackedSeriesValue> values,
    required this.origin,
    this.primaryPoint,
  }) : values = List<CartesianTrackedSeriesValue>.unmodifiable(values);

  /// Tracked X position in data space.
  final double dataX;

  /// Tracked X position in plot-local screen space.
  final double plotX;

  /// Resolved series values at [dataX], one entry per tracked series.
  ///
  /// The list is unmodifiable; attempts to mutate it throw
  /// [UnsupportedError].
  final List<CartesianTrackedSeriesValue> values;

  /// The interaction source that produced this snapshot.
  final CartesianTrackingOrigin origin;

  /// Canonical reference to the primary snapped data point, when one exists.
  final ChartPointRef? primaryPoint;

  /// Whether [other] resolves the same datum identity with the same
  /// formatted values.
  ///
  /// Compares the value count plus, per entry, [CartesianTrackedSeriesValue]'s
  /// `seriesId`, `dataPointIndex`, `isTrend`, `formattedY`, and the
  /// candlestick OHLC identity. Positional fields such as [dataX], [plotX],
  /// and [origin] are deliberately excluded so sub-pixel cursor movement over
  /// the same snapped datum suppresses re-publication.
  ///
  /// **Accepted marker quantization** (Slice-0 decision D10, hot-path
  /// contract): the raw interpolated `y` is also excluded, so cursor movement
  /// that changes an interpolated intersection Y without changing its
  /// `formattedY` keeps the previously published snapshot — consumers reusing
  /// its marker position render the *prior* interpolated Y until the
  /// formatted value ticks over. Marker placement is thereby quantized to the
  /// display precision of `formattedY`; that sub-precision drift is invisible
  /// at tooltip precision and is the accepted cost of suppressing per-pixel
  /// republication.
  bool sameIdentityAs(CartesianTrackingSnapshot other) {
    if (identical(this, other)) return true;
    if (values.length != other.values.length) return false;
    for (var index = 0; index < values.length; index++) {
      final a = values[index];
      final b = other.values[index];
      if (a.seriesId != b.seriesId ||
          a.dataPointIndex != b.dataPointIndex ||
          a.isTrend != b.isTrend ||
          a.formattedY != b.formattedY ||
          a.candlestick?._identityKey != b.candlestick?._identityKey) {
        return false;
      }
    }
    return true;
  }
}

extension on CandlestickInteractionDetails {
  /// Structural identity of one tracked candle: timestamp plus OHLC values
  /// and grouping count. [CandlestickInteractionDetails] exposes no identity
  /// member of its own, so the snapshot composes one here.
  (DateTime?, double, double, double, double, int) get _identityKey =>
      (timestamp, open, high, low, close, sourceCount);
}
