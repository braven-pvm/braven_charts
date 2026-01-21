# Scientific Data Input & Aggregation API (Comprehensive Design)

## 1. Problem Statement & Goals

### The Problem

Scientific plotting involves datasets that far exceed screen resolution (millions of points). Rendering every point is:

1.  **Slow**: CPU/GPU bottleneck.
2.  **Useless**: Pixels overlap, hiding density and distribution.
3.  **Misleading**: Outliers can be masked by noise or overdrawing.

### The Goal

Create a **typed, stream-capable, scientific data pipeline** that ingests raw data, performs deterministic reduction (aggregation/downsampling), and outputs a **Render-Ready Series**.

### Critical Performance Constraint: "The Rendering Contract"

**The Rendering Engine MUST NEVER aggregate data.**
It is a "dumb" visualizer. It receives a clean, columnar buffer of $(x, y)$ (plus optional pre-computed min/max/error) and draws lines/shapes.

- **Input**: `Series<TX, TY>` (Raw, heavy, huge).
- **Process**: `Aggregate` -> `Downsample` -> `Pyramid`.
- **Output**: `RenderSeries` (Light, screen-adapted, float32-ready).

---

## 2. Core Concepts & Data Model

We separate the **Logical Model** (Science) from the **Physical Storage** (Performance).

### A. The Series (Logical)

A `Series<TX, TY>` is the unit of management. It holds metadata, domains, and a handle to storage.

```dart
/// The user-facing container for scientific data.
class Series<TX, TY> {
  final String id;
  final SeriesMeta meta;

  // Logical Definitions
  final AxisDomain<TX> xDomain; // e.g., Time(ns), LogFrequency(Hz)
  final AxisDomain<TY> yDomain; // e.g., Voltage(mV), Count(N)

  // Physical Data
  final SeriesStorage<TX, TY> storage;

  // Statistical Summary (computed on ingest)
  final SeriesStats<TY>? globalStats;
}
```

### B. Columnar Storage (Physical)

We avoid `List<Point>` objects to reduce GC pressure and pointer chasing. Data is stored in typed arrays.

```dart
/// Abstraction for memory efficiency.
/// Implementations: ListStorage, TypedDataStorage (Float64List), MappedFileStorage.
abstract class SeriesStorage<TX, TY> {
  int get count;
  TX getX(int index);
  TY getY(int index);

  // Bulk access for high-speed processing
  List<TX> getXRange(int start, int end);
  List<TY> getYRange(int start, int end);
}
```

### C. The Point Varieties

While storage is columnar, we need types to reason about _what_ we are storing.

1.  **`RawPoint`**: Simple $(x, y)$.
2.  **`IntervalPoint`**: A summarized bin. Contains $x_{start}, x_{end}$ and statistics ($\mu, \sigma, \min, \max$). Used for drawing error bars or candlesticks.
3.  **`DistributionPoint`**: Similar to Interval, but contains quantiles ($q_{25}, q_{75}$) or a full histogram. Used for box plots.

---

## 3. Aggregation: The Heart of the Pipeline

Aggregation transforms data from "Raw Domain" to "Visual Domain".

### Workflow

1.  **Windowing**: Slice $x$-axis into buckets (Time, Count, or Value based).
2.  **Reducing**: Compute statistics for each bucket.
3.  **Emitting**: Create a new `Series` of `IntervalPoint`s.

### API Proposal: `AggregationSpec`

````dart
/// Defines HOW to reduce the data.
class AggregationSpec<TX> {
  // 1. How to slice
  final WindowSpec<TX> window;

  // 2. What to calculate
  final List<SeriesReducer> reducers; // CHANGED: Enum -> Extensible Class

  // 3. Post-process limit
  final int? maxOutputPoints;
}

/// Alignment of the window result relative to the input timeline
enum WindowAlignment {
  start,  // Point T represents [T, T+Size]
  center, // Point T represents [T-Size/2, T+Size/2]
  end     // Point T represents [T-Size, T] (Default for Trailing/Real-time)
}

/// Examples of Windowing
class WindowSpec<TX> {
  // "Fixed Bins": Reduces frequency (e.g., 1 point per 30s).
  // Default Alignment: WindowAlignment.start
  factory WindowSpec.fixed(TX size, {WindowAlignment align});

  // "Rolling Window": Maintains frequency (e.g., 1 point per 1s, smoothed).
  // Default Alignment: WindowAlignment.end (Trailing)
  factory WindowSpec.rolling(TX size, {TX? step, WindowAlignment align});

  // "Pixel Aligned": Dynamic adaptive binning for rendering.
  factory WindowSpec.pixelAligned(double pixels, Range<TX> visibleRange);
}


/// Defines how to reduce a list of values into a single point value
abstract class SeriesReducer<T> {
  T reduce(List<double> values);

  // Built-in reducers
  static const mean = MeanReducer();
  static const max = MaxReducer();
  static const np = NormalizedPowerReducer(); // Domain specific!
}


### 3.1 Specialized Algorithms: Physiological Power Metrics

For scientific and sports usage, simple arithmetic means are insufficient. The API supports multi-stage transformation pipelines for specific domain metrics.

#### A. Normalized Power (NP)®
*Formula*: $\sqrt[4]{\frac{1}{n} \sum (SMA_{30s})^4}$
*Logic*: Accounts for the physiological cost of high-intensity efforts (which rises to the 4th power of intensity).
*Pipeline Implementation*:
1.  **Smoothing**: Simple Moving Average (SMA), 30-second window.
2.  **Weighting**: Raise smoothed values to $P^4$.
3.  **Averaging**: Arithmetic Mean of the weighted values.
4.  **Scaling**: Take the 4th root.

#### B. xPower (Exponential variation)
*Formula*: $\sqrt[4]{\frac{1}{n} \sum (EWMA_{25s})^4}$
*Logic*: Similar to NP but uses Exponentially Weighted Moving Average for better temporal response (no "drop-off" artifact).
*Pipeline Implementation*:
1.  **Smoothing**: EWMA, 25-second window ($\alpha \approx 1/26$).
2.  **Weighting**: Rate smoothed values to $P^4$.
3.  **Averaging**: Arithmetic Mean.
4.  **Scaling**: Take 4th root.

#### C. Variability Index (VI)
*Formula*: $VI = \frac{NP}{AP}$
*Logic*: Ratio of Normalized Power to Average Power.
- $VI \approx 1.0$: Steady state effort.
- $VI > 1.2$: Highly stochastic (criterium/intervals).

### 3.2 Transformer Pipeline Extensions

To support the above, the `SeriesPipeline` includes `map()` and `rolling()` operators beyond simple windowing:

```dart
// Example: Calculating Normalized Power manually via primitives
var np = SeriesPipeline(rawWatts)
    .rollingMean(window: Duration(seconds: 30)) // Step 1: SMA
    .map((w) => pow(w, 4))                      // Step 2: Weight
    .collapse(Reducer.mean)                     // Step 3: Mean
    .map((w) => pow(w, 0.25));                  // Step 4: Root
````

````

### 3.3 Extensible Metric System (Formalized Calculations)

To avoid hardcoding every scientific formula into the core, we support a plugin architecture via `SeriesMetric` (Scalar) and `SeriesReducer` (Vector/Rolling).

#### The Metric Interface (Scalar)
```dart
/// Calculates a single value for an entire series (e.g., Total Normalized Power)
abstract class SeriesMetric<T> {
  T calculate(Series<dynamic, double> series);
}
```

#### The Reducer Interface (Vector/Rolling)
```dart
/// Applied to a Window (Fixed or Rolling) to produce a Point in a new Series.
/// This is what generates the "Data for Plotting".
abstract class SeriesReducer<T> {
  T reduce(List<double> windowValues);
}
```

#### Example: Implementing Reducers
```dart
class NormalizedPowerReducer implements SeriesReducer<double> {
  @override
  double reduce(List<double> values) {
    // Standard NP formula applied to this specific window/bin
    if (values.isEmpty) return 0.0;
    // Note: NP usually requires a 30s pre-smoothing, so typically
    // this reducer is applied to a 30s-smoothed series OR
    // it implements the logic internally on raw data.
    double sum4th = 0.0;
    for (final v in values) sum4th += pow(v, 4);
    return pow(sum4th / values.length, 0.25).toDouble();
  }
}
```

#### Proposed Usage (Fluent API)
Users can extend `SeriesPipeline` to add "syntax sugar" for their domain.

```dart
// Generate the PLOT DATA (Series)
// "30s Rolling Average Curve"
var plotData = SeriesPipeline(rawWatts)
    .rolling(window: Duration(seconds: 30))
    .reduce(SeriesReducer.mean) // or SeriesReducer.np
    .toSeries();

// Generate the METRIC (Scalar)
// "Total ride NP"
var npValue = SeriesPipeline(rawWatts).calculateNormalizedPower();
### Technical Explanation: Binning vs. Downsampling

- **Binning (Aggregation)**: 100 points -> 1 representative point (mean/max). Mathematically changes data shape. Good for scientific summaries.
- **Downsampling (LTTB - Largest Triangle Three Buckets)**: 100 points -> 1 selected point provided by original data. Visually preserves peaks and valleys. Good for "Sparklines" or general trends.

**Recommendation**: The API supports both via `SeriesProcessor`.

---

## 4. The Render-Ready Contract

The renderer API should look like this:

```dart
/// The ONLY thing the renderer consumes.
class RenderReadyData {
  // Float32Arrays for direct GPU upload or Canvas path creation
  final Float32List xCoordinates;
  final Float32List yCoordinates;

  // Optional buffers for auxiliary visuals
  final Float32List? yMin; // For error bands
  final Float32List? yMax; // For error bands
  final Int8List? flags;   // For coloring points by quality/status
}
````

**Developer Workflow**:

```dart
// 1. User loads massive dataset
var rawSeries = await CsvLoader.load("sensor_logs.csv");

// 2. Pipeline (runs in Isolate usually)
var viewSeries = SeriesPipeline(rawSeries)
    .window(Seconds(10))        // Aggregate to 10s buckets
    .reduce({mean, min, max})   // Compute error bars
    .toRenderSeries();          // Convert to Float32Lists

// 3. Render
chart.draw(viewSeries);
```

---

## 5. Use Case Scenarios

### Scenario A: High-Frequency Sensor (IoT)

**Context**: Vibration sensor @ 10kHz. 1 hour = 36M points.
**Requirement**: User zooms out to see the whole hour, then zooms in to 10ms spike.
**Solution**:

1.  **Ingest**: multiscale pyramid. Level 0 (Raw), Level 1 (1s Max/Min), Level 2 (1m Max/Min).
2.  **Render**: When zoomed out, chart requests Level 2. Renderer draws 60 points (Min/Max envelope).
3.  **Zoom**: User drills down. Chart requests Level 0 for the specific 10ms visible range.

### Scenario B: Irregular Market Data

**Context**: Trades happen sporadically.
**Requirement**: OHLC (Open High Low Close) bars every 1 minute.
**Solution**:

1.  Use `WindowSpec.fixed(Duration(minutes: 1))`.
2.  Use `reducers: {first, max, min, last}`.
3.  Output `IntervalPoint`s drawn as Candle sticks.

### Scenario C: Experimental Distribution (Biology)

**Context**: 1000 samples per time-point (replicates).
**Requirement**: Show median and 95% CI.
**Solution**:

1.  Use `WindowSpec.distinctX()` (group by unique X).
2.  Use `reducers: {median, quantile(0.05), quantile(0.95)}`.
3.  Render median as line, quantiles as shaded area.

---

## 6. Data Ingestion & Transformation Detail

### The Reality of "Raw Data"

Real-world scientific files are rarely single arrays. They are tables (CSV, Parquet, SQL Results) with **One Independent Variable (X)** (usually Time or Index) and **Multiple Dependent Variables (Y)**.

#### Example: `sensor_logs.csv`

```csv
timestamp,    sensor_1_volt, sensor_2_amp, status_flag
1700000001.0, 5.12,          0.50,         OK
1700000001.1, 5.14,          0.51,         OK
1700000001.2, 8.99,          0.49,         OL  <-- Outlier/Spike
...
```

### The Ingestion Strategy: "Table to Series"

We do not feed the CSV directly to the chart. We **Explode** the table into Columnar Series.

**Step 1: The Schema Definition**

We define how to read the file **once**.

```dart
final schema = CsvSchema(
  xColumn: "timestamp",
  xType: DataType.float64, // or DataType.timestamp
  columns: [
    ColumnDef(name: "sensor_1_volt", type: DataType.float32),
    ColumnDef(name: "sensor_2_amp",  type: DataType.float32),
    ColumnDef(name: "status_flag",   type: DataType.string) // Categorical
  ]
);
```

**Step 2: The Loader (Streaming)**

The loader reads the file line-by-line (or chunk-by-chunk) and populates **Column Buffers**. It does NOT create objects per row.

```dart
// Result is a "DataFrame" - a collection of unrelated columns aligned by index
DataFrame table = await CsvLoader.load("sensor_logs.csv", schema);
```

**Step 3: Series Extraction**

We assume the user wants to plot _Voltage_ and _Amperage_ on two vertically stacked charts. We extract two independent Series objects. Key concept: **They share the X-buffer** (zero-copy if possible).

```dart
// Series 1: Voltage
var voltageSeries = Series.fromColumns(
    id: "volt_s1",
    x: table["timestamp"],
    y: table["sensor_1_volt"],
    xDomain: AxisDomain.time(),
    yDomain: AxisDomain.numeric(unit: "V")
);

// Series 2: Amperage
var ampSeries = Series.fromColumns(
    id: "amp_s2",
    x: table["timestamp"],
    y: table["sensor_2_amp"],
    xDomain: AxisDomain.time(),
    yDomain: AxisDomain.numeric(unit: "A")
);
```

**Step 4: The Pipeline (Per Series)**

Now we apply specific logic. Voltage needs smoothing (Mean), Amperage needs Peak detection (Max).

```dart
// Voltage: Smooth out noise
var renderVolt = SeriesPipeline(voltageSeries)
    .window(Seconds(1))
    .reduce({mean})
    .toRenderSeries();

// Amperage: Capture short circuit spikes (Max)
var renderAmp = SeriesPipeline(ampSeries)
    .window(Seconds(1))
    .reduce({max})
    .toRenderSeries();
```

**Outcome**:

1.  **Memory Efficient**: We store columns `[float, float, float]`, not `List<RowObj>`.
2.  **Flexible**: One CSV input -> Multiple independent plots with different aggregation rules.
3.  **Fast**: Ingestion is just parsing strings to floats. Aggregation is a tight loop over float arrays.

---

## 8. Provenance & Verification

### Validated Against Real-World Data

This API design has been scenario-tested against typical cyclic performance data sets (simulating Garmin FIT exports), which present challenging requirements:

- **Multi-Metric**: Single timestamp correlated with Power (W), HR (bpm), Cadence (rpm), Speed (kph).
- **Mixed-Mode Aggregation**:
  - _Power_ requires **Sliding Window Mean (30s)** for smoothing pedal strokes.
  - _Power_ ALSO requires **Fixed Window Max (1m)** for peak output analysis.
  - _Heart Rate_ requires **Fixed Window Mean (5m)** for aerobic drift trends.

The `SeriesPipeline` specifically supports these "Forked Views"—one raw buffer, multiple interpretive pipelines—without duplicating the underlying memory.

---

## 9. Real-World Usage Example

Below is the exact pattern for ingesting a Garmin FIT/CSV file using this API.

### 9.1 The Source Data (`GarminPing.csv`)

```csv
timestamp,                  power, heart_rate, cadence
2025-10-26 07:32:46+02:00,  100.0, 85,         61
2025-10-26 07:32:47+02:00,  102.0, 86,         62
...
```

### 9.2 The Ingestion Code

```dart
void main() async {
  // 1. Define Schema (Once per file type)
  final schema = CsvSchema(
    dateColumn: "timestamp",
    columns: [
      ColumnDef("power", FieldType.float),
      ColumnDef("heart_rate", FieldType.integer),
    ]
  );

  // 2. Load Data (Streamed/Buffered)
  final table = await CsvLoader.load("data/GarminPing.csv", schema);

  // 3. Extract Series (Zero-Copy Views)
  final powerSeries = Series.fromColumn(
    id: "pwr",
    x: table.timestampColumn,
    y: table["power"]
  );

  // 4. Calculate Specialized Metrics (Scalar)
  final np = SeriesPipeline(powerSeries).calculateNormalizedPower();
  print("Normalized Power: ${np.toStringAsFixed(1)} W");

  // 5. Generate Smoothed Curves for Plotting (Series)
  // "Give me a 30s Rolling Average line to draw on the chart"
  // DEFAULT: Uses 'WindowAlignment.end' (Trailing).
  // Point at 10:00:30 represents average of 10:00:00 -> 10:00:30.
  final smoothPower = SeriesPipeline(powerSeries)
      .rolling(window: Duration(seconds: 30))
      .reduce(SeriesReducer.mean)
      .toSeries();

  // "Give me a 30s Rolling NP line to draw" (Sustained intensity)
  final np30s = SeriesPipeline(powerSeries)
      .rolling(window: Duration(seconds: 30))
      .reduce(SeriesReducer.np)
      .toSeries();
}
```

---

## 10. Implementation Phases

### Phase A: Data Model Types (`Series`, `Point`, `AxisDomain`, `PointMeta`)

Define the immutable data carriers. Ensure `SeriesStorage` can wrap a generic `Float64List` or `ByteBuffer`.

### Phase B: Logical Operators

Implement `Windowing.fixed`, `Windowing.sliding`, and the `Reducer` set (`mean`, `max`, `min`, `first`, `last`).

### Phase C: Pipeline & Rendering Contract

Build the `SeriesPipeline` fluent interface and `toRenderSeries()` exporter.
**Strict Enforcement**: The renderer must accept `RenderSeries`, not `List<Point>`.

### Phase D: Downsampling

Implement `LTTB` (Largest-Triangle-Three-Buckets) for visually faithful reduction of high-frequency noise not served by simple binning.

---

## 10. Sample API Usage

```dart
// 1. Define Domains
final tDomain = AxisDomain.time(unit: TimeUnit.seconds);
final vDomain = AxisDomain.numeric(unit: Unit("Volts"), limits: Range(0, 5));

// 2. Create Series
final rawData = Series.fromLists(
    x: timeStamps,
    y: voltages,
    xDomain: tDomain,
    yDomain: vDomain
);

// 3. Configure Aggregator
final pipe = AggregationPipeline()
    .step(
        WindowStep.fixed(1.0), // 1-second bins
        [Stats.mean, Stats.stdDev] // Compute Mean and Sigma
    );

// 4. Process
final summarySeries = pipe.process(rawData);

// 5. Visualize
// "Render mean line with sigma band"
chart.add(
    LineSeries(summarySeries, yAccessor: (p) => p.mean),
    BandSeries(summarySeries,
        upper: (p) => p.mean + p.stdDev,
        lower: (p) => p.mean - p.stdDev
    )
);
```
