# Data Model: Agentic Charts

**Feature**: 003-agentic-charts  
**Date**: 2026-01-25  
**Status**: Complete

## Core Entities

### 1. Conversation

The chat session between user and AI agent.

```dart
class Conversation {
  final String id;
  final List<Message> messages;
  final DateTime createdAt;
  final Map<String, LoadedData> dataStore;  // UUID → data
  final Map<String, ChartState> charts;     // chartId → state

  // Token tracking
  int totalInputTokens;
  int totalOutputTokens;
  double? estimatedCostUsd;
}
```

**Relationships**:

- 1:N with `Message`
- 1:N with `LoadedData` (via dataStore)
- 1:N with `ChartState` (via charts)

**Validation Rules**:

- `id` is UUID v4
- `messages` ordered by timestamp ascending
- Token counts ≥ 0

---

### 2. Message

A single chat message (user or assistant).

```dart
class Message {
  final String id;
  final MessageRole role;           // user | assistant | system
  final String? textContent;
  final List<ToolCall>? toolCalls;  // For assistant messages
  final List<ToolResult>? toolResults; // For tool responses
  final List<FileAttachment>? attachments; // For user messages
  final DateTime timestamp;
}

enum MessageRole { user, assistant, system }
```

**Relationships**:

- N:1 with `Conversation`
- 1:N with `ToolCall` (optional)
- 1:N with `FileAttachment` (optional)

**Validation Rules**:

- Either `textContent` or `toolCalls` must be present
- `attachments` only valid for `role == user`

---

### 3. ToolCall

An LLM tool invocation request.

```dart
class ToolCall {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolResult? result;
}
```

**Validation Rules**:

- `toolName` must match registered tool
- `arguments` validated against tool schema

---

### 4. LoadedData

Data loaded from a file, URL, or inline source. When loaded from a file, this represents a **Workout File** as defined in spec.md (FIT, CSV, or TCX containing time-series activity data).

```dart
class LoadedData {
  final String id;              // UUID reference
  final DataSourceType type;    // file | url | inline
  final String? fileName;
  final String? fileType;       // fit | csv | tcx (workout file formats)
  final int rowCount;
  final List<ColumnDescriptor> columns;
  final List<Map<String, dynamic>> data;  // Actual data rows
  final TimeRange? timeRange;   // For time-series data
  final DateTime loadedAt;
}

enum DataSourceType { file, url, inline }

class ColumnDescriptor {
  final String name;
  final ColumnType type;        // number | string | datetime | boolean
  final bool nullable;
  final ColumnStats? stats;     // min, max, mean, nullCount
  final List<dynamic> sampleValues;
}

class TimeRange {
  final DateTime start;
  final DateTime end;
  final int durationSeconds;
}
```

**Validation Rules**:

- `id` is UUID v4
- `columns.length > 0`
- `rowCount == data.length`

---

### 5. ChartState

The complete state of a rendered chart.

```dart
class ChartState {
  final String id;
  final String? name;           // User-visible name
  final ChartConfiguration config;
  final List<ChartConfiguration> undoStack;  // Max 20
  final List<ChartConfiguration> redoStack;
  final List<Message> inlineChat;  // Inline chat history
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime modifiedAt;
}
```

**State Transitions**:

- `created` → `modified` (on config change)
- Any state → `favorited` (toggle)

**Validation Rules**:

- `undoStack.length ≤ 20`
- `config` never null

---

### 6. ChartConfiguration

Complete chart configuration for rendering.

```dart
class ChartConfiguration {
  final ChartType type;
  final String? title;
  final String? subtitle;
  final List<SeriesConfig> series;
  final XAxisConfig? xAxis;
  final List<YAxisConfig> yAxes;    // Max 4
  final ChartStyleConfig? style;
  final InteractionConfig? interactions;
  final List<AnnotationConfig>? annotations;
  final LayoutConfig? layout;
}

enum ChartType { line, area, bar, scatter }  // V1 core types only; candlestick, heatmap aspirational for future
```

**Validation Rules**:

- `series.length > 0`
- `yAxes.length ≤ 4`
- `type` in supported types for V1: line, area, bar, scatter

---

### 7. SeriesConfig

Configuration for a single data series.

**AMENDMENT (2026-01-25)**: Added type-discriminated properties for bar, scatter, line, and area charts. These properties are optional at the SeriesConfig level but are applied with sensible defaults when rendering to concrete ChartSeries subclasses.

```dart
class SeriesConfig {
  final String id;
  final String? name;
  final String? dataColumn;       // Column from LoadedData
  final String? dataId;           // Reference to LoadedData
  final List<DataPoint>? data;    // Or explicit data points

  // Styling (common to all types)
  final String? color;
  final double strokeWidth;
  final List<double>? strokeDash;
  final double fillOpacity;
  final MarkerStyle markerStyle;
  final double markerSize;

  // Line/Area options
  final Interpolation interpolation;
  final bool showPoints;
  final double tension;                    // Bezier curve smoothing (0.0-1.0, default 0.25)
  final double dataPointMarkerRadius;      // Marker size when showPoints=true (default 3.0)

  // Bar chart options (REQUIRED for bar charts - one must be set)
  final double? barWidthPercent;           // 0.0-1.0, percentage of available space (default 0.7)
  final double? barWidthPixels;            // Fixed width in pixels (alternative to percent)
  final double barMinWidth;                // Minimum bar width (default 4.0)
  final double barMaxWidth;                // Maximum bar width (default 100.0)

  // Scatter chart options
  final double markerRadius;               // Scatter point radius (default 5.0)

  // Axis binding
  final String? yAxisId;
  final String? unit;

  // Visibility
  final bool visible;
  final bool legendVisible;
}

enum MarkerStyle { none, circle, square, triangle, diamond }
enum Interpolation { linear, bezier, stepped, monotone }
```

**Type-Specific Defaults**:

| Chart Type | Required Properties | Defaults Applied |
|------------|---------------------|------------------|
| `line` | none | `tension: 0.25`, `strokeWidth: 2.0` |
| `area` | none | `tension: 0.25`, `fillOpacity: 0.3` |
| `bar` | `barWidthPercent` OR `barWidthPixels` | `barWidthPercent: 0.7` if neither set |
| `scatter` | none | `markerRadius: 5.0` |

---

### 8. XAxisConfig / YAxisConfig

Axis configuration.

```dart
class XAxisConfig {
  final String? label;
  final String? unit;
  final AxisType type;           // numeric | time | category
  final double? min;
  final double? max;
  final bool autoRange;
  final double paddingPercent;
  final int? tickCount;
  final String? tickFormat;
  final double tickRotation;
  final bool showTicks;
  final bool showAxisLine;
  final bool showGridLines;
  final String? gridColor;
  final List<double>? gridDash;
}

class YAxisConfig {
  final String? id;              // For multi-axis reference
  final String? label;
  final String? unit;
  final AxisPosition position;   // left | right
  final double? min;
  final double? max;
  final bool autoRange;
  final bool includeZero;
  final double paddingPercent;
  final int? tickCount;
  final String? tickFormat;
  final bool showTicks;
  final bool showAxisLine;
  final bool showGridLines;
  final String? gridColor;
  final String? color;           // Axis color
}

enum AxisType { numeric, time, category }
enum AxisPosition { left, right }
```

---

### 9. AnnotationConfig

Chart annotation (reference lines, zones, labels).

```dart
class AnnotationConfig {
  final AnnotationType type;
  final double? yValue;          // horizontal_line
  final double? xValue;          // vertical_line
  final double? xStart;          // region
  final double? xEnd;
  final double? yStart;
  final double? yEnd;
  final String? color;
  final double strokeWidth;
  final List<double>? dash;
  final String? fillColor;
  final double fillOpacity;
  final String? label;
  final LabelPosition labelPosition;
  final bool showValue;
}

enum AnnotationType {
  horizontalLine,
  verticalLine,
  region,
  pointMarker,
  textLabel
}

enum LabelPosition { start, center, end }
```

---

### 10. FileAttachment

A file attached to a user message.

```dart
class FileAttachment {
  final String id;
  final String fileName;
  final String fileType;         // fit | csv | json | yaml
  final int fileSizeBytes;
  final Uint8List content;       // Raw bytes
  final FileStatus status;       // pending | parsing | ready | error
  final String? dataId;          // Reference to LoadedData after parsing
  final String? errorMessage;
}

enum FileStatus { pending, parsing, ready, error }
```

**Validation Rules**:

- `fileSizeBytes ≤ 52428800` (50 MB)
- `fileType` in allowed extensions
- `fileName` sanitized (no path traversal)

---

### 11. Metric

A computed scalar value.

```dart
class Metric {
  final MetricType type;
  final String? column;          // Source column (e.g., 'power')
  final double value;
  final String? unit;
  final String? formattedValue;  // e.g., "256 W"
  final Map<String, dynamic>? context;  // FTP, percentile, etc.
}

enum MetricType {
  normalizedPower,
  intensityFactor,
  trainingStressScore,
  variabilityIndex,
  efficiencyFactor,
  mean,
  max,
  min,
  stdev,
  percentile,
}
```

---

### 12. PromptTemplate

Pre-built prompt for common analyses.

```dart
class PromptTemplate {
  final String id;
  final String name;
  final String icon;             // Emoji
  final String prompt;           // Full prompt text
  final List<String>? requiredColumns;  // power, heart_rate, etc.
  final TemplateCategory category;
}

enum TemplateCategory { cycling, running, swimming, general }
```

**V1 Scope**: Read-only templates only.

---

## Entity Relationship Diagram

```
┌─────────────────┐     1:N     ┌─────────────────┐
│  Conversation   │────────────▶│     Message     │
└─────────────────┘             └─────────────────┘
        │                               │
        │ 1:N                           │ 1:N (optional)
        ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│   LoadedData    │             │  FileAttachment │
└─────────────────┘             └─────────────────┘
        │                               │
        │ 1:N                           │ refs
        ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│ColumnDescriptor│             │   LoadedData    │
└─────────────────┘             └─────────────────┘

┌─────────────────┐     1:N     ┌─────────────────┐
│  Conversation   │────────────▶│   ChartState    │
└─────────────────┘             └─────────────────┘
                                        │
                                        │ 1:1
                                        ▼
                                ┌─────────────────┐
                                │ChartConfiguration│
                                └─────────────────┘
                                        │
                                        │ 1:N
                                        ▼
                                ┌─────────────────┐
                                │  SeriesConfig   │
                                └─────────────────┘
```

---

## State Transitions

### FileAttachment Lifecycle

```
pending → parsing → ready
                ↘ error
```

### ChartState Lifecycle

```
created → modified (repeatable)
    ↓
favorited (toggle)
```

### Message Flow

```
user_input → assistant_thinking → tool_calls → tool_results → assistant_response
```

---

## Validation Summary

| Entity             | Key Constraints             |
| ------------------ | --------------------------- |
| Conversation       | Token limits warn at 80%    |
| LoadedData         | 50 MB max, columns required |
| ChartState         | 20 undo steps max           |
| ChartConfiguration | 4 Y-axes max                |
| FileAttachment     | Allowed extensions only     |
| SeriesConfig       | Valid yAxisId reference     |
