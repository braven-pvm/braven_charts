# Technical Debt: FIT File Data Pipeline for Agentic Charts

**Created:** 2025-01-27  
**Sprint:** 003-agentic-charts  
**Priority:** High (blocks meaningful FIT file analysis)  
**Status:** Deferred to post-sprint

## Problem Statement

When users import FIT files into the agentic chart demo, the agent receives only a metadata summary (column names, min/max/mean stats) but has no access to the actual data points. The agent correctly reports "I don't have access to the FIT file data."

### Current Behavior

1. User imports FIT file via `ChatInterface`
2. File is loaded via `LoadDataTool` → stored in `DataStore` with a `dataId`
3. Summary is built via `_buildDataContext()` and appended to user message
4. LLM receives:
   ```
   File: workout.fit (180000 rows)
   Columns:
     - timestamp (DateTime)
     - power (int) [min: 100, max: 850, mean: 225.50]
     - heartRate (int) [min: 95, max: 185, mean: 152.00]
     - cadence (int) [min: 0, max: 120, mean: 85.30]
   Time range: 2025-01-15T06:00:00Z to 2025-01-15T14:30:00Z
   ```
5. LLM has no way to access actual data points to create charts

### Why This Is Non-Trivial

FIT files from endurance athletes can be **massive**:

| Event Type  | Duration   | Recording Rate | Data Points |
| ----------- | ---------- | -------------- | ----------- |
| Short ride  | 1 hour     | 1s             | 3,600       |
| Long ride   | 5 hours    | 1s             | 18,000      |
| Ultra event | 50+ hours  | 1s             | 180,000+    |
| Multi-day   | 100+ hours | 1s             | 360,000+    |

**Sending raw data to LLM is not viable:**

- Token limits exceeded
- Extremely expensive
- Slow processing
- Poor user experience

**Even for visualization, raw data is problematic:**

- Browser/Flutter can't efficiently render 180k points
- Visual clutter makes charts unreadable
- Memory pressure on client devices

## Proposed Solution Architecture

### Data Reduction Pipeline

The system needs intelligent data reduction that preserves analytically-meaningful features:

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Raw FIT     │────▶│  Data Pipeline   │────▶│  Reduced Data   │
│  180k points │     │  (smart reduce)  │     │  ~1000 points   │
└──────────────┘     └──────────────────┘     └─────────────────┘
                              │
                              ▼
                     ┌────────────────────┐
                     │  Analysis Summary  │
                     │  (for LLM context) │
                     └────────────────────┘
```

### Reduction Strategies

#### 1. Time-Based Aggregation

- Aggregate 1-second data into larger windows (30s, 1min, 5min)
- Compute min, max, mean, stdev per window
- Preserve temporal structure while reducing volume

```dart
// Example: 1-second → 30-second aggregation
// 180,000 points → 6,000 points (30x reduction)
```

#### 2. LTTB (Largest Triangle Three Buckets)

- Downsampling algorithm that preserves visual shape
- Selects representative points that maintain chart appearance
- Target: ~1000-2000 points for visualization

#### 3. Peak Detection & Preservation

Critical for power analysis - must preserve:

- 5-second peak power
- 30-second peak power
- 1-minute peak power
- 5-minute peak power
- 20-minute peak power (FTP estimation)
- Heart rate peaks and zones

#### 4. Lap/Interval Detection

- Auto-detect laps from FIT file lap messages
- Aggregate statistics per lap
- Preserve lap boundaries in reduced data

#### 5. Zone Distribution

- Calculate time-in-zone for power and heart rate
- Provide zone distribution summary to LLM
- Enable zone-based analysis queries

### LLM Context Structure

Instead of raw data, provide structured analysis context:

```
File: ultra_race.fit
Duration: 52:30:15
Distance: 320.5 km

Power Analysis:
  - Average: 185W (NP: 210W, IF: 0.72)
  - Peak Powers: 5s=850W, 30s=620W, 1m=520W, 5m=380W, 20m=290W
  - Zones: Z1=15%, Z2=45%, Z3=25%, Z4=12%, Z5=3%

Heart Rate Analysis:
  - Average: 142 bpm, Max: 185 bpm
  - Zones: Z1=10%, Z2=40%, Z3=35%, Z4=12%, Z5=3%

Cadence: Average 82 rpm, Range 0-120

Laps: 12 detected
  Lap 1: 2:15:00, Avg Power 220W, Avg HR 155 bpm
  Lap 2: 2:30:00, Avg Power 195W, Avg HR 148 bpm
  ...

Available for charting:
  - dataId: "fit_abc123"
  - Reduced to 2000 points via LTTB
  - Columns: timestamp, power, heartRate, cadence, speed, altitude
```

### Tool Enhancements Needed

#### 1. `QueryDataTool` (New)

Allow LLM to request specific data slices:

```json
{
  "name": "query_data",
  "input": {
    "dataId": "fit_abc123",
    "columns": ["timestamp", "power", "heartRate"],
    "timeRange": {
      "start": "2025-01-15T08:00:00Z",
      "end": "2025-01-15T09:00:00Z"
    },
    "aggregation": "30s",
    "maxPoints": 500
  }
}
```

#### 2. `AnalyzeDataTool` (New)

Compute specific metrics on demand:

```json
{
  "name": "analyze_data",
  "input": {
    "dataId": "fit_abc123",
    "analysis": ["peak_powers", "zone_distribution", "lap_summary"]
  }
}
```

#### 3. `CreateChartTool` Enhancement

Add `dataId` + `dataColumn` support to schema:

```json
{
  "series": [
    {
      "id": "power",
      "dataId": "fit_abc123",
      "xColumn": "timestamp",
      "yColumn": "power",
      "reduction": "lttb",
      "maxPoints": 1000
    }
  ]
}
```

### Implementation Components

#### Data Pipeline (`lib/src/agentic/services/data_pipeline.dart`)

- `DataReducer` - LTTB and time-aggregation algorithms
- `PeakDetector` - Find power peaks at standard durations
- `ZoneCalculator` - Time-in-zone analysis
- `LapAggregator` - Per-lap statistics

#### Enhanced Data Store

- Store both raw and reduced versions
- Lazy reduction on first access
- Cache reduced versions

#### LLM Context Builder

- Structured analysis summary (not raw data)
- Available data references with dataIds
- Reduction metadata (point count, algorithm used)

## Files Currently Involved

| File                                           | Current Role        | Needed Changes                 |
| ---------------------------------------------- | ------------------- | ------------------------------ |
| `lib/src/agentic/widgets/chat_interface.dart`  | Builds data context | Enhanced context with analysis |
| `lib/src/agentic/tools/create_chart_tool.dart` | Creates charts      | Add dataId/dataColumn schema   |
| `lib/src/agentic/tools/load_data_tool.dart`    | Loads FIT files     | Trigger data pipeline          |
| `lib/src/agentic/tools/data_store.dart`        | Stores DataFrames   | Store reduced versions         |
| `lib/src/agentic/models/series_config.dart`    | Has dataId field    | Already supports it (unused)   |
| `example/lib/demos/agentic_chart_demo.dart`    | Demo app            | Register new tools             |

## Dependencies

- `braven_data` package - FIT file parsing (already used)
- LTTB algorithm implementation (needs to be added or imported)
- Power zone definitions (need athlete FTP input or estimation)
- Heart rate zone definitions (need athlete max HR or LTHR)

## Acceptance Criteria

1. User imports 50+ hour FIT file
2. Within 5 seconds, LLM receives structured analysis summary
3. LLM can create meaningful power/HR charts without raw data access
4. Charts render with ~1000-2000 points (LTTB reduced)
5. Analysis queries (peaks, zones, laps) return accurate results
6. Memory usage stays reasonable (<100MB for largest files)

## Risk Assessment

| Risk                               | Likelihood | Impact | Mitigation                            |
| ---------------------------------- | ---------- | ------ | ------------------------------------- |
| LTTB loses important features      | Medium     | High   | Preserve peaks separately             |
| Zone calculation wrong without FTP | High       | Medium | Provide default zones, allow override |
| Memory issues with huge files      | Medium     | High   | Stream processing, lazy loading       |
| LLM misunderstands reduced data    | Low        | Medium | Clear documentation in context        |

## Related Work

- FIT file parsing already works via `braven_data`
- `SeriesConfig.dataId` field exists but is unused
- `DescribeDataTool` provides basic metadata (could be enhanced)

## Notes

This is a blessing in disguise - forcing us to design a proper data pipeline rather than naively passing massive datasets. The resulting architecture will be more performant, cost-effective, and provide better analysis capabilities.

The current summary approach (column stats only) is a reasonable fallback - it at least tells the LLM what data is available even if it can't access it directly.
