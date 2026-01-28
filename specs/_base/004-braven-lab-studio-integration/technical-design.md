# Technical Design: End-to-End Implementation Guide (Spec 004)

**Status:** Canonical
**Context:** The "Blueprints" for Implementation.
**Date:** 2026-01-28

## 1. System Composition (The Wiring)

The solution is composed of three distinct layers.

### Layer 1: The App (`BravenLab Studio`)

**Responsibility:** UI, File I/O, Database, Credential Storage.
**Artifacts:** `main.dart`, `ChatScreen`, `ProjectDatabase`.

### Layer 2: The Brain (`braven_agent`)

**Responsibility:** Orchestration, Prompting, Tools, LLM Communication.
**Artifacts:** `AgentSession`, `AgentController`, `CreateChartTool`.

### Layer 3: The Body (`braven_chart_plus`)

**Responsibility:** Pure Rendering, Serialization (JSON <-> Chart).
**Artifacts:** `BravenChart`, `ChartConfiguration`, `ChartTheme`.

---

## 2. Initialization & Dependency Injection

How the system boots up.

```dart
// 1. Configure the LLM Provider (Strategy Pattern)
final llmConfig = LLMConfig(
  apiKey: env['ANTHROPIC_KEY'],
  providerIdx: 'anthropic-sonnet-3.5',
);
final llmProvider = LLMRegistry.create(llmConfig);

// 2. Configure Data Context (Bridge to App Data)
// Implements the abstract DataContext interface defined in braven_agent
final dataContext = AppDataContext(
  database: mySqliteDb,
  fileLoader: myFitFileLoader,
);

// 3. Register Tools
final tools = [
  CreateChartTool(), // Native chart generation
  QueryMetricsTool(dataContext), // Data analysis (uses DataContext)
  GetReducedSeriesTool(dataContext), // Fetches render-ready data points
  ProjectSearchTool(dataContext), // Search existing files
];

// 4. Create the Session Factory
final sessionFactory = AgentSessionFactory(
  llmProvider: llmProvider,
  tools: tools,
  systemPromptBuilder: (context) => "You are a sports scientist helping ${context.athleteName}...",
);

// 5. Start a Session (e.g., when opening a tab)
final session = sessionFactory.create(
  sessionId: 'session_123',
  context: SessionContext(athleteId: 'athlete_456'),
);
```

---

## 3. The Interaction Loop (End-to-End Flow)

### Scenario A: Synthetic Generation (Smoke Test)

**User Prompts:** "We are testing our now agent chart tool. Please use it to create a complex chart..."

1.  **Context:** No attachments, no `DataContext` interaction required.
2.  **LLM Decision:** "I possess the `create_chart` tool. I will generate synthetic data."
3.  **Agent Execution:**
    - Calls `CreateChartTool` with inline data: `series: [{ data: [{x:1, y:10}...] }]`.
    - No `QueryMetrics` or `GetReducedSeries` calls.
4.  **Result:** `ChartCreatedEvent` fires. Chart appears with >4 series.

### Scenario B: Data Analysis (Production Flow)

### Step 1: User Input

**User:** Typs "Show me my max power from last week" + Attaches `workout.fit`.

**App Code:**

```dart
session.transform(
  "Show me my max power from last week",
  attachments: [FileAttachment.fromPath('path/to/workout.fit')]
);
```

### Step 2: Agent Processing (`braven_agent`)

1.  **State Update:** `session.state.status` -> `thinking`.
2.  **Context Assembly:**
    - `AgentSession` converts `Attachment` -> `BinaryContent`.
    - `AgentSession` appends to `history`.
    - `AgentSession` executes the `SystemPromptBuilder` (invoking the callback provided by the App to get domain context).
3.  **LLM Request:**
    - `llmProvider.generateResponse(history, tools)` is called.

### Step 3: LLM & Tool Execution

1.  **LLM Decision:** Returns `ToolUseContent(name: 'query_metrics', input: {'metric': 'power', 'agg': 'max'})`.
2.  **Agent Execution:**
    - `AgentSession` sees `ToolUseContent`.
    - Updates `state.activeTool` (UI shows "Analyzing Power...").
    - Calls `tools['query_metrics'].execute(input)`.
    - `QueryMetricsTool` calls `dataContext.queryMetric()`.
3.  **Tool Result:** Returns "Max Power: 1205 Watts (Sprint Segment)".
4.  **Re-Prompt:** Agent sends Tool Result back to LLM.
5.  **Series Fetching:**
    - LLM decides to retrieve actual data points for the visualization.
    - LLM Calls `GetReducedSeriesTool`.
    - Tool returns JSON array of points `[{t: 0, v: 100}, {t: 1, v: 120}...]`.

### Step 4: Chart Generation

1.  **LLM Decision:** "I should visualize this."
    - Returns `ToolUseContent(name: 'create_chart', input: { ...json_with_data_points... })`.
2.  **Agent Execution:**
    - `CreateChartTool` validates JSON against `ChartConfiguration.fromJson`.
    - Returns a valid `ChartConfiguration` object.
    - **CRITICAL:** `AgentSession` detects a `ChartConfiguration` result.
    - Updates `state.activeChart = newChart`.
    - Fires `events.add(ChartCreatedEvent(newChart))`.
3.  **Final Response:**
    - LLM returns `TextContent("Here is your power chart...")`.
    - `state.pendingResponse` streams this text.

### Step 5: UI Rendering (`BravenLab Studio`)

1.  **Chart:**
    - `ValueListenableBuilder(value: session.state)` fires.
    - `BravenChart(config: state.activeChart)` rebuilds.
2.  **Chat:**
    - message list updates with the new text.
3.  **Persistence:**
    - App listens to `session.events`.
    - Receives `ChartCreatedEvent`.
    - Saves chart to SQLite.

---

## 4. Interfaces Checklist

### 4.1 `LLMProvider` (Input)

- `generateResponse(history, tools)`
- `streamResponse` (Optional for V1)
- Supports `BinaryContent` (pass-through or rejection)

### 4.2 `DataContext` (Bridge)

- `getAthleteMetadata(id)` -> YAML/JSON string
- `queryMetrics(fileId, query)` -> Numeric result
- `getReducedSeries(fileId, metric)` -> List<DataPoint> (LTTB reduced)
- `getFileSummary(fileId)` -> Token-optimized header

### 4.3 `AgentSession` (Output)

- `transform(text, attachments)`
- `cancel()`
- `state` (ValueListenable<SessionState>)
- `events` (Stream<AgentEvent>)

### 4.4 `ChartConfiguration` (Schema)

- Must support `fromJson` perfectly.
- Must support `NormalizationMode` (for Power vs HR).

---

## 5. Error Handling Strategy

1.  **LLM Distortion:** If LLM returns bad JSON for chart, `CreateChartTool` catches exception and returns `ToolResult(isError: true, message: "Invalid JSON config: missing 'series' field")`. LLM sees this and auto-corrects.
2.  **Data Access Error:** If `DataContext` fails (file not found), Tool returns error. Agent explains to user.
3.  **Network Error:** `LLMProvider` throws. `AgentSession` catches, sets `state.status = error`, emits `ErrorEvent`.
    final AthleteMetrics metrics; // FTP, Zones, etc.
    }

````

### 2.2 Integration

The `AgentService` will now require a `BravenStore` and a current `athleteId` context to function effectively.

## 3. UI/UX Component Library

The standard chat widgets will be refactored into a composable library:

- `BravenChatPanel`: The main container.
- `BravenMessageBubble`: Standardized bubble with support for "Rich Content" slots.
- `BravenInlineChat`: A floating/dockable version of the panel.

## 4. Architecture Refactor & Boundary Definition (CRITICAL)

Strict separation of concerns is required to keep `braven_chart_plus` a reusable package while enabling `BravenLab Studio` functionality.

### 4.1 BravenChartPlus Package (The "Engine")

**Responsibility:** "How to process data and render charts."

- **Components:**
  - `AgentService`: The core logic for talking to the LLM.
  - `SmartDataSource`: The logic for ingesting and reducing FIT/CSV files.
  - `BravenStore` (Abstract): Interface definitions for data access.
  - `ChartRenderer`: The Flutter widgets for drawing the charts.
  - `ChatWidgets`: Reusable UI components (bubbles, panels) but _styled_ generically.
- **Dependencies:** `dart:ui`, `flutter`, `llm_provider`, `fast_equatable`.
- **Forbidden:** Database implementations (Isar/Hive), User Auth logic, Specific file system paths.

### 4.2 BravenLab Studio (The "Application")

**Responsibility:** "Who analyzes what data."

- **Components:**
  - **Identity Management:** Selecting "Hansie Joubert", Auth.
  - **Concrete Store:** Implementation of `BravenStore` using Isar/SQLite.
  - **File Management:** Reading files from disk, passing file streams to `SmartDataSource`.
  - **App Shell:** Navigation, Settings, Theme configuration.
- **Dependencies:** `braven_chart_plus`, `isar`, `path_provider`, etc.

### 4.3 Integration Point

The Application initializes the Package by injecting dependencies:

```dart
// In BravenLab Studio (main.dart)
final store = IsarBravenStore(); // Implements abstract BravenStore
final agentService = AgentService(
  store: store,
  llmProvider: AnthropicProvider(apiKey: ...),
);
````

## 5. Migration Path

1. **Phase 1 (Data):** Implement `SmartDataSource` and LTTB reduction in `braven_chart_plus`.
2. **Phase 2 (Store):** Define `BravenStore` interfaces and mock implementation.
3. **Phase 3 (UI):** Refactor widgets to use the new unified design system.
4. **Phase 4 (Integration):** Wire it all up in the Example app (proto-Studio).
