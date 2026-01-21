# Foundation Layer: Quickstart Guide

**Feature**: Foundation Layer  
**Date**: 2025-10-04  
**Purpose**: Validate foundation implementation through practical examples

---

## Overview

This quickstart demonstrates all Foundation layer components through practical test scenarios. Each section MUST pass before moving to higher layers.

**Prerequisites**:
- Dart 3.0+ installed
- Flutter SDK 3.10.0+ installed
- All foundation tests passing (100% coverage)

---

## Test Scenario 1: Data Models (FR-001)

### Goal
Create and manipulate chart data structures with 100k points in <100ms.

### Steps

**1.1 Create Individual Data Points**
```dart
import 'package:braven_charts/src/foundation/foundation.dart';

void testDataPoints() {
  // Create simple point
  final point1 = ChartDataPoint(x: 10.0, y: 20.0);
  assert(point1.x == 10.0);
  assert(point1.y == 20.0);
  assert(!point1.hasTimestamp);
  
  // Create point with timestamp
  final point2 = ChartDataPoint(
    x: 15.0,
    y: 25.0,
    timestamp: DateTime(2024, 1, 1),
    label: 'Data Point',
  );
  assert(point2.hasTimestamp);
  assert(point2.hasLabel);
  
  // Test immutability
  final point3 = point1.copyWith(y: 30.0);
  assert(point1.y == 20.0); // Original unchanged
  assert(point3.y == 30.0); // New point updated
  
  // Test validation
  assert(point1.isValid); // Finite numbers
  assert(!ChartDataPoint(x: double.nan, y: 5.0).isValid); // NaN invalid
}
```

**Expected Result**: All assertions pass, point creation <1μs each (FR-005.1)

---

**1.2 Create Chart Series with 100k Points**
```dart
void testLargeDataset() {
  final stopwatch = Stopwatch()..start();
  
  // Generate 100k points
  final points = List.generate(
    100000,
    (i) => ChartDataPoint(x: i.toDouble(), y: (i * 0.5)),
  );
  
  // Create series
  final series = ChartSeries(
    id: 'large-dataset',
    name: 'Performance Test',
    points: points,
    isXOrdered: true, // Points sorted by x
  );
  
  stopwatch.stop();
  
  // Validate
  assert(series.length == 100000);
  assert(series.isXOrdered);
  assert(series.validateOrdering()); // Verify actual order
  assert(stopwatch.elapsedMilliseconds < 100); // <100ms (FR-005.2)
  
  // Check computed properties
  final xRange = series.xRange;
  assert(xRange.min == 0.0);
  assert(xRange.max == 99999.0);
  
  // Memory check (manual validation)
  // Series should occupy <10MB for 100k points (FR-005.2)
  print('Series created in ${stopwatch.elapsedMilliseconds}ms');
}
```

**Expected Result**: 
- Series creation <100ms
- Memory usage <10MB (verify with profiler)
- All assertions pass

---

**1.3 Data Range Calculations**
```dart
void testDataRanges() {
  final values = [10.0, 20.0, 15.0, 30.0, 25.0];
  
  // Auto-calculate range
  final range1 = DataRange.fromValues(values);
  assert(range1.min == 10.0);
  assert(range1.max == 30.0);
  assert(range1.span == 20.0);
  assert(range1.center == 20.0);
  
  // Range with padding
  final range2 = DataRange.fromValues(values, padding: 0.1);
  assert(range2.paddedMin == 8.0);  // 10 - (20 * 0.1)
  assert(range2.paddedMax == 32.0); // 30 + (20 * 0.1)
  
  // Symmetric range
  final range3 = DataRange.symmetric(100.0, 50.0);
  assert(range3.min == 50.0);
  assert(range3.max == 150.0);
  
  // Range operations
  assert(range1.contains(15.0));
  assert(!range1.contains(5.0));
}
```

**Expected Result**: All range calculations correct, operations complete instantly

---

## Test Scenario 2: Performance Primitives (FR-002)

### Goal
Validate object pooling, viewport culling, and batching performance targets.

### Steps

**2.1 ObjectPool Performance**
```dart
void testObjectPool() {
  // Create pool for Paint objects
  final pool = ObjectPool<Paint>(
    factory: () => Paint(),
    reset: (paint) {
      paint.color = Colors.black;
      paint.strokeWidth = 1.0;
      paint.style = PaintingStyle.fill;
    },
    maxSize: 100,
  );
  
  final stopwatch = Stopwatch();
  
  // Test acquire performance (<100ns target)
  stopwatch.start();
  final paint1 = pool.acquire();
  stopwatch.stop();
  assert(stopwatch.elapsedMicroseconds < 1); // <1μs = 1000ns
  
  // Modify and release
  paint1.color = Colors.red;
  stopwatch.reset();
  stopwatch.start();
  pool.release(paint1);
  stopwatch.stop();
  assert(stopwatch.elapsedMicroseconds < 1); // <1μs = 1000ns (FR-005.3)
  
  // Verify reset on acquire
  final paint2 = pool.acquire();
  assert(paint2.color == Colors.black); // Reset worked
  
  // Check statistics
  final stats = pool.statistics;
  assert(stats.acquireCount == 2);
  assert(stats.releaseCount == 1);
  assert(stats.currentInUse == 1);
  assert(stats.hitRate > 0.0); // Reuse occurred
  
  pool.release(paint2);
  print('ObjectPool hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
}
```

**Expected Result**:
- Acquire <100ns (FR-005.3)
- Release <100ns (FR-005.3)
- Hit rate >90% after warmup

---

**2.2 ViewportCuller Performance**
```dart
void testViewportCuller() {
  // Create 10k points
  final points = List.generate(
    10000,
    (i) => ChartDataPoint(x: i.toDouble(), y: i * 0.5),
  );
  
  final culler = ViewportCuller(margin: 0.1);
  final viewport = DataRange(min: 1000.0, max: 2000.0);
  
  // Test culling performance
  final stopwatch = Stopwatch()..start();
  final visible = culler.cull(
    points: points,
    viewportX: viewport,
    viewportY: DataRange(min: 0.0, max: 10000.0),
    isXOrdered: true, // Enable binary search
  );
  stopwatch.stop();
  
  // Validate
  assert(stopwatch.elapsedMilliseconds < 1); // <1ms (FR-005.4)
  assert(visible.length < points.length); // Culling worked
  assert(visible.every((p) => viewport.paddedMin <= p.x && p.x <= viewport.paddedMax));
  
  print('Culled ${points.length} points to ${visible.length} in ${stopwatch.elapsedMicroseconds}μs');
}
```

**Expected Result**:
- Culling <1ms for 10k points (FR-005.4)
- Only visible + margin points returned

---

**2.3 BatchProcessor Usage**
```dart
void testBatchProcessor() {
  // Create points with different colors
  final points = [
    (point: ChartDataPoint(x: 1, y: 1), color: Colors.red),
    (point: ChartDataPoint(x: 2, y: 2), color: Colors.blue),
    (point: ChartDataPoint(x: 3, y: 3), color: Colors.red),
    (point: ChartDataPoint(x: 4, y: 4), color: Colors.blue),
    (point: ChartDataPoint(x: 5, y: 5), color: Colors.green),
  ];
  
  // Batch by color
  final processor = BatchProcessor<({ChartDataPoint point, Color color}), Color>(
    keyExtractor: (item) => item.color,
    batchSize: 100,
  );
  
  final batches = processor.batch(points);
  
  // Validate batching
  assert(batches[Colors.red]!.length == 2);
  assert(batches[Colors.blue]!.length == 2);
  assert(batches[Colors.green]!.length == 1);
  
  print('Batched ${points.length} points into ${batches.length} groups');
}
```

**Expected Result**: Points grouped efficiently by key, minimal overhead

---

## Test Scenario 3: Type System (FR-003)

### Goal
Validate type-safe error handling and validation utilities.

### Steps

**3.1 ChartResult Success/Failure Handling**
```dart
void testChartResult() {
  // Success case
  final result1 = ChartResult<int>.success(42);
  assert(result1.isSuccess);
  assert(!result1.isFailure);
  assert(result1.getOrNull() == 42);
  assert(result1.getOrElse(0) == 42);
  
  // Failure case
  final error = ChartError.validation('Invalid data');
  final result2 = ChartResult<int>.failure(error);
  assert(result2.isFailure);
  assert(result2.getOrNull() == null);
  assert(result2.getOrElse(0) == 0);
  
  // Pattern matching
  final value = result1.when(
    success: (val) => 'Got: $val',
    failure: (err) => 'Error: ${err.message}',
  );
  assert(value == 'Got: 42');
  
  // Chaining operations
  final result3 = result1
      .map((x) => x * 2)
      .flatMap((x) => ChartResult.success(x + 10));
  assert(result3.getOrNull() == 94); // (42 * 2) + 10
}
```

**Expected Result**: All result operations type-safe, no exceptions

---

**3.2 Validation Utilities**
```dart
void testValidation() {
  // Range validation
  final valid1 = ValidationUtils.validateRange(5.0, 0.0, 10.0);
  assert(valid1.isSuccess);
  
  final invalid1 = ValidationUtils.validateRange(15.0, 0.0, 10.0);
  assert(invalid1.isFailure);
  
  // Finite number validation
  assert(ValidationUtils.isFiniteNumber(42.0));
  assert(!ValidationUtils.isFiniteNumber(double.nan));
  assert(!ValidationUtils.isFiniteNumber(double.infinity));
  
  final sanitized = ValidationUtils.sanitizeNumber(double.nan, fallback: 0.0);
  assert(sanitized == 0.0);
  
  // Collection validation
  final list = [1.0, 2.0, 3.0];
  final valid2 = ValidationUtils.validateNotEmpty(list);
  assert(valid2.isSuccess);
  
  final empty = <double>[];
  final invalid2 = ValidationUtils.validateNotEmpty(empty);
  assert(invalid2.isFailure);
  
  // Composable validation
  final result = ValidationUtils.validateAll(
    5.0,
    [
      (val) => ValidationUtils.validatePositive(val),
      (val) => ValidationUtils.validateRange(val, 0.0, 10.0),
      (val) => ValidationUtils.validateFinite(val),
    ],
  );
  assert(result.isSuccess);
}
```

**Expected Result**: All validations return ChartResult, composable chains work

---

## Test Scenario 4: Math Utilities (FR-004)

### Goal
Validate statistical functions, interpolation, and curve fitting.

### Steps

**4.1 Statistical Calculations**
```dart
void testStatistics() {
  final data = [10.0, 20.0, 30.0, 40.0, 50.0];
  
  // Central tendency
  final mean = StatisticalFunctions.mean(data);
  assert(mean == 30.0);
  
  final median = StatisticalFunctions.median(data);
  assert(median == 30.0);
  
  // Dispersion
  final stdDev = StatisticalFunctions.standardDeviation(data);
  assert(stdDev > 15.0 && stdDev < 16.0); // ~15.81
  
  final range = StatisticalFunctions.range(data);
  assert(range == 40.0); // 50 - 10
  
  // Quartiles
  final quartiles = StatisticalFunctions.quartiles(data);
  assert(quartiles.q1 == 20.0);
  assert(quartiles.q2 == 30.0); // Median
  assert(quartiles.q3 == 40.0);
  assert(quartiles.iqr == 20.0); // Q3 - Q1
  
  // Performance check (10k values)
  final largeData = List.generate(10000, (i) => i.toDouble());
  final stopwatch = Stopwatch()..start();
  final largeMean = StatisticalFunctions.mean(largeData);
  stopwatch.stop();
  assert(stopwatch.elapsedMilliseconds < 10); // <10ms (FR-005.5)
  
  print('Calculated mean of 10k values in ${stopwatch.elapsedMilliseconds}ms');
}
```

**Expected Result**:
- All calculations mathematically correct
- 10k value calculations <10ms (FR-005.5)

---

**4.2 Interpolation Functions**
```dart
void testInterpolation() {
  // Linear interpolation
  final lerp1 = InterpolationFunctions.lerp(0.0, 100.0, 0.5);
  assert(lerp1 == 50.0);
  
  final lerp2 = InterpolationFunctions.lerp(10.0, 20.0, 0.25);
  assert(lerp2 == 12.5);
  
  // Cubic spline
  final points = [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 1, y: 1),
    ChartDataPoint(x: 2, y: 4),
    ChartDataPoint(x: 3, y: 9),
  ];
  
  final spline = InterpolationFunctions.cubicSpline(points, samples: 100);
  assert(spline.length == 100);
  assert(spline.first == 0.0); // First point preserved
  assert((spline.last - 9.0).abs() < 0.1); // Last point preserved
  
  // Bezier curve
  final bezier = InterpolationFunctions.cubicBezier(0, 33, 67, 100, 10);
  assert(bezier.length == 10);
  assert(bezier.first == 0.0);
  assert(bezier.last == 100.0);
}
```

**Expected Result**: All interpolations smooth, endpoints preserved

---

**4.3 Curve Fitting**
```dart
void testCurveFitting() {
  // Linear regression: y = 2x + 5
  final points = [
    ChartDataPoint(x: 0, y: 5),
    ChartDataPoint(x: 1, y: 7),
    ChartDataPoint(x: 2, y: 9),
    ChartDataPoint(x: 3, y: 11),
    ChartDataPoint(x: 4, y: 13),
  ];
  
  final stopwatch = Stopwatch()..start();
  final fit = CurveFittingFunctions.linearFit(points);
  stopwatch.stop();
  
  // Validate coefficients
  assert((fit.coefficients[0] - 5.0).abs() < 0.01); // Intercept ≈ 5
  assert((fit.coefficients[1] - 2.0).abs() < 0.01); // Slope ≈ 2
  assert(fit.rSquared > 0.99); // Perfect fit
  assert(stopwatch.elapsedMilliseconds < 50); // <50ms (FR-005.6)
  
  print('Linear fit: ${fit.equation}');
  print('R² = ${fit.rSquared.toStringAsFixed(4)}');
  print('Computed in ${stopwatch.elapsedMilliseconds}ms');
  
  // Polynomial fit
  final quadratic = [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 1, y: 1),
    ChartDataPoint(x: 2, y: 4),
    ChartDataPoint(x: 3, y: 9),
  ];
  
  final polyFit = CurveFittingFunctions.polynomialFit(quadratic, degree: 2);
  assert(polyFit.coefficients.length == 3); // a₀, a₁, a₂
  assert(polyFit.rSquared > 0.99); // y = x²
}
```

**Expected Result**:
- Linear fit <5ms for 10k points
- Polynomial fit <50ms (FR-005.6)
- R² values indicate good fit

---

## Integration Test: Complete Workflow

### Goal
Validate all components working together in realistic scenario.

### Steps

**5.1 Full Chart Data Pipeline**
```dart
void integrationTest() {
  print('=== Foundation Layer Integration Test ===\n');
  
  // Step 1: Generate large dataset
  print('1. Generating 50k data points...');
  final stopwatch = Stopwatch()..start();
  
  final rawData = List.generate(
    50000,
    (i) => ChartDataPoint(
      x: i.toDouble(),
      y: (i * 0.5) + (Random().nextDouble() * 10 - 5), // Line + noise
      timestamp: DateTime(2024, 1, 1).add(Duration(hours: i)),
    ),
  );
  
  print('   Generated in ${stopwatch.elapsedMilliseconds}ms');
  
  // Step 2: Create series with validation
  print('\n2. Creating ChartSeries...');
  stopwatch.reset();
  stopwatch.start();
  
  final series = ChartSeries(
    id: 'integration-test',
    name: 'Test Dataset',
    points: rawData,
    isXOrdered: true,
  );
  
  final validationResult = series.validate();
  assert(validationResult.isSuccess);
  print('   Series created and validated in ${stopwatch.elapsedMilliseconds}ms');
  
  // Step 3: Calculate statistics
  print('\n3. Computing statistics...');
  stopwatch.reset();
  stopwatch.start();
  
  final yValues = rawData.map((p) => p.y).toList();
  final mean = StatisticalFunctions.mean(yValues);
  final stdDev = StatisticalFunctions.standardDeviation(yValues);
  final minMax = StatisticalFunctions.minMax(yValues);
  
  print('   Mean: ${mean.toStringAsFixed(2)}');
  print('   StdDev: ${stdDev.toStringAsFixed(2)}');
  print('   Range: [${minMax.min.toStringAsFixed(2)}, ${minMax.max.toStringAsFixed(2)}]');
  print('   Computed in ${stopwatch.elapsedMilliseconds}ms');
  
  // Step 4: Viewport culling
  print('\n4. Viewport culling (simulated pan)...');
  final viewport = DataRange(min: 10000.0, max: 20000.0);
  final culler = ViewportCuller(margin: 0.1);
  
  stopwatch.reset();
  stopwatch.start();
  
  final visible = culler.cull(
    points: rawData,
    viewportX: viewport,
    viewportY: DataRange(min: minMax.min, max: minMax.max),
    isXOrdered: true,
  );
  
  print('   Culled ${rawData.length} → ${visible.length} points in ${stopwatch.elapsedMicroseconds}μs');
  assert(stopwatch.elapsedMilliseconds < 1); // <1ms (FR-005.4)
  
  // Step 5: Curve fitting
  print('\n5. Fitting trend line...');
  stopwatch.reset();
  stopwatch.start();
  
  // Sample every 100th point for faster fitting
  final sample = <ChartDataPoint>[];
  for (var i = 0; i < rawData.length; i += 100) {
    sample.add(rawData[i]);
  }
  
  final fit = CurveFittingFunctions.linearFit(sample);
  print('   ${fit.equation}');
  print('   R² = ${fit.rSquared.toStringAsFixed(4)}');
  print('   Fitted in ${stopwatch.elapsedMilliseconds}ms');
  
  // Step 6: Object pooling (render simulation)
  print('\n6. Simulating render with object pool...');
  final paintPool = ObjectPool<Paint>(
    factory: () => Paint(),
    reset: (p) {
      p.color = Colors.black;
      p.strokeWidth = 1.0;
    },
    maxSize: 50,
  );
  
  stopwatch.reset();
  stopwatch.start();
  
  for (final point in visible.take(100)) {
    final paint = paintPool.acquire();
    paint.color = Colors.blue;
    // Simulate rendering...
    paintPool.release(paint);
  }
  
  final stats = paintPool.statistics;
  print('   Pool hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
  print('   Simulated render in ${stopwatch.elapsedMicroseconds}μs');
  
  print('\n=== All Integration Tests PASSED ===');
}
```

**Expected Result**:
- All operations complete successfully
- Performance targets met
- Memory usage reasonable
- No errors or exceptions

---

## Success Criteria

✅ **Data Models**: 100k points created in <100ms with <10MB memory  
✅ **Object Pool**: Acquire/release <100ns, hit rate >90%  
✅ **Viewport Culler**: 10k points culled in <1ms  
✅ **Statistics**: 10k values processed in <10ms  
✅ **Curve Fitting**: Linear fit <5ms, polynomial <50ms  
✅ **Type System**: All validations return ChartResult, no exceptions  
✅ **Integration**: Full pipeline works end-to-end  

**Constitutional Compliance**:
- ✅ TDD: Tests written before implementation
- ✅ Performance: All FR-005 targets met
- ✅ Pure Dart: No platform-specific code
- ✅ Null Safety: No null exceptions
- ✅ SOLID: Clean separation of concerns

---

## Next Steps

After all quickstart tests pass:
1. Run full test suite: `flutter test test/unit/foundation/`
2. Run performance benchmarks: `flutter test test/performance/foundation/`
3. Run integration tests: `flutter drive --driver=test/test_driver/integration_test.dart --target=test/integration_test/foundation_test.dart`
4. Verify 100% coverage: `flutter test --coverage`
5. Proceed to next layer (Rendering Layer)

---

**Status**: Ready for TDD implementation (Phase 3-4)
