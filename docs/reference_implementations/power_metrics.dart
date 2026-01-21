import 'dart:math';

/// --------------------------------------------------------------------------
/// FRAMEWORK CONTRACTS (Mocked for Reference)
/// --------------------------------------------------------------------------

/// Represents the data input series (as defined in data_input_api_proposal.md)
abstract class Series<TX, TY> {
  SeriesStorage<TX, TY> get storage;
}

abstract class SeriesStorage<TX, TY> {
  // Direct access to underlying buffers
  List<TY> get yAsList;
}

/// The plugin interface for any scientific calculation
abstract class SeriesMetric<T> {
  const SeriesMetric();
  T calculate(Series<dynamic, double> series);
}

/// --------------------------------------------------------------------------
/// DOMAIN IMPLEMENTATION: POWER METRICS
/// --------------------------------------------------------------------------

/// Normalized Power (NP)®
/// Algorithm: Mean of 4th powers of 30s-smoothed data, 4th rooted.
class NormalizedPowerMetric implements SeriesMetric<double> {
  final Duration windowSize;

  const NormalizedPowerMetric({this.windowSize = const Duration(seconds: 30)});

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    // 1. Smooth (SMA)
    // Assuming 1Hz data for simplicity in this reference impl.
    // In production, we check x-axis deltas.
    final smoothed = _calculateSMA(rawData, windowSize.inSeconds);

    // 2. Weight (Pow 4)
    double sum4th = 0.0;
    for (final val in smoothed) {
      sum4th += pow(val, 4);
    }

    // 3. Average
    final avg4th = sum4th / smoothed.length;

    // 4. Scale (Root 4)
    return pow(avg4th, 0.25).toDouble();
  }
}

/// xPower
/// Algorithm: Mean of 4th powers of 25s-EWMA-smoothed data, 4th rooted.
class XPowerMetric implements SeriesMetric<double> {
  const XPowerMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    // 1. Smooth (EWMA)
    // Alpha ~ 1/26 for 25s window
    const alpha = 1.0 / 26.0;
    final smoothed = _calculateEWMA(rawData, alpha);

    // 2. Weight & Average
    double sum4th = 0.0;
    for (final val in smoothed) {
      sum4th += pow(val, 4);
    }
    final avg4th = sum4th / smoothed.length;

    // 3. Scale
    return pow(avg4th, 0.25).toDouble();
  }
}

/// Variability Index (VI)
/// Algorithm: NP / AveragePower
class VariabilityIndexMetric implements SeriesMetric<double> {
  const VariabilityIndexMetric();

  @override
  double calculate(Series<dynamic, double> series) {
    final rawData = series.storage.yAsList;
    if (rawData.isEmpty) return 0.0;

    // Calculate NP
    final np = const NormalizedPowerMetric().calculate(series);

    // Calculate AP
    double sum = 0.0;
    for (final val in rawData) sum += val;
    final ap = sum / rawData.length;

    if (ap == 0) return 0.0;
    return np / ap;
  }
}

/// --------------------------------------------------------------------------
/// PRIMITIVE ALGORITHMS
/// --------------------------------------------------------------------------

List<double> _calculateSMA(List<double> data, int period) {
  final sma = <double>[];
  for (int i = 0; i < data.length; i++) {
    double sum = 0.0;
    int count = 0;
    final int start = max(0, i - period + 1);
    for (int j = start; j <= i; j++) {
      sum += data[j];
      count++;
    }
    sma.add(count > 0 ? sum / count : 0.0);
  }
  return sma;
}

List<double> _calculateEWMA(List<double> data, double alpha) {
  final ewma = <double>[];
  if (data.isEmpty) return ewma;

  double current = data.first;
  ewma.add(current);

  for (int i = 1; i < data.length; i++) {
    current = alpha * data[i] + (1 - alpha) * current;
    ewma.add(current);
  }
  return ewma;
}
