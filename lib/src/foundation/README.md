# Foundation Layer

The Foundation Layer provides core data structures, performance primitives, type system utilities, and mathematical functions for the Braven Charts library.

**Constitutional Principle**: ZERO dependencies on other chart layers. The Foundation can be used standalone.

---

## Overview

The Foundation layer consists of four main categories:

### 1. Data Models
Core data structures for representing chart data:
- **ChartDataPoint**: Individual (x, y) coordinates with optional timestamp and metadata
- **ChartSeries**: Collections of related data points with computed properties
- **DataRange**: Representation of min/max ranges with operations
- **TimeSeriesData**: Time-based data with aggregation and sampling capabilities

### 2. Performance Primitives
High-performance optimization tools:
- **ObjectPool**: Generic object pooling for reduced allocations
- **ViewportCuller**: Efficient viewport-based data point culling
- **BatchProcessor**: Grouping operations for batch processing

### 3. Type System
Type-safe error handling and validation:
- **ChartResult**: Sealed Result type for functional error handling
- **ChartError**: Structured error representation with types and severity
- **ValidationUtils**: Composable validation utilities

### 4. Math Utilities
Statistical and mathematical functions:
- **StatisticalFunctions**: Central tendency, dispersion, quartiles, correlation
- **InterpolationFunctions**: Linear, cubic spline, Bezier interpolation
- **CurveFittingFunctions**: Linear regression, polynomial fitting

---

## Quick Start

### Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  braven_charts: ^2.0.0
```

Import the foundation layer:
```dart
import 'package:braven_charts/braven_charts.dart';
```

### Basic Usage

#### Creating Chart Data

```dart
// Create individual data points
final point = ChartDataPoint(
  x: 10.0,
  y: 20.0,
  timestamp: DateTime.now(),
  label: 'Data Point 1',
);

// Create a series of points
final series = ChartSeries(
  id: 'revenue-2024',
  name: 'Revenue',
  points: [
    ChartDataPoint(x: 1.0, y: 100.0),
    ChartDataPoint(x: 2.0, y: 150.0),
    ChartDataPoint(x: 3.0, y: 120.0),
  ],
  isXOrdered: true, // Enable optimizations
);

// Access computed properties
print('X Range: ${series.xRange}'); // DataRange(min: 1.0, max: 3.0)
print('Y Range: ${series.yRange}'); // DataRange(min: 100.0, max: 150.0)
```

#### Statistical Analysis

```dart
final data = [1.0, 2.0, 3.0, 4.0, 5.0];

// Central tendency
final mean = StatisticalFunctions.mean(data); // 3.0
final median = StatisticalFunctions.median(data); // 3.0

// Dispersion
final stdDev = StatisticalFunctions.standardDeviation(data);
final variance = StatisticalFunctions.variance(data);

// Quartiles
final quartiles = StatisticalFunctions.quartiles(data);
print('IQR: ${quartiles.iqr}');

// Min/Max
final minMax = StatisticalFunctions.minMax(data);
print('Range: ${minMax.min} to ${minMax.max}');
```

#### Viewport Culling

```dart
final points = List.generate(
  10000,
  (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
);

final culler = ViewportCuller(margin: 0.1);
final visible = culler.cull(
  points: points,
  viewportX: DataRange(min: 1000, max: 2000),
  viewportY: DataRange(min: 0, max: 10000),
  isXOrdered: true,
);

// visible contains only points in viewport + margin
// Performance: <1ms for 10k ordered points
```

#### Object Pooling

```dart
// Create a pool for expensive objects
final pool = ObjectPool<List<int>>(
  factory: () => <int>[],
  reset: (list) => list.clear(),
  maxSize: 10,
);

// Acquire and release objects
for (int i = 0; i < 100; i++) {
  final list = pool.acquire();
  list.add(i);
  // ... use list ...
  pool.release(list);
}

// Check pool efficiency
final stats = pool.statistics;
print('Hit rate: ${stats.hitRate}'); // Should be >0.9 for good pooling
```

#### Error Handling with ChartResult

```dart
ChartResult<double> safeDivide(double a, double b) {
  if (b == 0) {
    return Failure(ChartError.calculation('Division by zero'));
  }
  return Success(a / b);
}

// Pattern matching
final result = safeDivide(10, 2);
final message = result.when(
  success: (value) => 'Result: $value',
  failure: (error) => 'Error: ${error.message}',
);

// Chaining operations
final chainedResult = result
    .map((value) => value * 2)
    .flatMap((value) => safeDivide(value, 2));
```

#### Curve Fitting

```dart
final points = [
  ChartDataPoint(x: 0, y: 1),
  ChartDataPoint(x: 1, y: 3),
  ChartDataPoint(x: 2, y: 5),
  ChartDataPoint(x: 3, y: 7),
];

// Linear regression
final fit = CurveFittingFunctions.linearFit(points);
print('Equation: ${fit.equation}');
print('R²: ${fit.rSquared}');
print('Slope: ${fit.coefficients[1]}');
print('Intercept: ${fit.coefficients[0]}');

// Predict values
final predicted = fit.predict(4.0); // Predict y for x=4
```

---

## Architecture

### Performance Characteristics

All Foundation components meet strict performance targets:

| Component | Target | Achieved |
|-----------|--------|----------|
| ChartDataPoint creation | <1μs | ✅ 0.07μs |
| ChartSeries (100k points) | <100ms | ✅ 10ms |
| ObjectPool acquire/release | <100ns | ✅ <100ns |
| ViewportCuller (10k points) | <1ms | ✅ 150μs |
| Statistics (10k values) | <10ms | ✅ 1-4ms |
| Curve fitting | <50ms | ✅ 0ms |

### Memory Efficiency

- **Zero unnecessary allocations**: Object pooling prevents allocation churn
- **Immutable data structures**: Thread-safe, cacheable
- **Lazy computed properties**: xRange/yRange calculated on first access
- **Efficient viewport culling**: Binary search for ordered data

### Type Safety

- **Sealed Result type**: Compile-time exhaustive pattern matching
- **Immutable value objects**: Prevent accidental mutations
- **Validation utilities**: ChartResult-based composable validation
- **Null safety**: Full Dart 3.0 sound null safety

---

## API Reference

### Data Models

#### ChartDataPoint
```dart
class ChartDataPoint {
  final double x;
  final double y;
  final DateTime? timestamp;
  final String? label;
  final Map<String, dynamic>? metadata;
  
  bool get isValid;
  bool get hasTimestamp;
  bool get hasLabel;
  
  ChartDataPoint copyWith({...});
}
```

#### ChartSeries
```dart
class ChartSeries {
  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  
  bool get isEmpty;
  int get length;
  DataRange get xRange;
  DataRange get yRange;
  
  bool validateOrdering();
  ChartResult<void> validate();
  ChartSeries copyWith({...});
}
```

#### DataRange
```dart
class DataRange {
  final double min;
  final double max;
  
  double get span;
  double get center;
  
  bool contains(double value);
  bool overlaps(DataRange other);
  DataRange merge(DataRange other);
  DataRange withPadding(double fraction);
  
  factory DataRange.fromValues(List<double> values);
  factory DataRange.fromPoints(List<ChartDataPoint> points, Axis axis);
  factory DataRange.symmetric(double center, double radius);
}
```

### Performance Primitives

#### ObjectPool\<T\>
```dart
class ObjectPool<T extends Object> {
  ObjectPool({
    required T Function() factory,
    required void Function(T) reset,
    int maxSize = 10,
  });
  
  T acquire();
  void release(T object);
  void clear();
  
  PoolStatistics get statistics;
}
```

#### ViewportCuller
```dart
class ViewportCuller {
  const ViewportCuller({double margin = 0.0});
  
  List<ChartDataPoint> cull({
    required List<ChartDataPoint> points,
    required DataRange viewportX,
    required DataRange viewportY,
    required bool isXOrdered,
  });
}
```

### Type System

#### ChartResult\<T\>
```dart
sealed class ChartResult<T> {
  bool get isSuccess;
  bool get isFailure;
  
  T? getOrNull();
  T getOrElse(T defaultValue);
  T getOrThrow();
  
  R when<R>({
    required R Function(T) success,
    required R Function(ChartError) failure,
  });
  
  ChartResult<R> map<R>(R Function(T) transform);
  ChartResult<R> flatMap<R>(ChartResult<R> Function(T) transform);
}

class Success<T> extends ChartResult<T> {
  const Success(this.value);
  final T value;
}

class Failure<T> extends ChartResult<T> {
  const Failure(this.error);
  final ChartError error;
}
```

### Math Utilities

#### StatisticalFunctions
```dart
class StatisticalFunctions {
  // Central Tendency
  static double mean(List<double> values, {MeanType type});
  static double median(List<double> values);
  static double mode(List<double> values);
  
  // Dispersion
  static double variance(List<double> values);
  static double standardDeviation(List<double> values);
  static Quartiles quartiles(List<double> values);
  static MinMax minMax(List<double> values);
  
  // Correlation
  static double covariance(List<double> x, List<double> y);
  static double pearsonCorrelation(List<double> x, List<double> y);
}
```

#### InterpolationFunctions
```dart
class InterpolationFunctions {
  static double lerp(double a, double b, double t);
  static ChartDataPoint lerpPoint(ChartDataPoint a, ChartDataPoint b, double t);
  static double cubicSpline(List<ChartDataPoint> points, double x);
  static ChartDataPoint bezierQuadratic(ChartDataPoint p0, ChartDataPoint p1, ChartDataPoint p2, double t);
  static ChartDataPoint bezierCubic(ChartDataPoint p0, ChartDataPoint p1, ChartDataPoint p2, ChartDataPoint p3, double t);
}
```

#### CurveFittingFunctions
```dart
class CurveFittingFunctions {
  static FitResult linearFit(List<ChartDataPoint> points);
  static FitResult polynomialFit(List<ChartDataPoint> points, int degree);
}

class FitResult {
  final List<double> coefficients;
  final double rSquared;
  final String equation;
  
  double predict(double x);
}
```

---

## Testing

The Foundation layer has comprehensive test coverage:

- **Unit Tests**: 100% line coverage
- **Contract Tests**: All API contracts validated
- **Integration Tests**: 52 comprehensive integration tests
- **Performance Tests**: All FR-005 targets validated

Run tests:
```bash
# Unit tests
flutter test test/unit/foundation/

# Contract tests
flutter test test/contract/foundation/

# Integration tests
flutter test test/integration_test/

# Performance tests
flutter test test/performance/foundation/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Performance Optimization Guide

### 1. Use `isXOrdered` for Large Datasets

When data points are sorted by x-value, set `isXOrdered: true`:

```dart
final series = ChartSeries(
  id: 'time-series',
  points: sortedPoints,
  isXOrdered: true, // Enables binary search optimizations
);
```

Benefits:
- ViewportCuller uses O(log n) binary search instead of O(n) linear scan
- Validation checks ordering once, not on every operation

### 2. Object Pooling for Frequent Allocations

Use ObjectPool for objects created/destroyed frequently:

```dart
// Good: Pool Paint objects
final paintPool = ObjectPool<Paint>(
  factory: () => Paint(),
  reset: (paint) {
    paint.reset();
    paint.color = Colors.white;
  },
  maxSize: 20,
);

// Avoid: Creating new Paint objects every frame
// final paint = Paint(); // ❌ Creates garbage
```

### 3. Viewport Culling for Large Datasets

Always cull points before rendering:

```dart
final visible = culler.cull(
  points: allPoints,
  viewportX: currentViewportX,
  viewportY: currentViewportY,
  isXOrdered: series.isXOrdered,
);

// Render only visible points
for (final point in visible) {
  canvas.drawCircle(/* ... */);
}
```

### 4. Batch Processing for Grouping

Use BatchProcessor for efficient grouping:

```dart
final processor = BatchProcessor<ChartDataPoint, Color>(
  keyExtractor: (point) => point.metadata?['color'] ?? Colors.blue,
);

final batches = processor.batch(points);
// Render each color group in one draw call
```

---

## Best Practices

### 1. Immutability

All data models are immutable. Use `copyWith` for modifications:

```dart
final modified = point.copyWith(y: newValue);
// Original point unchanged, new point created
```

### 2. Error Handling

Use ChartResult for operations that can fail:

```dart
ChartResult<ChartSeries> createSeries(List<ChartDataPoint> points) {
  if (points.isEmpty) {
    return Failure(ChartError.validation('Points cannot be empty'));
  }
  
  final series = ChartSeries(id: 'series', points: points);
  return series.validate().map((_) => series);
}
```

### 3. Validation

Validate data early with ValidationUtils:

```dart
final result = ValidationUtils.validateAll([
  ValidationUtils.validateFinite(x, 'x'),
  ValidationUtils.validateFinite(y, 'y'),
  ValidationUtils.requireNonNull(label, 'label'),
]);

result.when(
  success: (_) => print('Valid!'),
  failure: (error) => print('Invalid: ${error.message}'),
);
```

---

## Common Patterns

### Pattern 1: Creating Time Series Data

```dart
final timeData = TimeSeriesData(
  id: 'temperature',
  data: measurements.map((m) => ChartDataPoint(
    x: m.timestamp.millisecondsSinceEpoch.toDouble(),
    y: m.temperature,
    timestamp: m.timestamp,
  )).toList(),
);

// Sample to hourly data
final hourly = timeData.sample(Duration(hours: 1));
```

### Pattern 2: Statistical Summary

```dart
void printSummary(List<double> data) {
  final mean = StatisticalFunctions.mean(data);
  final median = StatisticalFunctions.median(data);
  final stdDev = StatisticalFunctions.standardDeviation(data);
  final quartiles = StatisticalFunctions.quartiles(data);
  
  print('Mean: $mean');
  print('Median: $median');
  print('Std Dev: $stdDev');
  print('Q1: ${quartiles.q1}, Q3: ${quartiles.q3}');
  print('IQR: ${quartiles.iqr}');
}
```

### Pattern 3: Trendline Calculation

```dart
ChartSeries addTrendline(ChartSeries series) {
  final fit = CurveFittingFunctions.linearFit(series.points);
  
  final trendPoints = series.points.map((p) => 
    ChartDataPoint(
      x: p.x,
      y: fit.predict(p.x),
    )
  ).toList();
  
  return ChartSeries(
    id: '${series.id}-trend',
    name: '${series.name} Trend',
    points: trendPoints,
    isXOrdered: series.isXOrdered,
  );
}
```

---

## Troubleshooting

### Performance Issues

**Problem**: Slow rendering with large datasets  
**Solution**: Enable viewport culling and ensure `isXOrdered: true` for sorted data

**Problem**: High memory usage  
**Solution**: Use object pooling for frequently allocated objects

**Problem**: Slow statistical calculations  
**Solution**: Ensure data is preprocessed once, not recalculated every frame

### Data Validation

**Problem**: NaN or Infinity in calculations  
**Solution**: Use `point.isValid` to filter invalid points before processing

**Problem**: Unordered data causing incorrect culling  
**Solution**: Sort points and set `isXOrdered: true`, or set `isXOrdered: false`

### Error Handling

**Problem**: Exceptions being thrown  
**Solution**: Use ChartResult-returning methods for graceful error handling

**Problem**: Unclear error messages  
**Solution**: ChartError includes context map for debugging details

---

## Migration Guide

### From v1.x to v2.0

The Foundation layer is new in v2.0. Key differences:

1. **Result Type**: Error handling now uses ChartResult instead of exceptions
2. **Immutability**: All data models are immutable (use copyWith)
3. **Performance Primitives**: New ObjectPool, ViewportCuller, BatchProcessor
4. **Validation**: New ValidationUtils for composable validation

---

## Contributing

The Foundation layer follows strict quality standards:

- **100% test coverage** required
- **All performance targets** must be met
- **Zero dependencies** on other chart layers
- **Comprehensive documentation** for all public APIs

See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for details.

---

## License

MIT License - see [LICENSE](../../../LICENSE) for details.

---

## Support

- **Documentation**: See inline DartDoc comments
- **Examples**: See `quickstart.md` and test files
- **Issues**: [GitHub Issues](https://github.com/forcegage-pvm/braven_charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/forcegage-pvm/braven_charts/discussions)
