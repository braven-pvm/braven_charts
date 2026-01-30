# Technical Design: End-to-End Implementation Guide (Spec 004)

**Status:** Canonical
**Context:** The "Blueprints" for Implementation.
**Date:** 2026-01-28
**Version:** 2.0 (Layer Boundaries Clarified)

---

## IMPORTANT: Spec-to-Layer Mapping

This document covers the FULL system across three specs. Each section is tagged with its owning spec.

| Spec  | Layer               | Package/App         | Status          |
| ----- | ------------------- | ------------------- | --------------- |
| 004.1 | Layer 2: The Brain  | `braven_agent`      | **Active**      |
| 004.2 | Layer 1: The App    | BravenLab Studio    | Future          |
| 004.3 | Layer 1: The Memory | Athlete Datastore   | Future          |
| N/A   | Layer 3: The Body   | `braven_chart_plus` | Exists (stable) |

**When implementing 004.1, IGNORE sections tagged with 004.2 or 004.3.**

---

## 1. System Composition (The Wiring)

The solution is composed of three distinct layers.

### Layer 1: The App (`BravenLab Studio`) — **Spec 004.2**

**Responsibility:** UI, File I/O, Database, Credential Storage, Athlete Identity.
**Artifacts:** `main.dart`, `ChatScreen`, `ProjectDatabase`.
**NOT in 004.1 scope.**

### Layer 2: The Brain (`braven_agent`) — **Spec 004.1** ✅

**Responsibility:** Orchestration, Prompting, Tools (create/modify chart), LLM Communication.
**Artifacts:** `AgentSession`, `CreateChartTool`, `ModifyChartTool`, `ChartRenderer`.
**This is what 004.1 implements.**

### Layer 3: The Body (`braven_chart_plus`) — **Existing**

**Responsibility:** Pure Rendering, Widget Library.
**Artifacts:** `BravenChartPlus`, `ChartTheme`, series types.
**Already exists - no changes needed for 004.1.**

---

## 2. Initialization & Dependency Injection

How the system boots up. **Components are tagged by spec.**

### 2.1 V1 Initialization (004.1 Only)

```dart
// ========================================
// 004.1 SCOPE - Minimal Agent Setup
// ========================================

// 1. Configure the LLM Provider
final llmConfig = LLMConfig(
  apiKey: env['ANTHROPIC_KEY'],
  model: 'claude-sonnet-4-20250514',
  temperature: 0.7,
  maxTokens: 4096,
);

// 2. Register providers (app startup)
LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));

// 3. Create provider
final llmProvider = LLMRegistry.create('anthropic', llmConfig);

// 4. Create session with V1 tools (chart only)
final session = AgentSessionImpl(
  llmProvider: llmProvider,
  tools: [
    CreateChartTool(),
    ModifyChartTool(getActiveChart: () => session.state.value.activeChart),
  ],
  systemPrompt: defaultSystemPrompt,  // From braven_agent
);

// 5. Use it
await session.transform('Create a line chart with sample data');
final chart = session.state.value.activeChart;
final widget = const ChartRenderer().render(chart!);
```

### 2.2 Future Initialization (004.2/004.3 - NOT V1)

```dart
// ========================================
// FUTURE SCOPE (004.2/004.3) - Full System
// DO NOT IMPLEMENT IN 004.1
// ========================================

// Data Context (004.3 - Athlete Datastore)
final dataContext = AppDataContext(
  database: mySqliteDb,
  fileLoader: myFitFileLoader,
);

// Extended Tools (004.2/004.3)
final tools = [
  CreateChartTool(),                        // 004.1 ✅
  ModifyChartTool(...),                     // 004.1 ✅
  QueryMetricsTool(dataContext),            // 004.3 ❌ NOT V1
  GetReducedSeriesTool(dataContext),        // 004.3 ❌ NOT V1
  ProjectSearchTool(dataContext),           // 004.2 ❌ NOT V1
];

// Session with context injection (004.2)
final sessionFactory = AgentSessionFactory(
  llmProvider: llmProvider,
  tools: tools,
  systemPromptBuilder: (context) => "You are helping ${context.athleteName}...",
);

final session = sessionFactory.create(
  sessionId: 'session_123',
  context: SessionContext(athleteId: 'athlete_456'),  // 004.2 ❌ NOT V1
);
```

---

## 3. The Interaction Loop (End-to-End Flow)

### Scenario A: Synthetic Generation — **004.1 Scope** ✅

This is the V1 smoke test. No data analysis, no file loading.

**User Prompts:** "Create a complex chart with 4 series and variability in the data"

1.  **Context:** No attachments, no `DataContext` needed.
2.  **LLM Decision:** "I will use `create_chart` with synthetic data."
3.  **Agent Execution:**
    - Calls `CreateChartTool` with inline data: `series: [{ data: [{x:1, y:10}...] }]`.
    - **No** `QueryMetrics` or `GetReducedSeries` calls.
4.  **Result:** `ChartCreatedEvent` fires. Chart renders with 4+ series.

**This is what 004.1 implements and tests.**

---

### Scenario B: Data Analysis — **004.2/004.3 Scope** ❌ NOT V1

**DO NOT IMPLEMENT THIS IN 004.1.** This requires the Athlete Datastore (004.3).

**User:** "Show me my max power from last week" + Attaches `workout.fit`.

#### Step 1: User Input (004.2)

```dart
session.transform(
  "Show me my max power from last week",
  attachments: [FileAttachment.fromPath('path/to/workout.fit')]  // 004.3
);
```

#### Step 2: Agent Processing (004.2/004.3)

1.  **State Update:** `session.state.status` -> `thinking`.
2.  **Context Assembly:**
    - `AgentSession` converts `Attachment` -> `BinaryContent`.
    - `AgentSession` executes the `SystemPromptBuilder` with athlete context. ❌ NOT V1
3.  **LLM Request:** `llmProvider.generateResponse(history, tools)`.

#### Step 3: LLM & Tool Execution (004.3)

1.  **LLM Decision:** Returns `ToolUseContent(name: 'query_metrics', ...)`. ❌ NOT V1
2.  **Agent Execution:**
    - Calls `QueryMetricsTool` which uses `dataContext.queryMetric()`. ❌ NOT V1
3.  **Tool Result:** Returns "Max Power: 1205 Watts".
4.  **Series Fetching:** LLM calls `GetReducedSeriesTool`. ❌ NOT V1

#### Step 4: Chart Generation (004.1 portion)

1.  **LLM Decision:** Returns `ToolUseContent(name: 'create_chart', ...)`.
2.  **Agent Execution:** `CreateChartTool` creates config. ✅ V1
3.  **Result:** `ChartCreatedEvent` fires. ✅ V1

#### Step 5: UI Rendering (004.2)

1.  **Chart:** `BravenChart(config: state.activeChart)` rebuilds. ✅ Partial V1
2.  **Persistence:** App saves chart to SQLite. ❌ NOT V1

---

## 4. Interfaces Checklist (By Spec)

### 4.1 `LLMProvider` — **004.1** ✅

- `generateResponse(systemPrompt, history, tools)`
- `streamResponse(...)` — Optional for V1
- Supports `BinaryContent` pass-through

### 4.2 `DataContext` — **004.3** ❌ NOT V1

**DO NOT IMPLEMENT IN 004.1.** This is the bridge to athlete data.

- `getAthleteMetadata(id)` -> YAML/JSON string
- `queryMetrics(fileId, query)` -> Numeric result
- `getReducedSeries(fileId, metric)` -> List<DataPoint> (LTTB reduced)
- `getFileSummary(fileId)` -> Token-optimized header

### 4.3 `AgentSession` — **004.1** ✅

- `transform(text, attachments)`
- `updateChart(newConfig)` — User edit flow
- `cancel()`
- `dispose()`
- `state` (ValueListenable<SessionState>)
- `events` (Stream<AgentEvent>)

### 4.4 `ChartConfiguration` — **004.1** ✅

- Full schema defined in 004.1 spec Section 4
- `fromJson` / `toJson` support
- `NormalizationMode` support

---

## 5. Error Handling Strategy

### 5.1 Errors Handled in 004.1 ✅

1.  **LLM Distortion:** If LLM returns bad JSON for chart, `CreateChartTool` catches and returns `ToolResult(isError: true, message: "...")`. LLM auto-corrects.
2.  **Network Error:** `LLMProvider` throws. `AgentSession` catches, sets `state.status = error`, emits `ErrorEvent`.
3.  **Unknown Tool:** `ToolNotFoundException` thrown, `ErrorEvent` emitted.

### 5.2 Errors Handled in 004.3 ❌ NOT V1

1.  **Data Access Error:** If `DataContext` fails (file not found), Tool returns error.
2.  **File Parse Error:** FIT/CSV parsing fails, Tool returns error with guidance.

---

## 6. Component Ownership Summary

| Component              | Spec  | Package/Layer       | Notes                          |
| ---------------------- | ----- | ------------------- | ------------------------------ |
| `AgentSession`         | 004.1 | `braven_agent`      | Core orchestration             |
| `CreateChartTool`      | 004.1 | `braven_agent`      | Synthetic data, no DataContext |
| `ModifyChartTool`      | 004.1 | `braven_agent`      | Modify active chart            |
| `ChartRenderer`        | 004.1 | `braven_agent`      | Config → Widget                |
| `ChartConfiguration`   | 004.1 | `braven_agent`      | Agentic model                  |
| `LLMProvider`          | 004.1 | `braven_agent`      | Abstract interface             |
| `AnthropicAdapter`     | 004.1 | `braven_agent`      | Anthropic implementation       |
| `LLMRegistry`          | 004.1 | `braven_agent`      | Provider factory               |
| `QueryMetricsTool`     | 004.3 | BravenLab Studio    | Requires DataContext           |
| `GetReducedSeriesTool` | 004.3 | BravenLab Studio    | Requires DataContext           |
| `ProjectSearchTool`    | 004.2 | BravenLab Studio    | Requires database              |
| `DataContext`          | 004.3 | BravenLab Studio    | Athlete data bridge            |
| `SessionContext`       | 004.2 | BravenLab Studio    | Athlete identity injection     |
| `AgentSessionFactory`  | 004.2 | BravenLab Studio    | Context-aware session creation |
| `SystemPromptBuilder`  | 004.2 | BravenLab Studio    | Dynamic prompt with athlete    |
| `BravenChartPlus`      | N/A   | `braven_chart_plus` | Already exists                 |

---

## 7. Implementation Sequence

### Phase 1: 004.1 (braven_agent) — **CURRENT**

1. Create `packages/braven_agent/` scaffold
2. Implement domain models (`ChartConfiguration`, etc.)
3. Implement `LLMProvider` + `AnthropicAdapter`
4. Implement `CreateChartTool` and `ModifyChartTool`
5. Implement `AgentSession` with state management
6. Translate `ChartRenderer` from `/agentic`
7. Verify with synthetic chart generation test

### Phase 2: 004.3 (Athlete Datastore) — FUTURE

1. Define `DataContext` interface
2. Implement FIT/CSV ingestion pipeline
3. Implement `QueryMetricsTool`, `GetReducedSeriesTool`
4. Add data-aware tools to agent

### Phase 3: 004.2 (BravenLab Studio) — FUTURE

1. Implement `SessionContext` and `AgentSessionFactory`
2. Implement `SystemPromptBuilder` with athlete context
3. Build UI shell and chat interface
4. Wire persistence layer
