# Tasks: Foundation Layer

**Input**: Design documents from `specs/001-foundation/`
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

---

## Task Overview

**Total Tasks**: 58  
**Completed**: 33 / 58 (57%)**  
**Estimated Duration**: 8-12 days with parallel execution  
**TDD Enforced**: All test tasks MUST complete before implementation tasks  
**Constitutional Compliance**: 100% coverage, all performance targets validated

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **File paths**: Absolute paths from repository root
- **TDD**: Tests written → Tests fail → Implementation → Tests pass → Refactor

---

## Phase 3.1: Setup & Project Structure

### T001: [X] Create Foundation Directory Structure
**Description**: Create foundation layer directory structure in `lib/src/foundation/`  
**Files to create**:
```
lib/src/foundation/
├── data_models/
├── performance/
├── type_system/
├── math/
└── foundation.dart (barrel export)
```
**Acceptance**: All directories exist, barrel file created with empty exports

---

### T002: [X] [P] Configure Test Directory Structure
**Description**: Create test directory structure for foundation layer  
**Files to create**:
```
test/
├── unit/foundation/
├── widget/foundation/
├── contract/foundation/
├── performance/foundation/
├── integration_test/
└── golden/foundation/
```
**Acceptance**: All test directories exist per docs/testing/ framework

---

### T003: [X] [P] Configure Analysis Options for Foundation
**Description**: Create `analysis_options.yaml` if not exists, ensure strict linting  
**File**: `analysis_options.yaml` (repository root)  
**Requirements**:
- Use `flutter_lints` package
- Enforce strict null safety
- Zero warnings allowed
- Enable all recommended lints  
**Acceptance**: `flutter analyze` returns zero warnings

---

## Phase 3.2: Contract Tests (TDD Phase 1 - MUST FAIL)

**CRITICAL**: These tests MUST be written and MUST FAIL before ANY implementation in Phase 3.3

### T004: [X] [P] Contract Test - Data Models
**Description**: Write contract tests for all data model APIs  
**File**: `test/contract/foundation/data_models_contract_test.dart`  
**Test Coverage**:
- ChartDataPoint: constructor, copyWith, equality, validation
- ChartSeries: constructor, copyWith, computed properties, ordering validation
- DataRange: constructors (fromValues, fromPoints, symmetric), operations
- TimeSeriesData: constructor, aggregations, conversions  
**Assertions**: All abstract methods exist with correct signatures  
**Expected**: ALL TESTS FAIL (no implementation yet)  
**Acceptance**: File created, all contract signatures verified, tests fail

---

### T005: [X] [P] Contract Test - Performance Primitives
**Description**: Write contract tests for performance primitive APIs  
**File**: `test/contract/foundation/performance_contract_test.dart`  
**Test Coverage**:
- ObjectPool<T>: acquire, release, statistics, clear
- ViewportCuller: cull method, bounds calculation
- BatchProcessor<T,K>: batch, processBatches  
**Assertions**: Generic types work, method signatures correct  
**Expected**: ALL TESTS FAIL (no implementation yet)  
**Acceptance**: File created, all contract signatures verified, tests fail

---

### T006: [X] [P] Contract Test - Type System
**Description**: Write contract tests for type system APIs  
**File**: `test/contract/foundation/type_system_contract_test.dart`  
**Test Coverage**:
- ChartResult<T>: sealed class exhaustiveness, Success/Failure variants
- ChartError: factory constructors, error types, severity levels
- ValidationUtils: all static validation methods  
**Assertions**: Pattern matching enforced, no uncovered cases  
**Expected**: ALL TESTS FAIL (no implementation yet)  
**Acceptance**: File created, sealed class exhaustiveness verified, tests fail

---

### T007: [X] [P] Contract Test - Math Utilities
**Description**: Write contract tests for math utility APIs  
**File**: `test/contract/foundation/math_contract_test.dart`  
**Test Coverage**:
- StatisticalFunctions: all static methods exist
- InterpolationFunctions: all interpolation types
- CurveFittingFunctions: all fit types  
**Assertions**: Method signatures match contracts  
**Expected**: ALL TESTS FAIL (no implementation yet)  
**Acceptance**: File created, all method signatures verified, tests fail

---

## Phase 3.3: Type System Implementation (Foundation for All)

**Priority**: HIGHEST - Everything depends on ChartResult<T>

### T008: [X] Implement ChartResult<T> Sealed Class
**Description**: Implement sealed class with Success and Failure variants  
**File**: `lib/src/foundation/type_system/chart_result.dart`  
**Requirements** (FR-003.1):
- Sealed class ChartResult<T>
- Success<T> final class with value
- Failure<T> final class with ChartError
- All methods: when, getOrNull, getOrElse, map, flatMap, fold
- Implement isSuccess, isFailure getters  
**Performance**: Pattern matching must be exhaustive (compile-time checked)  
**Tests**: T006 contract tests should now PASS  
**Acceptance**: All T006 tests pass, Dart analyzer confirms exhaustiveness

---

### T009: [X] Implement ChartError Class
**Description**: Implement error representation with categorization  
**File**: `lib/src/foundation/type_system/chart_error.dart`  
**Requirements** (FR-003.2):
- ErrorType enum (validation, rendering, calculation, configuration, internal)
- ErrorSeverity enum (warning, error, critical)
- ChartError class with all properties
- Factory constructors: validation(), rendering(), calculation(), internal()
- Proper equality and hashCode  
**Tests**: T006 contract tests for ChartError should PASS  
**Acceptance**: All error factories work, tests pass

---

### T010: [X] Implement ValidationUtils Static Class
**Description**: Implement all validation utility methods  
**File**: `lib/src/foundation/type_system/validation_utils.dart`  
**Requirements** (FR-003.3):
- Range validation methods
- Null safety methods (requireNonNull, validateList)
- NaN/Infinity detection (isFiniteNumber, validateFinite, sanitizeNumber)
- Collection validation (validateNotEmpty, validateSize, validateUnique)
- Custom validation (validate, validateAll)  
**Returns**: All methods return ChartResult<T> for composition  
**Tests**: T006 validation tests should PASS  
**Acceptance**: All validation methods work, composable, tests pass

---

### T011: [X] [P] Unit Tests - Type System
**Description**: Write comprehensive unit tests for type system  
**File**: `test/unit/foundation/type_system_test.dart`  
**Test Coverage**:
- ChartResult: all operations (map, flatMap, fold), edge cases
- ChartError: all factory methods, error codes, context
- ValidationUtils: all validation scenarios, edge cases (NaN, infinity, empty)  
**Coverage Target**: 100% for type_system/ directory  
**Acceptance**: All tests pass, 100% coverage verified

---

## Phase 3.4: Data Models Implementation

**Dependencies**: T008-T010 (ChartResult needed for validation)

### T012: [X] [P] Implement ChartDataPoint
**Description**: Implement immutable ChartDataPoint class  
**File**: `lib/src/foundation/data_models/chart_data_point.dart`  
**Requirements** (FR-001.1):
- Immutable class with const constructor
- Properties: x (double), y (double), timestamp (DateTime?), label (String?), metadata (Map?)
- copyWith method for mutations
- Equality based on x, y, timestamp, label (exclude metadata)
- Validation: isValid getter (checks finite numbers)
- Getters: hasTimestamp, hasLabel  
**Performance**: Creation <1μs, memory <1KB (FR-005.1, FR-005.7)  
**Tests**: T004 ChartDataPoint tests should PASS  
**Acceptance**: All T004 tests pass, immutability verified

---

### T013: [X] [P] Implement ChartSeries
**Description**: Implement immutable ChartSeries collection  
**File**: `lib/src/foundation/data_models/chart_series.dart`  
**Requirements** (FR-001.2):
- Immutable class with const constructor
- Properties: id, name, points (List<ChartDataPoint>), color, style, isXOrdered, metadata
- copyWith method
- Computed properties (cached): xRange, yRange, isEmpty, length
- validateOrdering() method
- validate() returns ChartResult<void>  
**Performance**: 10k points <10MB memory (FR-005.2)  
**Tests**: T004 ChartSeries tests should PASS  
**Acceptance**: All T004 tests pass, memory target verified

---

### T014: [X] [P] Implement DataRange
**Description**: Implement data range with padding support  
**File**: `lib/src/foundation/data_models/data_range.dart`  
**Requirements** (FR-001.3):
- Immutable class with const constructor
- Properties: min, max, padding
- Factory constructors: fromValues, fromPoints, symmetric
- Computed properties: span, center, paddedMin, paddedMax
- Operations: contains, overlaps, merge
- validate() returns ChartResult<void> (min <= max)  
**Tests**: T004 DataRange tests should PASS  
**Acceptance**: All T004 tests pass, all factories work

---

### T015: [X] [P] Implement TimeSeriesData
**Description**: Implement time-based dataset container  
**File**: `lib/src/foundation/data_models/time_series_data.dart`  
**Requirements** (FR-001.4):
- Immutable class with const constructor
- Properties: id, name, dataPoints (List<TimeSeriesPoint>), timeZone, samplingRate
- Computed properties: timeRange, valueRange, duration, averageSamplingRate
- toChartSeries() conversion method
- Aggregation methods: sampleByDuration, aggregateByPeriod, interpolateGaps
- validate() returns ChartResult<void> (sorted, unique timestamps)  
**Tests**: T004 TimeSeriesData tests should PASS  
**Acceptance**: All T004 tests pass, aggregations work

---

### T016: [X] [P] Unit Tests - Data Models
**Description**: Write comprehensive unit tests for all data models  
**File**: `test/unit/foundation/data_models_test.dart`  
**Test Coverage**:
- ChartDataPoint: all edge cases (NaN, infinity, null values)
- ChartSeries: empty series, single point, ordering validation
- DataRange: edge cases (equal min/max, negative values, padding)
- TimeSeriesData: timezone handling, sampling, aggregation  
**Coverage Target**: 100% for data_models/ directory  
**Acceptance**: All tests pass, 100% coverage verified

---

## Phase 3.5: Performance Primitives Implementation

**Dependencies**: T008-T010 (ChartResult), T012-T015 (ChartDataPoint, DataRange)

### T017: [X] [P] Implement ObjectPool<T>
**Description**: Implement generic object pool with statistics  
**File**: `lib/src/foundation/performance/object_pool.dart`  
**Requirements** (FR-002.1):
- Generic class ObjectPool<T>
- Constructor: factory function, reset function, maxSize
- Methods: acquire(), release(T), clear(), isTracked(T)
- Property: statistics (PoolStatistics)
- Internal tracking: _available list, _inUse set, _totalCreated counter  
**Performance**: Acquire/release <100ns each (FR-005.3)  
**Tests**: T005 ObjectPool tests should PASS  
**Acceptance**: All T005 tests pass, performance benchmarked  
**Status**: ✅ COMPLETE - 218 lines, all contract tests pass

---

### T018: [X] [P] Implement ViewportCuller
**Description**: Implement efficient viewport culling  
**File**: `lib/src/foundation/performance/viewport_culler.dart`  
**Requirements** (FR-002.2):
- Class with margin property
- cull() method with binary search for ordered data
- calculateBounds() method
- Binary search path for isXOrdered=true
- Linear scan path for isXOrdered=false  
**Performance**: <1ms for 10k points (FR-005.4)  
**Algorithm**: O(log n + m) for ordered, O(n) for unordered  
**Tests**: T005 ViewportCuller tests should PASS  
**Acceptance**: All T005 tests pass, performance target met  
**Status**: ✅ COMPLETE - 197 lines, all contract tests pass

---

### T019: [X] [P] Implement BatchProcessor<T,K>
**Description**: Implement operation batching utility  
**File**: `lib/src/foundation/performance/batch_processor.dart`  
**Requirements** (FR-002.3):
- Generic class BatchProcessor<T,K>
- Constructor: keyExtractor function, batchSize
- batch() method returns Map<K, List<T>>
- processBatches() method with callback  
**Use Cases**: Group by color, style, font  
**Tests**: T005 BatchProcessor tests should PASS  
**Acceptance**: All T005 tests pass, batching works correctly  
**Status**: ✅ COMPLETE - 88 lines, all contract tests pass

---

### T020: [X] [P] Unit Tests - Performance Primitives
**Description**: Write comprehensive unit tests for performance primitives  
**File**: `test/unit/foundation/performance_test.dart`  
**Test Coverage**:
- ObjectPool: hit rate, max size enforcement, reset verification
- ViewportCuller: ordered vs unordered, margin calculation, edge cases
- BatchProcessor: different key types, empty inputs  
**Coverage Target**: 100% for performance/ directory  
**Acceptance**: All tests pass, 100% coverage verified  
**Status**: ✅ COMPLETE - 1002 lines, 71 tests pass, 100% coverage

---

## Phase 3.6: Math Utilities Implementation

**Dependencies**: T012 (ChartDataPoint for curve fitting input)

### T021: [X] Implement StatisticalFunctions
**Description**: Implement all statistical calculation methods  
**File**: `lib/src/foundation/math/statistics.dart`  
**Requirements** (FR-004.1):
- Central tendency: mean (arithmetic/geometric/harmonic), median, mode
- Dispersion: standardDeviation, variance, range
- Quantiles: percentile, quartiles, iqr
- Extremes: min, max, minMax  
**Performance**: <10ms for 10k values (FR-005.5)  
**Algorithms**:
- Median: Quickselect O(n) average
- Standard deviation: Two-pass for numerical stability
- Quartiles: Linear interpolation  
**Tests**: T007 StatisticalFunctions tests should PASS  
**Acceptance**: All T007 statistical tests pass, performance met  
**Status**: ✅ COMPLETE - 505 lines, all 8 contract tests pass

---

### T022: [X] Implement InterpolationFunctions
**Description**: Implement all interpolation methods  
**File**: `lib/src/foundation/math/interpolation.dart`  
**Requirements** (FR-004.2):
- Linear: lerp, lerpInverse
- Cubic spline: cubicSpline (natural spline, Thomas algorithm)
- Hermite: hermite with explicit tangents
- Catmull-Rom: catmullRom with auto-tangents
- Bezier: bezier (De Casteljau), quadraticBezier, cubicBezier  
**Performance**: <1ms for 1000 samples, <10ms for complex splines  
**Tests**: T007 InterpolationFunctions tests should PASS  
**Acceptance**: All T007 interpolation tests pass, curves smooth  
**Status**: ✅ COMPLETE - 336 lines, all 7 contract tests pass

---

### T023: [X] Implement CurveFittingFunctions
**Description**: Implement regression and curve fitting  
**File**: `lib/src/foundation/math/curve_fitting.dart`  
**Requirements** (FR-004.3):
- linearFit: Least squares linear regression
- polynomialFit: Vandermonde matrix (degree 1-5)
- exponentialFit: Transform to linear via ln(y)
- logarithmicFit: y = a + b×ln(x)
- FitResult class with coefficients, rSquared, residuals, equation  
**Performance**: Linear <5ms, polynomial <50ms (FR-005.6)  
**Numerical Stability**: Use QR decomposition for polynomial  
**Tests**: T007 CurveFittingFunctions tests should PASS  
**Acceptance**: All T007 curve fitting tests pass, R² accurate  
**Status**: ✅ COMPLETE - 471 lines, all 6 contract tests pass, FitResult class with R² and residuals

---

### T024: [X] [P] Unit Tests - Math Utilities
**Description**: Write comprehensive unit tests for math functions  
**File**: `test/unit/foundation/math_test.dart`  
**Test Coverage**:
- Statistics: known datasets, edge cases (empty, single value, NaN)
- Interpolation: endpoint preservation, smoothness, parameter bounds
- Curve fitting: known equations (y=2x+5), R² validation, numerical stability  
**Coverage Target**: 100% for math/ directory  
**Acceptance**: All tests pass, 100% coverage, mathematical correctness verified  
**Status**: ✅ COMPLETE - 74 tests pass, comprehensive coverage of all math utilities

---

## Phase 3.7: Performance Benchmarks

**Dependencies**: All implementation tasks (T017-T023)

### T025: [X] [P] Benchmark - ChartDataPoint Creation
**Description**: Benchmark data point creation performance  
**File**: `test/performance/foundation/data_point_benchmark.dart`  
**Target**: <1μs per point (FR-005.1)  
**Test**: Create 100k points, measure average time  
**Benchmark Framework**: `package:benchmark_harness`  
**Acceptance**: Average <1μs per point, report generated  
**Status**: ✅ COMPLETE - Creation and copyWith benchmarks implemented

---

### T026: [X] [P] Benchmark - ObjectPool Operations
**Description**: Benchmark pool acquire/release performance  
**File**: `test/performance/foundation/object_pool_benchmark.dart`  
**Target**: <100ns per operation (FR-005.3)  
**Test**: 10k acquire/release cycles  
**Metrics**: Average time, hit rate, memory overhead  
**Acceptance**: Operations <100ns, hit rate >90% after warmup  
**Status**: ✅ COMPLETE - Acquire/release and reuse pattern benchmarks

---

### T027: [X] [P] Benchmark - ViewportCuller
**Description**: Benchmark viewport culling performance  
**File**: `test/performance/foundation/viewport_culler_benchmark.dart`  
**Target**: <1ms for 10k points (FR-005.4)  
**Test**: Cull 10k ordered and unordered datasets  
**Metrics**: Time for binary search vs linear scan  
**Acceptance**: <1ms for 10k points, both algorithms measured  
**Status**: ✅ COMPLETE - Ordered, unordered, and small viewport benchmarks

---

### T028: [X] [P] Benchmark - Math Functions
**Description**: Benchmark statistical and math functions  
**File**: `test/performance/foundation/math_benchmark.dart`  
**Targets**:
- Statistics: <10ms for 10k values (FR-005.5)
- Curve fitting: <50ms for polynomial (FR-005.6)  
**Test**: Run all math functions on large datasets  
**Acceptance**: All performance targets met, report generated  
**Status**: ✅ COMPLETE - Statistics, interpolation, linear fit, and polynomial fit benchmarks

---

### T029: [X] Performance Report Generation
**Description**: Generate comprehensive performance report  
**File**: `docs/performance/foundation_benchmarks.md`  
**Contents**:
- All benchmark results vs targets
- Memory profiling data
- Performance regression baseline  
**Format**: Markdown table with pass/fail indicators  
**Acceptance**: All targets met, documented evidence  
**Status**: ✅ COMPLETE - Comprehensive report with all FR-005 targets documented

---

## Phase 3.8: Integration Tests (QuickStart Scenarios)

**Dependencies**: All implementation (T008-T023), Benchmarks (T025-T028)

### T030: [X] [P] Integration Test - Data Models Scenario
**Description**: Convert quickstart scenario 1 to integration test  
**File**: `test/integration_test/foundation_data_models_test.dart`  
**Scenario**: Create 100k points, organize into series, validate performance  
**Assertions**:
- Series creation <100ms
- Memory <10MB for 100k points
- All validations pass  
**ChromeDriver**: Run with `flutter drive`  
**Acceptance**: Test passes, performance metrics verified  
**Status**: ✅ COMPLETE - 9 comprehensive integration tests, all performance targets met (FR-005.1, FR-005.2)

---

### T031: [X] [P] Integration Test - Performance Primitives Scenario
**Description**: Convert quickstart scenario 2 to integration test  
**File**: `test/integration_test/foundation_performance_test.dart`  
**Scenario**: ObjectPool, ViewportCuller, BatchProcessor end-to-end  
**Assertions**:
- ObjectPool hit rate >90%
- ViewportCuller <1ms for 10k points
- Batching reduces operations  
**ChromeDriver**: Run with `flutter drive`  
**Acceptance**: Test passes, all performance targets met  
**Status**: ✅ COMPLETE - 9 comprehensive tests validating all performance primitives (FR-005.3, FR-005.4)

---

### T032: [P] Integration Test - Type System Scenario
**Description**: Convert quickstart scenario 3 to integration test  
**File**: `test/integration_test/foundation_type_system_test.dart`  
**Scenario**: ChartResult pattern matching, validation chains  
**Assertions**:
- All pattern matching exhaustive
- No exceptions for expected failures
- Validation chains composable  
**ChromeDriver**: Run with `flutter drive`  
**Acceptance**: Test passes, type safety verified

**Status**: ✅ COMPLETE - 13 comprehensive tests validating type system (ChartResult Success/Failure, pattern matching, map/flatMap/fold, chaining, ChartError factories, ValidationUtils finite/collection/composable/requireNonNull validation, real-world scenarios, end-to-end workflow)

---

### T033: [P] Integration Test - Math Utilities Scenario
**Description**: Convert quickstart scenario 4 to integration test  
**File**: `test/integration_test/foundation_math_test.dart`  
**Scenario**: Statistics, interpolation, curve fitting on real data  
**Assertions**:
- Statistical calculations mathematically correct
- Interpolation endpoints preserved
- Curve fitting R² accurate  
**ChromeDriver**: Run with `flutter drive`  
**Acceptance**: Test passes, mathematical correctness verified

**Status**: ✅ COMPLETE - 16 comprehensive tests validating math utilities (statistics: mean/median/stddev/quartiles/performance/edge-cases, interpolation: linear/cubic-spline/bezier/edge-cases, curve-fitting: linear/polynomial/performance/noisy-data/edge-cases, end-to-end workflow, complex statistical analysis)

---

### T034: Integration Test - Complete Workflow
**Description**: Convert quickstart scenario 5 (full pipeline) to integration test  
**File**: `test/integration_test/foundation_workflow_test.dart`  
**Scenario**: 50k points → series → statistics → culling → curve fitting → pooling  
**Assertions**:
- All components work together
- No performance regressions
- Memory usage reasonable  
**ChromeDriver**: Run with `flutter drive`  
**Acceptance**: Test passes, full workflow validated

---

## Phase 3.9: Barrel Exports & Public API

**Dependencies**: All implementation (T008-T023)

### T035: Create Foundation Barrel Export
**Description**: Create barrel file exporting all public APIs  
**File**: `lib/src/foundation/foundation.dart`  
**Exports**:
```dart
// Data Models
export 'data_models/chart_data_point.dart';
export 'data_models/chart_series.dart';
export 'data_models/data_range.dart';
export 'data_models/time_series_data.dart';

// Performance
export 'performance/object_pool.dart';
export 'performance/viewport_culler.dart';
export 'performance/batch_processor.dart';

// Type System
export 'type_system/chart_result.dart';
export 'type_system/chart_error.dart';
export 'type_system/validation_utils.dart';

// Math
export 'math/statistics.dart';
export 'math/interpolation.dart';
export 'math/curve_fitting.dart';
```
**Acceptance**: All public APIs accessible via single import

---

### T036: Update Main Library Export
**Description**: Update main braven_charts.dart to export foundation  
**File**: `lib/braven_charts.dart`  
**Add**: `export 'src/foundation/foundation.dart';`  
**Acceptance**: Foundation APIs accessible from package root

---

### T037: Validate Public API Surface
**Description**: Verify only intended APIs are public  
**Test**: Create test that imports `package:braven_charts/braven_charts.dart`  
**Verify**:
- All 13 entities accessible
- No internal implementation exposed
- DartDoc comments on all public members  
**Acceptance**: API surface validated, no leaks

---

## Phase 3.10: Documentation

**Dependencies**: All implementation (T008-T023), Public API (T035-T037)

### T038: [P] Document ChartDataPoint API
**Description**: Add comprehensive DartDoc to ChartDataPoint  
**File**: `lib/src/foundation/data_models/chart_data_point.dart`  
**Requirements**:
- Class-level documentation with usage example
- Constructor parameter documentation
- Method documentation (copyWith, equality)
- Property documentation (isValid, hasTimestamp, hasLabel)  
**Example**: Show creating point with timestamp  
**Acceptance**: DartDoc complete, example compiles

---

### T039: [P] Document ChartSeries API
**Description**: Add comprehensive DartDoc to ChartSeries  
**File**: `lib/src/foundation/data_models/chart_series.dart`  
**Requirements**:
- Class-level documentation with usage example
- Explain isXOrdered optimization
- Document computed properties (xRange, yRange)
- Validation method documentation  
**Example**: Show creating series and validating ordering  
**Acceptance**: DartDoc complete, example compiles

---

### T040: [P] Document DataRange API
**Description**: Add comprehensive DartDoc to DataRange  
**File**: `lib/src/foundation/data_models/data_range.dart`  
**Requirements**:
- Class-level documentation
- Factory constructor documentation (fromValues, fromPoints, symmetric)
- Operation documentation (contains, overlaps, merge)
- Padding explanation  
**Example**: Show creating range with padding  
**Acceptance**: DartDoc complete, example compiles

---

### T041: [P] Document TimeSeriesData API
**Description**: Add comprehensive DartDoc to TimeSeriesData  
**File**: `lib/src/foundation/data_models/time_series_data.dart`  
**Requirements**:
- Class-level documentation
- Aggregation method documentation
- Timezone handling explanation
- Conversion to ChartSeries example  
**Example**: Show sampling and aggregation  
**Acceptance**: DartDoc complete, example compiles

---

### T042: [P] Document ObjectPool API
**Description**: Add comprehensive DartDoc to ObjectPool  
**File**: `lib/src/foundation/performance/object_pool.dart`  
**Requirements**:
- Class-level documentation with use case
- Generic type explanation
- Factory/reset function documentation
- Statistics property documentation  
**Example**: Show pooling Paint objects  
**Acceptance**: DartDoc complete, example compiles

---

### T043: [P] Document ViewportCuller API
**Description**: Add comprehensive DartDoc to ViewportCuller  
**File**: `lib/src/foundation/performance/viewport_culler.dart`  
**Requirements**:
- Class-level documentation
- Algorithm explanation (binary search vs linear)
- Margin parameter documentation
- Performance characteristics  
**Example**: Show culling with ordered data  
**Acceptance**: DartDoc complete, example compiles

---

### T044: [P] Document BatchProcessor API
**Description**: Add comprehensive DartDoc to BatchProcessor  
**File**: `lib/src/foundation/performance/batch_processor.dart`  
**Requirements**:
- Class-level documentation
- Generic types explanation
- Key extractor documentation
- Use case examples  
**Example**: Show batching by color  
**Acceptance**: DartDoc complete, example compiles

---

### T045: [P] Document ChartResult API
**Description**: Add comprehensive DartDoc to ChartResult  
**File**: `lib/src/foundation/type_system/chart_result.dart`  
**Requirements**:
- Sealed class pattern explanation
- Success/Failure variant documentation
- Method documentation (when, map, flatMap, fold)
- Pattern matching example  
**Example**: Show when() usage  
**Acceptance**: DartDoc complete, example compiles

---

### T046: [P] Document ChartError API
**Description**: Add comprehensive DartDoc to ChartError  
**File**: `lib/src/foundation/type_system/chart_error.dart`  
**Requirements**:
- Class-level documentation
- Factory constructor documentation
- Error type/severity explanation
- Error code format documentation  
**Example**: Show creating validation error  
**Acceptance**: DartDoc complete, example compiles

---

### T047: [P] Document ValidationUtils API
**Description**: Add comprehensive DartDoc to ValidationUtils  
**File**: `lib/src/foundation/type_system/validation_utils.dart`  
**Requirements**:
- Class-level documentation
- Each validation method documented
- Composability explanation
- ChartResult integration  
**Example**: Show validateAll() chain  
**Acceptance**: DartDoc complete, example compiles

---

### T048: [P] Document StatisticalFunctions API
**Description**: Add comprehensive DartDoc to StatisticalFunctions  
**File**: `lib/src/foundation/math/statistics.dart`  
**Requirements**:
- Class-level documentation
- Each function documented with formula
- Edge case behavior (empty list, NaN)
- Performance characteristics  
**Example**: Show mean, median, std dev calculation  
**Acceptance**: DartDoc complete, example compiles

---

### T049: [P] Document InterpolationFunctions API
**Description**: Add comprehensive DartDoc to InterpolationFunctions  
**File**: `lib/src/foundation/math/interpolation.dart`  
**Requirements**:
- Class-level documentation
- Each interpolation method explained
- Algorithm references
- Parameter constraints (t ∈ [0,1])  
**Example**: Show cubic spline usage  
**Acceptance**: DartDoc complete, example compiles

---

### T050: [P] Document CurveFittingFunctions API
**Description**: Add comprehensive DartDoc to CurveFittingFunctions  
**File**: `lib/src/foundation/math/curve_fitting.dart`  
**Requirements**:
- Class-level documentation
- Each fitting method explained
- R² interpretation
- FitResult usage  
**Example**: Show linear regression  
**Acceptance**: DartDoc complete, example compiles

---

### T051: Create Foundation Layer README
**Description**: Create comprehensive README for foundation layer  
**File**: `lib/src/foundation/README.md`  
**Contents**:
- Overview of foundation layer
- Quick start guide (from quickstart.md)
- Architecture diagram
- Performance characteristics
- Usage examples for each component  
**Acceptance**: README complete, examples tested

---

### T052: Update Main Package README
**Description**: Update main package README with foundation layer section  
**File**: `README.md` (repository root)  
**Add Section**: Foundation Layer overview with link to detailed docs  
**Acceptance**: README updated, foundation mentioned

---

## Phase 3.11: Quality & Polish

**Dependencies**: All implementation, documentation complete

### T053: Run Full Test Suite
**Description**: Execute all tests and verify 100% coverage  
**Commands**:
```bash
flutter test test/unit/foundation/
flutter test test/contract/foundation/
flutter test test/performance/foundation/
flutter test --coverage
```
**Coverage Target**: 100% for lib/src/foundation/  
**Acceptance**: All tests pass, coverage report shows 100%

---

### T054: Run Integration Tests with ChromeDriver
**Description**: Execute all integration tests  
**Commands**:
```bash
# Start ChromeDriver in separate terminal
chromedriver --port=4444

# Run integration tests
flutter drive --driver=test/test_driver/integration_test.dart \
  --target=test/integration_test/foundation_data_models_test.dart -d chrome
# ... repeat for T031-T034
```
**Acceptance**: All integration tests pass, no errors

---

### T055: Validate Dart Analyzer (Zero Warnings)
**Description**: Run analyzer and ensure zero warnings  
**Command**: `flutter analyze`  
**Target**: Zero warnings, zero errors  
**Fix**: Any warnings found must be addressed  
**Acceptance**: Analyzer output clean

---

### T056: Run Performance Validation
**Description**: Execute all benchmarks and verify targets met  
**Command**: `flutter test test/performance/foundation/`  
**Verify**:
- ChartDataPoint: <1μs ✓
- ObjectPool: <100ns ✓
- ViewportCuller: <1ms for 10k ✓
- Math functions: All targets met ✓  
**Acceptance**: All performance targets verified

---

### T057: Memory Profiling
**Description**: Profile memory usage with large datasets  
**Tool**: Flutter DevTools Memory view  
**Test Cases**:
- Create 100k ChartDataPoint objects
- Run for 60 seconds, monitor for leaks
- Verify <10MB for 10k series  
**Acceptance**: No memory leaks, targets met

---

### T058: Final Code Review & Cleanup
**Description**: Review all code for quality and consistency  
**Checklist**:
- [ ] All files have copyright headers
- [ ] All public APIs documented
- [ ] No TODO comments remain
- [ ] No debug print statements
- [ ] Consistent naming conventions
- [ ] No dead code
- [ ] SOLID principles followed  
**Acceptance**: Code review complete, all items checked

---

## Dependencies Graph

```
Phase 3.1: Setup (T001-T003) [P]
  ↓
Phase 3.2: Contract Tests (T004-T007) [P] MUST FAIL
  ↓
Phase 3.3: Type System (T008-T011)
  ├─→ Phase 3.4: Data Models (T012-T016) [P]
  ├─→ Phase 3.5: Performance (T017-T020) [P]
  └─→ Phase 3.6: Math (T021-T024) [P]
       ↓
Phase 3.7: Benchmarks (T025-T029) [P]
  ↓
Phase 3.8: Integration Tests (T030-T034) [P]
  ↓
Phase 3.9: Public API (T035-T037)
  ↓
Phase 3.10: Documentation (T038-T052) [P]
  ↓
Phase 3.11: Quality (T053-T058)
```

---

## Parallel Execution Examples

### Example 1: Contract Tests (All Parallel)
```bash
# Launch all contract tests simultaneously
Task: "Contract test data models in test/contract/foundation/data_models_contract_test.dart"
Task: "Contract test performance in test/contract/foundation/performance_contract_test.dart"
Task: "Contract test type system in test/contract/foundation/type_system_contract_test.dart"
Task: "Contract test math utilities in test/contract/foundation/math_contract_test.dart"
```

### Example 2: Data Models (All Parallel after Type System)
```bash
# After T008-T011 complete, launch all data models
Task: "Implement ChartDataPoint in lib/src/foundation/data_models/chart_data_point.dart"
Task: "Implement ChartSeries in lib/src/foundation/data_models/chart_series.dart"
Task: "Implement DataRange in lib/src/foundation/data_models/data_range.dart"
Task: "Implement TimeSeriesData in lib/src/foundation/data_models/time_series_data.dart"
```

### Example 3: Documentation (All Parallel)
```bash
# After implementation complete, document all APIs
Task: "Document ChartDataPoint API with DartDoc and examples"
Task: "Document ChartSeries API with DartDoc and examples"
Task: "Document DataRange API with DartDoc and examples"
# ... all T038-T050
```

---

## Task Execution Notes

### TDD Enforcement
1. **Phase 3.2 MUST complete FIRST**: All contract tests written and failing
2. **No implementation without failing tests**: Constitutional requirement
3. **Verify test failure**: Run tests after writing, confirm RED state
4. **Implement to pass**: Write minimal code to make tests GREEN
5. **Refactor**: Clean up code while keeping tests GREEN

### Parallel Execution
- **[P] markers**: Tasks can run in parallel (different files, no shared state)
- **No [P]**: Sequential execution required (dependencies or same file)
- **Maximize throughput**: Group parallel tasks, execute together

### Constitutional Compliance
- **100% Coverage**: Every task includes testing (T004-T007, T011, T016, T020, T024)
- **Performance Validation**: Benchmarks verify all FR-005 targets (T025-T029)
- **Documentation**: All public APIs documented (T038-T052)
- **Zero Warnings**: Analyzer enforced (T055)

### Quality Gates
- **After T007**: All contract tests fail ✓
- **After T024**: All implementation complete, contract tests pass ✓
- **After T029**: All performance targets verified ✓
- **After T034**: All integration tests pass ✓
- **After T058**: Ready for higher layers ✓

---

## Estimated Timeline

**With Parallel Execution** (3-4 developers):
- **Week 1**: Setup + Type System + Data Models (T001-T016)
- **Week 2**: Performance + Math + Benchmarks (T017-T029)
- **Week 3**: Integration + API + Documentation (T030-T052)
- **Week 4**: Quality & Polish (T053-T058)

**Sequential Execution** (1 developer):
- **Week 1-2**: Setup through Data Models (T001-T016)
- **Week 3-4**: Performance + Math (T017-T024)
- **Week 5-6**: Benchmarks + Integration (T025-T034)
- **Week 7-8**: API + Documentation + Polish (T035-T058)

---

## Success Criteria

✅ **All 58 tasks complete**  
✅ **100% test coverage** for lib/src/foundation/  
✅ **All performance targets met** (FR-005.1 to FR-005.10)  
✅ **Zero analyzer warnings**  
✅ **All integration tests pass**  
✅ **All public APIs documented**  
✅ **Memory profiling clean** (no leaks)  
✅ **Constitutional compliance verified**  

**Next Phase**: Rendering Layer (Layer 1) - depends on Foundation Layer completion

---

*Generated from specs/001-foundation/ design artifacts*  
*Constitutional compliance enforced*  
*Ready for TDD implementation*
