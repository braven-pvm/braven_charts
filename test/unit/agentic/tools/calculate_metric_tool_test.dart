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
    test('calculates NP within 1% tolerance', () async {
      final tool = CalculateMetricTool();
      final samples = List<double>.generate(
        60,
        (index) => [200.0, 250.0, 300.0, 150.0, 180.0][index % 5],
      );
      final expected = _referenceNormalizedPower(samples);

      final result = await tool.execute({
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

    test('calculates TSS using Coggan formula', () async {
      final tool = CalculateMetricTool();
      const durationSeconds = 3600.0;
      const np = 250.0;
      const ftp = 300.0;
      const ifValue = np / ftp;
      final expected =
          (durationSeconds * np * ifValue) / (ftp * 3600.0) * 100.0;

      final result = await tool.execute({
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

    test('calculates IF as NP divided by FTP', () async {
      final tool = CalculateMetricTool();
      const np = 250.0;
      const ftp = 300.0;
      const expected = np / ftp;

      final result = await tool.execute({
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

    test('calculates mean correctly', () async {
      final tool = CalculateMetricTool();
      final values = [100.0, 200.0, 300.0];

      final result = await tool.execute({
        'metric': 'mean',
        'values': values,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'Mean result must be numeric');
      if (value is! num) {
        return;
      }
      expect(value.toDouble(), closeTo(200.0, 0.0001));
    });

    test('calculates max correctly', () async {
      final tool = CalculateMetricTool();
      final values = [120.0, 200.0, 150.0];

      final result = await tool.execute({
        'metric': 'max',
        'values': values,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'Max result must be numeric');
      if (value is! num) {
        return;
      }
      expect(value.toDouble(), closeTo(200.0, 0.0001));
    });

    test('calculates min correctly', () async {
      final tool = CalculateMetricTool();
      final values = [120.0, 200.0, 150.0];

      final result = await tool.execute({
        'metric': 'min',
        'values': values,
      });

      final value = result['value'];
      expect(value, isA<num>(), reason: 'Min result must be numeric');
      if (value is! num) {
        return;
      }
      expect(value.toDouble(), closeTo(120.0, 0.0001));
    });

    test('calculates time in zones correctly', () async {
      final tool = CalculateMetricTool();
      final values = [100.0, 120.0, 160.0, 210.0, 260.0];
      final boundaries = [0.0, 150.0, 200.0, 250.0];

      final result = await tool.execute({
        'metric': 'timeInZones',
        'values': values,
        'zoneBoundaries': boundaries,
        'sampleRateHz': 1,
      });

      final value = result['value'];
      expect(value, isA<Map>(), reason: 'timeInZones must return a map');
      if (value is! Map) {
        return;
      }

      expect(value['Zone 1'], closeTo(2.0, 0.0001));
      expect(value['Zone 2'], closeTo(1.0, 0.0001));
      expect(value['Zone 3'], closeTo(2.0, 0.0001));
    });
  });
}
