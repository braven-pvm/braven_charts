// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import '../../models/series_callout_config.dart';

class SeriesCalloutLayoutCandidate {
  const SeriesCalloutLayoutCandidate({
    required this.id,
    required this.desiredCenterY,
    required this.size,
    required this.priority,
  });

  final String id;
  final double desiredCenterY;
  final Size size;
  final int priority;
}

class SeriesCalloutLayoutResult {
  const SeriesCalloutLayoutResult({required this.id, required this.top});

  final String id;
  final double top;
}

/// Returns the smallest panel that contains [labelRects] plus [padding].
///
/// The result is clipped to [plotBounds], so a large padding value cannot
/// make a callout lane paint outside the plot.
Rect? resolveSeriesCalloutPanelRect({
  required List<Rect> labelRects,
  required Rect plotBounds,
  required EdgeInsets padding,
}) {
  if (labelRects.isEmpty || plotBounds.isEmpty) return null;
  var contentBounds = labelRects.first;
  for (final rect in labelRects.skip(1)) {
    contentBounds = contentBounds.expandToInclude(rect);
  }
  final padded = Rect.fromLTRB(
    contentBounds.left - math.max(0, padding.left),
    contentBounds.top - math.max(0, padding.top),
    contentBounds.right + math.max(0, padding.right),
    contentBounds.bottom + math.max(0, padding.bottom),
  );
  final clipped = padded.intersect(plotBounds);
  return clipped.isEmpty ? null : clipped;
}

/// Deterministically packs labels into a vertical lane without overlap.
///
/// Priority decides which labels survive capacity pressure. Position ties are
/// resolved by stable series id, so input list order never changes the result.
List<SeriesCalloutLayoutResult> layoutSeriesCallouts({
  required List<SeriesCalloutLayoutCandidate> candidates,
  required double minimumY,
  required double maximumY,
  required double gap,
  required int maximumVisible,
  SeriesCalloutPacking packing = SeriesCalloutPacking.followAnchors,
}) {
  if (candidates.isEmpty || maximumY <= minimumY || maximumVisible <= 0) {
    return const [];
  }
  final selected = [...candidates]
    ..sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      return priority != 0 ? priority : a.id.compareTo(b.id);
    });
  if (selected.length > maximumVisible) {
    selected.removeRange(maximumVisible, selected.length);
  }
  selected.sort((a, b) {
    final position = a.desiredCenterY.compareTo(b.desiredCenterY);
    return position != 0 ? position : a.id.compareTo(b.id);
  });

  var totalHeight = selected.fold<double>(
    0,
    (sum, candidate) => sum + candidate.size.height,
  );
  totalHeight += gap * math.max(0, selected.length - 1);
  while (selected.isNotEmpty && totalHeight > maximumY - minimumY) {
    selected.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority != 0 ? priority : b.id.compareTo(a.id);
    });
    final removed = selected.removeAt(0);
    totalHeight -= removed.size.height;
    if (selected.isNotEmpty) totalHeight -= gap;
    selected.sort((a, b) {
      final position = a.desiredCenterY.compareTo(b.desiredCenterY);
      return position != 0 ? position : a.id.compareTo(b.id);
    });
  }
  if (selected.isEmpty) return const [];

  if (packing == SeriesCalloutPacking.compact) {
    final localTops = List<double>.filled(selected.length, 0);
    for (var i = 1; i < selected.length; i++) {
      localTops[i] = localTops[i - 1] + selected[i - 1].size.height + gap;
    }
    var preferredTop = 0.0;
    for (var i = 0; i < selected.length; i++) {
      preferredTop +=
          selected[i].desiredCenterY -
          localTops[i] -
          selected[i].size.height / 2;
    }
    preferredTop /= selected.length;
    final blockTop = preferredTop
        .clamp(minimumY, maximumY - totalHeight)
        .toDouble();
    return [
      for (var i = 0; i < selected.length; i++)
        SeriesCalloutLayoutResult(
          id: selected[i].id,
          top: blockTop + localTops[i],
        ),
    ];
  }

  final tops = List<double>.filled(selected.length, 0);
  for (var i = 0; i < selected.length; i++) {
    final candidate = selected[i];
    final desired = candidate.desiredCenterY - candidate.size.height / 2;
    tops[i] = i == 0
        ? math.max(minimumY, desired)
        : math.max(desired, tops[i - 1] + selected[i - 1].size.height + gap);
  }
  final overflow = tops.last + selected.last.size.height - maximumY;
  if (overflow > 0) {
    for (var i = 0; i < tops.length; i++) {
      tops[i] -= overflow;
    }
    for (var i = tops.length - 2; i >= 0; i--) {
      tops[i] = math.min(tops[i], tops[i + 1] - gap - selected[i].size.height);
    }
    if (tops.first < minimumY) {
      final shift = minimumY - tops.first;
      for (var i = 0; i < tops.length; i++) {
        tops[i] += shift;
      }
    }
  }

  return [
    for (var i = 0; i < selected.length; i++)
      SeriesCalloutLayoutResult(id: selected[i].id, top: tops[i]),
  ];
}
