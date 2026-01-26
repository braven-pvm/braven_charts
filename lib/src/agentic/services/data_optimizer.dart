// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

class DataPoint {
  const DataPoint(this.x, this.y);

  final double x;
  final double y;
}

class DataOptimizer {
  List<DataPoint> downsample(List<DataPoint> data, int targetCount) {
    if (data.isEmpty) {
      return <DataPoint>[];
    }

    if (data.length <= 100000 || targetCount >= data.length) {
      return List<DataPoint>.from(data);
    }

    if (targetCount < 2) {
      return <DataPoint>[data.first];
    }

    final result = <DataPoint>[data.first];
    final bucketSize = (data.length - 2) / (targetCount - 2);

    for (var i = 0; i < targetCount - 2; i++) {
      final index = (1 + (i * bucketSize)).round();
      final clampedIndex = index.clamp(1, data.length - 2);
      result.add(data[clampedIndex]);
    }

    result.add(data.last);
    return result;
  }
}
