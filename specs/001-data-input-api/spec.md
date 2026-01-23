# Feature Specification: Scientific Data Input & Aggregation API

**Feature Branch**: `001-data-input-api`  
**Created**: 2026-01-21  
**Status**: Draft  
**Input**: User description: "Implement Scientific Data Input & Aggregation API based on docs\data_input_api_proposal.md"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - High-Performance Data Ingestion (Priority: P1)

A developer needs to load large scientific datasets (e.g., 1 million+ points) into the chart system without blocking the UI thread or causing memory issues, using efficient columnar storage.

**Why this priority**: Foundation of the entire system. Without efficient storage and ingestion, aggregation and rendering are impossible.

**Independent Test**: Can be fully tested by ingesting a synthetic dataset of 10M points and verifying memory usage and access speed via the Data Series API.
**Performance Verification**: Use a standalone Dart script (e.g., `benchmarks/perf.dart`) using `Stopwatch` to verify ingestion and access times are within limits, avoiding Flutter test harness overhead.

**Acceptance Scenarios**:

1. **Given** a raw dataset of 1M double-precision values, **When** ingested into a "Typed Data Series" using optimized storage, **Then** memory usage should reflect compact primitive storage rather than object overhead.
2. **Given** a Data Series object, **When** accessing data via sequential or random access methods, **Then** values are returned correctly and efficiently.
3. **Given** different data types (e.g., Time, Voltage), **When** creating a Series, **Then** strongly-typed variations (e.g. Time-Value vs Value-Value) are supported.
4. **Given** an empty dataset, **When** ingested, **Then** the system creates a valid empty Series without errors.

---

### User Story 2 - Deterministic Aggregation & Downsampling (Priority: P1)

A developer wants to visualize a dense dataset where point density exceeds screen pixels. The system must automatically or manually aggregate data (e.g., "1 point per pixel") to produce a render-ready series.

**Why this priority**: Essential for the "Rendering Contract" (dumb renderer) and performance/visual clarity.

**Independent Test**: Create a Series with 1000 points, define a Window Configuration of size 10, run aggregation, verify output has 100 points with correct reduced values (Mean/Max).

**Acceptance Scenarios**:

1. **Given** a Series of 100 points and a Fixed Window of size 10, **When** aggregated with an "Average" reducer, **Then** output is a Series of 10 "Interval Points", each representing the average of its window.
2. **Given** a large dataset and a visible range, **When** using a "Pixel Aligned" window strategy, **Then** the aggregation window dynamically adjusts to match the points-per-pixel target.
3. **Given** a Series, **When** reduced, **Then** the output is a set of "Interval Points" (containing min, max, mean) suitable for drafting error bars or candlesticks.

---

### User Story 3 - Scientific Pipeline & Metrics (Priority: P2)

A sports scientist needs to calculate domain-specific metrics (like Normalized Power) from a raw data stream using a chain of transformations (Smoothing -> Weighting -> Averaging -> Scaling).

**Why this priority**: Validates the extensibility of the architecture and fulfills the "Scientific" part of the proposal.

**Independent Test**: Implement the Normalized Power (NP) algorithm using the Pipeline API and verify it matches the verified mathematical formula result for a known dataset.

**Acceptance Scenarios**:

1. **Given** a power series, **When** applying a pipeline of "Rolling Mean 30s -> Power(4) -> Average -> Root(4)", **Then** the result matches the standard Normalized Power calculation.
2. **Given** a custom requirement, **When** a user implements a Custom Metric or Reducer, **Then** it can be plugged into the pipeline seamlessy.
3. **Given** a pipeline definition, **When** data flows through, **Then** intermediate series (e.g., smoothed data) can optionally be accessed or visualized.

## Functional Requirements

### 1. Core Data Structures

- **Typed Data Series**: Main container class with `id`, metadata, statistics, and storage handle.
- **Storage Abstraction**: Interface for data access.
  - Implement **List Storage** (standard dynamic array).
  - Implement **Optimized Storage** (language-native primitive buffers).
    - Double data: `Float64List` (uses `NaN` for missing values)
    - Time data: `Int64List` (microseconds since epoch, uses `Int64.min` for sentinel)
- **Point Types**:
  - **Raw Point**: Simple x, y.
  - **Interval Point**: Aggregated bin with statistics (min, max, mean). stored as parallel arrays (Structure-of-Arrays) for performance.
  - **Distribution Point**: [DEFERRED] Aggregated bin with histogram/quantiles (Future Scope).

### 2. Aggregation Engine

- **Window Configuration**: Configuration for slicing data.
  - `Fixed`: Fixed bin size.
  - `Rolling`: Sliding window.
  - `Pixel Aligned`: Dynamic sizing based on visibility.
- **Series Reducer**: Extensible logic for reducing a window to a value.
  - Built-in: `Mean`, `Max`, `Min`, `Sum`.

### 3. Pipeline API

- Fluent interface for transforming Series.
- Operators: `map` (transform values), `rolling` (sliding window), `collapse` (reduce to scalar), `window` (reduce to series).
- Support for "Stream-like" definition.

### 4. Domain Specific Algorithms

- Pre-implement **Normalized Power (NP)** logic.
- Pre-implement **xPower** logic.
- Pre-implement **Variability Index (VI)**.

## Success Criteria

1.  **Performance**: Aggregating 100k points to 1000 points takes < 50ms. Verified via standalone `Stopwatch` benchmarks.
2.  **Accuracy**: "Rendering Contract" adhered to - Renderer receives clean $(x, y)$ or $(x, y_{min}, y_{max})$ data, never raw dumps of overlapping pixels.
3.  **Extensibility**: Custom Reducers and Metrics can be added without modifying core library code.
4.  **Type Safety**: API enforces generic types (e.g. can't calculate mean of non-numeric types).

## Assumptions

- **Location**: New package created at workspace root `braven_data/`.
- **Architecture**: Implemented as a standalone package (`braven_data`) distinct from the UI library.
- **Synchronous Execution**: Ingestion and processing pipeline are synchronous batch operations for V1. Async stream support is deferred.
- Initial implementation handles in-memory data (`List` / `TypedData`). Memory-mapped file storage is a future optimization.
- "Stream-capable" in this phase implies the API _design_ supports it, but the initial backing implementation might be batch-based for simplicity.
- Rendering Engine implementation is _outside_ the scope of this spec; this spec provides the _input_ to the renderer.

## Dependencies

- Optimized storage libraries (e.g., Typed Data).
- Standard Math libraries.

## Clarifications

### Session 2026-01-21

- Q: Should the initial API support async Streams or only synchronous Lists? → A: Synchronous List/TypedData only (V1).
- Q: How should Time axes be stored internally for performance? → A: Int64List (microseconds) for V1.
- Q: Architectural location of the data layer? → A: Standalone package (`braven_data`) to prevent circular dependencies.
- Q: How to handle sparse/missing data in primitive arrays? → A: Use sentinels (`NaN`, `Int64.min`) for efficiency.
- Q: Where should the new `braven_data` package live? → A: Workspace root (`/braven_data`) for eventual extraction to own repo.
- Q: How to benchmark the <50ms aggregation requirement? → A: Standalone Dart script using `Stopwatch` (no Flutter harness).
