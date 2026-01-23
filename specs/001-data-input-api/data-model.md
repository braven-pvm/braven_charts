# Data Model: Scientific Data Input

## Entities

### Series<TX, TY>

**Description**: The primary container for a sequence of data points.

- **Fields**:
  - `id`: String (Unique Identifier)
  - `meta`: SeriesMeta (Name, Units, etc.)
  - `storage`: SeriesStorage<TX, TY> (The physical data)
  - `stats`: SeriesStats? (Summary statistics: min, max, mean, count)
- **Relationships**: Owns one `SeriesStorage`.

### SeriesStorage<TX, TY>

**Description**: Abstract interface for columnar data access.

- **Variants**:
  - `TypedDataStorage`: Backed by `Float64List` / `Int64List`.
  - `ListStorage`: Backed by `List<T>` (fallback/flexible).
- **Methods**:
  - `count`: int
  - `getX(index)`: TX
  - `getY(index)`: TY
  - `copy()`: SeriesStorage

### Point Types (Logical)

These are transient objects returned by iterators or accessors, not stored directly in bulk.

- **RawPoint<TX, TY>**: `{ x: TX, y: TY }`
- **IntervalPoint<TX, TY>**: `{ x: TX, min: TY, max: TY, mean: TY, median: TY? }`
- **DistributionPoint<TX, TY>**: `{ x: TX, histogram: Map<Bucket, Count> }`

### AggregationSpec

**Description**: Configuration for downsampling.

- **Fields**:
  - `window`: WindowSpec (Fixed, Rolling, PixelAligned)
  - `reducer`: SeriesReducer (Mean, Max, Sum, Custom)

### WindowSpec

**Description**: Defines how to slice the domain.

- **Types**:
  - `Fixed`: size (TX)
  - `Rolling`: size (TX)
  - `PixelAligned`: pixelDensity (double)

## Validation Rules

1. **Storage Integrity**: `storage.count` must be non-negative.
2. **Type Safety**: `TX` and `TY` must match the backing storage capabilities (e.g., `Int64List` only supports `int`).
3. **Sorted Time**: For Time-Series, X-axis values SHOULD be sorted for efficient windowing/binary search.
4. **Sentinel Handling**: Accessors must handle sentinel values gracefully (e.g. return `null` or filter them out based on configuration).
