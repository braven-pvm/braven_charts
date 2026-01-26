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

    final indices = downsampleIndices(data.length, targetCount);
    return indices.map((index) => data[index]).toList();
  }

  List<int> downsampleIndices(int length, int targetCount) {
    if (length <= 0) {
      return <int>[];
    }

    if (targetCount >= length) {
      return List<int>.generate(length, (index) => index);
    }

    if (targetCount < 2) {
      return <int>[0];
    }

    final result = <int>[0];
    final bucketSize = (length - 2) / (targetCount - 2);

    for (var i = 0; i < targetCount - 2; i++) {
      final index = (1 + (i * bucketSize)).round();
      final clampedIndex = index.clamp(1, length - 2);
      result.add(clampedIndex);
    }

    result.add(length - 1);
    return result;
  }
}
