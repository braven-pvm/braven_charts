// Copyright 2025 Braven Charts - Data Generator Utilities
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';

/// Utility class for generating sample chart data.
///
/// Provides various data patterns useful for demos and testing.
class DataGenerator {
  static final math.Random _random = math.Random();

  /// Generates a sine wave pattern.
  ///
  /// [count] - Number of data points
  /// [frequency] - Wave frequency (higher = more cycles)
  /// [amplitude] - Wave height from center
  /// [phase] - Phase offset in radians
  /// [noise] - Random noise amplitude
  /// [startX] - Starting X value
  /// [stepX] - X increment per point
  /// [yOffset] - Vertical offset from zero
  static List<ChartDataPoint> generateSineWave({
    int count = 50,
    double frequency = 0.2,
    double amplitude = 30.0,
    double phase = 0.0,
    double noise = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
    double yOffset = 50.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = yOffset +
          amplitude * math.sin(frequency * x + phase) +
          (noise > 0 ? (_random.nextDouble() - 0.5) * noise : 0.0);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates a cosine wave pattern.
  static List<ChartDataPoint> generateCosineWave({
    int count = 50,
    double frequency = 0.2,
    double amplitude = 30.0,
    double phase = 0.0,
    double noise = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
    double yOffset = 50.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = yOffset +
          amplitude * math.cos(frequency * x + phase) +
          (noise > 0 ? (_random.nextDouble() - 0.5) * noise : 0.0);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates a linear trend with optional noise.
  static List<ChartDataPoint> generateLinear({
    int count = 50,
    double slope = 1.0,
    double intercept = 0.0,
    double noise = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = intercept +
          slope * x +
          (noise > 0 ? (_random.nextDouble() - 0.5) * noise : 0.0);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates random data points within bounds.
  static List<ChartDataPoint> generateRandom({
    int count = 50,
    double minY = 0.0,
    double maxY = 100.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = minY + _random.nextDouble() * (maxY - minY);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates a random walk pattern (cumulative random steps).
  static List<ChartDataPoint> generateRandomWalk({
    int count = 50,
    double startY = 50.0,
    double stepSize = 5.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    double currentY = startY;
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      if (i > 0) {
        currentY += (_random.nextDouble() - 0.5) * stepSize;
      }
      return ChartDataPoint(x: x, y: currentY);
    });
  }

  /// Generates step function data (staircase pattern).
  static List<ChartDataPoint> generateSteps({
    int count = 50,
    int stepsPerLevel = 10,
    double levelHeight = 20.0,
    double baseY = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final level = i ~/ stepsPerLevel;
      final y = baseY + level * levelHeight;
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates exponential growth/decay pattern.
  static List<ChartDataPoint> generateExponential({
    int count = 50,
    double base = 1.05,
    double scale = 10.0,
    double startX = 0.0,
    double stepX = 1.0,
    double yOffset = 0.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = yOffset + scale * math.pow(base, i);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates Gaussian/bell curve data.
  static List<ChartDataPoint> generateGaussian({
    int count = 50,
    double mean = 25.0,
    double stdDev = 10.0,
    double amplitude = 100.0,
    double startX = 0.0,
    double stepX = 1.0,
    double yOffset = 0.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final exponent = -math.pow(x - mean, 2) / (2 * math.pow(stdDev, 2));
      final y = yOffset + amplitude * math.exp(exponent);
      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates power output data (athletic performance simulation).
  ///
  /// Simulates realistic power meter data with:
  /// - Base power level varying by "phase"
  /// - Random noise
  /// - Occasional power spikes
  static List<ChartDataPoint> generatePowerData({
    int count = 500,
    double basePower = 150.0,
    double noise = 15.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;

      // Vary base power by "phase" to simulate intervals
      double phasePower = basePower;
      final phase = (i ~/ 50) % 4;
      switch (phase) {
        case 0:
          phasePower = basePower * 1.2; // High intensity
        case 1:
          phasePower = basePower * 0.8; // Recovery
        case 2:
          phasePower = basePower * 1.0; // Steady
        case 3:
          phasePower = basePower * 1.1; // Moderate
      }

      // Add noise and occasional spikes
      final noiseVal = (_random.nextDouble() - 0.5) * noise;
      final spike = _random.nextDouble() < 0.02 ? _random.nextDouble() * 30 : 0;
      final y = (phasePower + noiseVal + spike).clamp(50.0, 400.0);

      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates heart rate data (athletic performance simulation).
  ///
  /// Simulates realistic heart rate with gradual changes and variability.
  static List<ChartDataPoint> generateHeartRateData({
    int count = 500,
    double baseHR = 140.0,
    double noise = 5.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    double currentHR = baseHR;
    return List.generate(count, (i) {
      final x = startX + i * stepX;

      // Gradually drift HR based on effort phase
      final phase = (i ~/ 50) % 4;
      final targetHR = switch (phase) {
        0 => baseHR + 30, // High intensity
        1 => baseHR - 20, // Recovery
        2 => baseHR, // Steady
        _ => baseHR + 10, // Moderate (case 3 and any other)
      };

      // Gradual approach to target
      currentHR = currentHR + (targetHR - currentHR) * 0.05;

      // Add variability
      final noiseVal = (_random.nextDouble() - 0.5) * noise;
      final y = (currentHR + noiseVal).clamp(60.0, 200.0);

      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates cadence data (cycling RPM simulation).
  static List<ChartDataPoint> generateCadenceData({
    int count = 500,
    double baseCadence = 85.0,
    double noise = 3.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    return List.generate(count, (i) {
      final x = startX + i * stepX;

      // Vary cadence by phase
      final phase = (i ~/ 50) % 4;
      final phaseCadence = switch (phase) {
        0 => baseCadence + 10, // High cadence
        1 => baseCadence - 15, // Recovery
        2 => baseCadence, // Steady
        _ => baseCadence + 5, // Moderate (case 3 and any other)
      };

      final noiseVal = (_random.nextDouble() - 0.5) * noise;
      final y = (phaseCadence + noiseVal).clamp(40.0, 120.0);

      return ChartDataPoint(x: x, y: y);
    });
  }

  /// Generates temperature data with gradual drift.
  static List<ChartDataPoint> generateTemperatureData({
    int count = 100,
    double baseTemp = 20.0,
    double drift = 0.1,
    double noise = 0.5,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    double currentTemp = baseTemp;
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      currentTemp += drift + (_random.nextDouble() - 0.5) * noise;
      return ChartDataPoint(x: x, y: currentTemp);
    });
  }

  /// Creates smoothed version of data using moving average.
  static List<ChartDataPoint> smooth(
    List<ChartDataPoint> data, {
    int windowSize = 5,
  }) {
    if (data.length < windowSize) return data;

    final smoothed = <ChartDataPoint>[];
    final halfWindow = windowSize ~/ 2;

    for (int i = 0; i < data.length; i++) {
      final start = math.max(0, i - halfWindow);
      final end = math.min(data.length, i + halfWindow + 1);

      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += data[j].y;
      }
      final avg = sum / (end - start);

      smoothed.add(ChartDataPoint(x: data[i].x, y: avg));
    }

    return smoothed;
  }

  /// Downsamples data to reduce point count while preserving shape.
  static List<ChartDataPoint> downsample(
    List<ChartDataPoint> data, {
    int targetCount = 100,
  }) {
    if (data.length <= targetCount) return data;

    final step = data.length / targetCount;
    final result = <ChartDataPoint>[];

    for (int i = 0; i < targetCount; i++) {
      final index = (i * step).floor();
      if (index < data.length) {
        result.add(data[index]);
      }
    }

    return result;
  }
}
