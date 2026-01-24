# Feature Specification: Agentic Charts - AI-Powered Chart Generation

**Feature Branch**: `003-agentic-charts`  
**Created**: 2026-01-24  
**Status**: Draft  
**Input**: POC validated in `poc-agentic-charts` branch - chat-based chart generation working with Claude API

## Executive Summary

Enable AI agents (LLMs) to have **full programmatic control** over BravenChartPlus chart creation, configuration, and data processing. The system allows users to describe data visualizations in natural language, attach data files (FIT, CSV, JSON), provide URLs, or reference context—and receive fully interactive, professionally styled charts.

**Primary Use Case**: Sport science laboratory workflows where athletes' performance data (power, heart rate, cadence, speed) from devices like Garmin needs to be analyzed and visualized through conversational interfaces.

---

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Natural Language Chart Creation (Priority: P0)

A sport scientist wants to quickly visualize an athlete's training data by simply describing what they want to see, without writing any code.

**Why this priority**: Core value proposition - democratizes data visualization.

**Acceptance Scenarios**:

1. **Given** a user prompt "Show me a line chart of temperature over time", **When** processed by the agent, **Then** a valid line chart is rendered with appropriate axes and styling.
2. **Given** a prompt with styling requirements "Create a blue area chart with grid lines hidden", **When** processed, **Then** the chart reflects the exact styling specified.
3. **Given** ambiguous data (e.g., multiple possible Y-axis candidates), **When** the agent processes the request, **Then** it asks clarifying questions or makes intelligent defaults with explanation.

---

### User Story 2 - FIT File Power Analysis (Priority: P0)

A sport scientist needs to analyze an athlete's cycling power data from a Garmin FIT file, applying 30-second rolling averages and creating a line chart for the training session.

**Why this priority**: Core sport science use case - validates the complete data pipeline from file → processing → visualization.

**Acceptance Scenarios**:

1. **Given** a FIT file attachment from "Athlete Joe Soap", **When** user prompts "Extract power data and show 30s rolling averages", **Then**:
   - FIT file is parsed using `braven_data.FitLoader`
   - Power column is extracted
   - 30-second rolling window mean is applied
   - Line chart is rendered with time on X-axis, power (W) on Y-axis
2. **Given** a FIT file with multiple metrics, **When** user prompts "Compare power and heart rate", **Then** a multi-axis chart is created with power on left Y-axis and HR on right Y-axis.
3. **Given** a FIT file, **When** user prompts "Show power distribution bands at 20W intervals", **Then** the distribution calculator is invoked and a bar chart is rendered.

---

### User Story 3 - Full Chart Property Control (Priority: P0)

A developer embedding agentic charts needs the LLM to have complete control over all chart properties, styling, axes, interactions, and annotations.

**Why this priority**: Essential for production use - partial control is unusable.

**Acceptance Scenarios**:

1. **Given** a chart creation request, **When** specifying any combination of properties, **Then** ALL of the following are configurable:
   - Chart type (line, area, bar, scatter, candlestick, heatmap)
   - Series styling (color, stroke width, markers, fill opacity, dash patterns)
   - Line interpolation (linear, bezier, stepped, monotone)
   - X-axis (label, unit, range, tick format, time vs numeric)
   - Y-axis (label, unit, range, position, multiple axes)
   - Grid (show/hide, colors, dash patterns)
   - Legend (show/hide, position, style)
   - Interactions (pan, zoom, crosshair, tooltip, selection)
   - Annotations (horizontal lines, vertical lines, regions, markers, labels)
2. **Given** an existing chart, **When** user prompts "Change the line color to red and add a horizontal line at 200W", **Then** the chart is modified in-place without recreating.
3. **Given** incomplete styling, **When** processed, **Then** intelligent defaults are applied that respect the current theme.

---

### User Story 4 - Data Context & Sources (Priority: P1)

A user needs to provide data from multiple sources: file attachments, URLs, inline data, or referenced context files.

**Why this priority**: Real-world data comes from diverse sources.

**Acceptance Scenarios**:

1. **Given** a CSV file attachment, **When** user prompts "Chart the power column", **Then** CSV is parsed and charted.
2. **Given** a URL to a JSON API endpoint, **When** user prompts "Fetch and chart the temperature readings", **Then** data is fetched, parsed, and charted.
3. **Given** inline data in the prompt "Chart this: [1,2,3,4,5]", **When** processed, **Then** the inline data is used.
4. **Given** a context file reference "Use the athlete_context.json for defaults", **When** processing chart requests, **Then** the context (athlete name, preferred colors, thresholds) is applied.
5. **Given** a large dataset (>100k points), **When** charted, **Then** automatic downsampling is applied for performance.

---

### User Story 5 - Sport Science Metrics & Calculations (Priority: P1)

A sport scientist needs domain-specific calculations applied to the data before visualization.

**Why this priority**: Differentiating feature for sport science lab use case.

**Acceptance Scenarios**:

1. **Given** power data, **When** user prompts "Calculate and display Normalized Power (NP)", **Then** the NP algorithm (30s rolling mean → power(4) → average → root(4)) is applied and the scalar value is displayed.
2. **Given** power data, **When** user prompts "Show 30-second rolling average", **Then** a rolling window mean is applied.
3. **Given** power data, **When** user prompts "Show peak 1-minute power intervals", **Then** fixed 1-minute windows with max reducer are applied.
4. **Given** heart rate data over a long ride, **When** user prompts "Show HR drift (5-min averages)", **Then** fixed 5-minute windows with mean are applied.
5. **Given** a training session, **When** user prompts "Overlay training zones", **Then** horizontal annotations are added at zone thresholds (Z1-Z5).

---

### User Story 6 - Multi-Chart & Comparison Views (Priority: P2)

A user needs to create dashboard-style layouts with multiple synchronized charts.

**Why this priority**: Common requirement for comprehensive analysis.

**Acceptance Scenarios**:

1. **Given** a request "Show power, heart rate, and cadence in separate charts, synchronized", **When** processed, **Then** three vertically stacked charts are created with linked X-axes.
2. **Given** two FIT files from different sessions, **When** user prompts "Compare these two rides", **Then** overlay or side-by-side charts are created.
3. **Given** an existing multi-chart layout, **When** user prompts "Add speed to the bottom", **Then** a new chart is appended without disrupting existing charts.

---

### User Story 7 - Chart Export & Persistence (Priority: P2)

A user needs to export charts as images or save configurations for later use.

**Why this priority**: Essential for reporting and reproducibility.

**Acceptance Scenarios**:

1. **Given** a rendered chart, **When** user prompts "Export as PNG", **Then** a high-resolution PNG is generated.
2. **Given** a chart configuration, **When** user prompts "Save this chart template", **Then** the JSON configuration is persisted.
3. **Given** a saved template, **When** user prompts "Apply template 'weekly_power_analysis' to this file", **Then** the template is applied to new data.

---

## Functional Requirements

### 1. LLM Tool Schema (Expanded)

#### 1.1 Core Tools

| Tool               | Purpose                                | Status       |
| ------------------ | -------------------------------------- | ------------ |
| `create_chart`     | Create a new chart from data           | POC Complete |
| `modify_chart`     | Modify an existing chart               | POC Partial  |
| `explain_data`     | Analyze and describe data              | POC Complete |
| `load_data`        | Load data from file/URL/inline         | NEW          |
| `process_data`     | Apply transformations to data          | NEW          |
| `calculate_metric` | Compute scalar metrics (NP, TSS, etc.) | NEW          |
| `add_annotation`   | Add annotations to chart               | NEW          |
| `export_chart`     | Export chart as image/JSON             | NEW          |
| `create_dashboard` | Create multi-chart layout              | NEW          |

#### 1.2 Full Property Schema

```typescript
interface CreateChartInput {
  // Data Source (one of)
  data_source?: {
    type: "inline" | "file" | "url" | "reference";
    content?: DataPoint[]; // For inline
    file_id?: string; // For file (returned by load_data)
    url?: string; // For URL
    reference_id?: string; // For previously loaded data
  };

  // Chart Configuration
  chart_type: "line" | "area" | "bar" | "scatter" | "candlestick" | "heatmap";
  title?: string;
  subtitle?: string;

  // Series (can override data_source per series)
  series: SeriesConfig[];

  // Axes
  x_axis?: XAxisConfig;
  y_axes?: YAxisConfig[]; // Support multiple Y-axes

  // Styling
  style?: ChartStyleConfig;

  // Interactions
  interactions?: InteractionConfig;

  // Annotations
  annotations?: AnnotationConfig[];

  // Layout
  layout?: LayoutConfig;
}

interface SeriesConfig {
  id: string;
  name?: string;
  data_column?: string; // Column name from data source
  data?: DataPoint[]; // Or explicit data

  // Series Type Override
  type?: "line" | "area" | "bar" | "scatter";

  // Styling
  color?: string; // Hex or named color
  stroke_width?: number; // 1-10
  stroke_dash?: number[]; // e.g., [5, 3] for dashed
  fill_opacity?: number; // 0-1 for area charts
  marker_style?: "none" | "circle" | "square" | "triangle" | "diamond";
  marker_size?: number;

  // Line specific
  interpolation?: "linear" | "bezier" | "stepped" | "monotone";
  show_points?: boolean;

  // Bar specific
  bar_width_percent?: number; // 0-1
  bar_corner_radius?: number;

  // Y-Axis binding
  y_axis_id?: string; // For multi-axis
  unit?: string;

  // Visibility
  visible?: boolean;
  legend_visible?: boolean;
}

interface XAxisConfig {
  label?: string;
  unit?: string;
  type?: "numeric" | "time" | "category";

  // Range
  min?: number;
  max?: number;
  auto_range?: boolean;
  padding_percent?: number;

  // Ticks
  tick_count?: number;
  tick_format?: string; // e.g., "HH:mm:ss" for time
  show_ticks?: boolean;
  tick_rotation?: number; // Degrees

  // Appearance
  show_axis_line?: boolean;
  show_grid_lines?: boolean;
  grid_color?: string;
  grid_dash?: number[];
}

interface YAxisConfig {
  id?: string; // For multi-axis reference
  label?: string;
  unit?: string;
  position?: "left" | "right";

  // Range
  min?: number;
  max?: number;
  auto_range?: boolean;
  include_zero?: boolean;
  padding_percent?: number;

  // Ticks
  tick_count?: number;
  tick_format?: string;
  show_ticks?: boolean;

  // Appearance
  color?: string; // Axis and tick color
  show_axis_line?: boolean;
  show_grid_lines?: boolean;
  grid_color?: string;
}

interface ChartStyleConfig {
  // Background
  background_color?: string;

  // Grid
  show_grid?: boolean;
  grid_color?: string;
  grid_opacity?: number;
  grid_dash?: number[];

  // Legend
  show_legend?: boolean;
  legend_position?: "top" | "bottom" | "left" | "right" | "floating";
  legend_orientation?: "horizontal" | "vertical";

  // Padding
  padding_top?: number;
  padding_bottom?: number;
  padding_left?: number;
  padding_right?: number;

  // Size
  width?: number;
  height?: number;
  aspect_ratio?: number;

  // Theme
  theme?: "light" | "dark" | "auto";
  color_palette?: string[]; // Custom color sequence for series
}

interface InteractionConfig {
  // Pan & Zoom
  enable_pan?: boolean;
  pan_direction?: "horizontal" | "vertical" | "both";
  enable_zoom?: boolean;
  zoom_direction?: "horizontal" | "vertical" | "both";
  min_zoom?: number;
  max_zoom?: number;

  // Crosshair
  show_crosshair?: boolean;
  crosshair_style?: "full" | "horizontal" | "vertical";
  crosshair_snap_to_data?: boolean;

  // Tooltip
  show_tooltip?: boolean;
  tooltip_format?: string;

  // Selection
  enable_selection?: boolean;
  selection_mode?: "point" | "range" | "multi";

  // Animation
  animate_on_load?: boolean;
  animation_duration_ms?: number;
}

interface AnnotationConfig {
  type:
    | "horizontal_line"
    | "vertical_line"
    | "region"
    | "point_marker"
    | "text_label";

  // Position (depends on type)
  y_value?: number; // For horizontal_line
  x_value?: number; // For vertical_line
  x_start?: number; // For region
  x_end?: number;
  y_start?: number;
  y_end?: number;

  // Appearance
  color?: string;
  stroke_width?: number;
  dash?: number[];
  fill_color?: string; // For region
  fill_opacity?: number;

  // Label
  label?: string;
  label_position?: "start" | "center" | "end";
  show_value?: boolean;
}
```

### 2. Data Loading & Processing

#### 2.1 Supported Data Sources

| Source Type   | Format                     | Implementation           |
| ------------- | -------------------------- | ------------------------ |
| FIT Files     | Binary Garmin format       | `braven_data.FitLoader`  |
| CSV Files     | Comma-separated values     | `braven_data.CsvLoader`  |
| JSON Files    | JavaScript Object Notation | Native Dart parsing      |
| URLs          | HTTP/HTTPS endpoints       | `http` package + parsers |
| Inline        | Direct in prompt           | JSON parsing             |
| Context Files | Pre-loaded reference data  | Local file system        |

#### 2.2 Data Transformation Tools

```typescript
interface ProcessDataInput {
  data_id: string; // Reference to loaded data

  operations: DataOperation[];
}

type DataOperation =
  | { type: "select_columns"; columns: string[] }
  | { type: "filter"; condition: FilterCondition }
  | {
      type: "rolling_window";
      window_seconds: number;
      reducer: "mean" | "max" | "min" | "sum";
    }
  | {
      type: "fixed_window";
      window_seconds: number;
      reducer: "mean" | "max" | "min" | "sum";
    }
  | {
      type: "resample";
      interval_seconds: number;
      method: "interpolate" | "last" | "mean";
    }
  | { type: "normalize"; method: "min_max" | "z_score" }
  | { type: "derivative"; order: number }
  | { type: "smooth"; method: "sma" | "ema"; window: number }
  | { type: "clip"; min?: number; max?: number }
  | {
      type: "fill_missing";
      method: "interpolate" | "forward" | "backward" | "value";
      value?: number;
    };
```

#### 2.3 Sport Science Metrics

```typescript
interface CalculateMetricInput {
  data_id: string;
  column: string; // e.g., 'power'

  metric:
    | "normalized_power" // NP = (mean(30s_rolling^4))^0.25
    | "intensity_factor" // IF = NP / FTP
    | "training_stress" // TSS = (duration * NP * IF) / (FTP * 3600) * 100
    | "variability_index" // VI = NP / Average Power
    | "efficiency_factor" // EF = NP / Average HR
    | "xpower" // xPower algorithm
    | "mean"
    | "max"
    | "min"
    | "stdev"
    | "percentile";

  // Context for some metrics
  ftp?: number; // Functional Threshold Power (for IF, TSS)
  percentile_value?: number; // For percentile metric (0-100)
}
```

### 3. Context System

#### 3.1 Context File Schema

```yaml
# athlete_context.yaml
athlete:
  name: "Joe Soap"
  ftp: 280 # Functional Threshold Power
  lthr: 165 # Lactate Threshold Heart Rate
  max_hr: 190
  weight_kg: 75

training_zones:
  power:
    - { name: "Recovery", min: 0, max: 0.55, color: "#gray" }
    - { name: "Endurance", min: 0.55, max: 0.75, color: "#blue" }
    - { name: "Tempo", min: 0.75, max: 0.90, color: "#green" }
    - { name: "Threshold", min: 0.90, max: 1.05, color: "#yellow" }
    - { name: "VO2max", min: 1.05, max: 1.20, color: "#orange" }
    - { name: "Anaerobic", min: 1.20, max: null, color: "#red" }

chart_defaults:
  theme: "dark"
  power_color: "#FF6B00"
  hr_color: "#FF0000"
  cadence_color: "#00BFFF"
  speed_color: "#00FF00"

preferred_units:
  power: "W"
  speed: "km/h" # or "mph"
  distance: "km"
  temperature: "celsius"
```

#### 3.2 Context Loading

```typescript
interface LoadContextInput {
  type: "file" | "inline" | "url";
  path?: string; // File path
  content?: object; // Inline YAML/JSON
  url?: string; // Remote context

  scope?: "session" | "chart"; // How long context persists
}
```

### 4. Multi-Chart Dashboards

```typescript
interface CreateDashboardInput {
  title?: string;

  layout: {
    type: "grid" | "vertical" | "horizontal" | "custom";
    columns?: number; // For grid
    rows?: number;
    gap?: number; // Pixels between charts
  };

  charts: DashboardChartConfig[];

  // Synchronization
  sync_x_axes?: boolean; // Link X-axis pan/zoom across charts
  sync_crosshair?: boolean; // Show crosshair on all charts
  shared_legend?: boolean; // Single legend for all charts
}

interface DashboardChartConfig extends CreateChartInput {
  position?: { row: number; col: number; rowSpan?: number; colSpan?: number };
}
```

### 5. Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Chat Interface (UI)                          │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  User Input: Text + Attachments + Context References        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ChartAgentInterface                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Context    │  │ Tool Schema │  │ LLM Client (Pluggable)  │  │
│  │  Manager    │  │ Registry    │  │ - Anthropic             │  │
│  │             │  │             │  │ - OpenAI                │  │
│  │ - Athlete   │  │ - Charts    │  │ - Gemini                │  │
│  │ - Session   │  │ - Data      │  │ - Local (Ollama)        │  │
│  │ - Files     │  │ - Metrics   │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Tool Execution Layer                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DataLoader          │  ChartBuilder   │  MetricCalc     │   │
│  │  - FitLoader         │  - Series       │  - NP           │   │
│  │  - CsvLoader         │  - Axes         │  - TSS          │   │
│  │  - JsonParser        │  - Annotations  │  - IF           │   │
│  │  - UrlFetcher        │  - Style        │  - Custom       │   │
│  └──────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BravenChartPlus Widget                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │   [Interactive Chart with Full Feature Set]              │   │
│  │                                                          │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Criteria

1. **Completeness**: All BravenChartPlus chart properties are controllable via LLM tools.
2. **Sport Science**: FIT file → 30s rolling power chart works end-to-end in <5 seconds.
3. **Accuracy**: Metric calculations (NP, IF, TSS) match verified formulas to 0.1% tolerance.
4. **Multi-LLM**: Works with Anthropic Claude, OpenAI GPT-4, and Google Gemini.
5. **Performance**: Charts with 100k+ points render at 60 FPS with automatic downsampling.
6. **Extensibility**: Custom metrics and chart types can be added without core changes.

---

## Technical Decisions

### TD-1: LLM Provider Abstraction

**Decision**: Create `LLMProvider` interface supporting multiple backends.

**Rationale**: Avoid vendor lock-in; allow local models for privacy.

**Implementation**:

```dart
abstract class LLMProvider {
  Future<LLMResponse> chat(List<Message> messages, List<Tool> tools);
  Stream<LLMStreamEvent> chatStream(List<Message> messages, List<Tool> tools);
}

class AnthropicProvider implements LLMProvider { ... }
class OpenAIProvider implements LLMProvider { ... }
class GeminiProvider implements LLMProvider { ... }
class OllamaProvider implements LLMProvider { ... }  // Local
```

### TD-2: Data Reference System

**Decision**: Use UUID-based data references instead of passing data inline.

**Rationale**:

- Reduces token usage (LLM doesn't need to see all data)
- Enables large dataset handling
- Supports multi-step workflows

**Implementation**:

```dart
class DataStore {
  final Map<String, LoadedData> _store = {};

  String store(LoadedData data) {
    final id = Uuid().v4();
    _store[id] = data;
    return id;
  }

  LoadedData? get(String id) => _store[id];
}
```

### TD-3: Web CORS Handling

**Decision**: Provide multiple CORS solutions for production.

**Options**:

1. Cloudflare Worker proxy (recommended for production)
2. Backend proxy API (for existing backends)
3. `--disable-web-security` (development only)

### TD-4: FIT File Parsing

**Decision**: Use existing `braven_data.FitLoader` for FIT file parsing.

**Rationale**: Already implemented and tested in the data layer.

---

## Assumptions

- **POC Validated**: Basic chat → chart flow works (proven in `poc-agentic-charts`).
- **braven_data Available**: FIT/CSV loading and aggregation pipeline exists.
- **LLM API Keys**: User provides their own API keys (not bundled).
- **Web Primary**: Initial focus on web platform; mobile follows.

---

## Dependencies

| Dependency           | Purpose                      | Status       |
| -------------------- | ---------------------------- | ------------ |
| `anthropic_sdk_dart` | Claude API client            | ✅ Installed |
| `braven_data`        | FIT/CSV parsing, aggregation | ✅ Available |
| `http`               | URL fetching                 | Standard     |
| `uuid`               | Data reference IDs           | Standard     |
| `yaml`               | Context file parsing         | To add       |

---

## Out of Scope (V1)

- Voice input/output
- Real-time streaming data (WebSocket)
- Collaborative editing
- Chart versioning/history
- Native mobile optimizations
- Offline LLM models (local-first)

---

## Clarifications Needed

1. **Q**: Should we support multiple simultaneous chat sessions with separate chart states?
2. **Q**: What's the maximum file size for FIT/CSV uploads in web browsers?
3. **Q**: Should chart templates be shareable between users?
4. **Q**: Do we need audit logging of LLM interactions for compliance?
