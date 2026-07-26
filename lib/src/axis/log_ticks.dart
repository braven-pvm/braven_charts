// Copyright (c) 2025 braven_charts. All rights reserved.
// Log scale helpers + pure decade tick generation (no Flutter dependency).

import 'dart:math' as math;

/// The logarithm of [v] in the given [base] — `log(v) / log(base)`.
///
/// This is the forward log mapping shared by [ChartTransform] geometry, the
/// tick painters, and the domain guards so marks and ticks stay registered.
double logValue(double v, double base) => math.log(v) / math.log(base);

/// The inverse of [logValue]: `pow(base, t)`.
///
/// `logInverse(logValue(v, base), base) == v` (within floating-point error).
double logInverse(double t, double base) => math.pow(base, t).toDouble();

/// The `[0, 1]` fraction of [v] within a log-scaled `[min, max]` of [base].
///
/// This is the single source of truth for the log relative-position mapping:
/// it mirrors `ChartTransform`'s log arm exactly so that axis ticks (X painter
/// `tickRatio`, Y painter `MultiAxisNormalizer.normalizeScaled`) land on the
/// same pixels as the marks. Returns `0.5` for a degenerate (`min == max`)
/// range, matching the transform.
double logFraction(double v, double min, double max, double base) {
  final lo = logValue(min, base);
  final hi = logValue(max, base);
  return hi == lo ? 0.5 : (logValue(v, base) - lo) / (hi - lo);
}

/// Decade tick values within a positive `[min, max]` for a log axis of [base].
///
/// Returns one value per whole power of [base] that falls inside the range
/// (e.g. `[1, 10, 100, 1000]` for `1..1000` base 10). When more than [maxTicks]
/// whole powers would be produced, the exponents are strided so the count stays
/// at or below [maxTicks]. No sub-decade minor ticks are emitted (YAGNI in v1).
///
/// Non-positive or inverted ranges yield an empty list; callers (the log domain
/// guards) guarantee a positive range in practice.
List<double> decadeTicks(
  double min,
  double max, {
  double base = 10,
  int maxTicks = 12,
}) {
  if (min <= 0 || max <= 0 || max < min) return const <double>[];

  final loExp = logValue(min, base).floor();
  final hiExp = logValue(max, base).ceil();

  var stride = 1;
  final exponentCount = hiExp - loExp + 1;
  if (exponentCount > maxTicks) {
    stride = (exponentCount / maxTicks).ceil();
  }

  final ticks = <double>[];
  for (var e = loExp; e <= hiExp; e += stride) {
    final value = math.pow(base, e).toDouble();
    if (value >= min && value <= max) ticks.add(value);
  }
  return ticks;
}
