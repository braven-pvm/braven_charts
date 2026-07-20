// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show immutable, internal;

import '../../artifacts/chart_view_state.dart' show ChartPointRef;
import '../../models/cartesian_value_summary_config.dart'
    show CartesianValueSummaryValuePolicy;
import '../core/cartesian_tracking_snapshot.dart';

/// The outcome of one value-summary policy reduction.
///
/// [snapshot] is the snapshot the summary should display, or null when the
/// summary must hide. [clearedInvalidPin] is true when the reduction was
/// given a pinned [ChartPointRef] that could no longer be resolved (for
/// example after a data replacement removed the point): per the spec the
/// invalid pin is skipped and resolution continues through the policy, and
/// the pipeline that owns the pin state must clear it so the stale reference
/// is never retained.
@immutable
@internal
class ValueSummaryReduction {
  /// Creates a reduction result.
  const ValueSummaryReduction({this.snapshot, this.clearedInvalidPin = false});

  /// The snapshot to display, or null when the summary hides.
  final CartesianTrackingSnapshot? snapshot;

  /// Whether an explicit pin failed to resolve and must be cleared by the
  /// caller.
  final bool clearedInvalidPin;
}

/// Deterministic value-source precedence for the Cartesian value summary.
///
/// The reducer is pure: it owns no state and performs no resolution itself.
/// Point lookups and fallbacks are supplied as callables so the caller (the
/// render pipeline) keeps ownership of snapshot construction, and so the
/// fallback chain is evaluated lazily — a provider is invoked only when every
/// earlier source in the active policy's chain is unavailable.
///
/// Sources outside a policy's chain are ignored entirely: a pinned point
/// never influences `trackingThenLatest`, and a selection never influences
/// `pinnedThenTrackingThenLatest`.
@internal
abstract final class ValueSummaryReducer {
  /// Reduces the available value sources to the snapshot the summary shows.
  ///
  /// [tracking] is the active tracking snapshot, if any. [pinned] and
  /// [selection] are stable point references consulted only by the policies
  /// that include them. [resolvePoint] resolves a point reference into a
  /// snapshot, returning null when the point no longer exists.
  /// [latestVisible] and [firstVisible] produce the deterministic fallback
  /// snapshots; they return null when no visible datum exists (empty data or
  /// every series hidden), which hides the summary.
  static ValueSummaryReduction reduce({
    required CartesianValueSummaryValuePolicy policy,
    CartesianTrackingSnapshot? tracking,
    ChartPointRef? pinned,
    ChartPointRef? selection,
    required CartesianTrackingSnapshot? Function(ChartPointRef point)
    resolvePoint,
    required CartesianTrackingSnapshot? Function() latestVisible,
    required CartesianTrackingSnapshot? Function() firstVisible,
  }) {
    switch (policy) {
      case CartesianValueSummaryValuePolicy.explicitOnly:
        if (pinned == null) return const ValueSummaryReduction();
        final pinSnapshot = resolvePoint(pinned);
        if (pinSnapshot == null) {
          // The pinned point no longer exists. explicitOnly has no further
          // sources, so the summary hides; the stale pin is reported for the
          // owner to clear.
          return const ValueSummaryReduction(clearedInvalidPin: true);
        }
        return ValueSummaryReduction(snapshot: pinSnapshot);

      case CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest:
        var clearedInvalidPin = false;
        if (pinned != null) {
          final pinSnapshot = resolvePoint(pinned);
          if (pinSnapshot != null) {
            return ValueSummaryReduction(snapshot: pinSnapshot);
          }
          clearedInvalidPin = true;
        }
        return ValueSummaryReduction(
          snapshot: tracking ?? latestVisible(),
          clearedInvalidPin: clearedInvalidPin,
        );

      case CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest:
        if (selection != null) {
          final selectionSnapshot = resolvePoint(selection);
          if (selectionSnapshot != null) {
            return ValueSummaryReduction(snapshot: selectionSnapshot);
          }
          // An unresolvable selection is transient interaction state, not a
          // pin: fall through without reporting.
        }
        return ValueSummaryReduction(snapshot: tracking ?? latestVisible());

      case CartesianValueSummaryValuePolicy.trackingThenLatest:
        return ValueSummaryReduction(snapshot: tracking ?? latestVisible());

      case CartesianValueSummaryValuePolicy.trackingThenFirst:
        return ValueSummaryReduction(snapshot: tracking ?? firstVisible());
    }
  }
}
