import 'dart:ui';

/// Creates a path containing only the painted intervals from [dashPattern].
///
/// The pattern alternates painted and skipped distances and restarts for each
/// disconnected contour. An empty pattern preserves the original solid path.
Path createDashedPath(Path source, List<double> dashPattern) {
  if (dashPattern.isEmpty) return source;
  _validateDashPattern(dashPattern);

  final result = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var patternIndex = 0;
    var shouldPaint = true;

    while (distance < metric.length) {
      final interval = dashPattern[patternIndex];
      final nextDistance = (distance + interval).clamp(0.0, metric.length);
      if (shouldPaint && nextDistance > distance) {
        result.addPath(metric.extractPath(distance, nextDistance), Offset.zero);
      }
      distance = nextDistance;
      patternIndex = (patternIndex + 1) % dashPattern.length;
      shouldPaint = !shouldPaint;
    }
  }
  return result;
}

void _validateDashPattern(List<double> dashPattern) {
  if (dashPattern.length.isOdd) {
    throw ArgumentError.value(
      dashPattern,
      'dashPattern',
      'Must contain an even number of painted and skipped intervals',
    );
  }
  for (var index = 0; index < dashPattern.length; index++) {
    final interval = dashPattern[index];
    if (!interval.isFinite || interval <= 0) {
      throw ArgumentError.value(
        interval,
        'dashPattern[$index]',
        'Intervals must be positive and finite',
      );
    }
  }
}
