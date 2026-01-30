# Data Model: Agentic Charts

## Core Entities

### 1. Agent Session

**Description**: Represents an active chat session with chart state.

```dart
class AgentSession {
  final String id;
  final DateTime createdAt;
  final LLMProvider provider;
  final List<Message> conversationHistory;
  final Map<String, LoadedData> dataStore;
  final Map<String, ChartState> chartStore;
  final AgentContext context;
}
```

**Fields**:

- `id`: UUID session identifier
- `createdAt`: Session start timestamp
- `provider`: The LLM backend being used
- `conversationHistory`: Full message history for context
- `dataStore`: Loaded data files/URLs keyed by reference ID
- `chartStore`: Created charts keyed by chart ID
- `context`: Session-wide context (athlete, defaults, etc.)

---

### 2. Loaded Data

**Description**: Represents data loaded from any source, ready for processing.

```dart
class LoadedData {
  final String id;
  final DataSource source;
  final DataFrame data;
  final DataMeta meta;
  final DateTime loadedAt;
}

enum DataSourceType { fit, csv, json, url, inline }

class DataSource {
  final DataSourceType type;
  final String? path;        // For file sources
  final String? url;         // For URL sources
  final String? rawContent;  // For inline sources
}

class DataMeta {
  final int rowCount;
  final List<String> columnNames;
  final Map<String, DataType> columnTypes;
  final DateTimeRange? timeRange;  // For time-series data
}
```

---

### 3. Chart State

**Description**: Complete state of a created chart.

```dart
class ChartState {
  final String id;
  final String? title;
  final ChartType type;
  final List<SeriesState> series;
  final XAxisState xAxis;
  final List<YAxisState> yAxes;
  final ChartStyleState style;
  final InteractionState interactions;
  final List<AnnotationState> annotations;
  final DateTime createdAt;
  final DateTime modifiedAt;
}
```

---

### 4. Series State

**Description**: State of a single data series within a chart.

```dart
class SeriesState {
  final String id;
  final String name;
  final String? dataRef;         // Reference to LoadedData
  final String? column;          // Column name in data
  final List<ChartDataPoint>? explicitData;  // Or explicit points
  final SeriesStyle style;
  final SeriesVisualConfig visual;
}

class SeriesVisualConfig {
  final Color color;
  final double strokeWidth;
  final List<double>? dashPattern;
  final double fillOpacity;
  final MarkerStyle markerStyle;
  final double markerSize;
  final LineInterpolation interpolation;
  final bool showPoints;
  final bool visible;
  final bool legendVisible;
}

enum MarkerStyle { none, circle, square, triangle, diamond }
```

---

### 5. Axis State

**Description**: State of X or Y axis.

```dart
class XAxisState {
  final String? label;
  final String? unit;
  final AxisType type;           // numeric, time, category
  final AxisRangeState range;
  final AxisTickState ticks;
  final AxisAppearanceState appearance;
}

class YAxisState {
  final String id;               // For multi-axis reference
  final String? label;
  final String? unit;
  final YAxisPosition position;
  final AxisRangeState range;
  final AxisTickState ticks;
  final AxisAppearanceState appearance;
  final Color? color;            // Axis-specific color
}

class AxisRangeState {
  final double? min;
  final double? max;
  final bool autoRange;
  final bool includeZero;
  final double paddingPercent;
}

class AxisTickState {
  final int? tickCount;
  final String? format;
  final bool showTicks;
  final double rotation;
}

class AxisAppearanceState {
  final bool showAxisLine;
  final bool showGridLines;
  final Color? gridColor;
  final List<double>? gridDash;
}

enum AxisType { numeric, time, category }
```

---

### 6. Annotation State

**Description**: Visual annotations overlaid on the chart.

```dart
sealed class AnnotationState {
  final String id;
  final String? label;
  final Color color;
  final double strokeWidth;
  final List<double>? dashPattern;
}

class HorizontalLineAnnotation extends AnnotationState {
  final double yValue;
  final LabelPosition labelPosition;
  final bool showValue;
}

class VerticalLineAnnotation extends AnnotationState {
  final double xValue;
  final LabelPosition labelPosition;
  final bool showValue;
}

class RegionAnnotation extends AnnotationState {
  final double xStart;
  final double xEnd;
  final double? yStart;
  final double? yEnd;
  final Color fillColor;
  final double fillOpacity;
}

class PointMarkerAnnotation extends AnnotationState {
  final double x;
  final double y;
  final MarkerStyle style;
  final double size;
}

class TextLabelAnnotation extends AnnotationState {
  final double x;
  final double y;
  final String text;
  final TextAnchor anchor;
  final double fontSize;
}

enum LabelPosition { start, center, end }
enum TextAnchor { topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight }
```

---

### 7. Agent Context

**Description**: Contextual information that influences chart generation.

```dart
class AgentContext {
  final AthleteProfile? athlete;
  final TrainingZones? trainingZones;
  final ChartDefaults? chartDefaults;
  final UnitPreferences? units;
  final Map<String, dynamic> custom;
}

class AthleteProfile {
  final String name;
  final int? ftp;              // Functional Threshold Power
  final int? lthr;             // Lactate Threshold Heart Rate
  final int? maxHr;
  final double? weightKg;
}

class TrainingZones {
  final List<Zone> powerZones;
  final List<Zone> heartRateZones;
}

class Zone {
  final String name;
  final double minPercent;     // As fraction of threshold
  final double? maxPercent;
  final Color color;
}

class ChartDefaults {
  final ThemeMode theme;
  final Color powerColor;
  final Color heartRateColor;
  final Color cadenceColor;
  final Color speedColor;
  final List<Color> colorPalette;
}

class UnitPreferences {
  final String power;          // "W"
  final String speed;          // "km/h" or "mph"
  final String distance;       // "km" or "mi"
  final String temperature;    // "celsius" or "fahrenheit"
}
```

---

## LLM Communication Entities

### 8. Message Types

```dart
sealed class Message {
  final String id;
  final DateTime timestamp;
}

class UserMessage extends Message {
  final String content;
  final List<Attachment> attachments;
}

class AssistantMessage extends Message {
  final String? content;
  final List<ToolUse> toolUses;
}

class ToolResultMessage extends Message {
  final String toolUseId;
  final dynamic result;
  final bool isError;
}
```

### 9. Attachments

```dart
sealed class Attachment {
  final String id;
  final String filename;
  final int sizeBytes;
}

class FileAttachment extends Attachment {
  final Uint8List content;
  final String mimeType;       // e.g., "application/octet-stream" for FIT
}

class UrlAttachment extends Attachment {
  final String url;
}

class ContextAttachment extends Attachment {
  final String contextId;      // Reference to loaded context
}
```

---

### 10. Tool Definitions

```dart
class Tool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
}

class ToolUse {
  final String id;
  final String name;
  final Map<String, dynamic> input;
}

class ToolResult {
  final String toolUseId;
  final dynamic output;
  final String? error;
}
```

---

## Data Processing Entities

### 11. Data Operations

```dart
sealed class DataOperation {
  DataOperation apply(DataFrame input);
}

class SelectColumnsOp extends DataOperation {
  final List<String> columns;
}

class FilterOp extends DataOperation {
  final String column;
  final FilterOperator operator;
  final dynamic value;
}

class RollingWindowOp extends DataOperation {
  final int windowSeconds;
  final Reducer reducer;
}

class FixedWindowOp extends DataOperation {
  final int windowSeconds;
  final Reducer reducer;
}

class ResampleOp extends DataOperation {
  final int intervalSeconds;
  final ResampleMethod method;
}

class NormalizeOp extends DataOperation {
  final NormalizeMethod method;
}

class SmoothOp extends DataOperation {
  final SmoothMethod method;
  final int window;
}

class ClipOp extends DataOperation {
  final double? min;
  final double? max;
}

class FillMissingOp extends DataOperation {
  final FillMethod method;
  final double? value;
}

enum FilterOperator { eq, ne, gt, gte, lt, lte, between, isNull, isNotNull }
enum Reducer { mean, max, min, sum, count, first, last, median }
enum ResampleMethod { interpolate, last, mean }
enum NormalizeMethod { minMax, zScore }
enum SmoothMethod { sma, ema }
enum FillMethod { interpolate, forward, backward, value }
```

---

### 12. Metric Calculations

```dart
sealed class MetricCalculation {
  double calculate(Series<double, double> data, MetricContext? context);
}

class NormalizedPowerMetric extends MetricCalculation {
  // NP = (mean(30s_rolling^4))^0.25
}

class IntensityFactorMetric extends MetricCalculation {
  // IF = NP / FTP (requires FTP in context)
}

class TrainingStressMetric extends MetricCalculation {
  // TSS = (duration * NP * IF) / (FTP * 3600) * 100
}

class VariabilityIndexMetric extends MetricCalculation {
  // VI = NP / Average Power
}

class EfficiencyFactorMetric extends MetricCalculation {
  // EF = NP / Average HR (requires HR series)
}

class PercentileMetric extends MetricCalculation {
  final double percentile;  // 0-100
}

class MetricContext {
  final int? ftp;
  final int? lthr;
  final Series<double, double>? hrSeries;
}
```

---

## Validation Rules

1. **Session Integrity**: Session ID must be UUID v4 format.
2. **Data References**: All `dataRef` values must exist in `dataStore`.
3. **Chart References**: All chart IDs in modifications must exist in `chartStore`.
4. **Axis Binding**: Series `yAxisId` must reference existing Y-axis.
5. **Color Format**: Colors must be valid hex (#RRGGBB or #AARRGGBB) or named colors.
6. **Range Validity**: If specified, `min` must be less than `max`.
7. **Percentage Bounds**: Values like `fillOpacity`, `paddingPercent` must be 0-1.
8. **Time Continuity**: Time-series X values should be monotonically increasing.
9. **FTP Required**: IF and TSS calculations require FTP in context.
10. **Column Existence**: Referenced columns must exist in data source.

---

## State Transitions

```
[Empty Session]
      │
      ▼  load_data / attach file
[Session with Data]
      │
      ▼  create_chart
[Session with Chart]
      │
      ├──▶ modify_chart ──▶ [Updated Chart]
      │
      ├──▶ add_annotation ──▶ [Chart with Annotations]
      │
      ├──▶ create_chart ──▶ [Multiple Charts]
      │
      └──▶ create_dashboard ──▶ [Dashboard Layout]
```

---

## Serialization

All entities support JSON serialization for:

- Persistence (save/load sessions)
- LLM communication (tool inputs/outputs)
- Export (chart configurations)
- Debugging (state inspection)

```dart
abstract class Serializable {
  Map<String, dynamic> toJson();
  static T fromJson<T>(Map<String, dynamic> json);
}
```
