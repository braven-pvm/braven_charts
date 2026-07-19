// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

const radialDemoMinimumDataPoints = 3;
const radialDemoMaximumDataPoints = 20;

/// Returns stable category identities for a radial demo dataset.
///
/// Story-specific labels are retained first. Generic labels extend the dataset
/// when the requested test density exceeds the story's authored categories.
List<String> radialDemoLabels({
  required Iterable<String> preferredLabels,
  required int count,
}) {
  assert(count >= radialDemoMinimumDataPoints);
  assert(count <= radialDemoMaximumDataPoints);
  final labels = preferredLabels.toSet().toList(growable: true);
  var nextNumber = labels.length + 1;
  while (labels.length < count) {
    final candidate = 'Category $nextNumber';
    if (!labels.contains(candidate)) labels.add(candidate);
    nextNumber++;
  }
  return labels.take(count).toList(growable: false);
}

/// Creates a positive random part-to-whole distribution with an exact total.
Map<String, num> randomRadialDistribution({
  required List<String> labels,
  required double total,
  required math.Random random,
}) {
  assert(labels.isNotEmpty);
  assert(total > 0);
  final weights = [
    for (var index = 0; index < labels.length; index++)
      math.pow(0.08 + random.nextDouble() * 0.92, 1.6).toDouble(),
  ];
  final weightTotal = weights.fold<double>(0, (sum, value) => sum + value);
  var assigned = 0.0;
  final values = <String, num>{};
  for (var index = 0; index < labels.length; index++) {
    final value = index == labels.length - 1
        ? total - assigned
        : total * weights[index] / weightTotal;
    values[labels[index]] = value;
    assigned += value;
  }
  return values;
}

/// Creates a random secondary radial metric for the supplied identities.
Map<String, num> randomRadialMetric({
  required List<String> labels,
  required double minimum,
  required double maximum,
  required math.Random random,
}) {
  assert(minimum > 0);
  assert(maximum >= minimum);
  return {
    for (final label in labels)
      label: minimum + random.nextDouble() * (maximum - minimum),
  };
}
