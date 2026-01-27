import 'dart:math' as math;

import 'llm_tool.dart';

class CalculateMetricTool extends LLMTool {
  @override
  String get name => 'calculate_metric';

  @override
  String get description =>
      'Calculates sport science metrics (NP, TSS, IF, mean, max, min, timeInZones).';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'metric': {
            'type': 'string',
            'enum': ['np', 'tss', 'if', 'mean', 'max', 'min', 'timeInZones'],
            'description': 'Metric to calculate.'
          },
          'power': {
            'type': 'array',
            'items': {'type': 'number'},
            'description': 'Time-series samples for power (alias of values).'
          },
          'values': {
            'type': 'array',
            'items': {'type': 'number'},
            'description': 'Time-series samples.'
          },
          'sampleRateHz': {
            'type': 'number',
            'description': 'Samples per second (for NP/timeInZones).'
          },
          'windowSeconds': {
            'type': 'number',
            'description': 'Rolling window size in seconds for NP.'
          },
          'durationSeconds': {
            'type': 'number',
            'description': 'Workout duration in seconds for TSS.'
          },
          'np': {
            'type': 'number',
            'description': 'Normalized power value.'
          },
          'ftp': {
            'type': 'number',
            'description': 'Functional threshold power.'
          },
          'if': {
            'type': 'number',
            'description': 'Intensity factor.'
          },
          'zoneBoundaries': {
            'type': 'array',
            'items': {'type': 'number'},
            'description': 'Zone threshold boundaries for timeInZones.'
          }
        },
        'required': ['metric'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final metric = (params['metric'] ?? '').toString().toLowerCase();
    switch (metric) {
      case 'np':
        return {'value': _normalizedPower(params)};
      case 'tss':
        return {'value': _trainingStressScore(params)};
      case 'if':
        return {'value': _intensityFactor(params)};
      case 'mean':
        return {'value': _mean(params)};
      case 'max':
        return {'value': _max(params)};
      case 'min':
        return {'value': _min(params)};
      case 'timeinzones':
        return {'value': _timeInZones(params)};
      default:
        return {'value': 0.0};
    }
  }

  double _normalizedPower(Map<String, dynamic> params) {
    final samples =
        _toDoubleList(params['power'] ?? params['values'] ?? params['samples']);
    if (samples.isEmpty) {
      return 0.0;
    }

    final sampleRateHz = _toDouble(params['sampleRateHz'], fallback: 1.0);
    final windowSeconds = _toInt(params['windowSeconds'], fallback: 30);
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

  double _trainingStressScore(Map<String, dynamic> params) {
    final durationSeconds = _toDouble(params['durationSeconds']);
    final np = _toDouble(params['np']);
    final ftp = _toDouble(params['ftp']);

    if (durationSeconds <= 0 || np <= 0 || ftp <= 0) {
      return 0.0;
    }

    final ifValue =
        params.containsKey('if') ? _toDouble(params['if']) : (np / ftp);

    return (durationSeconds * np * ifValue) / (ftp * 3600.0) * 100.0;
  }

  double _intensityFactor(Map<String, dynamic> params) {
    final np = _toDouble(params['np']);
    final ftp = _toDouble(params['ftp']);
    if (ftp <= 0) {
      return 0.0;
    }
    return np / ftp;
  }

  double _mean(Map<String, dynamic> params) {
    final values = _toDoubleList(params['values'] ?? params['power']);
    if (values.isEmpty) {
      return 0.0;
    }
    final total = values.reduce((a, b) => a + b);
    return total / values.length;
  }

  double _max(Map<String, dynamic> params) {
    final values = _toDoubleList(params['values'] ?? params['power']);
    if (values.isEmpty) {
      return 0.0;
    }
    return values.reduce(math.max);
  }

  double _min(Map<String, dynamic> params) {
    final values = _toDoubleList(params['values'] ?? params['power']);
    if (values.isEmpty) {
      return 0.0;
    }
    return values.reduce(math.min);
  }

  Map<String, double> _timeInZones(Map<String, dynamic> params) {
    final values = _toDoubleList(params['values'] ?? params['power']);
    final boundaries = _toDoubleList(params['zoneBoundaries']);
    final sampleRateHz = _toDouble(params['sampleRateHz'], fallback: 1.0);

    if (values.isEmpty || boundaries.length < 2 || sampleRateHz <= 0) {
      return {};
    }

    final zoneCount = boundaries.length - 1;
    final secondsPerSample = 1.0 / sampleRateHz;
    final zoneSeconds = List<double>.filled(zoneCount, 0.0);

    for (final value in values) {
      var zoneIndex = 0;
      if (value >= boundaries.last) {
        zoneIndex = zoneCount - 1;
      } else {
        for (var i = 0; i < zoneCount; i += 1) {
          if (value >= boundaries[i] && value < boundaries[i + 1]) {
            zoneIndex = i;
            break;
          }
        }
      }
      zoneSeconds[zoneIndex] += secondsPerSample;
    }

    final result = <String, double>{};
    for (var i = 0; i < zoneCount; i += 1) {
      result['Zone ${i + 1}'] = zoneSeconds[i];
    }
    return result;
  }

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  List<double> _toDoubleList(dynamic value) {
    if (value is List) {
      return value.map((entry) => _toDouble(entry)).toList();
    }
    return <double>[];
  }
}
