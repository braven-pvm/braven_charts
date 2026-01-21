# Research: Scientific Data Input & Aggregation API

## Decisions

### 1. Architectural Separation

**Decision**: Create a standalone package `braven_data`.
**Rationale**:

- Decouples data processing from UI rendering (Flutter).
- Enables headless testing and processing in background isolates / servers.
- Prevents circular dependencies between chart logic and data models.
  **Alternatives Considered**:
- _Internal Library_: Rejected due to risk of coupling and cleaner workspace management.
- _Monorepo Sub-package_: Adopted (workspace root) to facilitate future extraction.

### 2. Physical Storage

**Decision**: Use `dart:typed_data` primitives (`Float64List` for values, `Int64List` for time).
**Rationale**:

- **Memory**: ~8 bytes/point vs ~64+ bytes for Dart objects. 1M points = ~16MB (compact) vs >100MB (objects).
- **CPU**: SIMD-friendly access patterns, reduced GC pressure.
  **Missing Data Strategy**:
- Use `double.nan` for missing float values (IEEE 754 standard).
- Use `Int64.min` (`0x8000000000000000`) for missing time values.

### 3. Aggregation Methodology

**Decision**: Synchronous pipeline with windowed reduction.
**Rationale**:

- Performance for typical scientific datasets (100k-1M points) is sufficient on main thread if vectorised/efficient.
- Async overhead (Streams) introduces complexity and scheduling latency unnecessary for V1 batch loading.
  **Algorithms**:
- **Mean/Max/Min**: Standard online calculation.
- **Normalized Power**: Rolling 30s mean -> Pow(4) -> Mean -> Pow(0.25).
- **Variability Index**: NP / Average Power.

### 4. Benchmarking Capability

**Decision**: Standalone Dart CLI scripts using `Stopwatch`.
**Rationale**:

- Avoids Flutter Engine overhead ("Headless Flutter").
- Provides stable, noise-free metrics for pure algorithmic performance.
- Easy to run in CI pipelines.

### 5. API Design

**Decision**: Fluent Builder pattern for Pipelines.
**Rationale**: Allows readable chaining of operations (`.rolling().map().collapse()`) mirroring functional programming styles familiar to data scientists (Pandas/Polars).

## Implementation References

- **Normalized Power Formula**: Coggan, A. R. (2003). training and racing with a power meter.
- **IEEE 754**: Standard for Floating-Point Arithmetic (NaN handling).
