import 'dart:math' as math;

/// Sample data generator for charts
class ChartDataGenerator {
  static final _random = math.Random(42); // Fixed seed for reproducibility

  /// Generate simple linear data
  static List<DataPoint> generateLinearData({
    int pointCount = 10,
    double startX = 0,
    double endX = 100,
    double startY = 0,
    double slope = 1,
    double noise = 5,
  }) {
    final points = <DataPoint>[];
    final step = (endX - startX) / (pointCount - 1);
    
    for (int i = 0; i < pointCount; i++) {
      final x = startX + (i * step);
      final y = startY + (slope * x) + (_random.nextDouble() * noise * 2 - noise);
      points.add(DataPoint(x, y));
    }
    
    return points;
  }

  /// Generate sine wave data
  static List<DataPoint> generateSineWave({
    int pointCount = 50,
    double startX = 0,
    double endX = 360,
    double amplitude = 50,
    double offset = 50,
    double frequency = 1,
  }) {
    final points = <DataPoint>[];
    final step = (endX - startX) / (pointCount - 1);
    
    for (int i = 0; i < pointCount; i++) {
      final x = startX + (i * step);
      final radians = x * math.pi / 180 * frequency;
      final y = offset + (amplitude * math.sin(radians));
      points.add(DataPoint(x, y));
    }
    
    return points;
  }

  /// Generate random data
  static List<DataPoint> generateRandomData({
    int pointCount = 20,
    double minX = 0,
    double maxX = 100,
    double minY = 0,
    double maxY = 100,
  }) {
    final points = <DataPoint>[];
    final step = (maxX - minX) / (pointCount - 1);
    
    for (int i = 0; i < pointCount; i++) {
      final x = minX + (i * step);
      final y = minY + (_random.nextDouble() * (maxY - minY));
      points.add(DataPoint(x, y));
    }
    
    return points;
  }

  /// Generate categorical data (for bar charts)
  static List<CategoricalData> generateCategoricalData({
    int categoryCount = 6,
    int seriesCount = 2,
    double minValue = 10,
    double maxValue = 100,
    bool allowNegative = false,
  }) {
    final categories = <CategoricalData>[];
    final categoryNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    for (int i = 0; i < categoryCount; i++) {
      final values = <double>[];
      for (int s = 0; s < seriesCount; s++) {
        var value = minValue + (_random.nextDouble() * (maxValue - minValue));
        if (allowNegative && _random.nextBool()) {
          value = -value;
        }
        values.add(value);
      }
      categories.add(CategoricalData(
        categoryNames[i % categoryNames.length],
        values,
      ));
    }

    return categories;
  }

  /// Generate scatter data with optional size
  static List<ScatterPoint> generateScatterData({
    int pointCount = 30,
    double minX = 0,
    double maxX = 100,
    double minY = 0,
    double maxY = 100,
    double minSize = 5,
    double maxSize = 20,
    bool includeSize = false,
  }) {
    final points = <ScatterPoint>[];
    
    for (int i = 0; i < pointCount; i++) {
      final x = minX + (_random.nextDouble() * (maxX - minX));
      final y = minY + (_random.nextDouble() * (maxY - minY));
      final size = includeSize
          ? minSize + (_random.nextDouble() * (maxSize - minSize))
          : null;
      points.add(ScatterPoint(x, y, size: size));
    }
    
    return points;
  }

  /// Generate time series data
  static List<DataPoint> generateTimeSeriesData({
    int dayCount = 30,
    double startValue = 100,
    double volatility = 5,
    double trend = 0.5,
  }) {
    final points = <DataPoint>[];
    var currentValue = startValue;
    
    for (int i = 0; i < dayCount; i++) {
      final change = (_random.nextDouble() * volatility * 2 - volatility) + trend;
      currentValue = math.max(0, currentValue + change);
      points.add(DataPoint(i.toDouble(), currentValue));
    }
    
    return points;
  }
}

/// Simple data point with x, y coordinates
class DataPoint {
  final double x;
  final double y;

  const DataPoint(this.x, this.y);

  @override
  String toString() => 'DataPoint($x, $y)';
}

/// Categorical data for bar charts
class CategoricalData {
  final String category;
  final List<double> values;

  const CategoricalData(this.category, this.values);

  @override
  String toString() => 'CategoricalData($category, $values)';
}

/// Scatter point with optional size
class ScatterPoint {
  final double x;
  final double y;
  final double? size;

  const ScatterPoint(this.x, this.y, {this.size});

  @override
  String toString() => 'ScatterPoint($x, $y${size != null ? ', size: $size' : ''})';
}
