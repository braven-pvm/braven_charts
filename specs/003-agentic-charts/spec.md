# Feature Specification: Agentic Charts - AI-Powered Chart Generation

**Feature Branch**: `003-agentic-charts`  
**Created**: 2026-01-25  
**Status**: Draft  
**Input**: AI-powered chart generation via natural language for sport science data visualization

## Clarifications

### Session 2026-01-25

- Q: How should the system respond when a user uploads a corrupted or unsupported file format? → A: Error message with suggested formats (e.g., "File format not recognized. Supported: FIT, CSV, TCX")
- Q: How should the system respond when a user requests a chart type that doesn't exist? → A: Error only (e.g., "Chart type 'waterfall' is not supported")
- Q: What level of observability (logging/metrics) is required for V1? → A: Minimal - console errors only, no structured logging
- Q: What should the user see when the application first loads (empty state)? → A: Welcome message with example prompts + sample chart pre-loaded with demo data
- Q: When the AI service is unavailable or rate-limited, what should the user experience? → A: Automatic retry (1 attempt) with spinner, then error with manual retry option if still failing

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Natural Language Chart Creation (Priority: P1)

A sport scientist wants to visualize an athlete's training data by describing what they want to see in plain language, without technical knowledge of charting APIs.

**Why this priority**: Core value proposition - enables non-technical users to create professional data visualizations through conversation.

**Independent Test**: User types "Show me a line chart of power over time" and receives a rendered chart with labeled axes.

**Acceptance Scenarios**:

1. **Given** a user with no technical charting knowledge, **When** they type "Show me a line chart of temperature over time", **Then** a line chart renders with time on X-axis, temperature on Y-axis, and appropriate labels.
2. **Given** a request with styling requirements "Create a blue area chart with the grid hidden", **When** processed, **Then** the chart displays in blue with grid lines removed.
3. **Given** an ambiguous request with multiple possible interpretations, **When** processed, **Then** the system either asks a clarifying question OR applies intelligent defaults with an explanation of what was chosen.

---

### User Story 2 - Sport Science File Analysis (Priority: P1)

A sport scientist needs to analyze an athlete's cycling session from a workout file, applying domain-specific calculations like rolling averages.

**Why this priority**: Core sport science use case - validates the complete workflow from file upload → data processing → visualization.

**Independent Test**: User uploads a workout file and types "Show 30-second rolling average of power" and receives a smoothed power chart.

**Acceptance Scenarios**:

1. **Given** a workout file from "Athlete Joe Soap", **When** user prompts "Extract power data and show 30-second rolling averages", **Then** a line chart renders showing smoothed power values over time.
2. **Given** a workout file with multiple metrics (power, heart rate, cadence), **When** user prompts "Compare power and heart rate", **Then** a multi-axis chart displays with power on one axis and heart rate on another.
3. **Given** a workout file, **When** user prompts "Show power distribution in 20W bands", **Then** a bar chart displays showing frequency distribution of power values.

---

### User Story 3 - Complete Chart Property Control (Priority: P1)

A power user needs full control over every aspect of chart appearance and behavior, including styling, axes, interactions, and annotations.

**Why this priority**: Essential for production use - partial control limits usefulness. Users expect all standard charting options to be available.

**Independent Test**: User requests complex styling: "Make the line red, dashed, add markers at peaks, show a horizontal reference line at 250W" and all specifications are applied.

**Acceptance Scenarios**:

1. **Given** a chart creation request, **When** specifying styling properties, **Then** all of these are controllable:
   - Chart type (line, area, bar, scatter)
   - Colors, line widths, fill opacity, dash patterns
   - Axis labels, ranges, tick formatting, visibility
   - Grid appearance, legend position, interactions (pan, zoom, crosshair)
   - Annotations (reference lines, regions, labels)
   - Theme (light/dark mode)
2. **Given** an existing chart, **When** user prompts "Change the line to red and add a reference line at 200W", **Then** the same chart updates in-place without recreating a new chart.
3. **Given** incomplete styling in a request, **When** processed, **Then** sensible defaults are applied based on chart type and data context.

---

### User Story 4 - Quick Configuration Adjustments (Priority: P2)

After a chart is generated, users need a visual panel to quickly adjust common settings without typing another message.

**Why this priority**: Reduces friction - not every small tweak needs a conversation.

**Independent Test**: User clicks a "Settings" button on a chart and toggles dark mode; chart updates immediately.

**Acceptance Scenarios**:

1. **Given** a generated chart, **When** displayed, **Then** a configuration panel is accessible with controls for:
   - Theme toggle (light/dark)
   - Grid visibility
   - Legend visibility and position
   - Scrollbar visibility
2. **Given** a configuration panel change, **When** user modifies a setting, **Then** the chart updates immediately without involving the AI.
3. **Given** a panel change followed by a new message, **When** user prompts for further changes, **Then** the AI is aware of the current chart state including manual panel adjustments.

---

### User Story 5 - Multiple Data Sources (Priority: P2)

Users need to provide data from multiple sources: file uploads, URLs, or inline values in their message.

**Why this priority**: Real-world data comes from diverse sources; flexibility increases utility.

**Independent Test**: User pastes CSV data directly in chat, types "Chart this data", and receives a visualization.

**Acceptance Scenarios**:

1. **Given** a spreadsheet file upload, **When** user prompts "Chart the power column", **Then** data is extracted and charted.
2. **Given** inline data in the message "[1,2,3,4,5]", **When** processed, **Then** the inline values are charted.
3. **Given** a context file describing athlete defaults (name, threshold values, preferred colors), **When** processing chart requests, **Then** the context is applied to personalize the output.
4. **Given** a large dataset (over 100,000 data points), **When** charted, **Then** automatic optimization is applied to maintain responsiveness.

---

### User Story 6 - Sport Science Calculations (Priority: P2)

Sport scientists need domain-specific metrics calculated from raw data, such as Normalized Power, Training Stress Score, and zone analysis.

**Why this priority**: Differentiating feature for sport science workflows - these calculations are core to the domain.

**Independent Test**: User prompts "Calculate Normalized Power for this ride" and receives the computed NP value displayed.

**Acceptance Scenarios**:

1. **Given** power data from a workout, **When** user prompts "Calculate Normalized Power", **Then** the NP value is computed and displayed.
2. **Given** heart rate data, **When** user prompts "Show HR zones with time in each zone", **Then** zone boundaries are computed and time-in-zone is displayed.
3. **Given** a training session, **When** user prompts "Overlay my power zones on the chart", **Then** horizontal bands or lines are added at zone thresholds.

---

### User Story 7 - Workout Comparison (Priority: P3)

Users need to compare multiple workouts side-by-side or overlaid to track progress over time.

**Why this priority**: Common analysis pattern - comparing sessions reveals trends.

**Independent Test**: User uploads two workout files, prompts "Compare these rides", and sees overlaid data with a comparison metrics table.

**Acceptance Scenarios**:

1. **Given** two workout files, **When** user prompts "Compare power for these two rides", **Then** both are overlaid on the same chart with distinct colors.
2. **Given** overlaid workouts, **When** displayed, **Then** a comparison table shows key metrics (average power, duration, peak values) for each.
3. **Given** up to 5 workout files, **When** compared, **Then** all are distinguishable through different colors and line styles.

---

### User Story 8 - Chart Export & Favorites (Priority: P3)

Users need to export charts as images and save chart configurations for reuse.

**Why this priority**: Essential for reporting and reproducibility, but secondary to core creation features.

**Independent Test**: User clicks "Export" on a chart and downloads a PNG image.

**Acceptance Scenarios**:

1. **Given** a rendered chart, **When** user clicks "Export", **Then** a high-resolution image is generated and downloaded.
2. **Given** a chart the user likes, **When** user clicks "Favorite", **Then** the chart is saved to a session-local favorites list.
3. **Given** saved favorites, **When** user opens the favorites gallery, **Then** all saved charts are displayed with preview thumbnails.
4. **Given** favorites in the session, **When** user clicks "Export All", **Then** favorites can be exported as a configuration file for backup.

---

### User Story 9 - Inline Chart Editing (Priority: P2)

When multiple charts exist on screen, users need an easy way to specify which chart they want to modify.

**Why this priority**: Reduces confusion when working with multiple visualizations.

**Independent Test**: User clicks the chat icon on a specific chart, types "Make this line red", and only that chart updates.

**Acceptance Scenarios**:

1. **Given** multiple charts displayed, **When** user clicks the chat button on a specific chart, **Then** an inline chat opens scoped to that chart only.
2. **Given** an inline chat open, **When** user types a modification request, **Then** only the linked chart is updated.
3. **Given** an inline chat, **When** user collapses and later expands the chart, **Then** the chat history is preserved.
4. **Given** a chart, **When** user clicks "Add to Context", **Then** the chart is added to the main chat context for cross-chart operations.

---

### Edge Cases

- **Corrupted/unsupported file**: Display error message listing supported formats (FIT, CSV, TCX) and allow retry.
- **Unsupported chart type**: Display error message stating the chart type is not supported (no alternative suggestions).
- **AI service unavailable/rate-limited**: Automatic retry (1 attempt) with spinner; if still failing, show error with manual retry option.
- **Large files approaching limits (40-50MB)**: Display warning "Large file may take longer to process" at 40MB; reject files >50MB with error message.
- **Exceeding Y-axis limit**: Display error "Maximum 4 Y-axes supported. Please remove an axis before adding another."
- **Timezone differences**: Use file-embedded timezone when available (per FR-026); otherwise apply global user default with notification.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST accept natural language descriptions and generate corresponding chart visualizations.
- **FR-002**: System MUST parse and visualize data from standard workout file formats: FIT (binary activity), CSV (spreadsheet), and TCX (training center exchange).
- **FR-003**: System MUST support all standard chart types: line, area, bar, and scatter.
- **FR-004**: System MUST allow users to control all chart properties through natural language (colors, line styles, axes, legends, grids, interactions, annotations).
- **FR-005**: System MUST support modifying existing charts in-place rather than always creating new charts.
- **FR-006**: System MUST provide a visual configuration panel for quick adjustments without requiring conversation.
- **FR-007**: System MUST support multiple data sources: file uploads, inline data in messages, and context files.
- **FR-008**: System MUST compute sport science metrics: Normalized Power, Training Stress Score, Intensity Factor, time-in-zones.
- **FR-009**: System MUST support multi-axis charts with up to 4 Y-axes for displaying different units together.
- **FR-010**: System MUST support comparing up to 5 workouts with overlay and metrics table.
- **FR-011**: System MUST provide chart export as image files.
- **FR-012**: System MUST maintain session-local favorites that can be exported as configuration files.
- **FR-013**: System MUST provide inline chat scoped to individual charts for targeted modifications.
- **FR-014**: System MUST auto-discover data columns when files are uploaded and make them available for reference.
- **FR-015**: System MUST display loading indicators during file parsing and AI processing.
- **FR-016**: System MUST stream text responses as they arrive while waiting for complete responses before rendering charts.
- **FR-017**: System MUST handle errors gracefully with user-friendly messages and retry options for transient failures.
- **FR-018**: System MUST enforce file size limits (50 MB maximum) with warnings for large files.
- **FR-019**: System MUST validate and sanitize uploaded files for security: enforce allowed extensions (fit, csv, tcx), reject executable content, and enforce size limits per FR-018.
- **FR-020**: System MUST maintain undo/redo history for chart modifications within a session.
- **FR-021**: System MUST provide read-only prompt templates for common sport science analyses.
- **FR-022**: System MUST show data preview after file upload with column information and sample values.
- **FR-023**: System MUST display metric cards for computed values (Normalized Power, TSS, etc.) alongside charts.
- **FR-024**: System MUST warn users when approaching conversation/token limits and suggest starting a new session.
- **FR-025**: System MUST support keyboard shortcuts for common actions (send message, upload file, undo, export).
- **FR-026**: System MUST use file-embedded timezone when available, otherwise use global default.
- **FR-027**: System MUST display a welcome message with example prompts and a sample chart with demo data on first load.

### Key Entities

- **Chart**: A visualization with type, data series, axes, styling, and interaction settings.
- **Series**: A single data series within a chart, with its own styling and axis binding.
- **Data Source**: The origin of data - file upload, inline values, URL, or context reference.
- **Workout File**: A binary or text file containing time-series activity data (power, heart rate, etc.).
- **Context File**: A configuration file providing defaults (athlete info, thresholds, preferences).
- **Favorites**: Session-local collection of saved chart configurations.
- **Metric**: A computed scalar value (Normalized Power, TSS, IF, average, peak).
- **Annotation**: Visual overlay on charts (reference lines, zones, labels, markers).
- **Conversation**: The chat history between user and AI for a session.
- **Prompt Template**: A pre-built prompt for common analysis patterns.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Users can create a basic chart from natural language in under 30 seconds from first message to rendered result.
- **SC-002**: 90% of common chart modification requests are understood correctly on the first attempt without clarification.
- **SC-003**: File parsing and column discovery complete within 10 seconds for files under 10 MB.
- **SC-004**: Chart rendering completes within 2 seconds after data is processed.
- **SC-005**: Users can modify any chart property through natural language that they could configure manually.
- **SC-006**: Sport science metric calculations (NP, TSS, IF) match industry-standard formulas within 1% tolerance.
- **SC-007**: System handles 50 MB files without crashing or timing out.
- **SC-008**: 95% of user sessions complete without encountering unrecoverable errors.
- **SC-009**: Exported chart images are publication-quality (300 DPI minimum).
- **SC-010**: Users report the interface as "intuitive" or "easy to use" in at least 80% of feedback.
- **SC-011**: Inline chart editing correctly targets only the selected chart 100% of the time.
- **SC-012**: Configuration panel changes apply instantly (under 100ms perceived latency).

## Assumptions

- Users have valid API credentials for the AI service provider.
- Workout files follow standard formats that can be parsed by existing data libraries.
- Users understand basic charting concepts (axes, series, legends) even if they don't know technical APIs.
- Session state (favorites, undo history) is acceptable to lose on page refresh for V1.
- Single-user sessions only; collaborative/multi-user features are out of scope.
- External API integrations (intervals.icu, TrainingPeaks) are deferred to a future phase.
- Advanced chart types (candlestick, heatmap) are aspirational for V1 with core types prioritized.
- Observability is minimal for V1 (console errors only); structured logging deferred to future phase.

## Constraints

| Constraint                      | Value                            |
| ------------------------------- | -------------------------------- |
| Maximum file size               | 50 MB                            |
| Maximum Y-axes per chart        | 4                                |
| Maximum workouts in comparison  | 5                                |
| Maximum concurrent file uploads | Unlimited (with warning if > 5)  |
| Session token limit             | Provider-dependent (warn at 80%) |
| Undo history depth              | 20 steps                         |
| Maximum prompt templates        | Read-only presets only in V1     |

## Dependencies

- AI/LLM service for natural language understanding and generation
- Data parsing libraries for workout file formats
- Chart rendering library with full property control
- Browser environment with file upload capabilities

## Out of Scope (V1)

- External API integrations (intervals.icu, TrainingPeaks)
- Persistent storage of favorites and templates across sessions
- Multi-user collaboration
- Custom user-defined prompt templates
- Shareable chart links
- Conversation search
- Customizable keyboard shortcuts
