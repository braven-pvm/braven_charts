import 'dart:math' as math;

import 'package:braven_charts/src/agentic/tools/calculate_metric_tool.dart';
import 'package:test/test.dart';

double _referenceNormalizedPower(
  List<double> samples, {
  int windowSeconds = 30,
  double sampleRateHz = 1,
}) {
  if (samples.isEmpty) {
    return 0;
  }

  var windowSize = (windowSeconds * sampleRateHz).round();
  if (windowSize <= 0) {
    windowSize = 1;
  }
  if (samples.length < windowSize) {
    windowSize = samples.length;
  }

  final rollingAverages = <double>[];
  for (var start = 0; start <= samples.length - windowSize; start += 1) {
    var sum = 0.0;
    for (var i = 0; i < windowSize; i += 1) {
      sum += samples[start + i];
    }
    rollingAverages.add(sum / windowSize);
  }

  final fourthPowers =
      rollingAverages.map((value) => math.pow(value, 4).toDouble()).toList();

  final averageFourthPower =
      fourthPowers.reduce((a, b) => a + b) / fourthPowers.length;

  return math.pow(averageFourthPower, 0.25).toDouble();
}

void main() {
  group('CalculateMetricTool', () {
    test('calculates NP within 1% tolerance', () {
      const tool = CalculateMetricTool();
      final samples = List<double>.generate(
        60,
        (index) => [200.0, 250.0, 300.0, 150.0, 180.0][index % 5],
      );
      final expected = _referenceNormalizedPower(samples);

      final result = tool.execute({
        'metric': 'np',
        'power': samples,
        'sampleRateHz': 1,
        'windowSeconds': 30,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'NP result must be numeric');
      if (value is! num) {
        return;
      }
      final np = value.toDouble();
      final tolerance = expected * 0.01;
      expect(
        (np - expected).abs(),
        lessThanOrEqualTo(tolerance),
        reason: 'NP must be within 1% of reference calculation',
      );
    });

    test('calculates TSS using Coggan formula', () {
      const tool = CalculateMetricTool();
      const durationSeconds = 3600.0;
      const np = 250.0;
      const ftp = 300.0;
      const ifValue = np / ftp;
      final expected =
          (durationSeconds * np * ifValue) / (ftp * 3600.0) * 100.0;

      final result = tool.execute({
        'metric': 'tss',
        'durationSeconds': durationSeconds,
        'np': np,
        'if': ifValue,
        'ftp': ftp,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'TSS result must be numeric');
      if (value is! num) {
        return;
      }
      expect(value.toDouble(), closeTo(expected, 0.01));
    });

    test('calculates IF as NP divided by FTP', () {
      const tool = CalculateMetricTool();
      const np = 250.0;
      const ftp = 300.0;
      const expected = np / ftp;

      final result = tool.execute({
        'metric': 'if',
        'np': np,
        'ftp': ftp,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'IF result must be numeric');
      if (value is! num) {
        return;
      }
      expect(value.toDouble(), closeTo(expected, 0.0001));
    });
  });
}
