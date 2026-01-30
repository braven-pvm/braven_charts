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

A developer embedding agentic charts needs the LLM to have **complete control over ALL chart properties** - no exceptions. Every configurable aspect of BravenChartPlus must be accessible to the agent.

**Why this priority**: Essential for production use - partial control is unusable. "ALL means ALL."

**Acceptance Scenarios**:

1. **Given** a chart creation request, **When** specifying any combination of properties, **Then** ALL of the following are configurable:
   - **Chart Types**: line, area, bar, scatter, candlestick, heatmap
   - **Series Styling**: color, stroke width, markers, fill opacity, dash patterns, gradients
   - **Line Interpolation**: linear, bezier, stepped, monotone
   - **X-Axis**: label, unit, range, tick format, time vs numeric, rotation, visibility
   - **Y-Axis**: label, unit, range, position (left/right), multiple axes, normalization
   - **Grid**: show/hide, colors, dash patterns, opacity
   - **Legend**: show/hide, position, orientation, style
   - **Interactions**: pan, zoom, crosshair, tooltip, selection, scrollbars
   - **Annotations**: horizontal lines, vertical lines, regions, markers, labels, training zones
   - **Theme**: light/dark/auto, color palettes, backgrounds
   - **Normalization**: auto-range, include zero, padding percentages
2. **Given** an existing chart, **When** user prompts "Change the line color to red and add a horizontal line at 200W", **Then** the chart is **modified in-place** (same chart ID) without recreating. The agent receives the current chart configuration for context.
3. **Given** incomplete styling, **When** processed, **Then** intelligent defaults are applied based on:
   - Chart type defaults (line defaults vs bar defaults)
   - Series type defaults (power → orange, HR → red, cadence → blue)
   - Current theme (dark mode adjustments)
   - Athlete context if loaded (preferred colors, zones)

---

### User Story 3a - Post-Generation Configuration Panel (Priority: P1)

After a chart is generated, users need a visual configuration panel to tweak common settings without re-prompting the agent.

**Why this priority**: Reduces friction for quick adjustments; not every change needs an LLM call.

**Acceptance Scenarios**:

1. **Given** a generated chart, **When** displayed, **Then** an optional config panel is available with controls for:
   - Theme toggle (light/dark)
   - Scrollbar visibility
   - Grid visibility
   - Legend position
   - Zoom reset
2. **Given** a config panel change, **When** user modifies a setting, **Then** the chart updates immediately without LLM involvement.
3. **Given** a config panel change, **When** user subsequently prompts the agent, **Then** the agent is aware of the current chart state including manual adjustments.

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

### User Story 8 - External API Data Integration (Priority: P2 - Future Phase)

A sport scientist needs to fetch athlete data directly from external platforms like intervals.icu, rather than manually downloading and uploading files.

**Why this priority**: Streamlines workflow for connected platforms; requires core functionality first.

**Acceptance Scenarios**:

1. **Given** configured intervals.icu API credentials, **When** user prompts "Fetch Joe Soap's last 5 rides from intervals.icu", **Then** the API is called and workout data is loaded.
2. **Given** multiple activities fetched, **When** user prompts "Show average power across all January rides", **Then** data is aggregated across workouts and charted.
3. **Given** fetched data, **When** the same data is requested again, **Then** cached data is used (intervals.icu data is immutable).

**Technical Notes**:

- intervals.icu requires OAuth/API key authentication
- Data is immutable once fetched → suitable for local caching
- Must support date range queries and athlete selection
- This is a **future phase** - core file-based workflow must work first

---

### User Story 9 - Modern Chat Interface & Chart Management (Priority: P0)

Users need a clean, modern UI that fits a sport science laboratory aesthetic, with proper file handling and chart management.

**Why this priority**: UX is critical for adoption; users won't tolerate clunky interfaces.

**Acceptance Scenarios**:

#### Chat Interface:

1. **Given** the chat interface, **When** displayed, **Then** it has:
   - Clean white/light background (with dark mode option)
   - Modern, minimal chat input box
   - Professional sport science aesthetic
   - Maximum chart real estate, minimal chrome
2. **Given** file attachments, **When** user adds files, **Then** they appear as removable chips/tags above the input.
3. **Given** multiple files attached, **When** user wants to remove one, **Then** clicking [×] removes just that file before sending.

#### Chart Management:

4. **Given** a generated chart, **When** user clicks "Save" or "Favorite", **Then** the chart is added to a session-local favorites list.
5. **Given** saved charts, **When** user opens the chart gallery, **Then** all favorited charts are displayed with thumbnails.
6. **Given** a chart in the conversation, **When** user prompts "make the line thicker", **Then** the **existing chart is updated in-place**, not replaced with a new chart.

#### Editing Flow:

7. **Given** an existing chart with ID, **When** editing via prompt, **Then** the agent receives the current chart configuration as context.
8. **Given** multiple charts in a session, **When** user says "update the power chart", **Then** the agent identifies and modifies the correct chart by context or ID.

**Note**: Persistence to database/file is a future phase. V1 uses session-local storage only.

---

## Functional Requirements

### 0. Complete Property Control Matrix

**Every property listed below MUST be controllable by the agent.** This is the definitive list - no exceptions.

| Category            | Properties                                                                                                                                                                                   |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Chart Types**     | line, area, bar, scatter, candlestick, heatmap                                                                                                                                               |
| **Series Styling**  | color, stroke_width, stroke_dash, fill_opacity, gradient, marker_style, marker_size, visible, legend_visible                                                                                 |
| **Line Options**    | interpolation (linear/bezier/stepped/monotone), show_points, point_size                                                                                                                      |
| **Bar Options**     | bar_width_percent, bar_corner_radius, bar_spacing, stacked                                                                                                                                   |
| **Area Options**    | fill_opacity, fill_gradient, show_line, line_width                                                                                                                                           |
| **Scatter Options** | marker_style, marker_size, marker_color_by_value                                                                                                                                             |
| **X-Axis**          | label, unit, type (numeric/time/category), min, max, auto_range, padding_percent, tick_count, tick_format, tick_rotation, show_ticks, show_axis_line, show_grid_lines, grid_color, grid_dash |
| **Y-Axis**          | id, label, unit, position (left/right), min, max, auto_range, include_zero, padding_percent, tick_count, tick_format, show_ticks, show_axis_line, show_grid_lines, grid_color, color         |
| **Multi-Axis**      | Multiple Y-axes with independent ranges, colors, and series bindings                                                                                                                         |
| **Grid**            | show_grid, grid_color, grid_opacity, grid_dash, horizontal_only, vertical_only                                                                                                               |
| **Legend**          | show_legend, position (top/bottom/left/right/floating), orientation (horizontal/vertical), item_spacing                                                                                      |
| **Interactions**    | enable_pan, pan_direction, enable_zoom, zoom_direction, min_zoom, max_zoom, enable_scrollbars, scrollbar_position                                                                            |
| **Crosshair**       | show_crosshair, crosshair_style (full/horizontal/vertical), snap_to_data, show_values                                                                                                        |
| **Tooltip**         | show_tooltip, tooltip_format, tooltip_position, show_all_series                                                                                                                              |
| **Selection**       | enable_selection, selection_mode (point/range/multi), selection_color                                                                                                                        |
| **Annotations**     | horizontal_line, vertical_line, region, point_marker, text_label, training_zones                                                                                                             |
| **Theme**           | theme (light/dark/auto), background_color, color_palette, font_family                                                                                                                        |
| **Layout**          | width, height, aspect_ratio, padding (top/bottom/left/right)                                                                                                                                 |
| **Animation**       | animate_on_load, animation_duration_ms, animation_easing                                                                                                                                     |
| **Normalization**   | auto_range, include_zero, padding_percent, domain_clamp                                                                                                                                      |

### 1. LLM Tool Schema (Expanded)

#### 1.1 Core Tools

| Tool               | Purpose                                | Status       |
| ------------------ | -------------------------------------- | ------------ |
| `create_chart`     | Create a new chart from data           | POC Complete |
| `modify_chart`     | Modify an existing chart               | POC Partial  |
| `explain_data`     | Analyze and describe data              | POC Complete |
| `describe_data`    | Discover columns/fields in loaded data | NEW          |
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

  // Scrollbars
  enable_scrollbars?: boolean;
  scrollbar_position?: "bottom" | "right" | "both";
  scrollbar_style?: "thin" | "normal" | "thick";

  // Crosshair
  show_crosshair?: boolean;
  crosshair_style?: "full" | "horizontal" | "vertical";
  crosshair_snap_to_data?: boolean;
  crosshair_show_values?: boolean;

  // Tooltip
  show_tooltip?: boolean;
  tooltip_format?: string;
  tooltip_show_all_series?: boolean;

  // Selection
  enable_selection?: boolean;
  selection_mode?: "point" | "range" | "multi";
  selection_color?: string;

  // Animation
  animate_on_load?: boolean;
  animation_duration_ms?: number;
  animation_easing?: "linear" | "ease_in" | "ease_out" | "ease_in_out";
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

### 6. UI/UX Requirements

#### 6.1 Visual Design Principles

| Principle         | Implementation                                                          |
| ----------------- | ----------------------------------------------------------------------- |
| **Clean**         | White/light backgrounds, minimal chrome, maximum data visibility        |
| **Modern**        | Contemporary chat interface, smooth animations, professional typography |
| **Sport Science** | Clinical, data-focused aesthetic appropriate for laboratory settings    |
| **Responsive**    | Works across screen sizes, charts resize fluidly                        |

#### 6.2 Chat Interface Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  📊 Agentic Charts                              [⚙️] [🌙/☀️]     │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ [Assistant]: Here's the power analysis you requested...    │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────┐   │  │
│  │  │                                                    │   │  │
│  │  │            [Generated Chart]                       │   │  │
│  │  │                                                    │   │  │
│  │  └────────────────────────────────────────────────────┘   │  │
│  │  [⭐ Save] [📋 Copy Config] [📷 Export PNG] [⚙️ Config]   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│  📎 athlete_ride.FIT [×]  📎 context.yaml [×]                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Show 30s rolling power with HR overlay and training zones │  │
│  └────────────────────────────────────────────────────────────┘  │
│  [+ Add File]                                      [Send ▶]      │
└──────────────────────────────────────────────────────────────────┘
```

#### 6.3 Chart Action Bar

Every generated chart has an action bar with:

- **⭐ Save/Favorite**: Add to session favorites gallery
- **📋 Copy Config**: Copy chart JSON to clipboard
- **📷 Export**: Download as PNG/SVG
- **⚙️ Config Panel**: Open side panel for quick tweaks
- **✏️ Edit**: Focus chat input with chart context for modification

#### 6.4 Favorites/Gallery View

```
┌──────────────────────────────────────────────────────────────────┐
│  📊 Saved Charts (3)                                    [× Close] │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  [Thumbnail] │  │  [Thumbnail] │  │  [Thumbnail] │           │
│  │              │  │              │  │              │           │
│  │ Power 30s    │  │ HR Drift     │  │ Zone Dist    │           │
│  │ Jan 25, 2026 │  │ Jan 25, 2026 │  │ Jan 25, 2026 │           │
│  │ [View] [×]   │  │ [View] [×]   │  │ [View] [×]   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└──────────────────────────────────────────────────────────────────┘
```

#### 6.5 File Attachment Handling

- Files appear as removable chips above input
- Each chip shows: icon + filename + [×] remove button
- Supported formats shown on hover
- Drag-and-drop support for file addition
- Clear visual feedback during file processing

---

## Success Criteria

1. **Completeness**: All BravenChartPlus chart properties are controllable via LLM tools (see Property Control Matrix).
2. **Sport Science**: FIT file → 30s rolling power chart works end-to-end in <5 seconds.
3. **Accuracy**: Metric calculations (NP, IF, TSS) match verified formulas to 0.1% tolerance.
4. **Multi-LLM**: Works with Anthropic Claude, OpenAI GPT-4, and Google Gemini.
5. **Performance**: Charts with 100k+ points render at 60 FPS with automatic downsampling.
6. **Extensibility**: Custom metrics and chart types can be added without core changes.
7. **In-Place Editing**: Modifying a chart updates it in place; does not create a new chart.
8. **UI/UX**: Chat interface matches modern sport science aesthetic (clean, white, professional).
9. **File Handling**: Files can be added/removed before prompting with clear visual feedback.
10. **Favorites**: Charts can be saved to session gallery and viewed later (without persistence).

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

## Constraints

| Constraint                  | Value            | Rationale                                          |
| --------------------------- | ---------------- | -------------------------------------------------- |
| Max file upload size        | 50 MB            | Browser memory limits; covers multi-activity files |
| File size warning threshold | 10 MB            | Alert user to potential slowness                   |
| Simultaneous sessions       | 1                | Simplicity for V1; multi-session in Phase 3        |
| Favorites storage           | Session-local    | No persistence in V1; JSON export available        |
| Config panel controls       | Appearance only  | Data changes require agent for traceability        |
| Chart edit context          | Full JSON config | Agent sees complete current state                  |
| Logging                     | Debug mode only  | Console in dev; silent in production               |

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
- **Persistent storage** (database, file system) - session-local only for V1
- **External API integration** (intervals.icu, TrainingPeaks) - Future Phase
- **User authentication** - assumes single-user local usage for V1

---

## Phasing

### Phase 1: Core (This Spec)

- Natural language chart creation
- FIT/CSV/JSON file loading
- Full property control
- In-place chart editing
- Config panel for quick tweaks
- Session-local favorites (non-persisted)
- Modern chat UI

### Phase 2: API Integration (Future Spec)

- intervals.icu API adapter
- OAuth authentication flow
- Data caching layer
- Multi-workout aggregation
- TrainingPeaks integration

### Phase 3: Persistence (Future Spec)

- Chart configuration persistence
- Template library
- User preferences
- Session restore
- Export to database

---

## Clarifications ✅ RESOLVED

| #   | Question                             | Decision                                                                                          |
| --- | ------------------------------------ | ------------------------------------------------------------------------------------------------- |
| 1   | Multiple simultaneous chat sessions? | **No** - Single session only for V1. Multi-session deferred to Phase 3.                           |
| 2   | Maximum file size for uploads?       | **50 MB** hard limit. Warning shown for files >10 MB.                                             |
| 3   | Chart template sharing?              | **Deferred** to Phase 3 with persistence. Local templates only in V1.                             |
| 4   | Audit logging for compliance?        | **Debug logging** in development mode only. Silent in production. Full audit deferred to Phase 3. |
| 5   | Config panel scope?                  | **Appearance only** - theme, scrollbars, grid, legend. Data changes go through agent.             |
| 6   | Chart editing context?               | **Full configuration** sent to agent. Token cost is minimal vs. preventing mistakes.              |
| 7   | Favorites export?                    | **Yes** - Allow JSON export for manual backup even without persistence.                           |
| 8   | intervals.icu API access?            | **Yes** - API key access available. Phase 2 will include specific intervals.icu adapter.          |

---

## Known Gaps & Open Issues

### Gap 1: Error Handling Strategy (High Severity)

**Problem**: No defined error handling for:

- LLM API failures (rate limits, timeouts, network errors)
- Invalid/corrupt file uploads
- Malformed data columns
- Chart rendering failures
- Token limit exceeded mid-conversation

**Required**: Error handling taxonomy with user-facing messages and recovery actions.

```typescript
interface ErrorHandling {
  // Error categories
  categories:
    | "api_error"
    | "file_error"
    | "data_error"
    | "render_error"
    | "token_error";

  // User-facing error display
  userMessage: string; // Friendly message
  technicalDetails?: string; // Optional expandable details
  recoveryAction?: string; // Suggested next step
  retryable: boolean; // Show retry button?
}
```

**✅ Decision (OQ1)**: Hybrid retry - auto-retry once silently, then show error with Retry button for subsequent attempts.

---

### Gap 2: Loading States & Progress Indicators (Medium Severity)

**Problem**: No specification for what users see during:

- File parsing (large FIT files can take 5-10 seconds)
- LLM API calls (2-10 seconds typical)
- Data transformation operations
- Chart rendering

**Required**: Loading state specifications.

| Operation      | Duration | Indicator                           |
| -------------- | -------- | ----------------------------------- |
| File upload    | 0-5s     | Upload progress bar with percentage |
| File parsing   | 1-10s    | "Parsing file..." with spinner      |
| LLM request    | 2-10s    | "Thinking..." with animated dots    |
| Data transform | 0-2s     | Inline spinner                      |
| Chart render   | 0-1s     | Skeleton chart placeholder          |

**✅ Decision (OQ2)**: Hybrid streaming - stream text explanations as they arrive, wait for complete tool calls before rendering charts.

---

### Gap 3: Undo/Redo Capability (Low Severity - Enhancement)

**Problem**: No undo/redo for chart modifications. User must re-request via chat.

**Recommendation**: Implement chart state history stack.

```typescript
interface ChartHistory {
  maxSteps: 20; // Maximum history depth
  states: ChartConfiguration[]; // Stack of configurations
  currentIndex: number; // Current position

  // Operations
  undo(): ChartConfiguration | null;
  redo(): ChartConfiguration | null;
  canUndo(): boolean;
  canRedo(): boolean;
}
```

**✅ Decision (OQ3)**: No persistence - undo history clears on page refresh (simpler implementation).

---

### Gap 4: Data Column Discovery Tool (High Severity)

**Problem**: The agent cannot know what columns/fields exist in uploaded data without a discovery tool.

**Required**: New LLM tool `describe_data`.

```typescript
interface DescribeDataInput {
  fileId: string; // Reference to uploaded file
}

interface DescribeDataOutput {
  fileName: string;
  fileType: "fit" | "csv" | "json";
  rowCount: number;
  columns: ColumnDescriptor[];
  sampleRows: Record<string, any>[]; // First 5 rows
  timeRange?: {
    start: string; // ISO timestamp
    end: string;
    durationSeconds: number;
  };
}

interface ColumnDescriptor {
  name: string;
  type: "number" | "string" | "datetime" | "boolean";
  nullable: boolean;
  stats?: {
    min?: number;
    max?: number;
    mean?: number;
    nullCount: number;
  };
  sampleValues: any[]; // First 5 non-null values
}
```

**✅ Decision (OQ4)**: Auto-run `describe_data` on every file upload. Agent always has column info available.

---

### Gap 5: Chart Identification & Inline Editing (Medium Severity)

**Problem**: When multiple charts exist, how does the user specify which chart to modify?

**Solution**: Inline chat linked to specific charts.

```
┌─────────────────────────────────────────────────────────────┐
│ [Power Chart]                                    [💬] [📌]  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │          ▄▄                                             │ │
│ │        ▄█▀▀█▄   ▄█▄                                     │ │
│ │      ▄█▀    ▀█▄█  ▀█▄     Power (watts)                 │ │
│ │    ▄█▀        ▀     ▀█▄                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [💬 Clicked - Inline Chat Opens Below]                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ User: Change the line color to red                      │ │
│ │ Agent: Done! Changed power series to #FF4444.           │ │
│ │ ┌─────────────────────────────────────────────────────┐ │ │
│ │ │ Type a message... (editing Power Chart)     [Send]  │ │ │
│ │ └─────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Features**:

- **💬 Chat Button**: Opens inline chat scoped to this specific chart
- **📌 Add to Context**: Adds chart to main chat context for cross-chart operations
- **Context Indicator**: Shows "(editing Power Chart)" in input field
- **Scoped Modifications**: Agent only modifies the linked chart

```typescript
interface ChartContext {
  chartId: string; // Unique chart identifier
  chartName: string; // User-visible name (e.g., "Power Chart")
  configuration: ChartConfiguration; // Full current config
  linkedConversation?: Message[]; // Inline chat history
}

interface InlineChatRequest {
  chartId: string; // Which chart is being edited
  userMessage: string;
  currentConfig: ChartConfiguration; // Full config for context
}
```

**✅ Decision (OQ5)**: Yes - persist inline chat history when chart collapsed/expanded.

---

### Gap 6: Time Zone Handling (Medium Severity)

**Problem**: FIT files store timestamps in UTC. User may be in different timezone. Display timezone not specified.

**Required**: Timezone handling strategy.

```typescript
interface TimezoneConfig {
  source: "utc" | "local" | "file" | "custom";
  customTimezone?: string; // e.g., 'America/New_York'
  displayFormat: "absolute" | "relative" | "elapsed";
  // 'absolute': "14:32:15"
  // 'relative': "+1:32:15" (from activity start)
  // 'elapsed': "1h 32m 15s"
}
```

**Default Behavior**: Display elapsed time from activity start for FIT files.

**✅ Decision (OQ6)**: Global default timezone + file override. FIT files use embedded timezone when available.

---

### Gap 7: Keyboard Shortcuts (Low Severity - Accessibility)

**Problem**: No keyboard shortcuts defined for power users and accessibility.

**Recommended Shortcuts**:

| Shortcut       | Action                           |
| -------------- | -------------------------------- |
| `Ctrl+Enter`   | Send message                     |
| `Ctrl+U`       | Upload file                      |
| `Ctrl+Z`       | Undo last chart change           |
| `Ctrl+Shift+Z` | Redo                             |
| `Ctrl+S`       | Save to favorites                |
| `Ctrl+E`       | Export chart                     |
| `Escape`       | Close config panel / inline chat |
| `Tab`          | Navigate between charts          |

**✅ Decision (OQ7)**: Fixed shortcuts for V1. Customization deferred to Phase 2.

---

### Issue 1: Chart Type Support Gap (Medium Severity)

**Problem**: Spec mentions chart types that may not exist in current BravenChartPlus:

- Candlestick charts
- Histogram charts
- Bubble charts
- Heatmaps

**Required**: Audit current BravenChartPlus capabilities.

**Known Supported Types**:

- ✅ LineChartSeries
- ✅ AreaChartSeries
- ✅ BarChartSeries
- ✅ ScatterChartSeries

**✅ Decision (OQ8)**: Keep all chart types in spec. Mark candlestick/heatmap as Phase 2 aspirational.

---

### Issue 2: Token Usage Visibility (Medium Severity)

**Problem**: No visibility into LLM API token consumption and costs.

**Recommendation**: Add optional token usage display.

```typescript
interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  estimatedCost?: number; // Optional USD estimate
}

interface ConversationStats {
  messageCount: number;
  totalTokensUsed: number;
  estimatedCost?: number;
  tokenLimit: number; // From constraints
  usagePercentage: number; // Visual indicator
}
```

**Display**: Show in collapsed footer: "Session: 12.4k / 100k tokens (~$0.15)"

**✅ Decision (OQ9)**: Soft limit - warn at 80%, suggest "Start new session", allow continue.

---

### Issue 3: Concurrent Tool Execution (Low Severity)

**Problem**: Unclear if agent should execute multiple tools in parallel.

**Example Scenario**: User uploads 3 FIT files simultaneously.

**Options**:

1. **Sequential**: Process one file at a time (safer, slower)
2. **Parallel**: Process all files concurrently (faster, more complex)

**Recommendation**: Sequential for V1, parallel for Phase 2.

**✅ Decision (OQ10)**: Soft limit - accept all files, warn if >5 about processing time.

---

### Issue 4: File Security & Validation (High Severity)

**Problem**: No specification for file security measures.

**Required Security Measures**:

| Check                     | Action                                  |
| ------------------------- | --------------------------------------- |
| File extension validation | Only allow .fit, .csv, .json, .yaml     |
| MIME type verification    | Verify content matches extension        |
| Size limit enforcement    | Reject files > 50 MB before upload      |
| Malicious content scan    | Sanitize embedded scripts in CSV/JSON   |
| Path traversal prevention | Strip directory paths from filenames    |
| Filename sanitization     | Remove special characters, limit length |

```typescript
interface FileValidation {
  allowedExtensions: [".fit", ".csv", ".json", ".yaml"];
  maxSizeBytes: 52428800; // 50 MB
  requireMimeValidation: true;
  sanitizeFilenames: true;
  maxFilenameLength: 255;
}
```

**✅ Decision (OQ11)**: Sanitize JSON - strip script-like values (`<script>`, `javascript:`). FIT files are proprietary binary format, not a concern.

---

### Issue 5: Multi-Axis Limits (Low Severity)

**Problem**: What is the maximum number of Y-axes supported?

**Technical Constraint**: BravenChartPlus renderer supports maximum 4 Y-axes (2 left, 2 right).

**⚠️ IMPORTANT DISTINCTION**:

- **Y-Axes**: Hard limit of 4 (technical constraint, no rendering for more)
- **Series**: Effectively unlimited (series share axes based on unit/scale compatibility)

```typescript
interface MultiAxisConstraints {
  maxYAxes: 4; // Hard limit: Left 2, Right 2
  maxSeriesPerAxis: 10; // Soft limit per axis
  totalSeriesLimit: null; // No hard limit on total series
  warnAtAxes: 3; // Show complexity warning
}
```

**✅ Decision (OQ12)**: Hard limit 4 Y-axes (technical). Agent must consolidate series onto shared axes when >4 different scales needed.

---

## Proposed Enhancements

### Enhancement 1: Prompt Templates (Medium Value)

**Problem**: Users repeatedly type similar requests for common sport science tasks.

**Proposal**: Pre-built prompt templates accessible via dropdown or slash commands.

```
┌─────────────────────────────────────────────────────────────┐
│ [/] Prompt Templates                              [▼]       │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📊 Power Analysis                                       │ │
│ │ 💓 Heart Rate Zones                                     │ │
│ │ 🏃 Pace/Speed Over Time                                 │ │
│ │ ⚡ Normalized Power vs Power                            │ │
│ │ 📈 Training Load (TSS) Summary                          │ │
│ │ 🔄 Cadence Analysis                                     │ │
│ │ 🌡️ Power vs Heart Rate Decoupling                       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**Template Example**:

```typescript
interface PromptTemplate {
  id: string;
  name: string;
  icon: string;
  prompt: string;                    // The actual prompt text
  requiredDataColumns?: string[];    // Columns needed (power, heart_rate, etc.)
  category: 'cycling' | 'running' | 'swimming' | 'general';
}

// Example template
{
  id: 'power-analysis',
  name: 'Power Analysis',
  icon: '📊',
  prompt: 'Create a power chart showing 30-second rolling average with the following zones highlighted: Z1 (0-55% FTP), Z2 (55-75%), Z3 (75-90%), Z4 (90-105%), Z5 (105-120%), Z6 (120%+). Show average and normalized power as horizontal reference lines.',
  requiredDataColumns: ['power'],
  category: 'cycling'
}
```

**✅ Decision (EQ1)**: Read-only templates for V1. User-editable templates in Phase 2.

---

### Enhancement 2: Data Preview Before Charting (High Value)

**Problem**: Users upload files but don't know what's in them before asking for a chart.

**Proposal**: Show interactive data preview after file upload.

```
┌─────────────────────────────────────────────────────────────┐
│ 📁 workout_2026-01-25.fit                          [✕]     │
│ ─────────────────────────────────────────────────────────── │
│ Duration: 1:32:45  |  Records: 5,565  |  Size: 2.4 MB      │
│                                                             │
│ Available Columns:                                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ☑ timestamp    │ datetime │ 2026-01-25 14:00:00 → ...   │ │
│ │ ☑ power        │ number   │ 0 → 485 W (avg: 218)        │ │
│ │ ☑ heart_rate   │ number   │ 98 → 178 bpm (avg: 142)     │ │
│ │ ☑ cadence      │ number   │ 0 → 112 rpm (avg: 87)       │ │
│ │ ☐ temperature  │ number   │ 18 → 22 °C                  │ │
│ │ ☐ altitude     │ number   │ 245 → 892 m                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [View Sample Data]  [Create Chart →]                        │
└─────────────────────────────────────────────────────────────┘
```

```typescript
interface DataPreview {
  fileName: string;
  fileType: "fit" | "csv" | "json";
  duration?: string; // For activity files
  recordCount: number;
  fileSizeBytes: number;
  columns: ColumnPreview[];
  sampleData?: Record<string, any>[]; // First 10 rows
}

interface ColumnPreview {
  name: string;
  type: "number" | "string" | "datetime" | "boolean";
  selected: boolean; // User can toggle columns
  range?: { min: any; max: any };
  average?: number; // For numeric columns
  unit?: string; // Detected unit (W, bpm, rpm, etc.)
}
```

**✅ Decision (EQ2)**: Visual only - checkboxes are UI hints, agent sees all columns.

---

### Enhancement 3: Conversation Search (Low Value - Phase 2)

**Problem**: Long sessions make it hard to find previous charts or discussions.

**Proposal**: Search through conversation history.

```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Search conversation...                          [✕]     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ power zones                                             │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Results (3):                                                │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📊 "Show power with zone colors" - 14:32                │ │
│ │ 💬 "Can you add power zones as..." - 14:35              │ │
│ │ 📊 "Update power zones to use..." - 14:41              │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**✅ Decision (EQ3)**: Defer to Phase 2 - sessions are ephemeral, low value for V1.

---

### Enhancement 4: Metric Display Cards (High Value)

**Problem**: Calculated metrics (NP, TSS, IF, etc.) are only shown in text responses, not visually.

**Proposal**: Display computed metrics as visual cards alongside charts.

```
┌─────────────────────────────────────────────────────────────┐
│ Workout Metrics                                             │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│ │ Avg Power│ │    NP    │ │    IF    │ │   TSS    │        │
│ │   218 W  │ │  245 W   │ │   0.87   │ │   78.4   │        │
│ │ ▲ +12W   │ │ ▲ +8W    │ │ ▼ -0.02  │ │ ▲ +5.2   │        │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│ │    VI    │ │   W/kg   │ │  kJ Tot  │ │ Avg HR   │        │
│ │   1.12   │ │  3.42    │ │  1,205   │ │  142 bpm │        │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────────┘
```

```typescript
interface MetricCard {
  id: string;
  label: string;
  value: number | string;
  unit?: string;
  format?: "number" | "decimal" | "time" | "percentage";
  precision?: number;
  trend?: {
    direction: "up" | "down" | "neutral";
    delta: number | string;
    comparison: string; // "vs last workout", "vs 30-day avg"
  };
  color?: string; // Card accent color
  tooltip?: string; // Explanation of metric
}

interface MetricDashboard {
  title?: string;
  metrics: MetricCard[];
  layout: "row" | "grid"; // Row = horizontal, Grid = 4-column
  collapsible: boolean;
}
```

**✅ Decision (EQ4)**: User-specified trend comparisons only. No automatic comparisons.

---

### Enhancement 5: Comparison Mode (High Value)

**Problem**: Users often want to compare multiple workouts side-by-side or overlaid.

**Proposal**: Built-in comparison mode for multi-workout analysis.

```
┌─────────────────────────────────────────────────────────────┐
│ Comparison Mode                               [Exit Compare]│
│ ─────────────────────────────────────────────────────────── │
│ Selected Workouts:                                          │
│ ┌───────────────────────┐ ┌───────────────────────┐        │
│ │ 📁 Jan 25 - Intervals │ │ 📁 Jan 18 - Intervals │        │
│ │ ━━━━ (blue)          │ │ ┅┅┅┅ (orange, dashed) │        │
│ └───────────────────────┘ └───────────────────────┘        │
│                                                             │
│ [Overlay] [Side-by-Side] [Difference Plot]                 │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │     ▄▄                                                  │ │
│ │   ▄█▀▀█▄   ▄█▄        ━━━ Jan 25                       │ │
│ │ ▄█┅┅┅┅▀█▄█┅┅▀█▄       ┅┅┅ Jan 18                       │ │
│ │█┅      ┅▀┅    ┅█                                        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Comparison Metrics:                                         │
│ ┌────────────┬───────────┬───────────┬──────────┐          │
│ │ Metric     │ Jan 25    │ Jan 18    │ Delta    │          │
│ ├────────────┼───────────┼───────────┼──────────┤          │
│ │ Avg Power  │ 218 W     │ 212 W     │ +6 W ▲   │          │
│ │ NP         │ 245 W     │ 238 W     │ +7 W ▲   │          │
│ │ TSS        │ 78.4      │ 72.1      │ +6.3 ▲   │          │
│ └────────────┴───────────┴───────────┴──────────┘          │
└─────────────────────────────────────────────────────────────┘
```

```typescript
interface ComparisonMode {
  enabled: boolean;
  workouts: WorkoutReference[]; // 2-5 workouts
  displayMode: "overlay"; // V1: overlay only, side-by-side/difference in Phase 2
  alignmentStrategy: "time-elapsed"; // V1: elapsed time only
  differenceBaseline?: string; // Phase 2
}

interface WorkoutReference {
  fileId: string;
  fileName: string;
  displayColor: string;
  lineStyle: "solid" | "dashed" | "dotted";
  visible: boolean;
}
```

**✅ Decision (EQ5)**: 5 workouts max. V1 scope: overlay + metrics table, elapsed time alignment.

---

### Enhancement 6: Smart Filename Parsing (Medium Value)

**Problem**: FIT filenames often contain useful metadata that's ignored.

**Examples**:

- `tp-2023646.2026-01-25-14-32-00.GarminPing.workout.FIT`
- `Joe_Soap_Intervals_2026-01-25.fit`
- `2026-01-25_Morning_Ride.fit`

**Proposal**: Auto-extract metadata from filenames.

```typescript
interface FilenameParsing {
  patterns: FilenamePattern[];
  extractedMetadata: {
    athleteName?: string;
    activityDate?: Date;
    activityType?: string; // ride, run, swim, intervals, etc.
    source?: string; // Garmin, Wahoo, TrainingPeaks, etc.
    customTags?: string[];
  };
}

interface FilenamePattern {
  regex: RegExp;
  groups: {
    athleteName?: number; // Capture group index
    date?: number;
    activityType?: number;
    source?: number;
  };
}

// Example patterns
const patterns = [
  // TrainingPeaks: tp-{id}.{date}.GarminPing.{id}.FIT
  { regex: /tp-\d+\.(\d{4}-\d{2}-\d{2}).*\.FIT/i, groups: { date: 1 } },

  // Common: {Name}_{Activity}_{Date}.fit
  {
    regex: /([A-Za-z_]+)_([A-Za-z]+)_(\d{4}-\d{2}-\d{2})\.fit/i,
    groups: { athleteName: 1, activityType: 2, date: 3 },
  },
];
```

**✅ Decision (EQ6)**: Display only - show parsed metadata in UI, do not auto-populate agent context.

---

### Enhancement 7: Shareable Chart Links (Low Value - Phase 3)

**Problem**: Users want to share chart configurations with colleagues without exporting files.

**Proposal**: Generate shareable links encoding chart configuration.

```
┌─────────────────────────────────────────────────────────────┐
│ Share Chart                                        [✕]     │
│ ─────────────────────────────────────────────────────────── │
│ ⚠️ Note: Link includes configuration only, not data.       │
│ Recipient must have access to the same data file.          │
│                                                             │
│ Share Options:                                              │
│ ☑ Include chart styling                                    │
│ ☑ Include axis configuration                               │
│ ☐ Include annotations                                       │
│ ☐ Include metric cards                                      │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ https://app.example.com/chart?c=eyJjaGFydCI6...        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [Copy Link]  [Copy as JSON]  [Download Config]             │
└─────────────────────────────────────────────────────────────┘
```

**✅ Decision (EQ7)**: URL-encoded shareable links, deferred to future phase (not V1).

---

## Enhancement Questions ✅ ALL RESOLVED

| #   | Question                                              | Enhancement   | Decision                                                           |
| --- | ----------------------------------------------------- | ------------- | ------------------------------------------------------------------ |
| EQ1 | Should prompt templates be editable by users?         | Enhancement 1 | **Read-only** for V1, editable in Phase 2                          |
| EQ2 | Should column selection filter what agent sees?       | Enhancement 2 | **Visual only** - agent sees all columns                           |
| EQ3 | Include conversation search in V1?                    | Enhancement 3 | **Defer** to Phase 2                                               |
| EQ4 | Automatic trend comparisons or user-specified?        | Enhancement 4 | **User-specified** - no automatic comparisons                      |
| EQ5 | Maximum workouts to compare?                          | Enhancement 5 | **5 workouts max** (overlay + metrics table, elapsed time aligned) |
| EQ6 | Auto-populate context from filename, or display only? | Enhancement 6 | **Display only** - show parsed metadata, don't auto-populate       |
| EQ7 | Shareable links in V1 or Phase 3?                     | Enhancement 7 | **Defer** - URL-encoded approach, future phase                     |

---

## Open Questions ✅ ALL RESOLVED

| #    | Question                                                 | Gap/Issue | Decision                                                                               |
| ---- | -------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------- |
| OQ1  | Automatic retry with exponential backoff for API errors? | Gap 1     | **Hybrid**: Auto-retry once silently, then show error with Retry button                |
| OQ2  | Show streaming LLM responses or wait for complete?       | Gap 2     | **Hybrid**: Stream text explanations, wait for complete tool calls before chart render |
| OQ3  | Should undo history persist across session restarts?     | Gap 3     | **No**: Undo history clears on page refresh (simpler implementation)                   |
| OQ4  | Auto-run `describe_data` on file upload?                 | Gap 4     | **Yes**: Automatically run on every upload, agent always has column info               |
| OQ5  | Persist inline chat history when chart collapsed?        | Gap 5     | **Yes**: Keep history, restore when chart expanded again                               |
| OQ6  | Timezone configurable per-chart or globally?             | Gap 6     | **Global default + file override**: FIT files use embedded timezone when available     |
| OQ7  | Customizable keyboard shortcuts?                         | Gap 7     | **Deferred**: Fixed shortcuts for V1, customization in Phase 2                         |
| OQ8  | Which chart types are actually implemented?              | Issue 1   | **Keep aspirational**: Mark candlestick/heatmap as Phase 2                             |
| OQ9  | Warn users when approaching token limits?                | Issue 2   | **Soft limit**: Warn at 80%, suggest new session, allow continue                       |
| OQ10 | Limit concurrent file uploads?                           | Issue 3   | **Soft limit**: Accept all files, warn if >5 about processing time                     |
| OQ11 | Scan for embedded JavaScript in JSON?                    | Issue 4   | **Sanitize**: Strip script-like values from JSON (FIT files not a concern)             |
| OQ12 | Allow more than 4 Y-axes with confirmation?              | Issue 5   | **Hard limit**: 4 Y-axes max (technical), unlimited series (share axes)                |
