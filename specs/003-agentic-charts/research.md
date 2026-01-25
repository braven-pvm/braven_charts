# Research: Agentic Charts

**Feature**: 003-agentic-charts  
**Date**: 2026-01-25  
**Status**: Complete

## Research Tasks

### RT-1: LLM Tool Calling Patterns for Dart/Flutter

**Question**: Best practices for implementing LLM tool/function calling in Dart?

**Decision**: Use typed Dart classes with JSON schema generation for tool definitions.

**Rationale**:

- `anthropic_sdk_dart` already supports tool calling with typed schemas
- JSON Schema can be generated from Dart classes using code generation or manual mapping
- Typed responses enable compile-time safety and IDE support

**Alternatives Considered**:

- Dynamic JSON maps: Rejected - loses type safety, error-prone
- Code generation (json_serializable): Considered but manual mapping sufficient for ~10 tools

**Implementation Pattern**:

```dart
abstract class LLMTool<TInput, TOutput> {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;

  Future<TOutput> execute(TInput input);
}
```

---

### RT-2: Multi-Provider LLM Abstraction

**Question**: How to support Anthropic, OpenAI, and Gemini with unified interface?

**Decision**: Create `LLMProvider` abstract class with provider-specific implementations.

**Rationale**:

- POC validated with Anthropic; pattern works
- Each provider has different API shapes but similar tool calling concepts
- Abstraction allows runtime provider switching

**Alternatives Considered**:

- Single provider (Anthropic only): Rejected - vendor lock-in, user preference varies
- LangChain-style framework: Rejected - overkill for this use case, adds dependency

**Implementation Pattern**:

```dart
abstract class LLMProvider {
  Future<LLMResponse> chat(List<Message> messages, List<Tool> tools);
  Stream<LLMStreamEvent> chatStream(List<Message> messages, List<Tool> tools);
}
```

---

### RT-3: Data Reference System

**Question**: How to handle large datasets without passing all data through LLM context?

**Decision**: UUID-based data store with references passed to LLM.

**Rationale**:

- Reduces token usage (LLM sees column names, not all data)
- Enables 100k+ data point handling
- Supports multi-step workflows (load → transform → chart)

**Alternatives Considered**:

- Inline data in tool calls: Rejected - token limits, cost
- File paths: Rejected - web platform has no file system access

**Implementation Pattern**:

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

---

### RT-4: CORS Handling for Web

**Question**: How to handle CORS for LLM API calls from Flutter web?

**Decision**: Development uses `--disable-web-security`; production uses Cloudflare Worker proxy.

**Rationale**:

- LLM APIs (Anthropic, OpenAI) don't support browser CORS
- Worker proxy is lightweight, serverless solution
- No backend required for simple API forwarding

**Alternatives Considered**:

- Full backend proxy: Rejected - adds deployment complexity
- Browser extension: Rejected - poor UX, requires installation

**Implementation Notes**:

- Document proxy setup in quickstart.md
- Provide Cloudflare Worker template

---

### RT-5: State Management for Chat UI

**Question**: Best state management pattern for chat interface with high-frequency updates?

**Decision**: Use `ValueNotifier` + `ValueListenableBuilder` per constitution requirements.

**Rationale**:

- Constitution mandates no `setState` for >10Hz updates
- Chat messages update frequently during streaming
- Chart interactions (crosshair, selection) are high-frequency

**Alternatives Considered**:

- Provider/Riverpod: Overkill for single-screen feature
- BLoC: More boilerplate than needed
- setState: Explicitly prohibited by constitution

**Implementation Pattern**:

```dart
class ChatState {
  final ValueNotifier<List<Message>> messages = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String> currentInput = ValueNotifier('');
}
```

---

### RT-6: FIT File Parsing Integration

**Question**: How to integrate existing `braven_data` FIT loader with agent tools?

**Decision**: Wrap `braven_data.FitLoader` in `LoadDataTool` with schema discovery.

**Rationale**:

- FIT parsing already implemented and tested
- `describe_data` tool needs column metadata extraction
- Reuse existing infrastructure

**Alternatives Considered**:

- Reimplement FIT parsing: Rejected - duplication, tested code exists
- External service: Rejected - adds latency, dependency

**Integration Points**:

- `FitLoader.load()` → `DataStore.store()`
- Column discovery from `FitLoader` metadata
- Unit conversion from `braven_data` utilities

---

### RT-7: Sport Science Metric Formulas

**Question**: What are the exact formulas for NP, TSS, IF calculations?

**Decision**: Use industry-standard TrainingPeaks formulas.

**Formulas**:

```
Normalized Power (NP):
  1. Calculate 30-second rolling average of power
  2. Raise each value to 4th power
  3. Calculate mean of powered values
  4. Take 4th root of mean
  NP = (mean(rolling_30s_power^4))^0.25

Intensity Factor (IF):
  IF = NP / FTP
  (where FTP = Functional Threshold Power)

Training Stress Score (TSS):
  TSS = (duration_seconds × NP × IF) / (FTP × 3600) × 100
```

**Rationale**:

- Industry standard formulas used by TrainingPeaks, Garmin, etc.
- 1% tolerance requirement met with proper floating-point handling

**Sources**:

- TrainingPeaks documentation
- Dr. Andrew Coggan original papers

---

### RT-8: Chart Configuration Serialization

**Question**: How to serialize/deserialize chart configurations for undo/redo and export?

**Decision**: Use Dart `json_serializable` for `ChartConfiguration` class.

**Rationale**:

- Need to serialize for: undo/redo stack, favorites export, LLM context
- JSON is universal format understood by LLMs
- Type-safe serialization with code generation

**Alternatives Considered**:

- Manual toJson/fromJson: Error-prone for complex nested structures
- Protobuf: Overkill, adds build complexity

---

## Summary

All research tasks complete. No NEEDS CLARIFICATION items remain.

| Task | Decision                | Risk Level          |
| ---- | ----------------------- | ------------------- |
| RT-1 | Typed tool classes      | Low                 |
| RT-2 | LLMProvider abstraction | Low                 |
| RT-3 | UUID data references    | Low                 |
| RT-4 | Cloudflare Worker proxy | Medium (deployment) |
| RT-5 | ValueNotifier pattern   | Low                 |
| RT-6 | braven_data integration | Low                 |
| RT-7 | TrainingPeaks formulas  | Low                 |
| RT-8 | json_serializable       | Low                 |

**Proceed to**: Phase 1 - Data Model & Contracts
