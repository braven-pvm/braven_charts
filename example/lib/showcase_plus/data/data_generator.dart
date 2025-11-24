import 'dart:math' as math;

import 'package:braven_charts/src_plus/models/chart_data_point.dart';

class DataGenerator {
  static List<ChartDataPoint> generateSineWave({
    int count = 20,
    double frequency = 1.0,
    double amplitude = 10.0,
    double phase = 0.0,
    double noise = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
    double yOffset = 0.0,
  }) {
    final random = math.Random();
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = yOffset + amplitude * math.sin(frequency * x + phase) + (noise > 0 ? (random.nextDouble() - 0.5) * noise : 0.0);
      return ChartDataPoint(x: x, y: y);
    });
  }

  static List<ChartDataPoint> generateLinear({
    int count = 20,
    double slope = 1.0,
    double intercept = 0.0,
    double noise = 0.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    final random = math.Random();
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = intercept + slope * x + (noise > 0 ? (random.nextDouble() - 0.5) * noise : 0.0);
      return ChartDataPoint(x: x, y: y);
    });
  }

  static List<ChartDataPoint> generateRandom({
    int count = 20,
    double min = 0.0,
    double max = 100.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    final random = math.Random();
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      final y = min + random.nextDouble() * (max - min);
      return ChartDataPoint(x: x, y: y);
    });
  }

  static List<ChartDataPoint> generateWalk({
    int count = 20,
    double startY = 50.0,
    double stepSize = 5.0,
    double startX = 0.0,
    double stepX = 1.0,
  }) {
    final random = math.Random();
    double currentY = startY;
    return List.generate(count, (i) {
      final x = startX + i * stepX;
      if (i > 0) {
        currentY += (random.nextDouble() - 0.5) * stepSize;
      }
      return ChartDataPoint(x: x, y: currentY);
    });
  }
}
