# Foundation Layer: Data Model

**Feature**: Foundation Layer  
**Date**: 2025-10-04  
**Status**: Phase 1 Complete

---

## Overview

This document defines all data entities for the Foundation layer, organized into four functional areas:
1. **Data Models** - Core chart data structures
2. **Performance Primitives** - Optimization utilities
3. **Type System** - Error handling and validation
4. **Math Utilities** - Statistical and mathematical functions

All entities are **immutable** (FR-005.14), **null-safe** (FR-005.12), and follow **SOLID principles**.

---

## 1. Data Models (FR-001)

### 1.1 ChartDataPoint

**Purpose**: Represents a single (x, y) coordinate with optional metadata.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| x | double | No | X-axis value (horizontal position) |
| y | double | No | Y-axis value (vertical position) |
| timestamp | DateTime | Yes | Optional timestamp for time-series data |
| label | String | Yes | Optional label for tooltips/annotations |
| metadata | Map<String, dynamic> | Yes | Optional custom metadata |

**Validation Rules**:
- `x` and `y` MUST NOT be null
- `x` and `y` CAN be NaN, infinity (handled gracefully - FR-005.13)
- `timestamp` MUST be valid DateTime if provided
- `label` MUST be non-empty string if provided
- `metadata` MUST be immutable map if provided

**Relationships**:
- **Contained by**: ChartSeries (one-to-many)
- **Used by**: ViewportCuller for visibility testing

**State Transitions**: None (immutable after creation)

**Performance Targets**:
- Creation time: <1μs (FR-005.1)
- Memory size: <1KB per instance (FR-005.7)
- Equality comparison: <100ns

**Equality Semantics**:
- Two points are equal if x, y, timestamp, and label match
- Metadata is excluded from equality (performance optimization)

---

### 1.2 ChartSeries

**Purpose**: Collection of related ChartDataPoint objects representing a data series.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| id | String | No | Unique identifier for the series |
| name | String | Yes | Display name (e.g., "Revenue 2024") |
| points | List<ChartDataPoint> | No | Ordered list of data points |
| color | Color | Yes | Suggested rendering color |
| style | SeriesStyle | Yes | Rendering style hints (line, bar, etc.) |
| isXOrdered | bool | No | True if points are sorted by x-value |
| metadata | Map<String, dynamic> | Yes | Optional custom metadata |

**Validation Rules**:
- `id` MUST NOT be null or empty
- `points` MUST NOT be null (can be empty list)
- `isXOrdered` MUST match actual point ordering
- If `isXOrdered` is true, points MUST be sorted by x ascending

**Relationships**:
- **Contains**: ChartDataPoint (one-to-many)
- **Used by**: ViewportCuller (checks isXOrdered for optimization)
- **Used by**: DataRange (calculates bounds from points)

**State Transitions**: None (immutable after creation)

**Performance Targets**:
- 10,000 points MUST occupy <10MB (FR-005.2)
- Iteration over points: O(n) with minimal overhead
- Point lookup by index: O(1)

**Computed Properties**:
- `xRange`: DataRange computed from points (cached)
- `yRange`: DataRange computed from points (cached)
- `isEmpty`: true if points list is empty
- `length`: number of points in series

---

### 1.3 DataRange

**Purpose**: Represents minimum and maximum bounds for a data axis.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| min | double | No | Minimum value (lower bound) |
| max | double | No | Maximum value (upper bound) |
| padding | double | Yes | Optional padding factor (0.0-1.0) |

**Validation Rules**:
- `min` MUST be <= `max` (enforced at construction)
- `padding` MUST be >= 0.0 and <= 1.0 if provided
- `min` and `max` CAN be equal (single-value range)
- NaN and infinity handled with special cases

**Relationships**:
- **Computed from**: ChartSeries points
- **Used by**: ViewportCuller for visibility testing
- **Used by**: Rendering system for axis scaling

**State Transitions**: None (immutable after creation)

**Computed Properties**:
- `span`: max - min (range magnitude)
- `center`: (max + min) / 2 (midpoint)
- `paddedMin`: min - (span × padding) if padding provided
- `paddedMax`: max + (span × padding) if padding provided
- `contains(value)`: true if value within [min, max]

**Factory Constructors**:
- `DataRange.fromValues(List<double>)`: Calculate from list
- `DataRange.fromPoints(List<ChartDataPoint>, axis)`: Extract from points
- `DataRange.symmetric(center, radius)`: Create symmetric range

---

### 1.4 TimeSeriesData

**Purpose**: Specialized container for time-based datasets with DateTime x-axis.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| id | String | No | Unique identifier |
| name | String | Yes | Display name |
| dataPoints | List<TimeSeriesPoint> | No | Time-based data points |
| timeZone | TimeZone | Yes | Time zone for display |
| samplingRate | Duration | Yes | Expected interval between points |

**TimeSeriesPoint** (embedded):
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| timestamp | DateTime | No | Point in time |
| value | double | No | Measured value |
| label | String | Yes | Optional label |

**Validation Rules**:
- `dataPoints` MUST be sorted by timestamp ascending
- `timestamp` values MUST be unique within series
- `samplingRate` MUST be positive if provided
- Time zone conversions preserve instant in time

**Relationships**:
- **Converts to**: ChartSeries (via toChartSeries() method)
- **Uses**: DataRange for time range calculation

**State Transitions**: None (immutable after creation)

**Computed Properties**:
- `timeRange`: Range of timestamps (min to max)
- `valueRange`: Range of values (min to max)
- `duration`: timeRange.max - timeRange.min
- `averageSamplingRate`: duration / point count

**Aggregation Operations**:
- `sampleByDuration(Duration)`: Downsample to specified interval
- `aggregateByPeriod(Period, Aggregation)`: Group by hour/day/month
- `interpolateGaps(Duration)`: Fill missing data points

---

## 2. Performance Primitives (FR-002)

### 2.1 ObjectPool<T>

**Purpose**: Generic object pool for memory-efficient object reuse.

**Type Parameters**:
- `T`: Type of objects being pooled (e.g., Paint, Path, List)

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| maxSize | int | No | Maximum pool capacity |
| factory | T Function() | No | Function to create new objects |
| reset | void Function(T) | No | Function to reset objects before reuse |

**Internal State** (not exposed):
- `_available`: List<T> of available objects
- `_inUse`: Set<T> of currently acquired objects
- `_totalCreated`: Counter for statistics

**Operations**:
- `T acquire()`: Get object from pool (create if empty)
- `void release(T object)`: Return object to pool
- `PoolStatistics get statistics`: Get usage metrics
- `void clear()`: Empty pool and reset counters

**Validation Rules**:
- `maxSize` MUST be > 0
- `factory` MUST NOT be null
- `reset` MUST NOT be null
- Released object MUST have been acquired
- Released object MUST NOT be released twice

**Performance Targets**:
- Acquire operation: <100ns (FR-005.3)
- Release operation: <100ns (FR-005.3)
- Memory overhead: <1KB per pool instance (FR-005.8)

**Thread Safety**:
- NOT thread-safe by default (single-threaded Flutter UI)
- Concurrent access handled by caller if needed

---

### 2.2 ViewportCuller

**Purpose**: Efficiently filter data points to visible viewport region.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| margin | double | No | Cull margin factor (0.0-1.0) |

**Operations**:
- `List<ChartDataPoint> cull(...)`: Filter points to viewport

**Method: cull()**

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| points | List<ChartDataPoint> | Points to filter |
| viewportX | DataRange | Visible x-axis range |
| viewportY | DataRange | Visible y-axis range |
| isXOrdered | bool | True if points sorted by x |

**Returns**: Filtered list of visible points plus margin

**Algorithm**:
- If `isXOrdered == true`: Binary search for x-range, then filter y
- If `isXOrdered == false`: Linear scan with rectangle test
- Margin extends viewport by `margin` × span in each direction

**Performance Targets**:
- 10,000 points: <1ms (FR-005.4)
- Ordered data: O(log n + m) where m = visible points
- Unordered data: O(n)

**Optimization Notes**:
- Binary search requires sorted data (verified by isXOrdered)
- Margin prevents pop-in during panning animations
- Typical margin: 0.1 (10% extra on each side)

---

### 2.3 BatchProcessor

**Purpose**: Group similar rendering operations to reduce state changes.

**Type Parameters**:
- `T`: Type of items being batched

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| batchSize | int | No | Target batch size |
| keyExtractor | K Function(T) | No | Function to extract grouping key |

**Operations**:
- `Map<K, List<T>> batch(List<T> items)`: Group items by key

**Method: batch()**

**Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| items | List<T> | Items to batch |

**Returns**: Map of key → list of items with that key

**Use Cases**:
- Group points by color for single Paint object reuse
- Group shapes by fill style to minimize Canvas state changes
- Group text by font for text layout batching

**Performance Targets**:
- Batching overhead: <5% of processing time
- Memory overhead: <10% of original data size

---

## 3. Type System (FR-003)

### 3.1 ChartResult<T>

**Purpose**: Type-safe success/failure result wrapper (no exceptions).

**Type**: Sealed class (Dart 3.0)

**Variants**:

**Success<T>**:
| Property | Type | Description |
|----------|------|-------------|
| value | T | The successful result value |

**Failure<T>**:
| Property | Type | Description |
|----------|------|-------------|
| error | ChartError | The error that occurred |

**Operations**:
- `R when<R>({success, failure})`: Pattern match on result
- `T? getOrNull()`: Get value or null if failure
- `T getOrElse(T defaultValue)`: Get value or default
- `ChartResult<R> map<R>(R Function(T))`: Transform success value
- `ChartResult<R> flatMap<R>(ChartResult<R> Function(T))`: Chain operations

**Usage Pattern**:
```dart
final result = calculateBounds(data);
return result.when(
  success: (bounds) => renderChart(bounds),
  failure: (error) => showError(error),
);
```

**Validation Rules**:
- Success variant MUST have non-null value
- Failure variant MUST have non-null error
- Exhaustive pattern matching enforced by sealed class

---

### 3.2 ChartError

**Purpose**: Categorized error representation with context.

**Properties**:
| Property | Type | Nullable | Description |
|----------|------|----------|-------------|
| type | ErrorType | No | Category of error |
| severity | ErrorSeverity | No | Warning/Error/Critical |
| message | String | No | Human-readable description |
| code | String | No | Machine-readable error code |
| stackTrace | StackTrace | Yes | Stack trace for debugging |
| context | Map<String, dynamic> | Yes | Additional error context |

**ErrorType Enum**:
- `validation` - Invalid input data
- `rendering` - Rendering failure
- `calculation` - Math/computation error
- `configuration` - Invalid configuration
- `internal` - Internal library error

**ErrorSeverity Enum**:
- `warning` - Non-fatal issue (e.g., data point skipped)
- `error` - Operation failed (e.g., invalid data)
- `critical` - System integrity issue (e.g., out of memory)

**Factory Constructors**:
- `ChartError.validation(message, {code, context})`: Validation error
- `ChartError.rendering(message, {code, context})`: Rendering error
- `ChartError.calculation(message, {code, context})`: Math error
- `ChartError.internal(message, {code, stackTrace})`: Internal error

**Validation Rules**:
- `message` MUST be non-empty
- `code` MUST follow pattern: `{TYPE}_{CATEGORY}_{NUMBER}` (e.g., "VAL_RANGE_001")
- `stackTrace` SHOULD be captured for severity >= error

---

### 3.3 ValidationUtils

**Purpose**: Data validation utilities for input checking.

**Static Methods**:

**Range Validation**:
- `bool isInRange(double value, double min, double max)`
- `ChartResult<void> validateRange(double value, double min, double max)`
- `ChartResult<void> validatePositive(double value)`

**Null Safety**:
- `ChartResult<T> requireNonNull<T>(T? value, String fieldName)`
- `ChartResult<List<T>> validateList<T>(List<T>? list)`

**NaN/Infinity Detection**:
- `bool isFiniteNumber(double value)`
- `ChartResult<double> validateFinite(double value, String fieldName)`
- `double sanitizeNumber(double value, {double fallback = 0.0})`

**Collection Validation**:
- `ChartResult<void> validateNotEmpty<T>(List<T> list, String name)`
- `ChartResult<void> validateSize<T>(List<T> list, int max, String name)`
- `ChartResult<void> validateUnique<T>(List<T> list, String name)`

**Custom Validation**:
- `ChartResult<T> validate<T>(T value, bool Function(T) predicate, String errorMsg)`

**Return Pattern**:
- All methods return `ChartResult<T>` for composable validation
- Failures include descriptive ChartError with validation context

---

## 4. Math Utilities (FR-004)

### 4.1 StatisticalFunctions

**Purpose**: Common statistical calculations on numeric data.

**Static Methods**:

**Central Tendency**:
- `double mean(List<double> values, {MeanType type = MeanType.arithmetic})`
  - `MeanType.arithmetic`: sum / count
  - `MeanType.geometric`: nth root of product
  - `MeanType.harmonic`: n / sum(1/x)
- `double median(List<double> values)`: Middle value or average of middle two
- `double mode(List<double> values)`: Most frequent value

**Dispersion**:
- `double standardDeviation(List<double> values, {bool sample = true})`
- `double variance(List<double> values, {bool sample = true})`
- `double range(List<double> values)`: max - min

**Quantiles**:
- `double percentile(List<double> values, double p)`: pth percentile (0-100)
- `Quartiles quartiles(List<double> values)`: Q1, Q2 (median), Q3
- `double iqr(List<double> values)`: Interquartile range (Q3 - Q1)

**Extremes**:
- `double min(List<double> values)`: Minimum value
- `double max(List<double> values)`: Maximum value
- `MinMax minMax(List<double> values)`: Both min and max in one pass

**Validation**:
- All methods return NaN for empty lists
- All methods handle NaN/infinity according to IEEE 754 rules
- Sample variance uses (n-1) denominator, population uses n

**Performance Targets**:
- All operations: <10ms for 10,000 values (FR-005.5)
- Single-pass algorithms where possible

---

### 4.2 InterpolationFunctions

**Purpose**: Interpolate between data points for smooth curves.

**Static Methods**:

**Linear Interpolation**:
- `double lerp(double a, double b, double t)`: Linear interpolate (t ∈ [0,1])
- `double lerpInverse(double a, double b, double value)`: Find t for value

**Cubic Spline**:
- `List<double> cubicSpline(List<ChartDataPoint> points, int samples)`
- Uses natural cubic spline (zero second derivative at endpoints)
- Returns sampled points for smooth curve

**Hermite Interpolation**:
- `double hermite(double p0, double p1, double m0, double m1, double t)`
- Requires tangent vectors (m0, m1) at endpoints

**Catmull-Rom Spline**:
- `List<double> catmullRom(List<ChartDataPoint> points, int samples, {double tension = 0.5})`
- Automatically computes tangents from neighboring points

**Bezier Curves**:
- `double bezier(List<double> controlPoints, double t)`: Arbitrary-degree Bezier
- `List<double> quadraticBezier(double p0, double p1, double p2, int samples)`
- `List<double> cubicBezier(double p0, double p1, double p2, double p3, int samples)`

**Validation**:
- `t` parameter MUST be in [0, 1] range
- Point lists MUST have minimum required points (varies by algorithm)
- Returns empty list for invalid input

**Performance Targets**:
- Interpolation: <1ms for 1000 sample points
- Curve generation: <10ms for complex splines

---

### 4.3 CurveFittingFunctions

**Purpose**: Fit mathematical curves to data for trend analysis.

**Return Type**: All methods return `FitResult`

**FitResult**:
| Property | Type | Description |
|----------|------|-------------|
| coefficients | List<double> | Fitted curve parameters |
| rSquared | double | Coefficient of determination (0-1) |
| residuals | List<double> | Residual errors per point |
| equation | String | Human-readable equation |

**Static Methods**:

**Linear Regression**:
- `FitResult linearFit(List<ChartDataPoint> points)`
- Equation: y = a + b×x
- Coefficients: [a, b] (intercept, slope)
- Uses least squares method

**Polynomial Regression**:
- `FitResult polynomialFit(List<ChartDataPoint> points, int degree)`
- Equation: y = a₀ + a₁×x + a₂×x² + ... + aₙ×xⁿ
- Coefficients: [a₀, a₁, ..., aₙ]
- Degree MUST be >= 1 and <= 5 (stability limit)

**Exponential Fit**:
- `FitResult exponentialFit(List<ChartDataPoint> points)`
- Equation: y = a × eᵇˣ
- Coefficients: [a, b]
- Transforms to linear: ln(y) = ln(a) + b×x

**Logarithmic Fit**:
- `FitResult logarithmicFit(List<ChartDataPoint> points)`
- Equation: y = a + b×ln(x)
- Coefficients: [a, b]
- Requires all x > 0

**R² Calculation**:
- R² = 1 - (SS_res / SS_tot)
- SS_res = sum of squared residuals
- SS_tot = total sum of squares
- R² ∈ [0, 1], higher = better fit

**Validation**:
- Points MUST have at least degree + 1 points
- Exponential requires all y > 0
- Logarithmic requires all x > 0
- Returns ChartResult.failure for invalid input

**Performance Targets**:
- Linear fit: <5ms for 10,000 points
- Polynomial fit: <50ms for degree ≤ 3 (FR-005.6)
- Exponential/Logarithmic: <50ms (FR-005.6)

---

## Entity Relationships Diagram

```
ChartSeries
  ├── contains [1..*] ChartDataPoint
  │   └── has timestamp → TimeSeriesPoint
  └── computes DataRange (xRange, yRange)

ViewportCuller
  ├── filters ChartDataPoint list
  └── uses DataRange for bounds

ObjectPool<T>
  └── manages [0..*] T instances

ChartResult<T>
  ├── Success<T> → holds T value
  └── Failure<T> → holds ChartError

ValidationUtils
  └── produces ChartResult<T>

StatisticalFunctions
  └── operates on List<double>

InterpolationFunctions
  └── operates on List<ChartDataPoint>

CurveFittingFunctions
  ├── operates on List<ChartDataPoint>
  └── produces FitResult
```

---

## Validation Rules Summary

**All Entities**:
- ✓ Immutable after creation (FR-005.14)
- ✓ Null-safe with proper annotations (FR-005.12)
- ✓ Graceful handling of NaN/infinity (FR-005.13)
- ✓ No platform-specific dependencies (FR-005.16)

**Data Models**:
- ChartDataPoint: x, y required; timestamp, label optional
- ChartSeries: id required, points can be empty, isXOrdered must match reality
- DataRange: min <= max enforced
- TimeSeriesData: points sorted by timestamp, unique timestamps

**Performance Primitives**:
- ObjectPool: maxSize > 0, factory and reset functions required
- ViewportCuller: margin in [0.0, 1.0]
- BatchProcessor: batchSize > 0

**Type System**:
- ChartResult: exhaustive pattern matching via sealed class
- ChartError: non-empty message, formatted error code
- ValidationUtils: all methods return ChartResult for composition

**Math Utilities**:
- Statistical functions: empty list → NaN
- Interpolation: t ∈ [0,1], minimum points enforced
- Curve fitting: degree limits, positivity requirements

---

## Performance Summary

| Entity | Operation | Target | Spec Reference |
|--------|-----------|--------|----------------|
| ChartDataPoint | Creation | <1μs | FR-005.1 |
| ChartDataPoint | Memory | <1KB | FR-005.7 |
| ChartSeries (10k) | Memory | <10MB | FR-005.2 |
| ObjectPool | Acquire | <100ns | FR-005.3 |
| ObjectPool | Release | <100ns | FR-005.3 |
| ViewportCuller | 10k points | <1ms | FR-005.4 |
| Statistics | 10k values | <10ms | FR-005.5 |
| Curve Fitting | Any | <50ms | FR-005.6 |

**All targets MUST be verified with benchmark tests before implementation merge.**

---

## Phase 1 Completion Checklist

- [x] All entities extracted from spec
- [x] Properties and types defined
- [x] Validation rules documented
- [x] Relationships mapped
- [x] Performance targets assigned
- [x] Immutability enforced
- [x] Null safety applied
- [x] SOLID principles followed

**Status**: ✅ READY FOR CONTRACT GENERATION
